
local ngx_now = ngx.now
local math_abs = math.abs

local math2d = cc.load("math2d")
local math2d_dist = math2d.dist
local math2d_degrees = math2d.degrees
local math2d_angleBetweenPoints = math2d.angleBetweenPoints

local Game = import(".Game")

-- Tank class
local Tank = class("Tank")

Tank.ACTION_COLDDOWN_TIME = 0.5

local function _absDegrees(d)
    while d < 0 do d = d + 360 end
    return d % 360
end

function Tank:ctor()
    self.x = 0
    self.y = 0
    self.rotation = 0
    self.lastMoveTime = 0
end

function Tank:setRandomPosition()
    math.randomseed(ngx_now() * 10000)
    self.x = math.random(0, Game.BATTLE_ZONE_SIZE.width)
    self.y = math.random(0, Game.BATTLE_ZONE_SIZE.height)
    self.rotation = math.round(math.random(0, 360) / 90) * 90
end

function Tank:move(cx, cy, rotation, dx, dy)
    local now = ngx_now()
    if now - self.lastMoveTime < Tank.ACTION_COLDDOWN_TIME then
        return
    end

    self.lastMoveTime = now
    self.x, self.y = cx, cy
    local dist = math2d_dist(cx, cy, dx, dy)
    local destr = _absDegrees(math2d_degrees(math2d_angleBetweenPoints(cx, cy, dx, dy)))
    rotation = _absDegrees(rotation)
    self.rotation = rotation

    local offset = rotation - destr
    local dir = "left"
    if offset > 180 or (offset < 0 and offset >= -180) then
        dir = "right"
    end

    local rotateoffset1 = _absDegrees(destr - rotation)
    local rotateoffset2 = _absDegrees(rotation - destr)
    local rotateoffset = rotateoffset1
    if rotateoffset1 > rotateoffset2 then
        rotateoffset = rotateoffset2
    end
    return {
        move = true,
        x = dx,
        y = dy,
        dist = dist,
        destr = destr,
        rotation = rotation,
        dir = dir,
        rotateoffset = math_abs(rotateoffset)
    }
end

return Tank
