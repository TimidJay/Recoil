Block = class("Block", Sprite)

--Block is a standard solid tile that does nothing

--NOTE: Block takes grid coordinates i, j instead of pixel coords x, y
--Unlike other objects, Blocks and other tiles should remain static and grid-aligned
function Block:initialize(i, j)
	local imgstr = "brick"
	local rect = nil
	local x = config.wall_l + (j-0.5)*config.cell_w
	local y = config.ceil + (i-0.5)*config.cell_h
	Sprite.initialize(self, imgstr, rect, 30, 30, x, y)
	self.i, self.j = i, j
	--the initial position of this shape won't matter
	--because it will immediately be moved to the sprite
	local shape = util.newRectangleShape(0, 0, 30, 30)
	self:setShape(shape)
end


--check if player and block intersects
--also returns horizontal and vertical separation vectors
function Block:checkPlayerCollision(player)
	return self:checkSpriteCollision(player)
end