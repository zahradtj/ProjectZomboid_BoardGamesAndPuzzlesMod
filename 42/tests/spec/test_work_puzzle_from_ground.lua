-- tests/spec/test_work_puzzle_from_ground.lua
-- LuaUnit tests for ISWorkPuzzleFromGround.lua
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

  function M.show(character, successes)
    table.insert(M.calls, { which = "show", character = character, successes = successes })
  end

  function M.showComplete(character)
    table.insert(M.calls, { which = "complete", character = character })
  end

  function M.reset() M.calls = {} end
  return M
end

package.preload["BGP_PuzzlesCore"] = function()
  local M = { calls = {}, nextResults = nil }

  -- test can set M.nextResults = { {isComplete=false,successes=..}, ... }
  function M.applyWorkResult(character, item, tuning)
    table.insert(M.calls, { character = character, item = item, tuning = tuning })
    if M.nextResults and #M.nextResults > 0 then
      local r = table.remove(M.nextResults, 1)
      return r
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
  local M = {
    _near = true,
    _surface = true,
    _light = true,
    calls = {},
  }

  function M.isCharacterNearWorldItem(player, worldItemObj)
    table.insert(M.calls, { fn = "near", player = player, worldItemObj = worldItemObj })
    return M._near
  end

  function M.hasNearbySurface(player, radius)
    table.insert(M.calls, { fn = "surface", player = player, radius = radius })
    return M._surface
  end

  function M.hasEnoughLight(player, lvl)
    table.insert(M.calls, { fn = "light", player = player, lvl = lvl })
    return M._light
  end

  function M.reset()
    M._near = true
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
local Action = require("TimedActions/ISWorkPuzzleFromGround")
local Thoughts = require("helpers/Puzzle_Thoughts")
local Core = require("BGP_PuzzlesCore")
local Req = require("BGP_Requirements")

-- -------------------------------------------------------
-- Helpers / fakes
-- -------------------------------------------------------

local function makeSquare(x, y, z)
  return {
    getX = function() return x end,
    getY = function() return y end,
    getZ = function() return z or 0 end,
  }
end

local function makeItem(fullType)
  return { getFullType = function() return fullType end }
end

local function makeCharacter()
  return {
    _vars = {},
    _faced = {},
    _said = {},
    SetVariable = function(self, k, v) self._vars[k] = v end,
    faceLocation = function(self, x, y) table.insert(self._faced, { x = x, y = y }) end,
    Say = function(self, s) table.insert(self._said, s) end,
  }
end

local function makeWorldItemObj(invItem, square)
  return {
    getItem = function() return invItem end,
    getSquare = function() return square end,
  }
end

-- -------------------------------------------------------
-- Tests
-- -------------------------------------------------------

TestWorkPuzzleFromGround = {}

function TestWorkPuzzleFromGround:setUp()
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

function TestWorkPuzzleFromGround:testIsValidWorldItemChecksAndNearGate()
  local ch = makeCharacter()
  local invItem = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local sq = makeSquare(10, 20, 0)

  -- 1) worldItemObj missing
  local a0 = Action:new(ch, nil, invItem)
  lu.assertFalse(a0:isValid())

  -- 2) item mismatch
  local wrongItem = makeItem("Base.Hammer")
  local woMismatch = makeWorldItemObj(wrongItem, sq)
  local a1 = Action:new(ch, woMismatch, invItem)
  lu.assertFalse(a1:isValid())

  -- 3) square missing
  local woNoSq = makeWorldItemObj(invItem, nil)
  local a2 = Action:new(ch, woNoSq, invItem)
  lu.assertFalse(a2:isValid())

  -- 4) not near
  Req._near = false
  local woOk = makeWorldItemObj(invItem, sq)
  local a3 = Action:new(ch, woOk, invItem)
  lu.assertFalse(a3:isValid())

  -- 5) all ok
  Req._near = true
  lu.assertTrue(a3:isValid())
end

function TestWorkPuzzleFromGround:testIsValidSurfaceAndLightRequirements()
  local ch = makeCharacter()
  local invItem = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local woOk = makeWorldItemObj(invItem, makeSquare(1, 1, 0))
  local a = Action:new(ch, woOk, invItem)

  a.requireSurface = true
  Req._surface = false
  lu.assertFalse(a:isValid())
  Req._surface = true
  lu.assertTrue(a:isValid())

  a.requireLight = true
  Req._light = false
  lu.assertFalse(a:isValid())
  Req._light = true
  lu.assertTrue(a:isValid())
end

