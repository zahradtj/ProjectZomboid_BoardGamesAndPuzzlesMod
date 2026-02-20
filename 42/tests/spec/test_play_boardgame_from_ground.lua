-- tests/spec/test_play_boardgame_from_ground.lua
-- LuaUnit tests for ISPlayBoardGameFromGround.lua
local lu = require("luaunit")

-- -------------------------------------------------------
-- Ensure cached real modules don't override our stubs
-- -------------------------------------------------------
package.loaded["TimedActions/ISBaseTimedAction"] = nil
package.loaded["helpers/BoardGame_Thoughts"] = nil
package.loaded["BoardGamesAndPuzzlesMod_Operation"] = nil

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
    return setmetatable({ character = character }, self)
  end

  function Base.perform(self) self._performed = true end
  function Base.stop(self) self._stopped = true end
  function Base.setActionAnim(self, anim) self._anim = anim end

  _G.ISBaseTimedAction = Base
  return true
end

package.preload["helpers/BoardGame_Thoughts"] = function()
  local M = { calls = {} }
  function M.show(character, fullType, outcome)
    table.insert(M.calls, { character = character, fullType = fullType, outcome = outcome })
  end
  function M.reset() M.calls = {} end
  return M
end

package.preload["BoardGamesAndPuzzlesMod_Operation"] = function()
  local M = { calls = {}, _isOperation = false }
  function M.isOperationItem(_) return M._isOperation end
  function M.doPlayOperation(character, item)
    table.insert(M.calls, { character = character, item = item })
  end
  function M.reset()
    M.calls = {}
    M._isOperation = false
  end
  return M
end

-- -------------------------------------------------------
-- Global stubs used by the action
-- -------------------------------------------------------

_G.hasNearbySurface = function(_, _) return true end
_G.hasEnoughLight   = function(_, _) return true end

_G.__NOW_MS = 1000
_G.getTimestampMs = function() return NOW_MS end

-- Default deterministic RNG. Tests can override per-test.
ZombRand = function(a, b)
  if b ~= nil then return a end
  return 99
end
_G.ZombRand = ZombRand

_G.CharacterStat = {
  BOREDOM = "BOREDOM",
  STRESS = "STRESS",
  UNHAPPINESS = "UNHAPPINESS",
}

-- -------------------------------------------------------
-- Require module under test
-- -------------------------------------------------------
local Action = require("TimedActions/ISPlayBoardGameFromGround")
local Thoughts = require("helpers/BoardGame_Thoughts")
local Operation = require("BoardGamesAndPuzzlesMod_Operation")

-- -------------------------------------------------------
-- Helpers / fakes
-- -------------------------------------------------------
local function makeItem(fullType)
  return { getFullType = function() return fullType end }
end

local function makeStats()
  return {
    removed = {},
    values = {
      [CharacterStat.BOREDOM] = 50,
      [CharacterStat.STRESS] = 0.5,
      [CharacterStat.UNHAPPINESS] = 25,
    },
    get = function(self, k) return self.values[k] end,
    remove = function(self, k, amt) table.insert(self.removed, { k = k, amt = amt }) end,
  }
end

local function makeCharacter(stats)
  stats = stats or makeStats()
  return {
    _vars = {},
    _faced = {},
    SetVariable = function(self, k, v) self._vars[k] = v end,
    faceLocation = function(self, x, y) table.insert(self._faced, { x = x, y = y }) end,
    getStats = function() return stats end,
  }, stats
end

local function makeSquare(x, y)
  return {
    getX = function() return x end,
    getY = function() return y end,
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
TestPlayFromGround = {}

function TestPlayFromGround:setUp()
  _G.reset_test_globals()
  Thoughts.reset()
  Operation.reset()
  _G.__NOW_MS = 1000

  ZombRand = function(a, b)
    if b ~= nil then return a end
    return 99
  end
  _G.ZombRand = ZombRand

  _G.hasNearbySurface = function(_, _) return true end
  _G.hasEnoughLight   = function(_, _) return true end
end



function TestPlayFromGround:testIsValidWorldItemChecks()
  local ch = makeCharacter()
  local invItem = makeItem("Base.Chess")
  local sq = makeSquare(10, 20)

  -- 1) worldItemObj missing
  local a0 = Action:new(ch, nil, invItem)
  lu.assertFalse(a0:isValid())

  -- 2) worldItemObj item mismatch
  local wrongItem = makeItem("Base.Hammer")
  local woMismatch = makeWorldItemObj(wrongItem, sq)
  local a1 = Action:new(ch, woMismatch, invItem)
  lu.assertFalse(a1:isValid())

  -- 3) square missing
  local woNoSq = makeWorldItemObj(invItem, nil)
  local a2 = Action:new(ch, woNoSq, invItem)
  lu.assertFalse(a2:isValid())

  -- 4) all ok
  local woOk = makeWorldItemObj(invItem, sq)
  local a3 = Action:new(ch, woOk, invItem)
  lu.assertTrue(a3:isValid())
end

function TestPlayFromGround:testIsValidSurfaceAndLightRequirements()
  local ch = makeCharacter()
  local invItem = makeItem("Base.Chess")
  local woOk = makeWorldItemObj(invItem, makeSquare(1, 1))
  local a = Action:new(ch, woOk, invItem)

  a.requireSurface = true
  _G.hasNearbySurface = function(_, _) return false end
  lu.assertFalse(a:isValid())
  _G.hasNearbySurface = function(_, _) return true end
  lu.assertTrue(a:isValid())

  a.requireLight = true
  _G.hasEnoughLight = function(_, _) return false end
  lu.assertFalse(a:isValid())
  _G.hasEnoughLight = function(_, _) return true end
  lu.assertTrue(a:isValid())
