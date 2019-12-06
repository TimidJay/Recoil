LaserBlock = class("LaserBlock", Block)

local laserData = {
	up    = {i = 1, j = 1, di = -1, dj =  0},
	right = {i = 1, j = 2, di =  0, dj =  1},
	down  = {i = 1, j = 3, di =  1, dj =  0},
	left  = {i = 1, j = 4, di =  0, dj = -1}
}

function LaserBlock:initialize(i, j, dir)
	Block.initialize(self, i, j)
	self.imgstr = "laserblock"
	local t = laserData[dir]
	self.rect = rects.tile[t.i][t.j]

	self.dir = dir
	self.di = t.di
	self.dj = t.dj
	self.stop = 0

	self.disabled = false
end
--scan the blocks in front of the laserblock to
--determine when the laser should stop
function LaserBlock:fireLaser()
	local i, j = self.i, self.j
	local di, dj = self.di, self.dj
	i, j = i + di, j + dj

	while boundCheck(i, j) do
		for _, tile in ipairs(playstate.tileGrid[i][j]) do
			if tile.tangible then
				--self.stop is a scalar that represents length of laser
				-- self.stop = math.abs(i - self.i) + math.abs(j - self.j)
				-- self.stop = self.stop * self.w - self.w/2

				local check, t = tile.shape:intersectsRay(self.x, self.y, dj, di)
				if check and t >= 0 then
					self.stop = t
					return
				end
				-- return
			end
		end
		i, j = i + di, j + dj
	end
	--if there are no blocks then collide with the wall
	self.stop = math.abs(i - self.i) + math.abs(j - self.j)
	self.stop = self.stop * self.w - self.w/2
	--might have to add gate collision later
end

--check if player touches laser and kill him if he does
function LaserBlock:shootPlayer()
	local ray = {self.x, self.y, self.dj, self.di}
	local player = playstate.player
	local check, t = player.shape:intersectsRay(unpack(ray))
	if check and t > 0 and t < self.stop then
		player.dead = true
	end
end

function LaserBlock:onTrigger()
	self.disabled = not self.disabled
end

function LaserBlock:update(dt)
	if not self.disabled then
		self:fireLaser()
		self:shootPlayer()
	end
	Block.update(self, dt)
end

function LaserBlock:draw()
	if not self.disabled then
		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.setLineWidth(5)
		love.graphics.setLineStyle("smooth")

		local x0, y0 = self:getPos()
		local x1 = x0 + self.stop * self.dj
		local y1 = y0 + self.stop * self.di

		love.graphics.line(x0, y0, x1, y1)

		love.graphics.setColor(1, 1, 1, 1)
	end
	Block.draw(self)
end