local lu = require("luaunit")

-- -------------------------------------------------------------------
-- Test doubles / stubs
-- -------------------------------------------------------------------

-- CharacterTrait constants used by evaluator
_G.CharacterTrait = {
    ILLITERATE = "ILLITERATE",
    SLOW_READER = "SLOW_READER",
    FAST_READER = "FAST_READER",
    ALL_THUMBS = "ALL_THUMBS",
    CLUMSY = "CLUMSY",
    DEXTROUS = "DEXTROUS",
}

-- Helpers to build fake player/item
local function makePlayer(traits, wearingAwkwardGloves)
    traits = traits or {}
    local traitSet = {}
    for _, t in ipairs(traits) do traitSet[t] = true end

    return {
        hasTrait = function(_, trait) return traitSet[trait] == true end,
        isWearingAwkwardGloves = function(_) return wearingAwkwardGloves == true end,
    }
end

local function makeItem(fullType)
    return {
        getFullType = function(_) return fullType end,
    }
end

-- We'll swap these per-test via package.loaded
local function installStubs(opts)
    opts = opts or {}

    local defs = opts.game_defs or {}
    local req = opts.req or {}
    local op = opts.operation or {}

    package.loaded["BGP_GameDefs"] = { GAME_DEFS = defs }
    package.loaded["BGP_Requirements"] = {
        hasNearbySurface = req.hasNearbySurface or function() return true end,
        hasEnoughLight   = req.hasEnoughLight   or function() return true end,
    }

    -- Your evaluator does `require "BoardGamesAndPuzzlesMod_Operation"` (no parens),
    -- which still uses package.loaded with that exact key.
    package.loaded["BoardGamesAndPuzzlesMod_Operation"] = {
        hasBattery = op.hasBattery or function() return true end,
    }
end

local function reloadEvaluator()
    package.loaded["BGP_GameEvaluator"] = nil
    return require("BGP_GameEvaluator")
end

-- -------------------------------------------------------------------
-- Tests
-- -------------------------------------------------------------------

TestBGP_GameEvaluator = {}

function TestBGP_GameEvaluator:testReturnsNilWhenPlayerOrItemMissing()
    installStubs({ game_defs = {} })
    local Eval = reloadEvaluator()

    lu.assertNil(Eval.evaluate(nil, makeItem("X.Y")))
    lu.assertNil(Eval.evaluate(makePlayer({}), nil))
end

function TestBGP_GameEvaluator:testReturnsNilWhenItemHasNoGetFullTypeMethod()
    installStubs({ game_defs = {} })
    local Eval = reloadEvaluator()

    local badItem = {} -- no getFullType
    lu.assertNil(Eval.evaluate(makePlayer({}), badItem))
end

function TestBGP_GameEvaluator:testReturnsNilWhenFullTypeMissingOrNotInDefs()
    installStubs({ game_defs = {} })
    local Eval = reloadEvaluator()

    local itemNilType = { getFullType = function() return nil end }
    lu.assertNil(Eval.evaluate(makePlayer({}), itemNilType))

    lu.assertNil(Eval.evaluate(makePlayer({}), makeItem("Nope.NotHere")))
end

function TestBGP_GameEvaluator:testLabelIsPlayPlusNameOnSuccess()
    local ft = "Mod.Chess"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Chess",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 0.5,
                clumsyImpacted = false,
                usesBattery = false,
                default = { illiterateAllowed = true },
            }
        }
    })
    local Eval = reloadEvaluator()

    local res = Eval.evaluate(makePlayer({}), makeItem(ft))
    lu.assertTrue(res.ok)
    lu.assertEquals(res.label, "Play Chess")
end

