-- media/lua/client/TimedActions/ISWorkPuzzleFromInventory.lua
require "TimedActions/ISBaseTimedAction"

local ISBaseTimedAction = _G.ISBaseTimedAction
local Puzzle_Thoughts = require "helpers/Puzzle_Thoughts"
local Core = require("BGP_PuzzlesCore")     -- ensure this is the correct module name/path
local Req = require("BGP_Requirements")

ISWorkPuzzleFromInventory = ISBaseTimedAction:derive("ISWorkPuzzleFromInventory")

function ISWorkPuzzleFromInventory:isValid()
    if not self.item then return false end

    if self.requireSurface and not Req.hasNearbySurface(self.character, 1) then return false end
    if self.requireLight and not Req.hasEnoughLight(self.character, 0.30) then return false end
    return true
end

function ISWorkPuzzleFromInventory:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")

    local now = _G.getTimestampMs()

    -- Work + thoughts cadence
    self.workEveryMs = self.workEveryMs or 2500          -- apply progress every 2.5s
    self.nextWorkMs = now + self.workEveryMs

    self.nextThoughtMs = now + _G.ZombRand(2000, 6001)   -- first thought 2–6s
    self.done = false
    self.lastRes = nil
end

local function endActionNow(self)
    -- Most reliable on many builds
    if self.forceStop then
        self:forceStop()
        return
    end

    -- Fallback: jump time to end
    self.currentTime = self.maxTime or 0
    self.maxTime = 0
end

function ISWorkPuzzleFromInventory:update()
    if self.done then
        endActionNow(self)
        return
    end

    local now = _G.getTimestampMs()

    -- 1) Apply incremental work during the action
    if self.nextWorkMs and now >= self.nextWorkMs then
        -- Apply one "work tick"
        local res = Core.applyWorkResult(self.character, self.item, self.tuning or {})
        self.lastRes = res

        -- If complete, end immediately
        if res and res.isComplete then
            self.done = true
            self.lastRes = res

            Puzzle_Thoughts.showComplete(self.character)

            -- End the action immediately (don’t keep animating)
            endActionNow(self)
            return
        end

        -- Schedule next work tick
        self.nextWorkMs = now + (self.workEveryMs or 2500)
    end

    -- 2) Thoughts while working (based on successes buckets)
    if self.nextThoughtMs and now >= self.nextThoughtMs then
        local ft = self.item and self.item:getFullType()

        -- If Core returned successes, use your bucketed thoughts
        if self.lastRes and self.lastRes.successes ~= nil then
            local line = Puzzle_Thoughts.pickWorkThought(self.lastRes.successes)
            if line then
                self.character:Say(line)
            end
        else
            -- Fallback neutral thought path
            if _G.ZombRand(100) < 35 then
                Puzzle_Thoughts.pickWorkThought((self.lastRes and self.lastRes.successes) or 0)
            end
        end

        self.nextThoughtMs = now + _G.ZombRand(4000, 10001)
    end
end

function ISWorkPuzzleFromInventory:stop()
    ISBaseTimedAction.stop(self)
end

function ISWorkPuzzleFromInventory:perform()
    -- Just show a final thought based on last result.
    local ft = self.item and self.item:getFullType()

    if self.lastRes and self.lastRes.outcome then
        if self.lastRes.isComplete then
            Puzzle_Thoughts.show(self.character, ft, "complete")
        elseif self.lastRes.successes ~= nil then
            local line = Puzzle_Thoughts.pickWorkThought(self.lastRes.successes)
            if line then self.character:Say(line) end
        end
    end

    ISBaseTimedAction.perform(self)
end

function ISWorkPuzzleFromInventory:new(character, item, duration, tuning)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.stopOnWalk = true
    o.stopOnRun = true
    o.useProgressBar = true

    o.maxTime = duration or 550
    o.tuning = tuning or {}

    o.boredomReduce = o.tuning.boredomReduce or 20
    o.unhappyReduce = o.tuning.unhappyReduce or 10
    o.stressReduce  = o.tuning.stressReduce  or 0.05

    o.requireSurface = o.tuning.requireSurface
    o.requireLight   = o.tuning.requireLight

    -- Allow caller to tune tick frequency
    o.workEveryMs = o.tuning.workEveryMs or 2500

    return o
end

return ISWorkPuzzleFromInventory