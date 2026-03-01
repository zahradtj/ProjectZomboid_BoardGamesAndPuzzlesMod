-- tests/spec/test_puzzle_progress_manager.lua
-- LuaUnit tests for helpers/Puzzle_ProgressManager.lua

local lu = require("luaunit")

local function reloadPM()
    package.loaded["helpers/Puzzle_ProgressManager"] = nil
    return require("helpers/Puzzle_ProgressManager")
end

TestPuzzle_ProgressManager = {}

function TestPuzzle_ProgressManager:setUp()
    -- Stub ZombRand deterministically for ensureSeed tests
    self._origZombRand = _G.ZombRand
    _G.ZombRand = function(lo, hi)
        -- PZ ZombRand(min,max) -> int in [min, max-1]
        -- return a fixed value inside range for predictability.
        if lo and hi then return lo + 41 end
        return 42
    end

    self.PM = reloadPM()
end

function TestPuzzle_ProgressManager:tearDown()
    _G.ZombRand = self._origZombRand
end

-- ---- ensureSeed ------------------------------------------------------

function TestPuzzle_ProgressManager:testEnsureSeedSetsSeedIfMissing()
    local md = {}
    local seed = self.PM.ensureSeed(md)
    lu.assertNotNil(seed)
    lu.assertEquals(md.bgpPuzzleSeed, seed)
end

function TestPuzzle_ProgressManager:testEnsureSeedDoesNotOverwriteExistingSeed()
    local md = { bgpPuzzleSeed = 12345 }
    local seed = self.PM.ensureSeed(md)
    lu.assertEquals(seed, 12345)
    lu.assertEquals(md.bgpPuzzleSeed, 12345)
end

-- ---- ensureDesign ----------------------------------------------------

function TestPuzzle_ProgressManager:testEnsureDesignSetsDesignIfMissingAndDesignProvided()
    local md = {}
    local design = self.PM.ensureDesign(md, "Alpaca")
    lu.assertEquals(design, "Alpaca")
    lu.assertEquals(md.bgpPuzzleDesign, "Alpaca")
end

function TestPuzzle_ProgressManager:testEnsureDesignDoesNotOverwriteExistingDesign()
    local md = { bgpPuzzleDesign = "Boat" }
    local design = self.PM.ensureDesign(md, "Alpaca")
    lu.assertEquals(design, "Boat")
    lu.assertEquals(md.bgpPuzzleDesign, "Boat")
end

function TestPuzzle_ProgressManager:testEnsureDesignDoesNothingWhenDesignIdNil()
    local md = {}
    local design = self.PM.ensureDesign(md, nil)
    lu.assertNil(design)
    lu.assertNil(md.bgpPuzzleDesign)
end

-- ---- getProgress / setProgress --------------------------------------

function TestPuzzle_ProgressManager:testGetProgressInitializesToZeroWhenMissing()
    local md = {}
    lu.assertEquals(self.PM.getProgress(md), 0)
    lu.assertEquals(md.bgpPuzzleProgress, 0)
end

function TestPuzzle_ProgressManager:testGetProgressReturnsExistingValue()
    local md = { bgpPuzzleProgress = 0.3 }
    lu.assertEquals(self.PM.getProgress(md), 0.3)
end

function TestPuzzle_ProgressManager:testSetProgressClampsLow()
    local md = {}
    lu.assertEquals(self.PM.setProgress(md, -5), 0)
    lu.assertEquals(md.bgpPuzzleProgress, 0)
end

function TestPuzzle_ProgressManager:testSetProgressClampsHigh()
    local md = {}
    lu.assertEquals(self.PM.setProgress(md, 5), 1)
    lu.assertEquals(md.bgpPuzzleProgress, 1)
end

function TestPuzzle_ProgressManager:testSetProgressAcceptsInRange()
    local md = {}
    lu.assertEquals(self.PM.setProgress(md, 0.42), 0.42)
    lu.assertEquals(md.bgpPuzzleProgress, 0.42)
end

-- ---- puzzleLabel / menuModel ----------------------------------------

function TestPuzzle_ProgressManager:testPuzzleLabelRoundsToNearestPercent()
    lu.assertEquals(self.PM.puzzleLabel(0.0), "Progress: 0%")
    lu.assertEquals(self.PM.puzzleLabel(0.004), "Progress: 0%")   -- 0.4% -> 0
    lu.assertEquals(self.PM.puzzleLabel(0.005), "Progress: 1%")   -- 0.5% -> 1 (round half up)
    lu.assertEquals(self.PM.puzzleLabel(0.994), "Progress: 99%")
    lu.assertEquals(self.PM.puzzleLabel(0.995), "Progress: 100%")
end

function TestPuzzle_ProgressManager:testMenuModelClampsAndSetsFlags()
    local m0 = self.PM.menuModel(-1)
    lu.assertEquals(m0.label, "Progress: 0%")
    lu.assertFalse(m0.showComplete)
    lu.assertFalse(m0.showDisassemble)

    local mMid = self.PM.menuModel(0.2)
    lu.assertEquals(mMid.label, "Progress: 20%")
    lu.assertFalse(mMid.showComplete)
    lu.assertTrue(mMid.showDisassemble)

    local m1 = self.PM.menuModel(1.5)
    lu.assertEquals(m1.label, "Progress: 100%")
    lu.assertTrue(m1.showComplete)
    lu.assertTrue(m1.showDisassemble) -- >0 is true
end

-- ---- playStep --------------------------------------------------------

function TestPuzzle_ProgressManager:testPlayStepReturnsCompleteWhenAlreadyComplete()
    local r = self.PM.playStep(1.0, 0, 0.1, 50)
    lu.assertEquals(r.outcome, "complete")
    lu.assertEquals(r.newProgress, 1)
end

function TestPuzzle_ProgressManager:testPlayStepSuccessIncrementsProgress()
    -- success if rng100 >= failChancePercent
    local r = self.PM.playStep(0.3, 50, 0.1, 10) -- 50 < 10? no => success
    lu.assertEquals(r.outcome, "success")
    lu.assertEquals(r.newProgress, 0.4)
end

function TestPuzzle_ProgressManager:testPlayStepFailureDoesNotIncrement()
    local r = self.PM.playStep(0.3, 5, 0.2, 10) -- 5 < 10 => failure
    lu.assertEquals(r.outcome, "failure")
    lu.assertEquals(r.newProgress, 0.3)
end

function TestPuzzle_ProgressManager:testPlayStepClampsToOneOnSuccess()
    local r = self.PM.playStep(0.95, 99, 0.2, 0) -- success, should clamp to 1
    lu.assertEquals(r.outcome, "success")
    lu.assertEquals(r.newProgress, 1)
end

function TestPuzzle_ProgressManager:testPlayStepClampsInputProgress()
    -- progress < 0 should clamp to 0 before use
    local r = self.PM.playStep(-1, 99, 0.2, 0)
    lu.assertEquals(r.outcome, "success")
    lu.assertEquals(r.newProgress, 0.2)
end

return TestPuzzle_ProgressManager