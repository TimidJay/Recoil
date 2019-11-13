EditorState = class("EditorState")

--TODO:
--  Add both the entrance and exit gate
--  Both gates are 5 tiles long, can only appear on the edge of the level
--  Entrance gate is green, exit gate is red?

tool = "fillrect"

function EditorState:initialize()
	editorstate = self

	self.className = "EditorState"

	--grid starts at the top-left corner
	self.grid = {}
	self.allNodes = {} --allows for easy iteration across all nodes
	for i = 1, config.grid_h do
		local row = {}
		for j = 1, config.grid_w do
			local node = GridNode:new(self, i, j)
			table.insert(row, node)
			table.insert(self.allNodes, node)
			--place blocks on the edges of the grid
			if i == 1 or i == config.grid_h or j == 1 or j == config.grid_w then
				node:setTile("block")
			end
		end
		table.insert(self.grid, row)
	end

	self.gates = {
		enter = Gate:new("enter", 22, 1, "left", false),
		exit = Gate:new("exit", 22, config.grid_w, "right", false)
	}
	self.entranceGate = Gate:new("enter", 22, 1, "left", false)
	self.exitGate = Gate:new("exit", 22, config.grid_w, "right", false)
	self:setOverlap()

	--holes can be added to the bottom wall
	self.pit = {} --work in progress

	self.selectedTile = "block"

	--gui stuff

	local frame = loveframes.Create("frame")
	frame:SetName("Tiles")
	frame:ShowCloseButton(false)
	frame:SetPos(window.w - 200, 100)
	frame:SetWidth(120)
	frame:SetHeight(250)
	frame:SetState("EditorState")

	local flist = loveframes.Create("list", frame)
	flist:SetPos(10, 40)
	flist:SetWidth(100)
	flist:SetHeight(200)
	flist:SetSpacing(5)
	flist:SetPadding(5)

	local tileKeys = {"block", "deathblock"}
	for i, key in ipairs(tileKeys) do
		local tileData = data.tiles[key]
		button = loveframes.Create("button", frame)
		button:SetText(tileData.editor.name)
		button.OnClick = function(obj, x, y)
			self.selectedTile = key
		end
		flist:AddItem(button)
	end

	self.frame = frame
end

function EditorState:close()
	editorstate = nil
end

function EditorState:reset()
	for _, n in ipairs(self.allNodes) do
		n:clear()
	end
	self.pit = {}
end

--global function for easier access
function saveLevel(filename)
	if game:top() ~= editorstate then
		print("Make sure you're in the Level Editor state!")
		return
	end
	editorstate:saveLevel(filename)
end

function EditorState:saveLevel(filename)
	local tableToString = util.tableToString
	local join = util.join

	local file = love.filesystem.newFile("levels/"..filename)
	file:open("w")
	file:write("local level = {}\n")

	file:write("level.tiles = {\n")
	for _, n in ipairs(self.allNodes) do
		if n.tile then
			local line = "\t{"..n.i..", "..n.j..", \""..n.tile.key.."\"},\n"
			file:write(line)
		end
	end
	file:write("}\n")

	local enter, exit = self.gates.enter, self.gates.exit
	file:write("level.gates = {\n")
	file:write("\tenter = {"..enter.i..", "..enter.j..", \""..enter.dir.."\"},\n")
	file:write("\texit = {"..exit.i..", "..exit.j..", \""..exit.dir.."\"},\n")
	file:write("}\n")

	--exported format is a list of keys
	file:write("level.pit = {")
	for j, _ in pairs(self.pit) do
		file:write(j..", ")
	end
	file:write("}\n")

	file:write("return level")
	file:close()
end

function loadLevel(filename)
	if game:top() ~= editorstate then
		print("Make sure you're in the Level Editor state!")
		return
	end
	editorstate:loadLevel(filename)
end

function EditorState:loadLevel(filename)
	local chunk = love.filesystem.load("levels/"..filename)
	if not chunk then
		print("ERROR: File "..filename.." not found!")
		return
	end
	self:reset()
	local level = chunk()
	for _, t in ipairs(level.tiles) do
		local i, j, key = unpack(t)
		self.grid[i][j]:setTile(key)
	end
	for k, gate in pairs(self.gates) do
		local t = level.gates[k]
		gate:setPos2(t[1], t[2])
		gate:setDir(t[3])
	end
	self:setOverlap()
	for _, v in ipairs(level.pit) do
		self.pit[v] = true
	end
