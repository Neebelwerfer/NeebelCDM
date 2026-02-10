SpellContextManager = {
    contexts = {}, -- context registry
    contextSubscriptions = {}, -- { [key] = { [guid] = true } }

    initialized = false,
}

function SpellContextManager.Initialize()
    if SpellContextManager.initialized then
        return
    end
    SpellContextManager.initialized = true
end

-- Registers a new context to the manager
function SpellContextManager.Register(sourceGuid, key)
    -- If the context doesn't exist, create it
    if not SpellContextManager.contextSubscriptions[key] then
        SpellContextManager.contextSubscriptions[key] = {}
        local context = SpellContext:new(key)
        SpellContextManager.contexts[key] = context
    end
    
    assert(not SpellContextManager.contextSubscriptions[key][sourceGuid], "Registering an already registered context")
    SpellContextManager.contextSubscriptions[key][sourceGuid] = true
end

-- Unregisters a context
function SpellContextManager.Unregister(sourceGuid, key)
    assert(SpellContextManager.contextSubscriptions[key][sourceGuid], "Unregistering an unregistered context")
    SpellContextManager.contextSubscriptions[key][sourceGuid] = nil

    if not next(SpellContextManager.contextSubscriptions[key]) then
        SpellContextManager.contextSubscriptions[key] = nil
        SpellContextManager.contexts[key] = nil
    end
end

-- Retrieves a context
function SpellContextManager.GetContext(key)
    return SpellContextManager.contexts[key]
end

-- Updates all contexts
function SpellContextManager.Update()
    for _, context in pairs(SpellContextManager.contexts) do
        context:Update()
    end
end

---@class SpellContext
---@field id number
---@field name string
---@field icon string
---@field cooldown? fun(): { start: number, duration: number, modRate: number}
---@field charges? fun(): { current: number, max: number, cooldown?: { start: number, duration: number, modRate: number}}
---@field inRange boolean
---@field usable boolean
---@field noMana boolean

SpellContext = {}
SpellContext.__index = SpellContext
function SpellContext:new(key)
    local spellInfo = C_Spell.GetSpellInfo(key)
    local charges = C_Spell.GetSpellCharges(key)
    local cooldown = C_Spell.GetSpellCooldown(key)
    local isUsable, noMana = C_Spell.IsSpellUsable(key)
    local inRange = C_Spell.IsSpellInRange(key, "target")


    local context = {
        id = spellInfo.spellID,
        name = spellInfo.name,
        icon = spellInfo.iconID,
        inRange = inRange,
        usable = isUsable,
        noMana = noMana,
        internal = {},
        cooldown = {
            start = cooldown.startTime,
            duration = cooldown.duration,
            modRate = cooldown.modRate,
        },
        charges = {
            current = charges.currentCharges,
            max = charges.maxCharges,
            cooldown = {
                start = charges.cooldownStartTime,
                duration = charges.cooldownDuration,
                modRate = charges.chargeModRate
            }
        }
    }

    context.cooldown.remaining = function()
        if not self.internal.cooldownDurationUtil then return 0 end
        return self.internal.cooldownDurationUtil:GetRemainingDuration(Enum.DurationTimeModifier.RealTime) or 0
    end

    context.cooldown.isActive = function()
        return self.internal.cooldown and not self.internal.cooldown.durationUtil:IsZero()
    end

    setmetatable(context, self)
    return context
end

function SpellContext:Update()
    local spellInfo = C_Spell.GetSpellInfo(self.id)
    local charges = C_Spell.GetSpellCharges(self.id)
    local cooldown = C_Spell.GetSpellCooldown(self.id)
    local isUsable, noMana = C_Spell.IsSpellUsable(self.id)
    local inRange = C_Spell.IsSpellInRange(self.id, "target")

    self.name = spellInfo.name
    self.icon = spellInfo.iconID

    if cooldown then
        self.internal.cooldownDurationUtil = C_Spell.GetSpellCooldownDuration(self.id)
        self.cooldown.start = cooldown.startTime
        self.cooldown.duration = cooldown.duration
        self.cooldown.modRate = cooldown.modRate
    else
        self.internal.cooldownDurationUtil = nil
        self.cooldown.start = 0
        self.cooldown.duration = 0
    end

    self.inRange = inRange
    self.usable = isUsable
    self.noMana = noMana

    self.charges = {
        current = charges.currentCharges,
        max = charges.maxCharges,
        cooldown = {
            start = charges.cooldownStartTime,
            duration = charges.cooldownDuration,
            modRate = charges.chargeModRate
        },
    }
end