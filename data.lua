data = {}

--the keys are also known as id
data.tiles = {
	--args will contain all arguments after the i, j params, if they exist
	--editor is the displayed image for the level editor
	block      = {class = Block     , args = {}, editor = {name = "Regular Block", imgstr = "brick", rect = nil}},
	deathblock = {class = DeathBlock, args = {}, editor = {name = "Death Block", imgstr = "death_brick", rect = nil}},
}

--each value should also contain its own key
for k, v in pairs(data.tiles) do
	v.key = k
end