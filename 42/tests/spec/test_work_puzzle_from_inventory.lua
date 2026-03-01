-- tests/spec/test_work_puzzle_from_inventory.lua
-- LuaUnit tests for ISWorkPuzzleFromInventory.lua

local lu = require("luaunit")

-- -------------------------------------------------------
-- Ensure cached real modules don't override our stubs
-- -------------------------------------------------------
package.loaded["TimedActions/ISBaseTimedAction"] = nil
package.loaded["helpers/Puzzle_Thoughts"] = nil
package.loaded["BGP_PuzzlesCore"] = nil
package.loaded["BGP_Requirements"] = nil

-- -------------------------------------------------------
-- Stubs via package.preload (must match require strings)
-- -------------------------------------------------------

package.preload["TimedActions/ISBaseTimedAction"] = function()
  local Base = {}

  function Base:derive(name)
    local cls = {}
    cls.__index = cls
    cls.__name = name
    setmetatable(cls, { __index = self })
    return cls
  end

  function Base.new(self, character)
    return setmetatable({ character = character, currentTime = 0, maxTime = 0 }, self)
  end

  function Base.perform(self) self._performed = true end
  function Base.stop(self) self._stopped = true end
  function Base.setActionAnim(self, anim) self._anim = anim end

  -- Many PZ builds have this; your action prefers it.
  function Base.forceStop(self)
    self._forcedStop = true
    self.currentTime = self.maxTime or 0
    self.maxTime = 0
  end

  _G.ISBaseTimedAction = Base
  return true
end

package.preload["helpers/Puzzle_Thoughts"] = function()
  local M = { calls = {} }

  function M.pickWorkThought(successes)
    table.insert(M.calls, { which = "pick", successes = successes })
    return "workthought-" .. tostring(successes)
  end

  function M.showComplete(character)
    table.insert(M.calls, { which = "complete", character = character })
  end

  function M.show(character, fullType, outcome)
    table.insert(M.calls, { which = "show", character = character, fullType = fullType, outcome = outcome })
  end

  function M.reset() M.calls = {} end
  return M
end

package.preload["BGP_PuzzlesCore"] = function()
  local M = { calls = {}, nextResults = nil }

  function M.applyWorkResult(character, item, tuning)
    table.insert(M.calls, { character = character, item = item, tuning = tuning })
    if M.nextResults and #M.nextResults > 0 then
      return table.remove(M.nextResults, 1)
    end
    return { outcome = "success", isComplete = false, successes = 3 }
  end

  function M.reset()
    M.calls = {}
    M.nextResults = nil
  end

  return M
end

package.preload["BGP_Requirements"] = function()
  local M = { _surface = true, _light = true, calls = {} }

  function M.hasNearbySurface(player, radius)
    table.insert(M.calls, { fn = "surface", player = player, radius = radius })
    return M._surface
  end

  function M.hasEnoughLight(player, level)
    table.insert(M.calls, { fn = "light", player = player, level = level })
    return M._light
  end

  function M.reset()
    M._surface = true
    M._light = true
    M.calls = {}
  end

  return M
end

-- -------------------------------------------------------
-- Global stubs used by the action
-- -------------------------------------------------------

_G.__NOW_MS = 1000
_G.getTimestampMs = function() return _G.__NOW_MS end

-- Default deterministic RNG. Tests can override per-test.
_G.ZombRand = function(a, b)
  if b ~= nil then return a end
  return 99
end

-- -------------------------------------------------------
-- Require module under test
-- -------------------------------------------------------
local Action = require("TimedActions/ISWorkPuzzleFromInventory")
local Thoughts = require("helpers/Puzzle_Thoughts")
local Core = require("BGP_PuzzlesCore")
local Req = require("BGP_Requirements")

-- -------------------------------------------------------
-- Helpers / fakes
-- -------------------------------------------------------

local function makeItem(fullType)
  return { getFullType = function() return fullType end }
end

local function makeCharacter()
  return {
    _vars = {},
    _said = {},
    SetVariable = function(self, k, v) self._vars[k] = v end,
    Say = function(self, s) table.insert(self._said, s) end,
  }
end

-- -------------------------------------------------------
-- Tests
-- -------------------------------------------------------

TestWorkPuzzleFromInventory = {}

function TestWorkPuzzleFromInventory:setUp()
  if _G.reset_test_globals then _G.reset_test_globals() end
  Thoughts.reset()
  Core.reset()
  Req.reset()

  _G.__NOW_MS = 1000

  _G.ZombRand = function(a, b)
    if b ~= nil then return a end
    return 99
  end
end

-- ---- isValid ---------------------------------------------------------

function TestWorkPuzzleFromInventory:testIsValidFalseWhenItemMissing()
  local ch = makeCharacter()
  local a = Action:new(ch, nil)
  lu.assertFalse(a:isValid())
end

function TestWorkPuzzleFromInventory:testIsValidHonorsSurfaceAndLightWhenRequired()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item)
  a.requireSurface = true
  a.requireLight = true

  Req._surface = false
  Req._light = true
  lu.assertFalse(a:isValid())

  Req._surface = true
  Req._light = false
  lu.assertFalse(a:isValid())

  Req._surface = true
  Req._light = true
  lu.assertTrue(a:isValid())
end

function TestWorkPuzzleFromInventory:testIsValidSkipsReqChecksWhenFlagsFalse()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item)
  a.requireSurface = false
  a.requireLight = false

  Req._surface = false
  Req._light = false
  lu.assertTrue(a:isValid())
