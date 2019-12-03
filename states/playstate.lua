PlayState = class("PlayState")

function PlayState:initialize(mode)
	playstate = self

	self.className = "PlayState"

	self.mode = mode or "play"
	self.state = "playing" --playing, death, victory
	self.player = Player:new(game.gates.enter:getPos())
	game.gates.enter:ejectPlayer(self.player)

	--initializes tile grid for collision detection
	self.tileGrid = {}
	for i = 1, config.grid_h do
		table.insert(self.tileGrid, {})
	end
	self:setTileGrid()

	love.mouse.setCursor(cursors.ready)
end

function PlayState:close()
	love.mouse.setCursor()
	playstate = nil
end

--partions tiles to a grid based on its position
--can now do moving blocks
function PlayState:setTileGrid()
	local grid = self.tileGrid
	for i = 1, config.grid_h do
		for j = 1, config.grid_w do
			grid[i][j] = {}
		end
	end
	for _, t in ipairs(game.tiles) do
		if t:isAlignedToGrid() then
			--simple partioning
			table.insert(grid[t.i][t.j], t)
		else
			--insert the same block in 4 adj grid cells
			local cx, cy = t:getPos()
			local gx, gy = getGridPosInv(t.i, t.j)
			local dj, di = -1, -1
			if cx > gx then
				dj = 1
			end
			if cy > gy then
				di = 1
			end
			for i = 0, di, di do
				for j = 0, dj, dj do
					local ii, jj = t.i + i, t.j + j
					if boundCheck(ii, jj) then
						table.insert(grid[ii][jj], t)
					end
				end
			end
		end
	end
end

-- returns a list of tiles adjacent to the player in
-- the following order:
-- 	7 4 8
-- 	3 P 2
-- 	6 1 5
-- note that the tile in the same spot as P is ignored because
-- the player shouldn't be that far inside a tile
-- Also, if no tile exists at that location, it will be skipped
function PlayState:getAdjTiles(player)
	local i, j = getGridPos(player:getPos())
	local candidates = {}
	local coords = {
		i+1, j+0,
		i+0, j+1,
		i+0, j-1,
		i-1, j+0,
		i+1, j+1,
		i+1, j-1,
		i-1, j-1,
		i-1, j+1
	}
	local duplicate = {} --check for duplicates
	local static = {} --this has higher priority
	local nonStatic = {} --non static (moving bricks) have less priority
	for index = 1, 16, 2 do
		local ti, tj = coords[index], coords[index+1]
		if boundCheck(ti, tj) then
			local li = self.tileGrid[ti][tj]
			for _, tile in ipairs(li) do
				if not duplicate[tile] then
					if tile.static then
						table.insert(static, tile)
					else
						table.insert(nonStatic, tile)
					end
					duplicate[tile] = true
				end
			end
		end
	end
	for i, v in ipairs(nonStatic) do
		table.insert(static, v)
	end
	return static
end

--returns a list of shapes that can be hit by a gun
function PlayState:getRaycastShapes()
	local shapes = {}
	for _, block in ipairs(game.tiles) do
		if block.shieldShape and not block.disabled then
			table.insert(shapes, block.shieldShape)
		end
		if block.tangible then
			table.insert(shapes, block.shape)
		end
	end
	for _, w in pairs(game.walls) do
		table.insert(shapes, w.shape)
	end
	for _, gate in pairs(game.gates) do
		for _, s in ipairs(gate:getShapes()) do
			table.insert(shapes, s)
		end
	end
	return shapes
end


local function spriteOverlap(a, b)
	local ax, ay, aw, ah = a.x, a.y, a.w/2, a.h/2
	local bx, by, bw, bh = b.x, b.y, b.w/2, b.h/2
	if (ax + aw < bx - bw) or (ax - aw > ax + bw) then
		return false
	end
	if (ay + ah < by - bh) or (ay - ah > by + bh) then
		return false
	end
	return true
end

-- 1. check object collisions
-- 2. update movement
-- 3. add the new objects into the game

use_keyboard_controls = false --debug

