local cargo = dtrequire("lib.cargo")
local json = dtrequire("lib.json")
local lume = dtrequire("lib.lume")

local resource = {}

local base = {}

local loaders = {
    shader = love.graphics.newShader,
    json = function(path)
        local s = love.filesystem.read(path)
        if s then
            return json.decode(s)
        end
    end,
}

function resource.addNamespace(namespace, path)
    base[namespace] = cargo.init(path)
end

function resource.get(name)
    print("fetching resource "..name)
    local node = base
    for _, key in ipairs(lume.split(name, ".")) do
        if node then
            node = node[key]
        else
            return nil
        end
    end
    return node
end

function resource.getTable()
    return base
end

return resource