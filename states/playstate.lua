PlayState = class("PlayState")

function PlayState:initialize(mode)
	playstate = self

	self.mode = mode or "play"
	self.player = Player:new(game.gates.enter:getPos())
	game.gates.enter:ejectPlayer(self.player)
	self:setTileGrid()
end

function PlayState:close()
	playstate = nil
end

--initializes tile grid for collision detection
--should be called after the tiles are constructed
function PlayState:setTileGrid()
	local grid = {}
	for i = 1, config.grid_h do
		table.insert(grid, {})
	end
	for _, t in ipairs(game.tiles) do
		grid[t.i][t.j] = t
	end
	self.tileGrid = grid
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
	for index = 1, 16, 2 do
		local ti, tj = coords[index], coords[index+1]
		if boundCheck(ti, tj) then
			local tile = self.tileGrid[ti][tj]
			if tile then
				table.insert(candidates, tile)
			end
		end
	end
	return candidates
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
	if self.mode == "test" and keys.escape then
		game:clearObjects()
		game:pop()
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

		if keys.lshift then
			mouse.m1 = 1
		end
	end

	local player = self.player
	player.touchingGround = false

	--Player collision with wall
	local px, py = player:getPos()
	local pw, ph = player:getDim()
	pw, ph = pw/2, ph/2
	local floor, lwall, rwall, ceil = config.floor, config.wall_l, config.wall_r, config.ceil

	local dy = ceil - (py - ph)
	if dy > 0 and player:validCollision(0, dy) then
		player:handleCollision(0, dy)
	end

	local dy = floor - (py + ph)
	if dy < 0 and player:validCollision(0, dy) then
		player:handleCollision(0, dy)
	end

	local dx = lwall - (px - pw)
	if dx > 0 and player:validCollision(dx, 0) then
		player:handleCollision(dx, 0)
	end

	local dx = rwall - (px + pw)
	if dx < 0 and player:validCollision(dx, 0) then
		player:handleCollision(dx, 0)
	end 
	
	--Player collision with tiles
	for _, t in ipairs(self:getAdjTiles(player)) do
		local check, dx, dy = t:checkPlayerCollision(player)
		if check and player:validCollision(dx, dy) then
			player:handleCollision(dx, dy)
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
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	local rec = love.graphics.rectangle
	rec("fill" , 0, config.floor, window.w, config.border_w) --floor
	rec("fill" , 0, 0, window.w, config.border_w) --ceiling
	rec("fill" , 0, 0, config.border_w, window.h) --left wall
	rec("fill" , config.wall_r, 0, config.border_w, window.h) --right wall
	love.graphics.setColor(1, 1, 1, 1)
	
	for _, t in ipairs(game.tiles) do
		t:draw()
	end
	--draw order is important
	self.player:draw()
	for _, p in ipairs(game.particles) do
		p:draw()
	end
	for _, p in ipairs(game.projectiles) do
		p:draw()
	end
	game.gates.enter:draw()
	game.gates.exit:draw()
end