end

-- ---- start -----------------------------------------------------------

function TestWorkPuzzleFromInventory:testStartSetsAnimLootPositionAndTimers()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item, 550, { workEveryMs = 2500 })
  _G.__NOW_MS = 1000

  -- ZombRand(2000,6001) default returns 2000
  a:start()

  lu.assertEquals(a._anim, "Loot")
  lu.assertEquals(ch._vars["LootPosition"], "Mid")

  lu.assertEquals(a.workEveryMs, 2500)
  lu.assertEquals(a.nextWorkMs, 3500)
  lu.assertEquals(a.nextThoughtMs, 3000)
  lu.assertFalse(a.done)
  lu.assertNil(a.lastRes)
end

-- ---- update: work ticks ---------------------------------------------

function TestWorkPuzzleFromInventory:testUpdateDoesNothingIfDoneEndsAction()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item, 550, {})
  a.done = true
  a.maxTime = 550

  a:update()

  lu.assertTrue(a._forcedStop)      -- uses forceStop path
  lu.assertEquals(a.maxTime, 0)
end

function TestWorkPuzzleFromInventory:testUpdateAppliesWorkWhenTimeReachedAndReschedules()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item, 550, { workEveryMs = 2500 })
  a:start()

  _G.__NOW_MS = a.nextWorkMs
  Core.nextResults = { { outcome = "success", isComplete = false, successes = 7 } }

  a:update()

  lu.assertEquals(#Core.calls, 1)
  lu.assertEquals(a.lastRes.successes, 7)
  lu.assertEquals(a.nextWorkMs, _G.__NOW_MS + 2500)
end

function TestWorkPuzzleFromInventory:testUpdateCompletionMarksDoneShowsCompleteAndEnds()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item, 550, { workEveryMs = 2500 })
  a:start()

  -- Force work tick due now
  a.nextWorkMs = _G.__NOW_MS
  Core.nextResults = { { outcome = "complete", isComplete = true, successes = 25 } }

  a:update()

  lu.assertTrue(a.done)
  lu.assertTrue(a._forcedStop)
  lu.assertEquals(a.maxTime, 0)

  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].which, "complete")
end

-- ---- update: thoughts ------------------------------------------------

function TestWorkPuzzleFromInventory:testUpdateThoughtUsesPickWorkThoughtWhenSuccessesPresent()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item, 550, {})
  a:start()

  a.lastRes = { successes = 9 }
  _G.__NOW_MS = a.nextThoughtMs

  a:update()

  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].which, "pick")
  lu.assertEquals(Thoughts.calls[1].successes, 9)
  lu.assertEquals(#ch._said, 1)
  lu.assertEquals(ch._said[1], "workthought-9")
end

function TestWorkPuzzleFromInventory:testUpdateFallbackThoughtChanceCallsPickWorkThought()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item, 550, {})
  a:start()

  -- Force thought tick due now and no successes
  a.lastRes = nil
  _G.__NOW_MS = a.nextThoughtMs

  -- Make chance hit: ZombRand(100) -> 0 (<35), and reschedule: ZombRand(4000,10001)->4000
  local oldZR = _G.ZombRand
  _G.ZombRand = function(x, y)
    if y == nil then return 0 end
    return x
  end

  a:update()
  _G.ZombRand = oldZR

  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].which, "pick")
  lu.assertEquals(Thoughts.calls[1].successes, 0)
end

-- ---- perform ---------------------------------------------------------

function TestWorkPuzzleFromInventory:testPerformShowsCompleteOutcomeWhenComplete()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item, 550, {})
  a.lastRes = { outcome = "complete", isComplete = true, successes = 10 }

  a:perform()

  lu.assertTrue(a._performed)
  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].which, "show")
  lu.assertEquals(Thoughts.calls[1].outcome, "complete")
  lu.assertEquals(Thoughts.calls[1].fullType, "BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
end

function TestWorkPuzzleFromInventory:testPerformSaysFinalWorkThoughtWhenNotCompleteAndHasSuccesses()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item, 550, {})
  a.lastRes = { outcome = "success", isComplete = false, successes = 4 }

  a:perform()

  lu.assertTrue(a._performed)
  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].which, "pick")
  lu.assertEquals(#ch._said, 1)
  lu.assertEquals(ch._said[1], "workthought-4")
end

function TestWorkPuzzleFromInventory:testPerformDoesNothingWhenNoLastRes()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item, 550, {})

  a:perform()

  lu.assertTrue(a._performed)
  lu.assertEquals(#Thoughts.calls, 0)
  lu.assertEquals(#ch._said, 0)
end

-- ---- new defaults ----------------------------------------------------

function TestWorkPuzzleFromInventory:testNewDefaults()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local a = Action:new(ch, item)

  lu.assertEquals(a.character, ch)
  lu.assertEquals(a.item, item)
  lu.assertTrue(a.stopOnWalk)
  lu.assertTrue(a.stopOnRun)
  lu.assertTrue(a.useProgressBar)
  lu.assertEquals(a.maxTime, 550)
  lu.assertEquals(a.boredomReduce, 20)
  lu.assertEquals(a.unhappyReduce, 10)
  lu.assertEquals(a.stressReduce, 0.05)
  lu.assertEquals(a.workEveryMs, 2500)
end

return TestWorkPuzzleFromInventory