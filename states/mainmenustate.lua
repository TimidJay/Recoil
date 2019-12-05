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

	local playButton = make_button("Play", cx - 200, cy + 200, 100, 30)
	playButton.OnClick = function(obj, x, y)
		game:push(LevelSelectState:new())
	end
	
	local editButton = make_button("Level Editor", cx - 200, cy + 240, 100, 30)
	editButton.OnClick = function(obj, x, y)
		game:push(EditorState:new())
	end

	local fsButton = make_button("Toggle Fullscreen", cx + 240, cy + 200, 100, 30)
	fsButton.OnClick = function(obj, x, y)
		if fullscreen then
			setFullscreen(false)
		else
			setFullscreen(true)
		end
	end

	local controlButton = make_button("Controls", cx + 240, cy + 240, 100, 30)
	controlButton.OnClick = function(obj, x, y)
		self:showControlsWindow()
	end
end

function MainMenuState:showControlsWindow()
	if self.ctrlframe then return end
	
	local frame = loveframes.Create("frame")
	frame:SetName("How to Play")
	frame:SetSize(300, 200)
	frame:SetPos(window.w/2, window.h/2 - 100)
	frame:SetState("MainMenuState")
	frame.OnClose = function()
		self.cntrlframe = nil
		return true
	end

	local lines = {
		"WASD to move",
		"Left-Click to fire weapon",
		"Right-Click to aim in the opposite direction",
		"Press R to instantly restart the level",
		"Press lctrl+Q to quit immediately.",
		"Press K to toggle Keyboard Mode",
		"While in Keyboard Mode:",
		"\tarrow keys control the aim",
		"\tinstead of the mouse"
	}
	local str = ""
	for _, s in ipairs(lines) do
		str = str..s.."\n"
	end

	local textObj = loveframes.Create("text", frame)
	textObj:SetText(str)
	textObj:SetPos(20, 40)

	self.cntrlframe = frame

end

function MainMenuState:update(dt)
end

function MainMenuState:draw()
	love.graphics.setColor(1, 1, 1, 1)
	draw("title", nil, window.w/2, window.h/2, 0, window.w, window.h)
	-- love.graphics.rectangle("fill", 0, 0, window.w, window.h)
end