function PlayState:update(dt)
	local player = self.player

	if self.mode == "test" and keys.escape then
		game:clearObjects()
		game:pop()
	end

	if keys.k == 1 then
		use_keyboard_controls = not use_keyboard_controls
	end

	if use_keyboard_controls then
		local x, y = 0, 0
		if love.keyboard.isDown("left") then x = -1 end
		if love.keyboard.isDown("right") then x = 1 end
		if love.keyboard.isDown("up") then y = -1 end
		if love.keyboard.isDown("down") then y = 1 end

		if x == 0 and y == 0 then
			x, y = 0, 1
		end

		local d = 100
		local px, py = self.player:getPos()
		mouse.x, mouse.y = px + x*d, py + y*d

		
	end
	--this is useful even for mouse controls
	if keys.lshift then
		mouse.m1 = 1
	end



	if self.state == "death" or self.state == "victory" then
		return
	end

	--temporary
	if player.dead then
		self.state = "death"
	end

	--Player out of bounds check
	local px, py = player:getPos()
	local pw, ph = player:getDim()
	local pvx, pvy = player:getVel()
	pw, ph = pw/2, ph/2

	if px+pw < 0 or px-pw > window.w or py+ph < 0 or py-ph > window.h then
		self.state = "death"
	end

	local check, dir = false, nil
	if px+pw < 0 and pvx < 0 then
		check = true
		dir = "left"
	elseif px-pw > window.w and pvx > 0 then
		check = true
		dir = "right"
	elseif py+ph < 0 and pvy < 0 then
		check = true
		dir = "up"
	elseif py-ph > window.h and pvy > 0 then
		check = true
		dir = "down"
	end

	if check then
		self.state = "death"
		if dir == game.exit.dir then
			local pi, pj = getGridPos(px, py)
			local coords = game.exit.coords
			if dir == "up" or dir == "down" then
				if pj >= coords[1][2] and pj <= coords[3][2] then
					self.state = "victory"
				end
			else
				if pi >= coords[1][1] and pi <= coords[3][1] then
					self.state = "victory"
				end
			end
		end
	end

	--collision stuff
	player.touchingGround = false

	self:setTileGrid()

	--Player collision with wall
	for _, wall in pairs(game.walls) do
		local check, dx, dy = wall:checkPlayerCollision(player)
		if check then
			player:handleCollision(dx, dy)
		end
	end
	
	--Player collision with tiles
	for _, t in ipairs(self:getAdjTiles(player)) do
		local check, dx, dy = t:checkPlayerCollision(player)
		if check and player:validCollision(dx, dy) then
			t:onPlayerHit(player)
			player:handleCollision(dx, dy)
			if t.onPlayerHit2 then t:onPlayerHit2(player) end --temporary
		end
	end

	--Player collision with items

	for _, item in ipairs(game.items) do
		local check, dx, dy = item:checkSpriteCollision(player)
		if check then
			item:onPlayerHit(player)
		end
	end


	--Player collision with gates
	for _, gate in pairs(game.gates) do
		local check, dx, dy = gate:checkPlayerCollision(player)
		if check and player:validCollision(dx, dy) then
			player:handleCollision(dx, dy)
		end
	end

	--update each object
	self.player:update(dt)
	for _, k in pairs(game.listTypes) do
		for _, v in pairs(game[k]) do
			v:update(dt)
		end
	end

	for _, gate in pairs(game.gates) do
		gate:update(dt)
	end

	--remove dead objects
	for _, k in pairs(game.listTypes) do
		util.remove_if(game[k], function(v) return v:isDead() end, game.destructor)
	end

	--add objects from the new object queue
	for str, new_objects in pairs(game.newObjects) do
		local objects = game[str]
		for k, v in ipairs(new_objects) do
			table.insert(objects, v)
			--don't worry, this won't cause undefined behavior
			new_objects[k] = nil
		end
	end
end

function PlayState:draw()
	-- love.graphics.setColor(0.5, 0.5, 0.5, 1)
	-- local rec = love.graphics.rectangle
	-- rec("fill" , 0, config.floor, window.w, config.border_w) --floor
	-- rec("fill" , 0, 0, window.w, config.border_w) --ceiling
	-- rec("fill" , 0, 0, config.border_w, window.h) --left wall
	-- rec("fill" , config.wall_r, 0, config.border_w, window.h) --right wall
	-- love.graphics.setColor(1, 1, 1, 1)

	--drawing order is important here
	for _, w in pairs(game.walls) do
		w:draw()
	end
	for _, t in ipairs(game.tiles) do
		t:draw()
		t:drawActuator()
	end
	for _, e in ipairs(game.enemies) do
		e:draw()
	end
	self.player:draw()
	for _, p in ipairs(game.particles) do
		p:draw()
	end
	for _, p in ipairs(game.projectiles) do
		p:draw()
	end
	for _, it in ipairs(game.items) do
		it:draw()
	end
	game.gates.enter:draw()
	game.gates.exit:draw()

	if self.state == "death" then
		draw("red_x", nil, window.w/2, window.h/2)
	elseif self.state == "victory" then
		draw("green_check", nil, window.w/2, window.h/2)
	end
end