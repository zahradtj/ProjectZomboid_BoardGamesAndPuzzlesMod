-- tests/test_BGP_Puzzles.lua
--
-- luaunit tests for current BGP_Puzzles (design-specific fullTypes)
--
local lu = require("luaunit")

local function countKeys(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

local Puzzles = require("BGP_Puzzles")

TestBGP_Puzzles = {}

function TestBGP_Puzzles:testModuleLoads()
    lu.assertEquals(type(Puzzles), "table")
    lu.assertEquals(type(Puzzles.Size), "table")
    lu.assertEquals(type(Puzzles.Design), "table")
end

-- ---- Size ------------------------------------------------------------

function TestBGP_Puzzles:testSizeDefsHaveRequiredFields()
    local expected = {
        Mini   = { key="mini",   pieces=20,   icon="Puzzle_20"   },
        Small  = { key="small",  pieces=500,  icon="Puzzle_500"  },
        Medium = { key="medium", pieces=1000, icon="Puzzle_1000" },
        Large  = { key="large",  pieces=2000, icon="Puzzle_2000" },
    }

    for name, exp in pairs(expected) do
        local def = Puzzles.Size[name]
        lu.assertEquals(type(def), "table", "Missing Size." .. tostring(name))

        lu.assertEquals(def.key, exp.key)
        lu.assertEquals(type(def.pieces), "number")
        lu.assertEquals(def.pieces, exp.pieces)

        lu.assertEquals(type(def.baseMinutes), "number")
        lu.assertTrue(def.baseMinutes > 0)

        lu.assertEquals(type(def.xp), "number")
        lu.assertTrue(def.xp >= 0)

        lu.assertEquals(type(def.icon), "string")
        lu.assertEquals(def.icon, exp.icon)
    end
end

function TestBGP_Puzzles:testSizePrefixMapExists()
    lu.assertEquals(type(Puzzles.SizePrefix), "table")
    lu.assertEquals(Puzzles.SizePrefix.mini,   "BoardGamesAndPuzzlesMod.Puzzle20_")
    lu.assertEquals(Puzzles.SizePrefix.small,  "BoardGamesAndPuzzlesMod.Puzzle500_")
    lu.assertEquals(Puzzles.SizePrefix.medium, "BoardGamesAndPuzzlesMod.Puzzle1000_")
    lu.assertEquals(Puzzles.SizePrefix.large,  "BoardGamesAndPuzzlesMod.Puzzle2000_")
end

-- ---- Design ----------------------------------------------------------

function TestBGP_Puzzles:testDesignTableHasEntriesAndRequiredFields()
    lu.assertTrue(countKeys(Puzzles.Design) > 0)

    for k, d in pairs(Puzzles.Design) do
        lu.assertEquals(type(d), "table", "Design." .. tostring(k) .. " must be table")

        lu.assertEquals(type(d.key), "string")
        lu.assertTrue(d.key ~= "")

        lu.assertEquals(type(d.size), "string")
        lu.assertTrue(d.size == "mini" or d.size == "small" or d.size == "medium" or d.size == "large")

        lu.assertEquals(type(d.human), "string")
        lu.assertTrue(d.human ~= "")

        lu.assertEquals(type(d.fullType), "string")
        lu.assertTrue(d.fullType:find("^BoardGamesAndPuzzlesMod%.Puzzle") ~= nil)

        lu.assertEquals(type(d.worldTex), "string")
        lu.assertTrue(d.worldTex ~= "")
    end
end

function TestBGP_Puzzles:testDesignByFullTypeLookupBuilt()
    lu.assertEquals(type(Puzzles.DesignByFullType), "table")
    lu.assertTrue(countKeys(Puzzles.DesignByFullType) > 0)

    -- pick a known design and verify lookup
    local ft = "BoardGamesAndPuzzlesMod.Puzzle20_Alpaca"
    local d = Puzzles.getDesignDefByFullType(ft)
    lu.assertNotNil(d)
    lu.assertEquals(d.fullType, ft)
    lu.assertEquals(d.human, "Alpaca")
end

function TestBGP_Puzzles:testDesignsBySizeLookupBuilt()
    lu.assertEquals(type(Puzzles.DesignsBySize), "table")
    lu.assertEquals(type(Puzzles.DesignsBySize.mini), "table")
    lu.assertEquals(type(Puzzles.DesignsBySize.small), "table")
    lu.assertEquals(type(Puzzles.DesignsBySize.medium), "table")
    lu.assertEquals(type(Puzzles.DesignsBySize.large), "table")

    -- each size should have at least 1 design in data
    lu.assertTrue(#Puzzles.getDesignsForSize("mini") > 0)
    lu.assertTrue(#Puzzles.getDesignsForSize("small") > 0)
    lu.assertTrue(#Puzzles.getDesignsForSize("medium") > 0)
    lu.assertTrue(#Puzzles.getDesignsForSize("large") > 0)

    -- spot check: all returned designs match requested size
    for _, d in ipairs(Puzzles.getDesignsForSize("mini")) do
        lu.assertEquals(d.size, "mini")
    end
end

-- ---- FullType helpers ------------------------------------------------

function TestBGP_Puzzles:testSizeKeyFromFullType()
    lu.assertEquals(Puzzles.sizeKeyFromFullType("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca"), "mini")
    lu.assertEquals(Puzzles.sizeKeyFromFullType("BoardGamesAndPuzzlesMod.Puzzle500_Boat"), "small")
    lu.assertEquals(Puzzles.sizeKeyFromFullType("BoardGamesAndPuzzlesMod.Puzzle1000_Space"), "medium")
    lu.assertEquals(Puzzles.sizeKeyFromFullType("BoardGamesAndPuzzlesMod.Puzzle2000_Aurora"), "large")

    lu.assertNil(Puzzles.sizeKeyFromFullType(nil))
    lu.assertNil(Puzzles.sizeKeyFromFullType("Base.Hammer"))
end

function TestBGP_Puzzles:testIsPuzzle()
    lu.assertTrue(Puzzles.isPuzzle("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca"))
    lu.assertTrue(Puzzles.isPuzzle("BoardGamesAndPuzzlesMod.Puzzle2000_Waterfall"))
    lu.assertFalse(Puzzles.isPuzzle("Base.Hammer"))
    lu.assertFalse(Puzzles.isPuzzle(nil))
end

function TestBGP_Puzzles:testGetSizeDefByFullType()
    lu.assertIs(Puzzles.getSizeDefByFullType("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca"), Puzzles.Size.Mini)
    lu.assertIs(Puzzles.getSizeDefByFullType("BoardGamesAndPuzzlesMod.Puzzle500_Boat"), Puzzles.Size.Small)
    lu.assertIs(Puzzles.getSizeDefByFullType("BoardGamesAndPuzzlesMod.Puzzle1000_Blossoms"), Puzzles.Size.Medium)
    lu.assertIs(Puzzles.getSizeDefByFullType("BoardGamesAndPuzzlesMod.Puzzle2000_Aurora"), Puzzles.Size.Large)

    lu.assertNil(Puzzles.getSizeDefByFullType("Base.Hammer"))
    lu.assertNil(Puzzles.getSizeDefByFullType(nil))
end

function TestBGP_Puzzles:testGetHumanNameByFullType()
    lu.assertEquals(Puzzles.getHumanNameByFullType("BoardGamesAndPuzzlesMod.Puzzle20_Alpaca"), "Alpaca")
    lu.assertEquals(Puzzles.getHumanNameByFullType("BoardGamesAndPuzzlesMod.Puzzle20_Smiles"), "Smiley Faces")
    lu.assertEquals(Puzzles.getHumanNameByFullType("BoardGamesAndPuzzlesMod.Puzzle2000_WinterTrees"), "Winter Trees")

    lu.assertNil(Puzzles.getHumanNameByFullType("Base.Hammer"))
    lu.assertNil(Puzzles.getHumanNameByFullType(nil))
end

function TestBGP_Puzzles:testDesignFullTypesAreUnique()
    local seen = {}
    for _, d in pairs(Puzzles.Design) do
        lu.assertNil(seen[d.fullType], "Duplicate fullType in designs: " .. tostring(d.fullType))
        seen[d.fullType] = true
    end
end

return TestBGP_Puzzles