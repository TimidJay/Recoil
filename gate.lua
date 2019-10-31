Gate = class("Gate", Sprite)

--Gate has 2 types: enter and exit
--type() is a builtin function so don't use it
--Gates are initially unactivated for use in EditorState
function Gate:initialize(gateType, i, j, dir, activate)
	self.type = gateType
	local y = self.type == "enter" and 0 or 15
	Sprite.initialize(self, "gate", make_rect(0, y, 75, 15), config.cell_w*5, config.cell_w)
	self.i, self.j = i, j
	self:setPos(getGridPosInv(i, j))
	self:setDirection(dir)
	self.state = "open"

	if activate then
		self:activate()
	end
end

function Gate:activate()
end

--places the player behind the gate
--also makes the player fly out of the gate
function Gate:ejectPlayer(player)
	player:setPos(self:getPos())
	local vtable = {
		up = {0, 100},
		down = {0, -600},
		left = {300, 0},
		right = {-300, 0}
	}
	local v = vtable[self.dir]
	player:setVel(v[1], v[2])
end

function Gate:checkPlayerCollision(player)
end

function Gate:draw()
	Sprite.draw(self)
	if self.state == "open" then
		local cw = config.cell_w
		local x, y = self.x, self.y
		local dx, dy = -3*cw/2, -cw/2
		local w, h = cw*3, cw
		if self.dir == "left" or self.dir == "right" then
			dx, dy = dy, dx
			w, h = h, w
		end
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle("fill", x+dx, y+dy, w, h)
	end
end

--editor function
function Gate:containMouse()
	local bbox = {self:bbox()}
	return util.containPoint(bbox, mouse.x, mouse.y)
end

--returns grid coords that are occupied by this gate
function Gate:getOccupied()
	local i, j = getGridPos(self:getPos())
	local t = {}
	if self.dir == "up" or self.dir == "down" then
		for d = -2, 2 do
			table.insert(t, {i, j+d})
		end
	else
		for d = -2, 2 do
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
end