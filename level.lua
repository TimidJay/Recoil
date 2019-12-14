Level = class("Level")

--Level is a structure that contains all level data
--I'm undecided whether or not Level should be a singleton
--Maybe level should be the bridge between Editorstate and Playstate

--Level should be in charge of saving/loading files
--Level should be able to create all objects

function Level:initialize(grid_w, grid_h)
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
	for i = 1, self.grid_w do
		local row = {}
		for j = 1, self.grid_h do
			table.insert(row, {})
		end
		table.insert(self.objectGrid, row)
	end
end

function Level:save()
end

--this allows playstate and editorstate to have the same load function
function Level:load()
end

--the walls should surround the playable area
function Level:createWalls()
	local walls = {
		left  = Wall:new("left" , self.x0, self.inner_x0, self.y0, self.y1, self),
		right = Wall:new("right", self.inner_x1, self.x1, self.y0, self.y1, self),
		up    = Wall:new("up"   , self.x0, self.x1, self.y0, self.inner_y0, self),
		down  = Wall:new("down" , self.x0, self.x1, self.inner_y1, self.y1, self)
	}
	return walls
end

--create all objects in objectGrid
--returns a table of lists of objects
function Level:createObjects()
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


--Idea:
--	Maybe Level should have the GridNodes instead of editorstate
--TODO: combine self.tile, self.enemy, self.item together into self.object

GridNode = class("GridNode")

-- i, j = row, column
function GridNode:initialize(editorstate, i, j)
	self.editorstate = editorstate
	self.i, self.j = i, j
	--the x, y coordinates are located at the center of the cell
	self.x = config.wall_l + (j-0.5)*config.cell_w
	self.y = config.ceil + (i-0.5)*config.cell_h
	self.w, self.h = config.cell_w, config.cell_h

	self.tile = nil
	self.enemy = nil
	self.item = nil
	self.actuator = nil
	self.highlight = false
end

function GridNode:setTile(tileKey)
	--tiles and enemies can't occupy the same space
	self.tile = data.tiles[tileKey]
	self.enemy = nil
	self.item = nil
end

function GridNode:setEnemy(enemyKey)
	self.tile = nil
	self.enemy = data.enemies[enemyKey]
	self.acuator = nil
	self.item = nil
end

function GridNode:setItem(itemKey)
	self.tile = nil
	self.enemy = nil
	self.actuator = nil
	self.item = data.items[itemKey]
end

function GridNode:setActuator(value)
	if not value then
		self.actuator = nil
		return
	end
	if self.tile then
		self.actuator = value
		self.actuatorColor = SwitchBlock.colors[value]
	end
end

--generic setter function that combines the above functions


function GridNode:setObject(objType, value)
	if objType == "tile" then
		self:setTile(value)
	elseif objType == "enemy" then
		self:setEnemy(value)
	elseif objType == "item" then
		self:setItem(value)
	elseif objType == "actuator" then
		self:setActuator(value)
	end
end

function GridNode:clear()
	self.tile = nil
	self.enemy = nil
	self.item = nil
	self.actuator = nil
end

function GridNode:makeTile()
	if not self.tile then return nil end

	local class = self.tile.class
	local args = self.tile.args
	local tile = class:new(self.i, self.j, unpack(args))
	tile:setActuator(self.actuator)
	return tile
end

function GridNode:makeEnemy()
	if not self.enemy then return nil end

	local class = self.enemy.class
	local args = self.enemy.args
	local enemy = class:new(self.i, self.j, unpack(args))
	return enemy
end

function GridNode:makeItem()
	if not self.item then return nil end

	local class = self.item.class
	local args = self.item.args
	local item = class:new(self.i, self.j, unpack(args))
	return item
end

function GridNode:draw()
	if self.tile then
		local t = self.tile.editor
		local rad = 0
		if t.deg then
			rad = math.rad(t.deg)
		end
		if t.color then
			love.graphics.setColor(unpack(t.color))
		else
			love.graphics.setColor(1, 1, 1, 1)
		end
		draw(t.imgstr, t.rect, self.x, self.y, rad, self.w, self.h)
	end
	if self.enemy then
		local t = self.enemy.editor
		local rad = 0
		if t.deg then
			rad = math.rad(t.deg)
		end
		draw(t.imgstr, t.rect, self.x, self.y, rad, self.w, self.h)
	end
	if self.item then
		local t = self.item.editor
		local w, h = self.w, self.h
		if t.w and t.h then
			w, h = t.w, t.h
		end
		draw(t.imgstr, t.rect, self.x, self.y, 0, w, h)
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
