-- tests/spec/test_battery_manager.lua
-- Unit tests for helpers/BoardGame_BatteryManager.lua using LuaUnit
local lu = require("luaunit")

local BatteryManager = require("helpers.BoardGame_BatteryManager")

TestBatteryManager = {}

function TestBatteryManager:testGetChargeInitializesMissing()
    local md = {}
    local v = BatteryManager.getCharge(md)
    lu.assertEquals(v, 0)
    lu.assertEquals(md.opBatteryCharge, 0)
end

function TestBatteryManager:testGetChargeReturnsExisting()
    local md = { opBatteryCharge = 0.72 }
    local v = BatteryManager.getCharge(md)
    lu.assertEquals(v, 0.72)
    lu.assertEquals(md.opBatteryCharge, 0.72)
end

function TestBatteryManager:testSetChargeClampsLowHighAndKeepsInRange()
    local md = {}

    lu.assertEquals(BatteryManager.setCharge(md, -1), 0)
    lu.assertEquals(md.opBatteryCharge, 0)

    lu.assertEquals(BatteryManager.setCharge(md, 2), 1)
    lu.assertEquals(md.opBatteryCharge, 1)

    lu.assertEquals(BatteryManager.setCharge(md, 0.5), 0.5)
    lu.assertEquals(md.opBatteryCharge, 0.5)
end

function TestBatteryManager:testBatteryLabelRounding()
    lu.assertEquals(BatteryManager.batteryLabel(0), "Battery: 0%")
    lu.assertEquals(BatteryManager.batteryLabel(1), "Battery: 100%")

    -- 0.725 * 100 = 72.5 => +0.5 => 73.0 => 73%
    lu.assertEquals(BatteryManager.batteryLabel(0.725), "Battery: 73%")
end

function TestBatteryManager:testMenuModelChargeZeroNoBattery()
    local m = BatteryManager.menuModel(0, false)
    lu.assertEquals(m.label, "Battery: 0%")
    lu.assertTrue(m.showInsert)
    lu.assertFalse(m.showRemove)
    lu.assertFalse(m.insertEnabled)
end

function TestBatteryManager:testMenuModelChargeZeroHasBattery()
    local m = BatteryManager.menuModel(0, true)
    lu.assertEquals(m.label, "Battery: 0%")
    lu.assertTrue(m.showInsert)
    lu.assertFalse(m.showRemove)
    lu.assertTrue(m.insertEnabled)
end

function TestBatteryManager:testMenuModelChargePositive()
    local m = BatteryManager.menuModel(0.2, false)
    lu.assertEquals(m.label, "Battery: 20%")
    lu.assertFalse(m.showInsert)
    lu.assertTrue(m.showRemove)
    lu.assertFalse(m.insertEnabled)
end

function TestBatteryManager:testMenuModelNilChargeTreatedAsZero()
    local m = BatteryManager.menuModel(nil, true)
    lu.assertEquals(m.label, "Battery: 0%")
    lu.assertTrue(m.showInsert)
    lu.assertFalse(m.showRemove)
    lu.assertTrue(m.insertEnabled)
end

function TestBatteryManager:testMenuModelClampsCharge()
    local m1 = BatteryManager.menuModel(-1, true)
    lu.assertEquals(m1.label, "Battery: 0%")
    lu.assertTrue(m1.showInsert)

    local m2 = BatteryManager.menuModel(2, false)
    lu.assertEquals(m2.label, "Battery: 100%")
    lu.assertTrue(m2.showRemove)
end

function TestBatteryManager:testPlayStepNoBattery()
    local step = BatteryManager.playStep(0, 0, 0.08, 18)
    lu.assertEquals(step.outcome, "no_battery")
    lu.assertEquals(step.newCharge, 0)
end

function TestBatteryManager:testPlayStepFailureAndDrain()
    -- rng100=0 < 18 => failure
    local step = BatteryManager.playStep(0.5, 0, 0.08, 18)
    lu.assertEquals(step.outcome, "failure")
    lu.assertAlmostEquals(step.newCharge, 0.42, 1e-9)
end

function TestBatteryManager:testPlayStepSuccessAndDrain()
    -- rng100=99 >= 18 => success
    local step = BatteryManager.playStep(0.5, 99, 0.08, 18)
    lu.assertEquals(step.outcome, "success")
    lu.assertAlmostEquals(step.newCharge, 0.42, 1e-9)
end

function TestBatteryManager:testPlayStepDrainClampsToZero()
    local step = BatteryManager.playStep(0.03, 99, 0.08, 18)
    lu.assertEquals(step.outcome, "success")
    lu.assertEquals(step.newCharge, 0)
end

function TestBatteryManager:testPlayStepClampsInputCharge()
    -- charge > 1 clamps to 1 before drain
    local stepHi = BatteryManager.playStep(2, 99, 0.08, 18)
    lu.assertEquals(stepHi.outcome, "success")
    lu.assertAlmostEquals(stepHi.newCharge, 0.92, 1e-9)

    -- charge < 0 clamps to 0 => no_battery
    local stepLo = BatteryManager.playStep(-1, 99, 0.08, 18)
    lu.assertEquals(stepLo.outcome, "no_battery")
    lu.assertEquals(stepLo.newCharge, 0)
end
