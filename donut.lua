DonutBlock=class("DonutBlock",Block)
--No sprite in mind yet for this
--TODO: need a sprite for this block
--TODO: determine some nice speeds
--TODO: decide on upwarp or crushing
function DonutBlock:initialize(i,j,spd)
	Block.initialize(self,i,j)
	local speed=spd
	local falling=false
	local initX=i
	local initY=j
end

function DonutBlock:checkPlayerOnTop()
	local player=playstate.player
	if Block.checkPlayerCollision(self,player) and player.touchingGround and (player.y+player.h/2)>=(self.y-self.h/2) then
		falling=true
	end
end

--setting a speed much slower than Marshall's for now
function DonutBlock:fall()
	self.vy=spd
end

--NOTE: if we decide to have these blocks be able to crush the player, they'll be similar to the other falling blocks
--		difference is that these ones will fall through the floor and respawn, probably generally fall slower,
--		and would only crush if the player's already standing on some floor
--	For now, I'll implement an upwarp instead and see how that feels

--This block shouldn't be lethal. If the player is on a block and beneath a falling donut block, upwarp the player on top of the donut block.
--This avoids getting stuck from what should be a crush but produces inconsistency with the crushing falling block. Thoughts?
--Not making the block push the player to the sides since a small upwarp will probably avoid issues more easily than getting pushed in case there are walls adjacent to the player
function DonutBlock:upwarp(player)
	--warp should put player 5 units above the donut block
	if player.touchingGround and (player.x-player.w/2)>=(self.x-self.w/2) and (player.x+player.w/2)<=self.x+self.w/2) and (player.y-player.h/2)<self.y and Block.checkPlayerCollision(self,player) then
		player.y=player.y-self.h-5
	end
end

function DonutBlock:update(dt)
	local player=playstate.player
	if !falling then
		self:checkPlayerOnTop()
	else
		self:fall()
		--Conditional to respawn at original position if block falls a bit below screen - set to 1000 for now, will confirm later
		if self.y>=1000 then
			falling=false
			self.y=initY
			self.vy=0
		end
	end
	Block.update(self,dt)
end
