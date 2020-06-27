local _, Component = dtrequire("entity").common()
local hooks = dtrequire("editor.hooks")
local lume = dtrequire("lib.lume")

local UUIDComponent = Component:subtype({}, "droptune.components.UUID")

function UUIDComponent:new(uuid)
    return uuid or lume.uuid()
end

hooks.registerComponent(UUIDComponent, {
    updateUI = function(uuid, Slab)
        Slab.Text("UUID: " .. uuid)
    end,

    newDefault = function()
        return UUIDComponent:new()
    end,
})

return UUIDComponent