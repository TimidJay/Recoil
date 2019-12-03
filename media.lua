ani = {}
assets = {}
rects = {}
font = {default = love.graphics.getFont()}
shader = {}
cursors = {}
sounds = {}

--the sound monitor makes sure only 3 instances of a sound can be played at once
--and that that they can't be played within 0.05 seconds of eachother
max_sounds = 3
soundMonitor = {
	active = false,
	limit = 0.05,
	lastPlayed = {},
	update = function(self, dt)
		for k, v in pairs(self.lastPlayed) do
			self.lastPlayed[k] = v + dt
		end
	end,
	activate = function(self)
		self.active = true
		for k, v in pairs(self.lastPlayed) do
			self.lastPlayed[k] = 0
		end
	end,
	deactivate = function(self)
		self.active = false
	end,
	canPlay = function(self, name)
		t = self.lastPlayed[name]
		return t >= self.limit
	end,
	updateSound = function(self, name)
		self.lastPlayed[name] = 0
	end
}

function loadSound(name, path, stream)
	if not love.filesystem.getInfo(path) then
		error("unable to load sound \""..path.."\"")
	end
	local atype = stream and "stream" or "static"
	local queue = Queue:new()
	sounds[name] = queue
	for i = 1, max_sounds do
		sound = love.audio.newSource(path, atype)
		queue:pushLeft(sound)
	end
	soundMonitor:updateSound(name)
end

 soundTable = {} --keeps track of which objects are associated with which sounds

--can pass an object as an argument to keep track of who played the sound
function playSound(name, loop, object)
	if not name then return end
	if soundMonitor.active then
		if not soundMonitor:canPlay(name) then return end
		soundMonitor:updateSound(name)
	end

	local queue = sounds[name]
	local sound = queue:popRight()
	sound:stop()
	soundTable[sound] = object
	sound:setLooping(loop == true)
	sound:play()
	queue:pushLeft(sound)
end

--single only stops the most recent instance of the sound
--if object is provided, only remove the sounds that are associated with the object
--if name is nil and object is not nil, then remove all sounds that belong to the object
function stopSound(name, single, object)
	if name then
		local queue = sounds[name]
		if object then
			--single does not affect this
			for _, v in pairs(queue.data) do
				---this might mess up the order of the sound queue, but does it matter?
				if soundTable[v] == object then
					v:stop()
					soundTable[v] = nil
				end
			end
		else
			if single then
				local sound = queue:popLeft()
				sound:stop()
				queue:pushRight(sound)
			else
				for _, v in pairs(queue.data) do
					v:stop()
				end
			end
		end
	else
		if object == nil then return end
		for k, queue in pairs(sounds) do
			for _, v in pairs(queue.data) do
				if soundTable[v] == object then
					v:stop()
				end
			end
		end
	end
end


function loadImage(name, path)
	if not love.filesystem.getInfo(path) then
		error("unable to load image \""..path.."\"")
	end
	local image = love.graphics.newImage(path)
	local iw, ih = image:getDimensions()
	assets[name] = {img  = image, 
					quad = love.graphics.newQuad(0, 0, iw, ih, iw, ih)}
end

--unless specified, the x and y coordinates denote the center of the image
--set ox and oy to 0 if you want x, y to be the top left corner instead
function draw(imgstr, rect, x, y, r, w, h, ox, oy, kx, ky, flooring)
	if flooring then
		x = math.floor(x)
		y = math.floor(y)
	end
	local image = assets[imgstr].img
	if rect then
		local quad = assets[imgstr].quad
		local iw, ih = rect[3], rect[4]
		w = w or iw
		h = h or ih
		ox = ox or iw/2
		oy = oy or ih/2
		quad:setViewport(unpack(rect))
		love.graphics.draw(image, quad, x, y, r, w/iw, h/ih, ox, oy, kx, ky)
	else
		local iw, ih = image:getDimensions()
		w = w or iw
		h = h or ih
		ox = ox or iw/2
		oy = oy or ih/2
		love.graphics.draw(image, x, y, r, w/iw, h/ih, ox, oy, kx, ky)
	end
end

--drawing with scaling instead of dimensions
function draw2(imgstr, rect, x, y, r, sx, sy, ox, oy, kx, ky)
	if y - math.floor(y) == 0.5 then y = y - 0.1 end --weird graphical glitches appear if drawn at values ending in .5
	local image = assets[imgstr].img
	if rect then
		local quad = assets[imgstr].quad
		local w, h = rect[3], rect[4]
		ox = ox or w/2
		oy = oy or h/2
		quad:setViewport(unpack(rect))
		love.graphics.draw(image, quad, x, y, r, sx, sy, ox, oy, kx, ky)
	else
		local w, h = image:getDimensions()
		ox = ox or w/2
		oy = oy or h/2
		love.graphics.draw(image, x, y, r, sx, sy, ox, oy, kx, ky)
	end
end

function getAniIter(t, loop)
	return coroutine.wrap(function()
		repeat
			for i, v in ipairs(t) do
				coroutine.yield(v[1], v[2])
			end
		until not loop
	end)
end

function setDeltaTime(t, dt)
	for i, v in ipairs(t) do
		v[2] = dt
	end
end

--format: generateFonts(file, name, {start, end, step}, {}, ...}
function generateFonts(name, file, ...)
	local args = {...}
	local path = "media/fonts/"..file
	for _, t in ipairs(args) do
		for i = t[1], t[2], t[3] do
			font[name..i] = love.graphics.newFont(path, i, "mono")
		end
	end
end

local genFonts = generateFonts

