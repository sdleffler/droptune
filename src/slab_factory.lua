local dtrequire = dtrequire

return function()
    local newgt = setmetatable({}, {__index = _G})
    setfenv(1, newgt)

    -- Shenaniganize the global state
    local unload = {}
    for k, v in pairs(package.loaded) do
        --print("unloading", k, v)
        unload[k], package.loaded[k] = v, nil
    end

    -- The ffi module has global state corresponding to loaded ffi functions
    -- that have to be carried over.
    package.loaded.ffi = unload.ffi

    local Slab = dtrequire("lib.Slab")
    local SlabDebug = dtrequire("lib.Slab.SlabDebug")

    -- Deshenaniganize.
    for k, v in pairs(unload) do
        --print("reloading", k, v)
        package.loaded[k] = v
    end

    return {
        Slab = Slab,
        SlabDebug = SlabDebug,
    }
end