-- tests/spec/test_requirements.lua
-- LuaUnit tests for media/lua/client/BoardGamesAndPuzzles/BGP_Requirements.lua

local lu = require("luaunit")

-- -----------------------
-- Helpers / fakes
-- -----------------------

local REQUIREMENTS_PATH = "media/lua/client/BGP_Requirements.lua"

local function snapshotGlobals()
    return {
        GameTime = _G.GameTime,
        getCell = _G.getCell,
        -- These globals are commonly stubbed by other specs; isolate them.
        hasNearbySurface = _G.hasNearbySurface,
        hasEnoughLight = _G.hasEnoughLight,
        isCharacterNearWorldItem = _G.isCharacterNearWorldItem,
    }
end

local function restoreGlobals(s)
    _G.GameTime = s.GameTime
    _G.getCell = s.getCell
    _G.hasNearbySurface = s.hasNearbySurface
    _G.hasEnoughLight = s.hasEnoughLight
    _G.isCharacterNearWorldItem = s.isCharacterNearWorldItem
end

local function clearConflictingGlobals()
    _G.hasNearbySurface = nil
    _G.hasEnoughLight = nil
    _G.isCharacterNearWorldItem = nil
end

-- Simple "ArrayList-like" wrapper for getObjects()
local function makeObjList(list)
    list = list or {}
    return {
        size = function() return #list end,
        get = function(_, i) return list[i + 1] end, -- 0-based index
    }
end

-- Property container fakes
local function makeSquareProps(opts)
    opts = opts or {}
    local surf = opts.surface -- number or nil
    local valSurface = opts.valSurface -- string/number/nil
    local throwGetSurface = opts.throwGetSurface == true
    local throwVal = opts.throwVal == true

    local p = {}

    if opts.hasGetSurface ~= false then
        function p:getSurface()
            if throwGetSurface then error("boom getSurface") end
            return surf
        end
        p.getSurface = p.getSurface
    end

    if opts.hasVal == true then
        function p:Val(k)
            if throwVal then error("boom Val") end
            if k == "Surface" then return valSurface end
            return nil
        end
        p.Val = p.Val
    end

    return p
end

local function makeSpriteProps(opts)
    opts = opts or {}
    local flags = opts.flags or {}
    local vals = opts.vals or {}
    local throwIs = opts.throwIs == true
    local throwVal = opts.throwVal == true

    local p = {}

    if opts.hasIs == true then
        function p:Is(k)
            if throwIs then error("boom Is") end
            return flags[k] == true
        end
        p.Is = p.Is
    end

    if opts.hasVal == true then
        function p:Val(k)
            if throwVal then error("boom Val") end
            return vals[k]
        end
        p.Val = p.Val
    end

    return p
end

local function makeSprite(props)
    return {
        getProperties = function() return props end
    }
end

local function makeWorldObj(opts)
    opts = opts or {}
    local spr = opts.sprite
    return {
        getSprite = function() return spr end
    }
end

local function makeGridSquare(x, y, z, opts)
    opts = opts or {}
    local props = opts.props
    local objects = opts.objects or {}

    local sq = {}
    function sq:getX() return x end
    function sq:getY() return y end
    function sq:getZ() return z end

    if props then
        function sq:getProperties() return props end
        sq.getProperties = sq.getProperties
    end

    function sq:getObjects()
        return makeObjList(objects)
    end

    function sq:isOutside() return opts.outside == true end
    if opts.supportsGetLightLevel ~= false then
        function sq:getLightLevel(_) return opts.lightLevel end
    end

    return sq
end

local function makeCell(gridSquaresByKey)
    return {
        getGridSquare = function(_, x, y, z)
            return gridSquaresByKey[tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)]
        end
    }
end

local function makeLightItem(isOn)
    -- Provide BOTH a truthy field and a callable method (matches code under test)
    local item = { isEmittingLight = true }
    function item:isEmittingLight() return isOn end
    return item
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

local function makeWorldItemObj(square)
    return {
        getSquare = function() return square end
    }
end

