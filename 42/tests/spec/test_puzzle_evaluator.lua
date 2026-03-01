-- tests/spec/test_puzzle_evaluator.lua
-- LuaUnit tests for media/lua/client/BoardGamesAndPuzzles/BGP_PuzzleEvaluator.lua

local lu = require("luaunit")

-- -------------------------------------------------------
-- Helpers / fakes
-- -------------------------------------------------------

local function makePlayer()
    return { id = "player" }
end

local function makeItem(fullType, md)
    md = md or {}
    return {
        getFullType = function() return fullType end,
        getModData = function() return md end,
    }
end

local function makeWorldItemObj()
    return { id = "worldItem" }
end

local function installStubs(opts)
    opts = opts or {}

    local puzzles = opts.puzzles or {}
    local req = opts.req or {}
    local core = opts.core or {}
    local pm = opts.pm or {}

    local calls = {
        puzzles = {},
        req = {},
        core = {},
        pm = {},
    }

    -- BGP_Puzzles
    package.loaded["BGP_Puzzles"] = {
        isPuzzle = function(fullType)
            table.insert(calls.puzzles, { fn = "isPuzzle", fullType = fullType })
            if puzzles.isPuzzle ~= nil then return puzzles.isPuzzle end
            return false
        end
    }

    -- BGP_Requirements
    package.loaded["BGP_Requirements"] = {
        isCharacterNearWorldItem = function(playerObj, worldItemObj)
            table.insert(calls.req, { fn = "near", player = playerObj, world = worldItemObj })
            if req.near ~= nil then return req.near end
            return true
        end,
        hasNearbySurface = function(playerObj, radius)
            table.insert(calls.req, { fn = "surface", player = playerObj, radius = radius })
            if req.surface ~= nil then return req.surface end
            return true
        end,
        hasEnoughLight = function(playerObj, minLevel)
            table.insert(calls.req, { fn = "light", player = playerObj, min = minLevel })
            if req.light ~= nil then return req.light end
            return true
        end,
    }

    -- helpers/Puzzle_ProgressManager
    package.loaded["helpers/Puzzle_ProgressManager"] = {
        getProgress = function(md)
            table.insert(calls.pm, { fn = "getProgress", md = md })
            if pm.progress ~= nil then return pm.progress end
            -- default: initialize if missing like real code
            if md.bgpPuzzleProgress == nil then md.bgpPuzzleProgress = 0 end
            return md.bgpPuzzleProgress
        end
    }

    -- BGP_PuzzlesCore
    package.loaded["BGP_PuzzlesCore"] = {
        updateName = function(item)
            table.insert(calls.core, { fn = "updateName", item = item })
            if core.updateNameRet ~= nil then return core.updateNameRet end
        end,
        canWorkNow = function(playerObj, item)
            table.insert(calls.core, { fn = "canWorkNow", player = playerObj, item = item })
            if core.canWorkNow ~= nil then
                return core.canWorkNow.ok, core.canWorkNow.tooltip
            end
            return true, nil
        end,
        getWorkTuning = function(playerObj, item)
            table.insert(calls.core, { fn = "getWorkTuning", player = playerObj, item = item })
            if core.tuning ~= nil then return core.tuning end
            return { duration = 123, requireSurface = true, requireLight = true }
        end,
    }

    return calls
end

local function reloadEvaluator()
    package.loaded["BGP_PuzzleEvaluator"] = nil
    return require("BGP_PuzzleEvaluator")
end

-- -------------------------------------------------------
-- Tests
-- -------------------------------------------------------

TestBGP_PuzzleEvaluator = {}

function TestBGP_PuzzleEvaluator:setUp()
    -- clear module under test between tests
    package.loaded["BGP_PuzzleEvaluator"] = nil
end

function TestBGP_PuzzleEvaluator:testReturnsNilWhenItemMissing()
    installStubs({
        puzzles = { isPuzzle = true }
    })
    local Eval = reloadEvaluator()

    local res = Eval.evaluate(makePlayer(), nil, nil)
    lu.assertNil(res)
end