end

--checks if the mouse overlaps a loveframes object
function EditorState.containMouse(obj)
	local x, y = obj:GetPos()
	local w, h = obj:GetSize()
	local mx, my = mouse.x, mouse.y

	return mx > x and mx < x+w and my > y and my < y+h
end

--sets overlap grid for non-tile objects such as gates
function EditorState:setOverlap()
	local overlap = {}
	for i = 1,  config.grid_w do
		overlap[i] = {}
	end
	for k, g in pairs(self.gates) do
		local t = g:getOccupied()
		for _, p in ipairs(t) do
			local i, j = p[1], p[2]
			overlap[i][j] = k --Only one object can occupy a cell at a time
		end
	end
	self.overlap = overlap
end

--checks if the gate does not overlap the other gate
function EditorState:gateValidPos(choice, name)
	local i, j = choice[3], choice[4]
	local dir = choice[1]
	local t = {}
	if dir == "up" or dir == "down" then
		for d = -2, 2 do
			table.insert(t, {i, j+d})
		end
	else
		for d = -2, 2 do
			table.insert(t, {i+d, j})
		end
	end
	local overlap = self.overlap
	for _, v in ipairs(t) do
		local o = overlap[v[1]][v[2]]
		if o ~= nil and o ~= name then
			return false
		end
	end
	return true
end

function EditorState:update(dt)
	local mx, my = mouse.x, mouse.y
	local mi, mj = getGridPos(mx, my)

	

	if keys.escape then

		self:startTest()
		return
	end

	for _, n in ipairs(self.allNodes) do
		n.highlight = false
	end

	--don't interact with background if mouse is in a gui
	if EditorState.containMouse(self.frame) and mouse.m1 ~= 2 then
		return
	end

	--dragging gates around
	if mouse.m1 == 1 and self.gates.enter:containMouse() then
		self.drag = "enter"
	elseif mouse.m1 == 1 and self.gates.exit:containMouse() then
		self.drag = "exit"
	end
	if self.drag then
		local gate = self.gates[self.drag]
		--get closest point to edge
		local gw, gh = config.grid_w, config.grid_h
		local i, j = getGridPos(mouse.x, mouse.y)
		i2 = math.min(math.max(i, 3), gh - 2)
		j2 = math.min(math.max(j, 3), gw - 2)
		local candidates = {
			{"up"   , math.abs(i - 1) , 1 , j2 },
			{"down" , math.abs(i - gh), gh, j2 },
			{"left" , math.abs(j - 1) , i2 , 1 },
			{"right", math.abs(j - gw), i2 , gw} 
		}
		local choice = candidates[1]
		for _, v in pairs(candidates) do
			if v[2] < choice[2] then
				choice = v
			end
		end
		if self:gateValidPos(choice, self.drag) then
			--move the gate to that location
			gate:setPos2(choice[3], choice[4])
			gate:setDirection(choice[1])
		end
		--after dragging is done, update the overlap grid
		if not mouse.m1 then
			self.drag = nil
			self:setOverlap()
		end
	--tool usage
	elseif boundCheck(mi, mj) then
		if tool == "free" then
			local node = self.grid[mi][mj]
			node.highlight = true

			if mouse.m1 then
				node:setTile(self.selectedTile)
			elseif mouse.m2 then
				node:clear()
			end
		elseif tool == "rect" or tool == "fillrect" then
			if mouse.m1 or mouse.m2 then
				self.selectedNodes = {}
				if mouse.m1 == 1 or mouse.m2 == 1 then
					self.clicked = {
						i = mi, 
						j = mj, 
						mode = (mouse.m1 == 1) and 1 or 2
					}
				end
				if self.clicked then
					local c = self.clicked

					local i0, i1 = c.i, mi
					local j0, j1 = c.j, mj
					if mi < c.i then
						i0, i1 = mi, c.i
					end
					if mj < c.j then
						j0, j1 = mj, c.j
					end

					for i = i0, i1 do
						for j = j0, j1 do
							if tool == "fillrect" or i == i0 or i == i1 or j == j0 or j == j1 then
								local node = self.grid[i][j]
								node.highlight = true
								table.insert(self.selectedNodes, node)
							end
						end
					end
				end
			elseif self.clicked then
				for _, node in ipairs(self.selectedNodes) do
					if self.clicked.mode == 1 then
						node:setTile(self.selectedTile)
					else
						node:clear()
					end
				end
				self.clicked = nil
			end

		end
	--pit placement
	elseif mi == config.grid_h + 1  and mj >= 1 and mj <= config.grid_w then
		if mouse.m1 then
			-- game.walls.down:setHole(mi, mj, true)
			self.pit[mj] = true
		elseif mouse.m2 then
			-- game.walls.down:setHole(mi, mj, false)
			self.pit[mj] = nil
		end
	end
