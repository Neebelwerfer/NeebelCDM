local _, ns = ...

local FrameDescriptionFactory = {}
ns.Frames.FrameDescriptionFactory = FrameDescriptionFactory

local PropertyFactory = ns.Frames.PropertyFactory

---@class ButtonAction
---@field type "spell" | "macro"
---@field value string


---@class FrameDescriptor<TProps>
---@field type Frame.FrameTypes
---@field name string
---@field props TProps
---@field transform {offsetX: number, offsetY: number, scale: number}
---@field visibility? RuleBindingDescriptor | RuleComposite
---@field strata? "BACKGROUND" | "LOW" | "MEDIUM" | "HIGH" | "DIALOG" | "FULLSCREEN" | "FULLSCREEN_DIALOG" | "TOOLTIP"
---@field frameLevel? number

---@enum Frame.FrameTypes
ns.Frames.FrameTypes = {
    Icon = 1,
    Bar = 2,
    Text = 3,
    IconButton = 4,
    TextButton = 5
}
local FrameTypes = ns.Frames.FrameTypes

---Default transform
---@return Transform
local function DefaultTransform()
    return {
            offsetX = 0,
            offsetY = 0,
            scale = 1
    }
end

---@return FrameDescriptor<IconProps>
function FrameDescriptionFactory.CreateIconFrame()
    return {
        type = FrameTypes.Icon,
        name = "Icon",
        props = PropertyFactory.DefaultIconPropeties(),
        transform = DefaultTransform()
    }
end

---@return FrameDescriptor<BarProps>
function FrameDescriptionFactory.CreateBarFrame()
    return {
        type = FrameTypes.Bar,
        name = "Bar",
        props = PropertyFactory.DefaultBarProperties(),
        transform = DefaultTransform()
    }
end

---@return FrameDescriptor<TextProps>
function FrameDescriptionFactory.CreateTextFrame()
    return {
        type = FrameTypes.Text,
        name = "Text",
        props = PropertyFactory.DefaultTextProperties(),
        transform = DefaultTransform()
    }
end

local frameCreators = {
    [FrameTypes.Icon] = FrameDescriptionFactory.CreateIconFrame,
    [FrameTypes.Bar] = FrameDescriptionFactory.CreateBarFrame,
    [FrameTypes.Text] = FrameDescriptionFactory.CreateTextFrame,
}

---@param type Frame.FrameTypes
---@return FrameDescriptor?
function FrameDescriptionFactory.GetFrameOfType(type)
    if type then
        return frameCreators[type]()
    end
end