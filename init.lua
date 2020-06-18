-- Shim in case droptune is being used as a git submodule or such.

if ... then
    return require((...):gsub('%.init$', '') .. ".src")
else
    return require("src.init")
end