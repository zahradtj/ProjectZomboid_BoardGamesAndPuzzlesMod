-- tests/spec/test_play_boardgame_from_inventory.lua
-- LuaUnit tests for ISPlayBoardGameFromInventory.lua
local lu = require("luaunit")

-- ---------------------------
-- Module stubs via preload
-- ---------------------------

-- Ensure real modules aren't already cached
package.loaded["helpers/BoardGame_Thoughts"] = nil
package.loaded["BoardGamesAndPuzzlesMod_Operation"] = nil
package.loaded["TimedActions/ISBaseTimedAction"] = nil
package.loaded["TimedActions/ISPlayBoardGameFromInventory"] = nil

-- Stub TimedActions/ISBaseTimedAction: the game loads it for side effects, but in tests we provide it.
package.preload["TimedActions/ISBaseTimedAction"] = function()
  local Base = {}

  -- Simple class system compatible with `:derive()`
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
  return true -- matches PZ style
end

-- Stub BoardGame_Thoughts module (records calls)
package.preload["helpers/BoardGame_Thoughts"] = function()
  local M = { calls = {} }
  function M.reset() M.calls = {} end
  function M.show(character, fullType, outcome)
    table.insert(M.calls, { character = character, fullType = fullType, outcome = outcome })
  end
  return M
end

-- Stub Operation module (record calls, controllable isOperation)
package.preload["BoardGamesAndPuzzlesMod_Operation"] = function()
  local M = { calls = {}, _isOperation = false }
  function M.reset()
    M.calls = {}
    M._isOperation = false
  end
  function M.isOperationItem(item) return M._isOperation end
  function M.doPlayOperation(character, item)
    table.insert(M.calls, { character = character, item = item })
  end
  return M
end

-- ---------------------------
-- Global function stubs
-- ---------------------------

-- Surface / light checks
_G.hasNearbySurface = function(_, _) return true end
_G.hasEnoughLight   = function(_, _) return true end

-- Clock + RNG (overridden per-test)
_G.__NOW_MS = 1000
_G.getTimestampMs = function() return NOW_MS end

-- Default deterministic RNG BEFORE requiring module under test
ZombRand = function(a, b)
  if b ~= nil then return a end
  return 99
end
_G.ZombRand = ZombRand


-- CharacterStat stub
_G.CharacterStat = {
  BOREDOM = "BOREDOM",
  STRESS = "STRESS",
  UNHAPPINESS = "UNHAPPINESS",
}

-- ---------------------------
-- Require module under test
-- ---------------------------
local Action = require("TimedActions/ISPlayBoardGameFromInventory")
local Thoughts = require("helpers/BoardGame_Thoughts")
local Operation = require("BoardGamesAndPuzzlesMod_Operation")

-- ---------------------------
-- Helpers / fakes
-- ---------------------------
local function makeItem(fullType)
  return {
    getFullType = function() return fullType end
  }
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
    SetVariable = function(self, k, v) self._vars[k] = v end,
    getStats = function() return stats end,
  }, stats
end

-- ---------------------------
-- Tests
-- ---------------------------
TestPlayFromInventory = {}

function TestPlayFromInventory:setUp()
  _G.reset_test_globals()
  Thoughts.reset()
  Operation.reset()
  _G.__NOW_MS = 1000

  ZombRand = function(a, b)
    if b ~= nil then return a end  -- two-arg: lower bound
    return 99                      -- one-arg: "high" (usually failure/no thought)
  end
  _G.ZombRand = ZombRand

  _G.hasNearbySurface = function(_, _) return true end
  _G.hasEnoughLight   = function(_, _) return true end
end


function TestPlayFromInventory:testIsValidSurfaceRequirement()
  local ch = makeCharacter()
  local a = Action:new(ch, makeItem("Base.Chess"), 400)
  a.requireSurface = true

  _G.hasNearbySurface = function(_, _) return false end
  lu.assertFalse(a:isValid())

  _G.hasNearbySurface = function(_, _) return true end
  lu.assertTrue(a:isValid())
end

function TestPlayFromInventory:testIsValidLightRequirement()
  local ch = makeCharacter()
  local a = Action:new(ch, makeItem("Base.Chess"), 400)
  a.requireLight = true

  _G.hasEnoughLight = function(_, _) return false end
  lu.assertFalse(a:isValid())

  _G.hasEnoughLight = function(_, _) return true end
  lu.assertTrue(a:isValid())
end

function TestPlayFromInventory:testStartSetsAnimAndSchedulesNextThought()
  local ch = makeCharacter()
  local a = Action:new(ch, makeItem("Base.Chess"), 400)

  _G.__NOW_MS = 1000

  local oldZR = ZombRand
  ZombRand = function(a, b)
    -- Force ZombRand(2000,6001) => 2000
    if b ~= nil then return 2000 end
    return 99
  end
  _G.ZombRand = ZombRand

  a:start()

  ZombRand = oldZR
  _G.ZombRand = oldZR


  lu.assertEquals(a._anim, "Loot")
  lu.assertEquals(ch._vars["LootPosition"], "Mid")
  lu.assertEquals(a.nextThoughtMs, 3000)
end


