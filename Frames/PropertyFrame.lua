PropertyFrame = {}
PropertyFrame.__index = PropertyFrame

---@class PropertyFrame
---@field frame Frame
---@field descriptor FrameDescriptor
---@field ApplyProperties fun(frame: Frame, resolvedProps: table<string, any>)
---@field UpdateProperties fun(self: PropertyFrame, resolvedProps: table<string, any>)
---@field UpdateTransform fun(self: PropertyFrame, layout: Layout)

---
---@param frame Frame
---@param frameDescriptor FrameDescriptor
---@param ApplyProperties fun(frame: Frame, resolvedProps: table<string, any>)
---@param UpdateTransformOverride? fun(self, layout: Layout)
---@return PropertyFrame
function PropertyFrame:New(frame, frameDescriptor, ApplyProperties, UpdateTransformOverride)
    local propFrame = {}
    propFrame.frame = frame
    propFrame.descriptor = frameDescriptor

    assert(ApplyProperties, "ApplyProperties is required")
    propFrame.ApplyProperties = ApplyProperties

    if UpdateTransformOverride then
        propFrame.UpdateTransform = UpdateTransformOverride
    end

    setmetatable(propFrame, PropertyFrame)
    return propFrame
end

---Updates the transform of the frame
---@param layout Layout
function PropertyFrame:UpdateTransform(layout)
    local frame = self.frame
    local descriptor = self.descriptor
    local parent = self.frame:GetParent()

    frame:SetSize(layout.size.width, layout.size.height)
    frame:SetPoint(
        "CENTER",
        parent,
        "CENTER",
        descriptor.transform.offsetX,
        descriptor.transform.offsetY
    )
    frame:SetScale(descriptor.transform.scale)
end

function PropertyFrame:UpdateProperties(resolvedProps)
    self.ApplyProperties(self.frame, resolvedProps)
end

function PropertyFrame:Destroy()
    
end