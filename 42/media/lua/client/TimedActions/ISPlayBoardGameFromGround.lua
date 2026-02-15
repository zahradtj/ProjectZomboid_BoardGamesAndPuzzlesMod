require "TimedActions/ISBaseTimedAction"

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

    -- Optional: set an animation variable / play a sound / etc.
    -- self:setActionAnim("Bob_IdleRollDice") -- or something that looks okay
    -- self:setActionAnim("Bob_IdleCube") -- or something that looks okay
    self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Mid")
end

function ISPlayBoardGameFromGround:update()
    -- Keep facing it
    local sq = self.worldItemObj:getSquare()
    if sq then
        self.character:faceLocation(sq:getX(), sq:getY())
    end
end

function ISPlayBoardGameFromGround:perform()
    local stats = self.character:getStats()

    if stats and stats.remove then
        print("[BGP] moodles before play - bored: ", stats:get(CharacterStat.BOREDOM), " stress: ", stats:get(CharacterStat.STRESS), " unhappy: ", stats:get(CharacterStat.UNHAPPINESS))
        stats:remove(CharacterStat.BOREDOM, self.boredomReduce)
        stats:remove(CharacterStat.STRESS, self.stressReduce)
        stats:remove(CharacterStat.UNHAPPINESS, self.unhappyReduce)
        print("[BGP] moodles after play - bored: ", stats:get(CharacterStat.BOREDOM), " stress: ", stats:get(CharacterStat.STRESS), " unhappy: ", stats:get(CharacterStat.UNHAPPINESS))
    end

    -- Example: degrade battery/condition/etc. without picking it up:
    -- self.invItem:setCondition(self.invItem:getCondition() - 1)

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
