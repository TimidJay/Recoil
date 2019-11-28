DeathBlock = class("DeathBlock", Block)

-- Die on contact with a DeathBlock

--NOTE: DeathBlock takes grid coordinates i, j instead of pixel coords x, y
--Unlike other objects, Blocks and other tiles should remain static and grid-aligned
function DeathBlock:initialize(i, j)
	Block.initialize(self,i,j)
	self.imgstr = "death_brick"
end

function DeathBlock:onPlayerHit(player)
	player.dead = true
end