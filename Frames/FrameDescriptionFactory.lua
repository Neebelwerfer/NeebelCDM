FrameDescriptionFactory = {}

---@class ButtonAction
---@field type "spell" | "macro"
---@field value string

---@class IconProps
---@field icon FlexiblePropDescriptor<string>
---@field colorMask FlexiblePropDescriptor<Color>

---@class IconButtonProps : IconProps
---@field action FlexiblePropDescriptor<ButtonAction>

---@class BarProps
---@field texture FlexiblePropDescriptor<string>
---@field color FlexiblePropDescriptor<Color>

---@class TextProps
---@field text FlexiblePropDescriptor<string>
---@field color FlexiblePropDescriptor<Color>
---@field fontSize FlexiblePropDescriptor<number>

---@class CooldownProps
---@field cooldown BoundPropDescriptor
---@field hideCountdown FlexiblePropDescriptor<boolean>
---@field swipe FlexiblePropDescriptor<boolean>
---@field edge FlexiblePropDescriptor<boolean>
---@field reverse FlexiblePropDescriptor<boolean>
---@field colorMask FlexiblePropDescriptor<Color>

---@generic T
---@class StaticPropDescriptor<T>
---@field allowedResolveTypes ["static"]
---@field resolveType "static"
---@field valueType string
---@field value T

---@class BoundPropDescriptor
---@field allowedResolveTypes ["binding"]
---@field resolveType "binding"
---@field valueType string
---@field value BindingValueDescriptor

---@generic T
---@class FlexiblePropDescriptor<T>
---@field allowedResolveTypes ["static", "binding"]
---@field resolveType "static" | "binding"
---@field valueType string
---@field value T | BindingValueDescriptor

---@class FrameDescriptor<TProps>
---@field type Frame.FrameTypes
---@field name string
---@field props TProps
---@field transform {offsetX: number, offsetY: number, scale: number}
---@field visibility? RuleBindingDescriptor | RuleComposite
---@field strata? "BACKGROUND" | "LOW" | "MEDIUM" | "HIGH" | "DIALOG" | "FULLSCREEN" | "FULLSCREEN_DIALOG" | "TOOLTIP"
---@field frameLevel? number

---@enum Frame.FrameTypes
FrameTypes = {
    Icon = 1,
    Bar = 2,
    Text = 3,
    Cooldown = 4,
    IconButton = 5,
    TextButton = 6
}

---Default transform
---@return Transform
local function DefaultTransform()
    return {
            offsetX = 0,
            offsetY = 0,
            scale = 1
    }
end

-- Helpers for creating props
---@return FlexiblePropDescriptor
local function FlexibleProp(valueType, defaultValue)
    return {
        allowedResolveTypes = {"static", "binding"},
        resolveType = "static",
        valueType = valueType,
        value = defaultValue
    }
end

---@return BoundPropDescriptor
local function BoundProp(valueType, defaultValue)
    return {
        allowedResolveTypes = {"binding"},
        resolveType = "binding",
        valueType = valueType,
        value = defaultValue
    }
end

---@return StaticPropDescriptor
local function StaticProp(valueType, defaultValue)
    return {
        allowedResolveTypes = {"static"},
        resolveType = "static",
        valueType = valueType,
        value = defaultValue
    }
end

---@return FrameDescriptor<IconProps>
function FrameDescriptionFactory.CreateIconFrame()
    return {
        type = FrameTypes.Icon,
        name = "Icon",
        props = {
            icon = FlexibleProp("string", "Interface\\Icons\\INV_Misc_QuestionMark"),
            colorMask = FlexibleProp("Color", Color(1, 1, 1, 1))
        },
        transform = DefaultTransform()
    }
end

---@return FrameDescriptor<BarProps>
function FrameDescriptionFactory.CreateBarFrame()
    return {
        type = FrameTypes.Bar,
        name = "Bar",
        props = {
            texture = FlexibleProp("string", "Interface\\TargetingFrame\\UI-StatusBar"),
            color = FlexibleProp("Color", Color(1, 1, 1, 1))
        },
        transform = DefaultTransform()
    }
end

---@return FrameDescriptor<TextProps>
function FrameDescriptionFactory.CreateTextFrame()
    return {
        type = FrameTypes.Text,
        name = "Text",
        props = {
            text = FlexibleProp("string", "Text"),
            color = FlexibleProp("Color", Color(1, 1, 1, 1)),
            fontSize = FlexibleProp("number", 12)
        },
        transform = DefaultTransform()
    }
end

---@return FrameDescriptor<CooldownProps>
function FrameDescriptionFactory.CreateCooldownFrame()
    return {
        type = FrameTypes.Cooldown,
        name = "Cooldown",
        props = {
            cooldown = BoundProp("cooldown", nil),
            hideCountdown = FlexibleProp("boolean", false),
            swipe = FlexibleProp("boolean", true),
            edge = FlexibleProp("boolean", false),
            reverse = FlexibleProp("boolean", false),
            colorMask = FlexibleProp("Color", Color(1, 1, 1, 1))
        },
        transform = DefaultTransform()
    }
end

local frameCreators = {
    [FrameTypes.Icon] = FrameDescriptionFactory.CreateIconFrame,
    [FrameTypes.Bar] = FrameDescriptionFactory.CreateBarFrame,
    [FrameTypes.Text] = FrameDescriptionFactory.CreateTextFrame,
    [FrameTypes.Cooldown] = FrameDescriptionFactory.CreateCooldownFrame
}

---@param type Frame.FrameTypes
---@return FrameDescriptor?
function FrameDescriptionFactory.GetFrameOfType(type)
    if type then
        return frameCreators[type]()
    end
end