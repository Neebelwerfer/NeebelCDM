--[[
The Context for Auras act a little different compared to the other context since the data is going to be dependant on the blizzard CDM.
Since the only way we can couple SpellID with auraInstanceID is through said frames, it is required by the user to add the buffs to the active part of the CDM to be registered.
]]


---@class AuraContext
---@field id number
---@field name string
---@field icon string
---@field isActive boolean
---@field stacks number
---@field duration { start: number, duration: number, modRate: number }
---@field remaining fun(): number


AuraContext = {}


function AuraContext.Create(key)
    local info = C_Spell.GetSpellInfo(key)

    CooldownViewerIntegration.BuildMap()

    local context = {
        id = key,
        name = info.name,
        icon = info.iconID,
        isActive = false,
        stacks = 0,
        duration = { start = 0, duration = 0, remaining = 0 },
        internal = {},
    }

    local frame = CooldownViewerIntegration.map[info.name]

    if frame then
        context.internal.frame = frame
        local auraInstanceID = frame:GetAuraSpellInstanceID()
        if auraInstanceID then
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID) or C_UnitAuras.GetAuraDataByAuraInstanceID("target", auraInstanceID)
            if aura then
                context.isActive = true
                local duration = C_UnitAuras.GetAuraDuration("player", aura.auraInstanceID) or C_UnitAuras.GetAuraDuration("target", aura.auraInstanceID)
                context.internal.duration = duration

                context.stacks = aura.applications
                context.isActive = true
                context.duration = { start = duration:GetStartTime(), duration = duration:GetTotalDuration(), modRate = duration:GetModRate() }

                context.duration.remaining = function()
                    if not context.internal.duration then return 0 end
                    print(context.internal.duration:GetRemainingDuration())
                    return context.internal.duration:GetRemainingDuration()
                end
            end
        else
            context.isActive = false
        end
    else
        context.internal.frame = nil
        context.isActive = false
    end


    return context
end