-- tests/run_tests.lua
local root = arg[1] or "."  -- allow passing repo root
local function add_path(p)
  package.path = p .. "/?.lua;" .. p .. "/?/init.lua;" .. package.path
end

-- tests/run_tests.lua

_G.__test_defaults = _G.__test_defaults or {}

local function set_default_globals()
  -- deterministic defaults that all specs can rely on
  _G.hasNearbySurface = function(_, _) return true end
  _G.hasEnoughLight   = function(_, _) return true end

  _G.__NOW_MS = 1000
  _G.getTimestampMs = function() return _G.__NOW_MS end

  _G.ZombRand = function(a, b)
    if b ~= nil then return a end
    return 99
  end
end

_G.reset_test_globals = function()
  set_default_globals()
end

reset_test_globals()


-- PZ loads from media/lua/(shared|client|server)
add_path(root .. "/media/lua/shared")
add_path(root .. "/media/lua/client")
add_path(root .. "/media/lua/server")

add_path(root .. "/tests")
add_path(root .. "/tests/libs")

-- If you want: basic stubs for globals some modules might expect
_G.Events = _G.Events or { OnFillInventoryObjectContextMenu = { Add = function(_) end } }
_G.ZombRand = _G.ZombRand or function(a, b) return a end  -- deterministic stub

local lu = require("luaunit")

require("tests.spec.test_battery_manager")
require("tests.spec.test_game_defs")
require("tests.spec.test_game_evaluator")
require("tests.spec.test_menu_handlers")
require("tests.spec.test_operation")
require("tests.spec.test_play_boardgame_from_ground")
require("tests.spec.test_play_boardgame_from_inventory")
require("tests.spec.test_requirements")
require("tests.spec.test_tooltips")

os.exit(lu.LuaUnit.run())