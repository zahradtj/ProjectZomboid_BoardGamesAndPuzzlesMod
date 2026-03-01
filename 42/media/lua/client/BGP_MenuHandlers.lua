-- media/lua/client/BoardGamesAndPuzzles/BGP_MenuHandlers.lua

require "TimedActions/ISTimedActionQueue"

require "TimedActions/ISPlayBoardGameFromInventory"
require "TimedActions/ISPlayBoardGameFromGround"
require "TimedActions/ISWorkPuzzleFromInventory"
require "TimedActions/ISWorkPuzzleFromGround"

local Tooltips = require("BGP_Tooltips")
local Eval = require("BGP_GameEvaluator")
local PuzzleEval = require("BGP_PuzzleEvaluator")
local GameDefs = require("BGP_GameDefs")
local Core = require("BGP_PuzzlesCore")

local Puzzles = require("BGP_Puzzles")
local PM = require("helpers/Puzzle_ProgressManager")

local GAME_DEFS = GameDefs.GAME_DEFS

local M = {}

-- ----------------------------
-- Actions
-- ----------------------------

local function onPlayFromInventory(context, playerObj, item, label, duration, boredomReduce, unhappyReduce, stressReduce)
    context:addOption(label, playerObj, function(p)
        ISTimedActionQueue.add(ISPlayBoardGameFromInventory:new(p, item, duration, boredomReduce, unhappyReduce, stressReduce))
    end)
end

local function onPlayFromGround(context, playerObj, item, label, duration, boredomReduce, unhappyReduce, stressReduce, worldItemObj)
    context:addOption(label, playerObj, function(p)
        ISTimedActionQueue.add(ISPlayBoardGameFromGround:new(p, worldItemObj, item, duration, boredomReduce, unhappyReduce, stressReduce))
    end)
end

local function onWorkPuzzleFromInventory(context, playerObj, item, label, duration, tuning)
    context:addOption(label, playerObj, function(p)
        ISTimedActionQueue.add(ISWorkPuzzleFromInventory:new(p, item, duration, tuning))
    end)
end

local function onWorkPuzzleFromGround(context, playerObj, item, label, duration, tuning, worldItemObj)
    context:addOption(label, playerObj, function(p)
        ISTimedActionQueue.add(ISWorkPuzzleFromGround:new(p, worldItemObj, item, duration, tuning))
    end)
end

-- ----------------------------
-- Options
-- ----------------------------

local function addBoardGameOption(context, playerObj, item, playFn, worldItemObj)
    local eval = Eval.evaluate(playerObj, item, worldItemObj)
    if not eval then return end

    if not eval.ok then
        Tooltips.addDisabledOptionWithTooltip(context, eval.label, eval.tooltip)
    else
        if worldItemObj then
            playFn(context, playerObj, item, eval.label, eval.duration, eval.boredom, eval.unhappy, eval.stress, worldItemObj)
        else
            playFn(context, playerObj, item, eval.label, eval.duration, eval.boredom, eval.unhappy, eval.stress)
        end
    end
end

local function resetPuzzle(item)
    if not item then return end
    local md = item:getModData()
    PM.setProgress(md, 0)
    Core.syncItemModData(item)
    Core.updateName(item)
end

local function addPuzzleOption(context, playerObj, item, workFn, worldItemObj)
    if not item or not item.getFullType then return end
    local ft = item:getFullType()
    if not Puzzles.isPuzzle(ft) then return end

    -- Reset only if started
    local md = item:getModData()
    local prog = PM.getProgress(md)
    if prog > 0 then
        context:addOption("Take Puzzle Apart (Reset)", playerObj, function(_p)
            resetPuzzle(item)
        end)
    end

    local eval = PuzzleEval.evaluate(playerObj, item, worldItemObj)
    if not eval then return end

    if not eval.ok then
        Tooltips.addDisabledOptionWithTooltip(context, eval.label, eval.tooltip)
    else
        if worldItemObj then
            workFn(context, playerObj, item, eval.label, eval.duration, eval.tuning, worldItemObj)
        else
            workFn(context, playerObj, item, eval.label, eval.duration, eval.tuning)
        end
    end
end

-- ----------------------------
-- Inventory menu
-- ----------------------------

function M.OnFillInventoryObjectContextMenu(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    for _, entry in ipairs(items) do
        local item = entry
        if type(entry) == "table" and entry.items then
            item = entry.items[1]
        end

        addBoardGameOption(context, playerObj, item, onPlayFromInventory)
        addPuzzleOption(context, playerObj, item, onWorkPuzzleFromInventory)
    end
end

-- ----------------------------
-- World menu helpers
-- ----------------------------

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

    local worldItemObj, invItem = getClickedWorldItem(worldobjects)
    if not invItem then return end

    local ft = invItem:getFullType()

    if GAME_DEFS[ft] then
        if test then return true end
        addBoardGameOption(context, playerObj, invItem, onPlayFromGround, worldItemObj)

    elseif Puzzles.isPuzzle(ft) then
        if test then return true end
        addPuzzleOption(context, playerObj, invItem, onWorkPuzzleFromGround, worldItemObj)
    end
end

return M