function TestWorkPuzzleFromGround:testStartFacesSquareSetsAnimAndSchedulesWorkAndThought()
  local ch = makeCharacter()
  local invItem = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local sq = makeSquare(10, 20, 0)
  local woOk = makeWorldItemObj(invItem, sq)
  local a = Action:new(ch, woOk, invItem, 400, { workEveryMs = 2500 })

  _G.__NOW_MS = 1000
  -- ZombRand(2000,6001) default returns 2000
  a:start()

  lu.assertEquals(#ch._faced, 1)
  lu.assertEquals(ch._faced[1].x, 10)
  lu.assertEquals(ch._faced[1].y, 20)

  lu.assertEquals(a._anim, "Loot")
  lu.assertEquals(ch._vars["LootPosition"], "Mid")

  lu.assertEquals(a.workEveryMs, 2500)
  lu.assertEquals(a.nextWorkMs, 3500)
  lu.assertEquals(a.nextThoughtMs, 3000)

  lu.assertFalse(a.done)
  lu.assertNil(a.lastRes)
end

function TestWorkPuzzleFromGround:testUpdateAppliesWorkTickAndReschedules()
  local ch = makeCharacter()
  local invItem = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local sq = makeSquare(10, 20, 0)
  local woOk = makeWorldItemObj(invItem, sq)
  local a = Action:new(ch, woOk, invItem, 400, { workEveryMs = 2500 })
  a:start()

  -- time reaches nextWorkMs
  _G.__NOW_MS = a.nextWorkMs
  Core.nextResults = { { isComplete = false, successes = 7 } }

  a:update()

  lu.assertEquals(#Core.calls, 1)
  lu.assertEquals(a.lastRes.successes, 7)
  lu.assertEquals(a.nextWorkMs, _G.__NOW_MS + 2500)
end

function TestWorkPuzzleFromGround:testUpdateCompletionEndsActionAndShowsCompleteThought()
  local ch = makeCharacter()
  local invItem = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local sq = makeSquare(10, 20, 0)
  local woOk = makeWorldItemObj(invItem, sq)
  local a = Action:new(ch, woOk, invItem, 400, { workEveryMs = 2500 })
  a:start()

  -- Force "work tick due now"
  a.nextWorkMs = _G.__NOW_MS

  Core.nextResults = { { isComplete = true, successes = 25 } }

  a:update()

  lu.assertTrue(a.done)
  lu.assertEquals(a.maxTime, 0)
  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].which, "complete")
end

function TestWorkPuzzleFromGround:testUpdateThoughtTickUsesPickWorkThoughtWhenSuccessesPresent()
  local ch = makeCharacter()
  local invItem = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local woOk = makeWorldItemObj(invItem, makeSquare(1, 1, 0))
  local a = Action:new(ch, woOk, invItem, 400, { workEveryMs = 2500 })
  a:start()

  a.lastRes = { successes = 9 }
  _G.__NOW_MS = a.nextThoughtMs

  a:update()

  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].which, "pick")
  lu.assertEquals(#ch._said, 1)
  lu.assertEquals(ch._said[1], "workthought-9")
end

function TestWorkPuzzleFromGround:testUpdateLegacyShowChancePath()
  local ch = makeCharacter()
  local invItem = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local woOk = makeWorldItemObj(invItem, makeSquare(1, 1, 0))
  local a = Action:new(ch, woOk, invItem, 400, { workEveryMs = 2500 })
  a:start()

  -- Make update deterministic:
  -- ZombRand(100) => 0 (hit <35), ZombRand(4000,10001) => 4000
  local oldZR = _G.ZombRand
  _G.ZombRand = function(x, y)
    if y == nil then return 0 end
    return x
  end

  -- Ensure thought triggers and we have no lastRes.successes
  a.lastRes = nil
  _G.__NOW_MS = a.nextThoughtMs
  a:update()

  _G.ZombRand = oldZR

  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].which, "show")
  lu.assertEquals(Thoughts.calls[1].successes, 0)
end

function TestWorkPuzzleFromGround:testPerformDoesNotApplyWorkAgainAndMaySayFinalThought()
  local ch = makeCharacter()
  local invItem = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local woOk = makeWorldItemObj(invItem, makeSquare(1, 1, 0))
  local a = Action:new(ch, woOk, invItem, 400, {})
  a.lastRes = { isComplete = false, successes = 4 }

  a:perform()

  lu.assertEquals(#Core.calls, 0)
  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].which, "pick")
  lu.assertEquals(#ch._said, 1)
  lu.assertEquals(ch._said[1], "workthought-4")
  lu.assertTrue(a._performed)
end

function TestWorkPuzzleFromGround:testNewDefaults()
  local ch = makeCharacter()
  local invItem = makeItem("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca")
  local woOk = makeWorldItemObj(invItem, makeSquare(1, 1, 0))
  local a = Action:new(ch, woOk, invItem)

  lu.assertEquals(a.character, ch)
  lu.assertEquals(a.worldItemObj, woOk)
  lu.assertEquals(a.item, invItem)
  lu.assertTrue(a.stopOnWalk)
  lu.assertTrue(a.stopOnRun)
  lu.assertTrue(a.useProgressBar)
  lu.assertEquals(a.maxTime, 400)
  lu.assertEquals(a.boredomReduce, 20)
  lu.assertEquals(a.unhappyReduce, 10)
  lu.assertEquals(a.stressReduce, 0.05)
  lu.assertEquals(a.workEveryMs, 2500)
end

return TestWorkPuzzleFromGround