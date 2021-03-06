local bitser = dtrequire("lib.bitser")

local prototype = {}

local Prototype = {}
Prototype.__index = Prototype
prototype.Prototype = Prototype

local isPrototypeTableKey = { "PROTOTYPE" }
local supertypeTableKey = { "SUPERTYPE" }
local nameTableKey = { "NAME" }
local shortNameTableKey = { "SHORTNAME" }

Prototype[isPrototypeTableKey] = true
Prototype[nameTableKey] = "Prototype"
Prototype[shortNameTableKey] = "Prototype"

function Prototype:new(...)
    local this = setmetatable({}, self)

    if self.init then
        self.init(this, ...)
    end

    return this
end

local function sanitizeSourcePath(path)
    return path:gsub("\\", "/"):gsub("^%./", "")
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

function prototype.tryNameFromDebugInfo()
    local level, info = 2, debug.getinfo(1, 'S')
    local here = info.short_src
    while info.short_src == here do
        level = level + 1
        info = debug.getinfo(level, 'Sl')
    end

    local namestring
    if info.source:sub(1, 1) == "@" then
        -- Turn backslashes to forward slashes and chop off a leading `./` if it's there,
        -- since it will confuse `love.filesystem.lines()`.
        -- These can happen when a file is loaded with `love.filesystem.load` rather than `require`.
        local corrected = sanitizeSourcePath(info.source:sub(2, -1))
        local line = getSourceFile(corrected)[info.currentline]
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

    return string.format("%s@%s", namestring, sanitizeSourcePath(info.short_src)), namestring
end

local function rawsubtype(this, table, namestring, shortnamestring)
    local subtype = table or {}

    -- If we're trying to create a Prototype out of a non-Prototype metatable,
    -- we need to copy over the __index if it's not already self-referential.
    local subtypeIndex = subtype.__index
    if subtypeIndex and subtypeIndex ~= subtype then
        for k, v in pairs(subtypeIndex) do
            subtype[k] = v
        end

        for i, v in ipairs(subtypeIndex) do
            subtype[i] = v
        end
    end

    -- Instead of using __index, make a shallow copy of the supertype.
    for k, v in pairs(this) do
        -- Avoid overwriting already-present keys; treat the provided
        -- table as an already-present subclass
        if not subtype[k] then
            subtype[k] = v
        end
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
        namestring, shortnamestring = prototype.tryNameFromDebugInfo()
    end

    if namestring then
        if LOGGER then
            LOGGER:debug("bitser.register(%s, %s)", namestring, subtype)
        end

        bitser.registerClass(namestring, subtype)
    else
        namestring = tostring(subtype)
    end

    subtype[nameTableKey] = namestring
    subtype[shortNameTableKey] = shortnamestring or namestring

    return subtype
end

function Prototype:subtype(namestring, shortnamestring)
    return rawsubtype(self, {}, namestring, shortnamestring)
end

function prototype.new(...)
    return rawsubtype(Prototype, ...)
end

prototype.rawsubtype = rawsubtype

function prototype.disallowSubtype(ty)
    assert(ty ~= Prototype, "don't fuck up the base type")  
    assert(Prototype.isSubtypeOf(ty, Prototype))
    ty.subtype = function()
        error("subtyping has been prohibited for this type")
    end
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

function Prototype:isSupertypeOf(ty)
    return ty ~= nil and Prototype.isSubtypeOf(ty, self)
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

function Prototype:getShortPrototypeName()
    return self[shortNameTableKey]
end

function Prototype:__tostring()
    local mt = getmetatable(self)
    setmetatable(self, nil)
    local tablestr = tostring(self)
    setmetatable(self, mt)
    return string.format("<%s:%s>", self[nameTableKey], tablestr)
end

function Prototype:implements(interface)
    return interface[prototype.of(self)] ~= nil
end

function prototype.isPrototyped(obj)
    local mt = getmetatable(obj)
    return mt and rawget(mt, supertypeTableKey) ~= nil
end

function prototype.isPrototype(proto)
    return type(proto) == "table" and rawget(proto, supertypeTableKey) ~= nil
end

function prototype.of(obj)
    return (type(obj) == "table" and rawget(obj, isPrototypeTableKey) and obj)
        or getmetatable(obj)
end

function prototype.is(obj, proto)
    local m = getmetatable(obj)
    while m do
        if m == proto then
            return true
        end
        m = m[supertypeTableKey]
    end
    return false
end

function prototype.subtypes(sub, super)
    local m = sub
    while m do
        if m == super then
            return true
        end
        m = m[supertypeTableKey]
    end
    return false
end

local Interface = prototype.new()

function prototype.newInterface(table)
    assert(not getmetatable(table), "cannot make interface out of table with metatable")

    -- Capture the module for the internal closure to capture
    local prototype = prototype

    for k, v in pairs(table) do
        if type(k) == "string" then
            table[k] = function(obj, ...)
                local t = assert(prototype.of(obj), 
                    "cannot lookup interface implementation for nil or non-prototyped object!")
                local impl = assert(table[t],
                    "interface not implemented!")
                return (impl[k] or v)(obj, ...)
            end
        end
    end

    return setmetatable(table, Interface)
end

function Interface:__newindex(proto, methods)
    prototype.registerInterface(self, proto, methods)
end

function prototype.registerInterface(interface, proto, methods)
    assert(not rawget(interface, proto),
        proto:getShortPrototypeName() .. " already registered")    

    for k, v in pairs(methods) do
        assert(rawget(interface, k), "method not in interface!")
    end

    rawset(interface, proto, setmetatable(methods, Interface))
end

return prototype