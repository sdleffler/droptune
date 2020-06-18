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
local old = _G.dtrequire
local dtpath = (...):gsub('%.init$', '') .. "."
_G.dtrequire = function(s)
    return require(dtpath .. s)
end

local status, err = pcall(function()
    droptune.agent = dtrequire("agent")
    droptune.entity = dtrequire("entity")
    droptune.log = dtrequire("log")
    droptune.keikaku = dtrequire("keikaku")
    droptune.prototype = dtrequire("prototype")
    droptune.scene = dtrequire("scene")

    droptune.bitser = dtrequire("lib.bitser")
    droptune.Slab = dtrequire("lib.Slab")
    droptune.tiny = dtrequire("lib.tiny")
    
    droptune.isLoaded = false

    function droptune.load(args)
        droptune.Slab.Initialize(args)
        droptune.isLoaded = true
    end
end)

-- Put the old dtrequire back so we don't screw up user code... in the
-- unlikely case that someone is actually using this variable.
_G.dtrequire = old

-- We caught any potential errors so that we could put `require`
-- back. But we still need to propagate any if they occurred.
if not status then
    error(err)
end

return droptune