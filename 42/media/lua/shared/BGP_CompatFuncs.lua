local M = {}

function M.playerHasTrait(playerObj, traitId)
    if not playerObj or not traitId then return false end


    if playerObj.hasTrait then
        return playerObj:hasTrait(traitId) == true
    end

    -- Prefer the common API
    if playerObj.HasTrait then
        return playerObj:HasTrait(traitId) == true
    end

    -- Fallback: some builds expose traits via the TraitFactory/traits list
    local traits = playerObj.getTraits and playerObj:getTraits()
    if traits and traits.contains then
        -- Java collection: contains(string)
        return traits:contains(traitId) == true
    end

    return false
end

return M