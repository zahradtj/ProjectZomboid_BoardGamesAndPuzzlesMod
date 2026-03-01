-- media/lua/client/TimedActions/ISWorkPuzzleFromGround.lua
require "TimedActions/ISBaseTimedAction"

local ISBaseTimedAction = _G.ISBaseTimedAction
local Puzzle_Thoughts = require "helpers/Puzzle_Thoughts"
local Core = require("BGP_PuzzlesCore")     -- match inventory version
local Req = require("BGP_Requirements")

ISWorkPuzzleFromGround = ISBaseTimedAction:derive("ISWorkPuzzleFromGround")

local function endActionNow(self)
    if self.forceStop then
        self:forceStop()
        return
    end
    self.currentTime = self.maxTime or 0
    self.maxTime = 0
end

function ISWorkPuzzleFromGround:isValid()
    if not self.worldItemObj then return false end
    if not self.item then return false end
    if self.worldItemObj:getItem() ~= self.item then return false end
    local sq = self.worldItemObj:getSquare()
    if not sq then return false end

    if not Req.isCharacterNearWorldItem(self.character, self.worldItemObj) then return false end

    if self.requireSurface and not Req.hasNearbySurface(self.character, 1) then return false end
    if self.requireLight and not Req.hasEnoughLight(self.character, 0.30) then return false end
    return true
end

function ISWorkPuzzleFromGround:start()
    -- Face the square so it feels like interacting with it
    local sq = self.worldItemObj:getSquare()
    if sq then
        self.character:faceLocation(sq:getX(), sq:getY())
    end

    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")

    local now = _G.getTimestampMs()

    -- Work + thoughts cadence (same as inventory)
    self.workEveryMs = self.workEveryMs or 2500
    self.nextWorkMs = now + self.workEveryMs

    self.nextThoughtMs = now + _G.ZombRand(2000, 6001)
    self.done = false
    self.lastRes = nil
end

function ISWorkPuzzleFromGround:update()
    if self.done then
        endActionNow(self)
        return
    end

    -- Keep facing it
    local sq = self.worldItemObj and self.worldItemObj:getSquare()
    if sq then
        self.character:faceLocation(sq:getX(), sq:getY())
    end

    local now = _G.getTimestampMs()

    -- 1) Apply incremental work during the action
    if self.nextWorkMs and now >= self.nextWorkMs then
        local res = Core.applyWorkResult(self.character, self.item, self.tuning or {})
        self.lastRes = res

        if res and res.isComplete then
            self.done = true
            self.lastRes = res

            -- Completion thought
            if Puzzle_Thoughts.showComplete then
                Puzzle_Thoughts.showComplete(self.character)
            end

            endActionNow(self)
            return
        end

        self.nextWorkMs = now + (self.workEveryMs or 2500)
    end

    -- 2) Thoughts while working
    if self.nextThoughtMs and now >= self.nextThoughtMs then
        if self.lastRes and self.lastRes.successes ~= nil then
            local line = Puzzle_Thoughts.pickWorkThought(self.lastRes.successes)
            if line then
                self.character:Say(line)
            end
        else
            -- If you still have any legacy show() that expects successes, keep it simple:
            if _G.ZombRand(100) < 35 then
                if Puzzle_Thoughts.show then
                    Puzzle_Thoughts.show(self.character, 0)
                end
            end
        end

        self.nextThoughtMs = now + _G.ZombRand(4000, 10001)
    end
end

function ISWorkPuzzleFromGround:stop()
    ISBaseTimedAction.stop(self)
end

function ISWorkPuzzleFromGround:perform()
    -- No extra work application here (update() already did it)
    if self.lastRes and self.lastRes.isComplete then
        -- already handled in update; nothing required
    elseif self.lastRes and self.lastRes.successes ~= nil then
        local line = Puzzle_Thoughts.pickWorkThought(self.lastRes.successes)
        if line then self.character:Say(line) end
    end

    ISBaseTimedAction.perform(self)
end

function ISWorkPuzzleFromGround:new(character, worldItemObj, invItem, duration, tuning)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.worldItemObj = worldItemObj
    o.item = invItem

    o.stopOnWalk = true
    o.stopOnRun = true
    o.useProgressBar = true

    o.maxTime = duration or 400
    o.tuning = tuning or {}

    o.boredomReduce = o.tuning.boredomReduce or 20
    o.unhappyReduce = o.tuning.unhappyReduce or 10
    o.stressReduce  = o.tuning.stressReduce  or 0.05

    o.requireSurface = o.tuning.requireSurface
    o.requireLight   = o.tuning.requireLight

    o.workEveryMs = o.tuning.workEveryMs or 2500

    return o
end

return ISWorkPuzzleFromGround