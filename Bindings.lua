---@class BindingValueDescriptor
---@field binding string
---@field field string

---@class BindingDescriptor
---@field type DataTypes -- What kind of game data (Spell, Item, Aura, Resource) 
---@field alias string -- User-friendly display name in editor
---@field key? number | string Game ID (spellID: 12345, itemID: 67890, etc) Only nil if type is Player
