-- media/lua/client/BGP_puzzles_core.lua
local Core = {}

local Puzzles = require("BGP_Puzzles")
local Req = require("BGP_Requirements")
local PM = require("helpers/Puzzle_ProgressManager")
local CompFuns = require("BGP_CompatFuncs")

-- Define strings for version 42.12 and lower
local ALL_THUMBS
local CLUMSY
local DEXTROUS

if CharacterTrait then
    ALL_THUMBS = CharacterTrait.ALL_THUMBS
    CLUMSY = CharacterTrait.CLUMSY
    DEXTROUS = CharacterTrait.DEXTROUS
else
    ALL_THUMBS = "AllThumbs"
    CLUMSY = "Clumsy"
    DEXTROUS = "Dextrous"
end

-- ----------------------------
-- Helpers
-- ----------------------------

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function setItemDisplayName(item, name)
    if not item or not name then return end

    -- Most builds: InventoryItem:setName(string)
    if item.setName then
        item:setName(name)
        return
    end

    -- Some builds: InventoryItem:setCustomName(boolean) + setName
    if item.setCustomName then
        item:setCustomName(true)
    end
    if item.setName then
        item:setName(name)
        return
    end

    -- Fallbacks seen in some mods/builds
    if item.setDisplayName then
        item:setDisplayName(name)
        return
    end

    -- If none exist, do nothing (avoids hard crash)
end

local function pct(progress01)
    return math.floor(clamp(progress01 or 0, 0, 1) * 100 + 0.5)
end

local function getMd(item)
    return item:getModData()
end

local function ensureIdentity(item)
    -- With design-specific fullTypes, identity = seed + progress only.
    local md = getMd(item)
    PM.ensureSeed(md)
    -- progress init happens via PM.getProgress when needed
    return md
end

local function formatPieces(n)
    n = tonumber(n) or 0
    if n <= 0 then return "Unknown Piece" end
    return tostring(n) .. " Piece"
end

function Core.syncItemModData(item)
    if not item then return end

    -- Common on many builds
    if item.transmitModData then
        item:transmitModData()
        return
    end

    -- Some builds expose transmitCompleteItemToServer instead
    if item.transmitCompleteItemToServer then
        item:transmitCompleteItemToServer()
        return
    end

    -- Some allow forcing a sync via container dirtying
    local c = item.getContainer and item:getContainer() or nil
    if c and c.setDrawDirty then
        c:setDrawDirty(true)
    end
end

-- ----------------------------
-- Public API
-- ----------------------------

