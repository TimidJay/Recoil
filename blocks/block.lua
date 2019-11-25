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
	local shape = util.newRectangleShape(30, 30)
	self:setShape(shape)

	self.static = true --whether or not block will move
	self.tangible = true --whether or not it can be collided
	self.actuator = nil --"red", "green", "blue", "yellow"
end

--checks to see if block's center is positioned exactly
--in the grid's center
function Block:isAlignedToGrid()
	local x, y = getGridPosInv(self.i, self.j)
	return x == self.x and y == self.y
end


--check if player and block intersects
--also returns horizontal and vertical separation vectors
function Block:checkPlayerCollision(player)
	if not self.tangible then
		return false
	end
	return self:checkSpriteCollision(player)
end

function Block:onPlayerHit(player)
end

function Block:onBulletHit()
	--print("Hit block at ("..self.i..", "..self.j..")")
end

--should be called by switch blocks only
function Block:onTrigger()
	self.tangible = not self.tangible
	if self.tangible then
		self.color.a = 1
	else
		self.color.a = 0.5
	end
end

function Block:update(dt)
	Sprite.update(self, dt)
	self.i, self.j = getGridPos(self:getPos())
end
--separate drawing frunction for actuators
--because the main drawing function will be overriden
function Block:drawActuator()
	if self.actuator then
		local color = SwitchBlock.colors[self.actuator]
		local color2 = {unpack(color)}
		color2[4] = self.color.a
		love.graphics.setColor(unpack(color2))
		draw("actuator", nil, self.x, self.y, 0, self.w, self.h)
	end
end