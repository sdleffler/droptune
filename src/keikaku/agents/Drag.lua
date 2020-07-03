local Agent, State = dtrequire("agent").common()
local Tool = dtrequire("keikaku.interactable").Tool

local DragAgent = Tool:subtype()
do
    local init = {}

    function init.mousepressed(agent, x, y, button)
        if button == agent.button then
            agent:pushState("dragging")

            local start = agent.start
            if start then
                start(x, y, button)
            end
        end
    end

    local dragging = {}

    function dragging.mousemoved(agent, x, y, dx, dy)
        local mousemoved = agent.mousemoved
        if mousemoved then
            mousemoved(x, y, dx, dy)
        end
    end

    function dragging.mousepressed(agent, x, y, button)
        local mousepressed = agent.mousepressed
        if mousepressed then
            mousepressed(x, y, button)
        end
    end

    function dragging.mousereleased(agent, x, y, button)
        local mousereleased = agent.mousereleased
        if mousereleased then
            mousereleased(x, y, button)
        end

        if button == agent.button then
            agent:popState()
            
            local finish = agent.finish
            if finish then
                finish(x, y)
            end
        end
    end

    function DragAgent:init(opts)
        Tool.init(self, {
            init = State:new(init),
            dragging = State:new(dragging),
        })

        self.mousemoved = opts.mousemoved
        self.mousepressed = opts.mousepressed
        self.mousereleased = opts.mousereleased
        self.start = opts.start
        self.finish = opts.finish
        self.button = opts.button or 1
        self.entity = opts.entity
    end

    function DragAgent.newFromAccessors(editor, entity, set, get)
        local offsetX, offsetY
        
        local function update(x, y)
            x, y = editor:getCamera():toWorld(x, y)
            set(x - offsetX, y - offsetY)
        end

        local function start(sx, sy)
            sx, sy = editor:getCamera():toWorld(sx, sy)
            local x, y = get()
            offsetX, offsetY = sx - x, sy - y
        end

        local agent = DragAgent:new({
            start = start,
            mousemoved = update,
            finish = update,
            entity = entity,
        })

        agent.set = set
        agent.get = get

        return agent
    end
end

return DragAgent