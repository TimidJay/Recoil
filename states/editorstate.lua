EditorState = class("EditorState")

function EditorState:initialize()
	--grid starts at the top-left corner
	self.grid = {}
	self.allNodes = {} --allows for easy iteration across all nodes
	for i = 1, config.grid_h do
		local row = {}
		for j = 1, config.grid_w do
			local node = GridNode:new(self, i, j)
			table.insert(row, node)
			table.insert(self.allNodes, node)
		end
		table.insert(self.grid, row)
	end
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

	if boundCheck(mi, mj) then
		local node = self.grid[mi][mj]
		node.highlight = true

		if mouse.m1 then
			node:setTile()
		elseif mouse.m2 then
			node:clear()
		end
	end
end

-- switches the game to test mode
function EditorState:startTest()

	for _, n in ipairs(self.allNodes) do
		if n.tile then
			local block = Block:new(n.i, n.j)
			table.insert(game.tiles, block)
		end
	end

	game:push(PlayState:new("test"))
end

function EditorState:draw()
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	local rec = love.graphics.rectangle
	rec("fill" , 0, config.floor, window.w, config.border_w) --floor
	rec("fill" , 0, 0, window.w, config.border_w) --ceiling
	rec("fill" , 0, 0, config.border_w, window.h) --left wall
	rec("fill" , config.wall_r, 0, config.border_w, window.h) --right wall

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
	for i, row in ipairs(self.grid) do
		for j, node in ipairs(row) do
			node:draw()
		end
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

function GridNode:update(dt)
	--use this if we need animations for the cells
end

function GridNode:setTile()
	self.tile = {imgstr = "brick", rect = nil}
end

function GridNode:clear()
	self.tile = nil
end

function GridNode:draw()
	if self.tile then
		local t = self.tile
		love.graphics.setColor(1, 1, 1, 1)
		draw(t.imgstr, t.rect, self.x, self.y, 0, self.w, self.h)
	end

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