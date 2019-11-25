ShieldBlock = class("ShieldBlock", LaserBlock)

--shares a lot of similarities with Laser Block

function ShieldBlock:initialize(i, j, dir)
	LaserBlock.initialize(self, i, j, dir)
	self.imgstr = "shieldblock"

	self.shieldWidth = 20
	self.stop = 1
	self:createShieldShape()
end

function ShieldBlock:createShieldShape()
	local stop = self.stop
	local shw = self.shieldWidth
	local x, y, w, h
	if self.dir == "up" then
		x = self.x - shw/2
		y = self.y - self.stop
		w = shw
		h = stop
	elseif self.dir == "down" then
		x = self.x - shw/2
		y = self.y
		w = shw
		h = stop
	elseif self.dir == "right" then
		x = self.x
		y = self.y - shw/2
		w = stop
		h = shw
	else --left
		x = self.x - self.stop
		y = self.y - shw/2
		w = stop
		h = shw
	end
	local shape = util.newRectangleShape(w, h, x, y)
	self.shieldShape = shape
end

function ShieldBlock:update(dt)
	if not self.disabled then
		local oldStop = self.stop
		self:fireLaser()
		if self.stop ~= oldStop then
			self:createShieldShape()
		end
	end
	Block.update(self, dt)
end

function ShieldBlock:draw()
	if not self.disabled then
		love.graphics.setLineStyle("smooth")

		local x0, y0 = self:getPos()
		local x1 = x0 + self.stop * self.dj
		local y1 = y0 + self.stop * self.di

		love.graphics.setColor(0, 0, 1, 1)
		love.graphics.setLineWidth(self.shieldWidth)
		love.graphics.line(x0, y0, x1, y1)

		love.graphics.setColor(0, 1, 1, 1)
		love.graphics.setLineWidth(self.shieldWidth - 3)
		love.graphics.line(x0, y0, x1, y1)
	end
	love.graphics.setColor(1, 1, 1, 1)
	Block.draw(self)
end