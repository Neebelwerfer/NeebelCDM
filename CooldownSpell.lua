CooldownSpell = {}
CooldownSpell.__index = CooldownSpell

function CooldownSpell:new(cooldownId)
    local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownId)
    local spell = C_Spell.GetSpellInfo(info.spellID)
    local charges = C_Spell.GetSpellCharges(info.spellID)
    
    local new = {}
    new.id = spell.spellID
    new.name = spell.name
    new.iconId = spell.iconID
    new.castTime = spell.castTime
    new.minRange = spell.minRange
    new.maxRange = spell.maxRange
    new.hasCharges =  charges and charges.currentCharges > 0
    new.hasAura = info.hasAura
    new.selfAura = info.selfAura
    new.linkedSpellIDs = info.linkedSpellIDs
    new.flags = info.flags

    setmetatable(new, CooldownSpell)
    return new
end

