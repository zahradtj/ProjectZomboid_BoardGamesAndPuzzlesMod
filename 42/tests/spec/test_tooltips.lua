-- tests/spec/test_tooltips.lua
-- LuaUnit tests for media/lua/client/BoardGamesAndPuzzles/BGP_Tooltips.lua

local lu = require("luaunit")

-- -----------------------
-- Stubs / helpers
-- -----------------------

local function installISToolTipStub(calls)
    calls = calls or {}

    -- The module under test does: require "ISUI/ISToolTip"
    -- Provide a stub at that require path.
    package.loaded["ISUI/ISToolTip"] = true

    _G.ISToolTip = {
        new = function()
            local tt = {
                _calls = {},
                initialise = function(self) table.insert(self._calls, "initialise") end,
                setVisible = function(self, v)
                    table.insert(self._calls, { "setVisible", v })
                    self.visible = v
                end,
                description = nil,
                visible = nil,
            }
            table.insert(calls, { kind = "new", tooltip = tt })
            return tt
        end
    }

    return calls
end

local function makeContext()
    return {
        added = {},
        addOption = function(self, label, a, b)
            local opt = { label = label, a = a, b = b }
            table.insert(self.added, opt)
            return opt
        end
    }
end

local function reloadTooltips()
    package.loaded["BGP_Tooltips"] = nil
    return require("BGP_Tooltips")
end

-- -----------------------
-- Tests
-- -----------------------

TestBGP_Tooltips = {}

function TestBGP_Tooltips:setUp()
    self.tooltipNewCalls = installISToolTipStub({})
    self.Tooltips = reloadTooltips()
end

function TestBGP_Tooltips:testAddsDisabledOptionAndSetsNotAvailable()
    local ctx = makeContext()

    local opt = self.Tooltips.addDisabledOptionWithTooltip(ctx, "Play Chess", { "Cannot play" })

    lu.assertEquals(#ctx.added, 1)
    lu.assertIs(opt, ctx.added[1])
    lu.assertEquals(opt.label, "Play Chess")
    lu.assertTrue(opt.notAvailable)
end

function TestBGP_Tooltips:testCreatesTooltipInitialisesAndHidesIt()
    local ctx = makeContext()

    local opt = self.Tooltips.addDisabledOptionWithTooltip(ctx, "Play Chess", { "Line1", "Line2" })

    -- Tooltip created once
    lu.assertEquals(#self.tooltipNewCalls, 1)
    local tt = self.tooltipNewCalls[1].tooltip
    lu.assertNotNil(tt)

    -- Methods called in the expected way
    lu.assertEquals(tt._calls[1], "initialise")
    lu.assertEquals(tt._calls[2][1], "setVisible")
    lu.assertEquals(tt._calls[2][2], false)

    -- Description is newline-joined
    lu.assertEquals(tt.description, "Line1\nLine2")

    -- Option has toolTip assigned
    lu.assertIs(opt.toolTip, tt)
end

function TestBGP_Tooltips:testPassesNilCallbacksToAddOption()
    local ctx = makeContext()

    self.Tooltips.addDisabledOptionWithTooltip(ctx, "Play X", { "Nope" })

    lu.assertNil(ctx.added[1].a)
    lu.assertNil(ctx.added[1].b)
end

return TestBGP_Tooltips
