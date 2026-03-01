-- tests/spec/test_menu_handlers.lua
-- LuaUnit tests for media/lua/client/BoardGamesAndPuzzles/BGP_MenuHandlers.lua

local lu = require("luaunit")

-- -----------------------
-- Test helpers / fakes
-- -----------------------

local function makeContext()
    local ctx = { options = {} }
    function ctx:addOption(label, target, callback)
        local opt = { label = label, target = target, callback = callback }
        table.insert(self.options, opt)
        return opt
    end
    return ctx
end

local function makeItem(fullType)
    return {
        getFullType = function() return fullType end,
        getModData = function()
            return {} -- overridden via PM stub in tests that need progress
        end
    }
end

local function makeWorldObj(item)
    return {
        _item = item,
        getItem = function(self) return self._item end,
        -- MenuHandlers doesn't call getSquare(), but other code might later; safe to include nil
        getSquare = function() return nil end,
    }
end

-- -----------------------
-- Stub installer
-- -----------------------

local function installStubs(opts)
    opts = opts or {}

    local eval = opts.eval or { returnValue = nil, calls = {} }
    local puzzleEval = opts.puzzleEval or { returnValue = nil, calls = {} }
    local defs = opts.game_defs or {}
    local tooltipCalls = opts.tooltipCalls or {}
    local queueAdds = opts.queueAdds or {}
    local ctorCalls = opts.ctorCalls or {}
    local pmCalls = opts.pmCalls or {}
    local coreCalls = opts.coreCalls or {}

    local isPuzzleFn = opts.isPuzzleFn or function(_) return false end
    local getProgressFn = opts.getProgressFn or function(_) return 0 end

    -- global PZ-ish helpers used by MenuHandlers.lua
    _G.getSpecificPlayer = opts.getSpecificPlayer or function(_) return { id = "player" } end
    _G.instanceof = opts.instanceof or function(obj, className)
        return className == "IsoWorldInventoryObject" and type(obj) == "table" and obj.getItem ~= nil
    end

    -- Stub Tooltips module
    package.loaded["BGP_Tooltips"] = {
        addDisabledOptionWithTooltip = function(context, label, lines)
            table.insert(tooltipCalls, { context = context, label = label, lines = lines })
            return { notAvailable = true, label = label, lines = lines }
        end
    }

    -- Stub Game evaluator
    package.loaded["BGP_GameEvaluator"] = {
        evaluate = function(playerObj, item, worldItemObj)
            table.insert(eval.calls, { playerObj = playerObj, item = item, worldItemObj = worldItemObj })
            return eval.returnValue
        end
    }

    -- Stub Puzzle evaluator
    package.loaded["BGP_PuzzleEvaluator"] = {
        evaluate = function(playerObj, item, worldItemObj)
            table.insert(puzzleEval.calls, { playerObj = playerObj, item = item, worldItemObj = worldItemObj })
            return puzzleEval.returnValue
        end
    }

    -- Stub GameDefs module (used to gate world menu by fullType)
    package.loaded["BGP_GameDefs"] = { GAME_DEFS = defs }

    -- Stub Puzzles module (used to gate puzzle branch + isPuzzle(ft))
    package.loaded["BGP_Puzzles"] = {
        isPuzzle = function(ft) return isPuzzleFn(ft) end
    }

    -- Stub ProgressManager
    package.loaded["helpers/Puzzle_ProgressManager"] = {
        getProgress = function(md)
            table.insert(pmCalls, { fn = "getProgress", md = md })
            return getProgressFn(md)
        end,
        setProgress = function(md, v)
            table.insert(pmCalls, { fn = "setProgress", md = md, v = v })
            md._progress = v
        end,
    }

    -- Stub Core for resetPuzzle()
    package.loaded["BGP_PuzzlesCore"] = {
        syncItemModData = function(item)
            table.insert(coreCalls, { fn = "syncItemModData", item = item })
        end,
        updateName = function(item)
            table.insert(coreCalls, { fn = "updateName", item = item })
        end
    }

    -- Timed action queue + action constructors
    _G.ISTimedActionQueue = {
        add = function(action)
            table.insert(queueAdds, action)
        end
    }

    _G.ISPlayBoardGameFromInventory = {
        new = function(_, p, item, duration, boredomReduce, unhappyReduce, stressReduce)
            table.insert(ctorCalls, {
                which = "play_inv",
                p = p, item = item, duration = duration,
                boredom = boredomReduce, unhappy = unhappyReduce, stress = stressReduce
            })
            return { kind = "play_inv_action" }
        end
    }

    _G.ISPlayBoardGameFromGround = {
        new = function(_, p, worldItemObj, item, duration, boredomReduce, unhappyReduce, stressReduce)
            table.insert(ctorCalls, {
                which = "play_ground",
                p = p, worldItemObj = worldItemObj, item = item, duration = duration,
                boredom = boredomReduce, unhappy = unhappyReduce, stress = stressReduce
            })
            return { kind = "play_ground_action" }
        end
    }

    _G.ISWorkPuzzleFromInventory = {
        new = function(_, p, item, duration, tuning)
            table.insert(ctorCalls, {
                which = "puzzle_inv",
                p = p, item = item, duration = duration, tuning = tuning
            })
            return { kind = "puzzle_inv_action" }
        end
    }

    _G.ISWorkPuzzleFromGround = {
        new = function(_, p, worldItemObj, item, duration, tuning)
            table.insert(ctorCalls, {
                which = "puzzle_ground",
                p = p, worldItemObj = worldItemObj, item = item, duration = duration, tuning = tuning
            })
            return { kind = "puzzle_ground_action" }
        end
    }

    -- Required-by-name placeholders so require doesn't error
    package.loaded["TimedActions/ISTimedActionQueue"] = true
    package.loaded["TimedActions/ISPlayBoardGameFromInventory"] = true
    package.loaded["TimedActions/ISPlayBoardGameFromGround"] = true
    package.loaded["TimedActions/ISWorkPuzzleFromInventory"] = true
    package.loaded["TimedActions/ISWorkPuzzleFromGround"] = true

    return {
        eval = eval,
        puzzleEval = puzzleEval,
        tooltipCalls = tooltipCalls,
        queueAdds = queueAdds,
        ctorCalls = ctorCalls,
        pmCalls = pmCalls,
        coreCalls = coreCalls,
    }
