local aabb = {}

function aabb.center(l, t, w, h)
    return l + w/2, t + h/2
end

function aabb.upperleft(l, t, w, h)
    return l, t
end

function aabb.uppermiddle(l, t, w, h)
    return l+w/2, t
end

function aabb.upperright(l, t, w, h)
    return l+w, t
end

function aabb.middleright(l, t, w, h)
    return l+w, t+h/2
end

function aabb.lowerright(l, t, w, h)
    return l+w, t+h
end

function aabb.lowermiddle(l, t, w, h)
    return l+w/2, t+h
end

function aabb.lowerleft(l, t, w, h)
    return l, t+h
end

function aabb.middleleft(l, t, w, h)
    return l, t+h/2
end

function aabb.merge(l1, t1, w1, h1)
    return function(l2, t2, w2, h2)
        local r1 = l1 + w1
        local r2 = l2 + w2
        local b1 = t1 + h1
        local b2 = t2 + h2
        
        local l = (l1 < l2 and l1) or l2
        local t = (t1 < t2 and t1) or t2
        local w = ((r1 > r2 and r1) or r2) - l
        local h = ((b1 > b2 and b1) or b2) - t

        return l, t, w, h
    end
end

function aabb.mirror(l, t, w, h)
    return function(x, y)
        l = l + math.min(0, x)
        t = t + math.min(0, y)
        w = w + math.abs(x)
        h = h + math.abs(y)
        return l, t, w, h
    end
end

return aabb