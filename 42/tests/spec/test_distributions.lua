-- tests/spec/test_distributions.lua
-- LuaUnit tests for server/BGP_Distributions.lua

local lu = require("luaunit")

-- -------------------------------------------------------
-- Candidate locations for the server file
-- -------------------------------------------------------
local CANDIDATE_PATHS = {
  "media/lua/server/BGP_Distributions.lua",
}

local function loadDistributionsScript()
  local lastErr
  for _, p in ipairs(CANDIDATE_PATHS) do
    local chunk, err = loadfile(p)
    if chunk then
      local ok, res = pcall(chunk)
      if not ok then error("Error executing " .. p .. ": " .. tostring(res)) end
      return p
    end
    lastErr = err
  end
  error("Could not load server/BGP_Distributions.lua from candidates. Last error: " .. tostring(lastErr))
end

-- -------------------------------------------------------
-- Stubs for required modules
-- -------------------------------------------------------
package.loaded["Items/ProceduralDistributions"] = nil
package.loaded["Items/SuburbsDistributions"] = nil
package.loaded["Items/Distributions"] = nil
package.loaded["Items/ItemPicker"] = nil
package.loaded["BoardGame"] = nil
package.loaded["BoardGameCategoryEnum"] = nil
package.loaded["BGP_Puzzles"] = nil

package.preload["Items/ProceduralDistributions"] = function() return true end
package.preload["Items/SuburbsDistributions"]       = function() return true end
package.preload["Items/Distributions"]              = function() return true end
package.preload["Items/ItemPicker"]                 = function() return true end

package.preload["BoardGameCategoryEnum"] = function()
  return {
    Kids   = "kids",
    Family = "family",
    Brain  = "brain",
    Hobby  = "hobby",
    Misc   = "misc",
  }
end

package.preload["BoardGame"] = function()
  local MOD = "BoardGamesAndPuzzlesMod"
  return {
    AxisAndAllies      = MOD .. ".AxisAndAllies",
    B17QueenOfTheSkies = MOD .. ".B17QueenOfTheSkies",
    Backgammon         = MOD .. ".Backgammon",
    Boggle             = MOD .. ".Boggle",
    CandyLand          = MOD .. ".CandyLand",
    Checkers           = MOD .. ".Checkers",
    Chess              = MOD .. ".Chess",
    Clue               = MOD .. ".Clue",
    Go                 = MOD .. ".Go",
    Mastermind         = MOD .. ".Mastermind",
    Monopoly           = MOD .. ".Monopoly",
    Operation          = MOD .. ".Operation",
    Risk               = MOD .. ".Risk",
    Scrabble           = MOD .. ".Scrabble",
    SnakesAndLadders   = MOD .. ".SnakesAndLadders",
    Sorry              = MOD .. ".Sorry",
    TheGameOfLife      = MOD .. ".TheGameOfLife",
    TrivialPursuit     = MOD .. ".TrivialPursuit",
    Trouble            = MOD .. ".Trouble",
    Yahtzee            = MOD .. ".Yahtzee",

    -- referenced in CATEGORY table but not in GAMES list (fine)
    MakeshiftStrategy  = MOD .. ".MakeshiftStrategy",
  }
end

package.preload["BGP_Puzzles"] = function()
  local MOD = "BoardGamesAndPuzzlesMod"

  -- We only need these functions for BGP_Distributions.lua:
  -- * getDesignsForSize(sizeKey) -> list of {fullType=...}
  -- * sizeKeyFromFullType(fullType) -> "mini"/"small"/"medium"/"large"/nil
  local M = {}

  local designsBySize = {
    mini = {
      { fullType = MOD .. ".Puzzle20_Alpaca" },
      { fullType = MOD .. ".Puzzle20_Blocks" },
    },
    small = {
      { fullType = MOD .. ".Puzzle500_Boat" },
      { fullType = MOD .. ".Puzzle500_Flowers" },
    },
    medium = {
      { fullType = MOD .. ".Puzzle1000_Marina" },
      { fullType = MOD .. ".Puzzle1000_Space" },
    },
    large = {
      { fullType = MOD .. ".Puzzle2000_Aurora" },
      { fullType = MOD .. ".Puzzle2000_WinterTrees" },
    },
  }

  function M.getDesignsForSize(sizeKey)
    return designsBySize[sizeKey] or {}
  end

  function M.sizeKeyFromFullType(fullType)
    if type(fullType) ~= "string" then return nil end
    if fullType:find(MOD .. ".Puzzle20_", 1, true) then return "mini" end
    if fullType:find(MOD .. ".Puzzle500_", 1, true) then return "small" end
    if fullType:find(MOD .. ".Puzzle1000_", 1, true) then return "medium" end
    if fullType:find(MOD .. ".Puzzle2000_", 1, true) then return "large" end
    return nil
  end

  return M
end

-- -------------------------------------------------------
-- Helpers for asserting procedural tables
-- -------------------------------------------------------
local PROCEDURAL_ALL = {
  "Antiques",
  "BarCounterMisc",
  "BedroomDresser",
  "BedroomDresserChild",
  "BedroomDresserClassy",
  "BedroomDresserRedneck",
  "BedroomSidetable",
  "BedroomSidetableChild",
  "BookstoreChilds",
  "BookstoreHobbies",
  "BookstoreMisc",
  "BreakRoomCounter",
  "BreakRoomShelves",
  "CafeShelfBooks",
  "ClassroomMisc",
  "ClassroomShelves",
  "ClassroomSecondaryMisc",
  "ClassroomSecondaryShelves",
  "ClosetShelfGeneric",
  "ComicStoreCounter",
  "ComicStoreShelfGames",
  "CrateRandomJunk",
  "CrateToys",
  "CyberCafeDesk",
  "CyberCafeFilingCabinet",
  "DaycareCounter",
  "DaycareDesk",
  "DaycareShelves",
  "Gifts",
  "GiftStoreToys",
  "GigamartToys",
  "Hobbies",
  "JunkHoard",
  "KitchenRandom",
  "LivingRoomShelf",
  "LivingRoomShelfClassy",
  "LivingRoomShelfRedneck",
  "LivingRoomSideTable",
  "LivingRoomSideTableClassy",
  "LivingRoomSideTableRedneck",
  "LivingRoomWardrobe",
  "OfficeDeskHome",
  "OfficeDeskHomeClassy",
  "RecRoomShelf",
  "SchoolLockers",
  "UniversitySideTable",
  "UniversityWardrobe",
  "WardrobeChild",
}

