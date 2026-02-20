-- media/lua/client/BoardGamesAndPuzzles/BGP_init.lua

--require("BoardGamesAndPuzzlesMod_Games").init()

local MenuHandlers = require("BGP_MenuHandlers")

Events.OnFillWorldObjectContextMenu.Add(MenuHandlers.OnFillWorldObjectContextMenu)
Events.OnFillInventoryObjectContextMenu.Add(MenuHandlers.OnFillInventoryObjectContextMenu)