local function stubGameTime(hour)
    _G.GameTime = {
        getInstance = function()
            return { getHour = function() return hour end }
        end
    }
end

-- ✅ Bullet-proof: bypass require/package.preload entirely
local function loadRequirementsFresh()
    package.loaded["BGP_Requirements"] = nil
    local chunk, err = loadfile(REQUIREMENTS_PATH)
    assert(chunk, "Failed to load requirements at " .. REQUIREMENTS_PATH .. ": " .. tostring(err))
    return chunk()
end

-- -----------------------
-- Tests
-- -----------------------

TestBGP_Requirements = {}

function TestBGP_Requirements:setUp()
    self._g = snapshotGlobals()
    clearConflictingGlobals()

    stubGameTime(2) -- default night

    _G.getCell = function()
        return makeCell({})
    end

    self.Req = loadRequirementsFresh()

    -- sanity: if this fails, you are not loading the real module
    lu.assertEquals(type(self.Req.hasNearbySurface), "function")
    lu.assertEquals(type(self.Req.hasEnoughLight), "function")
    lu.assertEquals(type(self.Req.isCharacterNearWorldItem), "function")
end

function TestBGP_Requirements:tearDown()
    package.loaded["BGP_Requirements"] = nil
    restoreGlobals(self._g)
end

-- ---- hasNearbySurface ------------------------------------------------

function TestBGP_Requirements:testHasNearbySurfaceReturnsFalseWhenPlayerNil()
    lu.assertFalse(self.Req.hasNearbySurface(nil, 1))
end

function TestBGP_Requirements:testHasNearbySurfaceReturnsFalseWhenPlayerSquareNil()
    local p = makePlayer({ square = nil })
    lu.assertFalse(self.Req.hasNearbySurface(p, 1))
end

function TestBGP_Requirements:testHasNearbySurfaceReturnsFalseWhenNoCellSquares()
    _G.getCell = function()
        return makeCell({})
    end

    local pSq = makeGridSquare(0, 0, 0, {})
    local p = makePlayer({ square = pSq })
    lu.assertFalse(self.Req.hasNearbySurface(p, 1))
end

function TestBGP_Requirements:testHasNearbySurfaceTrueWhenSquareGetSurfaceGreaterThanZero()
    local center = makeGridSquare(0, 0, 0, { props = makeSquareProps({ surface = 2, hasGetSurface = true }) })
    _G.getCell = function()
        return makeCell({ ["0,0,0"] = center })
    end

    local p = makePlayer({ square = center })
    lu.assertTrue(self.Req.hasNearbySurface(p, 0))
end

function TestBGP_Requirements:testHasNearbySurfaceTrueWhenSquareValSurfaceNumericString()
    local center = makeGridSquare(0, 0, 0, { props = makeSquareProps({ hasVal = true, valSurface = "1" }) })
    _G.getCell = function()
        return makeCell({ ["0,0,0"] = center })
    end

    local p = makePlayer({ square = center })
    lu.assertTrue(self.Req.hasNearbySurface(p, 0))
end

function TestBGP_Requirements:testHasNearbySurfaceTrueWhenObjectSpriteHasIsTableTop()
    local objProps = makeSpriteProps({ hasIs = true, flags = { IsTableTop = true } })
    local obj = makeWorldObj({ sprite = makeSprite(objProps) })

    local center = makeGridSquare(0, 0, 0, { objects = { obj } })
    _G.getCell = function()
        return makeCell({ ["0,0,0"] = center })
    end

    local p = makePlayer({ square = center })
    lu.assertTrue(self.Req.hasNearbySurface(p, 0))
end

function TestBGP_Requirements:testHasNearbySurfaceTrueWhenObjectSpriteGroupNameTable()
    local objProps = makeSpriteProps({ hasVal = true, vals = { GroupName = "Table" } })
    local obj = makeWorldObj({ sprite = makeSprite(objProps) })

    local center = makeGridSquare(0, 0, 0, { objects = { obj } })
    _G.getCell = function()
        return makeCell({ ["0,0,0"] = center })
    end

    local p = makePlayer({ square = center })
    lu.assertTrue(self.Req.hasNearbySurface(p, 0))
