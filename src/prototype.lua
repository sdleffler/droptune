local bitser = dtrequire("lib.bitser")

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

function Prototype.fromTable(obj, proto)
    return setmetatable(obj, proto)
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

function tryNameFromDebugInfo()
    local level, info = 2, debug.getinfo(1, 'S')
    local here = info.short_src
    while info.short_src == here do
        level = level + 1
        info = debug.getinfo(level, 'Sl')
    end

    local namestring
    if info.source:sub(1, 1) == "@" then
        local line = getSourceFile(info.source:sub(2, -1))[info.currentline]
        local _, j, name = line:find("^%s*(%w+)%s+")
        if name ~= "local" then
            namestring = name
        else
            namestring = select(3, line:sub(j, -1):find("^%s*(%w+)%s+"))
        end
    else
        --namestring = string.format("<UNKNOWN:%s>", tostring(this))

        -- local level = 1
        -- while true do
        --     local info = debug.getinfo(level, "Sl")
        --     if not info then break end
        --     if info.what == "C" then   -- is a C function?
        --         print(level, "C function")
        --     else   -- a Lua function
        --         print(string.format("[%s]:%d",
        --                         info.short_src, info.currentline))
        --     end
        --     level = level + 1
        -- end
        return nil
    end

    return string.format("%s@%s", namestring, info.short_src)
end

local function rawSubtype(this, namestring)
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

    if not namestring and debug then
        namestring = tryNameFromDebugInfo()
    end

    if namestring then
        bitser.register(namestring, this)
    else
        namestring = tostring(subtype)
    end

    subtype[nameTableKey] = namestring

    return subtype
end

function Prototype:subtype(namestring)
    return rawSubtype(self, namestring)
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

function Prototype:__tostring()
    local mt = getmetatable(self)
    setmetatable(self, nil)
    local tablestr = tostring(self)
    setmetatable(self, mt)
    return string.format("<%s:%s>", self[nameTableKey], tablestr)
end

return {
    Prototype = Prototype,
    new = function(...)
        return rawSubtype(Prototype, ...)
    end,
    disallowSubtype = disallowSubtype,
    fromParts = fromParts,
    tryNameFromDebugInfo = tryNameFromDebugInfo,
}