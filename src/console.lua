local slabfactory = dtrequire("slabfactory")

local Scene = dtrequire("scene.Scene")
local ConsoleScene = Scene:subtype()

function ConsoleScene:init()
    self.Slab = slabfactory().Slab

    self.slabhooks = {}
    self.Slab.Initialize(nil, self.slabhooks)

    self.fonts = dtrequire("fonts")
    self.Slab.PushFont(self.fonts.firaRegular)

    local mouseX, mouseY = 0, 0
    self.slabmouse = {
        isDown = function(button)
            return self.focused and love.mouse.isDown(button)
        end,

        getPosition = function(button)
            if self.focused then
                mouseX, mouseY = love.mouse.getPosition()
            end

            return mouseX, mouseY
        end,
    }

    self.slabkeyboard = {
        isDown = function(key)
            return self.focused and love.keyboard.isDown(key)
        end,
    }

    self.Slab.Update(0, {
        MouseAccessors = self.slabmouse,
        KeyboardAccessors = self.slabkeyboard,
    })

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
    Slab.Update(dt, {
        MouseAccessors = self.slabmouse, 
        KeyboardAccessors = self.slabkeyboard,
    })

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

    if Slab.IsVoidClicked() and Slab.IsMouseDoubleClicked() then
        scenestack:pop()
    end
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

function ConsoleScene:textinput(scenestack, ...)
    self.slabhooks.textinput(...)
end

function ConsoleScene:wheelmoved(scenestack, ...)
    self.slabhooks.wheelmoved(...)
end

function ConsoleScene:quit(scenestack, ...)
    self.slabhooks.quit(...)
end

return {
    ConsoleScene = ConsoleScene,
}