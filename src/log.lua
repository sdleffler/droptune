local prototype = dtrequire("prototype")

local loggerCode = [[
    local channel, stream = ...
    local msg

    if not stream then
        stream = io.stdout
        stream:setvbuf("no")
    end

    while true do
        stream:write(msg or "")

        if not msg then
            stream:flush()
            msg = channel:demand()
        else
            msg = channel:demand(100)
        end
    end
]]

local defaultLevels = {
    "debug",
    "info",
    "warn",
    "error",
}

local Logger = prototype.new()

function Logger:init(config)
    local levels = config.levels or defaultLevels
    for i, level in ipairs(levels) do
        assert(type(level) == "string", "logging levels must be strings")
        levels[level] = i
    end

    self.levels = levels
    self.minimum = config.minimum and levels[config.minimum] or levels[1]

    local channel = config.channel
    if not channel then
        local file = config.file
        if type(file) == "string" then
            local err
            file, err = love.filesystem.newFile(file, "w")
            
            if err then
                error(err)
            end
        elseif file then
            assert(file.type and file:type() == "File", "logging target must be a filename string, a File object, or nil")
        end

        channel = love.thread.newChannel()
        self.logger_thread = love.thread.newThread(loggerCode)
        self.logger_thread:start(channel, file)
    end

    self.channel = channel
end

function Logger:clone()
    return Logger:new(self)
end

function Logger:format(level, msg)
    return string.format("[%s] %s\n", level, msg)
end

function Logger:setMinimumLevel(level)
    local value = self.levels[level]
    assert(value, "unrecognized logging level")
    self.minimum = value
end

function Logger:push(level, msg, ...)
    local value = self.levels[level]
    assert(value, "unrecognized logging level")
    if value >= self.minimum then
        local formatted = self:format(level, string.format(msg, ...))
        self.channel:push(formatted)
    end
end

function Logger:debug(...)
    self:push("debug", ...)
end

function Logger:info(...)
    self:push("info", ...)
end

function Logger:warn(...)
    self:push("warn", ...)
end

function Logger:error(...)
    self:push("error", ...)
end

return {
    Logger = Logger,
}