local lu = require("luaunit")

local GameDefs = require("BGP_GameDefs")
local BoardGame = require("BoardGame")

local function countKeys(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function isString(x) return type(x) == "string" end
local function isTable(x)  return type(x) == "table"  end
local function isBool(x)   return type(x) == "boolean" end
local function isNumber(x) return type(x) == "number" end

local function looksLikeFullType(s)
    -- Typical: "ModName.ItemName"
    return isString(s) and s ~= "" and s:match("^%S+%.%S+$") ~= nil
end

local function isStressReduceValid(n)
    -- Your code normalizes if > 1 by dividing by 100.
    -- So accept 0..1 OR 0..100.
    if not isNumber(n) then return false end
    if n < 0 then return false end
    return (n <= 1) or (n <= 100)
end

TestGameDefs = {}

function TestGameDefs:setUp()
    self.defs = GameDefs.GAME_DEFS
end

function TestGameDefs:testGameDefsIsATableAndNotEmpty()
    lu.assertEquals(type(self.defs), "table")
    lu.assertTrue(countKeys(self.defs) > 0)
end

function TestGameDefs:testAllKeysLookLikeFullTypes()
    for fullType, _ in pairs(self.defs) do
        lu.assertTrue(looksLikeFullType(fullType), "Bad fullType key: " .. tostring(fullType))
    end
end

function TestGameDefs:testEachDefHasRequiredFieldsWithCorrectTypes()
    for fullType, def in pairs(self.defs) do
        lu.assertEquals(type(def), "table", "Def must be table for " .. fullType)

        lu.assertEquals(type(def.name), "string", "name must be string for " .. fullType)
        lu.assertTrue(def.name ~= "", "name must be non-empty for " .. fullType)

        lu.assertEquals(type(def.duration), "number", "duration must be number for " .. fullType)
        lu.assertTrue(def.duration > 0, "duration must be > 0 for " .. fullType)

        lu.assertEquals(type(def.boredomReduce), "number", "boredomReduce must be number for " .. fullType)
        lu.assertEquals(type(def.unhappyReduce), "number", "unhappyReduce must be number for " .. fullType)
        lu.assertEquals(type(def.stressReduce), "number", "stressReduce must be number for " .. fullType)

        lu.assertEquals(type(def.clumsyImpacted), "boolean", "clumsyImpacted must be boolean for " .. fullType)
        lu.assertEquals(type(def.usesBattery), "boolean", "usesBattery must be boolean for " .. fullType)

        lu.assertEquals(type(def.default), "table", "default must be table for " .. fullType)
        lu.assertEquals(type(def.default.illiterateAllowed), "boolean", "default.illiterateAllowed must be boolean for " .. fullType)
        lu.assertEquals(type(def.default.illiterateFailurePercent), "number", "default.illiterateFailurePercent must be number for " .. fullType)
    end
end

function TestGameDefs:testRangesAreSane()
    for fullType, def in pairs(self.defs) do
        lu.assertTrue(def.boredomReduce >= 0 and def.boredomReduce <= 100,
            "boredomReduce out of range for " .. fullType .. ": " .. tostring(def.boredomReduce))

        lu.assertTrue(def.unhappyReduce >= 0 and def.unhappyReduce <= 100,
            "unhappyReduce out of range for " .. fullType .. ": " .. tostring(def.unhappyReduce))

        lu.assertTrue(def.default.illiterateFailurePercent >= 0 and def.default.illiterateFailurePercent <= 100,
            "illiterateFailurePercent out of range for " .. fullType .. ": " .. tostring(def.default.illiterateFailurePercent))

        lu.assertTrue(isStressReduceValid(def.stressReduce),
            "stressReduce must be 0..1 or 0..100 for " .. fullType .. ": " .. tostring(def.stressReduce))
    end
end

function TestGameDefs:testGameNamesAreUnique()
    local seen = {}
    for fullType, def in pairs(self.defs) do
        if seen[def.name] then
            lu.fail(("Duplicate game name '%s' for %s and %s"):format(def.name, seen[def.name], fullType))
        end
        seen[def.name] = fullType
    end
end

function TestGameDefs:testEveryBoardGameConstantHasADefinition()
    -- Ensures your enum-like BoardGame table and GAME_DEFS stay in sync.
    for k, v in pairs(BoardGame) do
        if type(v) == "string" then
            lu.assertNotNil(self.defs[v], "Missing GAME_DEFS entry for BoardGame." .. tostring(k) .. " (" .. v .. ")")
        end
    end
end

-- If you want this test file to be runnable directly:
-- os.exit(lu.LuaUnit.run())
return TestGameDefs