function Core.canWorkNow(playerObj, item)
    if not playerObj or not item then
        return false, { "Cannot work right now." }
    end

    local missing = {}

    if not Req.hasNearbySurface(playerObj, 1) then
        missing[#missing+1] = "- Requires a nearby surface (table)."
    end
    if not Req.hasEnoughLight(playerObj, 0.30) then
        missing[#missing+1] = "- Not enough light."
    end

    if #missing > 0 then
        table.insert(missing, 1, "Cannot work right now:")
        return false, missing
    end

    return true, nil
end

local function getSessionSimParams(pieces)
  -- Attempts per session (feel free to tune)
  local attempts =
      (pieces == 20 and 25)
      or (pieces == 500 and 60)
      or (pieces == 1000 and 80)
      or (pieces == 2000 and 110)
      or 60

  -- Probability curve: slow early, fast late
  -- mini: high base, gentle ramp
  if pieces == 20 then
    return { attempts=attempts, baseP=0.55, gainP=0.35, exponent=1.2 }
  end

  -- 500: moderate base, moderate ramp
  if pieces == 500 then
    return { attempts=attempts, baseP=0.20, gainP=0.55, exponent=1.6 }
  end

  -- 1000: lower base, stronger ramp
  if pieces == 1000 then
    return { attempts=attempts, baseP=0.14, gainP=0.62, exponent=1.8 }
  end

  -- 2000: lowest base, strongest ramp
  return { attempts=attempts, baseP=0.10, gainP=0.70, exponent=2.1 }
end

function Core.getWorkTuning(playerObj, item)
    local fullType = item:getFullType()
    local sizeDef = Puzzles.getSizeDefByFullType(fullType)  -- <-- correct for new scheme
    local md = ensureIdentity(item)
    local progress = PM.getProgress(md)

    local TICKS_PER_MINUTE = 11250 / 60
    local duration = math.floor((sizeDef.baseMinutes or 60) * TICKS_PER_MINUTE)

    local sessions =
        (sizeDef.pieces == 20 and 1)
        or (sizeDef.pieces == 500 and 3)
        or (sizeDef.pieces == 1000 and 6)
        or (sizeDef.pieces == 2000 and 12)
        or 6

    local increment = 1 / sessions

        local failChancePercent = 0
    if playerObj then
        -- Build 42 uses CharacterTrait userdata, not strings
        if CompFuns.playerHasTrait(playerObj, ALL_THUMBS) or CompFuns.playerHasTrait(playerObj, CLUMSY) then
            failChancePercent = failChancePercent + 10
        end

        if CompFuns.playerHasTrait(playerObj, DEXTROUS) then
            failChancePercent = math.max(0, failChancePercent - 5)
        end

        if playerObj.isWearingAwkwardGloves and playerObj:isWearingAwkwardGloves() then
            failChancePercent = failChancePercent + 5
        end
    end

    local boredomReduce = 4 + math.floor((sizeDef.xp or 1) * 0.75)
    local unhappyReduce = 2 + math.floor((sizeDef.xp or 1) * 0.40)
    local stressReduce = 0.01 + (sizeDef.xp or 1) * 0.002

    local completionBonus = {
        boredom = 4 + (sizeDef.xp or 1),
        unhappy = 2 + math.floor((sizeDef.xp or 1) * 0.6),
        stress = 0.02 + (sizeDef.xp or 1) * 0.003,
    }

    return {
        duration = duration,
        increment = increment,
        failChancePercent = clamp(failChancePercent, 0, 95),

        requireSurface = true,
        requireLight = true,

        boredomReduce = boredomReduce,
        unhappyReduce = unhappyReduce,
        stressReduce = stressReduce,
        completionBonus = completionBonus,

        -- Convenience:
        progress = progress,
        seed = md.bgpPuzzleSeed,
        sizeDef = sizeDef,
    }
end

function Core.updateName(item)
    if not item then return end
    local ft = item:getFullType()
    if not Puzzles.isPuzzle(ft) then return end

    local md = ensureIdentity(item)
    local progress = PM.getProgress(md)

    local sizeDef = Puzzles.getSizeDefByFullType(ft)
    local pieces = sizeDef and sizeDef.pieces or 0

    local design = Puzzles.getDesignDefByFullType(ft)
    local human = (design and design.human) or "Puzzle"

    local baseName = string.format("%s Puzzle (%s)", human, formatPieces(pieces))

    if progress >= 1 then
        setItemDisplayName(item,baseName .. " - Complete")
    else
        setItemDisplayName(item,string.format("%s - %d%%", baseName, pct(progress)))
    end
end

-- Simulate a work session as piece-placement attempts.
-- Returns { outcome="success"/"failure"/"complete", newProgress=... , successes=..., attempts=... }
local function simulateSession(progress, totalPieces, attempts, baseP, gainP, exponent)
  progress = clamp(progress or 0, 0, 1)
  if progress >= 1 then
    return { outcome="complete", newProgress=1, successes=0, attempts=0 }
  end

  local placed = math.floor(progress * totalPieces + 0.5)

  -- success probability ramps up as progress increases
  local p = clamp(baseP + gainP * (progress ^ exponent), 0.01, 0.98)

  local successes = 0
  for _ = 1, attempts do
    if ZombRand(10000) < math.floor(p * 10000) then
      successes = successes + 1
      placed = placed + 1
      if placed >= totalPieces then
        return { outcome="complete", newProgress=1, successes=successes, attempts=attempts }
      end
    end
  end

  local newProgress = clamp(placed / totalPieces, 0, 1)
  local outcome = (successes > 0) and "success" or "failure"
  return { outcome=outcome, newProgress=newProgress, successes=successes, attempts=attempts }
end

function Core.applyWorkResult(playerObj, item, tuning)
    if not playerObj or not item then
        return { outcome="failure", newProgress=0, wasComplete=false, isComplete=false }
    end
    local ft = item:getFullType()
    if not Puzzles.isPuzzle(ft) then
        return { outcome="failure", newProgress=0, wasComplete=false, isComplete=false }
    end

    tuning = tuning or Core.getWorkTuning(playerObj, item)

    local md = ensureIdentity(item)
    local before = PM.getProgress(md)
    local wasComplete = (before >= 1)

    Core.updateName(item)
    if wasComplete then
        return { outcome="complete", newProgress=1, wasComplete=true, isComplete=true }
    end

    local rng100 = ZombRand(100)
    --local step = PM.playStep(before, rng100, tuning.increment or 0, tuning.failChancePercent or 0)
    local sizeDef = Puzzles.getSizeDefByFullType(ft)
    local pieces = sizeDef and sizeDef.pieces or 1000

    local sim = getSessionSimParams(pieces)

    -- Optional: apply trait/clumsy as a penalty on probability (simple + effective)
    local penalty = (tuning.failChancePercent or 0) / 100
    local baseP = clamp(sim.baseP * (1 - penalty), 0.01, 0.98)
    local gainP = clamp(sim.gainP * (1 - penalty), 0.01, 0.98)

    local step = simulateSession(before, pieces, sim.attempts, baseP, gainP, sim.exponent)
    PM.setProgress(md, step.newProgress)

    Core.updateName(item)
    Core.syncItemModData(item)

    local stats = playerObj:getStats()
    local body = playerObj:getBodyDamage()

    if stats and stats.remove then
        stats:remove(CharacterStat.BOREDOM, tuning.boredomReduce)
        stats:remove(CharacterStat.STRESS, tuning.stressReduce)
        stats:remove(CharacterStat.UNHAPPINESS, tuning.unhappyReduce)
    end

    local after = PM.getProgress(md)
    local isComplete = (after >= 1)

    if (not wasComplete) and isComplete and tuning.completionBonus and stats and body then
        local b = tuning.completionBonus
        if b.boredom then
            stats:remove(CharacterStat.BOREDOM, b.boredom)
        end
        if b.unhappy then
            stats:remove(CharacterStat.UNHAPPINESS, b.unhappy)
        end
        if b.stress then
            stats:remove(CharacterStat.STRESS, b.stress)
        end
        step.outcome = "complete"
    end

    return {
        outcome = step.outcome,
        newProgress = after,
        wasComplete = wasComplete,
        isComplete = isComplete,
        rng = rng100,
        successes = step.successes,
        attempts = step.attempts,
    }
end

return Core