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
local dtpath = (...):gsub("%.init$", "") .. "."

function _G.dtrequire(s)
    return require(dtpath .. s)
end

function _G.dtload(s)
    local path = dtpath:gsub("%.", "/") .. s
    return love.filesystem.load(path)
end

_G.DROPTUNE_MODULE = dtpath

local status, err = pcall(function()
    droptune.log = dtrequire("log")

    _G.LOGGER = droptune.log.Logger:new({minimum = "info"})

    LOGGER:info("Logger initialized")
    LOGGER:info("DROPTUNE_MODULE = `%s`", DROPTUNE_MODULE)

    if love then
        LOGGER:info("Searching for droptune src directory...")

        local dtsubdir = dotdotdot:gsub("%.init$", ""):gsub("%.", "/")
        for path, filepath in string.gmatch(packagepath, "(([^;]+)%.lua)") do
            local candidate = path:gsub("%?", dtsubdir .. "/init")
            LOGGER:info("\tChecking for init.lua at %s", candidate)
            
            local ok, chunk, result
            ok, chunk = pcall(love.filesystem.load, candidate)
            if not ok then
                LOGGER:warn("\tCouldn't load file %s: %s", candidate, tostring(chunk))
            else
                ok, result = pcall(chunk, "CHECKEXISTS")
            
                if not ok then
                    LOGGER:warn("\tCouldn't call chunk from %s: %s", candidate, tostring(result))
                elseif result == "FUCKYEAH" then
                    _G.DROPTUNE_SRC = filepath:gsub("%?", dtsubdir)
                    LOGGER:info("src directory found: %s", DROPTUNE_SRC)
                    break
                end
            end
        end
    end

    droptune.agent = dtrequire("agent")
    droptune.components = dtrequire("components")
    droptune.editor = dtrequire("editor")
    droptune.editable = dtrequire("editable")
    droptune.entity = dtrequire("entity")
    droptune.prototype = dtrequire("prototype")
    droptune.scene = dtrequire("scene")

    droptune.bitser = dtrequire("lib.bitser")
    droptune.tiny = dtrequire("lib.tiny")
end)

-- We caught any potential errors so that we could put `require`
-- back. But we still need to propagate any if they occurred.
if not status then
    error(err)
end

return droptune