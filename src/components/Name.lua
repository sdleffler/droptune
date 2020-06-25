local _, Component = dtrequire("entity").common()
local editable = dtrequire("editable")

local NameComponent = Component:subtype({}, "droptune.components.NameComponent")

function NameComponent:new(name)
    return name
end

editable.registerComponent(NameComponent, {
    buildUI = function(name, Slab)
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