local cargo = dtrequire("lib.cargo")
local json = dtrequire("lib.json")
local lume = dtrequire("lib.lume")

local resource = {}

local base = {}

cargo.loaders.shader = love.graphics.newShader

function cargo.loaders.json(path)
    local s = love.filesystem.read(path)
    if s then
        return json.decode(s)
    end
end

function cargo.loaders.bank(path)
    fmod.loadBank(path, 0)
end

function resource.addNamespace(namespace, path)
    base[namespace] = cargo.init(path)
end

function resource.get(name)
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

resource.addNamespace("droptune", DROPTUNE_BASE .. "assets")

return resource