PropertyFactory = {}
---@class CooldownDescriptor
---@field cooldown BoundPropDescriptor
---@field hideCountdown FlexiblePropDescriptor<boolean>
---@field swipe {enabled: FlexiblePropDescriptor<boolean>, color: FlexiblePropDescriptor<Color>}
---@field edge {enabled: FlexiblePropDescriptor<boolean>, color: FlexiblePropDescriptor<Color>, scale: FlexiblePropDescriptor<number>}
---@field bling {enabled: FlexiblePropDescriptor<boolean>, color: FlexiblePropDescriptor<Color>}
---@field reverse FlexiblePropDescriptor<boolean>

---@class IconProps
---@field icon FlexiblePropDescriptor<string>
---@field colorMask FlexiblePropDescriptor<Color>
---@field cooldowns? CooldownDescriptor[]

---@class IconButtonProps : IconProps
---@field action FlexiblePropDescriptor<ButtonAction>

---@class BarProps
---@field texture FlexiblePropDescriptor<string>
---@field color FlexiblePropDescriptor<Color>
---@field min FlexiblePropDescriptor<number>
---@field max FlexiblePropDescriptor<number>
---@field value BoundPropDescriptor<number>
---@field reverse FlexiblePropDescriptor<boolean>
---@field orientation StaticPropDescriptor<string>

---@class TextProps
---@field text FlexiblePropDescriptor<string>
---@field color FlexiblePropDescriptor<Color>
---@field fontSize FlexiblePropDescriptor<number>

---@generic T
---@class StaticPropDescriptor<T>
---@field resolveType "static"
---@field value T

---@class BoundPropDescriptor
---@field resolveType "binding"
---@field value BindingValueDescriptor

---@generic T
---@class FlexiblePropDescriptor<T>
---@field resolveType "static" | "binding"
---@field value T | BindingValueDescriptor

-- Helpers for creating props
---@return FlexiblePropDescriptor
local function FlexibleProp(defaultValue)
    return {
        resolveType = "static",
        value = defaultValue
    }
end

---@return BoundPropDescriptor
local function BoundProp(defaultValue)
    return {
        resolveType = "binding",
        value = defaultValue
    }
end

---@return StaticPropDescriptor
local function StaticProp(defaultValue)
    return {
        resolveType = "static",
        value = defaultValue
    }
end

---@return IconProps
function PropertyFactory.DefaultIconPropeties()
    return {
        icon = FlexibleProp(134400),
        colorMask = FlexibleProp(Color(1, 1, 1, 1)),
        cooldowns = {}
    }
end

function PropertyFactory.DefaultBarProperties()
    return {
        texture = FlexibleProp("Interface\\TargetingFrame\\UI-StatusBar"),
        color = FlexibleProp(Color(1, 1, 1, 1)),
        min = FlexibleProp(0),
        max = FlexibleProp(100),
        value = BoundProp(nil),
        reverse = FlexibleProp(false),
        orientation = StaticProp("HORIZONTAL")
    }
end

function PropertyFactory.DefaultTextProperties()
    return {
        text = FlexibleProp("Text"),
        color = FlexibleProp(Color(1, 1, 1, 1)),
        fontSize = FlexibleProp(12)
    }
end

function PropertyFactory.DefaultCooldownProperties()
    return {
            cooldown = BoundProp(nil),
            hideCountdown = FlexibleProp(false),
            swipe = {enabled = FlexibleProp(true), color = FlexibleProp(Color(0.0, 0.0, 0.0, 0.8))},
            edge = {enabled = FlexibleProp(false), color = FlexibleProp(Color(1, 1, 1, 1)), scale = FlexibleProp(1.5)},
            bling = {enabled = FlexibleProp(false), color = FlexibleProp(Color(0.5, 0.5, 0.5, 1))},
            reverse = FlexibleProp(false),
    }
end