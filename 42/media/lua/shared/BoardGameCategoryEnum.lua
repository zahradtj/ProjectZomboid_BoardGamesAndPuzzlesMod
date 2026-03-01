-- Enum-like constants for board game categories

local BoardGameCategoryEnum = {
  Kids      = "kids",
  Family    = "family",
  Brain     = "brain",
  Hobby     = "hobby",
  Misc      = "misc",
}

setmetatable(BoardGameCategoryEnum, {
  __newindex = function()
    error("BoardGameCategoryEnum enum is read-only", 2)
  end
})

return BoardGameCategoryEnum
