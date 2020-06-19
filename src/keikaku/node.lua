local Entity, Component = unpack(dtrequire("entity"))
local prototype = dtrequire("prototype")

local NodeComponent = Component:subtype()

function NodeComponent:init()
    self.children = {}
end