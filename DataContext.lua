---@class DataContext
---@field spells table<number, SpellContext>
---@field auras table<number, AuraContext>
---@field items table<number, ItemContext>
---@field resources table<string, ResourceContext>

---@class SpellContext
---@field id number
---@field name string
---@field icon string
---@field cooldown? fun(): { start: number, duration: number, modRate: number}
---@field charges? fun(): { current: number, max: number, cooldown?: { start: number, duration: number, modRate: number}}
---@field inRange boolean
---@field usable boolean
---@field noMana boolean

---@class AuraContext
---@field id number
---@field name string
---@field icon string
---@field isActive boolean
---@field stacks number
---@field duration { start: number, duration: number, remaining: number }
---@field source string -- "player", "target", etc.

---@class ItemContext
---@field id number
---@field name string
---@field icon string
---@field count number
---@field cooldown? { start: number, duration: number, remaining: number }

---@class ResourceContext
---@field current number
---@field max number
---@field percent number
---@field type string -- "MANA", "ENERGY", etc.

---@class PlayerContext
---@field health { current: number, max: number, percent: number }
---@field primaryPower { current: number, max: number, percent: number }
---@field secondaryPower { current: number, max: number, percent: number }
---@field class string


DataContext = {
    context = { -- Current game data
        spells = {},
        auras = {},
        items = {},
        resources = {},
        player = {}
    },

    dirty = { -- Tracks which parts of the context have changed
        spells = {},
        auras = {},
        items = {},
        resources = {}
    },

    bindings = {}, -- Tracks subscribers of each binding

    updateInterval = 0.5,
    lastUpdate = 0
}



---@param key number | string
---@return SpellContext
local function CreateSpellContext(key)
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
        internal = {}
    }

    if cooldown then
        context.internal.cooldown = {
            start = cooldown.startTime,
            duration = cooldown.duration,
            modRate = cooldown.modRate
        }
    end

    context.cooldown = function()
        if not context.internal.cooldown then return nil end
        local cd = context.internal.cooldown
        local remaining = (cd.start + cd.duration) - GetTime()
        
        if remaining <= 0 then return nil end
        
        return {
            start = cd.start,
            duration = cd.duration,
            remaining = remaining,
            modRate = cd.modRate
        }
    end

    context.charges = function()
        return context.internal.charges
    end

    if charges and charges.maxCharges > 1 then
        context.internal.charges = {
            current = charges.currentCharges,
            max = charges.maxCharges,
            cooldown = {
                start = charges.cooldownStartTime,
                duration = charges.cooldownDuration,
                modRate = charges.chargeModRate
            },
        }
    end
    return context
end

local contextCreators = {
    [DataTypes.Spell] = CreateSpellContext
}

---Register a binding from a node
---@param sourceGuid string
---@param binding BindingDescriptor
function DataContext.RegisterBinding(sourceGuid, binding)
    local path = tostring(binding.type) .. ":" .. binding.key

    if DataContext.bindings[path] then -- Binding already exists
        DataContext.bindings[path][sourceGuid] = true
        return
    end

    -- New binding
    DataContext.bindings[path] = {}
    DataContext.bindings[path][sourceGuid] = true

    if binding.key then
        if not DataContext.context[binding.type] then
            DataContext.context[binding.type] = {}
        end
        DataContext.context[binding.type][binding.key] = contextCreators[binding.type](binding.key)
    end
end


---Unregister a binding from a node
---@param sourceGuid string
---@param binding BindingDescriptor
function DataContext.UnregisterBinding(sourceGuid, binding)
    local path = tostring(binding.type) .. ":" .. binding.key

    if not DataContext.bindings[path] then -- Binding doesn't exist
        return
    end

    if DataContext.bindings[path] then -- Binding exists
        DataContext.bindings[path][sourceGuid] = nil
    end

    if not next(DataContext.bindings[path]) then -- Binding has no subscribers
        DataContext.bindings[path] = nil

        if binding.key then
            DataContext.context[binding.type][binding.key] = nil
        else
            DataContext.context[binding.type] = nil
        end
    end
end

---comment
---@param type DataTypes
---@param key? string | number
---@param field string
---@return any?
function DataContext.ResolveBinding(type, key, field)
    if type == DataTypes.Player then
        return DataContext.context[type][field] or nil
    else
        return DataContext.HandleNestedFields(DataContext.context[type][key], field) or nil
    end
end

function DataContext.HandleNestedFields(context, field)
    local parts = { strsplit(".", field) }

    local value = context
    for _, part in ipairs(parts) do
        value = value[part]
        if not value then return nil end

        if type(value) == "function" then
            value = value()
        end
    end
    return value
end

function DataContext.UpdateContext()

end