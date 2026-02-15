-- BoardGamesAndPuzzlesMod_Play.lua (client)

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "ISUI/ISToolTip"

require "TimedActions/ISPlayBoardGameFromInventory"
require "TimedActions/ISPlayBoardGameFromGround"
require "BoardGamesAndPuzzlesMod_Operation"

local DEFAULT_GAME_BASIC = {
  illiterateAllowed = true,
  illiterateFailurePercent = 0,
}

local DEFAULT_GAME_EASY = {
  illiterateAllowed = true,
  illiterateFailurePercent = 25,
}

local DEFAULT_GAME_MEDIUM = {
  illiterateAllowed = true,
  illiterateFailurePercent = 50,
}

local DEFAULT_GAME_HARD = {
  illiterateAllowed = false,
  illiterateFailurePercent = 100,
}


-- duration : 11250 = 1 hour
local GAME_DEFS = {
    ["BoardGamesAndPuzzlesMod.AxisAndAllies"] = {
      default = DEFAULT_GAME_HARD,
      name = "Axis and Allies",
      duration = 67500,
      boredomReduce = 35,
      unhappyReduce = 18,
      stressReduce = 12,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.B17QueenOfTheSkies"] = {
      default = DEFAULT_GAME_HARD,
      name = "B17 Queen of the Skies",
      duration = 22500,
      boredomReduce = 38,
      unhappyReduce = 20,
      stressReduce = 10,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.Backgammon"] = {
      default = DEFAULT_GAME_EASY,
      name = "Backgammon",
      duration = 5060,
      boredomReduce = 18,
      unhappyReduce = 8,
      stressReduce = 12,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.Boggle"] = {
      default = DEFAULT_GAME_HARD,
      name = "Boggle",
      duration = 3750,
      boredomReduce = 15,
      unhappyReduce = 6,
      stressReduce = 8,
      clumsyImpacted = false,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.CandyLand"] = {
      default = DEFAULT_GAME_BASIC,
      name = "Candy Land",
      duration = 5060,
      boredomReduce = 8,
      unhappyReduce = 4,
      stressReduce = 5,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.Checkers"] = {
      default = DEFAULT_GAME_BASIC,
      name = "Checkers",
      duration = 5060,
      boredomReduce = 15,
      unhappyReduce = 8,
      stressReduce = 12,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.ChessSet"] = {
      default = DEFAULT_GAME_EASY,
      name = "Chess",
      duration = 11250,
      boredomReduce = 20,
      unhappyReduce = 10,
      stressReduce = 15,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.Clue"] = {
      default = DEFAULT_GAME_MEDIUM,
      name = "Clue",
      duration = 16875,
      boredomReduce = 20,
      unhappyReduce = 10,
      stressReduce = 8,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.Go"] = {
      default = DEFAULT_GAME_BASIC,
      name = "Go",
      duration = 22500,
      boredomReduce = 22,
      unhappyReduce = 10,
      stressReduce = 15,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.Mastermind"] = {
      default = DEFAULT_GAME_EASY,
      name = "Mastermind",
      duration = 5060,
      boredomReduce = 12,
      unhappyReduce = 6,
      stressReduce = 8,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.Monopoly"] = {
      default = DEFAULT_GAME_MEDIUM,
      name = "Monopoly",
      duration = 45000,
      boredomReduce = 28,
      unhappyReduce = 15,
      stressReduce = 10,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.Operation"] = {
      default = DEFAULT_GAME_BASIC,
      name = "Operation",
      duration = 2250,
      boredomReduce = 12,
      unhappyReduce = 5,
      stressReduce = 5,
      clumsyImpacted = true,
      usesBattery = true,
    },

    ["BoardGamesAndPuzzlesMod.Risk"] = {
      default = DEFAULT_GAME_MEDIUM,
      name = "Risk",
      duration = 45000,
      boredomReduce = 30,
      unhappyReduce = 15,
      stressReduce = 12,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.Scrabble"] = {
      default = DEFAULT_GAME_HARD,
      name = "Scrabble",
      duration = 19690,
      boredomReduce = 25,
      unhappyReduce = 12,
      stressReduce = 10,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.SnakesAndLadders"] = {
      default = DEFAULT_GAME_BASIC,
      name = "Snakes and Ladders",
      duration = 11250,
      boredomReduce = 8,
      unhappyReduce = 4,
      stressReduce = 5,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.Sorry"] = {
      default = DEFAULT_GAME_EASY,
      name = "Sorry",
      duration = 11250,
      boredomReduce = 15,
      unhappyReduce = 8,
      stressReduce = 10,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.TheGameOfLife"] = {
      default = DEFAULT_GAME_MEDIUM,
      name = "The Game of Life",
      duration = 16875,
      boredomReduce = 20,
      unhappyReduce = 10,
      stressReduce = 8,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.TrivialPursuit"] = {
      default = DEFAULT_GAME_HARD,
      name = "Trivial Pursuit",
      duration = 19690,
      boredomReduce = 25,
      unhappyReduce = 12,
      stressReduce = 10,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.Trouble"] = {
      default = DEFAULT_GAME_BASIC,
      name = "Trouble",
      duration = 11250,
      boredomReduce = 12,
      unhappyReduce = 6,
      stressReduce = 8,
      clumsyImpacted = true,
      usesBattery = false,
    },

    ["BoardGamesAndPuzzlesMod.YahtzeeGame"] = {
      default = DEFAULT_GAME_EASY,
      name = "Yahtzee",
      duration = 5060,
      boredomReduce = 18,
      unhappyReduce = 8,
      stressReduce = 10,
      clumsyImpacted = true,
      usesBattery = false,
    }
}

