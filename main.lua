local dr = require "src"

local serialized
do
    local Entity, Component = dr.ecs.common()
    local NameComponent = dr.components.NameComponent
    local PhysicsComponent = dr.components.PhysicsComponent

    local world = dr.ecs.World:new(dr.systems.PhysicsSystem:new())
    world:refresh()

    world:addEntity(Entity:new({[NameComponent] = "Foo"}))
    
    local e = world:addEntity(Entity:new {
        [NameComponent] = NameComponent:new("Bar"),
        [PhysicsComponent] = PhysicsComponent:new(world)
    })
    love.physics.newFixture(
        e[PhysicsComponent].body,
        love.physics.newRectangleShape(32, 32)
    )
    
    world:refresh()

    serialized = ""
    local ok, err = xpcall(function()
        world:serializeEntities(function(s) serialized = serialized .. s end)
    end, debug.traceback)

    print(serialized)

    if not ok then
        error("serialize failed with:\n" .. err)
    end
end

do
    local world = dr.ecs.World:new(dr.systems.PhysicsSystem:new())
    world:refresh()

    world:deserializeEntities(serialized)
    world:refresh()
end

local world, pipeline

function love.load(args)
    logger = dr.log.Logger:new({ minimum = "warn" })
    scenestack = dr.scene.SceneStack:new()
    scenestack:installHooks(love)

    world = dr.ecs.World:new()
    world:setRenderer(dr.systems.render.SpriteRenderer:new())

    local e = dr.ecs.Entity:new {
        dr.components.render.SpriteComponent:new("assets/love-logo.png"),
        dr.components.TransformComponent:new(400, 300),
    }

    world:addEntity(e)
    world:refresh()

    scenestack:push(dr.editor.EditorScene:new(world))
end

function love.update(dt)
    dr.lurker.update()
    logger:push("info", "lol")
    world:update(dt)
    scenestack:message("update", dt)
end

function love.draw()
    love.graphics.clear(1.0, 1.0, 1.0, 1.0)
    --world:draw()
    scenestack:message("draw")
end