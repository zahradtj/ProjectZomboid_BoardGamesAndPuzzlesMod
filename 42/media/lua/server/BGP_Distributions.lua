-- server/BGP_Distributions.lua
-- Drop-in replacement: baseline spawn everywhere + category-weight boosts in themed containers.
-- Works with design-specific puzzle fullTypes (Puzzle20_Alpaca, Puzzle500_Boat, etc.)
-- Requires BGP_Puzzles.lua to be loadable on server (put it in media/lua/shared/).

require "Items/ProceduralDistributions"
require "Items/SuburbsDistributions"       -- provides Distributions
require "Items/Distributions"
require "Items/ItemPicker"

local BoardGame = require("BoardGame")
local BoardGameCategory = require("BoardGameCategoryEnum")
local Puzzles = require("BGP_Puzzles")

-- ----------------------------
-- Helpers: insert into loot tables
-- ----------------------------

local function addToProcedural(listName, fullType, weight)
    local dist = ProceduralDistributions.list[listName]
    if not dist or not dist.items then
        print("[BGP] Missing ProceduralDistributions.list[" .. tostring(listName) .. "]")
        return false
    end
    table.insert(dist.items, fullType)
    table.insert(dist.items, weight)
    return true
end

local function addToDistTable(path, fullType, weight)
    local t = Distributions
    for i = 1, #path do
        t = t and t[path[i]]
    end
    if not t or not t.items then
        print("[BGP] Missing Distributions." .. table.concat(path, "."))
        return false
    end
    table.insert(t.items, fullType)
    table.insert(t.items, weight)
    return true
end

-- ----------------------------
-- Items: board games
-- ----------------------------

local GAMES = {
    { BoardGame.AxisAndAllies,        0.25 },
    { BoardGame.B17QueenOfTheSkies,   0.15 },
    { BoardGame.Backgammon,           1.2  },
    { BoardGame.Boggle,               0.9  },
    { BoardGame.CandyLand,            1.0  },
    { BoardGame.Checkers,             1.4  },
    { BoardGame.Chess,                1.0  },
    { BoardGame.Clue,                 0.6  },
    { BoardGame.Go,                   0.35 },
    { BoardGame.Mastermind,           0.9  },
    { BoardGame.Monopoly,             0.8  },
    { BoardGame.Operation,            0.6  },
    { BoardGame.Risk,                 0.5  },
    { BoardGame.Scrabble,             0.7  },
    { BoardGame.SnakesAndLadders,     0.9  },
    { BoardGame.Sorry,                0.9  },
    { BoardGame.TheGameOfLife,        0.7  },
    { BoardGame.TrivialPursuit,       0.6  },
    { BoardGame.Trouble,              0.9  },
    { BoardGame.Yahtzee,              1.6  },
}

-- Base weight per puzzle *size* (total weight per size is stable; split across designs)
local PUZZLE_SIZE_WEIGHT = {
    mini   = 1.3,
    small  = 1.0,
    medium = 0.7,
    large  = 0.35,
}

