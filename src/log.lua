local prototype = dtrequire("prototype")

local loggerCode = [[
    local channel, stream = ...
    local msg

    if not stream then
        stream = io.stdout
        stream:setvbuf("no")
    end

    repeat
        msg = channel:demand(5000)

        if not msg then
            stream:flush()
        else
            stream:write(msg)
        end

        msg = channel:demand()
    until not msg
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
        self.channel:push(self:format(level, string.format(msg, ...)))
    end
end

return {
    Logger = Logger,
}