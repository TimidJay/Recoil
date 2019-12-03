BounceBlock1 = class("BounceBlock1", Block)

function BounceBlock1:initialize(i,j)
	Block.initialize(self,i,j)
	self.imgstr = "bounceblock1"
end

function BounceBlock1:update(dt)

	-- self:checkAboveorBelow(playstate.player)

	Block.update(self,dt)
end

--check if player and block intersects
--also returns horizontal and vertical separation vectors
-- function BounceBlock1:checkPlayerCollision(player)
-- 	return self:checkSpriteCollision(player)
-- end

function BounceBlock1:onPlayerHit2(player)
	local i, j = getGridPos(player:getPos())
	if j == self.j then
		if i == self.i - 1 then
			self:bounceUp(player)
		elseif i == self.i + 1 then
			self:bounceDown(player)
		end
	end
end

-- function BounceBlock1:checkAboveorBelow(player)

-- 	playeri, playerj = getGridPos(player.x,player.y) 
-- 	if self.j == playerj and playeri- self.i <= 1 and playeri - self.i > 0 then
-- 		self:bounceUp(player)
-- 	end

-- 	if self.j == playerj and self.i - playeri <= 1 and playeri - self.i > 0 then
-- 		self:bounceDown(player)
-- 	end
-- end



function BounceBlock1:bounceUp(player)
	local spd = 3000
	player.vy = -spd
	player.speedLimit = spd
end

function BounceBlock1:bounceDown(player)
	local spd = 3000
	player.vy = spd
	player.speedLimit = spd
end
