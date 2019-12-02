loveframes = require("loveframes")
console = require("console")
class = require("middleclass")
util = require("my_util")
shapes = require("hardoncollider.shapes")

--save files are located in
--	C:\Users\[your username]\AppData\Roaming\LOVE\Recoil
love.filesystem.setIdentity("Recoil")
love.filesystem.createDirectory("levels")

window = {
	w = 1280,
	h = 800
}

--list of various constants
--these will be used all over the place so its better to have them here
config = {
	border_w = 25, --how thick should the border wall be
	cell_w = 30, --each cell is a square
	grid_w = 41, --how many cells wide
	grid_h = 25 --how many cells tall
}
--aliases
config.cell_h = config.cell_w
config.rows = config.grid_h
config.cols = config.grid_w
--derived constants
config.floor = window.h - config.border_w
config.wall_l = config.border_w
config.wall_r = window.w - config.border_w
config.ceil = config.border_w
config.ceiling = config.ceil

local super_print = print

--causes print to print to the console
_G["print"] = function(...)
	super_print(...)
	console.i(...)
end

--does not do bound checking
function getGridPos(x, y)
	local i = math.floor((y - config.ceil) / config.cell_h)
	local j = math.floor((x - config.wall_l) / config.cell_w)
	return i+1, j+1
end

--does the inverse of above function
--returns the coords of the center the grid cell
function getGridPosInv(i, j)
	local cw = config.cell_w
	return config.wall_l - cw/2 + (cw * j), config.ceil - cw/2 + (cw * i)
end

function boundCheck(i, j)
	return i >= 1 and i <= config.rows and j >= 1 and j <= config.cols
end

mouse = {}
keys = {}
function love.keypressed(key, code, isrepeat)
	if not console.keypressed(key) then
		if isrepeat then
			keys[key] = 2
		else
			keys[key] = 1
		end
	end
	--print(key.." "..code.." "..(isrepeat and "repeat" or "no repeat"))
	loveframes.keypressed(key, code, isrepeat)
end

function love.keyreleased(key)
	loveframes.keyreleased(key)
end

function love.mousepressed(x, y, button)
	if console.mousepressed(x, y, button) then
	end
	loveframes.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end

function love.textinput(t)
	console.textinput(t)
	loveframes.textinput(t)
end

local function executeImmediately(input)
	local f, err = loadstring(input)
	console.i("> "..input)
	if f then
		local status, err = pcall(f)
		if not status then
			--runtime error
			console.e(err)
		end
	else
		--compilation error
		console.e(err)
	end
end

function love.load(arg)
	love.window.setMode(window.w, window.h, {borderless = false, vsync = false})
	love.window.setTitle("Recoil")
	love.mouse.setGrabbed(true)
	love.graphics.setDefaultFilter("nearest", "nearest", 1)

	love.audio.setVolume(0.5)

	console.load(love.graphics.newFont("fonts/Inconsolata.otf", 16), true, executeImmediately)
	console.i("With this console, you can execute any lua code you want!")

	require("wall")
	require("game")
	require("states/playstate")
	require("states/editorstate")
	require("media")
	require("sprite")
	require("player")
	require("gate")
	require("turret")
	require("ammo")

	require("blocks/block")
	require("blocks/death_block")
	require("blocks/laserblock")
	require("blocks/shieldblock")
	require("blocks/falling_block")
	require("blocks/donut")
    require("blocks/switchblock")
    require("blocks/onewayblock")
    require("blocks/shootblock")

	require("data")

	game:initialize()
	game:push(EditorState:new())
end

time_scale = 1

disable_screen_shake = false
screen_shake = {}

function setScreenShake()
	if disable_screen_shake then
		return
	end

	local ss = screen_shake
	ss.on = true
	ss.timer = 0.2
	ss.maxTimer = ss.timer
	--magnitude will decrease linearly to 0
	ss.mag = 1
	ss.maxMag = ss.mag
	ss.linearDecay = false
end


function love.update(dt)
	console.update(dt)
	
	if love.keyboard.isDown("lctrl") and love.keyboard.isDown("q") then
		love.event.quit()
	end

	local buttons = {m1 = 1, 
					 m2 = 2, 
					 m3 = 3}
	for k, v in pairs(buttons) do
		if love.mouse.isDown(v) then
			if not mouse[k] then mouse[k] = 1 else mouse[k] = 2 end
		else
			mouse[k] = false
		end
	end
	mouse.x, mouse.y = love.mouse.getPosition()

	game:update(math.min(1/60, dt*time_scale))

	for k, v in pairs(keys) do
		keys[k] = nil
	end

	loveframes.update(dt)

	local ss = screen_shake
	if ss.on then
		ss.timer = ss.timer - dt
		if ss.timer <= 0 then
			ss.on = false
		end
		if ss.linearDecay then
			ss.mag = ss.timer / ss.maxTimer * ss.maxMag
		end
	end

end

function love.draw()
	local ss = screen_shake
	if ss.on then
		local dx, dy = util.rotateVec(0, ss.mag, math.random(360))
		love.graphics.translate(dx, dy)
	end

	love.graphics.setColor(0.8, 0.8, 0.8, 1)
	love.graphics.rectangle("fill", 0, 0, window.w, window.h)
	love.graphics.setColor(1, 1, 1, 1)
	game:draw()

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 12, 12)

	loveframes.draw()
	console.draw()
end
