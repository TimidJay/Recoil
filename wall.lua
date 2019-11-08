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

	self.holes = {}
	if dir == "up" or dir == "down" then
		for i = 1, config.grid_w do
			self.holes[i] = false
		end
	else
		for i = 1, config.grid_h do
			self.holes[i] = false
		end
	end

	self.shape = util.newRectangleShape(t.w, t.h, t.x, t.y)
end

--based on the wall's direction, either i or j will be ignored
function Wall:addHole(i, j)
	if self.dir == "up" or self.dir == "down" then
		self.holes[j] = true
	else
		self.holes[i] = true
	end
end

function Wall:removeHole(i, j)
	if self.dir == "up" or self.dir == "down" then
		self.holes[j] = false
	else
		self.holes[i] = false
	end
end

function Wall:update(dt)
end

function Wall:draw()
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

	love.graphics.setColor(0, 0, 0, 1)
	if self.dir == "up" or self.dir == "down" then
		for j, v in ipairs(self.holes) do
			if v then
				love.graphics.rectangle(
					"fill", 
					config.border_w + (j-1) * config.cell_w, 
					self.y, 
					config.cell_w, 
					self.h
				)
			end
		end
	else
		for i, v in ipairs(self.holes) do
			if v then
				love.graphics.rectangle(
					"fill", 
					self.x, 
					config.border_w + (i-1) * config.cell_w, 
					self.w, 
					config.cell_w
				)
			end
		end
	end

end