local dr = require "src"

dr.resource.addNamespace("test", "test")

local serialized
do
    local Entity, Component = dr.ecs.common()
    local NameComponent = dr.components.Name
    local PhysicsComponent = dr.components.Physics

    local world = dr.ecs.World:new(dr.systems.Physics:new())
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
    local world = dr.ecs.World:new(dr.systems.Physics:new())
    world:refresh()

    world:deserializeEntities(serialized)
    world:refresh()
end

function love.load(args)
    logger = dr.log.Logger:new({ minimum = "warn" })
    scenestack = dr.scene.SceneStack:new()
    scenestack:installHooks(love)

    world = dr.ecs.World:new(dr.systems.Physics:new())
    world:setRenderer(dr.systems.render.SpriteRenderer:new())

    -- world:addEntity(dr.ecs.Entity:new {
    --     dr.components.render.Sprite:new("test.Textures.love-logo"),
    --     dr.components.Transform:new(400, 300),
    -- })

    local e = world:addEntity(dr.ecs.Entity:new {
        [dr.components.Name] = dr.components.Name:new("Bar"),
        [dr.components.Physics] = dr.components.Physics:new(world, 250, 800, "dynamic")
    })

    love.physics.newFixture(
        e[dr.components.Physics].body,
        love.physics.newRectangleShape(32, 32)
    )

    e[dr.components.Physics].body:setAngle(1.4)

    world:instantiate(dr.resource.get("test.Scripts.Logo"), nil, 400, 300)

    world:refresh()

    --scenestack:push(dr.editor.EditorScene:new(world))
    --scenestack:push(dr.keikaku.EditorScene:new(world))
    scenestack:push(dr.keikaku.Editor:new(world))
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