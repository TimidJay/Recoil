EditorState = class("EditorState")

tool = "free"

function EditorState:initialize(level)
	editorstate = self

	self.className = "EditorState"

	--level will contain the grid
	-- self.level = level
	self:setLevel(level)

	-- self:initGridLines()
	-- self.allNodes = self.level.allNodes

	self.selectedType = "tile"
	self.selectedValue = "block"

	self.actuatorCheck = false

	--gui stuff
	self.frames = {}

	self:initToolWindow(window.w-110, 290)
	self:initObjectWindow(window.w-165, 30)
	self:initSwitchWindow(window.w-415, 30)
	self:initLevelBrowserWindow(0, 30)
	self:initResizeWindow(260, 30)
	self:initMenuButtons()
end

--the default OnClose function deletes the frame
--however, I only want to hide the frame
local hide = function(obj)
	obj:SetVisible(false)
	return false
end

function EditorState:initResizeWindow(x, y)
	local level = self.level
	local frame = loveframes.Create("frame")
	frame.OnClose = hide
	frame:SetName("Resize Level")
	frame:SetPos(x, y)
	frame:SetSize(200, 180)
	frame:SetState("EditorState")

	local numbox1 = loveframes.Create("textinput", frame)
	numbox1:SetPos(125, 40)
	numbox1:SetSize(40, 18)
	numbox1:SetText(tostring(level.grid_w))
	local text1 = loveframes.Create("text", frame)
	text1:SetText("# of cells wide:")
	text1:SetPos(30, 40)
	self.numbox_w = numbox1

	local numbox2 = loveframes.Create("textinput", frame)
	numbox2:SetPos(125, 70)
	numbox2:SetSize(40, 18)
	numbox2:SetText(tostring(level.grid_h))
	local text2 = loveframes.Create("text", frame)
	text2:SetText("# of cells high:")
	text2:SetPos(30, 70)
	self.numbox_h = numbox2

	local warning = loveframes.Create("text", frame)
	warning:SetDefaultColor(1, 0, 0, 1)
	warning:SetText("WARNING: Level will be\ncleared upon Resizing.")
	warning:SetPos(30, 100)

	local butt = loveframes.Create("button", frame)
	butt:SetText("Resize")
	butt:SetPos(60, 140)
	butt.OnClick = function(obj, x, y)
		local w = tonumber(numbox1:GetText())
		local h = tonumber(numbox2:GetText())
		if not w or not h then return end
		if not (w >= 5 and w <= 100) then return end
		if not (h >= 5 and h <= 100) then return end

		self:setLevel(Level:new(w, h))
	end

	self.frames.resize = frame
end

function EditorState:initToolWindow(x, y)
	local frame = loveframes.Create("frame")
	frame.OnClose = hide
	frame:SetName("Tools")
	-- frame:ShowCloseButton(true)
	frame:SetPos(x, y)
	frame:SetWidth(100)
	frame:SetHeight(150)
	frame:SetState("EditorState")

	local tools = {
		"free",
		"rect",
		"fillrect"
	}
	for i, name in ipairs(tools) do
		local button = loveframes.Create("button", frame)
		button:SetPos(10, 40 + (i-1)*30)
		button:SetText(name)
		button.OnClick = function(obj)
			tool = name
		end
	end

	self.frames.tool = frame
end

local objKeys = {
	"block", 
	"block2", 
	"block3", 
	"block4", 
	"deathblock",
	"fallingblock",
	"donutblock",
	"shootblock",
	"bounceblock1",
	"bounceblock2",
	"", --add some padding to align the buttons
	"",
	"laser1",
	"laser2",
	"laser3",
	"laser4",
	"shield1",
	"shield2",
	"shield3",
	"shield4",
	"oneway1",
	"oneway2",
	"oneway3",
	"oneway4",
	"turret1",
	"turret2",
	"turret3",
	"turret4",
	"ammo"
}

