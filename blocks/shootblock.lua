ShootBlock = class("ShootBlock",Block)

function ShootBlock:initialize(i,j)
    Block.initialize(self,i,j)
    self.touched = 0
    self.imgstr = "shootBlock1"
    self.contact = false
end


function ShootBlock:onBulletHit()
    self.touched = self.touched +1
end

function ShootBlock:update(dt)
	local player=playstate.player
	if(Block.checkPlayerCollision(self, player) and (not self.contact)) then
		self.contact = true
		self.touched = self.touched +1
	end
	
	if not Block.checkPlayerCollision(self, player) then
		self.contact = false
	end

    if self.touched==0 then
        self.imgstr = "shootBlock1"
    end
    if self.touched==1 then
        self.imgstr = "shootBlock2"
    end
    if self.touched==2 then
        self.imgstr="shootBlock3"
    end
    if self.touched==3 then
        self.vy=1000
    end
    Block.update(self,dt)
end
