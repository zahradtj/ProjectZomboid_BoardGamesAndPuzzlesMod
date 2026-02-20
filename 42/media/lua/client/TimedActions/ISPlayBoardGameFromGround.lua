require "TimedActions/ISBaseTimedAction"

local ISBaseTimedAction = _G.ISBaseTimedAction
local BoardGame_Thoughts = require "helpers/BoardGame_Thoughts"
local Operation = require "BoardGamesAndPuzzlesMod_Operation"


ISPlayBoardGameFromGround = ISBaseTimedAction:derive("ISPlayBoardGameFromGround")

function ISPlayBoardGameFromGround:isValid()
    -- Still exists on the ground?
    if not self.worldItemObj then return false end
    if self.worldItemObj:getItem() ~= self.invItem then return false end
    if self.worldItemObj:getSquare() == nil then return false end
    if self.requireSurface and not hasNearbySurface(self.character, 1) then
        return false
    end
    if self.requireLight and not hasEnoughLight(self.character, 0.30) then
        return false
    end
    return true
end

function ISPlayBoardGameFromGround:start()
    -- Face the square so it feels like interacting with it
    local sq = self.worldItemObj:getSquare()
    if sq then
        self.character:faceLocation(sq:getX(), sq:getY())
    end

    self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Mid")
    -- next thought 2–6 seconds from now
    self.nextThoughtMs = _G.getTimestampMs() + _G.ZombRand(2000, 6001)
end

function ISPlayBoardGameFromGround:update()
    -- Keep facing it
    local sq = self.worldItemObj:getSquare()
    if sq then
        self.character:faceLocation(sq:getX(), sq:getY())
    end

    -- Thoughts
    local now = _G.getTimestampMs()
    if not self.nextThoughtMs or now < self.nextThoughtMs then return end

    local fullType = self.item and self.item:getFullType()

    if _G.ZombRand(100) < 35 then
        BoardGame_Thoughts.show(self.character, fullType, "neutral")
    end

    -- schedule next thought 4–10 seconds out
    self.nextThoughtMs = now + _G.ZombRand(4000, 10001)
end

function ISPlayBoardGameFromGround:stop()
    ISBaseTimedAction.stop(self)
end

function ISPlayBoardGameFromGround:perform()
    local stats = self.character:getStats()

    if stats and stats.remove then
        stats:remove(CharacterStat.BOREDOM, self.boredomReduce)
        stats:remove(CharacterStat.STRESS, self.stressReduce)
        stats:remove(CharacterStat.UNHAPPINESS, self.unhappyReduce)
    end


    if Operation.isOperationItem(self.item) then
        Operation.doPlayOperation(self.character, self.item)
    else
        local fullType = self.item and self.item:getFullType()
        if _G.ZombRand(100) < 50 then
            BoardGame_Thoughts.show(self.character, fullType, "success")
        else
            BoardGame_Thoughts.show(self.character, fullType, "failure")
        end
    end

    ISBaseTimedAction.perform(self)
end

function ISPlayBoardGameFromGround:new(character, worldItemObj, invItem, duration, boredomReduce, unhappyReduce, stressReduce)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.worldItemObj = worldItemObj
    o.invItem = invItem
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = duration or 400
    o.boredomReduce = boredomReduce or 20
    o.unhappyReduce = unhappyReduce or 10
    o.stressReduce = stressReduce or 0.05
    return o
end

return ISPlayBoardGameFromGround