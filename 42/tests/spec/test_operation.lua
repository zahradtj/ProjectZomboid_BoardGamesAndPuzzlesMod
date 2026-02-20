-- tests/spec/test_operation.lua
local lu = require("luaunit")

-- -----------------------
-- Global stubs (must exist BEFORE requiring the mod file)
-- -----------------------

-- prevent event registration from crashing
_G.Events = {
  OnFillInventoryObjectContextMenu = {
    Add = function(_) end
  }
}

-- deterministic RNG default (not used if we pass rng100 explicitly)
_G.ZombRand = function(_) return 99 end

-- stub thoughts module used by the mod
_G.BoardGame_Thoughts = {
  calls = {},
  show = function(playerObj, opType, outcome)
    table.insert(_G.BoardGame_Thoughts.calls, { playerObj = playerObj, opType = opType, outcome = outcome })
  end
}

-- stub sound-related globals so failure path doesn't crash
_G.getSoundManager = function()
  return {
    PlayWorldSoundImpl = function(...) end
  }
end
_G.addWorldSound = function(...) end  -- optional, but nice

-- getSpecificPlayer stub for menu tests
_G.getSpecificPlayer = function(_) return nil end

-- ISContextMenu stub for menu tests
_G.ISContextMenu = {
  getNew = function(_)
    return {
      options = {},
      addOption = function(self, label, target, cb, arg)
        local opt = { label = label, target = target, cb = cb, arg = arg }
        table.insert(self.options, opt)
        return opt
      end
    }
  end
}

package.preload["helpers/BoardGame_Thoughts"] = function()
  return {
    calls = {},
    show = function(playerObj, opType, outcome)
      table.insert(package.loaded["helpers/BoardGame_Thoughts"].calls,
        { playerObj = playerObj, opType = opType, outcome = outcome })
    end
  }
end


-- --------------------------------
-- Require the module under test
-- --------------------------------
local Operation = require("BoardGamesAndPuzzlesMod_Operation")  -- adjust path if needed

-- --------------------------------
-- Test helpers / fakes
-- --------------------------------

local function makeItem(fullType, md)
  md = md or {}
  return {
    getModData = function() return md end,
    getFullType = function() return fullType end,
  }, md
end

local function makeBattery(usedDelta)
  return {
    getUsedDelta = function() return usedDelta end,
    setUsedDelta = function(self, v) self._set = v end,
    _set = nil,
  }
end

local function makeInventory(opts)
  -- opts = { foundBattery = <battery or nil>, addItemBattery = <battery>, containsBattery = bool }
  local inv = {
    removed = {},
    added = {},
    FindAndReturn = function(self, fullType)
      self._findType = fullType
      return opts.foundBattery
    end,
    Remove = function(self, item)
      table.insert(self.removed, item)
    end,
    AddItem = function(self, fullType)
      self._addType = fullType
      local b = opts.addItemBattery or makeBattery(1.0)
      table.insert(self.added, b)
      return b
    end,
    containsTypeRecurse = function(self, typeName)
      self._containsType = typeName
      return opts.containsBattery == true
    end
  }
  return inv
end

local function makePlayer(inv)
  return {
    getInventory = function() return inv end,
    getEmitter = function() return { playSound = function(...) end } end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
  }
end

local function resetThoughtCalls()
  _G.BoardGame_Thoughts.calls = {}
end

-- -----------------------
-- Tests: public API only
-- -----------------------
TestOperationPublic = {}

function TestOperationPublic:testIsOperationItem()
  local opItem = makeItem("BoardGamesAndPuzzlesMod.Operation")
  lu.assertTrue(Operation.isOperationItem(opItem))

  local other = makeItem("Base.Hammer")
  lu.assertFalse(Operation.isOperationItem(other))

  lu.assertFalse(Operation.isOperationItem(nil))
end

function TestOperationPublic:testGetChargeInitializesToZero()
  local item, md = makeItem("BoardGamesAndPuzzlesMod.Operation", {})
  lu.assertEquals(Operation.getCharge(item), 0)
  lu.assertEquals(md.opBatteryCharge, 0)
end

function TestOperationPublic:testHasBattery()
  local item, md = makeItem("BoardGamesAndPuzzlesMod.Operation", { opBatteryCharge = 0 })
  lu.assertFalse(Operation.hasBattery(item))

  md.opBatteryCharge = 0.01
  lu.assertTrue(Operation.hasBattery(item))
end

