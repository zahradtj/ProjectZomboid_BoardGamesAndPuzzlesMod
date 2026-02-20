-- tests/spec/test_menu_handlers.lua
-- LuaUnit tests for media/lua/client/BoardGamesAndPuzzles/BGP_MenuHandlers.lua

local lu = require("luaunit")

-- -----------------------
-- Test helpers / stubs
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
    }
end

local function makeWorldObj(item)
    return {
        _item = item,
        getItem = function(self) return self._item end,
    }
end

local function installStubs(opts)
    opts = opts or {}
    local eval = opts.eval or {}
    local defs = opts.game_defs or {}
    local tooltipCalls = opts.tooltipCalls or {}
    local queueAdds = opts.queueAdds or {}
    local ctorCalls = opts.ctorCalls or {}

    -- global PZ-ish helpers used by MenuHandlers.lua
    _G.getSpecificPlayer = opts.getSpecificPlayer or function(_) return { id = "player" } end
    _G.instanceof = opts.instanceof or function(obj, className)
        -- Treat our makeWorldObj(...) objects as IsoWorldInventoryObject by default
        return className == "IsoWorldInventoryObject" and type(obj) == "table" and obj.getItem ~= nil
    end

    -- Stub Tooltips module
    package.loaded["BGP_Tooltips"] = {
        addDisabledOptionWithTooltip = function(context, label, lines)
            table.insert(tooltipCalls, { context = context, label = label, lines = lines })
            -- in-game this would add a disabled option; for tests we just record call
            return { notAvailable = true, label = label, lines = lines }
        end
    }

    -- Stub Evaluator module
    package.loaded["BGP_GameEvaluator"] = {
        evaluate = function(playerObj, item)
            table.insert(eval.calls, { playerObj = playerObj, item = item })
            return eval.returnValue
        end
    }
    eval.calls = eval.calls or {}

    -- Stub GameDefs module (only used to gate world menu by fullType)
    package.loaded["BGP_GameDefs"] = { GAME_DEFS = defs }

    -- Timed action queue + action constructors
    _G.ISTimedActionQueue = {
        add = function(action)
            table.insert(queueAdds, action)
        end
    }

    _G.ISPlayBoardGameFromInventory = {
        new = function(_, p, item, duration, boredomReduce, unhappyReduce, stressReduce)
            table.insert(ctorCalls, {
                which = "inv",
                p = p, item = item, duration = duration,
                boredom = boredomReduce, unhappy = unhappyReduce, stress = stressReduce
            })
            return { kind = "inv_action" }
        end
    }

    _G.ISPlayBoardGameFromGround = {
        new = function(_, p, item, duration, boredomReduce, unhappyReduce, stressReduce)
            table.insert(ctorCalls, {
                which = "ground",
                p = p, item = item, duration = duration,
                boredom = boredomReduce, unhappy = unhappyReduce, stress = stressReduce
            })
            return { kind = "ground_action" }
        end
    }

    -- Required-by-name (PZ style) placeholders so require doesn't error
    package.loaded["TimedActions/ISTimedActionQueue"] = true
    package.loaded["TimedActions/ISPlayBoardGameFromInventory"] = true
    package.loaded["TimedActions/ISPlayBoardGameFromGround"] = true

    return {
        eval = eval,
        tooltipCalls = tooltipCalls,
        queueAdds = queueAdds,
        ctorCalls = ctorCalls,
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

function TestBGP_MenuHandlers:testInventoryMenuReturnsEarlyWhenNoPlayer()
    local ctx = makeContext()
    local t = installStubs({
        getSpecificPlayer = function(_) return nil end,
        eval = { returnValue = { ok = true, label="Play X", duration=1, boredom=1, unhappy=1, stress=0.1 }, calls = {} },
        game_defs = {},
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillInventoryObjectContextMenu(0, ctx, { makeItem("Mod.Game") })

    lu.assertEquals(#ctx.options, 0)
    lu.assertEquals(#t.eval.calls, 0)
end

function TestBGP_MenuHandlers:testInventoryMenuUnwrapsEntryItemsTable()
    local ctx = makeContext()
    local item = makeItem("Mod.Game")
    local t = installStubs({
        eval = { returnValue = nil, calls = {} }, -- evaluator returns nil, still should be called once
        game_defs = {},
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillInventoryObjectContextMenu(0, ctx, { { items = { item } } })

    lu.assertEquals(#t.eval.calls, 1)
    lu.assertIs(t.eval.calls[1].item, item)
end

function TestBGP_MenuHandlers:testInventoryMenuDoesNothingWhenEvaluatorReturnsNil()
    local ctx = makeContext()
    local t = installStubs({
        eval = { returnValue = nil, calls = {} },
        game_defs = {},
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillInventoryObjectContextMenu(0, ctx, { makeItem("Mod.Game") })

    lu.assertEquals(#ctx.options, 0)
    lu.assertEquals(#t.tooltipCalls, 0)
end

function TestBGP_MenuHandlers:testInventoryMenuAddsDisabledOptionWhenEvalNotOk()
    local ctx = makeContext()
    local t = installStubs({
        eval = {
            returnValue = { ok = false, label = "Play Chess", tooltip = { "Cannot play" } },
            calls = {}
        },
        game_defs = {},
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillInventoryObjectContextMenu(0, ctx, { makeItem("Mod.Chess") })

    lu.assertEquals(#t.tooltipCalls, 1)
    lu.assertEquals(t.tooltipCalls[1].label, "Play Chess")
    lu.assertEquals(t.tooltipCalls[1].lines[1], "Cannot play")
    lu.assertEquals(#ctx.options, 0) -- Tooltips module is responsible for adding disabled option; we only record call here
end

function TestBGP_MenuHandlers:testInventoryMenuAddsPlayOptionWhenEvalOkAndCallbackEnqueuesTimedAction()
    local ctx = makeContext()
    local item = makeItem("Mod.Chess")
    local t = installStubs({
        eval = {
            returnValue = {
                ok = true, label = "Play Chess",
                duration = 123, boredom = 10, unhappy = 5, stress = 0.2
            },
            calls = {}
        },
        game_defs = {},
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillInventoryObjectContextMenu(0, ctx, { item })

    lu.assertEquals(#ctx.options, 1)
    lu.assertEquals(ctx.options[1].label, "Play Chess")

    -- click it
    local playerObj = _G.getSpecificPlayer(0)
    ctx.options[1].callback(playerObj)

    lu.assertEquals(#t.ctorCalls, 1)
    lu.assertEquals(t.ctorCalls[1].which, "inv")
    lu.assertIs(t.ctorCalls[1].item, item)
    lu.assertEquals(t.ctorCalls[1].duration, 123)
    lu.assertEquals(t.ctorCalls[1].boredom, 10)
    lu.assertEquals(t.ctorCalls[1].unhappy, 5)
    lu.assertEquals(t.ctorCalls[1].stress, 0.2)

    lu.assertEquals(#t.queueAdds, 1)
    lu.assertEquals(t.queueAdds[1].kind, "inv_action")
end

function TestBGP_MenuHandlers:testWorldMenuReturnsEarlyWhenNoPlayer()
    local ctx = makeContext()
    local t = installStubs({
        getSpecificPlayer = function(_) return nil end,
        eval = { returnValue = { ok = true }, calls = {} },
        game_defs = { ["Mod.Game"] = { name = "Game" } },
    })
    local Menu = reloadMenuHandlers()

    local world = { makeWorldObj(makeItem("Mod.Game")) }
    Menu.OnFillWorldObjectContextMenu(0, ctx, world, false)

    lu.assertEquals(#ctx.options, 0)
    lu.assertEquals(#t.eval.calls, 0)
end

function TestBGP_MenuHandlers:testWorldMenuReturnsEarlyWhenNoWorldItemUnderCursor()
    local ctx = makeContext()
    local t = installStubs({
        instanceof = function() return false end,
        eval = { returnValue = { ok = true }, calls = {} },
        game_defs = { ["Mod.Game"] = { name = "Game" } },
    })
    local Menu = reloadMenuHandlers()

    Menu.OnFillWorldObjectContextMenu(0, ctx, { {} }, false)

    lu.assertEquals(#ctx.options, 0)
    lu.assertEquals(#t.eval.calls, 0)
end

function TestBGP_MenuHandlers:testWorldMenuReturnsEarlyWhenItemNotInGameDefs()
    local ctx = makeContext()
    local t = installStubs({
        eval = { returnValue = { ok = true }, calls = {} },
        game_defs = {}, -- not present
    })
    local Menu = reloadMenuHandlers()

    local world = { makeWorldObj(makeItem("Mod.NotDefined")) }
    Menu.OnFillWorldObjectContextMenu(0, ctx, world, false)

    lu.assertEquals(#ctx.options, 0)
    lu.assertEquals(#t.eval.calls, 0) -- gate prevents eval call
end

function TestBGP_MenuHandlers:testWorldMenuTestFlagReturnsTrueWhenGameDefExists()
    local ctx = makeContext()
    local item = makeItem("Mod.Game")
    local t = installStubs({
        eval = { returnValue = { ok = true }, calls = {} },
        game_defs = { ["Mod.Game"] = { name = "Game" } },
    })
    local Menu = reloadMenuHandlers()

    local world = { makeWorldObj(item) }
    local ret = Menu.OnFillWorldObjectContextMenu(0, ctx, world, true)

    lu.assertTrue(ret)
    lu.assertEquals(#ctx.options, 0)
    lu.assertEquals(#t.eval.calls, 0) -- test-mode should not evaluate
end

function TestBGP_MenuHandlers:testWorldMenuAddsDisabledOptionWhenEvalNotOk()
    local ctx = makeContext()
    local item = makeItem("Mod.Game")
    local t = installStubs({
        eval = { returnValue = { ok = false, label = "Play Game", tooltip = { "Nope" } }, calls = {} },
        game_defs = { ["Mod.Game"] = { name = "Game" } },
    })
    local Menu = reloadMenuHandlers()

    local world = { makeWorldObj(item) }
    Menu.OnFillWorldObjectContextMenu(0, ctx, world, false)

    lu.assertEquals(#t.tooltipCalls, 1)
    lu.assertEquals(t.tooltipCalls[1].label, "Play Game")
end

function TestBGP_MenuHandlers:testWorldMenuAddsPlayOptionAndCallbackEnqueuesGroundTimedAction()
    local ctx = makeContext()
    local item = makeItem("Mod.Game")
    local t = installStubs({
        eval = { returnValue = { ok = true, label = "Play Game", duration = 50, boredom = 1, unhappy = 2, stress = 0.3 }, calls = {} },
        game_defs = { ["Mod.Game"] = { name = "Game" } },
    })
    local Menu = reloadMenuHandlers()

    local world = { makeWorldObj(item) }
    Menu.OnFillWorldObjectContextMenu(0, ctx, world, false)

    lu.assertEquals(#ctx.options, 1)
    lu.assertEquals(ctx.options[1].label, "Play Game")

    ctx.options[1].callback(_G.getSpecificPlayer(0))

    lu.assertEquals(#t.ctorCalls, 1)
    lu.assertEquals(t.ctorCalls[1].which, "ground")
    lu.assertIs(t.ctorCalls[1].item, item)
    lu.assertEquals(t.ctorCalls[1].duration, 50)
    lu.assertEquals(t.ctorCalls[1].stress, 0.3)

    lu.assertEquals(#t.queueAdds, 1)
    lu.assertEquals(t.queueAdds[1].kind, "ground_action")
end

return TestBGP_MenuHandlers
