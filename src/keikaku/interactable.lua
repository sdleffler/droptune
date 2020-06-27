local HC = dtrequire("lib.HC")
local lume = dtrequire("lib.lume")

local Agent, _ = dtrequire("agent").common()
local ecs = dtrequire("ecs")
local prototype = dtrequire("prototype")

if not _keikaku_interactable_G then
    local globals = {}

    globals.Properties = prototype.newInterface({
        updateProperties = function(self, editor) end,
    })

    local Interaction = ecs.System:subtype()
    globals.Interaction = Interaction
    do
        Interaction.active = false

        function Interaction:init(editor)
            ecs.System.init(self)
            self.editor = editor
        end

        function Interaction:draw(pipeline) end
    end

    local Tool = Agent:subtype()
    globals.Tool = Tool
    do
        function Tool:overrideGUI()
            return self:getState() ~= "init"
        end

        function Tool:overrideNonToolInteractions()
            return false
        end

        function Tool:overrideContextMenu()
            return false
        end

        function Tool:getName()
            return self:getShortPrototypeName()
        end
    end

    globals.registry = {}

    local systems = dtrequire("systems")
    local InteractorSystem = systems.render.MultistageRenderer:subtype()
    globals.InteractorSystem = InteractorSystem
    do
        InteractorSystem.active = false

        function InteractorSystem:init(editor)
            local children = {}
            for _, itr in pairs(globals.registry) do
                local sys = itr:new(editor)
                table.insert(children, sys)
            end

            systems.render.MultistageRenderer.init(self, children)
            self.editor = editor
        end

        function InteractorSystem:update(dt)
            for _, child in ipairs(self.children) do
                child:update(dt)
            end
        end
    end

    _keikaku_interactable_G = globals
end

local Properties = _keikaku_interactable_G.Properties
local Interaction = _keikaku_interactable_G.Interaction
local Tool = _keikaku_interactable_G.Tool

local interactable = {
    Interaction = Interaction,
    Properties = Properties,
    Tool = Tool,
}

function interactable.registerInteraction(name, interaction)
    _keikaku_interactable_G.registry[name] = interaction
end

function interactable.deinit(editor)
    editor.world:removeSystem(editor.interaction)
end

function interactable.init(editor)
    for k, v in pairs(_keikaku_interactable_G) do
        interactable[k] = v
    end

    editor.interactable = interactable
    editor.hc = HC.new()
    editor.hovered = {}

    editor.interaction = interactable.InteractorSystem:new(editor)
    editor.world:addSystem(editor.interaction)
    editor.world:refresh()
end

function interactable.update(dt, editor)
    if editor.interactable ~= interactable then
        if editor.interactable then
            interactable.deinit(editor)
        end
        interactable.init(editor)
    end

    editor.interaction:update(dt)

    local hovered = editor.hovered
    if editor.Slab.IsVoidHovered() then
        if not (editor.tool and editor.tool:overrideNonToolInteractions()) then
            local shapes = editor.hc:shapesAt(editor.mousestate:getMousePosition())

            for i = #hovered, 1, -1 do
                local hovshape = hovered[i]
                if not shapes[hovshape] then
                    table.remove(hovered, i)
                else
                    shapes[hovshape] = nil
                end
            end

            for shape in pairs(shapes) do
                table.insert(hovered, shape)
            end
        end

        if #hovered == 0 then
            table.insert(hovered, {agent = editor.tool})
        end
    else
        lume.clear(hovered)
    end
end

function interactable.draw(editor)
    editor.world:refresh()
    editor.interaction:draw(editor.world:getPipeline())

    love.graphics.setColor(0, 0, 1, 0.8)
    love.graphics.setLineWidth(1)

    local hc = editor.hc
    local shapes = hc:hash():shapes()
    local hovered = hc:shapesAt(love.mouse.getPosition())

    for shape in pairs(shapes) do
        local kind
        if hovered[shape] or shape.agent:getState() ~= "init" then
            kind = "fill"
        else
            kind = "line"
        end

        shape:draw(kind)
    end
end

return interactable