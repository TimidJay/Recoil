MainMenuState = class("MainMenuState")

local function make_button(name, x, y, w, h)
	local butt = loveframes.Create("button")
	butt:SetText(name)
	butt:SetPos(x-w/2, y-h/2)
	butt:SetSize(w, h)
	butt:SetState("MainMenuState")
	return butt
end

function MainMenuState:initialize()
	self.className = "MainMenuState"
	local cx, cy = window.w/2, window.h/2

	local playButton = make_button("Play", cx, cy, 100, 30)
	playButton.OnClick = function(obj, x, y)
		game:push(LevelSelectState:new())
	end
	
	local editButton = make_button("Level Editor", cx, cy + 40, 100, 30)
	editButton.OnClick = function(obj, x, y)
		game:push(EditorState:new())
	end

	local fsButton = make_button("Toggle Fullscreen", cx + 200, cy + 200, 100, 30)
	fsButton.OnClick = function(obj, x, y)
		if fullscreen then
			setFullscreen(false)
		else
			setFullscreen(true)
		end
	end
end

function MainMenuState:update(dt)
end

function MainMenuState:draw()
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	love.graphics.rectangle("fill", 0, 0, window.w, window.h)
end