function TestBGP_PuzzleEvaluator:testReturnsNilWhenNotAPuzzle()
    local calls = installStubs({
        puzzles = { isPuzzle = false }
    })
    local Eval = reloadEvaluator()

    local item = makeItem("Mod.NotPuzzle", {})
    local res = Eval.evaluate(makePlayer(), item, nil)

    lu.assertNil(res)
    lu.assertEquals(#calls.puzzles, 1)
    lu.assertEquals(calls.puzzles[1].fn, "isPuzzle")
end

function TestBGP_PuzzleEvaluator:testReturnsNotOkWhenProgressComplete()
    local calls = installStubs({
        puzzles = { isPuzzle = true },
        pm = { progress = 1 },
    })
    local Eval = reloadEvaluator()

    local item = makeItem("Mod.Puzzle", {})
    local res = Eval.evaluate(makePlayer(), item, nil)

    lu.assertNotNil(res)
    lu.assertFalse(res.ok)
    lu.assertEquals(res.label, "Work on Puzzle")
    lu.assertEquals(res.tooltip[1], "Cannot work:")
    lu.assertEquals(res.tooltip[2], "- Puzzle already complete.")

    -- should not call requirements/core when already complete
    lu.assertEquals(#calls.req, 0)
    lu.assertEquals(#calls.core, 0)
end

function TestBGP_PuzzleEvaluator:testAddsTooFarWhenWorldItemProvidedAndNotNear()
    local calls = installStubs({
        puzzles = { isPuzzle = true },
        pm = { progress = 0 },
        req = { near = false, surface = true, light = true },
    })
    local Eval = reloadEvaluator()

    local player = makePlayer()
    local item = makeItem("Mod.Puzzle", {})
    local w = makeWorldItemObj()

    local res = Eval.evaluate(player, item, w)

    lu.assertFalse(res.ok)
    lu.assertEquals(res.tooltip[1], "Cannot work right now:")
    lu.assertEquals(res.tooltip[2], "- Too far away.")

    -- ensure near check was called
    lu.assertEquals(calls.req[1].fn, "near")
    lu.assertIs(calls.req[1].player, player)
    lu.assertIs(calls.req[1].world, w)
end

function TestBGP_PuzzleEvaluator:testMissingSurfaceAndLightProduceDisabledTooltip()
    installStubs({
        puzzles = { isPuzzle = true },
        pm = { progress = 0 },
        req = { surface = false, light = false },
    })
    local Eval = reloadEvaluator()

    local res = Eval.evaluate(makePlayer(), makeItem("Mod.Puzzle", {}), nil)

    lu.assertFalse(res.ok)
    lu.assertEquals(res.tooltip[1], "Cannot work right now:")
    lu.assertEquals(res.tooltip[2], "- Requires a nearby surface (table).")
    lu.assertEquals(res.tooltip[3], "- Not enough light.")
end

function TestBGP_PuzzleEvaluator:testWhenReqPassesCallsUpdateNameThenCanWorkNowAndMayFailThere()
    local calls = installStubs({
        puzzles = { isPuzzle = true },
        pm = { progress = 0 },
        req = { surface = true, light = true },
        core = { canWorkNow = { ok = false, tooltip = { "Nope" } } }
    })
    local Eval = reloadEvaluator()

    local player = makePlayer()
    local item = makeItem("Mod.Puzzle", {})

    local res = Eval.evaluate(player, item, nil)

    lu.assertFalse(res.ok)
    lu.assertEquals(res.label, "Work on Puzzle")
    lu.assertEquals(res.tooltip[1], "Nope")

    -- Core.updateName called before canWorkNow
    lu.assertEquals(#calls.core, 2)
    lu.assertEquals(calls.core[1].fn, "updateName")
    lu.assertEquals(calls.core[2].fn, "canWorkNow")
end

function TestBGP_PuzzleEvaluator:testSuccessReturnsDurationAndTuning()
    local tuning = { duration = 777, increment = 0.1 }
    local calls = installStubs({
        puzzles = { isPuzzle = true },
        pm = { progress = 0 },
        req = { surface = true, light = true, near = true },
        core = { canWorkNow = { ok = true }, tuning = tuning }
    })
    local Eval = reloadEvaluator()

    local player = makePlayer()
    local item = makeItem("Mod.Puzzle", {})
    local w = makeWorldItemObj()

    local res = Eval.evaluate(player, item, w)

    lu.assertTrue(res.ok)
    lu.assertEquals(res.label, "Work on Puzzle")
    lu.assertEquals(res.duration, 777)
    lu.assertIs(res.tuning, tuning)

    -- verify expected calls happened
    -- near + surface + light, then updateName + canWorkNow + getWorkTuning
    lu.assertTrue(#calls.req >= 3)
    lu.assertEquals(calls.core[1].fn, "updateName")
    lu.assertEquals(calls.core[2].fn, "canWorkNow")
    lu.assertEquals(calls.core[3].fn, "getWorkTuning")
end

return TestBGP_PuzzleEvaluator