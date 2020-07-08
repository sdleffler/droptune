local Agent, State = dtrequire("agent")
local ecs = dtrequire("ecs")
local lume = dtrequire("lib.lume")
local prototype = dtrequire("prototype")
local scene = dtrequire("scene")
local slabfactory = dtrequire("slabfactory")

local keikaku = {}

keikaku.agents = dtrequire("keikaku.agents")

keikaku.Interaction = dtrequire("keikaku.interactable").Interaction
keikaku.Tool = dtrequire("keikaku.interactable").Tool

keikaku.registerInteraction = dtrequire("keikaku.interactable").registerInteraction

keikaku.ResourcePicker = dtrequire("keikaku.ResourcePicker")

local Editor = scene.Scene:subtype()
do
    keikaku.Editor = Editor

    function Editor:init(world)
        local slab = slabfactory()
        self.Slab = slab.Slab
        self.SlabDebug = slab.SlabDebug

        self.world = world or ecs.World:new()
        self.world:refresh()

        self.slabhooks = {}
        self.Slab.Initialize(nil, self.slabhooks)

        self.slabinputs = {
            isMouseDown = {false, false, false},
            getMousePosition = {0, 0},
        }

        dtrequire("keikaku.main").updateSlab(self, 0)
    end

    function Editor:update(scenestack, dt)
        dtrequire("keikaku.main").update(scenestack, dt, self)
    end

    function Editor:draw(scenestack)
        dtrequire("keikaku.main").draw(scenestack, self)
    end

    function Editor:getCamera()
        return self.world:getPipeline().camera
    end

    function Editor:textinput(scenestack, ch)
        dtrequire("keikaku.main").textinput(self, ch)
    end

    function Editor:wheelmoved(scenestack, x, y)
        dtrequire("keikaku.main").wheelmoved(self, x, y)
    end

    function Editor:quit(scenestack)
        return dtrequire("keikaku.main").quit(self)
    end
end

dtrequire("keikaku.interactions")

return keikaku