-- Context menu hook
local function onPlayFromInventory(context, playerObj, item, label, duration, boredomReduce, unhappyReduce, stressReduce)
    context:addOption(label, playerObj, function(p)
        ISTimedActionQueue.add(ISPlayBoardGameFromInventory:new(p, item, duration, boredomReduce, unhappyReduce, stressReduce))
    end)
end

local function addDisabledOptionWithTooltip(context, label, lines)
    local opt = context:addOption(label, nil, nil)
    opt.notAvailable = true

    local tt = ISToolTip:new()
    tt:initialise()
    tt:setVisible(false)
    tt.description = table.concat(lines, "\n")
    opt.toolTip = tt

    return opt
end

-- --- Requirements ----------------------------------------------------

local function hasNearbySurface(playerObj, radius)
    radius = radius or 1
    if not playerObj then return false end
    local sq = playerObj:getSquare()
    if not sq then return false end

    local surrounding = sq:getSurroundingSquares()

    for _, tile in pairs(surrounding) do
        if tile and tile:getProperties() and tile:getProperties():getSurface() and tile:getProperties():getSurface() > 0 then
            return true
        end
    end

    return false
end


local function playerHasLightSource(playerObj)
    local prim = playerObj:getPrimaryHandItem()
    local sec  = playerObj:getSecondaryHandItem()

    local function isOn(item)
        return item and item.isEmittingLight and item:isEmittingLight()
    end

    return isOn(prim) or isOn(sec)
end

local function hasEnoughLight(playerObj, minLevel)
    minLevel = minLevel or 0.30
    local sq = playerObj:getSquare()
    if not sq then return false end

    -- Daylight outside is usually “fine”
    if sq:isOutside() then
        local gt = GameTime.getInstance()
        local hour = gt:getHour()
        if hour >= 7 and hour <= 18 then
            return true
        end
    end

    -- Flashlight / torch, etc.
    if playerHasLightSource(playerObj) then
        return true
    end

    -- If available in your build:
    if sq.getLightLevel then
        local lvl = sq:getLightLevel(playerObj:getPlayerNum())
        return lvl and lvl >= minLevel
    end

    return false
end

