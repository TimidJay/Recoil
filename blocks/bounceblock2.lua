BounceBlock2 = class("BounceBlock2", Block)

function BounceBlock2:initialize(i,j)
	Block.initialize(self,i,j)
	self.imgstr = "bounceblock2"
end

function BounceBlock2:update(dt)

	-- self:checkAboveorBelow(playstate.player)

	Block.update(self,dt)
end

--check if player and block intersects
--also returns horizontal and vertical separation vectors
-- function BounceBlock1:checkPlayerCollision(player)
-- 	return self:checkSpriteCollision(player)
-- end

function BounceBlock2:onPlayerHit2(player)
	local i, j = getGridPos(player:getPos())
	if i == self.i then
		if j == self.j - 1 then
			self:bounceLeft(player)
		elseif j == self.j + 1 then
			self:bounceRight(player)
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



function BounceBlock2:bounceLeft(player)
	local spd = 3000
	player.vx = -spd
	player.speedLimit = spd
end

function BounceBlock2:bounceRight(player)
	local spd = 3000
	player.vx = spd
	player.speedLimit = spd
end
