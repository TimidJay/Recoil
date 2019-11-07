Wall = class("Wall")
--Although Wall does not inherit Sprite,
--it shares some of Sprite's features

Wall.data = {
	left = {
		x = 0, 
		y = 0,
		w = config.border_w,
		h = window.h
	},
	right = {
		x = window.w - config.border_w,
		y = 0,
		w = config.border_w,
		h = window.h

	},
	up = {
		x = 0,
		y = 0,
		w = window.w,
		h = config.border_w

	},
	down = {
		x = 0,
		y = window.h - config.border_w,
		w = window.w,
		h = config.border_w
	}
}

--left, right, up, down
function Wall:initialize(dir)
	self.dir = dir
	local t = Wall.data[dir]
	self.x = t.x
	self.y = t.y
	self.w = t.w
	self.h = t.h

	self.shape = util.newRectangleShape(t.w, t.h, t.x, t.y)
	
end

function Wall:update(dt)
end

function Wall:draw()
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end