local prototype = dtrequire("prototype")

local editable = {}

local Editable = {}

function Editable:buildUI(Slab) end

function Editable:newDefault()
    return nil
end

editable.Editable = prototype.newInterface(Editable)
editable.registeredComponents = {}
editable.registeredComponentNames = {}

function editable.register(component, methods)
    prototype.registerInterface(Editable, component, methods)

    local name = component:getPrototypeName()
    editable.registeredComponents[name] = component
    table.insert(editable.registeredComponentNames, name)
end

return editable