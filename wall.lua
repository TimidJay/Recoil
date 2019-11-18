Wall = class("Wall")
--Although Wall does not inherit from Sprite,
--it shares some of Sprite's attributes

local bl = {0, 0, 0, 1} --black
local cl = {0, 0, 0, 0} --clear
local grad = util.gradientMesh

Wall.data = {
	left = {
		x = 0, 
		y = 0,
		w = config.border_w,
		h = window.h,
		gr = grad("horizontal", bl, cl)
	},
	right = {
		x = window.w - config.border_w,
		y = 0,
		w = config.border_w,
		h = window.h,
		gr = grad("horizontal", cl, bl)
	},
	up = {
		x = 0,
		y = 0,
		w = window.w,
		h = config.border_w,
		gr = grad("vertical", bl, cl)

	},
	down = {
		x = 0,
		y = window.h - config.border_w,
		w = window.w,
		h = config.border_w,
		gr = grad("vertical", cl, bl)
	}
}

--left, right, up, down
function Wall:initialize(dir)
	self.dir = dir
	local t = Wall.data[dir]
	--x and y denote top left corner instead of middle
	self.x = t.x
	self.y = t.y
	self.w = t.w
	self.h = t.h
	self.gr = t.gr

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
	self.shapes = {}
end

function Wall:reset()
	self.shapes = {}
	self:clearHoles()
end

--based on the wall's direction, either i or j will be ignored
--set to either true or false
function Wall:setHole(i, j, value)
	if self.dir == "up" or self.dir == "down" then
		self.holes[j] = value
	else
		self.holes[i] = value
	end
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

function Wall:clearHoles()
	for k, v in ipairs(self.holes) do
		self.holes[k] = false
	end
end

--creates shapes based on the holes
function Wall:createShapes()
	--calculate wall segments
	local segments = {}
	local seg = nil
	for i, hole in ipairs(self.holes) do
		if seg then
			if hole then
				table.insert(segments, seg)
				seg = nil
			else
				seg.finish = i
			end
		else
			if not hole then
				seg = {start = i, finish = i}
			end
		end
	end
	if seg then
		table.insert(segments, seg)
	end
	--create shapes out of wall segments
	local x, y, w, h
	for _, seg in ipairs(segments) do
		local shape
		if self.dir == "up" or self.dir == "down" then
			shape = util.newRectangleShape(
				(seg.finish - seg.start + 1) * config.cell_w,
				self.h,
				config.border_w + (seg.start-1) * config.cell_w,
				self.y
			)
		else
			shape = util.newRectangleShape(
				self.w,
				(seg.finish - seg.start + 1) * config.cell_w,
				self.x,
				config.border_w + (seg.start-1) * config.cell_w
			)
		end
		table.insert(self.shapes, shape)
	end
end

function Wall:checkPlayerCollision(player)
	local pshape = player.shape
	for _, wshape in ipairs(self.shapes) do
		local check, dx, dy = Wall.tempShapeCollision(wshape, pshape)
		if check then
			return true, dx, dy
		end
	end
	return false
end

function Wall.tempShapeCollision(box1, box2)
	--left, up, right, down
	local al, au, ar, ad = box1:bbox()
	local bl, bu, br, bd = box2:bbox()
	local ax, ay = box1:center()
	local bx, by = box2:center()

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


function Wall:update(dt)
end

function Wall:draw()
	local rect = love.graphics.rectangle
	local border_w = config.border_w
	local cell_w = config.cell_w
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	-- love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

	local gr_w = cell_w * 0.75

	if self.dir == "up" or self.dir == "down" then
		rect("fill", 0            , self.y, cell_w, self.h) --left corner
		rect("fill", config.wall_r, self.y, cell_w, self.h) --right corner
		for j, v in ipairs(self.holes) do
			local x = border_w + (j-1) * cell_w
			local y = self.y
			local dy = self.dir == "up" and 0 or -gr_w
			local dh = gr_w
			if v then
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(self.gr, x, y + dy, 0, cell_w, self.h + dh)
			else
				love.graphics.setColor(0.5, 0.5, 0.5, 1)
				rect("fill", x, y, cell_w, self.h)
			end
		end
	else
		--corners are already filled by up and down walls
		for i, v in ipairs(self.holes) do
			local x = self.x
			local y = border_w + (i-1) * cell_w
			local dx = self.dir == "left" and 0 or -gr_w
			local dw = gr_w
			if v then
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(self.gr, x + dx, y, 0, self.w + dw, cell_w)
			else
				love.graphics.setColor(0.5, 0.5, 0.5, 1)
				rect("fill", x, y, self.w, cell_w)
			end
		end
	end

	-- love.graphics.setColor(0, 1, 1, 1)
	-- love.graphics.setLineWidth(1)
	-- for _, shape in ipairs(self.shapes) do
	-- 	shape:draw()
	-- end
end