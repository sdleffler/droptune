local prototype = dtrequire("prototype")
local scene = dtrequire("scene")
local Slab = dtrequire("lib.Slab")

local editor = dtrequire("keikaku.editor")
local node = dtrequire("keikaku.node")

local ComponentRegistry = prototype.new()

function ComponentRegistry:init()
    self.components = {}
end

local Layer = prototype.new()

function Layer:init()
    self.objects = {}
end

return {
    editor = editor,
    node = node,
}