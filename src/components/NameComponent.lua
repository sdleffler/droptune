local _, Component = dtrequire("entity").common()
local editable = dtrequire("editable")

local NameComponent = Component:subtype({}, "droptune.components.NameComponent")

function NameComponent:init(name)
    self.name = name
end

editable.registerComponent(NameComponent, {
    buildUI = function(namecomponent, Slab)
        Slab.Text("Name: ")
        Slab.SameLine()
        if Slab.Input("NameComponentName", {
            ReturnOnText = false,
            Text = namecomponent.name,
        }) then
            namecomponent.name = Slab.GetInputText()
        end
    end,

    newDefault = function()
        return NameComponent:new("Entity")
    end,
})

return NameComponent