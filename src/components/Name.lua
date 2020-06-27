local _, Component = dtrequire("entity").common()
local hooks = dtrequire("editor.hooks")

local NameComponent = Component:subtype({}, "droptune.components.Name")

function NameComponent:new(name)
    return name
end

hooks.registerComponent(NameComponent, {
    updateUI = function(name, Slab)
        Slab.Text("Name: ")
        Slab.SameLine()
        if Slab.Input("NameComponentName", {
            ReturnOnText = false,
            Text = name,
        }) then
            return Slab.GetInputText()
        else
            return name
        end
    end,

    newDefault = function()
        return NameComponent:new("Entity")
    end,
})

return NameComponent