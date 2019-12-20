Gate = class("Gate", Sprite)

--Gate has 2 types: enter and exit
--Gates are initially unactivated for use in EditorState
--Gate consists of 3 sprites, left, middle, right

--TODO: Animate the opening and closing of gates

function Gate:initialize(gateType, i, j, dir, level)
	self.type = gateType
	self.level = level

	self.i, self.j = i, j
	self.offset = CELL_WIDTH*2

	local y = self.type == "enter" and 0 or 15
	-- Sprite.initialize(self, "gate", make_rect(0, y, 75, 15), config.cell_w*5, config.cell_w)
	Sprite.initialize(self, nil, nil, CELL_WIDTH*5, CELL_WIDTH)
	self.left = Sprite:new("gate", make_rect(0, y, 15, 15), CELL_WIDTH, CELL_WIDTH)
	self.middle = Sprite:new("gate", make_rect(15, y, 45, 15), CELL_WIDTH*3, CELL_WIDTH)
	self.right = Sprite:new("gate", make_rect(60, y, 15, 15), CELL_WIDTH, CELL_WIDTH)

	self:setShape(util.newRectangleShape(CELL_WIDTH*5, CELL_WIDTH))
	self.left:setShape(util.newRectangleShape(CELL_WIDTH, CELL_WIDTH))
	self.right:setShape(util.newRectangleShape(CELL_WIDTH, CELL_WIDTH))

	self.dir = dir
	self:setPos(getGridPosInv(i, j))
	self:setDirection(dir)
	self.state = "closed"

	self.dragged = false

	--call this outside
	-- self:setOccupiedNodes()
	-- self:setHoles()
end

function Gate:copy()
	local gate = Gate:new(self.type, self.i, self.j, self.dir, self.level)
	return gate
end

function Gate:activate()
	if self.type == "enter" then
		self.state = "open"
		self.timer = 0.2
	else --type == "exit"
		self.state = "open"
	end
end

function Gate:reset()
	self.state = "closed"
	self.timer = nil
end

--for raycasting and collision
function Gate:getShapes()
	if self.state == "open" then
		return {self.left.shape, self.right.shape}
	else
		return {self.shape}
	end
end

--update the three parts of the gate
function Gate:updateComponents()
	local x, y = self:getPos()
	local off = self.offset

	local dirtable = {
		up = {-1, 0},
		down = {1, 0},
		left = {0, -1},
		right = {0, 1}
	}
	local t = dirtable[self.dir]
	self.left:setPos(x - t[1]*off, y - t[2]*off)
	self.middle:setPos(x, y)
	self.right:setPos(x + t[1]*off, y + t[2]*off)

	self.left:setAngle(self.angle)
	self.middle:setAngle(self.angle)
	self.right:setAngle(self.angle)
end

function Gate:setPos(x, y)
	Sprite.setPos(self, x, y)
	self:updateComponents()
end

--use this one instead
function Gate:setPos2(i, j)
	local x, y = getGridPosInv(i, j)
	self:setPos(x, y)
	self.i, self.j = i, j
end

function Gate:setDir(dir)
	self:setDirection(dir)
end

function Gate:setDirection(dir)
	self.dir = dir
	if dir == "up" then
		self:setAngle(math.pi)
	elseif dir == "left" then
		self:setAngle(math.pi/2)
	elseif dir == "down" then
		self:setAngle(0)
	elseif dir == "right" then
		self:setAngle(-math.pi/2)
	end
	self:updateComponents()
end

--places the player behind the gate
--also makes the player fly out of the gate
function Gate:ejectPlayer(player)
	player:setPos(self:getPos())
	local vtable = {
		up = {0, 100},
		down = {0, -800},
		left = {300, 0},
		right = {-300, 0}
	}
	local v = vtable[self.dir]
	player:setVel(v[1], v[2])
	player:setHelpless(0.2)
	player.afterImageTimer = 1000 --disable afterimages
end

function Gate:checkPlayerCollision(player)
	if self.state == "open" then
		local check, dx, dy = self.left:checkSpriteCollision(player)
		if check then
			return true, dx, dy
		end
		check, dx, dy = self.right:checkSpriteCollision(player)
		if check then
			return true, dx, dy
		end
		return false
	else
		--the player can just collide with the big rectangle if the gate is closed
		local check, dx, dy = self:checkSpriteCollision(player)
		if check then
			return true, dx, dy
		end
		return false
	end
end

function Gate:update(dt)
	if self.timer then
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self.timer = nil
			self.state = "closed"
		end
	end
end

function Gate:draw()
	if self.dragged then
		self.left.color.a = 0.5
		self.middle.color.a = 0.5
		self.right.color.a = 0.5
	else
		self.left.color.a = 1
		self.middle.color.a = 1
		self.right.color.a = 1
	end

	self.left:draw()
	if self.state ~= "open" then
		self.middle:draw()
	end
	self.right:draw()
end

--------------------
-- EDITOR METHODS --
--------------------
function Gate:containMouse()
	local bbox = {self:bbox()}
	return util.containPoint(bbox, mouse.cx, mouse.cy)
end

--returns grid coords that are occupied by this gate
--if middle is true, get the middle 3 coordinates only
function Gate:getOccupiedCoords(middle)
	local i, j = getGridPos(self:getPos())
	local t = {}
	local r = middle and 1 or 2
	if self.dir == "up" or self.dir == "down" then
		for d = -r, r do
			table.insert(t, {i, j+d})
		end
	else
		for d = -r, r do
			table.insert(t, {i+d, j})
		end
	end
	return t
end

function Gate:setOccupiedNodes()
	local occupied = {}
	local t = self:getOccupiedCoords()
	local grid = self.level.objectGrid

	for _, v in ipairs(t) do
		local node = grid[v[1]][v[2]]
		occupied[node] = true
	end

	self.occupied = occupied
end

--clears any nodes the gate occupies
function Gate:clearOccupiedNodes()
	for node, _ in pairs(self.occupied) do
		node:clear()
	end
end

--clear the holes at the previous position
--and set the current holes
function Gate:setHoles()
	--not the most efficient but whatever
	local gateType = self.type
	for k, wall in pairs(self.level.walls) do
		for i, v in pairs(wall.holes) do
			if v == gateType then
				wall:setHole(i, i, false)
			end
		end
	end

	local wall = self.level.walls[self.dir]
	local coords = self:getOccupiedCoords(true)
	for _, v in ipairs(coords) do
		wall:setHole(v[1], v[2], self.type)
	end
end