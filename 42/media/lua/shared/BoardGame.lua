-- Enum-like constants for board game item full types

local MOD = "BoardGamesAndPuzzlesMod"

local BoardGame = {
  AxisAndAllies      = MOD .. ".AxisAndAllies",
  B17QueenOfTheSkies = MOD .. ".B17QueenOfTheSkies",
  Backgammon         = MOD .. ".Backgammon",
  Boggle             = MOD .. ".Boggle",
  CandyLand          = MOD .. ".CandyLand",
  Checkers           = MOD .. ".Checkers",
  Chess              = MOD .. ".Chess",
  Clue               = MOD .. ".Clue",
  Go                 = MOD .. ".Go",
  Mastermind         = MOD .. ".Mastermind",
  Monopoly           = MOD .. ".Monopoly",
  Operation          = MOD .. ".Operation",
  Risk               = MOD .. ".Risk",
  Scrabble           = MOD .. ".Scrabble",
  SnakesAndLadders   = MOD .. ".SnakesAndLadders",
  Sorry              = MOD .. ".Sorry",
  TheGameOfLife      = MOD .. ".TheGameOfLife",
  Trouble            = MOD .. ".Trouble",
  TrivialPursuit     = MOD .. ".TrivialPursuit",
  Yahtzee            = MOD .. ".Yahtzee",
}

-- make it read-only (helps catch typos like BoardGame.Chees)
setmetatable(BoardGame, {
  __newindex = function()
    error("BoardGame enum is read-only", 2)
  end
})

return BoardGame
