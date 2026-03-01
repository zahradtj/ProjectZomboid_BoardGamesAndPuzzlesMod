-- media/lua/client/BoardGamesAndPuzzles/BGP_Requirements.lua

local M = {}

function M.hasNearbySurface(playerObj, radius)
    radius = radius or 1
    if not playerObj then return false end
    local sq = playerObj:getSquare()
    if not sq then return false end

    local cell = getCell()
    local cx, cy, cz = sq:getX(), sq:getY(), sq:getZ()

    local function squareHasSurface(s)
        local p = s and s.getProperties and s:getProperties() or nil
        if not p then return false end

        -- This is the classic/most reliable check for many tiles
        if p.getSurface then
            local ok, surf = pcall(function() return p:getSurface() end)
            if ok and surf and surf > 0 then return true end
        end

        -- Sometimes exposed as "Surface" property instead of getSurface()
        if p.Val then
            local ok, v = pcall(function() return p:Val("Surface") end)
            local n = ok and tonumber(v) or nil
            if n and n > 0 then return true end
        end

        return false
    end

    local function objectLooksLikeSurface(obj)
        if not obj then return false end
        local spr = (obj.getSprite and obj:getSprite()) or nil
        local props = (spr and spr.getProperties and spr:getProperties()) or nil
        if not props then return false end

        -- Flag-style properties
        if props.Is then
            local ok, isTableTop = pcall(function() return props:Is("IsTableTop") end)
            if ok and isTableTop then return true end
            local ok2, isSurface = pcall(function() return props:Is("Surface") end)
            if ok2 and isSurface then return true end
        end

        -- Value-style properties
        if props.Val then
            local okG, group = pcall(function() return props:Val("GroupName") end)
            if okG and (group == "Table" or group == "Counter") then return true end

            local okS, surface = pcall(function() return props:Val("Surface") end)
            local n = okS and tonumber(surface) or nil
            if n and n > 0 then return true end

            local okN, custom = pcall(function() return props:Val("CustomName") end)
            if okN and type(custom) == "string" then
                local lc = string.lower(custom)
                if lc:find("table", 1, true) or lc:find("counter", 1, true) then
                    return true
                end
            end
        end

        return false
    end

    for dx = -radius, radius do
        for dy = -radius, radius do
            local s = cell:getGridSquare(cx + dx, cy + dy, cz)
            if s then
                -- 1) Square-level surface (important!)
                if squareHasSurface(s) then
                    return true
                end

                -- 2) Object-level surface hints
                local objs = s:getObjects()
                for i = 0, objs:size() - 1 do
                    if objectLooksLikeSurface(objs:get(i)) then
                        return true
                    end
                end
            end
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

function M.isCharacterNearWorldItem(playerObj, worldItemObj)
    local psq = playerObj and playerObj:getSquare()
    if not psq then return false end

    local sq = worldItemObj:getSquare()
    if not sq then return false end

    local dx = math.abs(psq:getX() - sq:getX())
    local dy = math.abs(psq:getY() - sq:getY())

    -- within 1 tile (includes diagonals)
    if math.max(dx, dy) > 1 then return false end

    -- optional: also require same Z level
    if psq:getZ() ~= sq:getZ() then return false end

    return true
end

return M
