-- BoardGame_BatteryManager.lua
local M = {}

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

function M.getCharge(md)
  local v = md.opBatteryCharge
  if v == nil then
    md.opBatteryCharge = 0
    return 0
  end
  return v
end

function M.setCharge(md, charge)
  md.opBatteryCharge = clamp(charge, 0, 1)
  return md.opBatteryCharge
end

function M.batteryLabel(charge)
  return string.format("Battery: %d%%", math.floor(charge * 100 + 0.5))
end

function M.menuModel(charge, hasBatteryInInventory)
  charge = clamp(charge or 0, 0, 1)
  return {
    label = M.batteryLabel(charge),
    showInsert = (charge <= 0),
    showRemove = (charge > 0),
    insertEnabled = (charge <= 0) and hasBatteryInInventory or false,
  }
end

-- rng100 is a random int 0..99 supplied by caller
function M.playStep(charge, rng100, drain, failChancePercent)
  charge = clamp(charge or 0, 0, 1)
  if charge <= 0 then
    return { outcome = "no_battery", newCharge = 0 }
  end

  local outcome = (rng100 < failChancePercent) and "failure" or "success"
  local newCharge = clamp(charge - drain, 0, 1)
  return { outcome = outcome, newCharge = newCharge }
end

return M
