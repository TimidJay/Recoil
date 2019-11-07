-- game is a SINGLETON not a class
-- game acts like a container that stores objects between states

game = {}

--these shapes will be used for raycasting
--maybe turn these into complete sprites later on
-- game.wallShapes = {
-- 	lwall   = util.newRectangleShape(config.border_w, window.h       , 0            , 0           ),
-- 	rwall   = util.newRectangleShape(config.border_w, window.h       , config.wall_r, 0           ),
-- 	ceiling = util.newRectangleShape(window.w       , config.border_w, 0            , 0           ),
-- 	floor   = util.newRectangleShape(window.w       , config.border_w, 0            , config.floor)
-- }

game.walls = {
	left = Wall:new("left"),
	right = Wall:new("right"),
	up = Wall:new("up"),
	down = Wall:new("down")
}

--TODO: Change this to contain Recoil object types
-- game.listTypes = {"balls", "bricks", "projectiles", "powerups", "callbacks", "particles", "environments", "menacers", "enemies"}
game.listTypes = {"tiles", "projectiles", "particles"}

function game:initialize()
	self.states = {}

	self.newObjects = {}
	for _, str in pairs(self.listTypes) do
		self[str] = {}
		self.newObjects[str] = {}
	end
	self.gates = {}
end

function game:push(state)
	table.insert(self.states, state)
end

function game:pop()
	local top = self:top()
	if top.close then top:close() end
	self.states[#self.states] = nil
end

function game:top()
	return self.states[#self.states]
end

function game:update(dt)
	self:top():update(dt)
end

function game:draw()
	self:top():draw()
end

function game:emplace(str, obj)
	local t = self.newObjects[str]
	table.insert(t, obj)
end

function game:clearObjects()
	for _, str in pairs(self.listTypes) do
		util.clear(self[str])
		util.clear(self.newObjects[str])
	end
	for k, gate in pairs(self.gates) do
		gate:reset()
		self.gates[k] = nil
	end
end

function game.destructor(obj)
	if obj.onDeath then
		obj:onDeath()
	end
	if obj.destructor then
		obj:destructor()
	end
end