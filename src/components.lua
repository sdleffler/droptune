function recursiveDTRequire(directoryPath)
    local files = love.filesystem.getDirectoryItems(directoryPath)
    local loaded = {}
    while #files > 0 do
        local path = table.remove(files)
        local fullpath = directoryPath .. "/" .. path
        local found = fullpath:find("%.lua$")
        if found then
            local includePath = fullpath:sub(1, found-1):gsub("/", ".")
            local name = path:sub(1, path:find("%.lua$")-1)
            LOGGER:info("loading component: %s", includePath)
            loaded[name] = require(includePath)
        elseif love.filesystem.getInfo(path).type == "directory" then
            loaded[path] = recursiveDTRequire(fullpath)
        end
    end
    return loaded
end

return recursiveDTRequire(DROPTUNE_SRC .. "/components")