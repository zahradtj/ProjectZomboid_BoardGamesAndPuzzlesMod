-- BoardGamesAndPuzzlesMod_Operation.lua
-- Adds: Insert Battery / Remove Battery / Play Operation to your Operation item.
require "helpers/BoardGame_Thoughts"

local BatteryManager = require "helpers/BoardGame_BatteryManager"

local OP_TYPE = "BoardGamesAndPuzzlesMod.Operation"
local BATTERY_TYPE = "Base.Battery"

BoardGamesAndPuzzlesMod_Operation = BoardGamesAndPuzzlesMod_Operation or {}

function BoardGamesAndPuzzlesMod_Operation.getCharge(item)
    local md = item:getModData()
    return BatteryManager.getCharge(md)
end

local function setCharge(item, charge)
    local md = item:getModData()
    BatteryManager.setCharge(md, charge)
end

function BoardGamesAndPuzzlesMod_Operation.hasBattery(item)
    return BoardGamesAndPuzzlesMod_Operation.getCharge(item) > 0
end

local function findFirst(inventory, fullType)
    return inventory:FindAndReturn(fullType)
end

local function getBatteryUsedDelta(batt)
    -- TODO: fix always-100% issue later; wrapper enables unit tests now
    if batt and batt.getUsedDelta then
        return batt:getUsedDelta()
    end
    return 1.0
end

local function setBatteryUsedDelta(batt, charge)
    if batt and batt.setUsedDelta then
        batt:setUsedDelta(charge)
    end
end

local function doInsertBattery(playerObj, opItem)
    local inv = playerObj:getInventory()
    local batt = findFirst(inv, BATTERY_TYPE)
    if not batt then return end

    -- Batteries in PZ are drainables; charge is 0..1 via getUsedDelta()
    local charge = getBatteryUsedDelta(batt)

    inv:Remove(batt)
    setCharge(opItem, charge)
end

local function doRemoveBattery(playerObj, opItem)
    local inv = playerObj:getInventory()
    local charge = BoardGamesAndPuzzlesMod_Operation.getCharge(opItem)
    if charge <= 0 then return end

    local batt = inv:AddItem(BATTERY_TYPE)
    setBatteryUsedDelta(batt, charge)

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
        getSoundManager():PlayWorldSoundImpl("BGPM_OperationBuzz", false, playerObj:getX(), playerObj:getY(), playerObj:getZ(), 0, 8, 0.8, false)


        playerObj:getEmitter():playSound("BGPM_OperationBuzz")
    end

    -- Not very loud: small radius + low volume
    makeWorldSound(playerObj, 6, 10)
end

function BoardGamesAndPuzzlesMod_Operation.doPlayOperation(playerObj, opItem, rng100)
    rng100 = rng100 or function() return ZombRand(100) end
    local DRAIN = 0.08
    local FAIL = 18 -- TODO - increase this chance drastically if player is clumsy or wearing obnoxious gloves

    local charge = BoardGamesAndPuzzlesMod_Operation.getCharge(opItem)
    local step = BatteryManager.playStep(charge, rng100(), DRAIN, FAIL)

    if step.outcome == "no_battery" then return end

    if step.outcome == "failure" then
        playBuzz(playerObj)
        BoardGame_Thoughts.show(playerObj, OP_TYPE, "failure")
    else
        BoardGame_Thoughts.show(playerObj, OP_TYPE, "success")
    end

    setCharge(opItem, step.newCharge)
end

function BoardGamesAndPuzzlesMod_Operation.isOperationItem(item)
    if not item or not item.getFullType then return false end
    return item:getFullType() == OP_TYPE
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

            -- decide if the user can insert (pure input)
            local hasBatteryInInventory = playerObj:getInventory():containsTypeRecurse("Battery")

            -- PURE decision: what should the menu show?
            local model = BatteryManager.menuModel(charge, hasBatteryInInventory)

            -- UI rendering (side effects)
            local sub = context:addOption("Operation", nil, nil)
            local subMenu = ISContextMenu:getNew(context)
            context:addSubMenu(sub, subMenu)

            subMenu:addOption(model.label, nil, nil)

            if model.showInsert then
                local opt = subMenu:addOption("Insert Battery", playerObj, doInsertBattery, item)
                if not model.insertEnabled then opt.notAvailable = true end
            end

            if model.showRemove then
                subMenu:addOption("Remove Battery", playerObj, doRemoveBattery, item)
            end

            return -- only add once
        end
    end
end

BoardGamesAndPuzzlesMod_Operation._test = {
  _setCharge = setCharge,
  _getBatteryUsedDelta = getBatteryUsedDelta,
  _setBatteryUsedDelta = setBatteryUsedDelta,
  _doInsertBattery = doInsertBattery,
  _doRemoveBattery = doRemoveBattery,
  _addMenuEntries = addMenuEntries,
}

Events.OnFillInventoryObjectContextMenu.Add(addMenuEntries)
return BoardGamesAndPuzzlesMod_Operation
