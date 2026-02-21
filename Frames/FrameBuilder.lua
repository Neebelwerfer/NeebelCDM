local _, ns = ...
local FramePools = ns.Frames.FramePools
local PropertyFrame = ns.Frames.PropertyFrame
local FrameTypes = ns.Frames.FrameTypes

FrameBuilder = {}
ns.Frames.FrameBuilder = FrameBuilder


---@param node Node
---@param parentFrame Frame
---@return Frame
function FrameBuilder.BuildRootFrame(node, parentFrame)
    local root = FramePools.AquireFrame("Root", parentFrame)

    root:SetSize(node.layout.size.width, node.layout.size.height)
    root:SetPoint(node.transform.point, parentFrame, node.transform.relativePoint, node.transform.offsetX, node.transform.offsetY)
    root:SetScale(node.transform.scale)
    
    for _, frameDescriptor in pairs(node.frames) do
        local frame = FrameBuilder.BuildFrameFromDescriptor(node, root, frameDescriptor)
        root.frames[frameDescriptor.name] = frame
    end

    root:Show()
    return root
end

---comment
---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor<IconProps>
---@return PropertyFrame
function FrameBuilder.BuildIconFrame(node, rootFrame, frameDescriptor)
    local frame = FramePools.AquireFrame("Icon", rootFrame)
    
    for i, _ in ipairs(frameDescriptor.props.cooldowns) do
        local cdFrame = FramePools.AquireFrame("Cooldown", frame)

        cdFrame:SetSize(node.layout.size.width, node.layout.size.height)
        cdFrame:SetAllPoints(frame)
        cdFrame:SetScale(frameDescriptor.transform.scale)
        table.insert(frame.cooldowns, PropertyFrame:New(cdFrame, frameDescriptor, FrameBuilder.ApplyCooldownProps))
    end
    frame:Show()

    return PropertyFrame:New(frame, frameDescriptor, FrameBuilder.ApplyIconProps, function (propertyFrame, layout)
        local frame = propertyFrame.frame
        frame:SetSize(layout.size.width, layout.size.height)
        frame:SetPoint(
            "CENTER",
            rootFrame,
            frameDescriptor.transform.relativePoint,
            frameDescriptor.transform.offsetX,
            frameDescriptor.transform.offsetY
        )
        frame:SetScale(frameDescriptor.transform.scale)

        for _, cdFrame in pairs(frame.cooldowns) do
            cdFrame:UpdateTransform(layout)
        end
    end)
end

---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor<TextProps>
---@return PropertyFrame
function FrameBuilder.BuildTextFrame(node, rootFrame, frameDescriptor)
    local frame = FramePools.AquireFrame("Text", rootFrame)
    frame:Show()

    return PropertyFrame:New(frame, frameDescriptor, FrameBuilder.ApplyTextProps)
end

---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor<BarProps>
---@return PropertyFrame
function FrameBuilder.BuildBarFrame(node, rootFrame, frameDescriptor)
    local frame = FramePools.AquireFrame("Bar", rootFrame)
    frame:Show()

    return PropertyFrame:New(frame, frameDescriptor, FrameBuilder.ApplyBarProps)
end

local creators = {
    [FrameTypes.Icon] = FrameBuilder.BuildIconFrame,
    [FrameTypes.Bar] = FrameBuilder.BuildBarFrame,
    [FrameTypes.Text] = FrameBuilder.BuildTextFrame,
}

---comment
---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor
---@return PropertyFrame
function FrameBuilder.BuildFrameFromDescriptor(node, rootFrame, frameDescriptor)
    local creator = creators[frameDescriptor.type]
    return creator(node, rootFrame, frameDescriptor)
end

function FrameBuilder.ApplyIconProps(frame, resolvedProps)
    local color = resolvedProps.colorMask
    local icon = resolvedProps.icon
    
    frame.tex:SetAllPoints(frame)
    frame.tex:SetTexture(icon or 134400)
    frame.tex:SetVertexColor(color.r, color.g, color.b, color.a)

    for i, cd in ipairs(frame.cooldowns) do
        FrameBuilder.ApplyCooldownProps(cd.frame, resolvedProps.cooldowns[i])
    end
end

---comment
---@param frame Frame
---@param resolvedProps table<string, any>
function FrameBuilder.ApplyCooldownProps(frame, resolvedProps)
    -- Configure cooldown appearance
    
    -- Color mask
    local swipe = resolvedProps.swipe
    if swipe then
        local color = swipe.color
        frame:SetDrawSwipe(swipe.enabled)
        frame:SetSwipeColor(color.r, color.g, color.b, color.a)
        frame:SetSwipeTexture("", color.r, color.g, color.b, color.a)
    end

    local edge = resolvedProps.edge
    if edge then
        local color = edge.color
        frame:SetDrawEdge(edge.enabled)
        frame:SetEdgeColor(color.r, color.g, color.b, color.a)
        frame:SetEdgeScale(edge.scale)
    end

    local bling = resolvedProps.bling
    if bling then
        local color = bling.color
        frame:SetDrawBling(bling.enabled)
        frame:SetBlingTexture("", color.r, color.g, color.b, color.a)
    end
    frame:SetReverse(resolvedProps.reverse)

    local cooldown = resolvedProps.cooldown
    if cooldown then
        frame:SetCooldown(cooldown.start, cooldown.duration, cooldown.modRate or 1)
    end
    frame:SetHideCountdownNumbers(resolvedProps.hideCountdown or false)
end

function FrameBuilder.ApplyTextProps(frame, resolvedProps)
    frame.text:SetFont("Fonts\\FRIZQT__.TTF", resolvedProps.fontSize or 12, "OUTLINE")
    frame.text:SetText(resolvedProps.text or "")

    local color = resolvedProps.color
    frame.text:SetTextColor(color.r, color.g, color.b, color.a)
end


function FrameBuilder.ApplyBarProps(frame, resolvedProps)
    -- Set bar texture and color
    frame:SetStatusBarTexture(resolvedProps.texture or "Interface\\TargetingFrame\\UI-StatusBar")

    
    local color = resolvedProps.color
    frame:SetStatusBarColor(color.r, color.g, color.b, color.a)
    frame:SetOrientation(resolvedProps.orientation or "HORIZONTAL")
    frame:SetReverseFill(resolvedProps.reverse or false)
    frame:SetMinMaxValues(resolvedProps.min or 0, resolvedProps.max or 100)
    frame:SetValue(resolvedProps.value or 0)
end

local applyers = {
    [FrameTypes.Icon] = FrameBuilder.ApplyIconProps,
    [FrameTypes.Bar] = FrameBuilder.ApplyBarProps,
    [FrameTypes.Text] = FrameBuilder.ApplyTextProps,
}

function FrameBuilder.UpdateFrameByProps(frame, frameDescriptor, resolvedProps)
    local applyer = applyers[frameDescriptor.type]
    if applyer then
        applyer(frame, resolvedProps)
    end
end