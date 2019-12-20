Level = class("Level")

--Level should only be directly modified by EditorState

--Level is a structure that contains all level data
--I'm undecided whether or not Level should be a singleton
--Maybe level should be the bridge between Editorstate and Playstate

--Level should be in charge of saving/loading files
--Level should be able to create all objects for playing

function Level:initialize(grid_w, grid_h, no_border)
	--grid_w is how many cells wide
	--width is how wide the playable area is in pixels
	--fullWidth is how wide the level is including walls
	self.grid_w = grid_w or 30
	self.grid_h = grid_h or 20
	self.width = self.grid_w * CELL_WIDTH
	self.height = self.grid_h * CELL_WIDTH
	self.fullWidth = self.width + WALL_WIDTH * 2
	self.fullHeight = self.height + WALL_WIDTH * 2

	--absolute edges of the level + walls
	self.x0, self.y0 = 0, 0
	self.x1, self.y1 = self.fullWidth, self.fullHeight

	--edges of the playable area
	self.inner_x0 = WALL_WIDTH
	self.inner_y0 = WALL_WIDTH
	self.inner_x1 = WALL_WIDTH + self.width
	self.inner_y1 = WALL_WIDTH + self.height

	--object grid contains tiles, enemies, and other objects
	--currently only one object can occupy a cell at a time
	--not sure if that will change later 
	self.objectGrid = {}
	self.allNodes = {}
	for i = 1, self.grid_h do
		local row = {}
		for j = 1, self.grid_w do
			local node = GridNode:new(self, i, j)
			table.insert(row, node)
			table.insert(self.allNodes, node)
		end
		table.insert(self.objectGrid, row)
	end

	--walls will remain static for the entire level
	--so they can be created here
	--Don't forget to initialize their shapes later
	self:initializeWalls()
	self:initializeGates()

	--initialize a border of blocks
	if not no_border then
		for i = 1, self.grid_h do
			for j = 1, self.grid_w do
				if (i == 1 or i == self.grid_h) or (j == 1 or j == self.grid_w) then
					local node = self.objectGrid[i][j]
					if not self.gates.enter.occupied[node] and not self.gates.exit.occupied[node] then
						node:setObject("tile", "block")
					end
				end
			end
		end
	end
end

function Level:initializeWalls()
	local walls = {
		left  = Wall:new("left" , self.x0, self.inner_x0, self.y0, self.y1, self),
		right = Wall:new("right", self.inner_x1, self.x1, self.y0, self.y1, self),
		up    = Wall:new("up"   , self.x0, self.x1, self.y0, self.inner_y0, self),
		down  = Wall:new("down" , self.x0, self.x1, self.inner_y1, self.y1, self)
	}
	self.walls = walls
end

function Level:initializeGates()
	local ci = math.floor(self.grid_h / 2) + 1
	local gates = {
		enter = Gate:new("enter", ci, 1, "left", self),
		exit = Gate:new("exit", ci, self.grid_w, "right", self)
	}
	gates.enter:setOccupiedNodes()
	gates.exit:setOccupiedNodes()
	gates.enter:setHoles()
	gates.exit:setHoles()
	self.gates = gates
end

--these 2 are class functions, not methods
function Level.save(level, filename)
	local file = love.filesystem.newFile("levels/"..filename)
	file:open("w")

	local line = function(str)
		file:write(str.."\n")
	end
	local quote = function(str)
		return "\""..str.."\""
	end

	line("local levelData = {}")
	line("levelData.grid_w = "..level.grid_w)
	line("levelData.grid_h = "..level.grid_h)

	line("levelData.objects = {")
	for _, n in ipairs(level.allNodes) do
		if n.object then
			local s = "\t{"..n.i..", "..n.j..", "..quote(n.objType)..", "..quote(n.object.key)
			if n.objType == "tile" and n.actuator then
				s = s..", "..quote(n.actuator).."},"
			else
				s = s.."},"
			end
			line(s)
		end
	end
	line("}")

	--can be expanded to include holes from all sides of the wall
	line("levelData.holes = {")
	local s = "\tdown = {"
	local dholes = level.walls.down.holes
	for h, v in pairs(dholes) do
		if v == "normal" then
			s = s..h..","
		end
	end
	line(s.."}\n}")

	local en = level.gates.enter
	local ex = level.gates.exit
	line("levelData.gates = {")
	line("\tenter = {"..en.i..", "..en.j..", "..quote(en.dir).."},")
	line("\texit = {"..ex.i..", "..ex.j..", "..quote(ex.dir).."},")
	line("}")

	line("return levelData")

	file:close()
end

