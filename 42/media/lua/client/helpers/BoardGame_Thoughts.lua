-- Use: local line = BoardGame_Thoughts.pick("chess", "neutral")  -- or "success"/"failure"
local BoardGame = require("BoardGame")

BoardGame_Thoughts = BoardGame_Thoughts or {}

BoardGame_Thoughts.lines = {
    [BoardGame.AxisAndAllies] = {
        neutral = {
            "Numbers on a map. Graves in my head.",
            "Plan like it'll matter.",
            "Supply lines. Broken bones.",
            "I can't cover every border.",
            "Choose where to bleed.",
            "War on paper still feels heavy.",
        },
        success = {
            "Held the line.",
            "One front survives. Barely.",
            "A counterattack that actually lands.",
            "Good. The push didn't crack me.",
            "I took ground and kept it.",
            "Tonight, I win. That's enough.",
        },
        failure = {
            "Collapsed. Too many holes.",
            "Lost the war one choice at a time.",
            "I spread thin and paid for it.",
            "Everything I ignored came back.",
            "The front breaks. Then I do.",
            "Retreat again. Count the dead.",
        },
    },

    [BoardGame.B17QueenOfTheSkies] = {
        neutral = {
            "Keep her steady. Bring someone home.",
            "Flak doesn't care if you pray.",
            "Hold formation. Hold yourself together.",
            "Engines hum like a dying animal.",
            "Count the bullets. Count the fear.",
            "Just get through the run.",
        },
        success = {
            "We made it back. Somehow.",
            "Not today. Today we live.",
            "Landed hard, but landed.",
            "Crew intact. That's everything.",
            "Good. The sky missed us.",
            "Home again… for now.",
        },
        failure = {
            "Hit bad. Real bad.",
            "Another crew lost in my head.",
            "She’s going down. I knew it.",
            "Too much flak. Too little luck.",
            "We don't make it. Not this time.",
            "The sky takes what it wants.",
        },
    },

    [BoardGame.Backgammon] = {
        neutral = {
            "Don't leave it exposed.",
            "One bad roll, one bad day.",
            "Count pips. Count problems.",
            "Keep the board tight. Keep calm.",
            "I miss certainty. Dice hate certainty.",
            "Move clean. No gifts.",
        },
        success = {
            "Hit. Good. Keep pressure.",
            "Clean run home.",
            "A roll that finally helps.",
            "I cornered it. I finished it.",
            "Good. No blots, no mercy.",
            "Homeward. Like I wish I was.",
        },
        failure = {
            "Left a blot. Paid for it.",
            "Pinned down. Nowhere to go.",
            "The dice turned and so did fate.",
            "I got hit and felt it.",
            "Stuck on the bar. Again.",
            "I should've played safer. Too late.",
        },
    },

    [BoardGame.Boggle] = {
        neutral = {
            "Letters in a box. Thoughts in a cage.",
            "Find a word. Any word.",
            "My mind drifts. Drag it back.",
            "Three minutes of silence, please.",
            "Spell something. Prove I'm here.",
            "Don't freeze. Don't blank out.",
        },
        success = {
            "There. Something real.",
            "I'm still sharp enough.",
            "I found it. I kept up.",
            "A long word. A small triumph.",
            "My brain still sparks sometimes.",
            "Good. I can still think fast.",
        },
        failure = {
            "Nothing. My mind's empty.",
            "Time's up. I'm slower now.",
            "I stare and see nothing.",
            "Words slip away like water.",
            "Too tired to search.",
            "I lost the clock. I lost myself.",
        },
    },

    [BoardGame.CandyLand] = {
        neutral = {
            "Bright colors. Empty comfort.",
            "Keep moving. That's all.",
            "It’s sweetness painted over rot.",
            "No choices. Just draw and drift.",
            "I remember when this felt safe.",
            "Smile if you can. I can't.",
        },
        success = {
            "Almost there. Don't stop.",
            "A good draw. A rare thing.",
            "Forward. Finally forward.",
            "For a second, it feels light.",
            "I get closer. That's enough.",
            "Okay. One less detour.",
        },
        failure = {
            "Dragged back. Figures.",
            "It never lets you finish clean.",
            "Back again. Like I'm cursed.",
            "All color, no mercy.",
            "The game laughs quietly.",
            "Another setback. Another breath.",
        },
    },

    [BoardGame.Checkers] = {
        neutral = {
            "Simple rules. Hard lessons.",
            "Wait. Set the trap.",
            "Don't rush. Don't bleed pieces.",
            "Move like it costs you food.",
            "I can’t afford impatience.",
            "Quiet board. Loud thoughts.",
        },
        success = {
            "Kinged. Finally.",
            "Took the piece. Took the breath with it.",
            "Clean jump. Clean win.",
            "I forced it. I earned it.",
            "Good. The plan worked.",
            "For once, I outlasted it.",
        },
        failure = {
            "Walked right into it.",
            "Outplayed. Outlasted.",
            "I lost control in one move.",
            "Too tired to see the trap.",
            "My pieces vanish like people.",
            "I should have waited. I didn't.",
        },
    },

    [BoardGame.Chess] = {
        neutral = {
            "Quiet. Think. Don't waste moves.",
            "Every piece is one more thing to lose.",
            "I can’t afford mistakes. Even here.",
            "Trade safely. Survive the endgame.",
            "My head’s heavy. Keep it simple.",
            "One move at a time. That's all.",
        },
        success = {
            "That was clean. For once.",
            "Small win. Still breathing.",
            "Good. A plan that actually held.",
            "I saw it coming. I stopped it.",
            "A little control, in a broken world.",
            "Not proud. Just… relieved.",
        },
        failure = {
            "I didn't see it. I never see it.",
            "Checkmate. Just like everything else.",
            "I handed it away. Again.",
            "Too tired to calculate. Too tired to care.",
            "One mistake and everything collapses.",
            "I should've slowed down. I didn't.",
        },
    },

    [BoardGame.Clue] = {
        neutral = {
            "Everyone's guilty of something.",
            "Watch what they hide.",
            "Follow the questions. Follow the cracks.",
            "Some truth always leaks.",
            "I’m tired of mysteries. Still here.",
            "Keep notes. Keep distance.",
        },
        success = {
            "I see it now.",
            "Solved. Cold and clear.",
            "The pieces finally fit.",
            "I called it. No hesitation.",
            "Truth, for once, stays still.",
            "Good. One question answered.",
        },
        failure = {
            "Wrong. Misread it.",
            "I accused the dark. The dark laughed.",
            "I guessed. I paid.",
            "The real answer slips past me.",
            "I trusted a pattern that wasn't there.",
            "Another mistake, neatly written down.",
        },
    },

    [BoardGame.Go] = {
        neutral = {
            "Surround. Breathe. Endure.",
            "Don't fight every battle.",
            "Shape first. Survival first.",
            "Every stone is a promise.",
            "Give ground to keep life.",
            "Quiet game. Loud loss.",
        },
        success = {
            "That group lives.",
            "Quiet territory. Quiet relief.",
            "I found the vital point.",
            "Alive. Barely, but alive.",
            "Good shape. Good breath.",
            "I saved what mattered.",
        },
        failure = {
            "Cut off. Suffocated.",
            "I thought it would live. It didn't.",
            "I read it wrong. It died.",
            "Everything collapses in silence.",
            "Too late to connect.",
            "I lose stones like I lose sleep.",
        },
    },

    [BoardGame.Mastermind] = {
        neutral = {
            "Test. Eliminate. Keep going.",
            "Patterns don't lie. People do.",
            "One clue at a time.",
            "Stay calm. Think cold.",
            "The answer is there. Hidden.",
            "I can solve this. I have to.",
        },
        success = {
            "Found it. Cracked the lock.",
            "One clean solve.",
            "I pinned it down. No escape.",
            "Good. The pattern broke.",
            "I was right. For once.",
            "Solved. Like a door opening.",
        },
        failure = {
            "Too many guesses. Not enough truth.",
            "I'm chasing shadows again.",
            "I ran out of turns and patience.",
            "The answer stayed buried.",
            "I circled it and still missed.",
            "Wrong code. Wrong life.",
        },
    },

    [BoardGame.Monopoly] = {
        neutral = {
            "Money game. Like the old world died for nothing.",
            "Count bills. Count days.",
            "Build houses. Lose souls.",
            "Buy comfort. Sell time.",
            "Rent is just hunger with numbers.",
            "At least paper cuts don't bite.",
        },
        success = {
            "They're broke. I'm not.",
            "I built something that lasts... on paper.",
            "The deal worked. I survived it.",
            "A clean sweep. Cold and simple.",
            "I take what's mine. Nobody else will.",
            "Victory feels like relief, not joy.",
        },
        failure = {
            "Bankrupt. Same feeling, different name.",
            "One bad landing and it's over.",
            "I watched it coming. Did nothing.",
            "Debt wins. It always does.",
            "Hotels. Graves with windows.",
            "I fold. I lose. The world continues.",
        },
    },

    [BoardGame.Operation] = {
        neutral = {
            "Hands steady. Breathe through it.",
            "Don't shake. Not now.",
            "Focus. Ignore the hunger.",
            "Just a tiny move. No panic.",
            "If I mess up, it screams at me.",
            "My fingers feel like чужие. Still mine.",
        },
        success = {
            "Got it. No buzz. No pain.",
            "Still got control... somehow.",
            "Clean pull. No tremor.",
            "I did it right. Quietly.",
            "Steady. Like the old days.",
            "Good. One less thing to regret.",
        },
        failure = {
            "Buzz. Of course.",
            "My hands aren't what they were.",
            "Too rough. Too tired.",
            "I flinched. I always flinch.",
            "Even plastic bones punish me.",
            "Reset. Try again. Same ending.",
        },
    },

    [BoardGame.Risk] = {
        neutral = {
            "Hold ground. Don't get greedy.",
            "Everything falls apart if I rush.",
            "Consolidate. Breathe. Then move.",
            "I can't fight on every front.",
            "Sacrifice something, save something.",
            "This is just maps and loss.",
        },
        success = {
            "Took it. Cost me, but I took it.",
            "A foothold. That's enough.",
            "One territory closer to quiet.",
            "I pushed hard, and it held.",
            "Good. The line didn't break.",
            "I win here, because I must.",
        },
        failure = {
            "Overextended. Punished.",
            "Lost it all in one bad push.",
            "I gambled. The world laughed.",
            "Too many dice. Not enough sense.",
            "The front collapsed. So did I.",
            "Retreat. Like always. Like life.",
        },
    },

    [BoardGame.Scrabble] = {
        neutral = {
            "Make something out of scraps.",
            "Words don't feed you, but... still.",
            "Arrange the mess. Pretend it's order.",
            "Hold the good tiles. Wait.",
            "Quiet. Count. Place.",
            "If I had to, I'd eat these letters.",
        },
        success = {
            "That fit. That worked.",
            "Good placement. Good enough.",
            "Triple word. Finally.",
            "I made meaning out of junk.",
            "A strong play. No wasted pain.",
            "I win a little. I keep going.",
        },
        failure = {
            "Dead letters. Dead end.",
            "I can't make anything from this.",
            "All vowels. All emptiness.",
            "I burn a turn and feel it.",
            "I missed the spot. Of course.",
            "Even language turns on me.",
        },
    },

    [BoardGame.SnakesAndLadders] = {
        neutral = {
            "Climb. Fall. Repeat.",
            "No choices. Just consequences.",
            "Progress is an illusion.",
            "Up, down… same tired path.",
            "At least it ends eventually.",
            "Roll. Accept. Endure.",
        },
        success = {
            "A ladder. A way out—briefly.",
            "Up. For a moment.",
            "I rise without earning it.",
            "A break. I’ll take it.",
            "Higher. Not safe, but higher.",
            "Good. Something lifts me.",
        },
        failure = {
            "Snake. Down again.",
            "Every time I stand up, I drop.",
            "Of course it's a long fall.",
            "Hope lasts one roll.",
            "Back near the bottom. Familiar.",
            "Fine. Punish me for moving.",
        },
    },

    [BoardGame.Sorry] = {
        neutral = {
            "Just move the pieces. Keep busy.",
            "It's cruel, but it's simple.",
            "No strategy. Just waiting for pain.",
            "Push forward. Get knocked back.",
            "The rules feel personal.",
            "At least it's predictable cruelty.",
        },
        success = {
            "Back to start. Good.",
            "At least something went my way.",
            "Little revenge. Little relief.",
            "One clean hit. No mercy.",
            "I didn't hesitate. I can't.",
            "Good. Someone else suffers for once.",
        },
        failure = {
            "Sent home. Again.",
            "No matter how close, I lose ground.",
            "So close. Then nothing.",
            "Punished for moving at all.",
            "I should've expected it.",
            "Reset. Start over. Story of me.",
        },
    },

    [BoardGame.TheGameOfLife] = {
        neutral = {
            "So this is what 'normal' looked like.",
            "Spin the wheel. Watch it decide.",
            "Choices with no consequences. Lucky.",
            "I miss having problems like this.",
            "Life on cardboard. Cleaner than mine.",
            "Keep going. It's what I do.",
        },
        success = {
            "A lucky break. Feels strange.",
            "I made it through that part.",
            "For once, it didn’t sting.",
            "A gentle turn. Rare.",
            "I land safe. I breathe.",
            "Good. One less weight on me.",
        },
        failure = {
            "Bad turn. Story of my life.",
            "Should've known better than to hope.",
            "The wheel never favors me.",
            "Every road ends in debt.",
            "Even pretend life hurts.",
            "I take the hit. I always do.",
        },
    },

    [BoardGame.TrivialPursuit] = {
        neutral = {
            "Dig it up. Somewhere in my head.",
            "I used to know things.",
            "My memory’s a ruined house.",
            "Think. The answer's buried.",
            "Old facts, like old scars.",
            "I miss caring about this.",
        },
        success = {
            "Yeah. I remember.",
            "One right answer. A tiny victory.",
            "Still in there. Still mine.",
            "That used to be easy.",
            "A scrap of the old me survived.",
            "Good. Something I didn't lose.",
        },
        failure = {
            "Blank. Just static.",
            "Doesn't matter what I knew before.",
            "My mind slips when I need it.",
            "I can’t pull it up. Not anymore.",
            "All that learning… for nothing.",
            "Wrong again. Add it to the pile.",
        },
    },

    [BoardGame.Trouble] = {
        neutral = {
            "Pop the bubble. Make the noise. Feel nothing.",
            "Six. Please. Just once.",
            "Small hopes. Small humiliations.",
            "The pop is louder than my thoughts.",
            "Move forward. Get punished.",
            "This is what passing time looks like.",
        },
        success = {
            "There it is. Move.",
            "Home stretch. Don't jinx it.",
            "A six. A miracle.",
            "I slip through before it hurts me.",
            "Good. Progress without pain.",
            "Almost done. Almost safe.",
        },
        failure = {
            "Not a six. Never a six.",
            "Sent back. Again. Of course.",
            "So close. Then reset.",
            "I hate how predictable this is.",
            "Back to the start. Again me.",
            "The bubble laughs at me.",
        },
    },

    [BoardGame.Yahtzee] = {
        neutral = {
            "Roll. Count. Pretend it matters.",
            "Odds don't care if I'm tired.",
            "My hands shake, but the dice don't.",
            "Numbers are honest. People weren't.",
            "Keep the score. Keep moving.",
            "Maybe luck still exists. Maybe not.",
        },
        success = {
            "Finally. Something breaks my way.",
            "Good roll. I'll take what I can get.",
            "A clean hit. No questions asked.",
            "For once, the world gives back.",
            "I’ll remember this. For a minute.",
            "Not joy. Just a quiet yes.",
        },
        failure = {
            "Garbage. Again.",
            "Luck's gone. Same as always.",
            "All noise, no help.",
            "The dice hate me like everything else.",
            "I needed one thing. I got nothing.",
            "Fine. Put it in the gutter column.",
        },
    },
}

-- Random line picker
function BoardGame_Thoughts.pick(gameKey, mood)
    local g = BoardGame_Thoughts.lines[gameKey]
    if not g then return nil end
    local arr = g[mood] or g.neutral
    if not arr or #arr == 0 then return nil end
    return arr[ZombRand(#arr) + 1]
end

-- mood: "neutral"|"success"|"failure"
function BoardGame_Thoughts.show(player, gameKey, mood)
    print("BGP - show thought")
    local line = BoardGame_Thoughts.pick(gameKey, mood)
    print("BGP - line: ", line)
    if not line then return end

    -- colors (0..1 floats)
    local r,g,b = 1.0, 1.0, 1.0
    if mood == "success" then r,g,b = 0.2, 1.0, 0.2
    elseif mood == "failure" then r,g,b = 1.0, 0.2, 0.2
    end

    player:addLineChatElement(line, r, g, b)
end

return BoardGame_Thoughts