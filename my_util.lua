local util = {}

function util.nullfunc() end

function util.defaultDestructor(obj)
	if obj.destructor then
		obj:destructor()
	end
end

function util.remove_if(t, func, destr)
	destr = destr or util.nullfunc
	local i = 1
	while i <= #t do
		if func(t[i]) then
			destr(t[i])
			table.remove(t, i)
		else
			i = i + 1
		end
	end
end

function util.clear(t, destr)
	destr = destr or util.nullfunc
	for k, v in pairs(t) do
		destr(v)
		t[k] = nil
	end
end

function util.push_back(t, val)
	t[#t+1] = val
end

function util.copy(t)
	local c = {}
	for k, v in pairs(t) do
		c[k] = v
	end
	setmetatable(c, getmetatable(t))
	return c
end

function util.isEmpty(t)
	return next(t) == nil
end

function util.generateLookup(t)
	local l = {}
	for i, v in ipairs(t) do
		l[v] = true
	end
	return l
end

function util.tableToString(table)
	local str = "{"
	for k, v in pairs(table) do
		local vstr = tostring(v)
		if type(v) == "table" then
			vstr = util.tableToString(v)
		elseif type(v) == "string" then
			vstr = "\""..vstr.."\""
		end
		if type(k) == "number" then
			str = str..vstr..", "
		else
			str = str..k.." = "..vstr..", "
		end
	end
	str = str:sub(1, #str - 2).."}"
	return str
end

function util.join(lines)
	local str = ''
	for k, v in pairs(lines) do
		str = str .. prefix .. v .. "\n"
	end
	return str
end


function util.cap_first_letter(str)
	return str:sub(1,1):upper()..str:sub(2)
end

function util.randomReal(a, b)
	if a > b then
		local c = a
		a = b
		b = c
	end
	return math.random() * (b-a) + a
end

function util.round(n)
	return math.floor(n + 0.5)
end

function util.deltaEqual(a, b, delta)
	delta = delta or 0.000001
	return math.abs(a - b) < delta
end

function util.dist(x1, y1, x2, y2)
	x2 = x2 or 0
	y2 = y2 or 0
	return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

function util.angleBetween(x1, y1, x2, y2)
	return math.acos((x1 * x2 + y1 * y2) / (util.dist(x1, y1) * util.dist(x2, y2)))
end

function util.normalize(x, y)
	local d = util.dist(x, y)
	if d == 0 then return 0, 0 end
	return x/d, y/d
end

function util.rotateVec(x, y, deg)
	local angle = deg * math.pi / 180
	local newx = (x*math.cos(angle)) - (y*math.sin(angle))
	local newy = (x*math.sin(angle)) + (y*math.cos(angle))
	return newx, newy
end

function util.rotateVec2(x, y, rad)
	local angle = rad
	local newx = (x*math.cos(angle)) - (y*math.sin(angle))
	local newy = (x*math.sin(angle)) + (y*math.cos(angle))
	return newx, newy
end

function util.rotatePoint(cx, cy, x, y, deg)
	x, y = x-cx, y-cy
	x, y = util.rotateVec(x, y, deg)
	x, y = x+cx, y+cy
	return x, y
end

function util.rotatePoint2(cx, cy, x, y, rad)
	x, y = x-cx, y-cy
	x, y = util.rotateVec2(x, y, rad)
	x, y = x+cx, y+cy
	return x, y
end

--returns a new rectangle shape from hardoncollider/shapes
--x and y denotes top left corner of the retangle
--x and y are optional because the shape most likely be moved to the sprite after creation
function util.newRectangleShape(w, h, x, y)
	x = x or 0
	y = y or 0
	local x0, y0 = x, y
	local x1, y1 = x+w, y+h
	return shapes.newPolygonShape(x0,y0, x0,y1, x1,y1, x1,y0)
end

function util.bboxOverlap(box1, box2) --damn you floating points!!!
	return not (math.floor(box1[1]) >= math.floor(box2[3]) or
				math.floor(box1[3]) <= math.floor(box2[1]) or
				math.floor(box1[2]) >= math.floor(box2[4]) or
				math.floor(box1[4]) <= math.floor(box2[2]))
end

--faster than using SAT but doesn't provide normal vectors
function util.circleRectOverlap(ccx, ccy, cr, rcx, rcy, rw, rh)
	local circleDistX = math.abs(ccx - rcx)
	local circleDistY = math.abs(ccy - rcy)
	if circleDistX > (rw / 2 + cr) then return false end
	if circleDistY > (rh / 2 + cr) then return false end
	if circleDistX <= (rw / 2) then return true end
	if circleDistY <= (rh / 2) then return true end
	local cornerDist = math.pow(circleDistX - rw / 2, 2) + math.pow(circleDistY - rh / 2, 2)
	return cornerDist <= math.pow(cr, 2)
end

function util.containPoint(box, x, y)
	return x >= box[1] and x <= box[3] and y >= box[2] and y <= box[4]
end

--borrowed from https://love2d.org/wiki/LineStippleSnippet
function util.lineStipple( x1, y1, x2, y2, dash, gap )
    local dash = dash or 10
    local gap  = dash + (gap or 10)
 
    local steep = math.abs(y2-y1) > math.abs(x2-x1)
    if steep then
        x1, y1 = y1, x1
        x2, y2 = y2, x2
    end
    if x1 > x2 then
        x1, x2 = x2, x1
        y1, y2 = y2, y1
    end
 
    local dx = x2 - x1
    local dy = math.abs( y2 - y1 )
    local err = dx / 2
    local ystep = (y1 < y2) and 1 or -1
    local y = y1
    local maxX = x2
    local pixelCount = 0
    local isDash = true
    local lastA, lastB, a, b
 
    for x = x1, maxX do
        pixelCount = pixelCount + 1
        if (isDash and pixelCount == dash) or (not isDash and pixelCount == gap) then
            pixelCount = 0
            isDash = not isDash
            a = steep and y or x
            b = steep and x or y
            if lastA then
                love.graphics.line( lastA, lastB, a, b )
                lastA = nil
                lastB = nil
            else
                lastA = a
                lastB = b
            end
        end
 
        err = err - dy
        if err < 0 then
            y = y + ystep
            err = err + dx
        end
    end
end


 
--borrowed from https://love2d.org/wiki/Gradients
--instructions:
--dir is either "horizontal" or "vertical"
--... is a list of colors, {r1, g1, b1, a1}, {r1, g1, b1, a1}, etc
--returns a drawable pixel that can be scaled to fit any size
local COLOR_MUL = love._version >= "11.0" and 1 or 255 --compatibility
function util.gradientMesh(dir, ...)
    -- Check for direction
    local isHorizontal = true
    if dir == "vertical" then
        isHorizontal = false
    elseif dir ~= "horizontal" then
        error("bad argument #1 to 'gradient' (invalid value)", 2)
    end
 
    -- Check for colors
    local colorLen = select("#", ...)
    if colorLen < 2 then
        error("color list is less than two", 2)
    end
 
    -- Generate mesh
    local meshData = {}
    if isHorizontal then
        for i = 1, colorLen do
            local color = select(i, ...)
            local x = (i - 1) / (colorLen - 1)
 
            meshData[#meshData + 1] = {x, 1, x, 1, color[1], color[2], color[3], color[4] or (1 * COLOR_MUL)}
            meshData[#meshData + 1] = {x, 0, x, 0, color[1], color[2], color[3], color[4] or (1 * COLOR_MUL)}
        end
    else
        for i = 1, colorLen do
            local color = select(i, ...)
            local y = (i - 1) / (colorLen - 1)
 
            meshData[#meshData + 1] = {1, y, 1, y, color[1], color[2], color[3], color[4] or (1 * COLOR_MUL)}
            meshData[#meshData + 1] = {0, y, 0, y, color[1], color[2], color[3], color[4] or (1 * COLOR_MUL)}
        end
    end
 
    -- Resulting Mesh has 1x1 image size
    return love.graphics.newMesh(meshData, "strip", "static")
end

Stack = class("Stack")

function Stack:initialize(list)
	self.data = {}
	if list then
		self.data = util.copy(list) 
	end
end

function Stack:push(t)
	self.data[#self.data+1] = t
end

function Stack:pop()
	local top = self:top()
	self.data[#self.data] = nil
	return top
end

function Stack:top()
	return self.data[#self.data]
end

function Stack:size()
	return #self.data
end

function Stack:empty()
	return self:size() == 0
end

Queue = class("Queue")

function Queue:initialize(list)
	self.first = 0
	self.last = -1
	self.length = 0
	self.data = {}
	if list then
		for i, v in ipairs(list) do
			self:pushRight(v)
		end
	end
end

function Queue:peekLeft()
	return self.data[self.first]
end

function Queue:peekRight()
	return self.data[self.last]
end

function Queue:pushLeft(value)
	local first = self.first - 1
	self.first = first
	self.data[first] = value
	self.length = self.length + 1
end

function Queue:pushRight(value)
	local last = self.last + 1
	self.last = last
	self.data[last] = value
	self.length = self.length + 1
end

function Queue:popLeft()
	local first = self.first
	if first > self.last then error("empty queue") end
	local value = self.data[first]
	self.data[first] = nil
	self.first = first + 1
	self.length = self.length - 1
	return value
end

function Queue:popRight()
	local last = self.last
	if self.first > last then error("empty queue") end
	local value = self.data[last]
	self.data[last] = nil
	self.last = last - 1
	self.length = self.length - 1
	return value
end

function Queue:size()
	return self.length
end

function Queue:empty()
	return self.length == 0
end

return util