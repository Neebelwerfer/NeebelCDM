FrameBuilder = {}
local appName, env = ...

function FrameBuilder.GenerateFrameName(guid, frameName)
    return appName .. ":" .. guid .. "-" .. frameName
end

---@param node Node
---@param parentFrame Frame
---@return Frame
function FrameBuilder.BuildRootFrame(node, parentFrame)
    local name = FrameBuilder.GenerateFrameName(node.guid, "Root")
    local frame = CreateFrame("Frame", name, parentFrame)


    frame:SetSize(node.layout.size.width, node.layout.size.height)
    frame:SetPoint(node.transform.point, parentFrame, node.transform.relativePoint, node.transform.offsetX, node.transform.offsetY)
    frame:SetScale(node.transform.scale)

    return frame
end

---comment
---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor<IconProps>
---@return Frame
function FrameBuilder.BuildIconFrame(node, rootFrame, frameDescriptor)
    local name = FrameBuilder.GenerateFrameName(node.guid, frameDescriptor.name)
    local frame = CreateFrame("Frame", name, rootFrame, "BackdropTemplate")

    local color = frameDescriptor.props.colorMask.value
    local icon = frameDescriptor.props.icon.value

    frame:SetSize(frameDescriptor.layout.size.width, frameDescriptor.layout.size.height)
    frame:SetPoint(
        "CENTER",
        rootFrame,
        frameDescriptor.transform.offsetX,
        frameDescriptor.transform.offsetY
    )
    frame:SetScale(frameDescriptor.transform.scale)

    frame.tex = frame:CreateTexture()
    frame.tex:SetAllPoints(frame)
    frame.tex:SetTexture(icon)
    frame.tex:SetVertexColor(color.r, color.g, color.b, color.a)

    return frame
end

---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor<TextProps>
---@return Frame
function FrameBuilder.BuildTextFrame(node, rootFrame, frameDescriptor)
    local name = FrameBuilder.GenerateFrameName(node.guid, frameDescriptor.name)
    local frame = CreateFrame("Frame", name, rootFrame)

    frame:SetSize(frameDescriptor.layout.size.width, frameDescriptor.layout.size.height)
    frame:SetPoint(
        "CENTER",
        rootFrame,
        frameDescriptor.transform.offsetX,
        frameDescriptor.transform.offsetY
    )
    frame:SetScale(frameDescriptor.transform.scale)

    -- Create FontString as child of the frame
    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetAllPoints(frame)
    frame.text:SetFont("Fonts\\FRIZQT__.TTF", frameDescriptor.props.fontSize or 12, "OUTLINE")
    frame.text:SetText(frameDescriptor.props.text.value)

    local color = frameDescriptor.props.color.value
    frame.text:SetTextColor(color.r, color.g, color.b, color.a)

    return frame
end

---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor<CooldownProps>
---@return Frame
function FrameBuilder.BuildCooldownFrame(node, rootFrame, frameDescriptor)
    local name = FrameBuilder.GenerateFrameName(node.guid, frameDescriptor.name)
    local frame = CreateFrame("Cooldown", name, rootFrame, "CooldownFrameTemplate")

    frame:SetSize(frameDescriptor.layout.size.width, frameDescriptor.layout.size.height)
    frame:SetPoint(
        "CENTER",
        rootFrame,
        frameDescriptor.transform.offsetX,
        frameDescriptor.transform.offsetY
    )
    frame:SetScale(frameDescriptor.transform.scale)

    -- Configure cooldown appearance
    frame:SetDrawSwipe(frameDescriptor.props.swipe.value)
    frame:SetDrawEdge(frameDescriptor.props.edge.value)
    frame:SetReverse(frameDescriptor.props.reverse.value)

    -- Color mask
    local color = frameDescriptor.props.colorMask.value
    frame:SetSwipeColor(color.r, color.g, color.b, color.a)
    
    return frame
end

---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor<BarProps>
---@return Frame
function FrameBuilder.BuildBarFrame(node, rootFrame, frameDescriptor)
    local name = FrameBuilder.GenerateFrameName(node.guid, frameDescriptor.name)
    local frame = CreateFrame("StatusBar", name, rootFrame)

    frame:SetSize(frameDescriptor.layout.size.width, frameDescriptor.layout.size.height)
    frame:SetPoint(
        "CENTER",
        rootFrame,
        frameDescriptor.transform.offsetX,
        frameDescriptor.transform.offsetY
    )
    frame:SetScale(frameDescriptor.transform.scale)

    -- Set bar texture and color
    frame:SetStatusBarTexture(frameDescriptor.props.texture.value)

    local color = frameDescriptor.props.color.value
    frame:GetStatusBarTexture():SetVertexColor(color.r, color.g, color.b, color.a)

    -- Default min/max (will be updated via bindings later)
    frame:SetMinMaxValues(0, 100)
    frame:SetValue(50)

    return frame
end


local creators = {
    [FrameTypes.Icon] = FrameBuilder.BuildIconFrame,
    [FrameTypes.Bar] = FrameBuilder.BuildBarFrame,
    [FrameTypes.Text] = FrameBuilder.BuildTextFrame,
    [FrameTypes.Cooldown] = FrameBuilder.BuildCooldownFrame
}
---comment
---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor
---@return Frame
function FrameBuilder.BuildFrameFromDescriptor(node, rootFrame, frameDescriptor)
    local creator = creators[frameDescriptor.type]
    return creator(node, rootFrame, frameDescriptor)
end