function EditorState:initObjectWindow(x, y)
	local frame = loveframes.Create("frame")
	frame.OnClose = hide
	frame:SetName("Tiles")
	-- frame:ShowCloseButton(false)
	frame:SetPos(x, y)
	frame:SetWidth(160)
	frame:SetHeight(250)
	frame:SetState("EditorState")

	local list = loveframes.Create("list", frame)
	list:SetPos(5, 30)
	list:SetSize(150, 210)

	--panel should be tall enough to contain all the buttons
	local panel = loveframes.Create("panel", frame)
	panel:SetPos(5, 30)
	panel:SetSize(0, 500)
	panel:SetState("EditorState")
	list:AddItem(panel)

	local x0, y0 = 5, 5
	local w = 30
	local gridCoord = function(i, j)
		return x0 + (w * (j-1)), y0 + (w * (i-1))
	end

	self.objectButtons = {}

	for index, key in ipairs(objKeys) do
		local objData = data.objects[key]
		if objData then
			local objType = objData.type
			local ed = objData.editor

			local i = math.floor((index-1) / 4) + 1
			local j = ((index-1) % 4) + 1
			local button = loveframes.Create("imagebutton", panel)
			button:SetText("")
			button:SetPos(gridCoord(i, j))
			button:SetSize(30, 30)
			button.imgstr = ed.imgstr
			button.rect = ed.rect
			button.scale = 2
			button.deg = ed.deg
			if key == "ammo" then button.scale = 1 end
			button.offx = 15
			button.offy = 15

			button.OnClick = function(obj, x, y)
				self:select(objType, key)
				obj.highlight = true
				for _, b in ipairs(self.objectButtons) do
					if b ~= obj then
						b.highlight = false 
					end
				end
			end
			table.insert(self.objectButtons, button)

			--these tooltips are causing problems
			--they interfere with the cursor hovering
			local tooltip = loveframes.Create("tooltip")
			tooltip:SetObject(button)
			tooltip:SetText(ed.name)
			-- tooltip:SetFollowCursor(false)
			-- tooltip:SetFollowObject(true)
			tooltip:SetState("EditorState")
		end
	end

	self.objectButtons[1].highlight = true
	

	self.frames.tile = frame
end

function EditorState:initSwitchWindow(x, y)
	local frame = loveframes.Create("frame")
	frame.OnClose = hide
	frame:SetName("Switch Blocks")
	-- frame:ShowCloseButton(false)
	frame:SetPos(x, y)
	frame:SetWidth(240)
	frame:SetHeight(180)
	frame:SetState("EditorState")

	local choice = loveframes.Create("multichoice", frame)
	choice:SetPos(10, 40)
	choice:SetWidth(90)
	local colors = {
		red = "switch1",
		green = "switch2",
		blue = "switch3" ,
		yellow = "switch4"
	}
	for c, v in pairs(colors) do
		choice:AddChoice(c)
	end
	choice:SetChoice("red")
	choice.OnChoiceSelected = function(obj, col)

		if self.selectedType == "actuator" then
			self.selectedValue = col
			if self.actuatorCheck then
				self.selectedValue = "-"..self.selectedValue
			end
		elseif self.selectedType == "tile" then
			if self.selectedValue:sub(1, 6) == "switch" then
				self.selectedValue = colors[col]
			end
		end
	end

	local button1 = loveframes.Create("button", frame)
	button1:SetText("Switch Block")
	button1:SetPos(110, 40)
	button1.OnClick = function(obj, x, y)
		local col = choice:GetChoice()
		local key = colors[col]
		-- self.selectedTile = key
		-- self.selectedActuator = nil

		self:select("tile", key)
	end

	local button2 = loveframes.Create("button", frame)
	button2:SetText("Actuator")
	button2:SetPos(110, 80)
	button2.OnClick = function(obj, x, y)
		local col = choice:GetChoice()
		-- self.selectedActuator = col
		self:select("actuator", col)
		if self.actuatorCheck then
			self.selectedValue = "-"..self.selectedValue
		end
	end

	local check = loveframes.Create("checkbox", frame)
	check:SetText("Set Triggered")
	check:SetPos(110, 120)
	check.OnChanged = function(obj, value)
		self.actuatorCheck = value
		if self.selectedType == "actuator" then
			if value then
				self.selectedValue = "-"..self.selectedValue
			else
				self.selectedValue = self.selectedValue:sub(2, -1)
			end
			print(self.selectedValue)
		end
	end

	self.frames.switch = frame
end