-- Returns:
--   nil (not a boardgame item)
--   { ok=false, label=string, tooltip=table<string> }
--   { ok=true, label=string, duration=number, boredom=number, unhappy=number, stress=number }
local function evaluateBoardGamePlay(playerObj, item)
    if not playerObj or not item or not item.getFullType then return nil end

    local fullType = item:getFullType()
    if not fullType then return nil end

    local gameDef = GAME_DEFS[fullType]
    if not gameDef then return nil end

    local label = "Play " .. gameDef.name

    -- Literacy gating
    if playerObj:hasTrait(CharacterTrait.ILLITERATE) and not gameDef.default.illiterateAllowed then
        return {
            ok = false,
            label = label,
            tooltip = {
                "Cannot play:",
                "- Requires reading ability.",
            },
        }
    end

    -- Requirements: surface + light
    local missing = {}
    if not hasNearbySurface(playerObj, 1) then
        table.insert(missing, "- Requires a nearby surface (table).")
    end
    if not hasEnoughLight(playerObj, 0.30) then
        table.insert(missing, "- Not enough light.")
    end
    if gameDef.usesBattery and not BoardGamesAndPuzzlesMod_Operation.hasBattery(item) then
        table.insert(missing, "- Requires a charged battery.")
    end

    if #missing > 0 then
        table.insert(missing, 1, "Cannot play right now:")
        return { ok = false, label = label, tooltip = missing }
    end

    -- Duration adjustments
    local duration = gameDef.duration

    if not gameDef.default.illiterateAllowed then
        if playerObj:hasTrait(CharacterTrait.SLOW_READER) then
            duration = math.floor(duration * 1.5)
        elseif playerObj:hasTrait(CharacterTrait.FAST_READER) then
            duration = math.floor(duration * 0.5)
        end
    end

    if gameDef.clumsyImpacted then
        if playerObj:hasTrait(CharacterTrait.ALL_THUMBS)
            or playerObj:hasTrait(CharacterTrait.CLUMSY)
            or playerObj:isWearingAwkwardGloves()
        then
            duration = math.floor(duration * 1.25)
        elseif playerObj:hasTrait(CharacterTrait.DEXTROUS) then
            duration = math.floor(duration * 0.75)
        end
    end

    -- Normalize stress reduce (PZ stress is 0..1)
    local stressReduce = gameDef.stressReduce
    if stressReduce and stressReduce > 1 then
        stressReduce = stressReduce / 100
    end

    return {
        ok = true,
        label = label,
        duration = duration,
        boredom = gameDef.boredomReduce,
        unhappy = gameDef.unhappyReduce,
        stress = stressReduce or 0.08,
    }
end

local function onFillInventoryObjectContextMenu(player, context, items)
    print("[BGP] - INV FILL")
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    for _, entry in ipairs(items) do
        local item = entry
        if type(entry) == "table" and entry.items then
            item = entry.items[1]
        end

        --addBoardGamePlayOption(context, playerObj, item, onPlayFromInventory)
        local eval = evaluateBoardGamePlay(playerObj, item)
        if not eval then return false end -- not a boardgame item

        if not eval.ok then
            addDisabledOptionWithTooltip(context, eval.label, eval.tooltip)
        else
            -- IMPORTANT: context menu callbacks are invoked later; capture only what you need.
            onPlayFromInventory(
                context,
                playerObj,
                item,
                eval.label,
                eval.duration,
                eval.boredom,
                eval.unhappy,
                eval.stress
            )
        end
    end
end



local function getClickedWorldItem(worldobjects)
    for _, o in ipairs(worldobjects) do
        -- Dropped items on the ground are IsoWorldInventoryObject
        if instanceof(o, "IsoWorldInventoryObject") then
            local item = o:getItem()
            if item then return o, item end
        end
    end
    return nil, nil
end

local function onPlayFromGround(context, playerObj, worldItemObj, invItem, label, duration, boredomReduce, unhappyReduce, stressReduce)
    context:addOption(label, playerObj, function(p)
        ISTimedActionQueue.add(ISPlayBoardGameFromGround:new(p, worldItemObj, invItem, duration, boredomReduce, unhappyReduce, stressReduce))
    end)
end

local function OnFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    local worldItemObj, invItem = getClickedWorldItem(worldobjects)
    if not worldItemObj or not invItem then return end

    local def = GAME_DEFS[invItem:getFullType()]
    if not def then return end

    if test then
        -- tells the game “yes this will add something to the menu”
        return true
    end

    local eval = evaluateBoardGamePlay(playerObj, invItem)
    if not eval then return false end -- not a boardgame item

    if not eval.ok then
        addDisabledOptionWithTooltip(context, eval.label, eval.tooltip)
    else
        -- IMPORTANT: context menu callbacks are invoked later; capture only what you need.
        onPlayFromGround(
            context,
            playerObj,
            worldItemObj,
            invItem,
            eval.label,
            eval.duration,
            eval.boredom,
            eval.unhappy,
            eval.stress
        )
    end
end


Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)

