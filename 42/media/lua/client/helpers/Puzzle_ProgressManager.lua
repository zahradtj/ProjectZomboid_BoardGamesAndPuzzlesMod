-- helpers/Puzzle_ProgressManager.lua
local M = {}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function M.ensureSeed(md)
  if md.bgpPuzzleSeed == nil then
    md.bgpPuzzleSeed = ZombRand(1, 2147483647)
  end
  return md.bgpPuzzleSeed
end

function M.ensureDesign(md, designId)
  if md.bgpPuzzleDesign == nil and designId then
    md.bgpPuzzleDesign = designId
  end
  return md.bgpPuzzleDesign
end

function M.getProgress(md)
    local v = md.bgpPuzzleProgress
    if v == nil then
        md.bgpPuzzleProgress = 0
        return 0
    end
    return v
end

function M.setProgress(md, progress)
    md.bgpPuzzleProgress = clamp(progress, 0, 1)
    return md.bgpPuzzleProgress
end

function M.puzzleLabel(progress)
    return string.format("Progress: %d%%", math.floor(progress * 100 + 0.5))
end

function M.menuModel(progress)
    progress = clamp(progress or 0, 0, 1)
    return {
        label = M.puzzleLabel(progress),
        showComplete = (progress >= 1),
        showDisassemble = (progress > 0),
    }
end

-- rng100 is a random int 0..99 supplied by caller
function M.playStep(progress, rng100, increment, failChancePercent)
    progress = clamp(progress or 0, 0, 1)
    if progress >= 1 then
        return { outcome = "complete", newProgress = 1 }
    end

    local success = not (rng100 < failChancePercent)
    local newProgress = success and clamp(progress + increment, 0, 1) or progress
    return { outcome = success and "success" or "failure", newProgress = newProgress }
end

return M
