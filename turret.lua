Turret = class("Turret", Sprite)

local turret_rect = {
	make_rect(0, 0, 15, 15),
	make_rect(15, 0, 15, 15)
}

local dir_table = {
	up = 0,
	right = 90,
	down = 180,
	left = 270
}

local offset_table = {
	up = {0, 6},
	right = {-6, 0},
	down = {0, -6},
	left = {6, 0}
}

function Turret:initialize(i, j, dir)
	local x, y = getGridPosInv(i, j)
	Sprite.initialize(self, "turret", turret_rect[1], 30, 30, x, y)
	self.dir = dir
	self:setAngle(math.rad(dir_table[dir]))
	self:setShape(shapes.newCircleShape(0, 0, 15))

	self.state = "idle" --"idle", "lockon", "firing"

	local off = offset_table[dir]
	self.offx, self.offy = off[1], off[2]
	self.cx, self.cy = self.x + self.offx, self.y + self.offy

	self.gun = Sprite:new("turret", turret_rect[2], 30, 30, self.x, self.y)
	self.gun.angle = self.angle

	self.aim_dx = 0
	self.aim_dy = 0
	self.aim_len = 1

	self.lockOnTimerMax = 1
	self.lockOnTimer = 0
	self.fireDelayMax = 0.1
	self.fireDelay = 0
end

function Turret:updateShape()
	if self.shape then
		local dx, dy = 0, 12
		dx, dy = util.rotateVec2(dx, dy, self.angle)
		self.shape:moveTo(self.x + dx, self.y + dy)
		self.shape:setRotation(self.angle)
	end
end

function Turret:onBulletHit()
	self.dead = true
end

--aim at player
function Turret:aim()
	local player = playstate.player
	local gun = self.gun

	local px, py = player:getPos()
	local cx, cy = self.cx, self.cy
	local dx, dy = px - cx, py - cy

	self.aim_len = util.dist(dx, dy)
	dx, dy = util.normalize(dx, dy)

	-- local rad = -math.atan2(dx, dy) + math.pi
	-- gun.angle = rad

	self.aim_dx = dx
	self.aim_dy = dy
end

--perform raycast
--if dx and dy are not provided, then use self.aim_dx and self.aim_dy
--returns tmin, tplayer(either a number or nil)
function Turret:raycast(x0, y0, dx, dy)
	if not x0 then
		x0, y0 = self.cx, self.cy
		dx, dy = self.aim_dx, self.aim_dy
	end

	local player = playstate.player
	local shapes = playstate:getRaycastShapes()

	local tmin = math.huge
	for _, shape in ipairs(shapes) do
		local check, t = shape:intersectsRay(x0, y0, dx, dy)
		if check and t > 0 and t < tmin then
			tmin = t
		end
	end

	local check, tplayer = player.shape:intersectsRay(x0, y0, dx, dy)
	if check and tplayer < tmin then
		return tmin, tplayer
	end
	return tmin
end

--fire a laser shot at the player with some spread
function Turret:fire()
	local dx, dy = self.aim_dx, self.aim_dy

	--get muzzle point
	local mlen = 14
	local mpx = self.cx + dx * mlen
	local mpy = self.cy + dy * mlen

	--get firing vector with spread
	local variance = 2
	--use the gaussian distribution because
	local deg = math.sqrt(-2 * variance * math.log(math.random())) *
                math.cos(2 * math.pi * math.random())
	dx, dy = util.rotateVec(dx, dy, deg)

	--do the raycast
	local tmin, tplayer = self:raycast(mpx, mpy, dx, dy)

	if tplayer then playstate.player.dead = true end

	local bullet = {
		x0 = mpx,
		y0 = mpy,
		x1 = mpx + tmin * dx,
		y1 = mpy + tmin * dy,
		time = 0.1,
		alpha = 1,
		width = 2
	}
	bullet.maxTime = bullet.time

	bullet.update = function(obj, dt)
		obj.time = obj.time - dt
		obj.alpha = obj.time / obj.maxTime
	end
	bullet.isDead = function(obj)
		return obj.time <= 0
	end
	bullet.draw = function(obj)
		love.graphics.setLineStyle("smooth")
		love.graphics.setLineWidth(obj.width)
		love.graphics.setColor(1, 1, 0, obj.alpha)
		love.graphics.line(
			obj.x0, obj.y0, obj.x1, obj.y1
		)
	end
	game:emplace("particles", bullet)


end

function Turret:update(dt)
	Sprite.update(self, dt)
	self:aim()
	local tmin, tplayer = self:raycast()
	if tplayer then
		--lock on!
		self.state = "lockon"
		self.lockOnTimer = self.lockOnTimer + dt
		if self.lockOnTimer >= self.lockOnTimerMax then
			self.state = "firing"
			self.fireDelay = self.fireDelay - dt
			if self.fireDelay <= 0 then
				self:fire()
				self.fireDelay = self.fireDelayMax + self.fireDelay
			end
		end
		self.gun.angle = -math.atan2(self.aim_dx, self.aim_dy) + math.pi
	else
		--no line of sight
		self.state = "idle"
		self.lockOnTimer = 0
		self.fireDelay = 0
	end
	local gun = self.gun
	-- gun.angle = gun.angle + 1 * dt

	local dx, dy = 0, -6
	dx, dy = util.rotateVec2(dx, dy, gun.angle)
	gun:setPos(self.cx + dx, self.cy + dy)
end

function Turret:draw()
	Sprite.draw(self)

	--draw aiming laser
	if self.state == "lockon" then
		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.setLineWidth(2)
		love.graphics.setLineStyle("smooth")
		local x0, y0 = self.cx, self.cy
		local x1, y1 = x0 + self.aim_dx * self.aim_len, y0 + self.aim_dy * self.aim_len
		love.graphics.line(x0, y0, x1, y1)
	end

	self.gun:draw()

	-- self.shape:draw()
end