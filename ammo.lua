Ammo = class("Ammo", Sprite)

function Ammo:initialize(i, j)
	local x, y = getGridPosInv(i, j)
	Sprite.initialize(self, "bullet", nil, 30, 30, x, y)
	self.yi = self.y
	self.timer = 0
end

function Ammo:onPlayerHit(player)
	self.dead = true
	player.gun.state = "ready"
	player.helpless = false
	love.mouse.setCursor(cursors.ready)
end

function Ammo:update(dt)
	self.timer = self.timer + dt
	local y = self.yi + (10 * math.sin(self.timer * 3))
	self:setPos(self.x, math.floor(y))
	-- Sprite.update(self, dt)
end