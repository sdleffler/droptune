local droptune = {
    _LICENSE = "MIT/X11",
    _URL = "https://github.com/sdleffler/droptune",
    _VERSION = "0.0.1",
    _DESCRIPTION = "A collection of Lua libraries designed as a starting point for LÖVE projects",
}

if not (love or package.path:find("%?%.lua%;%?%/init%.lua%;")) then
    package.path = "?.lua;?/init.lua;" .. package.path
end

-- This is a setup for loading files with relative paths. It's
-- an ugly hack, but it works. For submodules of droptune, we
-- call droptune("module.path") rather than require("module.path").
local oldreq, oldload, oldpath = _G.dtrequire, _G.dtload, _G.DROPTUNE_PATH
local dtpath = (...):gsub('%.init$', '') .. "."

function _G.dtrequire(s)
    return require(dtpath .. s)
end

function _G.dtload(s)
    local path = dtpath:gsub("%.", "/") .. s
    return love.filesystem.load(path)
end

_G.DROPTUNE_PATH = dtpath

local status, err = pcall(function()
    droptune.agent = dtrequire("agent")
    droptune.editor = dtrequire("editor")
    droptune.editable = dtrequire("editable")
    droptune.entity = dtrequire("entity")
    droptune.log = dtrequire("log")
    droptune.prototype = dtrequire("prototype")
    droptune.scene = dtrequire("scene")

    droptune.bitser = dtrequire("lib.bitser")
    droptune.tiny = dtrequire("lib.tiny")
end)

-- Put the old dtrequire back so we don't screw up user code... in the
-- unlikely case that someone is actually using this variable.
_G.dtrequire = oldreq
_G.dtload = oldload
_G.DROPTUNE_PATH = DROPTUNE_PATH

-- We caught any potential errors so that we could put `require`
-- back. But we still need to propagate any if they occurred.
if not status then
    error(err)
end

return droptune