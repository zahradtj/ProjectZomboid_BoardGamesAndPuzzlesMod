-- media/lua/client/BoardGamesAndPuzzles/BGP_Tooltips.lua

require "ISUI/ISToolTip"

local M = {}

function M.addDisabledOptionWithTooltip(context, label, lines)
    local opt = context:addOption(label, nil, nil)
    opt.notAvailable = true

    local tt = ISToolTip:new()
    tt:initialise()
    tt:setVisible(false)
    tt.description = table.concat(lines, "\n")
    opt.toolTip = tt

    return opt
end

return M
