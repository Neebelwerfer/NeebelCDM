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

    -- Adding movement scripts, starts disabled
    frame:SetScript("OnMouseDown", function(self, button)
        self:StartMoving()
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
        
    end)
    frame:SetMovable(true)
    frame:EnableMouse(false)

    return frame
end

---comment
---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor<IconProps>
---@param resolvedProps table<string, any>
---@return Frame
function FrameBuilder.BuildIconFrame(node, rootFrame, frameDescriptor, resolvedProps)
    local name = FrameBuilder.GenerateFrameName(node.guid, frameDescriptor.name)
    local frame = CreateFrame("Frame", name, rootFrame, "BackdropTemplate")

    
    frame:SetSize(node.layout.size.width, node.layout.size.height)
    frame:SetPoint(
        "CENTER",
        rootFrame,
        frameDescriptor.transform.offsetX,
        frameDescriptor.transform.offsetY
    )
    frame:SetScale(frameDescriptor.transform.scale)
    
    local color = resolvedProps.colorMask
    local icon = resolvedProps.icon
    
    frame.tex = frame:CreateTexture()
    frame.tex:SetAllPoints(frame)
    frame.tex:SetTexture(icon)
    frame.tex:SetVertexColor(color.r, color.g, color.b, color.a)

    return frame
end

---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor<TextProps>
---@param resolvedProps table<string, any>
---@return Frame
function FrameBuilder.BuildTextFrame(node, rootFrame, frameDescriptor, resolvedProps)
    local name = FrameBuilder.GenerateFrameName(node.guid, frameDescriptor.name)
    local frame = CreateFrame("Frame", name, rootFrame)

    frame:SetSize(node.layout.size.width, node.layout.size.height)
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
    frame.text:SetFont("Fonts\\FRIZQT__.TTF", resolvedProps.fontSize or 12, "OUTLINE")
    frame.text:SetText(resolvedProps.text or "")

    local color = resolvedProps.color
    frame.text:SetTextColor(color.r, color.g, color.b, color.a)

    return frame
end

---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor<CooldownProps>
---@param resolvedProps table<string, any>
---@return Frame
function FrameBuilder.BuildCooldownFrame(node, rootFrame, frameDescriptor, resolvedProps)
    local name = FrameBuilder.GenerateFrameName(node.guid, frameDescriptor.name)
    local frame = CreateFrame("Cooldown", name, rootFrame, "CooldownFrameTemplate")

    frame:SetSize(node.layout.size.width, node.layout.size.height)
    frame:SetPoint(
        "CENTER",
        rootFrame,
        frameDescriptor.transform.offsetX,
        frameDescriptor.transform.offsetY
    )
    frame:SetScale(frameDescriptor.transform.scale)

    -- Configure cooldown appearance
    frame:SetDrawSwipe(resolvedProps.swipe)
    frame:SetDrawEdge(resolvedProps.edge)
    frame:SetReverse(resolvedProps.reverse)

    -- Color mask
    local color = resolvedProps.colorMask
    -- frame:SetSwipeColor(color.r, color.g, color.b, color.a)

    local cooldown = resolvedProps.cooldown
    if cooldown then
        local startTime, duration = cooldown.start, cooldown.duration
        if duration and startTime then
            frame:SetCooldown(startTime, duration)
        end
    end
    frame:SetHideCountdownNumbers(resolvedProps.hideCountdown or false)
    return frame
end

---@param node Node
---@param rootFrame Frame
---@param frameDescriptor FrameDescriptor<BarProps>
---@param resolvedProps table<string, any>
---@return Frame
function FrameBuilder.BuildBarFrame(node, rootFrame, frameDescriptor, resolvedProps)
    local name = FrameBuilder.GenerateFrameName(node.guid, frameDescriptor.name)
    local frame = CreateFrame("StatusBar", name, rootFrame)

    frame:SetSize(node.layout.size.width, node.layout.size.height)
    frame:SetPoint(
        "CENTER",
        rootFrame,
        frameDescriptor.transform.offsetX,
        frameDescriptor.transform.offsetY
    )
    frame:SetScale(frameDescriptor.transform.scale)

    -- Set bar texture and color
    frame:SetStatusBarTexture(resolvedProps.texture or "Interface\\TargetingFrame\\UI-StatusBar")

    local color = resolvedProps.color
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
---@param resolvedProps table<string, any>
---@return Frame
function FrameBuilder.BuildFrameFromDescriptor(node, rootFrame, frameDescriptor, resolvedProps)
    local creator = creators[frameDescriptor.type]
    return creator(node, rootFrame, frameDescriptor, resolvedProps)
end
