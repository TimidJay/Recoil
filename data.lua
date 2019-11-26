data = {}

--the keys are also known as id
data.tiles = {
	--args will contain all arguments after the i, j params, if they exist
	--editor is the displayed image for the level editor
	block = {class = Block, args = {}, editor = {name = "Regular Block", imgstr = "brick", rect = nil}},
	deathblock = {class = DeathBlock, args = {}, editor = {name = "Death Block", imgstr = "death_brick", rect = nil}},
    switchblock = {class = SwitchBlock, args = {}, editor = {name = "Switch Block", imgstr = "bluebrick", rect = nil}},
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
	switch1 = {class = SwitchBlock, args = {"red"}, editor = {name = "Switch (Red)", imgstr = "switch_off", color = {1, 0, 0}}},
	switch2 = {class = SwitchBlock, args = {"green"}, editor = {name = "Switch (Green)", imgstr = "switch_off", color = {0, 1, 0}}},
	switch3 = {class = SwitchBlock, args = {"blue"}, editor = {name = "Switch (Blue)", imgstr = "switch_off", color = {0, 0, 1}}},
	switch4 = {class = SwitchBlock, args = {"yellow"}, editor = {name = "Switch (Yellow)", imgstr = "switch_off", color = {1, 1, 0}}},
}

data.enemies = {
	turret1 = {class = Turret, args = {"up"}, editor = {name = "Turret (Up)", imgstr = "turret_editor", deg = 0}},
	turret2 = {class = Turret, args = {"right"}, editor = {name = "Turret (Right)", imgstr = "turret_editor", deg = 90}},
	turret3 = {class = Turret, args = {"down"}, editor = {name = "Turret (Down)", imgstr = "turret_editor", deg = 180}},
	turret4 = {class = Turret, args = {"left"}, editor = {name = "Turret (Left)", imgstr = "turret_editor", deg = 270}},
}

data.items = {
	ammo = {class = Ammo, args = {}, editor = {name = "Ammo", imgstr = "bullet", w = 30, h = 15}}
}

--each value should also contain its own key
for k, v in pairs(data.tiles) do
	v.key = k
end

for k, v in pairs(data.enemies) do
	v.key = k
end

for k, v in pairs(data.items) do
	v.key = k
end
