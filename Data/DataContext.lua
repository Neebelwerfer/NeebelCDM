---@class DataContext
---@field spells table<number, SpellContext>
---@field auras table<number, AuraContext>
---@field items table<number, ItemContext>
---@field resources table<string, ResourceContext>

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
        unit = {
            player = {}
        }
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

local contextRegistors = {
    [DataTypes.Spell] = SpellContext.Create,
    [DataTypes.Aura] = AuraContextManager.Register,
}

function DataContext.Initialize()
    AuraContextManager.Initialize()
end

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
        
        if binding.type == DataTypes.Aura then
            AuraContextManager.Register(binding.key)
        else
            DataContext.context[binding.type][binding.key] = contextRegistors[binding.type](binding.key)
        end
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
    if type == DataTypes.Aura then
        return DataContext.HandleNestedFields(AuraContextManager.contexts[key], field)
    end
    return DataContext.HandleNestedFields(DataContext.context[type][key], field) or nil
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
    for typeName, type in pairs(DataTypes) do
        if DataContext.context[type] then
            for key, _ in pairs(DataContext.context[type]) do
                DataContext.context[type][key] = contextRegistors[type](key)
            end
        end
        
    end
end