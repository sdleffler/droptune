local Prototype = {}
Prototype.__index = Prototype

local supertypeTableKey = { "SUPERTYPE" }
local nameTableKey = { "NAME" }

Prototype[nameTableKey] = "Prototype"

function Prototype:new(...)
    local this = setmetatable({}, self)

    if self.init then
        self.init(this, ...)
    end

    return this
end

function Prototype:subtype(name)
    assert((name == nil or type(name) == "string"), "Prototype:subtype expects a string name as its only (optional) argument.")

    local subtype = {}

    -- Instead of using __index, make a shallow copy of the supertype.
    for k, v in pairs(self) do
        subtype[k] = v
    end

    local metatable = getmetatable(self)
    if metatable then
        local subtypemt = {}
        for k, v in pairs(metatable) do
            subtypemt[k] = v
        end
        setmetatable(subtype, subtypemt)
    end

    subtype.__index = subtype
    subtype[supertypeTableKey] = self
    subtype[nameTableKey] = name

    return subtype
end

function disallowSubtype(ty)
    assert(ty ~= Prototype, "don't fuck up the base type")  
    assert(Prototype.isSubtypeOf(ty, Prototype))
    ty.subtype = function()
        error("subtyping has been prohibited for this type")
    end
end

function Prototype:prototype()
    return getmetatable(self)
end

function Prototype:super()
    return self[supertypeTableKey]
end

function Prototype:isSubtypeOf(ty)
    local m = self
    while m do
        if m == ty then
            return true
        end
        m = m[supertypeTableKey]
    end
    return false
end

function Prototype:elementOf(ty)
    local m = getmetatable(self)
    while m do
        if m == ty then
            return true
        end
        m = m[supertypeTableKey]
    end
    return false
end

function Prototype:getPrototypeName()
    local name = rawget(self, nameTableKey)
    if name then
        print("woo")
        return name
    else
        return rawget(getmetatable(self), nameTableKey)
    end
end

return {
    Prototype = Prototype,
    new = function(...)
        return Prototype:subtype(...)
    end,
    disallowSubtype = disallowSubtype,
}