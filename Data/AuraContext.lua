--[[
The Context for Auras act a little different compared to the other context since the data is going to be dependant on the blizzard CDM.
Since the only way we can couple SpellID with auraInstanceID is through said frames, it is required by the user to add the buffs to the active part of the CDM to be registered.
]]
AuraContextManager = {
    contexts = {}, -- context registry
    contextSubscriptions = {}, -- { [key] = { [guid] = true } }
    
    auraIDToFrame = {}, -- auraInstanceID -> frame
    frameToContext = {}, -- frame -> context
    initialized = false
}

-- Initializes the context manager and builds the CDM cache
function AuraContextManager.Initialize()
    if AuraContextManager.initialized then
        return
    end
    
    AuraContextManager.ConnectFramesToContexts()
    
    hooksecurefunc(BuffIconCooldownViewer, "RefreshData", function(self, ...)
        print("RefreshData")
        AuraContextManager.ConnectFramesToContexts()
    end)

    
    hooksecurefunc(BuffIconCooldownViewer, "OnUnitAura", AuraContextManager.UpdateAuras)
    hooksecurefunc(BuffBarCooldownViewer, "OnUnitAura", AuraContextManager.UpdateAuras)
    AuraContextManager.initialized = true
end

-- Registers a new context to the manager
-- TODO: Handle the case where the context is already registered, and since we use names we should look what we do between handling SpellID vs Spell names; an aura could have multiple spellIDs connected!!!
function AuraContextManager.Register(sourceGuid, key)
    -- If the context doesn't exist, create it
    if not AuraContextManager.contextSubscriptions[key] then
        AuraContextManager.contextSubscriptions[key] = {}
        local context = AuraContext:new(key)
        AuraContextManager.contexts[key] = context
    end
    
    assert(not AuraContextManager.contextSubscriptions[key][sourceGuid], "Registering an already registered context")
    AuraContextManager.contextSubscriptions[key][sourceGuid] = true
end

-- Unregisters a context
function AuraContextManager.Unregister(sourceGuid, key)
    assert(AuraContextManager.contextSubscriptions[key][sourceGuid], "Unregistering an unregistered context")
    AuraContextManager.contextSubscriptions[key][sourceGuid] = nil

    if not next(AuraContextManager.contextSubscriptions[key]) then
        AuraContextManager.contextSubscriptions[key] = nil
        AuraContextManager.contexts[key] = nil
    end
end

-- Retrieves a context
function AuraContextManager.GetContext(key)
    return AuraContextManager.contexts[key]
end

-- Updates all contexts
function AuraContextManager.Update()
    for frame, context in pairs(AuraContextManager.frameToContext) do
        local auraInstanceID = frame:GetAuraSpellInstanceID()
        if auraInstanceID then
            context:Update(frame, auraInstanceID)
        end
    end
end

-- Rebuild the contexts from scratch (Might not be needed now)
function AuraContextManager.Rebuild()
    if InCombatLockdown() then
        return
    end
    
    for key, _ in pairs(AuraContextManager.contexts) do
        local new = AuraContext:new(key)
        AuraContextManager.contexts[key] = new
    end

    AuraContextManager.ConnectFramesToContexts()
end

-- Builds the connection between frames and contexts
function AuraContextManager.ConnectFramesToContexts()
    if InCombatLockdown() then
        return
    end

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
    AuraContextManager.frameToContext = frameToContext
end

---Update loop called when BuffIconCooldownViewer & BuffBarCooldownViewer gets aura updated
---@param manager table
---@param unit string
---@param updateInfo {isFullUpdate: boolean, addedAuras: table, updatedAuraInstanceIDs: table, removedAuraInstanceIDs: table}
function AuraContextManager.UpdateAuras(manager, unit, updateInfo)
    -- Update all tracked Auras
	if updateInfo.isFullUpdate then
        AuraContextManager.Update()
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

--- A data structure for representing an aura. 
--- ince the data is going to be dependant on the blizzard CDM, 
--- it is required by the user to add the buffs to the active part of the CDM to be registered.
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

--- Updates the context for the given frame and auraInstanceIDs.
--- If the frame is nil, the context will be reset
function AuraContext:Update(frame, auraInstanceID, auraData)
    if frame and auraInstanceID then
        assert(type(auraInstanceID) == "number", "AuraInstanceID must be a number")

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