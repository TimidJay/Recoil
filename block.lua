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
	local px, py, pw, ph = player.x, player.y, player.w/2, player.h/2
	local tx, ty, tw, th = self.x, self.y, self.w/2, self.h/2
	--left, right, up, down
	local pl, pr, pu, pd = px - pw, px + pw, py - ph, py + ph
	local tl, tr, tu, td = tx - tw, tx + tw, ty - th, ty + th

	local dx, dy = nil, nil
	if px > tx then
		--dx should be positive if overlapping
		dx = tr - pl
		if dx <= 0 then return false end
	else
		--dx should be negative if overlapping
		dx = tl - pr
		if dx >= 0 then return false end
	end

	if py > ty then
		--dy should be positive if overlapping
		dy = td - pu
		if dy <= 0 then return false end
	else
		--dy should be negative if overlapping
		dy = tu - pd
		if dy >= 0 then return false end
	end

	--since they are overlapping, we need to shift player horizontally or vertically
	--we should use the lowest magnitude since it best reflects which direction the player hit the block
	if math.abs(dx) < math.abs(dy) then
		return true, dx, 0
	else
		return true, 0, dy
	end
end