end

function TestPlayFromGround:testStartFacesSquareSetsAnimAndSchedulesNextThought()
  local ch = makeCharacter()
  local invItem = makeItem("Base.Chess")
  local sq = makeSquare(10, 20)
  local woOk = makeWorldItemObj(invItem, sq)
  local a = Action:new(ch, woOk, invItem)

  _G.__NOW_MS = 1000
  -- ZombRand(2000,6001) default returns 2000
  a:start()

  lu.assertEquals(#ch._faced, 1)
  lu.assertEquals(ch._faced[1].x, 10)
  lu.assertEquals(ch._faced[1].y, 20)

  lu.assertEquals(a._anim, "Loot")
  lu.assertEquals(ch._vars["LootPosition"], "Mid")
  lu.assertEquals(a.nextThoughtMs, 3000)
end

function TestPlayFromGround:testUpdateKeepsFacingAndDoesNothingBeforeNextThought()
  local ch = makeCharacter()
  local invItem = makeItem("Base.Chess")
  local sq = makeSquare(10, 20)
  local woOk = makeWorldItemObj(invItem, sq)
  local a = Action:new(ch, woOk, invItem)

  a.nextThoughtMs = 5000
  _G.__NOW_MS = 4000

  a:update()

  -- still faces each update
  lu.assertEquals(#ch._faced, 1)
  lu.assertEquals(#Thoughts.calls, 0)
  lu.assertEquals(a.nextThoughtMs, 5000)
end

function TestPlayFromGround:testUpdateShowsNeutralAndReschedulesDeterministic()
  local ch = makeCharacter()
  local invItem = makeItem("Base.Chess")
  local sq = makeSquare(10, 20)
  local woOk = makeWorldItemObj(invItem, sq)
  local a = Action:new(ch, woOk, invItem)
  a.item = invItem -- update uses self.item for fullType

  _G.__NOW_MS = 5000
  a.nextThoughtMs = 5000

  -- Make update deterministic:
  -- ZombRand(100) => 0 (show neutral), ZombRand(4000,10001) => 4000
  local oldZR = _G.ZombRand
  _G.ZombRand = function(x, y)
    if y == nil then return 0 end
    return x
  end

  a:update()

  _G.ZombRand = oldZR

  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].outcome, "neutral")
  lu.assertEquals(Thoughts.calls[1].fullType, "Base.Chess")
  lu.assertEquals(a.nextThoughtMs, 9000)
end

function TestPlayFromGround:testPerformReducesStats()
  local ch, stats = makeCharacter()
  local invItem = makeItem("Base.Chess")
  local woOk = makeWorldItemObj(invItem, makeSquare(1, 1))
  local a = Action:new(ch, woOk, invItem, 400, 21, 11, 0.06)
  a.item = invItem

  Operation._isOperation = false
  _G.ZombRand = function(_) return 0 end -- success

  a:perform()

  lu.assertEquals(#stats.removed, 3)
  lu.assertEquals(stats.removed[1].k, CharacterStat.BOREDOM)
  lu.assertEquals(stats.removed[1].amt, 21)
  lu.assertEquals(stats.removed[2].k, CharacterStat.STRESS)
  lu.assertEquals(stats.removed[2].amt, 0.06)
  lu.assertEquals(stats.removed[3].k, CharacterStat.UNHAPPINESS)
  lu.assertEquals(stats.removed[3].amt, 11)

  lu.assertTrue(a._performed)
end

function TestPlayFromGround:testPerformOperationCallsDoPlayOperation()
  local ch = makeCharacter()
  local invItem = makeItem("BoardGamesAndPuzzlesMod.Operation")
  local woOk = makeWorldItemObj(invItem, makeSquare(1, 1))
  local a = Action:new(ch, woOk, invItem)
  a.item = invItem

  Operation._isOperation = true

  a:perform()

  lu.assertEquals(#Operation.calls, 1)
  lu.assertEquals(Operation.calls[1].character, ch)
  lu.assertEquals(Operation.calls[1].item, invItem)
  lu.assertEquals(#Thoughts.calls, 0)
end

function TestPlayFromGround:testPerformNonOperationSuccessAndFailure()
  local ch = makeCharacter()
  local invItem = makeItem("Base.Chess")
  local woOk = makeWorldItemObj(invItem, makeSquare(1, 1))
  local a = Action:new(ch, woOk, invItem)
  a.item = invItem
  Operation._isOperation = false

  -- Success
  Thoughts.reset()
  _G.ZombRand = function(_) return 0 end -- < 50
  a:perform()
  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].outcome, "success")

  -- Failure
  Thoughts.reset()
  _G.ZombRand = function(_) return 99 end -- >= 50
  a:perform()
  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].outcome, "failure")
end

function TestPlayFromGround:testNewDefaults()
  local ch = makeCharacter()
  local invItem = makeItem("Base.Chess")
  local woOk = makeWorldItemObj(invItem, makeSquare(1, 1))
  local a = Action:new(ch, woOk, invItem)

  lu.assertEquals(a.character, ch)
  lu.assertEquals(a.worldItemObj, woOk)
  lu.assertEquals(a.invItem, invItem)
  lu.assertTrue(a.stopOnWalk)
  lu.assertTrue(a.stopOnRun)
  lu.assertEquals(a.maxTime, 400)
  lu.assertEquals(a.boredomReduce, 20)
  lu.assertEquals(a.unhappyReduce, 10)
  lu.assertEquals(a.stressReduce, 0.05)
end