end

function TestBGP_Requirements:testHasNearbySurfaceTrueWhenObjectCustomNameContainsTable()
    local objProps = makeSpriteProps({ hasVal = true, vals = { CustomName = "Picnic Table" } })
    local obj = makeWorldObj({ sprite = makeSprite(objProps) })

    local center = makeGridSquare(0, 0, 0, { objects = { obj } })
    _G.getCell = function()
        return makeCell({ ["0,0,0"] = center })
    end

    local p = makePlayer({ square = center })
    lu.assertTrue(self.Req.hasNearbySurface(p, 0))
end

function TestBGP_Requirements:testHasNearbySurfaceHonorsRadius()
    local center = makeGridSquare(0, 0, 0, {})
    local near = makeGridSquare(1, 0, 0, { props = makeSquareProps({ surface = 1, hasGetSurface = true }) })

    _G.getCell = function()
        return makeCell({
            ["0,0,0"] = center,
            ["1,0,0"] = near,
        })
    end

    local p = makePlayer({ square = center })
    lu.assertFalse(self.Req.hasNearbySurface(p, 0))
    lu.assertTrue(self.Req.hasNearbySurface(p, 1))
end

function TestBGP_Requirements:testHasNearbySurfaceDoesNotCrashWhenPropsThrow()
    local badProps = makeSquareProps({ hasGetSurface = true, throwGetSurface = true, hasVal = true, throwVal = true })
    local center = makeGridSquare(0, 0, 0, { props = badProps })
    _G.getCell = function()
        return makeCell({ ["0,0,0"] = center })
    end

    local p = makePlayer({ square = center })
    lu.assertFalse(self.Req.hasNearbySurface(p, 0))
end

function TestBGP_Requirements:testHasNearbySurfaceDoesNotCrashWhenObjectPropsThrow()
    local objProps = makeSpriteProps({ hasIs = true, throwIs = true, hasVal = true, throwVal = true })
    local obj = makeWorldObj({ sprite = makeSprite(objProps) })

    local center = makeGridSquare(0, 0, 0, { objects = { obj } })
    _G.getCell = function()
        return makeCell({ ["0,0,0"] = center })
    end

    local p = makePlayer({ square = center })
    lu.assertFalse(self.Req.hasNearbySurface(p, 0))
end

-- ---- hasEnoughLight --------------------------------------------------

function TestBGP_Requirements:testHasEnoughLightReturnsFalseWhenSquareNil()
    local p = makePlayer({ square = nil })
    lu.assertFalse(self.Req.hasEnoughLight(p, 0.3))
end

function TestBGP_Requirements:testHasEnoughLightReturnsTrueOutsideDuringDaylight()
    stubGameTime(12)
    self.Req = loadRequirementsFresh()

    local sq = makeGridSquare(0, 0, 0, { outside = true, lightLevel = 0.0 })
    local p = makePlayer({ square = sq })
    lu.assertTrue(self.Req.hasEnoughLight(p, 0.99))
end

function TestBGP_Requirements:testHasEnoughLightReturnsFalseOutsideAtNightWithoutLightAndNoLightLevel()
    stubGameTime(2)
    self.Req = loadRequirementsFresh()

    local sq = makeGridSquare(0, 0, 0, { outside = true, supportsGetLightLevel = false })
    local p = makePlayer({ square = sq })
    lu.assertFalse(self.Req.hasEnoughLight(p, 0.3))
end

function TestBGP_Requirements:testHasEnoughLightReturnsTrueWithPrimaryLightSource()
    local sq = makeGridSquare(0, 0, 0, { outside = false, lightLevel = 0.0 })
    local p = makePlayer({ square = sq, primary = makeLightItem(true), secondary = nil })
    lu.assertTrue(self.Req.hasEnoughLight(p, 0.9))
end

