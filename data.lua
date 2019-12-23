data = {}

--the keys are also known as id
--make sure each key is unique across all 3 tables
data.tile = {
	--args will contain all arguments after the i, j params, if they exist
	--editor is the displayed image for the level editor
	block = {class = Block, args = {1}, editor = {name = "Regular Block", imgstr = "brick", rect = nil}},
	block2 = {class = Block, args = {2}, editor = {name = "Regular Block", imgstr = "brick2", rect = nil}},
	block3 = {class = Block, args = {3}, editor = {name = "Regular Block", imgstr = "brick3", rect = nil}},
	block4 = {class = Block, args = {4}, editor = {name = "Regular Block", imgstr = "brick4", rect = nil}},
	deathblock = {class = DeathBlock, args = {}, editor = {name = "Death Block", imgstr = "death_brick", rect = nil}},
    switchblock = {class = SwitchBlock, args = {}, editor = {name = "Switch Block", imgstr = "bluebrick", rect = nil}},
    shootblock = {class = ShootBlock, args = {}, editor = {name = "Shoot Block", imgstr = "shootBlock1", rect = nil}},
    bounceblock1 = {class = BounceBlock1, args = {}, editor = {name = "Bounce Block 1", imgstr = "bounceblock1", rect = nil}},
    bounceblock2 = {class = BounceBlock2, args = {}, editor = {name = "Bounce Block 2", imgstr = "bounceblock2", rect = nil}},
	laser1 = {class = LaserBlock, args = {"up"}, editor = {name = "Laser (Up)", imgstr = "laserblock", rect = rects.tile[1][1]}},
	laser2 = {class = LaserBlock, args = {"right"}, editor = {name = "Laser (Right)", imgstr = "laserblock", rect = rects.tile[1][2]}},
	laser3 = {class = LaserBlock, args = {"down"}, editor = {name = "Laser (Down)", imgstr = "laserblock", rect = rects.tile[1][3]}},
	laser4 = {class = LaserBlock, args = {"left"}, editor = {name = "Laser (Left)", imgstr = "laserblock", rect = rects.tile[1][4]}},
	shield1 = {class = ShieldBlock, args = {"up"}, editor = {name = "Shield (Up)", imgstr = "shieldblock", rect = rects.tile[1][1]}},
	shield2 = {class = ShieldBlock, args = {"right"}, editor = {name = "Shield (Right)", imgstr = "shieldblock", rect = rects.tile[1][2]}},
	shield3 = {class = ShieldBlock, args = {"down"}, editor = {name = "Shield (Down)", imgstr = "shieldblock", rect = rects.tile[1][3]}},
	shield4 = {class = ShieldBlock, args = {"left"}, editor = {name = "Shield (Left)", imgstr = "shieldblock", rect = rects.tile[1][4]}},
	fallingblock = {class = FallingBlock, args = {}, editor = {name = "Falling Block", imgstr = "fallingblock", rect = nil}},
	donutblock = {class=DonutBlock, args={}, editor = {name = "Donut Block", imgstr = "donut", rect=nil}},
	oneway1 = {class = OneWayBlock, args = {"up"}, editor = {name = "One Way (Up)", imgstr = "oneway", deg = 0}},
	oneway2 = {class = OneWayBlock, args = {"right"}, editor = {name = "One Way (Right)", imgstr = "oneway", deg = 90}},
	oneway3 = {class = OneWayBlock, args = {"down"}, editor = {name = "One Way (Down)", imgstr = "oneway", deg = 180}},
	oneway4 = {class = OneWayBlock, args = {"left"}, editor = {name = "One Way (Left)", imgstr = "oneway", deg = 270}},
	switch1 = {class = SwitchBlock, args = {"red"}, editor = {name = "Switch (Red)", imgstr = "switch_off", color = {1, 0, 0}}},
	switch2 = {class = SwitchBlock, args = {"green"}, editor = {name = "Switch (Green)", imgstr = "switch_off", color = {0, 1, 0}}},
	switch3 = {class = SwitchBlock, args = {"blue"}, editor = {name = "Switch (Blue)", imgstr = "switch_off", color = {0, 0, 1}}},
	switch4 = {class = SwitchBlock, args = {"yellow"}, editor = {name = "Switch (Yellow)", imgstr = "switch_off", color = {1, 1, 0}}},
}

--SwitchBlocks are generated because theres like 8 variants
-- local colors = {"red", "green", "blue", "yellow"}
-- for i = 1, 4 do
-- 	for j = 1, 2 do
-- 		local key = "switch"..(i + (j-1)*4)
-- 		local v = {class = SwitchBlock}
-- 		v.args = {colors[i], (j == 2)}
-- 		name = "Switch ("..colors[i]..")"
-- 	end
-- end

data.enemy = {
	turret1 = {class = Turret, args = {"up"}, editor = {name = "Turret (Up)", imgstr = "turret_editor", deg = 0}},
	turret2 = {class = Turret, args = {"right"}, editor = {name = "Turret (Right)", imgstr = "turret_editor", deg = 90}},
	turret3 = {class = Turret, args = {"down"}, editor = {name = "Turret (Down)", imgstr = "turret_editor", deg = 180}},
	turret4 = {class = Turret, args = {"left"}, editor = {name = "Turret (Left)", imgstr = "turret_editor", deg = 270}},
}

data.item = {
	ammo = {class = Ammo, args = {}, editor = {name = "Ammo", imgstr = "bullet", w = 30, h = 30}}
}

--combine them all together into one big table
--also assigns each value with its own key
data.objects = {}
local names = {"tile", "enemy", "item"}
for _, name in ipairs(names) do
	t = data[name]
	for k, v in pairs(t) do
		v.key = k
		data.objects[k] = v
		data.objects[k].type = name
	end
end
