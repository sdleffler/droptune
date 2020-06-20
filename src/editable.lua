local prototype = dtrequire("prototype")

local editable = {}

local Editable = {}

function Editable:buildUI(Slab) end

editable.Editable = prototype.newInterface(Editable)

function editable.register(component, methods)
    prototype.registerInterface(Editable, component, methods)
end

return editable