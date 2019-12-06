Player = class("Player", Sprite)

--if you want to modify the player's gravity in-game, you have to
--respawn the player (restart the level) in order for the change to take effect
Player.gravity = 6000

Player.recoil = 1800 --also temporarily raises the player's speed limit
Player.default_helpless = 0.25 --period of time where player can't move on its own after firing gun
Player.fire_delay = 0.25 --time between shots
Player.jump_spd = 900
Player.move_accel = 5000 --when the player manually moves left or right
Player.air_mult = 0.4 --multiplier for air movement (the player's air control should be weaker than on ground)
Player.move_spd_max = 400 --how fast the player can move horizontally
Player.friction = 3000 --how fast the player slows down on the ground

Player.enable_speed_limit = true 

--Speed Limit
Player.speed_limit = 750 --maximum speed limit for player movement
Player.speed_limit_decay = 10000 --how fast the speed limit reverts to max_speed_limit
Player.speed_limit_decay_delay = 0.05 --how much time before the increased speed limit starts decaying
Player.speed_limit_instant_decay = false --if true then, speed limit reverts instantly after decay delay (ignores the decay value)

function Player:initialize(x, y)
	Sprite.initialize(self, "player", rects.player[1], 20, 40, x or 0, y or 0) --28 52
	-- self:setShape(util.newRectangleShape(self.w, self.h))
	self:setShape(util.newRectangleShape(20, 40))
	self.ay = Player.gravity
	self.speedLimit = Player.speed_limit
	self.touchingGround = false
	self.helpless = false
	self.gun = Gun:new(self)
end

function Player:setHelpless(time)
	self.helpless = true
	self.helplessTimer = time or Player.default_helpless
	self.afterImageTimer = 0
end

--to get the shape's bbox
-- function Player:bbox()
-- 	return Sprite.bbox(self, false)
-- end

--adjust hitbox location?
-- function Player:setShape(shape)
-- 	self:removeShape()
-- 	self.shape = shape
-- 	shape.sprite = self
-- 	self.shape:moveTo(self.x, self.y + 2)
-- 	self.shape:setRotation(self.angle)
-- end

-- --adjust hitbox location?
-- function Player:updateShape()
-- 	if (self.shape) then
-- 		self.shape:moveTo(self.x, self.y + 2)
-- 		self.shape:setRotation(self.angle)
-- 	end
-- end



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

	if not self.touchingGround then
		self:stopAnimation()
	elseif keyright then
		if not self.isAnimating then
			if self.gun.flip then
				self:playAnimation("player_walk_left", true)
			else
				self:playAnimation("player_walk_right", true)
			end
		end
	elseif keyleft then
		if not self.isAnimating then
			if self.gun.flip then
				self:playAnimation("player_walk_right", true)
			else
				self:playAnimation("player_walk_left", true)
			end
		end
	else
		self:stopAnimation()
	end
	

	--Player Physics

	if self.helpless then
		self.helplessTimer = self.helplessTimer - dt
		if self.helplessTimer <= 0 then
			self.helpless = false
		end
		--draw after image
		self.afterImageTimer = self.afterImageTimer - dt
		if self.afterImageTimer <= 0 then
			self.afterImageTimer = self.afterImageTimer + 0.025
			local p = Sprite:new(self.imgstr, self.rect, self.w, self.h, self.x, self.y)
			local mag = self.helplessTimer / Player.default_helpless
			-- p.fade = 1.25 - mag
			p.fade = 0.5
			p.update = function(obj, dt)
				obj.fade = obj.fade + dt * 2
			end
			p.isDead = function(obj)
				return obj.fade >= 1
			end
			p.draw = function(obj)
				shader.glow:send("mag", 1)
				shader.glow:send("target", {1, 0.3, 0.3, 1 - obj.fade})
				love.graphics.setShader(shader.glow)
				Sprite.draw(obj)
				love.graphics.setShader()
			end
			game:emplace("particles2", p)
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
	if Player.enable_speed_limit then
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
	end
	
	self.ay = Player.gravity --debugging

	Sprite.update(self, dt)
	self.gun:update(dt)
end

function Player:draw()
	-- if self.dead then
	-- 	self:setColor(0.3, 0.3, 0.3)
	-- elseif self.helpless then
	-- 	self:setColor(1, 0, 0)
	-- elseif self.touchingGround then
	-- 	self:setColor(0, 1, 0)
	-- else
	-- 	self:setColor(0, 0, 1)
	-- end
	Sprite.draw(self, self.gun.flip)
	self.gun:draw()
end

--Gun class here because only the player will use this gun

Gun = class("Gun", Sprite)

function Gun:initialize(player)
	Sprite.initialize(self, "gun", nil, 76, 26)
	self.player = player
	self:setPos(player:getPos())
	self.muzzleOffset = {dx = 37, dy = -2}
	self.muzzlePoint = {x = 0, y = 0} --to be initialized
	self:setMuzzlePoint()
	self.cooldown = 0

	self.state = "ready" --ready, empty, reloading
	self.reloadTimer = 0
end

function Gun:setMuzzlePoint()
	local mo = self.muzzleOffset
	local mp = self.muzzlePoint
	local dx, dy = mo.dx, mo.dy
	if self.flip then dy = -dy end
	dx, dy = util.rotateVec2(dx, dy, self.angle)
	mp.x = self.x + dx
	mp.y = self.y + dy
end

function Gun:canFire()
	if self.player.helpless then return false end
	if self.state ~= "ready" then return false end
	if mouse.m1 ~= 1 then return false end
	return true
end

function Gun:fire()
	setScreenShake()
	playSound("m1_shot")
	-- playSound("shoot")

	self.state = "empty"
	love.mouse.setCursor(cursors.empty)

	local mp = self.muzzlePoint
	local dx, dy = mouse.x - mp.x, mouse.y - mp.y
	dx, dy = util.normalize(dx, dy)
	if mouse.m2 then
		dx, dy = -dx, -dy
	end

	--get all the collision shapes first
	--could make a function out of this
	
	local shapes = playstate:getRaycastShapes()

	--check for obstruction
	--obstruction occurs when there is an object in between the player's center and muzzle point.
	--if there is an obstruction, then the gun is most likely stuck inside the wall, so it should not fire.
	--or at least not fire a bullet
	local obstructed = false
	local px, py = self.player:getPos()
	for _, shape in ipairs(shapes) do
		local check, t = shape:intersectsRay(px, py, mp.x - px, mp.y - py)
		if check and t > 0 and t < 1 then
			obstructed = true
			break
		end
		--do it backwards in case player is inside a One Way Block
		local check, t = shape:intersectsRay(mp.x, mp.y, px - mp.x, py - mp.y)
		if check and t > 0 and t < 1 then
			obstructed = true
			break
		end
	end

	if obstructed then return end

	--do the raycast
	local tmin = math.huge
	local hitShape = nil
	for _, shape in ipairs(shapes) do
		local check, t = shape:intersectsRay(mp.x, mp.y, dx, dy)
		if check and t > 0 and t < tmin then
			tmin = t
			hitShape = shape
		end
	end
	local tx, ty = mp.x + dx*tmin, mp.y + dy*tmin --shot location
	--the raycast should always hit something since the player is in an enclosed room

	--these shapes will be pierced
	local pierceShapes = {}
	for _, e in ipairs(game.enemies) do
		table.insert(pierceShapes, e.shape)
	end

	for _, shape in pairs(pierceShapes) do
		local check, t = shape:intersectsRay(mp.x, mp.y, dx, dy)
		if check and t > 0 and t < tmin then
			if shape.sprite then
				shape.sprite:onBulletHit()
			end
		end
	end

	--notify object if it exists
	local sprite = hitShape.sprite
	if sprite then
		if sprite.onBulletHit then
			sprite:onBulletHit()
		end
	end

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

	
	self:bulletExplosion(tx, ty)
	--fire the bullet particle effect
	self:bulletTrail(dx, dy, tmin)
	--create impact sparks
	self:bulletImpactSparks(tx, ty, dx, dy, hitShape)
end

--fire a menacing yet harmless bullet
function Gun:bulletTrail(dx, dy, t)
	local mp = self.muzzlePoint
	local bullet = {
		x0 = mp.x,
		y0 = mp.y,
		dx = dx,
		dy = dy,
		tmax = t,
		time = 0.2,
		width = 5,
		color = {1, 1, 0, 1}
	}
	local lines1 = {
		{width = 7, color = {1, 0.5, 0, 1}},
		{width = 5, color = {1, 1, 0, 1}},
		{width = 3, color = {1, 1, 0.75, 1}}
	}
	local lines2 = {
		{width = 2 , color = {1, 1, 1, 1}}
	}
	bullet.lines = lines1
	bullet.update = function(obj, dt)
		obj.time = obj.time - dt
		if obj.time < 0.10 then
			obj.lines = lines2
			if not obj.alpha then
				obj.alpha = 1
			else
				obj.alpha = obj.time / 0.10
			end
		end
	end
	bullet.isDead = function(obj)
		return obj.time <= 0
	end
	bullet.draw = function(obj)
		love.graphics.setLineStyle("smooth")
		for _, line in ipairs(obj.lines) do
			local r, g, b, a = unpack(line.color)
			if obj.alpha then
				a = obj.alpha
			end
			love.graphics.setColor(r, g, b, a)
			love.graphics.setLineWidth(line.width)
			love.graphics.line(
				obj.x0, 
				obj.y0, 
				obj.x0 + obj.dx * obj.tmax, 
				obj.y0 + obj.dy * obj.tmax
			)
		end
	end
	game:emplace("particles", bullet)

	for i = 1, 3 do
		local shock = Sprite:new("shockwave", rects.shockwave[1], 39, 13, mp.x, mp.y)
		-- shock.color = {r = 0, b = 0, g = 0, a = 1}
		shock:setAngle(self.angle + math.pi/2)
		shock:translate(dx*(i-1)*15, dy*(i-1)*15)
		shock.isDead = function(obj)
			return not obj.isAnimating
		end
		shock:playAnimation("shockwave"..(4-i))
		game:emplace("particles", shock)
	end
end

--spawns a small circular explosion at point of impact
function Gun:bulletExplosion(x, y)
	local circle = {
		x = x,
		y = y,
		r = 12,
		dr = 50,
	}
	circle.update = function(obj, dt)
		obj.r = math.max(0, obj.r - obj.dr * dt)
	end
	circle.isDead = function(obj)
		return obj.r == 0
	end
	circle.draw = function(obj)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.circle("fill", obj.x, obj.y, obj.r)
	end
	game:emplace("particles", circle)
end

--generates bullet impact sparks
--currently only works for axis aligned rectangular shapes
function Gun:bulletImpactSparks(px, py, vx, vy, shape)
	--vector reflects vertically or horizontally based on
	--impact point's relative position to the shape's center
	local cx, cy = shape:center()
	local nx, ny

	local x0, y0, x1, y1 = shape:bbox()
	local li = {x0 - px, x1 - px, y0 - py, y1 - py}
	local minIndex = 1
	local minValue = math.abs(li[1])
	for i, v in ipairs(li) do
		v = math.abs(v)
		if v < minValue then
			minIndex = i
			minValue = v
		end
	end

	if minIndex == 1 then
		nx, ny = -1, 0
	elseif minIndex == 2 then
		nx, ny = 1, 0
	elseif minIndex == 3 then
		nx, ny = 0, -1
	elseif minIndex == 4 then
		nx, ny = 0, 1
	end

	-- print(nx.." "..ny)


	if nx == 0 then
		vy = -vy
	else
		vx = -vx
	end

	local rad = util.angleBetween(vx, vy, nx, ny)
	local deg = math.deg(rad)
	deg = 90 - deg
	deg = math.min(45, deg)
	--range: -deg to +deg

	local n = 9 --number of sparks
	local var = math.ceil(deg / n) --variance

	for i = 0, n-1 do
		local deg = (deg * 2 * i)/(n-1) - deg
		if i ~= 0 and i ~= n-1 then
			deg = deg + math.random(-var, var)
		end
		local vx, vy = util.rotateVec(vx, vy, deg)
		local len = math.random(50, 100)
		local spark = {
			x0 = px, --origin
			y0 = py,
			vx = vx, --direction
			vy = vy,
			t0 = 0, --startpoint
			t1 = len, --endpoint
			tspd = len * 2, --catchup
			spd = len * 10,
			timer = 0.3,
			dead = false,
			color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1
			}
		}
		spark.accel = spark.spd * 2
		spark.maxTimer = spark.timer
		spark.update = function(obj, dt)
			obj.timer = math.max(0, obj.timer - dt)
			obj.spd = math.max(10, obj.spd - spark.accel * dt)
			--startpoint will catch up to the endpoint
			obj.t0 = obj.t0 + obj.spd * dt
			obj.t1 = obj.t1 + obj.spd * dt
			obj.t0 = obj.t0 + obj.tspd * dt / 2
			obj.t1 = obj.t1 - obj.tspd * dt / 2
			if obj.t0 > obj.t1 then
				obj.dead = true
			end


			local c = obj.color
			c.b = c.b - (2 * dt)
		end
		spark.isDead = function(obj)
			return obj.dead
		end
		spark.draw = function(obj)
			love.graphics.setLineStyle("rough")
			love.graphics.setLineWidth(3)
			local c = obj.color
			love.graphics.setColor(c.r, c.g, c.b, c.a)
			local x0 = obj.x0 + obj.vx * obj.t0
			local y0 = obj.y0 + obj.vy * obj.t0
			local x1 = obj.x0 + obj.vx * obj.t1
			local y1 = obj.y0 + obj.vy * obj.t1
			love.graphics.line(x0, y0, x1, y1)
		end
		game:emplace("particles", spark)
	end