function TestBGP_Requirements:testHasEnoughLightReturnsTrueWithSecondaryLightSource()
    local sq = makeGridSquare(0, 0, 0, { outside = false, lightLevel = 0.0 })
    local p = makePlayer({ square = sq, primary = nil, secondary = makeLightItem(true) })
    lu.assertTrue(self.Req.hasEnoughLight(p, 0.9))
end

function TestBGP_Requirements:testHasEnoughLightUsesSquareLightLevelWhenNoOtherSources()
    local sq = makeGridSquare(0, 0, 0, { outside = false, lightLevel = 0.35 })
    local p = makePlayer({ square = sq, playerNum = 0 })
    lu.assertTrue(self.Req.hasEnoughLight(p, 0.30))
    lu.assertFalse(self.Req.hasEnoughLight(p, 0.40))
end

function TestBGP_Requirements:testHasEnoughLightReturnsFalseWhenGetLightLevelUnsupportedAndNoOtherSources()
    local sq = makeGridSquare(0, 0, 0, { outside = false, supportsGetLightLevel = false })
    local p = makePlayer({ square = sq })
    lu.assertFalse(self.Req.hasEnoughLight(p, 0.01))
end

function TestBGP_Requirements:testHasEnoughLightDefaultMinLevelIsPointThree()
    local sqLow = makeGridSquare(0, 0, 0, { outside = false, lightLevel = 0.29 })
    local pLow = makePlayer({ square = sqLow })
    lu.assertFalse(self.Req.hasEnoughLight(pLow, nil))

    local sqOk = makeGridSquare(0, 0, 0, { outside = false, lightLevel = 0.30 })
    local pOk = makePlayer({ square = sqOk })
    lu.assertTrue(self.Req.hasEnoughLight(pOk, nil))
end

-- ---- isCharacterNearWorldItem ---------------------------------------

function TestBGP_Requirements:testIsCharacterNearWorldItemReturnsFalseWhenPlayerSquareNil()
    local p = makePlayer({ square = nil })
    local w = makeWorldItemObj(makeGridSquare(0, 0, 0, {}))
    lu.assertFalse(self.Req.isCharacterNearWorldItem(p, w))
end

function TestBGP_Requirements:testIsCharacterNearWorldItemReturnsFalseWhenWorldSquareNil()
    local p = makePlayer({ square = makeGridSquare(0, 0, 0, {}) })
    local w = { getSquare = function() return nil end }
    lu.assertFalse(self.Req.isCharacterNearWorldItem(p, w))
end

function TestBGP_Requirements:testIsCharacterNearWorldItemTrueSameSquare()
    local psq = makeGridSquare(10, 10, 0, {})
    local wsq = makeGridSquare(10, 10, 0, {})
    local p = makePlayer({ square = psq })
    local w = makeWorldItemObj(wsq)
    lu.assertTrue(self.Req.isCharacterNearWorldItem(p, w))
end

function TestBGP_Requirements:testIsCharacterNearWorldItemTrueAdjacentIncludingDiagonal()
    local psq = makeGridSquare(10, 10, 0, {})
    local wsq = makeGridSquare(11, 11, 0, {})
    local p = makePlayer({ square = psq })
    local w = makeWorldItemObj(wsq)
    lu.assertTrue(self.Req.isCharacterNearWorldItem(p, w))
end

function TestBGP_Requirements:testIsCharacterNearWorldItemFalseWhenTooFar()
    local psq = makeGridSquare(10, 10, 0, {})
    local wsq = makeGridSquare(12, 10, 0, {})
    local p = makePlayer({ square = psq })
    local w = makeWorldItemObj(wsq)
    lu.assertFalse(self.Req.isCharacterNearWorldItem(p, w))
end

function TestBGP_Requirements:testIsCharacterNearWorldItemFalseDifferentZ()
    local psq = makeGridSquare(10, 10, 0, {})
    local wsq = makeGridSquare(10, 10, 1, {})
    local p = makePlayer({ square = psq })
    local w = makeWorldItemObj(wsq)
    lu.assertFalse(self.Req.isCharacterNearWorldItem(p, w))
end

return TestBGP_Requirements