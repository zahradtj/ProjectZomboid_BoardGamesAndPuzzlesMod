require "TimedActions/ISBaseTimedAction"
require "helpers/BoardGame_Thoughts"
require "BoardGamesAndPuzzlesMod_Operation"

ISPlayBoardGameFromInventory = ISBaseTimedAction:derive("ISPlayBoardGameFromInventory")

function ISPlayBoardGameFromInventory:isValid()
    if self.requireSurface and not hasNearbySurface(self.character, 1) then
        return false
    end
    if self.requireLight and not hasEnoughLight(self.character, 0.30) then
        return false
    end
    return true
end

function ISPlayBoardGameFromInventory:start()
    self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Mid")
    -- next thought 2–6 seconds from now
    self.nextThoughtMs = getTimestampMs() + ZombRand(2000, 6001)
end

function ISPlayBoardGameFromInventory:update()
    local now = getTimestampMs()
    if not self.nextThoughtMs or now < self.nextThoughtMs then return end

    local fullType = self.item and self.item:getFullType()

    if ZombRand(100) < 35 then
        BoardGame_Thoughts.show(self.character, fullType, "neutral")
    end

    -- schedule next thought 4–10 seconds out
    self.nextThoughtMs = now + ZombRand(4000, 10001)
end

function ISPlayBoardGameFromInventory:stop()
    ISBaseTimedAction.stop(self)
end

function ISPlayBoardGameFromInventory:perform()
    local stats = self.character:getStats()

    if stats and stats.remove then
        print("[BGP] moodles before play - bored: ", stats:get(CharacterStat.BOREDOM), " stress: ", stats:get(CharacterStat.STRESS), " unhappy: ", stats:get(CharacterStat.UNHAPPINESS))
        stats:remove(CharacterStat.BOREDOM, self.boredomReduce)
        stats:remove(CharacterStat.STRESS, self.stressReduce)
        stats:remove(CharacterStat.UNHAPPINESS, self.unhappyReduce)
        print("[BGP] moodles after play - bored: ", stats:get(CharacterStat.BOREDOM), " stress: ", stats:get(CharacterStat.STRESS), " unhappy: ", stats:get(CharacterStat.UNHAPPINESS))
    end

    if BoardGamesAndPuzzlesMod_Operation.isOperationItem(self.item) then
        BoardGamesAndPuzzlesMod_Operation.doPlayOperation(self.character, self.item)
    else
        local fullType = self.item and self.item:getFullType()
        if ZombRand(100) < 50 then
            BoardGame_Thoughts.show(self.character, fullType, "success")
        else
            BoardGame_Thoughts.show(self.character, fullType, "failure")
        end
    end

    ISBaseTimedAction.perform(self)
end


function ISPlayBoardGameFromInventory:new(character, item, duration, boredomReduce, unhappyReduce, stressReduce)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = duration or 400
    o.boredomReduce = boredomReduce or 20
    o.unhappyReduce = unhappyReduce or 10
    o.stressReduce = stressReduce or 0.05
    return o
end
