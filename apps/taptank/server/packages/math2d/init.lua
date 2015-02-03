
local math2d = {}

function math2d.dist(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    return math.sqrt(dx * dx + dy * dy)
end

function math2d.angleBetweenPoints(ax, ay, bx, by)
    return math.atan2(ay - by, bx - ax)
end

function math2d.pointAtCircle(px, py, radians, radius)
    return px + math.cos(radians) * radius, py - math.sin(radians) * radius
end

function math2d.angle(degrees)
    return degrees * math.pi / 180
end

function math2d.degrees(radians)
    return radians * 180 / math.pi
end

return math2d
