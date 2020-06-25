setfenv(1, setmetatable({}, {__index = _G}))

if type(...) == "string" and ... == "CHECKEXISTS" then
    return "FUCKYEAH"
end

local droptune = {
    _LICENSE = "MIT/X11",
    _URL = "https://github.com/sdleffler/droptune",
    _VERSION = "0.0.1",
    _DESCRIPTION = "A collection of Lua libraries designed as a starting point for LÖVE projects",
}

local packagepath
if not (love or package.path:find("%?%.lua%;%?%/init%.lua%;")) then
    package.path = "?.lua;?/init.lua;" .. package.path
    packagepath = package.path
elseif love then
    packagepath = love.filesystem.getRequirePath()
end

-- This is a setup for loading files with relative paths. It's
-- an ugly hack, but it works. Internally for submodules of droptune, we
-- call dtrequire("module.path") rather than require("module.path").
local dotdotdot = ...

function _G.dtrequire(s)
    return require(DROPTUNE_MODULE .. s)
end

function _G.dtload(s)
    local path = DROPTUNE_SRC .. s
    return love.filesystem.load(path)
end

function droptune.findModuleDirectory(modulepath)
    if LOGGER then
        LOGGER:info("Searching for module %s in filesystem...", modulepath)
    end

    local modulesubdir = modulepath:gsub("%.", "/")
    for path in string.gmatch(packagepath, "[^;]+%.lua") do
        local candidate = path:gsub("%?", modulesubdir)
        if LOGGER then
            LOGGER:info("\tChecking at %s", candidate)
        end
        
        local ok, chunk, result
        ok, chunk = love.filesystem.load(candidate)
        if not ok then
            if LOGGER then
                LOGGER:info("\tCouldn't load file %s: `%s`, moving on...", candidate, tostring(chunk))
            end
        else
            local found = path:gsub("%?", modulesubdir):gsub("[^;/]+%.lua$", "")
            if LOGGER then
                LOGGER:info("\tLoaded Lua file at %s, success!", candidate)
                LOGGER:info("\tmodule directory found: %s", found)
            end
            return found
        end
    end

    LOGGER:warn("Module %s not found...", modulepath)
end

function droptune.recursiverequire(modulepath, relative)
    relative = relative or ""
    local love, LOGGER = love, LOGGER

    function inner(directoryPath)
        local files = love.filesystem.getDirectoryItems(directoryPath)
        local loaded = {}
        while #files > 0 do
            local path = table.remove(files)
            local fullpath = directoryPath .. "/" .. path
            local found = fullpath:find("%.lua$")
            if found then
                local includePath = fullpath:sub(1, found-1):gsub("/", ".")
                local name = path:sub(1, path:find("%.lua$")-1)
                LOGGER:info("\tloading: %s from %s", includePath, fullpath)
                loaded[name] = require(includePath)
            else
                local info = love.filesystem.getInfo(fullpath)
                if info and info.type == "directory" then
                    loaded[path] = inner(fullpath)
                else
                    LOGGER:warn("odd path found: `%s`, are you sure recursiverequire is being run in the right place?", fullpath)
                end
            end
        end
        return loaded
    end

    local basepath = droptune.findModuleDirectory(modulepath) .. relative
    LOGGER:info("beginning recursive require with base path `%s`", basepath)
    return inner(basepath)
end

function _G.recursivedtrequire(path, relative)
    return droptune.recursiverequire(DROPTUNE_MODULE .. path, relative)
end

_G.DROPTUNE_MODULE = droptune.findModuleDirectory(dotdotdot):gsub("/", ".")

local status, err = xpcall(function()
    droptune.log = dtrequire("log") 
    _G.LOGGER = droptune.log.Logger:new({minimum = "info"})
    LOGGER:info("Logger initialized")
    LOGGER:info("DROPTUNE_MODULE = `%s`", DROPTUNE_MODULE)
    if love then
        LOGGER:info("Searching for droptune src directory...")
        _G.DROPTUNE_SRC = droptune.findModuleDirectory(dotdotdot)
        _G.DROPTUNE_BASE = DROPTUNE_SRC:match("(.*)src/$")
    end
    LOGGER:info("DROPTUNE_SRC = `%s`", DROPTUNE_SRC)
    LOGGER:info("DROPTUNE_BASE = `%s`", DROPTUNE_BASE)

    droptune.agent = dtrequire("agent")
    droptune.components = dtrequire("components")
    droptune.editor = dtrequire("editor")
    droptune.editable = dtrequire("editable")
    droptune.ecs = dtrequire("ecs")
    droptune.entity = dtrequire("entity")
    droptune.graphics = dtrequire("graphics")
    droptune.prototype = dtrequire("prototype")
    droptune.scene = dtrequire("scene")
    droptune.systems = dtrequire("systems")

    droptune.bitser = dtrequire("lib.bitser")
    droptune.lume = dtrequire("lib.lume")
    droptune.lurker = dtrequire("lib.lurker")
    droptune.peachy = dtrequire("lib.peachy")
    droptune.tiny = dtrequire("lib.tiny")
end, debug.traceback)

-- We caught any potential errors so that we could put `require`
-- back. But we still need to propagate any if they occurred.
if not status then
    error(err)
end

return droptune