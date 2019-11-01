Sprite = class("Sprite")

--function Sprite:initialize(imgstr, _rect, _scale, _x, _y, _vx, _vy, _angle)
function Sprite:initialize(imgstr, rect, w, h, x, y, vx, vy, angle)
	self.imgstr       = imgstr or "white_pixel"
	self.rect         = rect
	self.w            = w or 1
	self.h            = h or 1
	self.x            = x or 0 --position for the center of the sprite not the top-left corner
	self.y            = y or 0
	self.vx           = vx or 0
	self.vy           = vy or 0
	self.ax           = 0
	self.ay           = 0
	self.angle        = angle or 0 --in radians
	self.dead         = false
	self.destroyed    = false --means you should drop this object as soon as possible
	self.isAnimating  = false
	self.originRect   = nil
	self.originImgstr = nil
	self.aniTimer     = 0
	self.aniScale     = 1 --alters the speed of the animation
	self.aniIter      = nil
	self.gameType     = "default"

	if not self.w or not self.h then
		self.w, self.h = self:getImageDim()
	end

	self.color = {r = 1, g = 1, b = 1, a = 1}
end

function Sprite:destructor()
	self.destroyed = true
	self:removeShape()
end

function Sprite:onDeath()
end

function Sprite:isDead()
	return self.dead
end

function Sprite:kill()
	self.dead = true
end

function Sprite:setColor(r, g, b, a)
	self.color.r = r or self.color.r
	self.color.g = g or self.color.g
	self.color.b = b or self.color.b
	self.color.a = a or self.color.a
end

--returns top left and bottom right coords
--if you want to put them in the table, put {} around it.
--noshape ignores the sprite's shape
function Sprite:bbox(noshape)
	if not noshape and self.shape then
		return self.shape:bbox()
	end
	--if Sprite does not have a shape,
	--it is assumed that the Sprite is a rectangle
	local x, y, w, h = self.x, self.y, self.w, self.h
	local x0, y0, x1, y1 = x-w/2, y-h/2, x+w/2, y+h/2
	if self.angle ~= 0 then
		x0, y0 = util.rotatePoint2(x, y, x0, y0, self.angle)
		x1, y1 = util.rotatePoint2(x, y, x1, y1, self.angle)
		if x1 < x0 then
			x0, x1 = x1, x0
		end
		if y1 < y0 then
			y0, y1 = y1, y0
		end
	end
	return x0, y0, x1, y1
end

--checks if two sprites collide.
--returns true or false as well as the separation vector.
--assumes that the two sprites are rectangles.
--does NOT use shapes for collision checking.
function Sprite:checkSpriteCollision(other)
	local ax, ay = self:getPos()
	local bx, by = other:getPos()
	--left, up, right, down
	local al, au, ar, ad = self:bbox(true)
	local bl, bu, br, bd = other:bbox(true)

	local dx, dy = nil, nil
	if bx > ax then
		--dx should be positive if overlapping
		dx = ar - bl
		if dx <= 0 then return false end
	else
		--dx should be negative if overlapping
		dx = al - br
		if dx >= 0 then return false end
	end

	if by > ay then
		--dy should be positive if overlapping
		dy = ad - bu
		if dy <= 0 then return false end
	else
		--dy should be negative if overlapping
		dy = au - bd
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

function Sprite:setShape(shape)
	self:removeShape()
	self.shape = shape
	shape.sprite = self
	self.shape:moveTo(self.x, self.y)
	self.shape:setRotation(self.angle)
end

function Sprite:removeShape()
	if self.shape then
		self.shape.sprite = nil
		self.shape = nil
	end
end

function Sprite:updateShape()
	if (self.shape) then
		self.shape:moveTo(self.x, self.y)
		self.shape:setRotation(self.angle)
	end
end

function Sprite:startAnimation(anistr, loop)
	if self.isAnimating then self:stopAnimation() end
	self.isAnimating = true
	self.currentAnistr = anistr
	self.aniLoop = loop
	self.originRect = self.rect
	self.originImgstr = self.imgstr
	self.imgstr = ani[anistr].imgstr
	self.aniIter = getAniIter(ani[anistr], loop)
	self.rect, self.aniTimer = self.aniIter()
end

function Sprite:playAnimation(anistr, loop)
	self:startAnimation(anistr, loop)
end

function Sprite:stopAnimation()
	if self.isAnimating then
		self.isAnimating = false
		self.currentAnistr = nil
		self.aniLoop = false
		self.rect = self.originRect
		self.imgstr = self.originImgstr
	end
end

function Sprite:getPos()
	return self.x, self.y
end

function Sprite:setPos(x, y)
	if x then self.x = x end
	if y then self.y = y end
	self:updateShape()
end

function Sprite:setAngle(theta)
	self.angle = theta
	self:updateShape()
end

function Sprite:getVel()
	return self.vx, self.vy
end

function Sprite:setVel(vx, vy)
	if vx then self.vx = vx end
	if vy then self.vy = vy end
end

function Sprite:getSpeed()
	local vx, vy = self:getVel()
	return math.sqrt(vx * vx + vy * vy)
end

function Sprite:scaleVelToSpeed(s2)
	local s1 = self:getSpeed()
	if s1 == 0 then return end
	s2 = math.max(0, s2)
	--if s2 < 1 then return end
	self.vx = self.vx * s2 / s1
	self.vy = self.vy * s2 / s1
end


function Sprite:getDim()
	return self.w, self.h
end

--if a dimension is nil then the dimension wont change
function Sprite:setDim(w, h)
	self.w = w or self.w
	self.h = h or self.h
end

function Sprite:getImageDim()
	local w, h
	if self.rect then
		w, h = self.rect[3], self.rect[4]
	else
		w, h = assets[self.imgstr].img:getDimensions()
	end
	return w, h
end

function Sprite:translate(dx, dy)
	self.x = self.x + dx
	self.y = self.y + dy
	self:updateShape()
end

function Sprite:update(dt)
	if self.isAnimating then
		self.aniTimer = self.aniTimer - (dt * self.aniScale)
		if self.aniTimer <= 0 then
			self.rect, self.aniTimer = self.aniIter()
			if not self.rect then self:stopAnimation() end
		end
	end

	self.x = self.x + (self.vx * dt) + (0.5 * self.ax * dt * dt)
	self.y = self.y + (self.vy * dt) + (0.5 * self.ay * dt * dt)

	self.vx = self.vx + (self.ax * dt)
	self.vy = self.vy + (self.ay * dt)

	self:updateShape()
end

function Sprite:draw()
	love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
	draw(self.imgstr, self.rect, self.x, self.y, self.angle, self.w, self.h, nil, nil, nil, nil, self.drawFloor)
end

function Sprite:drawAlt()
	love.graphcis.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
	draw(self.imgstr, self.rect, self.x, self.y, self.angle, self.w, self.h, 0, 0, nil, nil, self.drawFloor)
end