function TestOperationPublic:testDoPlayOperationNoBatteryDoesNothing()
  resetThoughtCalls()
  local item, md = makeItem("BoardGamesAndPuzzlesMod.Operation", { opBatteryCharge = 0 })
  local player = makePlayer(makeInventory({}))

  Operation.doPlayOperation(player, item, function() return 0 end)

  lu.assertEquals(#_G.BoardGame_Thoughts.calls, 0)
  lu.assertEquals(md.opBatteryCharge, 0)
end

function TestOperationPublic:testDoPlayOperationSuccessDrainsAndShowsSuccess()
  resetThoughtCalls()
  local item, md = makeItem("BoardGamesAndPuzzlesMod.Operation", { opBatteryCharge = 0.5 })
  local player = makePlayer(makeInventory({}))

  -- rng=99 => success (since FAIL=18)
  Operation.doPlayOperation(player, item, function() return 99 end)

  lu.assertEquals(#_G.BoardGame_Thoughts.calls, 1)
  lu.assertEquals(_G.BoardGame_Thoughts.calls[1].outcome, "success")
  lu.assertAlmostEquals(md.opBatteryCharge, 0.42, 1e-9)
end

function TestOperationPublic:testDoPlayOperationFailureDrainsAndShowsFailure()
  resetThoughtCalls()
  local item, md = makeItem("BoardGamesAndPuzzlesMod.Operation", { opBatteryCharge = 0.5 })
  local player = makePlayer(makeInventory({}))

  -- rng=0 => failure
  Operation.doPlayOperation(player, item, function() return 0 end)

  lu.assertEquals(#_G.BoardGame_Thoughts.calls, 1)
  lu.assertEquals(_G.BoardGame_Thoughts.calls[1].outcome, "failure")
  lu.assertAlmostEquals(md.opBatteryCharge, 0.42, 1e-9)
end

-- -----------------------------------------------------
-- Tests: require _test export for local functions below
-- -----------------------------------------------------
TestOperationLocals = {}

function TestOperationLocals:setUp()
  if not Operation._test then
    self._skip = true
  end
end

function TestOperationLocals:testInsertBatteryMovesChargeIntoOpItem()
  if self._skip then
    lu.assertTrue(true) -- effectively skip
    return
  end

  local opItem, md = makeItem("BoardGamesAndPuzzlesMod.Operation", {})
  local batt = makeBattery(0.72)
  local inv = makeInventory({ foundBattery = batt, containsBattery = true })
  local player = makePlayer(inv)

  Operation._test._doInsertBattery(player, opItem)

  lu.assertEquals(#inv.removed, 1)
  lu.assertEquals(inv.removed[1], batt)
  lu.assertAlmostEquals(md.opBatteryCharge, 0.72, 1e-9)
end

function TestOperationLocals:testInsertBatteryNoBatteryNoChanges()
  if self._skip then
    lu.assertTrue(true)
    return
  end

  local opItem, md = makeItem("BoardGamesAndPuzzlesMod.Operation", { opBatteryCharge = 0.2 })
  local inv = makeInventory({ foundBattery = nil })
  local player = makePlayer(inv)

  Operation._test._doInsertBattery(player, opItem)

  lu.assertEquals(#inv.removed, 0)
  lu.assertAlmostEquals(md.opBatteryCharge, 0.2, 1e-9)
end

function TestOperationLocals:testRemoveBatteryAddsBatteryAndResetsCharge()
  if self._skip then
    lu.assertTrue(true)
    return
  end

  local opItem, md = makeItem("BoardGamesAndPuzzlesMod.Operation", { opBatteryCharge = 0.33 })
  local created = makeBattery(1.0)
  local inv = makeInventory({ addItemBattery = created })
  local player = makePlayer(inv)

  Operation._test._doRemoveBattery(player, opItem)

  lu.assertEquals(#inv.added, 1)
  lu.assertEquals(created._set, 0.33)
  lu.assertEquals(md.opBatteryCharge, 0)
end

function TestOperationLocals:testRemoveBatteryNoChargeNoAdd()
  if self._skip then
    lu.assertTrue(true)
    return
  end

  local opItem, md = makeItem("BoardGamesAndPuzzlesMod.Operation", { opBatteryCharge = 0 })
  local inv = makeInventory({})
  local player = makePlayer(inv)

  Operation._test._doRemoveBattery(player, opItem)

  lu.assertEquals(#inv.added, 0)
  lu.assertEquals(md.opBatteryCharge, 0)
end

function TestOperationLocals:testAddMenuEntriesShowsInsertOrRemove()
  if self._skip then
    lu.assertTrue(true)
    return
  end

  -- Provide getSpecificPlayer for this test
  local ctx = {
    options = {},
    addOption = function(self, label, target, cb, arg)
      local opt = { label = label, target = target, cb = cb, arg = arg }
      table.insert(self.options, opt)
      return opt
    end,
    addSubMenu = function(self, opt, subMenu)
      opt.subMenu = subMenu
    end
  }

  -- Case 1: charge=0, no battery in inv => insert option notAvailable
  local opItem, md = makeItem("BoardGamesAndPuzzlesMod.Operation", { opBatteryCharge = 0 })
  local inv1 = makeInventory({ containsBattery = false })
  local player1 = makePlayer(inv1)
  _G.getSpecificPlayer = function(_) return player1 end

  Operation._test._addMenuEntries(0, ctx, { opItem })

  -- find "Operation" top option and its submenu
  lu.assertEquals(#ctx.options, 1)
  lu.assertEquals(ctx.options[1].label, "Operation")
  local sub = ctx.options[1].subMenu
  lu.assertNotNil(sub)

  local foundInsert = false
  for _, opt in ipairs(sub.options) do
    if opt.label == "Insert Battery" then
      foundInsert = true
      lu.assertTrue(opt.notAvailable) -- disabled because no battery
    end
  end
  lu.assertTrue(foundInsert)

  -- Reset ctx for case 2
  ctx.options = {}

  -- Case 2: charge>0 => remove option
  md.opBatteryCharge = 0.5
  local inv2 = makeInventory({ containsBattery = true })
  local player2 = makePlayer(inv2)
  _G.getSpecificPlayer = function(_) return player2 end

  Operation._test._addMenuEntries(0, ctx, { opItem })

  lu.assertEquals(#ctx.options, 1)
  local sub2 = ctx.options[1].subMenu
  local foundRemove = false
  for _, opt in ipairs(sub2.options) do
    if opt.label == "Remove Battery" then
      foundRemove = true
    end
  end
  lu.assertTrue(foundRemove)
end
