-- media/lua/client/BoardGamesAndPuzzles/BGP_GameEvaluator.lua

local GameDefs = require("BGP_GameDefs")
local Req = require("BGP_Requirements")

local Operation = require "BoardGamesAndPuzzlesMod_Operation"

local GAME_DEFS = GameDefs.GAME_DEFS

local M = {}

-- Returns:
--   nil (not a boardgame item)
--   { ok=false, label=string, tooltip=table<string> }
--   { ok=true, label=string, duration=number, boredom=number, unhappy=number, stress=number, gameDef=table }
function M.evaluate(playerObj, item)
    if not playerObj or not item or not item.getFullType then return nil end

    local fullType = item:getFullType()
    if not fullType then return nil end

    local gameDef = GAME_DEFS[fullType]
    if not gameDef then return nil end

    local label = "Play " .. gameDef.name

    -- Literacy gating
    if playerObj:hasTrait(CharacterTrait.ILLITERATE) and not gameDef.default.illiterateAllowed then
        return {
            ok = false,
            label = label,
            tooltip = { "Cannot play:", "- Requires reading ability." },
            gameDef = gameDef,
        }
    end

    -- Requirements
    local missing = {}

    if not Req.hasNearbySurface(playerObj, 1) then
        table.insert(missing, "- Requires a nearby surface (table).")
    end

    if not Req.hasEnoughLight(playerObj, 0.30) then
        table.insert(missing, "- Not enough light.")
    end

    if gameDef.usesBattery and not Operation.hasBattery(item) then
        table.insert(missing, "- Requires a charged battery.")
    end

    if #missing > 0 then
        table.insert(missing, 1, "Cannot play right now:")
        return { ok = false, label = label, tooltip = missing, gameDef = gameDef }
    end

    -- Duration adjustments
    local duration = gameDef.duration

    if not gameDef.default.illiterateAllowed then
        if playerObj:hasTrait(CharacterTrait.SLOW_READER) then
            duration = math.floor(duration * 1.5)
        elseif playerObj:hasTrait(CharacterTrait.FAST_READER) then
            duration = math.floor(duration * 0.5)
        end
    end

    if gameDef.clumsyImpacted then
        if playerObj:hasTrait(CharacterTrait.ALL_THUMBS)
            or playerObj:hasTrait(CharacterTrait.CLUMSY)
            or playerObj:isWearingAwkwardGloves()
        then
            duration = math.floor(duration * 1.25)
        elseif playerObj:hasTrait(CharacterTrait.DEXTROUS) then
            duration = math.floor(duration * 0.75)
        end
    end

    -- Normalize stress reduce (PZ stress is 0..1)
    local stressReduce = gameDef.stressReduce
    if stressReduce and stressReduce > 1 then
        stressReduce = stressReduce / 100
    end

    return {
        ok = true,
        label = label,
        duration = duration,
        boredom = gameDef.boredomReduce,
        unhappy = gameDef.unhappyReduce,
        stress = stressReduce or 0.08,
        gameDef = gameDef,
    }
end

return M
