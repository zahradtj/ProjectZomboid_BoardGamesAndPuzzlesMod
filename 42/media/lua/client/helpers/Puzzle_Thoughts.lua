Puzzle_Thoughts = Puzzle_Thoughts or {}

-- Buckets:
--   none   = 0 successes
--   small  = 1-4
--   medium = 5-19
--   big    = 20+
Puzzle_Thoughts.Work = {
  none = {
    "Nothing. Not a single damn piece.",
    "All wrong. Again.",
    "This is just cardboard torture.",
    "No luck. My eyes are getting tired.",
    "I swear these pieces are mocking me.",
    "Dead end. I’m wasting daylight.",
    "Tried everything. Still nothing fits.",
    "Great. I made it worse in my head.",
    "Not even close. Just… no.",
    "I can’t see the picture at all.",
  },

  small = {
    "A few pieces. Better than staring at it.",
    "Something fit. I’ll take it.",
    "Slow going, but it’s moving.",
    "Found a match. Keep at it.",
    "Little wins. Still alive.",
    "That’s… what, two? Three? Good enough.",
    "Edges are starting to behave.",
    "Tiny progress beats no progress.",
    "One corner’s making sense.",
    "Not much, but it’s real.",
  },

  medium = {
    "Okay—this is actually working.",
    "That’s a decent run of matches.",
    "I’m getting a feel for it now.",
    "The picture’s starting to talk back.",
    "Steady hands. Keep sorting.",
    "Found a rhythm. Don’t break it.",
    "This pile’s shrinking. Finally.",
    "More fits than misses. Good.",
    "It’s messy, but it’s progress.",
    "I can see where the next bits go.",
  },

  big = {
    "Now it’s clicking.",
    "Finally—this is coming together.",
    "That’s a lot of matches. Keep pushing.",
    "I can see the picture forming.",
    "Hands are steady. Brain’s locked in.",
    "This is the kind of progress I need.",
    "Pieces are falling into place.",
    "I’m on a roll—don’t stop.",
    "Almost feels normal for a minute.",
    "Yeah… this might actually get finished.",
  },
}

Puzzle_Thoughts.Complete = {
    "Done. Every piece where it belongs.",
    "Complete. For once, something’s finished.",
    "That’s it. Picture’s whole.",
    "Finally. A clean ending.",
    "All together. No loose ends.",
    "Finished. Now I can breathe.",
}

function Puzzle_Thoughts.bucketForSuccesses(successes)
  successes = tonumber(successes) or 0
  if successes <= 0 then return "none" end
  if successes < 5 then return "small" end
  if successes < 20 then return "medium" end
  return "big"
end

function Puzzle_Thoughts.pickWorkThought(successes)
  local bucket = Puzzle_Thoughts.bucketForSuccesses(successes)
  local list = Puzzle_Thoughts.Work[bucket] or Puzzle_Thoughts.Work.small
  return list[ZombRand(#list) + 1]
end

function Puzzle_Thoughts.show(player, successes)
    local line = Puzzle_Thoughts.pickWorkThought(successes)
    if not line then return end

    -- colors (0..1 floats)
    local r,g,b = 1.0, 1.0, 1.0
    if Puzzle_Thoughts.bucketForSuccesses(successes) == "big" then r,g,b = 0.2, 1.0, 0.2
    elseif Puzzle_Thoughts.bucketForSuccesses(successes) == "none" then r,g,b = 1.0, 0.2, 0.2
    end

    player:addLineChatElement(line, r, g, b)
end

function Puzzle_Thoughts.showComplete(player)
    local r,g,b = 0.2, 1.0, 0.2

    local list = Puzzle_Thoughts.Complete
    local line = list[ZombRand(#list) + 1]
    player:addLineChatElement(line, r, g, b)
end

return Puzzle_Thoughts