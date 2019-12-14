camera = {}

--Camera is a singleton

--TODO: Fix player aiming

camera.x, camera.y = 0, 0
camera.oldMouseX = 0
camera.oldMouseY = 0

function camera:push()
	love.graphics.push()
	love.graphics.translate(-self.x, -self.y)
end

function camera:pop()
	love.graphics.pop()
end

function camera:centerOnPlayer(player)
	local px, py = player:getPos()
	self.x = px - window.w/2
	self.y = py - window.h/2
end

function camera:clampToLevel(level)
	if level.fullWidth < window.w then
		self.x = (window.w - level.fullWidth)/-2
	else
		self.x = math.max(0, math.min(self.x, level.fullWidth - window.w))
	end

	if level.fullHeight < window.h then 
		self.y = (window.h - level.fullHeight)/-2
	else 
		self.y = math.max(0, math.min(self.y, level.fullHeight - window.h))
	end
end