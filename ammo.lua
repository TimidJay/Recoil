Ammo = class("Ammo", Sprite)

function Ammo:initialize(i, j)
	local x, y = getGridPosInv(i, j)
	Sprite.initialize(self, "bullet", nil, 30, 30, x, y)
	self.yi = self.y
	self.floatTimer = 0
	self.tangible = true
	self.respawnTimer = 0
end

function Ammo:onPlayerHit(player)
	self.tangible = false
	self.respawnTimer = 3
	player.gun.state = "ready"
	player.helpless = false
	love.mouse.setCursor(cursors.ready)
end

function Ammo:update(dt)
	self.floatTimer = self.floatTimer + dt
	local y = self.yi + (10 * math.sin(self.floatTimer * 3))
	self:setPos(self.x, math.floor(y))

	if not self.tangible then
		self.respawnTimer = self.respawnTimer - dt
		if self.respawnTimer <= 0 then
			self.tangible = true
		end
	end
	-- Sprite.update(self, dt)
end

function Ammo:draw()
	if self.tangible then
		Sprite.draw(self)
	end
end