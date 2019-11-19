DeathBlock = class("DeathBlock", Block)

-- Die on contact with a DeathBlock

--NOTE: DeathBlock takes grid coordinates i, j instead of pixel coords x, y
--Unlike other objects, Blocks and other tiles should remain static and grid-aligned
function DeathBlock:initialize(i, j)
	local imgstr = "death_brick"
	local rect = nil
	local x = config.wall_l + (j-0.5)*config.cell_w
	local y = config.ceil + (i-0.5)*config.cell_h
	Sprite.initialize(self, imgstr, rect, 30, 30, x, y)
	self.i, self.j = i, j
	--the initial position of this shape won't matter
	--because it will immediately be moved to the sprite
	local shape = util.newRectangleShape(30, 30)
	self:setShape(shape)
end


--check if player and block intersects
--also returns horizontal and vertical separation vectors
function DeathBlock:checkPlayerCollision(player)
	return self:checkSpriteCollision(player)
end

function DeathBlock:onPlayerHit(player)
	player.dead = true
end