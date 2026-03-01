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

_G.Events = _G.Events or { OnFillInventoryObjectContextMenu = { Add = function(_) end } }
_G.ZombRand = _G.ZombRand or function(a, b) return a end  -- deterministic stub

local lu = require("luaunit")

local ok_lfs, lfs = pcall(require, "lfs")

local function require_all_tests()
  local specDir = "tests/spec"

  if ok_lfs and lfs then
    for file in lfs.dir(specDir) do
      -- load only test_*.lua
      if file:match("^test_.*%.lua$") then
        local mod = ("tests.spec.%s"):format(file:gsub("%.lua$", ""))
        require(mod)
      end
    end
    return
  end

  -- Fallback (no lfs): use io.popen + ls (linux/mac)
  local p = io.popen("ls " .. specDir)
  if not p then error("Could not list " .. specDir .. " (need lfs or io.popen)") end

  for file in p:lines() do
    if file:match("^test_.*%.lua$") then
      local mod = ("tests.spec.%s"):format(file:gsub("%.lua$", ""))
      require(mod)
    end
  end
  p:close()
end

require_all_tests()

os.exit(lu.LuaUnit.run())