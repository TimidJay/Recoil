FallingBlock = class("FallingBlock", Block)

--Falling block drops in proximity below, die if falls on player

--NOTE: FallingBlock takes grid coordinates i, j instead of pixel coords x, y
--Unlike other objects, Blocks and other tiles should remain static and grid-aligned
function FallingBlock:initialize(i, j)
	Block.initialize(self,i,j)
	self.imgstr = "fallingblock"
end


function FallingBlock:update(dt)

	local check, dx, dy = self:checkPlayerCollision(playstate.player)

	if check and dy > 0 then
		playstate.player.dead = true
	end

	self:checkBelow(playstate.player)
	
	self:onPlayerHit(playstate.player)

	Block.update(self,dt)
end

--check if player and block intersects
--also returns horizontal and vertical separation vectors
function FallingBlock:checkPlayerCollision(player)
	return self:checkSpriteCollision(player)
end

function FallingBlock:checkBelow(player)

	playeri, playerj = getGridPos(player.x,player.y) 
	if self.j == playerj and playeri- self.i <= 5 and playeri - self.i > 0 then
		self:fall(player)
	end
end

-- function FallingBlock:onPlayerHit(player)
-- 	playeri, playerj = getGridPos(player.x,player.y) 
-- 	if self.j == playerj and playeri - self.i == 1 then
-- 		print("DEAD")
-- 		player.dead = true
-- 	end
-- end

-- TODO: figure out how to move block until it hits ground
-- TODO: check for other blocks
function FallingBlock:fall(player)
	self.vy = 650
end