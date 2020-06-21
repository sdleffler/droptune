local slabFactory = dtrequire("slab_factory")

local Scene = dtrequire("scene.Scene")
local ConsoleScene = Scene:subtype()

function ConsoleScene:init()
    self.Slab = slabFactory().Slab
    self.Slab.Initialize()

    self.fonts = dtrequire("fonts")
    self.Slab.PushFont(self.fonts.firaRegular)

    self.Slab.Update(0)

    self.focused = false
    self.output = ""
    self.input = ""
    self.history = {}
    self.historyPos = -1
    self.pendingText = nil
end

function ConsoleScene:setFocused(scenestack, focused)
    self.focused = focused

    if focused then
        self.parent = scenestack[#scenestack - 1]
    end
end

function ConsoleScene:update(scenestack, dt)
    local Slab = self.Slab
    Slab.Update(dt)

    local w, h = love.graphics.getDimensions()
    Slab.BeginWindow("Console", {
        X = 0,
        Y = h - 154,
        W = w - 4,
        H = 150,
        SizerFilter = {"N"},
        AutoSizeWindow = false,
    })

    Slab.Input("Output", {
        Text = self.output,
        ReadOnly = true,
        MultiLine = true,
        W = w - 8,
        H = 150 - 28,
    })

    Slab.SetCursorPos(nil, 150 - 20)

    Slab.BeginLayout("ConsoleLayout", {
        ExpandW = true,
        AlignX = "center",
    })

    if Slab.Input("Input", {
        Align = "left",
        Text = self.input,
        ReturnOnText = false,
        TextColor = {0, 0, 0, 1}
    }) then
        local code = Slab.GetInputText()
        table.insert(self.history, code)
        self.historyPos = -1
        local concat = "> " .. code .. "\n"
        local ok, err = loadstring("return " .. code)

        if ok then
            ok, result = xpcall(setfenv(ok, scenestack.env), debug.traceback) -- TODO: setfenv

            if ok then
                concat = concat .. tostring(result) .. "\n"
            else
                concat = concat .. result .. "\n"
            end
        else
            concat = concat .. err .. "\n"
        end

        self.pendingText = ""
        self.output = concat .. self.output
    else
        -- HAAAAAAAACK
        local inputText = Slab.GetInputText()
        if self.pendingText and self.input ~= self.pendingText then
            Slab.SetInputFocus("Output")
            self.input = self.pendingText
        elseif self.pendingText and not Slab.IsInputFocused("Input") then
            Slab.SetInputFocus("Input")
        elseif self.pendingText then
            self.pendingText = nil
        elseif inputText ~= self.input then
            -- TODO: autocomplete
            self.input = inputText
        end
    end

    self.inputFocused = Slab.IsInputFocused("Input")

    Slab.EndLayout()

    Slab.EndWindow()
end

function ConsoleScene:draw(scenestack)
    local parent = self.parent
    if parent then
        parent:message("draw", scenestack)
    end
    self.Slab.Draw()
end

function ConsoleScene:keypressed(scenestack, key, scancode, isrepeat)
    local Slab = self.Slab
    if self.inputFocused and (key == "up" or key == "down") then
        if self.historyPos == -1 then
            self.historyPos = #self.history
        elseif key == "down" and self.historyPos > 1 then
            self.historyPos = self.historyPos - 1
        elseif key == "up" and self.historyPos < #self.history then
            self.historyPos = self.historyPos + 1
        end

        if self.historyPos > 0 then
            self.pendingText = self.history[self.historyPos]
        end
    elseif key == "`" and love.keyboard.isDown("lctrl", "lshift") then
        scenestack:pop()
    end
end

return {
    ConsoleScene = ConsoleScene,
}