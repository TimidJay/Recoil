DonutBlock=class("DonutBlock",Block)
--No sprite in mind yet for this
--TODO: need a sprite for this block
--TODO: determine some nice speeds
function DonutBlock:initialize(i,j,spd)
	Block.initialize(self,i,j)
	self.speed=spd or 100
	self.falling=false
	self.initX=self.x
	self.initY=self.y
	self.countdown=50
	self.static = false
end

function DonutBlock:checkPlayerOnTop()
	local player=playstate.player
	if Block.checkPlayerCollision(self,player) and player.touchingGround and (player.y+player.h/2)>=(self.y-self.h/2) and (player.x+player.w/2)<=(self.x+self.w/2) and (player.x-player.w/2)>=(self.x-self.w/2) then
		self.falling=true
	end
end

--To keep movement smooth over these blocks if you don't want to fall with them, there's a short delay before they fall
function DonutBlock:fall()
	if self.countdown>0 then
		self.countdown=self.countdown-1
	else
		self.vy= self.speed
	end
end

--upwarp feels really weird with this implementation, don't necessarily need it so may just delete it
function DonutBlock:upwarp(player)
	--warp should put player 5 units above the donut block
	if player.touchingGround and (player.x-player.w/2)>=(self.x-self.w/2) and (player.x+player.w/2)<=(self.x+self.w/2) and Block.checkPlayerCollision(self,player) then
		player.y=player.y-self.h/2-5
		end
end

function DonutBlock:onPlayerHit(player)
	if self.falling and self.vy > 0 then
		player.y = player.y + self.vy * 1/60
	end

end

function DonutBlock:update(dt)
	local player=playstate.player
	--start with upwarp checks
	if not self.falling then
		self:checkPlayerOnTop()
		--self:upwarp(player)
	else
		--self:upwarp(player)
		self:fall()
		--Conditional to respawn at original position if block falls a bit below screen - set to 1000 for now, will confirm later
		if self.y>=1000 then
			self.falling=false
			self.y=self.initY
			self.vy=0
			self.countdown=50
		end
	end
	Block.update(self,dt)
end
 