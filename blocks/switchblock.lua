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
	self.imgstr = "switch_off"
    self.on = false
    self.switchColor = switchColor
    local sc = SwitchBlock.colors[switchColor]
    self.color = {r = sc[1], g = sc[2], b = sc[3], a = 1}
    self.touched = 0

    self.blockType = "Switch"
end

function SwitchBlock:touchOtherSwitches()
    for _, t in ipairs(game.tiles) do
        if t ~= self then
            if t.blockType == "Switch" and t.switchColor == self.switchColor then
                t.touched = 2
            end
        end
    end
end

function SwitchBlock:onPlayerHit(player)
    if self.touched == 0 then
        self.on = not self.on
        self:onSwitch()
    end
    self:touchOtherSwitches()
    self.touched = 2
end

function SwitchBlock:onBulletHit()
    self:onPlayerHit()
end

function SwitchBlock:onSwitch()
    for _, t in ipairs(game.tiles) do
        if t ~= self then
            if t.actuator == self.switchColor then
                t:onTrigger()
            end
            if t.blockType == "Switch" and t.switchColor == self.switchColor then
                t.on = not t.on
            end
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