--returns a level object or nil if loading failed
function Level.load(filename, is_default)
	if is_default then
		filename = "default_levels/"..filename
	else
		filename = "levels/"..filename
	end
	local chunk = love.filesystem.load(filename)
	if not chunk then
		print("ERROR: File "..filename.." not found!")
		return nil
	end

	local levelData = chunk()
	
	local level = Level:new(levelData.grid_w, levelData.grid_h, true)

	for _, t in ipairs(levelData.objects) do
		local i, j = t[1], t[2]
		local objType = t[3]
		local object = t[4]
		local actuator = t[5]
		local node = level.objectGrid[i][j]
		node:setObject(objType, object)
		if actuator then
			node:setObject("actuator", object)
		end
	end

	local dwall = level.walls.down
	for _, h in ipairs(levelData.holes.down) do
		dwall:setHole(h, h, "normal")
	end

	for k, gate in pairs(level.gates) do
		local t = levelData.gates[k]
		gate:setPos2(t[1], t[2])
		gate:setDir(t[3])
		gate:setOccupiedNodes()
		gate:setHoles()
	end

	return level
end

function Level:boundCheck(i, j)
	return i >= 1 and i <= self.grid_h and j >= 1 and j <= self.grid_w
end

function Level:checkOutOfBounds(player)
	local px, py = player:getPos()
	local pw, ph = player:getDim()
	pw, ph = pw/2, ph/2
	local x0, x1, y0, y1 = self.x0, self.x1, self.y0, self.y1
	return px+pw < x0 or px-pw > x1 or py+ph < y0 or py-ph > y1
end

--sets up all of the game objects for playing
function Level:play()
	self:createObjects()
	self:copyWalls()
	self:copyGates()
end

--create all objects in objectGrid
--returns a table of lists of objects
function Level:createObjects()
	for _, n in ipairs(self.allNodes) do
		local obj = n:makeObject()
		if obj then
			local t = n.objType
			if t == "tile" then
				table.insert(game.tiles, obj)
			elseif t == "enemy" then
				table.insert(game.enemies, obj)
			elseif t == "item" then
				table.insert(game.items, obj)
			end
		end
	end
end

--copy walls and add pits
--Gate holes should be added after
function Level:copyWalls()
	for k, wall in pairs(self.walls) do
		local w2 = wall:copy()
		game.walls[k] = w2
		w2:activate()
	end
end

--copy gates and activate them
function Level:copyGates()
	for k, gate in pairs(self.gates) do
		local g2 = gate:copy()
		game.gates[k] = g2
		g2:activate()
	end
end

--add an actual background graphic later
function Level:drawBackground()
	local x = self.x0
	local y = self.y0
	local w = self.fullWidth
	local h = self.fullHeight

	love.graphics.setColor(0.8, 0.8, 0.8, 1)
	love.graphics.rectangle("fill", x, y, w, h)
end

GridNode = class("GridNode")

-- i, j = row, column
function GridNode:initialize(level, i, j)
	self.level = level
	self.i, self.j = i, j
	--the x, y coordinates are located at the center of the cell
	self.x = level.inner_x0 + (j-0.5) * CELL_WIDTH
	self.y = level.inner_y0 + (i-0.5)* CELL_WIDTH
	self.w, self.h = CELL_WIDTH, CELL_WIDTH

	self.objectType = nil
	self.object = nil
	self.actuator = nil
	self.highlight = false
end

function GridNode:setObject(objType, key)
	if objType == "actuator" then
		if self.objType == "tile" then
			self.actuator = key
			self.actuatorColor = SwitchBlock.colors[key]
		end
	else
		self.objType = objType
		self.object = data[objType][key]
		self.actuator = nil
	end
end

function GridNode:clear()
	self.objType = nil
	self.object = nil
	self.actuator = nil
end

--does not return its type
function GridNode:makeObject()
	if not self.object then return nil end

	local class = self.object.class
	local args = self.object.args
	local obj = class:new(self.i, self.j, unpack(args))

	if self.objType == "tile" and self.actuator then
		obj:setActuator(self.actuator)
	end

	return obj
end

function GridNode:draw()
	if self.object then
		local t = self.object.editor
		local w, h = self.w, self.h
		if t.w and t.h then
			w, h = t.w, t.h
		end
		local rad = 0
		if t.deg then
			rad = math.rad(t.deg)
		end
		if t.color then
			love.graphics.setColor(unpack(t.color))
		else
			love.graphics.setColor(1, 1, 1, 1)
		end
		draw(t.imgstr, t.rect, self.x, self.y, rad, w, h)
	end
	if self.actuator then
		love.graphics.setColor(unpack(self.actuatorColor))
		draw("actuator", nil, self.x, self.y, 0, self.w, self.h)
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
