local vec2 = {}

function vec2.pack(x1, y1)
    return function(x2, y2)
        return x1, y1, x2, y2
    end
end

function vec2.add(x1, y1)
    return function(x2, y2)
        return x1 + x2, y1 + y2
    end
end

function vec2.sub(x1, y1)
    return function(x2, y2)
        return x1 - x2, y1 - y2
    end
end

function vec2.neg(x1, y1)
    return -x1, -y1
end

return vec2