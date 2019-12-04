LevelSelectState = class("LevelSelectState")

local difficulties = {
	"very_easy",
	"easy",
	"medium",
	"hard",
	"very_hard"
}

local function getLevels()
	local levels = {}
	for i = 1, 5 do
		levels[i] = {}
	end
	local index = 0
	for line in love.filesystem.lines("level_order.txt") do
		if #line > 0 then
			if line:sub(1, 1) == "[" then
				index = index + 1
			--check if file exists first
			elseif love.filesystem.getInfo("pushedLevels/"..line) then
				table.insert(levels[index], line)
			end
		end
	end

	return levels
end

local function make_button(name, x, y, w, h)
	local butt = loveframes.Create("button")
	butt:SetText(name)
	butt:SetPos(x-w/2, y-h/2)
	butt:SetSize(w, h)
	butt:SetState("LevelSelectState")
	return butt
end

--includes the frame
local function make_list(index, x, y, w, h, levels)
	local frame = loveframes.Create("frame")
	frame:SetName(difficulties[index])
	frame:SetPos(x, y)
	frame:SetSize(w, h)
	frame:SetState("LevelSelectState")

	local list = loveframes.Create("columnlist", frame)
	list:SetPos(10, 35)
	list:SetSize(w - 20, h - 45)
	list:AddColumn("Name")
	--disables the sorting effect when you click on list
	list.children[#list.children].enabled = false


	local names = levels[index]
	for i, n in ipairs(names) do
		list:AddRow(n)
	end

	list:ResizeColumns()
	list:SetSelectionEnabled(false)

	return frame, list
end

function LevelSelectState:initialize()
	self.className = "LevelSelectState"

	local cx, cy = window.w/2, window.h/2

	local exitButton = make_button("Main Menu", cx, cy + 300, 100, 30)
	exitButton.OnClick = function(obj, x, y)
		game:pop()
	end

	local levels = getLevels()

	local w, h = 200, 400
	for i = 1, 5 do
		local x = 100 + (i-1) * 210
		local y = window.w/2 - 500
		local frame, list = make_list(i, x, y, w, h, levels)

		list.OnRowClicked = function(obj, row, rowdata)
			local filename = rowdata[1]
			print("Play ".." "..filename)
			game:push(PlayState:new("play", filename))
		end
	end
end

function LevelSelectState:update(dt)
end

function LevelSelectState:draw()
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	love.graphics.rectangle("fill", 0, 0, window.w, window.h)
end