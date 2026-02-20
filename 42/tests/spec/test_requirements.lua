-- tests/spec/test_requirements.lua
-- LuaUnit tests for media/lua/client/BoardGamesAndPuzzles/BGP_Requirements.lua

local lu = require("luaunit")

-- -----------------------
-- Helpers / fakes
-- -----------------------

local function makeProps(surfaceVal)
    return {
        getSurface = function() return surfaceVal end
    }
end

local function makeTile(surfaceVal)
    return {
        getProperties = function() return makeProps(surfaceVal) end
    }
end

local function makeSquare(opts)
    opts = opts or {}
    local surrounding = opts.surrounding or {}
    local outside = opts.outside == true
    local lightLevel = opts.lightLevel -- number or nil
    local supportsGetLightLevel = opts.supportsGetLightLevel ~= false -- default true

    local sq = {}
    function sq:getSurroundingSquares() return surrounding end
    function sq:isOutside() return outside end

    if supportsGetLightLevel then
        function sq:getLightLevel(_) return lightLevel end
    end

    return sq
end

local function makeLightItem(isOn)
    return {
        isEmittingLight = function() return true end,
        isEmittingLight = true, -- also exists as a field check in code
        isEmittingLight_fn = function() return isOn end, -- not used
        isEmittingLight2 = function() return isOn end, -- not used
        isEmittingLight3 = isOn, -- not used
        isEmittingLight4 = nil, -- not used
        -- actual method called:
        isEmittingLight = function(self) return isOn end
    }
end

local function makePlayer(opts)
    opts = opts or {}
    local sq = opts.square
    local prim = opts.primary
    local sec  = opts.secondary
    local playerNum = opts.playerNum or 0

    return {
        getSquare = function() return sq end,
        getPrimaryHandItem = function() return prim end,
        getSecondaryHandItem = function() return sec end,
        getPlayerNum = function() return playerNum end,
    }
end

-- NOTE: BGP_Requirements uses global GameTime.getInstance():getHour()
local function stubGameTime(hour)
    _G.GameTime = {
        getInstance = function()
            return { getHour = function() return hour end }
        end
    }
end

local function reloadRequirements()
    package.loaded["BGP_Requirements"] = nil
    return require("BGP_Requirements")
end

-- -----------------------
-- Tests
-- -----------------------

TestBGP_Requirements = {}

function TestBGP_Requirements:setUp()
    -- Default time used by most tests (night)
    stubGameTime(2)
    self.Req = reloadRequirements()
end

-- ---- hasNearbySurface ------------------------------------------------

function TestBGP_Requirements:testHasNearbySurfaceReturnsFalseWhenPlayerNil()
    lu.assertFalse(self.Req.hasNearbySurface(nil, 1))
end

function TestBGP_Requirements:testHasNearbySurfaceReturnsFalseWhenSquareNil()
    local p = makePlayer({ square = nil })
    lu.assertFalse(self.Req.hasNearbySurface(p, 1))
end

function TestBGP_Requirements:testHasNearbySurfaceReturnsFalseWhenNoSurfaces()
    local sq = makeSquare({
        surrounding = { makeTile(0), makeTile(nil), makeTile(0) }
    })
    local p = makePlayer({ square = sq })
    lu.assertFalse(self.Req.hasNearbySurface(p, 1))
end

function TestBGP_Requirements:testHasNearbySurfaceReturnsTrueWhenAnyTileHasSurfaceGreaterThanZero()
    local sq = makeSquare({
        surrounding = { makeTile(0), makeTile(2), makeTile(0) }
    })
    local p = makePlayer({ square = sq })
    lu.assertTrue(self.Req.hasNearbySurface(p, 1))
end

function TestBGP_Requirements:testHasNearbySurfaceIgnoresRadiusButAcceptsNilRadius()
    local sq = makeSquare({
        surrounding = { makeTile(1) }
    })
    local p = makePlayer({ square = sq })
    lu.assertTrue(self.Req.hasNearbySurface(p, nil))
    lu.assertTrue(self.Req.hasNearbySurface(p, 99))
end

-- ---- hasEnoughLight --------------------------------------------------

function TestBGP_Requirements:testHasEnoughLightReturnsFalseWhenSquareNil()
    local p = makePlayer({ square = nil })
    lu.assertFalse(self.Req.hasEnoughLight(p, 0.3))
end

function TestBGP_Requirements:testHasEnoughLightReturnsTrueOutsideDuringDaylight()
    stubGameTime(12) -- noon
    self.Req = reloadRequirements()

    local sq = makeSquare({ outside = true, lightLevel = 0.0 })
    local p = makePlayer({ square = sq })
    lu.assertTrue(self.Req.hasEnoughLight(p, 0.99)) -- should still be true due to daylight rule
end

function TestBGP_Requirements:testHasEnoughLightReturnsFalseOutsideAtNightWithoutLightAndNoLightLevel()
    stubGameTime(2) -- night
    self.Req = reloadRequirements()

    local sq = makeSquare({ outside = true, supportsGetLightLevel = false })
    local p = makePlayer({ square = sq })
    lu.assertFalse(self.Req.hasEnoughLight(p, 0.3))
end

function TestBGP_Requirements:testHasEnoughLightReturnsTrueWithPrimaryLightSource()
    local sq = makeSquare({ outside = false, lightLevel = 0.0 })
    local p = makePlayer({ square = sq, primary = makeLightItem(true), secondary = nil })
    lu.assertTrue(self.Req.hasEnoughLight(p, 0.9))
end

function TestBGP_Requirements:testHasEnoughLightReturnsTrueWithSecondaryLightSource()
    local sq = makeSquare({ outside = false, lightLevel = 0.0 })
    local p = makePlayer({ square = sq, primary = nil, secondary = makeLightItem(true) })
    lu.assertTrue(self.Req.hasEnoughLight(p, 0.9))
end

function TestBGP_Requirements:testHasEnoughLightUsesSquareLightLevelWhenNoOtherSources()
    local sq = makeSquare({ outside = false, lightLevel = 0.35 })
    local p = makePlayer({ square = sq, playerNum = 0 })
    lu.assertTrue(self.Req.hasEnoughLight(p, 0.30))
    lu.assertFalse(self.Req.hasEnoughLight(p, 0.40))
end

function TestBGP_Requirements:testHasEnoughLightReturnsFalseWhenGetLightLevelUnsupportedAndNoOtherSources()
    local sq = makeSquare({ outside = false, supportsGetLightLevel = false })
    local p = makePlayer({ square = sq })
    lu.assertFalse(self.Req.hasEnoughLight(p, 0.01))
end

function TestBGP_Requirements:testHasEnoughLightDefaultMinLevelIsPointThree()
    -- light level 0.29 should fail default; 0.30 should pass default
    local sqLow = makeSquare({ outside = false, lightLevel = 0.29 })
    local pLow = makePlayer({ square = sqLow })
    lu.assertFalse(self.Req.hasEnoughLight(pLow, nil))

    local sqOk = makeSquare({ outside = false, lightLevel = 0.30 })
    local pOk = makePlayer({ square = sqOk })
    lu.assertTrue(self.Req.hasEnoughLight(pOk, nil))
end

return TestBGP_Requirements