-- EXAMPLES FROM OTAKUBALL
-- genFonts("Nov"     , "November.ttf",               {1, 30, 1}, {32, 64, 8})
-- genFonts("Arcade"  , "ARCADEPI.ttf",               {10, 50, 10})
-- genFonts("Pokemon" , "Pokemon Card GB Part B.ttf", {12, 12, 1}, {8, 32, 8})

-- EXAMPLES FROM OTAKUBALL
-- loadImage("border"                 , "media/OtakuBallBorder.png")
-- loadImage("background"             , "media/background.png")
-- loadImage("background2"            , "media/background2.png")

-- EXAMPLES FROM OTAKUBALL
-- loadSound("paddlehit"        , "audio/gameplay/Paddle Bounce.wav")
-- loadSound("blockhit"         , "audio/gameplay/Block Armor.wav")
-- loadSound("blockbreak"       , "audio/gameplay/Block Destroyed.wav")

loadSound("shoot", "audio/shoot.wav")
loadSound("m1_ping", "audio/m1_garand_ping.mp3")
loadSound("m1_shot", "audio/m1_garand_shot_quieter.wav")
loadSound("m1_cock", "audio/shotgun_cock.wav")

cursors.ready = love.mouse.newCursor("media/crosshair1.png", 15, 15)
cursors.empty = love.mouse.newCursor("media/crosshair2.png", 15, 15)

loadImage("white_pixel", "media/whitepixel.png")
loadImage("clear_pixel", "media/clearpixel.png")
loadImage("gun", "media/connor-schultz-asset.png")
loadImage("brick", "media/mariobrick.png")
loadImage("hitmarker", "media/hitmark.png")
loadImage("gate", "media/gates2.png")
loadImage("death_brick", "media/dieblock.png")
loadImage("red_x", "media/big_red_x.png")
loadImage("green_check", "media/big_green_check.png")
loadImage("shockwave", "media/recoil_shockwave.png")
loadImage("laserblock", "media/laserblock2.png")
loadImage("shieldblock", "media/shieldblock2.png")
loadImage("shootBlock1", "media/break1.png" )
loadImage("shootBlock2", "media/break2.png" )
loadImage("shootBlock3", "media/break3.png" )
loadImage("bounceblock1", "media/bounceblock1.png")
loadImage("bounceblock2", "media/bounceblock2.png")
loadImage("fallingblock", "media/fallingblock.png")
loadImage("bluebrick", "media/bluebrick.png")
loadImage("redbrick", "media/redbrick.png")
loadImage("switch_on", "media/switch_on.png")
loadImage("switch_off", "media/switch_off.png")
loadImage("actuator", "media/actuator.png")
loadImage("turret", "media/turret.png")
loadImage("turret_editor", "media/turret_editor.png")
loadImage("bullet", "media/bullettest1.png")
loadImage("donut", "media/donutblock.png")
loadImage("oneway", "media/oneway.png")

--quads are required to be tied to an image
--rects are just simple tables with (x, y, w, h)
--partition rects

local mt = {}
mt.__index = function(t, k)
	if k == "x" then
		return t[1]
	elseif k == "y" then
		return t[2]
	elseif k == "w" then
		return t[3]
	elseif k == "h" then
		return t[4]
	else
		return rawget(t, k)	end
end

function make_rect(x, y, w, h)
	local r = {x, y, w, h}
	setmetatable(r, mt)
	return r
end


--EXAMPLE FROM OTAKUBALL
-- rects.bg = {}
-- for i = 1, 20 do
-- 	rects.bg[i] = {}
-- 	for j = 1, 5 do
-- 		rects.bg[i][j] = make_rect((j-1)*32, (i-1)*32, 32, 32)
-- 	end
-- end

-- rects.ball = {}
-- for i = 1, 100 do
-- 	rects.ball[i] = {}
-- 	for j = 1, 100 do
-- 		rects.ball[i][j] = make_rect((j-1)*12, (i-1)*12, 12, 12)
-- 	end
-- end

-- rects.laser =
-- {
-- 	regular       = make_rect(0, 0, 3, 10),
-- 	plus          = make_rect(3, 0, 4, 10),
-- 	ball          = make_rect(7, 0, 3, 7),
-- 	shooter_red   = make_rect(0, 11, 2, 5),
-- 	shooter_green = make_rect(2, 11, 2, 7),
-- 	shooter_blue  = make_rect(4, 11, 4, 9)
-- }

--powerup animations
-- rects.powerup_ordered = {}
-- local row, col
-- for i = 0, 134 do
-- 	local str = "P"..(i+1)
-- 	if i < 80 then
-- 		row = i % 40
-- 		col = math.floor(i / 40)
-- 	else
-- 		row = (i - 80) % 37
-- 		col = math.floor((i - 80) / 37) + 2
-- 	end
-- 	rects.powerup_ordered[i+1] = rects.powerup[row+1][col+1+(8*4)]
-- 	ani[str] = {imgstr = "powerup_spritesheet"}
-- 	for j = 0, 16 do
-- 		local jj = (j + 8) % 17
-- 		table.insert(ani[str], {rects.powerup[row+1][col+1+(jj*4)], 0.05})
-- 	end
-- end

rects.tile = {}
for i = 1, 100 do
	local row = {}
	for j = 1, 100 do
		table.insert(row, make_rect((j-1)*15, (i-1)*15, 15, 15))
	end
	table.insert(rects.tile, row)
end

rects.shockwave = {}
for i = 1, 5 do
	table.insert(rects.shockwave, make_rect(0, (i-1)*13, 39, 13))
end

for i = 1, 5 do
	local anistr = "shockwave"..i
	ani[anistr] = {imgstr = "shockwave"}
	for j = i, 5 do
		table.insert(ani[anistr], {rects.shockwave[j], 0.05})
	end
end
