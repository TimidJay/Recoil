FallingBlock = class("FallingBlock", Block)

--Falling block drops in proximity below, die if falls on player

--NOTE: FallingBlock takes grid coordinates i, j instead of pixel coords x, y
--Unlike other objects, Blocks and other tiles should remain static and grid-aligned
function FallingBlock:initialize(i, j)
	local imgstr = "fallingblock"
	local rect = nil
	local x = config.wall_l + (j-0.5)*config.cell_w
	local y = config.ceil + (i-0.5)*config.cell_h
	local falling = false
	Sprite.initialize(self, imgstr, rect, 30, 30, x, y)
	self.i, self.j = i, j
	--the initial position of this shape won't matter
	--because it will immediately be moved to the sprite
	local shape = util.newRectangleShape(30, 30)
	self:setShape(shape)
end





--check if player and block intersects
--also returns horizontal and vertical separation vectors
function FallingBlock:checkPlayerCollision(player)
	return self:checkSpriteCollision(player)
end

function FallingBlock:checkBelow(player)
	if self.i == player.i and self.j - player.j <= 5 then
		self.falling = true
	end
end

function DeathBlock:onPlayerHit(player)
	if self.i == player.i and self.j - player.j == 1 then
		player.dead = true
	end
end

-- TODO: figure out how to move block until it hits ground
-- TODO: check for other blocks
function FallingBlock:fall(player)
	self.i = self.i + 1
end