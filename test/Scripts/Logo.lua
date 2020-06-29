local x, y = ...

if editor then
    x = editor.x
    y = editor.y
end

return entity(1) {
    ["droptune.components.render.Sprite"] = {
        ["resource"] = "test.Textures.love-logo",
    },
    ["droptune.components.Position"] = {
        ["x"] = x,
        ["y"] = y,
        ["rot"] = 0,
    },
}