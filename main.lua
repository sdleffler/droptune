local dt = require "src"

function love.load(args)
    dt.load(args)
    logger = dt.log.Logger:new({ minimum = "warn" })
    scenestack = dt.scene.SceneStack:new()
    scenestack:push(dt.keikaku.editor.EditorScene:new())
end

function love.update(dt)
    logger:push("info", "lol")
    scenestack:update(dt)
end

function love.draw()
    scenestack:draw()
end