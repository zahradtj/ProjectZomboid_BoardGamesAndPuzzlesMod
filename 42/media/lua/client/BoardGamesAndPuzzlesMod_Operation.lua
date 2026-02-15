-- BoardGamesAndPuzzlesMod_OperationBatteryMenu.lua
-- Adds: Insert Battery / Remove Battery / Play Operation to your Operation item.

local OP_TYPE = "BoardGamesAndPuzzlesMod.Operation"
local BATTERY_TYPE = "Base.Battery"

BoardGamesAndPuzzlesMod_Operation = BoardGamesAndPuzzlesMod_Operation or {}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function BoardGamesAndPuzzlesMod_Operation.getCharge(item)
    local md = item:getModData()
    if md.opBatteryCharge == nil then md.opBatteryCharge = 0 end -- 0..1 like UsedDelta
    return md.opBatteryCharge
end

local function setCharge(item, charge)
    local md = item:getModData()
    md.opBatteryCharge = clamp(charge, 0, 1)
end

function BoardGamesAndPuzzlesMod_Operation.hasBattery(item)
    return BoardGamesAndPuzzlesMod_Operation.getCharge(item) > 0
end

local function findFirst(inventory, fullType)
    return inventory:FindAndReturn(fullType)
end

local function doInsertBattery(playerObj, opItem)
    local inv = playerObj:getInventory()
    local batt = findFirst(inv, BATTERY_TYPE)
    if not batt then return end

    -- Batteries in PZ are drainables; charge is 0..1 via getUsedDelta()
    local charge = batt.getUsedDelta and batt:getUsedDelta() or 1.0  --TODO - fix this, battery is always inserted as 100%

    inv:Remove(batt)
    setCharge(opItem, charge)
end

local function doRemoveBattery(playerObj, opItem)
    local inv = playerObj:getInventory()
    local charge = BoardGamesAndPuzzlesMod_Operation.getCharge(opItem)
    if charge <= 0 then return end

    local batt = inv:AddItem(BATTERY_TYPE)
    if batt and batt.setUsedDelta then
        batt:setUsedDelta(charge)
    end

    setCharge(opItem, 0)
end

-- Small helper to create a zombie-hearable sound.
-- Build 42 exposes a global AddWorldSound in javadocs; it’s commonly reachable from Lua as addWorldSound(...).
-- (If your environment only has addSound(...), swap it in.)
local function makeWorldSound(playerObj, radius, volume)
    if addWorldSound then
        addWorldSound(playerObj, radius, volume) -- see LuaManager.GlobalObject.AddWorldSound :contentReference[oaicite:1]{index=1}
        return
    end

    -- Fallback: older/global signature some builds use:
    if addSound then
        addSound(playerObj, playerObj:getX(), playerObj:getY(), playerObj:getZ(), radius, volume)
        return
    end
end

local function playBuzz(playerObj)
    local emitter = playerObj:getEmitter()
    if emitter then
        --local p = getSpecificPlayer(0)
        getSoundManager():PlayWorldSoundImpl("BoardGamesAndPuzzlesMod_OperationBuzz", false, playerObj:getX(), playerObj:getY(), playerObj:getZ(), 0, 8, 0.8, false)


        playerObj:getEmitter():playSound("BoardGamesAndPuzzlesMod_OperationBuzz")
    end

    -- Not very loud: small radius + low volume
    makeWorldSound(playerObj, 6, 10)
end

function BoardGamesAndPuzzlesMod_Operation.doPlayOperation(playerObj, opItem)
    -- Drain amount per “play”
    local DRAIN = 0.08  -- ~8% of a battery per play; tune to taste
    local charge = BoardGamesAndPuzzlesMod_Operation.getCharge(opItem)
    if charge <= 0 then return end

    -- Chance to buzz while playing
    if ZombRand(100) < 18 then -- 18% chance; tune to taste -- TODO - increase this chance drastically if player is clumsy or wearing obnoxious gloves
        playBuzz(playerObj)
    end

    setCharge(opItem, charge - DRAIN)
end

function BoardGamesAndPuzzlesMod_Operation.isOperationItem(item)
    return item and item.getFullType and item:getFullType() == OP_TYPE
end

local function addMenuEntries(playerIndex, context, items)
    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj then return end

    -- Handle right-click stacks (items may be wrappers)
    for _, entry in ipairs(items) do
        local item = entry
        if type(entry) == "table" and entry.items and entry.items[1] then
            item = entry.items[1]
        end

        if BoardGamesAndPuzzlesMod_Operation.isOperationItem(item) then
            local charge = BoardGamesAndPuzzlesMod_Operation.getCharge(item)

            local battLabel = string.format("Battery: %d%%", math.floor(charge * 100 + 0.5))
            local sub = context:addOption("Operation", nil, nil)
            local subMenu = ISContextMenu:getNew(context)
            context:addSubMenu(sub, subMenu)

            subMenu:addOption(battLabel, nil, nil)

            if charge <= 0 then
                local canInsert = playerObj:getInventory():containsTypeRecurse("Battery")
                local opt = subMenu:addOption("Insert Battery", playerObj, doInsertBattery, item)
                if not canInsert then opt.notAvailable = true end
            else
                subMenu:addOption("Remove Battery", playerObj, doRemoveBattery, item)
            end

            return -- only add once
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addMenuEntries)
