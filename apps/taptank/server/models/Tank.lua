
local ngx_now = ngx.now
local math_abs = math.abs

local math2d = cc.load("math2d")
local math2d_dist = math2d.dist
local math2d_degrees = math2d.degrees
local math2d_angleBetweenPoints = math2d.angleBetweenPoints

local GameConfig = import("..GameConfig")

-- Tank class
local Tank = class("Tank")

local _BORDER_SIZE = 20
local _ACTION_COLDDOWN_TIME = 0.5
local _COLORS = {"Red", "Blue", "Green", "Yellow"}

local function _absDegrees(d)
    while d < 0 do d = d + 360 end
    return d % 360
end

function Tank:ctor(uid)
    self._uid = uid
    self._color = "Red"
    self._x = 0
    self._y = 0
    self._rotation = 0
    self._lastMoveTime = 0
    self._speed = 60
    self._rotationSpeed = 120
end

function Tank:getUid()
    return self._uid
end

function Tank:getPosition()
    return {x = self._x, y = self._y}
end

function Tank:getRotation()
    return self._rotation
end

function Tank:enter()
    math.randomseed(ngx_now() * 10000)
    self._x = math.random(_BORDER_SIZE, GameConfig.BATTLE_ZONE_SIZE.width - _BORDER_SIZE * 2)
    self._y = math.random(_BORDER_SIZE, GameConfig.BATTLE_ZONE_SIZE.height - _BORDER_SIZE * 2)
    self._rotation = math.round(math.random(0, 360) / 90) * 90
    self._color = _COLORS[math.random(1, #_COLORS)]
    return {
        color = self._color,
        x = self._x,
        y = self._y,
        rotation = self._rotation
    }
end

function Tank:move(x, y, rotation, destx, desty)
    local now = ngx_now()
    if now - self._lastMoveTime < _ACTION_COLDDOWN_TIME then
        return
    end

    self._lastMoveTime = now
    self._x, self._y = x, y
    local dist = math2d_dist(x, y, destx, desty)
    local destr = _absDegrees(math2d_degrees(math2d_angleBetweenPoints(x, y, destx, desty)))
    rotation = _absDegrees(rotation)
    self._rotation = rotation

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
        x = self._x,
        y = self._y,
        rotation = rotation,
        destx = destx,
        desty = desty,
        destr = destr,
        dist  = dist,
        dir = dir,
        rotateoffset = math_abs(rotateoffset)
    }
end

return Tank
