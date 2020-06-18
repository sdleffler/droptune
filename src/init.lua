local droptune = {
    _LICENSE = "MIT/X11",
    _URL = "https://github.com/sdleffler/droptune",
    _VERSION = "0.0.1",
    _DESCRIPTION = "A collection of Lua libraries designed as a starting point for Love2D games",
}

if not love then
    package.path = "?.lua;?/init.lua" .. package.path
end

-- This is a setup for loading files with relative paths. It's
-- an ugly hack, but it works. For submodules of droptune, we
-- call droptune("module.path") rather than require("module.path").
local old = _G.require
local dtpath = (...):gsub('%.init$', '') .. "."
_G.require = function(s)
    return old(dtpath .. s)
end

local status, err = pcall(function()
    droptune.agent = require("agent")
    droptune.entity = require("entity")
    droptune.tiny = require("tiny")
end)

-- Put the old require back so we don't screw up user code.
_G.require = old

-- We caught any potential errors so that we could put `require`
-- back. But we still need to propagate any if they occurred.
if not status then
    error(err)
end

return droptune