Gate = class("Gate", Sprite)

--Gate has 2 types: enter and exit
--Gates are initially unactivated for use in EditorState
--Gate consists of 3 sprites, left, middle, right
function Gate:initialize(gateType, i, j, dir, activate)
	self.type = gateType
	local y = self.type == "enter" and 0 or 15
	local cell_w = config.cell_w
	-- Sprite.initialize(self, "gate", make_rect(0, y, 75, 15), config.cell_w*5, config.cell_w)
	Sprite.initialize(self, nil, nil, cell_w*5, cell_w)
	self.left = Sprite:new("gate", make_rect(0, y, 15, 15), cell_w, cell_w)
	self.middle = Sprite:new("gate", make_rect(15, y, 45, 15), cell_w*3, cell_w)
	self.right = Sprite:new("gate", make_rect(60, y, 15, 15), cell_w, cell_w)

	self:setShape(util.newRectangleShape(cell_w*5, cell_w))
	self.left:setShape(util.newRectangleShape(cell_w, cell_w))
	self.right:setShape(util.newRectangleShape(cell_w, cell_w))

	self.offset = cell_w*2
	self.dir = "down"

	self.i, self.j = i, j
	self:setPos(getGridPosInv(i, j))
	self:setDirection(dir)
	self.state = "closed"

	if activate then
		self:activate()
	end
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
	self.left:draw()
	if self.state ~= "open" then
		self.middle:draw()
	end
	self.right:draw()
end

--editor function
function Gate:containMouse()
	local bbox = {self:bbox()}
	return util.containPoint(bbox, mouse.x, mouse.y)
end

--returns grid coords that are occupied by this gate
--if middle is true, get the middle 3 coordinates only
function Gate:getOccupied(middle)
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