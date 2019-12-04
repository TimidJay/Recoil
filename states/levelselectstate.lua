LevelSelectState = class("LevelSelectState")

local difficulties = {
	"very_easy",
	"easy",
	"medium",
	"hard",
	"very_hard"
}

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
	list:AddColumn("#")
	list:AddColumn("Name")
	list:AddColumn("W")
	local width = list:GetWidth()
	list:SetColumnWidth(1, width/8 * 1)
	list:SetColumnWidth(2, width/8 * 6)
	list:SetColumnWidth(3, width/8 * 1)
	--disables the sorting effect when you click on list
	for _, col in ipairs(list.children) do
		col.enabled = false 
	end
	-- list.children[#list.children].enabled = false


	local names = levels[index]
	for i, n in ipairs(names) do
		list:AddRow(i, n, 0)
	end

	-- list:ResizeColumns()
	list:SetSelectionEnabled(false)

	return frame, list
end

function LevelSelectState:initialize()
	levelselectstate = self
	self.className = "LevelSelectState"

	local cx, cy = window.w/2, window.h/2

	local exitButton = make_button("Main Menu", cx, cy + 300, 100, 30)
	exitButton.OnClick = function(obj, x, y)
		game:pop()
	end

	self.lists = {}

	local levels = self:getLevels()

	local w, h = 200, 400
	for i = 1, 5 do
		local x = 100 + (i-1) * 210
		local y = window.w/2 - 500
		local frame, list = make_list(i, x, y, w, h, levels)

		list.OnRowClicked = function(obj, row, rowdata)
			local filename = rowdata[2]
			print("Play ".." "..filename)
			game:push(PlayState:new("play", filename))
		end

		table.insert(self.lists, list)
	end
end

function LevelSelectState:getLevels()
	self.all_levels = {}
	self.all_levels_lookup = {}
	self.column_list_lookup = {}

	local levels = {}
	for i = 1, 5 do
		levels[i] = {}
		self.column_list_lookup[i] = {}
	end
	local index = 0
	local size = 0
	for line in love.filesystem.lines("level_order.txt") do
		if #line > 0 then
			if line:sub(1, 1) == "[" then
				index = index + 1
				size = 0
			--check if file exists first
			elseif love.filesystem.getInfo("pushedLevels/"..line) then
				table.insert(levels[index], line)
				table.insert(self.all_levels, line)
				self.column_list_lookup[line] = {index, size+1}
				size = size + 1
			else
				print("Warning: Level "..line.." does not exist!")
			end
		end
	end

	for k, v in pairs(self.all_levels) do
		self.all_levels_lookup[v] = k
	end

	return levels
end

function LevelSelectState:beatLevel(level)
	local t = self.column_list_lookup[level]
	if not t then return end

	self.lists[t[1]]:SetCellText(1, t[2], 3)
end

function LevelSelectState:update(dt)
end

function LevelSelectState:draw()
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	love.graphics.rectangle("fill", 0, 0, window.w, window.h)
end