local function makeProceduralList()
  local list = {}
  for _, k in ipairs(PROCEDURAL_ALL) do
    list[k] = { items = {} }
  end
  -- also referenced by special-case injection:
  list["PoliceFilingCabinet"] = { items = {} }
  return list
end

local function makeDistributionsTree()
  return {
    BagsAndContainers = {
      Parcel_Small  = { items = {} },
      Parcel_Medium = { items = {} },
    },
    ClutterTables = {
      BinItems   = { items = {} },
      ClosetJunk = { items = {} },
    }
  }
end

local function occurrences(itemsArray, fullType)
  local n = 0
  for i = 1, #itemsArray, 2 do
    if itemsArray[i] == fullType then n = n + 1 end
  end
  return n
end

local function findWeight(itemsArray, fullType, nth)
  nth = nth or 1
  local seen = 0
  for i = 1, #itemsArray, 2 do
    if itemsArray[i] == fullType then
      seen = seen + 1
      if seen == nth then
        return itemsArray[i + 1]
      end
    end
  end
  return nil
end

-- -------------------------------------------------------
-- Tests
-- -------------------------------------------------------
TestBGP_Distributions = {}

function TestBGP_Distributions:setUp()
  -- Fresh globals used by script
  _G.ProceduralDistributions = { list = makeProceduralList() }
  _G.Distributions = makeDistributionsTree()

  -- quiet prints (still callable)
  self._origPrint = _G.print
  _G.print = function(...) end
end

function TestBGP_Distributions:tearDown()
  _G.print = self._origPrint
end

function TestBGP_Distributions:testBaselineInjectionAddsItemsToAllProceduralLists()
  loadDistributionsScript()

  local BoardGame = require("BoardGame")
  local Puzzles = require("BGP_Puzzles")

  local sampleGame = BoardGame.Chess
  local samplePuzzle = Puzzles.getDesignsForSize("mini")[1].fullType

  for _, listName in ipairs(PROCEDURAL_ALL) do
    local items = _G.ProceduralDistributions.list[listName].items
    lu.assertTrue(occurrences(items, sampleGame) >= 1, "Missing baseline game in " .. listName)
    lu.assertTrue(occurrences(items, samplePuzzle) >= 1, "Missing baseline puzzle in " .. listName)
  end
end

function TestBGP_Distributions:testBoostInjectionAddsExtraWeightWhenMultiplierAboveOne()
  loadDistributionsScript()

  local BoardGame = require("BoardGame")

  -- kids group includes DaycareShelves
  local items = _G.ProceduralDistributions.list["DaycareShelves"].items

  -- CandyLand baseW = 1.0, kids multiplier in kids group = 1.8 => extra = 0.8
  lu.assertEquals(occurrences(items, BoardGame.CandyLand), 2) -- baseline + extra
  lu.assertAlmostEquals(findWeight(items, BoardGame.CandyLand, 2), 0.8, 1e-9)
end

function TestBGP_Distributions:testBoostInjectionDoesNotAddWhenMultiplierBelowOrEqualOne()
  loadDistributionsScript()

  local BoardGame = require("BoardGame")

  -- hobby group includes Hobbies; kids multiplier in hobby group = 0.6 (<=1 => no extra)
  local items = _G.ProceduralDistributions.list["Hobbies"].items

  -- CandyLand is kids category; should only have baseline entry in Hobbies (no extra)
  lu.assertEquals(occurrences(items, BoardGame.CandyLand), 1)
end

function TestBGP_Distributions:testPuzzleWeightsAreSplitAcrossDesignsPerSize()
  loadDistributionsScript()

  local Puzzles = require("BGP_Puzzles")

  -- mini base weight = 1.3 split across 2 mini designs => 0.65 each baseline
  local mini1 = Puzzles.getDesignsForSize("mini")[1].fullType

  local items = _G.ProceduralDistributions.list["Antiques"].items
  local w = findWeight(items, mini1, 1) -- baseline entry
  lu.assertAlmostEquals(w, 1.3 / 2, 1e-9)
end

function TestBGP_Distributions:testSpecialCaseAddsClueToPoliceFilingCabinet()
  loadDistributionsScript()

  local BoardGame = require("BoardGame")

  local items = _G.ProceduralDistributions.list["PoliceFilingCabinet"].items
  lu.assertEquals(occurrences(items, BoardGame.Clue), 1)
  lu.assertAlmostEquals(findWeight(items, BoardGame.Clue, 1), 0.15, 1e-9)
end

function TestBGP_Distributions:testDistTablesReceiveScaledWeights()
  loadDistributionsScript()

  local BoardGame = require("BoardGame")

  local parcel = _G.Distributions.BagsAndContainers.Parcel_Small.items
  -- Chess base weight in file is 1.0, scaled by 0.35 => 0.35
  lu.assertEquals(occurrences(parcel, BoardGame.Chess), 1)
  lu.assertAlmostEquals(findWeight(parcel, BoardGame.Chess, 1), 0.35, 1e-9)
end

return TestBGP_Distributions