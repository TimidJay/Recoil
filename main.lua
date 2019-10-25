console = require("console")
class = require("middleclass")
util = require("my_util")
shapes = require("hardoncollider.shapes")

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

function getGridPos(x, y)
	local i = math.floor((y - config.ceil) / config.cell_h)
	local j = math.floor((x - config.wall_l) / config.cell_w)
	return i+1, j+1
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
end

function love.mousepressed(x, y, button)
	if console.mousepressed(x, y, button) then
	end
end

function love.textinput(t)
	console.textinput(t)
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

	
	console.load(love.graphics.newFont("fonts/Inconsolata.otf", 16), true, executeImmediately)
	console.i("With this console, you can run any lua code want!\nJust don't come crying to me if the game crashes or something.")

	require("game")
	require("states/playstate")
	require("states/editorstate")
	require("media")
	require("sprite")
	require("player")
	require("block")

	game:initialize()
	game:push(EditorState:new())
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

	game:update(dt)

	for k, v in pairs(keys) do
		keys[k] = nil
	end
end

function love.draw()
	love.graphics.setColor(0.8, 0.8, 0.8, 1)
	love.graphics.rectangle("fill", 0, 0, window.w, window.h)
	love.graphics.setColor(1, 1, 1, 1)
	game:draw()

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 12, 12)

	console.draw()
end