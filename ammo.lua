Ammo = class("Ammo", Sprite)

function Ammo:initialize(i, j)
	local x, y = getGridPosInv(i, j)
	Sprite.initialize(self, "bullet", nil, 30, 30, x, y)
end

function Ammo:onPlayerHit(player)
	self.dead = true
	player.gun.state = "ready"
	love.mouse.setCursor(cursors.ready)
end