CooldownViewerIntegration = {
    map = {},
}

function CooldownViewerIntegration.BuildMap()
    if InCombatLockdown() then
        return
    end
    
    local map = {}

    for i,k in ipairs(BuffIconCooldownViewer:GetLayoutChildren()) do
        local spellID = k:GetSpellID()
        local info = C_Spell.GetSpellInfo(spellID)
        
        map[info.name] = k
    end

    for i,k in ipairs(BuffBarCooldownViewer:GetLayoutChildren()) do
        if k then
            local spellID = k:GetSpellID()
            if spellID then
                if issecretvalue(spellID) then
                    return
                end

                local info = C_Spell.GetSpellInfo(spellID)
                map[info.name] = k
            end
        end
    end

    CooldownViewerIntegration.map = map
end