function TestBGP_GameEvaluator:testIlliterateBlockedWhenReadingRequired()
    local ft = "Mod.TrivialPursuit"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Trivial Pursuit",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 10,
                clumsyImpacted = false,
                usesBattery = false,
                default = { illiterateAllowed = false },
            }
        }
    })
    local Eval = reloadEvaluator()

    local player = makePlayer({ CharacterTrait.ILLITERATE })
    local res = Eval.evaluate(player, makeItem(ft))

    lu.assertNotNil(res)
    lu.assertFalse(res.ok)
    lu.assertEquals(res.label, "Play Trivial Pursuit")
    lu.assertEquals(res.tooltip[1], "Cannot play:")
    lu.assertEquals(res.tooltip[2], "- Requires reading ability.")
end

function TestBGP_GameEvaluator:testIlliterateAllowedPassesLiteracyGate()
    local ft = "Mod.CandyLand"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Candy Land",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 10,
                clumsyImpacted = false,
                usesBattery = false,
                default = { illiterateAllowed = true },
            }
        }
    })
    local Eval = reloadEvaluator()

    local player = makePlayer({ CharacterTrait.ILLITERATE })
    local res = Eval.evaluate(player, makeItem(ft))
    lu.assertTrue(res.ok)
end

function TestBGP_GameEvaluator:testMissingSurfaceOrLightProducesDisabledTooltip()
    local ft = "Mod.Checkers"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Checkers",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 10,
                clumsyImpacted = false,
                usesBattery = false,
                default = { illiterateAllowed = true },
            }
        },
        req = {
            hasNearbySurface = function() return false end,
            hasEnoughLight   = function() return false end,
        }
    })
    local Eval = reloadEvaluator()

    local res = Eval.evaluate(makePlayer({}), makeItem(ft))
    lu.assertFalse(res.ok)
    lu.assertEquals(res.tooltip[1], "Cannot play right now:")
    lu.assertEquals(res.tooltip[2], "- Requires a nearby surface (table).")
    lu.assertEquals(res.tooltip[3], "- Not enough light.")
end

function TestBGP_GameEvaluator:testBatteryRequirementAddsTooltipLine()
    local ft = "Mod.Operation"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Operation",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 10,
                clumsyImpacted = false,
                usesBattery = true,
                default = { illiterateAllowed = true },
            }
        },
        operation = {
            hasBattery = function() return false end,
        }
    })
    local Eval = reloadEvaluator()

    local res = Eval.evaluate(makePlayer({}), makeItem(ft))
    lu.assertFalse(res.ok)
    lu.assertEquals(res.tooltip[1], "Cannot play right now:")
    lu.assertEquals(res.tooltip[2], "- Requires a charged battery.")
end

function TestBGP_GameEvaluator:testSlowReaderIncreasesDurationWhenReadingRequired()
    local ft = "Mod.Scrabble"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Scrabble",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 10,
                clumsyImpacted = false,
                usesBattery = false,
                default = { illiterateAllowed = false }, -- requires reading
            }
        }
    })
    local Eval = reloadEvaluator()

    local player = makePlayer({ CharacterTrait.SLOW_READER })
    local res = Eval.evaluate(player, makeItem(ft))
    lu.assertTrue(res.ok)
    lu.assertEquals(res.duration, math.floor(100 * 1.5))
end

function TestBGP_GameEvaluator:testFastReaderDecreasesDurationWhenReadingRequired()
    local ft = "Mod.Scrabble"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Scrabble",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 10,
                clumsyImpacted = false,
                usesBattery = false,
                default = { illiterateAllowed = false }, -- requires reading
            }
        }
    })
    local Eval = reloadEvaluator()

    local player = makePlayer({ CharacterTrait.FAST_READER })
    local res = Eval.evaluate(player, makeItem(ft))
    lu.assertTrue(res.ok)
    lu.assertEquals(res.duration, math.floor(100 * 0.5))
end

function TestBGP_GameEvaluator:testReaderTraitsDoNotAffectDurationWhenIlliterateAllowed()
    local ft = "Mod.CandyLand"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Candy Land",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 10,
                clumsyImpacted = false,
                usesBattery = false,
                default = { illiterateAllowed = true }, -- not treated as “requires reading”
            }
        }
    })
    local Eval = reloadEvaluator()

    local slow = Eval.evaluate(makePlayer({ CharacterTrait.SLOW_READER }), makeItem(ft))
    local fast = Eval.evaluate(makePlayer({ CharacterTrait.FAST_READER }), makeItem(ft))
    lu.assertEquals(slow.duration, 100)
    lu.assertEquals(fast.duration, 100)
