-- media/lua/client/BoardGamesAndPuzzles/BGP_Requirements.lua

local M = {}

function M.hasNearbySurface(playerObj, radius)
    radius = radius or 1
    if not playerObj then return false end
    local sq = playerObj:getSquare()
    if not sq then return false end

    -- You currently ignore radius; keeping behavior identical.
    local surrounding = sq:getSurroundingSquares()
    for _, tile in pairs(surrounding) do
        if tile and tile:getProperties() and tile:getProperties():getSurface() and tile:getProperties():getSurface() > 0 then
            return true
        end
    end

    return false
end

local function playerHasLightSource(playerObj)
    local prim = playerObj:getPrimaryHandItem()
    local sec  = playerObj:getSecondaryHandItem()

    local function isOn(item)
        return item and item.isEmittingLight and item:isEmittingLight()
    end

    return isOn(prim) or isOn(sec)
end

function M.hasEnoughLight(playerObj, minLevel)
    minLevel = minLevel or 0.30
    local sq = playerObj and playerObj:getSquare()
    if not sq then return false end

    if sq:isOutside() then
        local gt = GameTime.getInstance()
        local hour = gt:getHour()
        if hour >= 7 and hour <= 18 then
            return true
        end
    end

    if playerHasLightSource(playerObj) then
        return true
    end

    if sq.getLightLevel then
        local lvl = sq:getLightLevel(playerObj:getPlayerNum())
        return lvl and lvl >= minLevel
    end

    return false
end

return M
