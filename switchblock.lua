SwitchBlock = class("SwitchBlock", Block)

--Block is a standard solid tile that does nothing

--NOTE: Block takes grid coordinates i, j instead of pixel coords x, y
--Unlike other objects, Blocks and other tiles should remain static and grid-aligned
function SwitchBlock:initialize(i, j)
    Block.initialize(self, i, j)
	self.imgstr = "bluebrick"
    self.toggle = true
    self.touched = 0
end


function SwitchBlock:onPlayerHit(player)
    if self.touched == 0 then
        if self.toggle then
            if self.imgstr == "bluebrick" then
                self.imgstr = "redbrick"
            else
                self.imgstr = "bluebrick"
            end
                
        else
            self.imgstr = "redbrick"
        end
    end
    self.touched = 2
end

function SwitchBlock:onBulletHit()
    self:onPlayerHit()
end

function SwitchBlock:update(dt)

    if self.touched > 0 then
        self.touched = self.touched - 1
    end


    Block.update(self, dt)
end