function TestPlayFromInventory:testUpdateDoesNothingBeforeNextThought()
  local ch = makeCharacter()
  local a = Action:new(ch, makeItem("Base.Chess"), 400)

  a.nextThoughtMs = 5000
  _G.__NOW_MS = 4000

  local oldZR = ZombRand
  ZombRand = function(a, b) return 0 end -- shouldn't be called
  _G.ZombRand = ZombRand

  a:update()

  ZombRand = oldZR
  _G.ZombRand = oldZR


  lu.assertEquals(#Thoughts.calls, 0)
  lu.assertEquals(a.nextThoughtMs, 5000)
end


function TestPlayFromInventory:testUpdateShowsNeutralAndReschedules()
    local ch = makeCharacter()
    local a = Action:new(ch, makeItem("Base.Chess"), 400)

    _G.__NOW_MS = 5000
    a.nextThoughtMs = 5000

    -- Force: first ZombRand(100) => 0 (show thought)
    -- and next ZombRand(4000,10001) => 4000 (reschedule)
    local oldZR = _G.ZombRand
    _G.ZombRand = function(a, b)
        if b == nil then
            -- one-arg call: ZombRand(100)
            return 0
        else
            -- two-arg call: ZombRand(4000,10001)
            return a
        end
    end

    a:update()

    _G.ZombRand = oldZR

    lu.assertEquals(#Thoughts.calls, 1)
    lu.assertEquals(Thoughts.calls[1].outcome, "neutral")
    lu.assertEquals(Thoughts.calls[1].fullType, "Base.Chess")
    lu.assertEquals(a.nextThoughtMs, 9000)
end


function TestPlayFromInventory:testUpdateNoNeutralStillReschedules()
  local ch = makeCharacter()
  local a = Action:new(ch, makeItem("Base.Chess"), 400)

  _G.__NOW_MS = 5000
  a.nextThoughtMs = 5000

  local oldZR = ZombRand
  ZombRand = function(a, b)
    if b == nil then return 99 end -- ZombRand(100) => 99 (no neutral)
    return 4000                    -- ZombRand(4000,10001) => 4000
  end
  _G.ZombRand = ZombRand

  a:update()

  ZombRand = oldZR
  _G.ZombRand = oldZR


  lu.assertEquals(#Thoughts.calls, 0)
  lu.assertEquals(a.nextThoughtMs, 9000)
end

function TestPlayFromInventory:testPerformReducesStats()
  local ch, stats = makeCharacter()
  local a = Action:new(ch, makeItem("Base.Chess"), 400, 21, 11, 0.06)

  -- Force non-operation and success branch doesn't matter for this test
  Operation._isOperation = false
  local oldZR = ZombRand
  ZombRand = function(a, b)
    if b == nil then return 0 end -- ZombRand(100) => 0 (success)
    return a
  end
  _G.ZombRand = ZombRand

  a:perform()

  ZombRand = oldZR
  _G.ZombRand = oldZR


  lu.assertEquals(#stats.removed, 3)
  lu.assertEquals(stats.removed[1].k, CharacterStat.BOREDOM)
  lu.assertEquals(stats.removed[1].amt, 21)
  lu.assertEquals(stats.removed[2].k, CharacterStat.STRESS)
  lu.assertEquals(stats.removed[2].amt, 0.06)
  lu.assertEquals(stats.removed[3].k, CharacterStat.UNHAPPINESS)
  lu.assertEquals(stats.removed[3].amt, 11)

  lu.assertTrue(a._performed) -- ISBaseTimedAction.perform called
end

function TestPlayFromInventory:testPerformOperationCallsDoPlayOperation()
  local ch = makeCharacter()
  local item = makeItem("BoardGamesAndPuzzlesMod.Operation")
  local a = Action:new(ch, item, 400)

  Operation._isOperation = true

  a:perform()

  lu.assertEquals(#Operation.calls, 1)
  lu.assertEquals(Operation.calls[1].character, ch)
  lu.assertEquals(Operation.calls[1].item, item)
  lu.assertEquals(#Thoughts.calls, 0) -- should not show success/failure thoughts here
end

function TestPlayFromInventory:testPerformNonOperationSuccessShowsThought()
  local ch = makeCharacter()
  local item = makeItem("Base.Chess")
  local a = Action:new(ch, item, 400)

  Operation._isOperation = false

  local oldZR = _G.ZombRand
  _G.ZombRand = function(a, b)
    -- perform uses ZombRand(100) (one-arg)
    if b == nil then return 0 end
    return a
  end

  a:perform()

  _G.ZombRand = oldZR

  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].outcome, "success")
end


function TestPlayFromInventory:testPerformNonOperationFailureShowsThought()
  local ch = makeCharacter()
  local item = makeItem("Base.Chess")
  local a = Action:new(ch, item, 400)

  Operation._isOperation = false
  local oldZR = ZombRand
  ZombRand = function(a, b)
    if b == nil then return 99 end -- failure branch
    return a
  end
  _G.ZombRand = ZombRand

  a:perform()

  ZombRand = oldZR
  _G.ZombRand = oldZR


  lu.assertEquals(#Thoughts.calls, 1)
  lu.assertEquals(Thoughts.calls[1].outcome, "failure")
end

function TestPlayFromInventory:testNewDefaults()
  local ch = makeCharacter()
  local item = makeItem("Base.Chess")
  local a = Action:new(ch, item)

  lu.assertEquals(a.character, ch)
  lu.assertEquals(a.item, item)
  lu.assertTrue(a.stopOnWalk)
  lu.assertTrue(a.stopOnRun)
  lu.assertEquals(a.maxTime, 400)
  lu.assertEquals(a.boredomReduce, 20)
  lu.assertEquals(a.unhappyReduce, 10)
  lu.assertEquals(a.stressReduce, 0.05)
end