function EditorState:initLevelBrowserWindow(x, y)
	local frame = loveframes.Create("frame")
	frame.OnClose = hide
	frame:SetName("Level Browser")
	frame:SetPos(x, y)
	frame:SetWidth(250)
	frame:SetHeight(500)
	frame:SetState("EditorState")

	local tabs = loveframes.Create("tabs", frame)
	tabs:SetPos(10, 40)
	tabs:SetWidth(200)

	local textBox = loveframes.Create("textinput", frame)
	textBox:SetPos(10, 420)
	textBox:SetEditable(true)

	local panel = loveframes.Create("panel")
	panel.Draw = function() end --make it invisible

	local panel2 = loveframes.Create("panel")
	panel2.Draw = function() end

	local fileList = loveframes.Create("columnlist", panel)
	fileList:SetPos(0, 0)
	fileList:SetSize(200, 340)
	fileList:AddColumn("Filename")
	fileList.refresh = function(obj)
		obj:Clear()
		local filenames = love.filesystem.getDirectoryItems("levels")
		for _, name in ipairs(filenames) do
			obj:AddRow(name)
		end
	end
	fileList:refresh()
	fileList:ResizeColumns()
	fileList.OnRowClicked = function(obj, row, rowdata)
		local filename = rowdata[1]
		textBox:SetText(filename)
	end

	local fileList2 = loveframes.Create("columnlist", panel2)
	fileList2:SetPos(0, 0)
	fileList2:SetSize(200, 340)
	fileList2:AddColumn("Filename")
	fileList2.refresh = function(obj)
		obj:Clear()
		local filenames = love.filesystem.getDirectoryItems("default_levels")
		for _, name in ipairs(filenames) do
			obj:AddRow(name)
		end
	end
	fileList2:refresh()
	fileList2:ResizeColumns()
	fileList2.OnRowClicked = function(obj, row, rowdata)
		local filename = rowdata[1]
		textBox:SetText(filename)
	end

	tabs:AddTab("Local Levels", panel)
	tabs:AddTab("Default Levels", panel2)

	local saveButton = loveframes.Create("button", frame)
	saveButton:SetText("Save")
	saveButton:SetPos(10, 460)
	saveButton.OnClick = function(obj, x, y)
		local filename = textBox:GetText()
		if #filename > 0 then
			saveLevel(filename)
			fileList:refresh()
		end
	end

	local loadButton = loveframes.Create("button", frame)
	loadButton:SetText("Load")
	loadButton:SetPos(100, 460)
	loadButton.OnClick = function(obj, x, y)
		local filename = textBox:GetText()
		local pushed = (tabs:GetTabNumber() == 2)
		if #filename > 0 then
			loadLevel(filename, pushed)
		end
	end

	self.frames.browser = frame
end

function EditorState:initMenuButtons()
	self.menuButtons = {}
	local items = {
		{"browser", "Save/Load"},
		{"resize", "Resize Level"},
		{"tool", "Toolbar"},
		{"tile", "Objects"},
		{"switch", "Switches/Actuator"},
	}

	local x0, y0 = 80, 2
	local w, h = 120, 20
	local gap = 10

	for i, v in pairs(items) do
		local button = loveframes.Create("button")
		button:SetText(v[2])
		button:SetPos(x0+(i-1)*(w+gap), y0)
		button:SetSize(w, h)
		local frame = self.frames[v[1]]
		button.OnClick = function(obj, x, y)
			frame:SetVisible(true)
		end
		button:SetState("EditorState")
		table.insert(self.menuButtons, button)
	end

	local button = loveframes.Create("button")
	button:SetText("Main Menu")
	button:SetPos(window.w - 120 - 10, 2)
	button:SetSize(120, 20)
	button.OnClick = function(obj, x, y)
		game:pop()
	end
	button:SetState("EditorState")
end

function EditorState:setLevel(level)
	self.level = level
	self:initGridLines()
	self.allNodes = self.level.allNodes
	camera:clampToLevel(self.level)
end

function EditorState:close()
	editorstate = nil

	for k, frame in pairs(self.frames) do
		frame:Remove()
	end
	for _, butt in ipairs(self.menuButtons) do
		butt:Remove()
	end
end

function EditorState:reset()
	for _, n in ipairs(self.allNodes) do
		n:clear()
	end
	self.pit = {}
end

--possible types: "tile", "enemy", "actuator"
function EditorState:select(objType, value)
	self.selectedType = objType
	self.selectedValue = value
end

function openSaveDirectory()
	love.system.openURL("file://"..love.filesystem.getSaveDirectory())
end

--global function for easier access
function saveLevel(filename)
	-- if game:top() ~= editorstate then
	-- 	print("Make sure you're in the Level Editor state!")
	-- 	return
	-- end
	-- editorstate:saveLevel(filename)
	Level.save(editorstate.level, filename)
end

function loadLevel(filename, is_default)
	if game:top() ~= editorstate then
		print("Make sure you're in the Level Editor state!")
		return
	end
	editorstate:loadLevel(filename, is_default)
end

function EditorState:loadLevel(filename, is_default)
	local level = Level.load(filename, is_default)
	if level then
		self:setLevel(level)
		self.numbox_w:SetText(level.grid_w)
		self.numbox_h:SetText(level.grid_h)
	end
end

