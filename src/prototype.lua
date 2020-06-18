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

local cache = {}
local function getSourceFile(path)
    local cached = cache[path]
    if not cached then
        local lines = {}
        local iter = (love and love.filesystem.lines(path))
            or io.lines(path)

        for line in iter do
            lines[#lines + 1] = line
        end 

        cache[path] = lines
        cached = lines
    end
    return cached
end

local function subtypeInner(this, target_frame)
    assert((name == nil or type(name) == "string"), "Prototype:subtype expects a string name as its only (optional) argument.")

    local subtype = {}

    -- Instead of using __index, make a shallow copy of the supertype.
    for k, v in pairs(this) do
        subtype[k] = v
    end

    local metatable = getmetatable(this)
    if metatable then
        local subtypemt = {}
        for k, v in pairs(metatable) do
            subtypemt[k] = v
        end
        setmetatable(subtype, subtypemt)
    end

    subtype.__index = subtype
    subtype[supertypeTableKey] = this

    local namestring
    if debug then
        local info = debug.getinfo(target_frame)
        if info.source:sub(1, 1) == "@" then
            local line = getSourceFile(info.source:sub(2, -1))[info.currentline]
            local _, j, name = line:find("^%s*(%w+)%s+")
            if name ~= "local" then
                namestring = name
            else
                namestring = select(3, line:sub(j, -1):find("^%s*(%w+)%s+"))
            end
        else
            namestring = "<UNKNOWN>"
        end

        namestring = string.format("%s@%s:%d", namestring, info.short_src, info.currentline)
    else
        namestring = tostring(subtype)
    end

    return subtype
end

function Prototype:subtype()
    return subtypeInner(self, 3)
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
    return self[nameTableKey]
end

return {
    Prototype = Prototype,
    new = function(...)
        return subtypeInner(Prototype, 2)
    end,
    disallowSubtype = disallowSubtype,
}