end

--maybe move some update functions here
function Gun:update(dt)
	local dx, dy = mouse.x - self.player.x, mouse.y - self.player.y
	if mouse.m2 then
		dx, dy = -dx, -dy
	end

	local theta = math.atan2(dy, dx)
	self.angle = theta
	--flip the gun upside down if aiming to the left
	local deg = math.deg(theta)
	self.flip = deg > 90 or deg < -90
	
	self:setPos(self.player:getPos())
	self:setMuzzlePoint()

	if self.state == "empty" then
		if not self.player.helpless and self.player.touchingGround then
			self.state = "reloading"
			self.reloadTimer = 0.25
			playSound("m1_cock")
		end
	elseif self.state == "reloading" then
		self.reloadTimer = self.reloadTimer - dt
		if self.reloadTimer <= 0 then
			self.state = "ready"
			love.mouse.setCursor(cursors.ready)
			self:ejectCasing()
			
		end
	end
	--does nothing when state is "ready"
end

function Gun:ejectCasing()
	local casing = Sprite:new(nil, nil, 10, 5, self.x, self.y)
	casing.color = {r = 1, g = 1, b = 0, a = 1}
	local deg = math.deg(self.angle)
	local mag = 300
	if self.flip then mag = -mag end
	casing.vx, casing.vy = util.rotateVec(0, -mag, deg + math.random(30) - 15)
	casing.ay = 1500
	casing.angle = self.angle

	game:emplace("particles", casing)
end

function Gun:draw()
	Sprite.draw(self, false, self.flip)
	--show the muzzle point for debug
	-- love.graphics.setColor(1, 0, 0, 1)
	-- local mp = self.muzzlePoint
	-- love.graphics.circle("fill", mp.x, mp.y, 2)
end