--checks if the mouse overlaps a loveframes object
function EditorState.containMouse(obj)
	local x, y = obj:GetPos()
	local w, h = obj:GetSize()
	local mx, my = mouse.x, mouse.y

	return mx > x and mx < x+w and my > y and my < y+h
end

--sets overlap grid for non-tile objects such as gates
function EditorState:setOverlap()
	local level = self.level
	local overlap = {}
	for i = 1,  level.grid_w do
		overlap[i] = {}
	end
	for k, g in pairs(level.gates) do
		local t = g:getOccupiedCoords()
		for _, p in ipairs(t) do
			local i, j = p[1], p[2]
			overlap[i][j] = k --Only one object can occupy a cell at a time
		end
	end
	self.overlap = overlap
end

--checks if node is already occupied by a gate (or other objects?)
function EditorState:notOverlapping(node)
	for k, gate in pairs(self.level.gates) do
		if gate.occupied[node] then
			return false
		end
	end
	return true
end

--checks if the gate does not overlap the other gate
function EditorState:gateValidPos(choice, name)
	local level = self.level

	local i, j = choice[3], choice[4]
	local dir = choice[1]
	local t = {}
	if dir == "up" or dir == "down" then
		for d = -2, 2 do
			table.insert(t, {i, j+d})
		end
	else
		for d = -2, 2 do
			table.insert(t, {i+d, j})
		end
	end

	local other = level.gates[(name == "enter") and "exit" or "enter"]
	for _, v in ipairs(t) do
		local node = level.objectGrid[v[1]][v[2]]
		if other.occupied[node] then
			return false
		end
	end
	return true
end

function EditorState:update(dt)

	local mx, my = mouse.cx, mouse.cy
	local mi, mj = getGridPos(mx, my)

	local level = self.level
	local grid = level.objectGrid

	if keys.escape then

		self:startTest()
		return
	end

	for _, n in ipairs(self.allNodes) do
		n.highlight = false
	end

	--don't interact with background if mouse is in a gui
	for k, f in pairs(self.frames) do
		if f:GetVisible() and EditorState.containMouse(f) then
			return 
		end
	end

	--dragging gates around
	local gates = level.gates

	if mouse.m1 == 1 and gates.enter:containMouse() then
		self.drag = "enter"
	elseif mouse.m1 == 1 and gates.exit:containMouse() then
		self.drag = "exit"
	end

	if self.drag then
		local gate = gates[self.drag]
		gate.dragged = true
		--get closest point to edge
		local gw, gh = level.grid_w, level.grid_h
		local i, j = mi, mj
		i2 = math.min(math.max(i, 3), gh - 2)
		j2 = math.min(math.max(j, 3), gw - 2)
		local candidates = {
			{"up"   , math.abs(i - 1) , 1 , j2 },
			{"down" , math.abs(i - gh), gh, j2 },
			{"left" , math.abs(j - 1) , i2 , 1 },
			{"right", math.abs(j - gw), i2 , gw} 
		}
		local choice = candidates[1]
		for _, v in pairs(candidates) do
			if v[2] < choice[2] then
				choice = v
			end
		end
		if self:gateValidPos(choice, self.drag) then
			--move the gate to that location
			gate:setPos2(choice[3], choice[4])
			gate:setDirection(choice[1])
		end
		--after dragging is done, update the overlap grid
		if not mouse.m1 then
			self.drag = nil
			gate.dragged = false
			gate:setOccupiedNodes()
			gate:clearOccupiedNodes()
			gate:setHoles()
		end
	--tool usage
	--TODO: Add copy/paste for easier level resizing
	elseif self.level:boundCheck(mi, mj) then
		if tool == "free" then
			local node = grid[mi][mj]
			node.highlight = true

			if self:notOverlapping(node) then
				if mouse.m1 then
					node:setObject(self.selectedType, self.selectedValue)
					-- if self.selectedActuator then
					-- 	node:setActuator(self.selectedActuator)
					-- else
					-- 	node:setTile(self.selectedTile)
					-- end
				elseif mouse.m2 then
					node:clear()
				end
			end
		elseif tool == "rect" or tool == "fillrect" then
			if mouse.m1 or mouse.m2 then
				self.selectedNodes = {}
				if mouse.m1 == 1 or mouse.m2 == 1 then
					self.clicked = {
						i = mi, 
						j = mj, 
						mode = (mouse.m1 == 1) and 1 or 2
					}
				end
				if self.clicked then
					local c = self.clicked

					local i0, i1 = c.i, mi
					local j0, j1 = c.j, mj
					if mi < c.i then
						i0, i1 = mi, c.i
					end
					if mj < c.j then
						j0, j1 = mj, c.j
					end

					for i = i0, i1 do
						for j = j0, j1 do
							if tool == "fillrect" or i == i0 or i == i1 or j == j0 or j == j1 then
								local node = grid[i][j]
								node.highlight = true
								table.insert(self.selectedNodes, node)
							end
						end
					end
				end
			elseif self.clicked then
				for _, node in ipairs(self.selectedNodes) do
					if self:notOverlapping(node) then
						if self.clicked.mode == 1 then
							node:setObject(self.selectedType, self.selectedValue)
							-- if self.selectedActuator then
							-- 	node:setActuator(self.selectedActuator)
							-- else
							-- 	node:setTile(self.selectedTile)
							-- end
						else
							node:clear()
						end
					end
				end
				self.clicked = nil
			end

		end
	--pit placement
	elseif (mi > level.grid_h and mi < level.grid_h + 3)  and mj >= 1 and mj <= level.grid_w then
		local wall = level.walls.down
		local val = wall:getHole(0, mj)
		if (val == "normal") or (not val) then
			if mouse.m2 then
				wall:setHole(0, mj, "normal")
			elseif mouse.m1 then
				wall:setHole(0, mj, false)
			end
		end
	end

	--camera movement
	local camera_speed = 500
	local dx, dy = 0, 0

	--move if mouse cursor is at edge of screen
	--but what about the gui elements?
	-- local x, y = mouse.x, mouse.y
	-- local band_w = CELL_WIDTH

	-- if x <= band_w then dx = -1 end
	-- if x >= window.w - band_w then dx = 1 end
	-- if y <= band_w then dy = -1 end
	-- if y >= window.h - band_w then dy = 1 end

	if love.keyboard.isDown("w") then dy = -1 end
	if love.keyboard.isDown("a") then dx = -1 end
	if love.keyboard.isDown("s") then dy = 1 end
	if love.keyboard.isDown("d") then dx = 1 end
	camera.x = camera.x + dx * dt * camera_speed
	camera.y = camera.y + dy * dt * camera_speed
	camera:clampToLevel(self.level)
