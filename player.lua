Player = class("Player", Sprite)

--if you want to modify the player's gravity in-game, you have to
--respawn the player (restart the level) in order for the change to take effect
Player.gravity = 4000

Player.recoil = 1500
Player.default_helpless = 0.25 --period of time where player can't move on its own after firing gun
Player.fire_delay = 0.25 --time between shots
Player.jump_spd = 800
Player.move_accel = 6000 --when the player manually moves left or right
Player.air_mult = 0.5 --multiplier for air movement (the player's air control should be weaker than on ground)
Player.move_spd_max = 400 --how fast the player can move horizontally
Player.friction = 3000 --how fast the player slows down on the ground

function Player:initialize(x, y)
	Sprite.initialize(self, "white_pixel", nil, 20, 40, x or 0, y or 0)
	self.ay = Player.gravity
	self.touchingGround = false
	self.gun = Gun:new(self)
	self.fireDelay = 0
	self.helpless = false
end

function Player:setHelpless(time)
	self.helpless = true
	self.helplessTimer = time or Player.default_helpless
end

function Player:update(dt)
	local dx, dy = mouse.x - self.x, mouse.y - self.y

	if mouse.m2 then
		dx, dy = -dx, -dy
	end

	self.fireDelay = self.fireDelay - dt

	local theta = math.atan2(dy, dx)
	self.gun.angle = theta
	if mouse.m1 == 1 and self.fireDelay <= 0 then
		local spd = Player.recoil
		local vx, vy = util.normalize(dx, dy)
		self:setVel(-vx*spd, -vy*spd)

		--temporary bullet
		local ray = {
			x1 = self.x,
		    y1 = self.y,
			x2 = self.x + dx * 2000,
			y2 = self.y + dy * 2000,
			vx = vx,
			vy = vy,
			t = 0.05
		}
		self.ray = ray

		--raycasting
		local tmin = math.huge
		for _, block in ipairs(game.tiles) do
			local shape = block.shape
			local check, t = shape:intersectsRay(ray.x1, ray.y1, ray.vx, ray.vy)
			if check and t > 0 then
				tmin = math.min(tmin, t)
			end
		end
		for _, shape in pairs(game.wallShapes) do
			local check, t = shape:intersectsRay(ray.x1, ray.y1, ray.vx, ray.vy)
			if check and t > 0 then
				tmin = math.min(tmin, t)
			end
		end
		if tmin ~= math.huge then
			print(tmin)
		end

		--debug hit marker
		local px, py = vx*tmin, vy*tmin
		local hit = Sprite:new("hitmarker", nil, 10, 10, self.x + vx*tmin, self.y + vy*tmin)
		hit.deathTimer = 2
		hit.update = function(obj, dt)
			obj.deathTimer = obj.deathTimer - dt
			if obj.deathTimer <= 0 then
				obj.dead = true
			end
			Sprite.update(obj, dt)
		end
		game:emplace("particles", hit)

		self:setHelpless()
		self.fireDelay = Player.fire_delay
	end

	if self.ray then
		self.ray.t = self.ray.t - dt
		if self.ray.t <= 0 then
			self.ray = nil
		end
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
	if self.ray then
		local r = self.ray
		love.graphics.setColor(1, 1, 0, 1)
		love.graphics.line(r.x1, r.y1, r.x2, r.y2)
	end
end

--Gun class here because only the player will use this gun

Gun = class("Gun", Sprite)

function Gun:initialize(player)
	Sprite.initialize(self, "gun", nil, 57, 17)
	self:setPos(player:getPos())
	self.player = player
end

--maybe move some update functions here
function Gun:update(dt)
	self:setPos(self.player:getPos())
end

