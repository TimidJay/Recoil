OneWayBlock = class("OneWayBlock", Block)


function OneWayBlock:initialize(i, j, dir)
	local deg = 0
	if dir == "up" then
		deg = 0
	elseif dir == "right" then
		deg = 90
	elseif dir == "down" then
		deg = 180
	elseif dir == "left" then
		deg = 270
	end
	Block.initialize(self, i, j)
	self.imgstr = "oneway"
	self:setAngle(math.rad(deg))
	self.dir = dir
end

local normals = {
	up = {0, -1},
	right = {1, 0},
	down = {0, 1},
	left = {-1, 0}
}

--only check for collision if player is going in opposite direction
function OneWayBlock:checkPlayerCollision(player)
	local norm = normals[self.dir]
	local nx, ny = norm[1], norm[2]
	local vx, vy = player:getVel()

	local check, dx, dy = Block.checkPlayerCollision(self, player)
	if check and (dx * nx + dy * ny > 0) then
		return true, dx, dy
	end
	return false
end