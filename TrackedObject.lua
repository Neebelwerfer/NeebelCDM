TrackedObject = {}
TrackedObject.__index = TrackedObject

local _, env = ...

function OnInit(frame)
    frame:SetScript("OnDragStart", function(self, button)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
end

FramePool = CreateFramePool("Frame", nil, "BackdropTemplate", nil, nil, OnInit)

function TrackedObject.CreateTrackedSpell(guid, id, parentFrame, config)
    guid = guid or GenerateGUID()

    local spell = env.spellLookup[id]
    if spell == nil then
        return nil
    end
    
    local item = TrackedObject:new(guid, TrackedObjectTypes.Spell, spell, parentFrame, config)
    return item
end


function TrackedObject:new(guid, type, data, parentFrame, config)
    local trackedObject = {}
    trackedObject.guid = guid
    trackedObject.type = type
    trackedObject.data = data
    
    trackedObject.config = config or {
        size = env.baseSize
    }

    trackedObject.internalState = {
        timers = {},
        currentTimerType = nil,
        timerIsDirty = false
    }
    
    trackedObject.frame = FramePool:Acquire()
    trackedObject.frame:SetParent(parentFrame)
    trackedObject.frame:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)
    trackedObject.frame:SetSize(trackedObject.config.size, trackedObject.config.size)
    trackedObject.frame.tex = trackedObject.frame:CreateTexture()
    trackedObject.frame.tex:SetAllPoints()
    trackedObject.frame.tex:SetTexture(data.iconId)
    trackedObject.frame:Show()

    if data.hasCharges then
        trackedObject.chargeFrame = CreateFrame("Frame", nil, trackedObject.frame, "BackdropTemplate")
        trackedObject.chargeFrame:SetAllPoints()
        
        trackedObject.charges = trackedObject.chargeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        trackedObject.charges:SetPoint("CENTER", trackedObject.frame, "BOTTOMRIGHT", -10, 10)

        local charges = C_Spell.GetSpellCharges(data.id)
        trackedObject.charges:SetText(tostring(charges.currentCharges))
    end

    trackedObject.Cooldown = CreateFrame("Cooldown", nil, trackedObject.frame, "CooldownFrameTemplate")
    trackedObject.Cooldown:SetAllPoints(trackedObject.frame)
    trackedObject.Cooldown:SetDrawEdge(false)
    trackedObject.Cooldown:SetDrawSwipe(true)
    trackedObject.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    trackedObject.Cooldown:SetReverse(false)
    
    setmetatable(trackedObject, TrackedObject)
    return trackedObject
end

function TrackedObject:SetPoint(point, offsetX, offsetY)
    self.frame:SetPoint(point, offsetX, offsetY)
end

function TrackedObject:Show()
    self.frame:Show()
end

function TrackedObject:Hide()
    self.frame:Hide()
end

function TrackedObject:Update(DirtyStateContext)
    if(DirtyStateContext["spellID"][self.data.id] or (self.data.hasCharges and DirtyStateContext["charges"])) then
        self.internalState.timers = {}
        
        if self.type == TrackedObjectTypes.Spell then
            if self.data.hasCharges then
                local charges = C_Spell.GetSpellCharges(self.data.id)
                if charges then
                    self.charges:SetText(tostring(charges.currentCharges))
                    local timer = self.CreateTimer(CDTimerTypes.Charge, charges.cooldownStartTime, charges.cooldownDuration, charges.chargeModRate)
                    table.insert(self.internalState.timers, timer)
                end
            end
            
            -- Not Great
            local auraByName = C_UnitAuras.GetAuraDataBySpellName("player", self.data.name, nil)

            if not auraByName and self.data.linkedSpellIDs and (self.data.selfAura or self.data.hasAura) then
                for _, linkedSpellId in pairs(self.data.linkedSpellIDs) do
                    local aura = C_UnitAuras.GetPlayerAuraBySpellID(linkedSpellId)
                    if aura then
                        local timer = self.CreateTimer(CDTimerTypes.Aura, aura.expirationTime - aura.duration, aura.duration, aura.modRate)
                        table.insert(self.internalState.timers, timer)
                    end
                end
            elseif auraByName then
                local timer = self.CreateTimer(CDTimerTypes.Aura, auraByName.expirationTime - auraByName.duration, auraByName.duration, auraByName.modRate)
                table.insert(self.internalState.timers, timer)
            end
            
            local cooldownData = C_Spell.GetSpellCooldown(self.data.id)
            if cooldownData and cooldownData.duration > 1 then
                local timer = self.CreateTimer(CDTimerTypes.Cooldown, cooldownData.startTime, cooldownData.duration, cooldownData.modRate)
                table.insert(self.internalState.timers, timer)
            end
        end

        self.internalState.timerIsDirty = true
        self.internalState.currentTimerType = nil
    end

    if #self.internalState.timers > 0 then
        local type = -1
        local timer = nil

        for _, t in ipairs(self.internalState.timers) do
            local isOld = t.startTime + t.duration < GetTime()
            if (t.type > type) and not isOld then
                type = t.type
                timer = t
            end
        end

        local shouldUpdate = false
        if self.internalState.timerIsDirty or type ~= self.internalState.currentTimerType then
            self.internalState.currentTimerType = type
            self.internalState.timerIsDirty = false
            shouldUpdate = true
        end


        if shouldUpdate then
            if type == CDTimerTypes.Charge then
                self.Cooldown:SetCooldown(timer.startTime, timer.duration, timer.modRate)
                self.Cooldown:SetDrawSwipe(false)
                self.Cooldown:SetDrawEdge(true)
                self.Cooldown:SetReverse(false)
            elseif type == CDTimerTypes.Cooldown then
                self.Cooldown:SetCooldown(timer.startTime, timer.duration, timer.modRate)
                self.Cooldown:SetDrawSwipe(true)
                self.Cooldown:SetDrawEdge(false)
                self.Cooldown:SetReverse(false)
            elseif type == CDTimerTypes.Aura then
                self.Cooldown:SetCooldown(timer.startTime, timer.duration, timer.modRate)
                self.Cooldown:SetDrawSwipe(true)
                self.Cooldown:SetDrawEdge(false)
                self.Cooldown:SetReverse(true)
            else
                self.Cooldown:Clear()
            end
        end
    end
end

function TrackedObject.CreateTimer(type, startTime, duration, modRate)
    local timer = {
        startTime = startTime,
        duration = duration,
        modRate = modRate,
        type = type
    }
    return timer
end