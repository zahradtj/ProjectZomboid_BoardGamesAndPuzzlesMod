-- tests/spec/test_puzzle_progress_manager.lua
-- LuaUnit tests for helpers/Puzzle_ProgressManager.lua

local lu = require("luaunit")

local CANDIDATE_PATHS = {
  "media/lua/client/helpers/Puzzle_ProgressManager.lua",
}

local function loadPMFresh()
  -- Prevent cross-test pollution
  package.loaded["helpers/Puzzle_ProgressManager"] = nil
  package.preload["helpers/Puzzle_ProgressManager"] = nil

  local lastErr
  for _, path in ipairs(CANDIDATE_PATHS) do
    local chunk, err = loadfile(path)
    if chunk then
      local ok, mod = pcall(chunk)
      if ok and type(mod) == "table" then
        return mod, path
      end
      lastErr = ("Loaded %s but it didn't return a table (got %s)"):format(path, type(mod))
    else
      lastErr = err
    end
  end

  error("Could not load Puzzle_ProgressManager.lua from any candidate path. Last error: " .. tostring(lastErr))
end

TestPuzzle_ProgressManager = {}

function TestPuzzle_ProgressManager:setUp()
  self.PM, self._pmPath = loadPMFresh()

  -- deterministic seed
  _G.ZombRand = function(a, b)
    if b ~= nil then return a end
    return 0
  end
end

function TestPuzzle_ProgressManager:testModuleExportsExpectedFunctions()
  lu.assertEquals(type(self.PM.ensureSeed), "function")
  lu.assertEquals(type(self.PM.ensureDesign), "function")
  lu.assertEquals(type(self.PM.getProgress), "function")
  lu.assertEquals(type(self.PM.setProgress), "function")
  lu.assertEquals(type(self.PM.puzzleLabel), "function")
  lu.assertEquals(type(self.PM.menuModel), "function")
  lu.assertEquals(type(self.PM.playStep), "function")
end

function TestPuzzle_ProgressManager:testEnsureSeedSetsWhenMissing()
  local md = {}
  local s = self.PM.ensureSeed(md)
  lu.assertNotNil(s)
  lu.assertEquals(md.bgpPuzzleSeed, s)
end

function TestPuzzle_ProgressManager:testEnsureSeedDoesNotOverwriteExistingSeed()
  local md = { bgpPuzzleSeed = 999 }
  lu.assertEquals(self.PM.ensureSeed(md), 999)
  lu.assertEquals(md.bgpPuzzleSeed, 999)
end

function TestPuzzle_ProgressManager:testEnsureDesignSetsDesignIfMissingAndDesignProvided()
  local md = {}
  lu.assertEquals(self.PM.ensureDesign(md, "Boat"), "Boat")
  lu.assertEquals(md.bgpPuzzleDesign, "Boat")
end

function TestPuzzle_ProgressManager:testEnsureDesignDoesNotOverwriteExistingDesign()
  local md = { bgpPuzzleDesign = "Alpaca" }
  lu.assertEquals(self.PM.ensureDesign(md, "Boat"), "Alpaca")
  lu.assertEquals(md.bgpPuzzleDesign, "Alpaca")
end

function TestPuzzle_ProgressManager:testEnsureDesignDoesNothingWhenDesignIdNil()
  local md = {}
  lu.assertNil(self.PM.ensureDesign(md, nil))
  lu.assertNil(md.bgpPuzzleDesign)
end

function TestPuzzle_ProgressManager:testGetProgressInitializesToZeroWhenMissing()
  local md = {}
  lu.assertEquals(self.PM.getProgress(md), 0)
  lu.assertEquals(md.bgpPuzzleProgress, 0)
end

function TestPuzzle_ProgressManager:testSetProgressClamps()
  local md = {}
  lu.assertEquals(self.PM.setProgress(md, -1), 0)
  lu.assertEquals(self.PM.setProgress(md, 2), 1)
  lu.assertEquals(self.PM.setProgress(md, 0.25), 0.25)
end

function TestPuzzle_ProgressManager:testPuzzleLabelRoundsToNearestPercent()
  lu.assertEquals(self.PM.puzzleLabel(0.0), "Progress: 0%")
  lu.assertEquals(self.PM.puzzleLabel(0.004), "Progress: 0%")
  lu.assertEquals(self.PM.puzzleLabel(0.005), "Progress: 1%")
  lu.assertEquals(self.PM.puzzleLabel(0.995), "Progress: 100%")
end

function TestPuzzle_ProgressManager:testMenuModelClampsAndSetsFlags()
  local m0 = self.PM.menuModel(nil)
  lu.assertEquals(m0.label, "Progress: 0%")
  lu.assertFalse(m0.showComplete)
  lu.assertFalse(m0.showDisassemble)

  local m1 = self.PM.menuModel(0.1)
  lu.assertFalse(m1.showComplete)
  lu.assertTrue(m1.showDisassemble)

  local m2 = self.PM.menuModel(1.0)
  lu.assertTrue(m2.showComplete)
  lu.assertTrue(m2.showDisassemble)
end

function TestPuzzle_ProgressManager:testPlayStepReturnsCompleteWhenAlreadyComplete()
  local r = self.PM.playStep(1.0, 0, 0.1, 50)
  lu.assertEquals(r.outcome, "complete")
  lu.assertEquals(r.newProgress, 1)
end

function TestPuzzle_ProgressManager:testPlayStepSuccessIncrementsProgress()
  local r = self.PM.playStep(0.2, 99, 0.1, 50) -- 99 < 50? no => success
  lu.assertEquals(r.outcome, "success")
  lu.assertAlmostEquals(r.newProgress, 0.3, 1e-9)
end

function TestPuzzle_ProgressManager:testPlayStepFailureDoesNotIncrement()
  local r = self.PM.playStep(0.2, 10, 0.1, 50) -- 10 < 50 => failure
  lu.assertEquals(r.outcome, "failure")
  lu.assertEquals(r.newProgress, 0.2)
end

function TestPuzzle_ProgressManager:testPlayStepClampsToOneOnSuccess()
  local r = self.PM.playStep(0.95, 99, 0.2, 0)
  lu.assertEquals(r.outcome, "success")
  lu.assertEquals(r.newProgress, 1)
end

function TestPuzzle_ProgressManager:testPlayStepClampsInputProgress()
  local r = self.PM.playStep(-5, 99, 0.1, 0)
  lu.assertEquals(r.outcome, "success")
  lu.assertEquals(r.newProgress, 0.1)
end

return TestPuzzle_ProgressManager