local function buildPuzzles()
    local out = {}
    for sizeKey, baseW in pairs(PUZZLE_SIZE_WEIGHT) do
        local designs = Puzzles.getDesignsForSize(sizeKey)
        local per = baseW / math.max(1, #designs)
        for _, d in ipairs(designs) do
            if d.fullType then
                out[#out+1] = { d.fullType, per }
            end
        end
    end
    return out
end

local PUZZLES = buildPuzzles()

-- Combined list of spawnables: { {fullType, weight}, ... }
local ITEMS = {}
for _, e in ipairs(GAMES) do ITEMS[#ITEMS+1] = e end
for _, e in ipairs(PUZZLES) do ITEMS[#ITEMS+1] = e end

-- Quick lookup fullType -> base weight
local BASE_WEIGHT = {}
for _, e in ipairs(ITEMS) do
    BASE_WEIGHT[e[1]] = e[2]
end

-- ----------------------------
-- Category mapping (board games explicitly; puzzles derived by size)
-- ----------------------------

local CATEGORY = {
    -- kids/family
    [BoardGame.CandyLand]        = BoardGameCategory.Kids,
    [BoardGame.SnakesAndLadders] = BoardGameCategory.Kids,
    [BoardGame.Sorry]            = BoardGameCategory.Kids,
    [BoardGame.Trouble]          = BoardGameCategory.Kids,

    -- family (non-kid)
    [BoardGame.Checkers]         = BoardGameCategory.Family,
    [BoardGame.Chess]            = BoardGameCategory.Family,
    [BoardGame.Monopoly]         = BoardGameCategory.Family,
    [BoardGame.Yahtzee]          = BoardGameCategory.Family,

    -- brain games
    [BoardGame.Backgammon]       = BoardGameCategory.Brain,
    [BoardGame.Boggle]           = BoardGameCategory.Brain,
    [BoardGame.Clue]             = BoardGameCategory.Brain,
    [BoardGame.Mastermind]       = BoardGameCategory.Brain,
    [BoardGame.Scrabble]         = BoardGameCategory.Brain,
    [BoardGame.TrivialPursuit]   = BoardGameCategory.Brain,

    -- hobby / niche
    [BoardGame.AxisAndAllies]      = BoardGameCategory.Hobby,
    [BoardGame.B17QueenOfTheSkies] = BoardGameCategory.Hobby,
    [BoardGame.Go]                 = BoardGameCategory.Hobby,
    [BoardGame.Risk]               = BoardGameCategory.Hobby,

    -- misc
    [BoardGame.MakeshiftStrategy]  = BoardGameCategory.Misc,
    [BoardGame.Operation]          = BoardGameCategory.Misc,
}

local function categoryFor(fullType)
    local cat = CATEGORY[fullType]
    if cat then return cat end

    -- puzzles: derive by size prefix
    local sizeKey = Puzzles.sizeKeyFromFullType(fullType)
    if sizeKey == "mini" then return BoardGameCategory.Kids end
    if sizeKey == "small" or sizeKey == "medium" then return BoardGameCategory.Family end
    if sizeKey == "large" then return BoardGameCategory.Hobby end

    return BoardGameCategory.Misc
end

-- ----------------------------
-- Where items can spawn
-- ----------------------------

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

-- These are *boost* containers only (they don't need to cover everything)
local CONTAINER_GROUPS = {
    kids = {
        "DaycareShelves", "BedroomDresserChild", "BedroomSidetableChild",
        "WardrobeChild", "CrateToys", "GiftStoreToys", "GigamartToys", "BookstoreChilds",
    },
    hobby = {
        "Hobbies", "BookstoreHobbies", "ComicStoreShelfGames", "ComicStoreCounter",
    },
    home = {
        "LivingRoomShelf", "LivingRoomSideTable", "BedroomSidetable", "BedroomDresser",
        "KitchenRandom", "CrateRandomJunk",
    },
    school = {
        "ClassroomShelves", "ClassroomMisc", "SchoolLockers",
    },
}

-- Multipliers by (group -> category)
local MULT = {
    kids  = { kids=1.8, family=1.3, brain=0.9, hobby=0.4, misc=1.0 },
    hobby = { kids=0.6, family=0.9, brain=1.2, hobby=2.0, misc=1.0 },
    home  = { kids=1.0, family=1.0, brain=1.0, hobby=0.7, misc=1.0 },
    school= { kids=0.8, family=0.9, brain=1.3, hobby=0.5, misc=1.0 },
}

-- ----------------------------
-- Distribution_* tables (non-procedural)
-- ----------------------------

local DIST_TABLES = {
    { "BagsAndContainers", "Parcel_Small" },
    { "BagsAndContainers", "Parcel_Medium" },
    { "ClutterTables", "BinItems" },
    { "ClutterTables", "ClosetJunk" },
}

-- ----------------------------
-- Baseline injection: everything into every procedural location
-- ----------------------------

local function injectBaseline()
    for _, listName in ipairs(PROCEDURAL_ALL) do
        for fullType, baseW in pairs(BASE_WEIGHT) do
            addToProcedural(listName, fullType, baseW)
        end
    end
end

-- ----------------------------
-- Boost injection: add extra weight based on category in themed containers
-- ----------------------------

local function injectBoosts()
    for groupName, containers in pairs(CONTAINER_GROUPS) do
        local mult = MULT[groupName] or {}
        for _, listName in ipairs(containers) do
            for fullType, baseW in pairs(BASE_WEIGHT) do
                local cat = categoryFor(fullType)         -- enum value: "kids"/"family"/...
                local m = mult[cat] or 1.0                -- MULT keys match enum values
                local extra = baseW * (m - 1.0)           -- add delta over baseline
                if extra > 0 then
                    addToProcedural(listName, fullType, extra)
                end
            end
        end
    end
end

-- ----------------------------
-- Special-case: clue in police filing cabinet
-- ----------------------------

local function injectSpecialCases()
    addToProcedural("PoliceFilingCabinet", BoardGame.Clue, 0.15)
end

-- ----------------------------
-- Parcels + clutter tables
-- ----------------------------

local function injectDistTables()
    for _, path in ipairs(DIST_TABLES) do
        for fullType, baseW in pairs(BASE_WEIGHT) do
            addToDistTable(path, fullType, baseW * 0.35)
        end
    end
end

-- ----------------------------
-- Run injections
-- ----------------------------

injectBaseline()
injectBoosts()
injectSpecialCases()
injectDistTables()