end

function TestBGP_GameEvaluator:testClumsyImpactedIncreasesDuration()
    local ft = "Mod.Operation"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Operation",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 10,
                clumsyImpacted = true,
                usesBattery = false,
                default = { illiterateAllowed = true },
            }
        }
    })
    local Eval = reloadEvaluator()

    local clumsy = makePlayer({ CharacterTrait.CLUMSY })
    local res = Eval.evaluate(clumsy, makeItem(ft))
    lu.assertEquals(res.duration, math.floor(100 * 1.25))
end

function TestBGP_GameEvaluator:testAllThumbsOrAwkwardGlovesAlsoIncreaseDuration()
    local ft = "Mod.Operation"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Operation",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 10,
                clumsyImpacted = true,
                usesBattery = false,
                default = { illiterateAllowed = true },
            }
        }
    })
    local Eval = reloadEvaluator()

    local thumbs = Eval.evaluate(makePlayer({ CharacterTrait.ALL_THUMBS }), makeItem(ft))
    lu.assertEquals(thumbs.duration, math.floor(100 * 1.25))

    local gloves = Eval.evaluate(makePlayer({}, true), makeItem(ft))
    lu.assertEquals(gloves.duration, math.floor(100 * 1.25))
end

function TestBGP_GameEvaluator:testDextrousDecreasesDurationWhenClumsyImpacted()
    local ft = "Mod.Operation"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Operation",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 10,
                clumsyImpacted = true,
                usesBattery = false,
                default = { illiterateAllowed = true },
            }
        }
    })
    local Eval = reloadEvaluator()

    local dex = Eval.evaluate(makePlayer({ CharacterTrait.DEXTROUS }), makeItem(ft))
    lu.assertEquals(dex.duration, math.floor(100 * 0.75))
end

function TestBGP_GameEvaluator:testStressReduceNormalizedWhenPercentStyle()
    local ft = "Mod.Chess"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Chess",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = 12, -- percent style
                clumsyImpacted = false,
                usesBattery = false,
                default = { illiterateAllowed = true },
            }
        }
    })
    local Eval = reloadEvaluator()

    local res = Eval.evaluate(makePlayer({}), makeItem(ft))
    lu.assertTrue(res.ok)
    lu.assertEquals(res.stress, 0.12)
end

function TestBGP_GameEvaluator:testStressReduceDefaultsToPointZeroEightWhenNil()
    local ft = "Mod.Chess"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Chess",
                duration = 100,
                boredomReduce = 1,
                unhappyReduce = 2,
                stressReduce = nil,
                clumsyImpacted = false,
                usesBattery = false,
                default = { illiterateAllowed = true },
            }
        }
    })
    local Eval = reloadEvaluator()

    local res = Eval.evaluate(makePlayer({}), makeItem(ft))
    lu.assertTrue(res.ok)
    lu.assertEquals(res.stress, 0.08)
end

function TestBGP_GameEvaluator:testPassesThroughMoodValues()
    local ft = "Mod.Go"
    installStubs({
        game_defs = {
            [ft] = {
                name = "Go",
                duration = 100,
                boredomReduce = 22,
                unhappyReduce = 10,
                stressReduce = 0.2,
                clumsyImpacted = false,
                usesBattery = false,
                default = { illiterateAllowed = true },
            }
        }
    })
    local Eval = reloadEvaluator()

    local res = Eval.evaluate(makePlayer({}), makeItem(ft))
    lu.assertEquals(res.boredom, 22)
    lu.assertEquals(res.unhappy, 10)
    lu.assertEquals(res.stress, 0.2)
end

return TestBGP_GameEvaluator
