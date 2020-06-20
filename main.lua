local dt = require "src"

function love.load(args)
    logger = dt.log.Logger:new({ minimum = "warn" })
    scenestack = dt.scene.SceneStack:new()
    scenestack:push(dt.editor.EditorScene:new())
end

function love.update(dt)
    logger:push("info", "lol")
    scenestack:message("update", dt)
end

function love.draw()
    scenestack:message("draw", dt)
end