end

-- switches the game to test mode

function EditorState:startTest()
	game:push(PlayState:new(self.level, "test"))
end

function EditorState:draw()
	--any HUD elements should be drawn independent of the camera
	camera:push()

	self.level:drawBackground()
	for k, w in pairs(self.level.walls) do
		w:draw()
	end
	--draw gridnodes (cells)
	for _, node in ipairs(self.allNodes) do
		node:draw()
	end
	for k, g in pairs(self.level.gates) do
		g:draw()
	end
	for _, node in ipairs(self.allNodes) do
		node:drawHighlight()
	end
	self:drawGridLines()

	camera:pop()

	--draw makeshift menubar
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", 0, 0, window.w, 26)
	love.graphics.setColor(0.9, 0.9, 0.9, 1)
	love.graphics.rectangle("fill", 0, 0, window.w, 24)
	--personal fps rectangle
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	love.graphics.rectangle("fill", 2, 2, 60, 20)
end

--predraw the gridlines to a canvas because drawing dashed lines
--is really expensive
--There needs to be a level size limit because certain old gpus
--do not support extremely large canvases
function EditorState:initGridLines()
	local level = self.level

	local canvas = love.graphics.newCanvas(level.fullWidth, level.fullHeight)
	love.graphics.setCanvas(canvas)
	love.graphics.origin()

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1)
	
	local grid_w = level.grid_w
	local grid_h = level.grid_h
	local width = level.fullWidth
	local height = level.fullHeight
	local start = level.inner_y0

	--don't use util.lineStipple because it's very expensive
	local line = love.graphics.line
	for i = 1, grid_h+1 do
		local y = start + (i-1) * CELL_WIDTH
		local x0, x1 = 0, 8
		while(x1 < width) do
			line(x0, y, x1, y)
			x0, x1 = x0 + 10, x1 + 10
		end
	end
	for j = 1, grid_w+1 do
		local x = start + (j-1) * CELL_WIDTH 
		local y0, y1 = 0, 8
		while (y1 < height) do
			line(x, y0, x, y1)
			y0, y1 = y0 + 10, y1 + 10
		end
	end

	love.graphics.setCanvas()
	self.gridLineCanvas = canvas
end

--need to compensate for fullscreen
function EditorState:drawGridLines()
	love.graphics.push()
	if fullscreen then
		-- love.graphics.origin()
	end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.gridLineCanvas)
	love.graphics.pop()
end