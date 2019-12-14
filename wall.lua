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
		w = WALL_WIDTH,
		h = window.h,
		gr = grad("horizontal", bl, cl)
	},
	right = {
		x = window.w - WALL_WIDTH,
		y = 0,
		w = WALL_WIDTH,
		h = window.h,
		gr = grad("horizontal", cl, bl)
	},
	up = {
		x = 0,
		y = 0,
		w = window.w,
		h = WALL_WIDTH,
		gr = grad("vertical", bl, cl)

	},
	down = {
		x = 0,
		y = window.h - WALL_WIDTH,
		w = window.w,
		h = WALL_WIDTH,
		gr = grad("vertical", cl, bl)
	}
}

--dir left, right, up, down
--xn and yn values are the edges
--level is temp?
function Wall:initialize(dir, x0, x1, y0, y1, level)
	self.dir = dir
	local t = Wall.data[dir]
	--x and y denote top left corner instead of middle
	-- self.x = t.x
	-- self.y = t.y
	-- self.w = t.w
	-- self.h = t.h
	-- self.gr = t.gr

	self.x = x0
	self.y = y0
	self.w = x1 - x0
	self.h = y1 - y0

	self.x0, self.x1, self.y0, self.y1 = x0, x1, y0, y1

	self.holes = {}
	if dir == "up" or dir == "down" then
		for i = 1, level.grid_w do
			self.holes[i] = false
		end
	else
		for i = 1, level.grid_h do
			self.holes[i] = false
		end
	end

	-- self.shape = util.newRectangleShape(self.w, self.h, self.x, self.y)
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
				(seg.finish - seg.start + 1) * CELL_WIDTH,
				self.h,
				WALL_WIDTH + (seg.start-1) * CELL_WIDTH,
				self.y
			)
		else
			shape = util.newRectangleShape(
				self.w,
				(seg.finish - seg.start + 1) * CELL_WIDTH,
				self.x,
				WALL_WIDTH + (seg.start-1) * CELL_WIDTH
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
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	-- love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

	local gr_w = CELL_WIDTH * 0.75

	if self.dir == "up" or self.dir == "down" then
		--draw corners
		rect("fill", 0                  , self.y, WALL_WIDTH, WALL_WIDTH) --left corner
		rect("fill", self.w - WALL_WIDTH, self.y, WALL_WIDTH, WALL_WIDTH) --right corner
		for j, v in ipairs(self.holes) do
			local x = WALL_WIDTH + (j-1) * CELL_WIDTH
			local y = self.y
			local dy = self.dir == "up" and 0 or -gr_w
			local dh = gr_w
			if v then
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(self.gr, x, y + dy, 0, CELL_WIDTH, self.h + dh)
			else
				love.graphics.setColor(0.5, 0.5, 0.5, 1)
				rect("fill", x, y, CELL_WIDTH, self.h)
			end
		end
	else
		--corners are already filled by up and down walls
		for i, v in ipairs(self.holes) do
			local x = self.x
			local y = WALL_WIDTH + (i-1) * CELL_WIDTH
			local dx = self.dir == "left" and 0 or -gr_w
			local dw = gr_w
			if v then
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(self.gr, x + dx, y, 0, self.w + dw, CELL_WIDTH)
			else
				love.graphics.setColor(0.5, 0.5, 0.5, 1)
				rect("fill", x, y, self.w, CELL_WIDTH)
			end
		end
	end

	--draw shapes for debugging

	-- love.graphics.setColor(0, 1, 1, 1)
	-- love.graphics.setLineWidth(1)
	-- for _, shape in ipairs(self.shapes) do
	-- 	shape:draw()
	-- end
end