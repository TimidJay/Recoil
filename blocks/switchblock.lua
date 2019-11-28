SwitchBlock = class("SwitchBlock", Block)

SwitchBlock.colors = {
    red = {1, 0, 0},
    green = {0, 1, 0},
    blue = {0, 0, 1},
    yellow = {1, 1, 0},
    --colors for EditorState
    ["-red"] = {1, 0.65, 0.65},
    ["-green"] = {0.65, 1, 0.65},
    ["-blue"] = {0.65, 0.65, 1},
    ["-yellow"] = {1, 1, 0.65},
}
function SwitchBlock:initialize(i, j, switchColor)
    Block.initialize(self, i, j)
    --toggle determines whether or not block can be
    --toggled on/off or just stay on
    self.toggle = true
	self.imgstr = "switch_off"
    self.on = false
    self.switchColor = switchColor
    local sc = SwitchBlock.colors[switchColor]
    self.color = {r = sc[1], g = sc[2], b = sc[3], a = 1}
    self.touched = 0
end

function SwitchBlock:onPlayerHit(player)
    if self.touched == 0 then
        if self.toggle then
            self.on = not self.on
            self:onSwitch()
        else
            if not self.on then
                self.on = true
                self:onSwitch()
            end
        end
    end
    self.touched = 2
end

function SwitchBlock:onBulletHit()
    self:onPlayerHit()
end

function SwitchBlock:onSwitch()
    for _, t in ipairs(game.tiles) do
        if t.actuator == self.switchColor then
            t:onTrigger()
        end
    end
end

function SwitchBlock:update(dt)
    if self.touched > 0 then
        self.touched = self.touched - 1
    end

    Block.update(self, dt)
end

function SwitchBlock:draw()
    self.imgstr = self.on and "switch_on" or "switch_off"
    Block.draw(self)
end
