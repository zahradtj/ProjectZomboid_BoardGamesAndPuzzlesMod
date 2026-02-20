-- media/lua/client/BoardGamesAndPuzzles/BGP_GameDefs.lua

local BoardGame = require("BoardGame")

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
    [BoardGame.AxisAndAllies] = {
      default = DEFAULT_GAME_HARD,
      name = "Axis and Allies",
      duration = 67500,
      boredomReduce = 35,
      unhappyReduce = 18,
      stressReduce = 12,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.B17QueenOfTheSkies] = {
      default = DEFAULT_GAME_HARD,
      name = "B17 Queen of the Skies",
      duration = 22500,
      boredomReduce = 38,
      unhappyReduce = 20,
      stressReduce = 10,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Backgammon] = {
      default = DEFAULT_GAME_EASY,
      name = "Backgammon",
      duration = 5060,
      boredomReduce = 18,
      unhappyReduce = 8,
      stressReduce = 12,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Boggle] = {
      default = DEFAULT_GAME_HARD,
      name = "Boggle",
      duration = 3750,
      boredomReduce = 15,
      unhappyReduce = 6,
      stressReduce = 8,
      clumsyImpacted = false,
      usesBattery = false,
    },

    [BoardGame.CandyLand] = {
      default = DEFAULT_GAME_BASIC,
      name = "Candy Land",
      duration = 5060,
      boredomReduce = 8,
      unhappyReduce = 4,
      stressReduce = 5,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Checkers] = {
      default = DEFAULT_GAME_BASIC,
      name = "Checkers",
      duration = 5060,
      boredomReduce = 15,
      unhappyReduce = 8,
      stressReduce = 12,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Chess] = {
      default = DEFAULT_GAME_EASY,
      name = "Chess",
      duration = 11250,
      boredomReduce = 20,
      unhappyReduce = 10,
      stressReduce = 15,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Clue] = {
      default = DEFAULT_GAME_MEDIUM,
      name = "Clue",
      duration = 16875,
      boredomReduce = 20,
      unhappyReduce = 10,
      stressReduce = 8,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Go] = {
      default = DEFAULT_GAME_BASIC,
      name = "Go",
      duration = 22500,
      boredomReduce = 22,
      unhappyReduce = 10,
      stressReduce = 15,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Mastermind] = {
      default = DEFAULT_GAME_EASY,
      name = "Mastermind",
      duration = 5060,
      boredomReduce = 12,
      unhappyReduce = 6,
      stressReduce = 8,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Monopoly] = {
      default = DEFAULT_GAME_MEDIUM,
      name = "Monopoly",
      duration = 45000,
      boredomReduce = 28,
      unhappyReduce = 15,
      stressReduce = 10,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Operation] = {
      default = DEFAULT_GAME_BASIC,
      name = "Operation",
      duration = 2250,
      boredomReduce = 12,
      unhappyReduce = 5,
      stressReduce = 5,
      clumsyImpacted = true,
      usesBattery = true,
    },

    [BoardGame.Risk] = {
      default = DEFAULT_GAME_MEDIUM,
      name = "Risk",
      duration = 45000,
      boredomReduce = 30,
      unhappyReduce = 15,
      stressReduce = 12,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Scrabble] = {
      default = DEFAULT_GAME_HARD,
      name = "Scrabble",
      duration = 19690,
      boredomReduce = 25,
      unhappyReduce = 12,
      stressReduce = 10,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.SnakesAndLadders] = {
      default = DEFAULT_GAME_BASIC,
      name = "Snakes and Ladders",
      duration = 11250,
      boredomReduce = 8,
      unhappyReduce = 4,
      stressReduce = 5,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Sorry] = {
      default = DEFAULT_GAME_EASY,
      name = "Sorry",
      duration = 11250,
      boredomReduce = 15,
      unhappyReduce = 8,
      stressReduce = 10,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.TheGameOfLife] = {
      default = DEFAULT_GAME_MEDIUM,
      name = "The Game of Life",
      duration = 16875,
      boredomReduce = 20,
      unhappyReduce = 10,
      stressReduce = 8,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.TrivialPursuit] = {
      default = DEFAULT_GAME_HARD,
      name = "Trivial Pursuit",
      duration = 19690,
      boredomReduce = 25,
      unhappyReduce = 12,
      stressReduce = 10,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Trouble] = {
      default = DEFAULT_GAME_BASIC,
      name = "Trouble",
      duration = 11250,
      boredomReduce = 12,
      unhappyReduce = 6,
      stressReduce = 8,
      clumsyImpacted = true,
      usesBattery = false,
    },

    [BoardGame.Yahtzee] = {
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

return {
    GAME_DEFS = GAME_DEFS,
}
