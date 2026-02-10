--[[
The Context for Auras act a little different compared to the other context since the data is going to be dependant on the blizzard CDM.
Since the only way we can couple SpellID with auraInstanceID is through said frames, it is required by the user to add the buffs to the active part of the CDM to be registered.
]]
AuraContextManager = {
    contexts = {},
    auraIDToFrame = {},

    CDMCache = {},
    frameToContext = {},
    initialized = false
}

function AuraContextManager.Initialize()
    if AuraContextManager.initialized then
        return
    end
    
    AuraContextManager.BuildCDMCache()
    
    hooksecurefunc(BuffIconCooldownViewer, "RefreshData", function(self, ...)
        print("RefreshData")
        AuraContextManager.BuildCDMCache()
    end)

    
    hooksecurefunc(BuffIconCooldownViewer, "OnUnitAura", AuraContextManager.UpdateAuras)
    hooksecurefunc(BuffBarCooldownViewer, "OnUnitAura", AuraContextManager.UpdateAuras)
    AuraContextManager.initialized = true
end

function AuraContextManager.Register(key)
    local context = AuraContext:new(key)
    AuraContextManager.contexts[key] = context
    return context
end

function AuraContextManager.Unregister(key)
    AuraContextManager.contexts[key] = nil
end

function AuraContextManager.GetContext(key)
    return AuraContextManager.contexts[key]
end


function AuraContextManager.Update()
end


function AuraContextManager.Rebuild()
    assert(not InCombatLockdown(), "Cannot rebuild while in combat")
    
    for key, _ in pairs(AuraContextManager.contexts) do
        local new = AuraContext:new(key)
        AuraContextManager.contexts[key] = new
    end

    AuraContextManager.BuildCDMCache()
end


function AuraContextManager.BuildCDMCache()
    assert(not InCombatLockdown(), "Cannot build CDM cache while in combat")

    local map = {}
    for _,k in ipairs(BuffIconCooldownViewer:GetLayoutChildren()) do
        local spellID = k:GetSpellID()
        if not spellID or issecretvalue(spellID) then return end
        local info = C_Spell.GetSpellInfo(spellID)
        map[info.name] = k
    end

    for _,k in ipairs(BuffBarCooldownViewer:GetLayoutChildren()) do
        if k then
            local spellID = k:GetSpellID()
            if spellID then
                if issecretvalue(spellID) then return end
                local info = C_Spell.GetSpellInfo(spellID)
                map[info.name] = k
            end
        end
    end

    local frameToContext = {}
    for _,v in pairs(AuraContextManager.contexts) do
        local frame = map[v.name]
        if frame then
            frameToContext[frame] = v

            local auraInstanceID = frame:GetAuraSpellInstanceID()
            if auraInstanceID then
                AuraContextManager.auraIDToFrame[auraInstanceID] = frame
                v:Update(frame, auraInstanceID)
            end
        end
    end

    AuraContextManager.CDMCache = map
    AuraContextManager.frameToContext = frameToContext
end

---Update loop called when BuffIconCooldownViewer & BuffBarCooldownViewer gets aura updated
---@param manager any
---@param unit any
---@param updateInfo any
function AuraContextManager.UpdateAuras(manager, unit, updateInfo)
    -- Update all tracked Auras
	if updateInfo.isFullUpdate then
        for frame, context in pairs(AuraContextManager.frameToContext) do
            local auraInstanceID = frame:GetAuraSpellInstanceID()
            if auraInstanceID then
                context:Update(frame, auraInstanceID)
            end
        end
    end

    -- Find and connect auraInstanceID with spell data so we can update the contexts later
	if updateInfo.addedAuras then
		for _, v in pairs(updateInfo.addedAuras) do
            local frames = BuffIconCooldownViewer.auraInstanceIDToItemFramesMap[v.auraInstanceID] or BuffBarCooldownViewer.auraInstanceIDToItemFramesMap[v.auraInstanceID]
            if frames and #frames > 0 then
                if #frames > 1 then print("multiple frames!!") end -- Will probably not happen?
                local frame = frames[1]
                local context = AuraContextManager.frameToContext[frame]
                if context then
                    print("Updating", context.name, v.auraInstanceID)
                    context:Update(frame, v.auraInstanceID, v)
                end
                AuraContextManager.auraIDToFrame[v.auraInstanceID] = frame
            end
		end
    end

    -- Update the specific contexts
	if updateInfo.updatedAuraInstanceIDs then
		for _, v in pairs(updateInfo.updatedAuraInstanceIDs) do
            local frame = AuraContextManager.auraIDToFrame[v]
            if frame then
                local context = AuraContextManager.frameToContext[frame]
                if context then
                    print("Updating", context.name, v)
                    context:Update(frame, v)
                end
            end
		end
	end

    -- Remove the specific auraInstanceID mappings
	if updateInfo.removedAuraInstanceIDs then
		for _, v in pairs(updateInfo.removedAuraInstanceIDs) do
            local frame = AuraContextManager.auraIDToFrame[v]
            if frame then
                print("Removed",frame, v)
                local context = AuraContextManager.frameToContext[frame]
                if context then
                    context:Update()
                end
            end
			AuraContextManager.auraIDToFrame[v] = nil
		end
	end
end

---@class AuraContext
---@field id number
---@field name string
---@field icon string
---@field isActive boolean
---@field stacks number
---@field duration { start: number, duration: number, modRate: number }
---@field remaining fun(): number

AuraContext = {}
AuraContext.__index = AuraContext

function AuraContext:new(key)
    local info = C_Spell.GetSpellInfo(key)

    local context = {
        id = key,
        name = info.name,
        icon = info.iconID,
        isActive = false,
        stacks = 0,
        duration = { start = 0, duration = 0, remaining = 0 },
        internal = { info = info, duration = nil },
    }

    context.duration.remaining = function()
        if not self.internal.duration then return 0 end
        print(self.internal.duration:GetRemainingDuration())
        return self.internal.duration:GetRemainingDuration()
    end

    setmetatable(context, self)
    return context
end

function AuraContext:Update(frame, auraInstanceID, auraData)
    if frame and auraInstanceID then
        local aura = auraData or C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID) or C_UnitAuras.GetAuraDataByAuraInstanceID("target", auraInstanceID)
        if aura then
            local duration = C_UnitAuras.GetAuraDuration("player", aura.auraInstanceID) or C_UnitAuras.GetAuraDuration("target", aura.auraInstanceID)
            self.internal.duration = duration

            self.stacks = aura.applications
            self.isActive = true
            self.duration = { start = duration:GetStartTime(), duration = duration:GetTotalDuration(), modRate = duration:GetModRate() }
        end
    else
        self.stacks = 0
        self.duration = { start = 0, duration = 0, modRate = 0 }
        self.isActive = false
    end
end