end

local function reloadMenuHandlers()
    package.loaded["BGP_MenuHandlers"] = nil
    return require("BGP_MenuHandlers")
end

-- -----------------------
-- Tests
-- -----------------------

TestBGP_MenuHandlers = {}

-- ---- Inventory menu --------------------------------------------------

function TestBGP_MenuHandlers:testInventoryMenuReturnsEarlyWhenNoPlayer()
    local ctx = makeContext()
    local t = installStubs({
        getSpecificPlayer = function(_) return nil end,
        eval = { returnValue = { ok = true }, calls = {} },
        puzzleEval = { returnValue = { ok = true }, calls = {} },
        game_defs = {},
        isPuzzleFn = function() return true end,
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillInventoryObjectContextMenu(0, ctx, { makeItem("Mod.Game") })

    lu.assertEquals(#ctx.options, 0)
    lu.assertEquals(#t.eval.calls, 0)
    lu.assertEquals(#t.puzzleEval.calls, 0)
end

function TestBGP_MenuHandlers:testInventoryMenuUnwrapsEntryItemsTable()
    local ctx = makeContext()
    local item = makeItem("Mod.Game")
    local t = installStubs({
        eval = { returnValue = nil, calls = {} },
        puzzleEval = { returnValue = nil, calls = {} },
        game_defs = {},
        isPuzzleFn = function() return false end,
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillInventoryObjectContextMenu(0, ctx, { { items = { item } } })

    lu.assertEquals(#t.eval.calls, 1)
    lu.assertIs(t.eval.calls[1].item, item)
end

function TestBGP_MenuHandlers:testInventoryMenuAddsDisabledOptionForGameWhenEvalNotOk()
    local ctx = makeContext()
    local t = installStubs({
        eval = { returnValue = { ok = false, label = "Play Chess", tooltip = { "Nope" } }, calls = {} },
        puzzleEval = { returnValue = nil, calls = {} },
        isPuzzleFn = function() return false end,
        game_defs = {},
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillInventoryObjectContextMenu(0, ctx, { makeItem("Mod.Chess") })

    lu.assertEquals(#t.tooltipCalls, 1)
    lu.assertEquals(t.tooltipCalls[1].label, "Play Chess")
    lu.assertEquals(#ctx.options, 0)
end

function TestBGP_MenuHandlers:testInventoryMenuAddsPlayOptionAndCallbackEnqueuesInventoryAction()
    local ctx = makeContext()
    local item = makeItem("Mod.Chess")
    local t = installStubs({
        eval = {
            returnValue = { ok = true, label = "Play Chess", duration = 123, boredom = 10, unhappy = 5, stress = 0.2 },
            calls = {}
        },
        puzzleEval = { returnValue = nil, calls = {} },
        isPuzzleFn = function() return false end,
        game_defs = {},
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillInventoryObjectContextMenu(0, ctx, { item })

    lu.assertEquals(#ctx.options, 1)
    lu.assertEquals(ctx.options[1].label, "Play Chess")

    ctx.options[1].callback(_G.getSpecificPlayer(0))

    lu.assertEquals(#t.ctorCalls, 1)
    lu.assertEquals(t.ctorCalls[1].which, "play_inv")
    lu.assertIs(t.ctorCalls[1].item, item)
    lu.assertEquals(t.ctorCalls[1].duration, 123)

    lu.assertEquals(#t.queueAdds, 1)
    lu.assertEquals(t.queueAdds[1].kind, "play_inv_action")
end

function TestBGP_MenuHandlers:testInventoryMenuAddsPuzzleWorkOptionWhenPuzzleEvalOk()
    local ctx = makeContext()
    local item = makeItem("Mod.Puzzle20_Alpaca")
    local tuning = { workEveryMs = 2500 }
    local t = installStubs({
        eval = { returnValue = nil, calls = {} },
        puzzleEval = {
            returnValue = { ok = true, label = "Work on Puzzle", duration = 456, tuning = tuning },
            calls = {}
        },
        isPuzzleFn = function(ft) return ft:find("Puzzle", 1, true) ~= nil end,
        game_defs = {},
        getProgressFn = function() return 0 end,
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillInventoryObjectContextMenu(0, ctx, { item })

    lu.assertEquals(#ctx.options, 1)
    lu.assertEquals(ctx.options[1].label, "Work on Puzzle")

    ctx.options[1].callback(_G.getSpecificPlayer(0))

    lu.assertEquals(#t.ctorCalls, 1)
    lu.assertEquals(t.ctorCalls[1].which, "puzzle_inv")
    lu.assertEquals(t.ctorCalls[1].duration, 456)
    lu.assertIs(t.ctorCalls[1].item, item)

    lu.assertEquals(#t.queueAdds, 1)
    lu.assertEquals(t.queueAdds[1].kind, "puzzle_inv_action")
end

function TestBGP_MenuHandlers:testInventoryMenuAddsPuzzleResetOptionWhenProgressGreaterThanZero()
    local ctx = makeContext()
    local item = makeItem("Mod.Puzzle500_Boat")
    local t = installStubs({
        eval = { returnValue = nil, calls = {} },
        puzzleEval = { returnValue = nil, calls = {} },
        isPuzzleFn = function() return true end,
        getProgressFn = function() return 0.25 end, -- started
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillInventoryObjectContextMenu(0, ctx, { item })

    lu.assertEquals(#ctx.options, 1)
    lu.assertEquals(ctx.options[1].label, "Take Puzzle Apart (Reset)")

    -- invoke reset callback
    ctx.options[1].callback(_G.getSpecificPlayer(0))

    -- setProgress called to 0 + Core sync + updateName
    lu.assertTrue(#t.pmCalls >= 1)
    lu.assertEquals(t.pmCalls[#t.pmCalls].fn, "setProgress")
    lu.assertEquals(t.pmCalls[#t.pmCalls].v, 0)

    lu.assertEquals(#t.coreCalls, 2)
    lu.assertEquals(t.coreCalls[1].fn, "syncItemModData")
    lu.assertEquals(t.coreCalls[2].fn, "updateName")
end

-- ---- World menu ------------------------------------------------------

function TestBGP_MenuHandlers:testWorldMenuReturnsEarlyWhenNoPlayer()
    local ctx = makeContext()
    local t = installStubs({
        getSpecificPlayer = function(_) return nil end,
        eval = { returnValue = { ok = true }, calls = {} },
        puzzleEval = { returnValue = { ok = true }, calls = {} },
        game_defs = { ["Mod.Game"] = { name = "Game" } },
        isPuzzleFn = function() return true end,
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillWorldObjectContextMenu(0, ctx, { makeWorldObj(makeItem("Mod.Game")) }, false)

    lu.assertEquals(#ctx.options, 0)
    lu.assertEquals(#t.eval.calls, 0)
    lu.assertEquals(#t.puzzleEval.calls, 0)
end

function TestBGP_MenuHandlers:testWorldMenuReturnsEarlyWhenNoWorldItemUnderCursor()
    local ctx = makeContext()
    local t = installStubs({
        instanceof = function() return false end,
        eval = { returnValue = { ok = true }, calls = {} },
        puzzleEval = { returnValue = { ok = true }, calls = {} },
        game_defs = { ["Mod.Game"] = { name = "Game" } },
        isPuzzleFn = function() return true end,
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillWorldObjectContextMenu(0, ctx, { {} }, false)

    lu.assertEquals(#ctx.options, 0)
    lu.assertEquals(#t.eval.calls, 0)
    lu.assertEquals(#t.puzzleEval.calls, 0)
end

function TestBGP_MenuHandlers:testWorldMenuTestFlagReturnsTrueWhenGameDefExists()
    local ctx = makeContext()
    local item = makeItem("Mod.Game")
    local Menu = nil

    installStubs({
        eval = { returnValue = { ok = true }, calls = {} },
        puzzleEval = { returnValue = { ok = true }, calls = {} },
        game_defs = { ["Mod.Game"] = { name = "Game" } },
        isPuzzleFn = function() return false end,
    })
    Menu = reloadMenuHandlers()

    local ret = Menu.OnFillWorldObjectContextMenu(0, ctx, { makeWorldObj(item) }, true)
    lu.assertTrue(ret)
    lu.assertEquals(#ctx.options, 0)
end

function TestBGP_MenuHandlers:testWorldMenuAddsPlayOptionAndCallbackEnqueuesGroundAction()
    local ctx = makeContext()
    local item = makeItem("Mod.Game")
    local worldObj = makeWorldObj(item)

    local t = installStubs({
        eval = {
            returnValue = { ok = true, label = "Play Game", duration = 50, boredom = 1, unhappy = 2, stress = 0.3 },
            calls = {}
        },
        puzzleEval = { returnValue = nil, calls = {} },
        game_defs = { ["Mod.Game"] = { name = "Game" } },
        isPuzzleFn = function() return false end,
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillWorldObjectContextMenu(0, ctx, { worldObj }, false)

    lu.assertEquals(#ctx.options, 1)
    lu.assertEquals(ctx.options[1].label, "Play Game")

    ctx.options[1].callback(_G.getSpecificPlayer(0))

    lu.assertEquals(#t.ctorCalls, 1)
    lu.assertEquals(t.ctorCalls[1].which, "play_ground")
    lu.assertIs(t.ctorCalls[1].worldItemObj, worldObj)
    lu.assertIs(t.ctorCalls[1].item, item)

    lu.assertEquals(#t.queueAdds, 1)
    lu.assertEquals(t.queueAdds[1].kind, "play_ground_action")

    -- Ensure evaluator got worldItemObj passed through
    lu.assertEquals(#t.eval.calls, 1)
    lu.assertIs(t.eval.calls[1].worldItemObj, worldObj)
end

function TestBGP_MenuHandlers:testWorldMenuAddsPuzzleWorkOptionAndCallbackEnqueuesGroundPuzzleAction()
    local ctx = makeContext()
    local item = makeItem("Mod.Puzzle20_Alpaca")
    local worldObj = makeWorldObj(item)
    local tuning = { workEveryMs = 2500 }

    local t = installStubs({
        eval = { returnValue = nil, calls = {} },
        puzzleEval = {
            returnValue = { ok = true, label = "Work on Puzzle", duration = 111, tuning = tuning },
            calls = {}
        },
        game_defs = {}, -- not a board game
        isPuzzleFn = function(ft) return ft:find("Puzzle", 1, true) ~= nil end,
        getProgressFn = function() return 0 end,
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillWorldObjectContextMenu(0, ctx, { worldObj }, false)

    lu.assertEquals(#ctx.options, 1)
    lu.assertEquals(ctx.options[1].label, "Work on Puzzle")

    ctx.options[1].callback(_G.getSpecificPlayer(0))

    lu.assertEquals(#t.ctorCalls, 1)
    lu.assertEquals(t.ctorCalls[1].which, "puzzle_ground")
    lu.assertIs(t.ctorCalls[1].worldItemObj, worldObj)
    lu.assertIs(t.ctorCalls[1].item, item)
    lu.assertEquals(t.ctorCalls[1].duration, 111)

    lu.assertEquals(#t.queueAdds, 1)
    lu.assertEquals(t.queueAdds[1].kind, "puzzle_ground_action")

    -- Ensure puzzle evaluator got worldItemObj passed through
    lu.assertEquals(#t.puzzleEval.calls, 1)
    lu.assertIs(t.puzzleEval.calls[1].worldItemObj, worldObj)
end

return TestBGP_MenuHandlers