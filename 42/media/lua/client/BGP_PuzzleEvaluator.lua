-- BGP_PuzzleEvaluator.lua
local Puzzles = require("BGP_Puzzles")
local Req = require("BGP_Requirements")
local Core = require("BGP_PuzzlesCore")
local PM = require("helpers/Puzzle_ProgressManager")

local M = {}

function M.evaluate(playerObj, item, worldItemObj)
    if not item then return nil end
    if not Puzzles.isPuzzle(item:getFullType()) then return nil end

    local label = "Work on Puzzle"

    local md = item:getModData()
    local prog = PM.getProgress(md)

    if prog >= 1 then
        return {
            ok = false,
            label = label,
            tooltip = { "Cannot work:", "- Puzzle already complete." }
        }
    end
    local missing = {}

    if worldItemObj and not Req.isCharacterNearWorldItem(playerObj, worldItemObj) then
        table.insert(missing, "- Too far away.")
    end
    if not Req.hasNearbySurface(playerObj, 1) then
        missing[#missing+1] = "- Requires a nearby surface (table)."
    end
    if not Req.hasEnoughLight(playerObj, 0.30) then
        missing[#missing+1] = "- Not enough light."
    end
    if #missing > 0 then
        table.insert(missing, 1, "Cannot work right now:")
        return { ok=false, label=label, tooltip=missing }
    end

    -- Keep display name current (design/progress)
    Core.updateName(item)

    local ok, tooltip = Core.canWorkNow(playerObj, item)
    if not ok then
        return { ok=false, label=label, tooltip=tooltip }
    end

    local tuning = Core.getWorkTuning(playerObj, item)
    return {
        ok = true,
        label = label,
        duration = tuning.duration,
        tuning = tuning,
    }
end

return M