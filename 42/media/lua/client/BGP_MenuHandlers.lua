-- media/lua/client/BoardGamesAndPuzzles/BGP_MenuHandlers.lua

require "TimedActions/ISTimedActionQueue"

require "TimedActions/ISPlayBoardGameFromInventory"
require "TimedActions/ISPlayBoardGameFromGround"

local Tooltips = require("BGP_Tooltips")
local Eval = require("BGP_GameEvaluator")
local GameDefs = require("BGP_GameDefs")

local GAME_DEFS = GameDefs.GAME_DEFS

local M = {}

-- Both play functions share the same signature you stated.
local function onPlayFromInventory(context, playerObj, item, label, duration, boredomReduce, unhappyReduce, stressReduce)
    context:addOption(label, playerObj, function(p)
        ISTimedActionQueue.add(ISPlayBoardGameFromInventory:new(p, item, duration, boredomReduce, unhappyReduce, stressReduce))
    end)
end

local function onPlayFromGround(context, playerObj, item, label, duration, boredomReduce, unhappyReduce, stressReduce)
    -- If your ISPlayBoardGameFromGround still takes worldItemObj, update it to use item:getWorldItem()
    -- (recommended), then signature stays identical.
    context:addOption(label, playerObj, function(p)
        ISTimedActionQueue.add(ISPlayBoardGameFromGround:new(p, item, duration, boredomReduce, unhappyReduce, stressReduce))
    end)
end

local function addBoardGameOption(context, playerObj, item, playFn)
    local eval = Eval.evaluate(playerObj, item)
    if not eval then return end

    if not eval.ok then
        Tooltips.addDisabledOptionWithTooltip(context, eval.label, eval.tooltip)
    else
        playFn(context, playerObj, item, eval.label, eval.duration, eval.boredom, eval.unhappy, eval.stress)
    end
end

-- Inventory menu
function M.OnFillInventoryObjectContextMenu(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    for _, entry in ipairs(items) do
        local item = entry
        if type(entry) == "table" and entry.items then
            item = entry.items[1]
        end

        addBoardGameOption(context, playerObj, item, onPlayFromInventory)
    end
end

-- World menu helpers
local function getClickedWorldItem(worldobjects)
    for _, o in ipairs(worldobjects) do
        if instanceof(o, "IsoWorldInventoryObject") then
            local item = o:getItem()
            if item then return o, item end
        end
    end
    return nil, nil
end

function M.OnFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    local _, invItem = getClickedWorldItem(worldobjects)
    if not invItem then return end

    if not GAME_DEFS[invItem:getFullType()] then return end

    if test then return true end

    addBoardGameOption(context, playerObj, invItem, onPlayFromGround)
end

return M