end

-- switches the game to test mode
function EditorState:startTest()
	for _, n in ipairs(self.allNodes) do
		if n.tile and not self.overlap[n.i][n.j] then
			table.insert(game.tiles, n:makeTile())
		end
	end

	game.gates.enter = self.gates.enter
	game.gates.exit = self.gates.exit
	game.gates.enter:activate()
	game.gates.exit:activate()

	--add the holes
	for j, v in pairs(self.pit) do
		game.walls.down:setHole(0, j, true)
	end

	for _, gate in pairs(game.gates) do
		local holes = gate:getOccupied(true)
		local wall = game.walls[gate.dir]
		for _, t in ipairs(holes) do
			wall:setHole(t[1], t[2], true)
		end
	end

	for _, wall in pairs(game.walls) do
		wall:createShapes()
	end

	--set the exit point
	local exit = self.gates.exit
	game.exit = {
		dir = exit.dir,
		coords = exit:getOccupied(true)
	}

	game:push(PlayState:new("test"))
end

function EditorState:draw()
	-- love.graphics.setColor(0.5, 0.5, 0.5, 1)
	-- local rec = love.graphics.rectangle
	-- rec("fill" , 0, config.floor, window.w, config.border_w) --floor
	-- rec("fill" , 0, 0, window.w, config.border_w) --ceiling
	-- rec("fill" , 0, 0, config.border_w, window.h) --left wall
	-- rec("fill" , config.wall_r, 0, config.border_w, window.h) --right wall

	for _, w in pairs(game.walls) do
		w:draw()
	end

	--draw gridlines
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1)
	for i = 1, config.grid_h+1 do
		local y = config.ceil + (i-1) * config.cell_w
		util.lineStipple(0, y, window.w, y, 3, 4)
	end
	for j = 1, config.grid_w+1 do
		local x = config.ceil + (j-1) * config.cell_h
		util.lineStipple(x, 0, x, window.h, 3, 4)
	end

	--draw gridnodes (cells)
	for _, node in ipairs(self.allNodes) do
		node:draw()
	end

	self.gates.enter:draw()
	self.gates.exit:draw()

	for _, node in ipairs(self.allNodes) do
		node:drawHighlight()
	end

	--draw proposed pit
	local dwall = game.walls.down
	local cell_w = config.cell_w
	local border_w = config.border_w
	love.graphics.setColor(0, 0, 0, 1)
	for j, v in pairs(self.pit) do
		love.graphics.rectangle("fill", border_w + (j-1) * cell_w, dwall.y, cell_w, dwall.h)
	end
end

GridNode = class("GridNode")

-- i, j = row, column
function GridNode:initialize(editorstate, i, j)
	self.editorstate = editorstate
	self.i, self.j = i, j
	--the x, y coordinates are located at the center of the cell
	self.x = config.wall_l + (j-0.5)*config.cell_w
	self.y = config.ceil + (i-0.5)*config.cell_h
	self.w, self.h = config.cell_w, config.cell_h
	self.highlight = false
end

function GridNode:setTile(tileKey)
	self.tile = data.tiles[tileKey]
end

function GridNode:clear()
	self.tile = nil
end

function GridNode:makeTile()
	if not self.tile then return nil end

	local class = self.tile.class
	local args = self.tile.args
	local tile = class:new(self.i, self.j, unpack(args))
	return tile
end

function GridNode:draw()
	if self.tile then
		local t = self.tile.editor
		love.graphics.setColor(1, 1, 1, 1)
		draw(t.imgstr, t.rect, self.x, self.y, 0, self.w, self.h)
	end
end

--separated so the highlight can be drawn on top of things
function GridNode:drawHighlight()
	if self.highlight then
		love.graphics.setColor(1, 1, 0, 0.25)
		love.graphics.rectangle(
			"fill", 
			self.x - self.w/2, 
			self.y - self.h/2,
			self.w,
			self.h
		)
	end
end