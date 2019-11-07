Player = class("Player", Sprite)

--if you want to modify the player's gravity in-game, you have to
--respawn the player (restart the level) in order for the change to take effect
Player.gravity = 5000

Player.recoil = 2500 --also temporarily raises the player's speed limit
Player.default_helpless = 0.25 --period of time where player can't move on its own after firing gun
Player.fire_delay = 0.25 --time between shots
Player.jump_spd = 900
Player.move_accel = 5000 --when the player manually moves left or right
Player.air_mult = 0.75 --multiplier for air movement (the player's air control should be weaker than on ground)
Player.move_spd_max = 400 --how fast the player can move horizontally
Player.friction = 3000 --how fast the player slows down on the ground

Player.enable_speed_limit = 2 

--mode 1
Player.speed_limit = 1000 --maximum speed limit for player movement
Player.speed_limit_decay = 10000 --how fast the speed limit reverts to max_speed_limit
Player.speed_limit_decay_delay = 0.05 --how much time before the increased speed limit starts decaying
Player.speed_limit_instant_decay = false --if true then, speed limit reverts instantly after decay delay (ignores the decay value)

--mode 2
Player.speed_limit_x = 1200
Player.speed_limit_decay_x = 6000
Player.speed_limit_y = 1200
Player.speed_limit_decay_y = 6000

function Player:initialize(x, y)
	Sprite.initialize(self, "white_pixel", nil, 20, 40, x or 0, y or 0)
	self.ay = Player.gravity
	self.speedLimit = Player.speed_limit
	self.touchingGround = false
	self.helpless = false
	self.gun = Gun:new(self)
end

function Player:setHelpless(time)
	self.helpless = true
	self.helplessTimer = time or Player.default_helpless
end

--checks to see if the player's velocity goes against the separating vector
--might have to change this if the player starts colliding against slopes
function Player:validCollision(dx, dy)
	if dx ~= 0 then
		if dx < 0 then
			return self.vx > 0
		end
		return self.vx < 0
	end
	if dy < 0 then
		return self.vy > 0
	end
	return self.vy < 0
end

--moves the player based on the separating vector
--also sets the player horizontal/vertical velocity to 0
--also checks whether or not the player is colliding with the ground
function Player:handleCollision(dx, dy)
	self:setPos(self.x + dx, self.y + dy)
	if dx ~= 0 then
		self:setVel(0, nil)
	else
		self:setVel(nil, 0)
	end
	if dy < 0 then
		self.touchingGround = true
	end
end

function Player:update(dt)

	if self.gun:canFire() then
		self.gun:fire()
		local dx, dy = mouse.x - self.x, mouse.y - self.y
		local dx, dy = util.normalize(dx, dy)
		if mouse.m2 then
			dx, dy = -dx, -dy
		end
		local spd = Player.recoil
		self:setVel(-dx*spd, -dy*spd)
		self:setHelpless()
		self.speedLimit = Player.recoil
		self.speedLimitDelay = Player.speed_limit_decay_delay
	end

	keyleft = love.keyboard.isDown("a")
	keyright = love.keyboard.isDown("d")
	

	--Player Physics

	if self.helpless then
		self.helplessTimer = self.helplessTimer - dt
		if self.helplessTimer <= 0 then
			self.helpless = false
		end
	else
		
		local max_vx = Player.move_spd_max
		local ax = Player.move_accel
		local mult = self.touchingGround and 1 or Player.air_mult
		--make sure the player is not traveling at a greater speed first
		if keyleft and self.vx >= -max_vx then
			self.vx = math.max(-max_vx, self.vx - mult*ax*dt)
		end
		if keyright and self.vx <= max_vx then
			self.vx = math.min(max_vx, self.vx + mult*ax*dt)
		end
		if keys.space == 1 and self.touchingGround then
			self.vy = -self.jump_spd
		end
	end

	if self.touchingGround then
		-- friction
		local sign = self.vx >= 0 and 1 or -1
		local vx = math.abs(self.vx)
		vx = math.max(vx - Player.friction*dt, 0)
		self.vx = vx * sign
	end

	--speed limit stuff
	if Player.enable_speed_limit == 1 then
		if self.speedLimitDelay then
			self.speedLimitDelay = self.speedLimitDelay - dt
			if self.speedLimitDelay <= 0 then
				self.speedLimitDelay = nil
			end
		else
			if self.speedLimit > Player.speed_limit then
				if Player.speed_limit_instant_decay then
					self.speedLimit = Player.speed_limit
				else
					self.speedLimit = math.max(
						Player.speed_limit,
						self.speedLimit - Player.speed_limit_decay * dt
					)
				end
			end
		end
		local spd = self:getSpeed()
		if spd > self.speedLimit then
			self:scaleVelToSpeed(self.speedLimit)
		end

	elseif Player.enable_speed_limit == 2 then
		--Alternative speed limit
		local limx = Player.speed_limit_x
		local limy = Player.speed_limit_y
		local decayx = Player.speed_limit_decay_x
		local decayy = Player.speed_limit_decay_y
		local sx = self.vx < 0 and -1 or 1
		local sy = self.vy < 0 and -1 or 1
		local vx = math.abs(self.vx)
		local vy = math.abs(self.vy)
		if vx > limx then
			self.vx = sx * math.max(vx - decayx*dt, limx)
		end
		if vy > limy then
			self.vy = sy * math.max(vy - decayy*dt, limy)
		end
	end
	self.ay = Player.gravity --debugging

	Sprite.update(self, dt)
	self.gun:update(dt)
end

function Player:draw()
	if self.helpless then
		self:setColor(1, 0, 0)
	elseif self.touchingGround then
		self:setColor(0, 1, 0)
	else
		self:setColor(0, 0, 1)
	end
	Sprite.draw(self)
	self.gun:draw()
end

--Gun class here because only the player will use this gun

Gun = class("Gun", Sprite)

function Gun:initialize(player)
	Sprite.initialize(self, "gun", nil, 57, 17)
	self.player = player
	self:setPos(player:getPos())
	self.muzzleOffset = {dx = 27, dy = -2}
	self.muzzlePoint = {x = self.x, y = self.y}
	self:setMuzzlePoint()
	self.cooldown = 0
end

function Gun:setMuzzlePoint()
	local mo = self.muzzleOffset
	local mp = self.muzzlePoint
	local dx, dy = mo.dx, mo.dy
	dx, dy = util.rotateVec2(dx, dy, self.angle)
	mp.x = self.x + dx
	mp.y = self.y + dy
end

function Gun:canFire()
	if self.cooldown > 0 then return false end
	if mouse.m1 ~= 1 then return false end
	return true
end

function Gun:fire()
	self.cooldown = Player.fire_delay

	local mp = self.muzzlePoint
	local dx, dy = mouse.x - mp.x, mouse.y - mp.y
	dx, dy = util.normalize(dx, dy)
	if mouse.m2 then
		dx, dy = -dx, -dy
	end

	--get all the collision shapes first
	--could make a function out of this
	local tmin = math.huge
	local shapes = {}
	for _, block in ipairs(game.tiles) do
		table.insert(shapes, block.shape)
	end
	for _, w in pairs(game.walls) do
		table.insert(shapes, w.shape)
	end
	for _, gate in pairs(game.gates) do
		for _, s in ipairs(gate:getShapes()) do
			table.insert(shapes, s)
		end
	end

	--check for obstruction
	--obstruction occurs when there is an object in between the player's center and muzzle point.
	--if there is an obstruction, then the gun is most likely stuck inside the wall, so it should not fire.
	local obstructed = false
	local px, py = self.player:getPos()
	for _, shape in ipairs(shapes) do
		local check, t = shape:intersectsRay(px, py, mp.x - px, mp.y - py)
		if check and t > 0 and t < 1 then
			obstructed = true
			break
		end
	end

	if obstructed then return end

	--do the raycast
	for _, shape in ipairs(shapes) do
		local check, t = shape:intersectsRay(mp.x, mp.y, dx, dy)
		if check and t > 0 then
			tmin = math.min(tmin, t)
		end
	end
	local tx, ty = mp.x + dx*tmin, mp.y + dy*tmin --shot location

	--the raycast should always hit something since the player is in an enclosed room
	--debug hit marker
	local hit = Sprite:new("hitmarker", nil, 10, 10, tx, ty)
	hit.deathTimer = 2
	hit.update = function(obj, dt)
		obj.deathTimer = obj.deathTimer - dt
		if obj.deathTimer <= 0 then
			obj.dead = true
		end
		Sprite.update(obj, dt)
	end
	game:emplace("particles", hit)

	--fire the bullet particle effect
	self:fireBullet(dx, dy, tmin)
end

--fire a menacing yet harmless bullet
function Gun:fireBullet(dx, dy, t)
	local mp = self.muzzlePoint
	local bullet = {
		x0 = mp.x,
		y0 = mp.y,
		dx = dx,
		dy = dy,
		t0 = 0,
		t1 = 0,
		tmax = t,
		phase = 0,
		width = 3,
		color = {1, 1, 0, 1}
	}

	bullet.tspd1 = 8000
	bullet.tspd2 = 4000
	--First the line segment will extend until it hits the target
	--Then the line segment will shrink from the muzzle until it dissapears
	bullet.update = function(obj, dt)
		if obj.phase == 0 then
			obj.t1 = obj.t1 + obj.tspd1 * dt
			if obj.t1 >= obj.tmax then
				obj.t1 = obj.tmax
				obj.phase = 1
			end
		elseif obj.phase == 1 then
			obj.t0 = obj.t0 + obj.tspd2 * dt
			if obj.t0 >= obj.tmax then
				obj.t0 = obj.tmax
				obj.phase = 2
			end
		end
	end
	bullet.isDead = function(obj)
		return obj.phase == 2
	end
	bullet.draw = function(obj)
		love.graphics.setColor(unpack(obj.color))
		love.graphics.setLineWidth(obj.width)
		--the length of the line will change constantly
		love.graphics.line(
			obj.x0 + obj.dx * obj.t0, 
			obj.y0 + obj.dy * obj.t0, 
			obj.x0 + obj.dx * obj.t1, 
			obj.y0 + obj.dy * obj.t1
		)
	end
	game:emplace("particles", bullet)
end

--maybe move some update functions here
function Gun:update(dt)
	local dx, dy = mouse.x - self.player.x, mouse.y - self.player.y
	if mouse.m2 then
		dx, dy = -dx, -dy
	end
	local theta = math.atan2(dy, dx)
	self.angle = theta
	self:setPos(self.player:getPos())
	self:setMuzzlePoint()
	self.cooldown = self.cooldown - dt
end

function Gun:draw()
	Sprite.draw(self)
	--show the muzzle point for debug
	-- love.graphics.setColor(1, 0, 0, 1)
	-- local mp = self.muzzlePoint
	-- love.graphics.circle("fill", mp.x, mp.y, 2)
end

