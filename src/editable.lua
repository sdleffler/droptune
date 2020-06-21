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

function editable.registerComponent(component, methods)
    prototype.registerInterface(Editable, component, methods)

    local name = component:getPrototypeName()
    editable.registeredComponents[name] = component
    table.insert(editable.registeredComponentNames, name)
end

editable.registeredSystems = {}
editable.registeredSystemNames = {}

function editable.registerSystem(system, methods)
    prototype.registerInterface(Editable, system, methods)

    local name = system:getPrototypeName()
    editable.registeredSystems[name] = system
    table.insert(editable.registeredSystemNames, name)
end

return editable