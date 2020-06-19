-- Shim in case droptune is being used as a git submodule or such.

if not (love or package.path:find("%?%.lua%;%?%/init%.lua%;")) then
    package.path = "?.lua;?/init.lua;" .. package.path
end

return require(... .. ".src")