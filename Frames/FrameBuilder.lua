FrameBuilder = {}
local appName, env = ...

function FrameBuilder.GenerateFrameName(guid, frameName)
    return appName .. ":" .. guid .. "-" .. frameName
end


---@param node Node
---@param parentFrame Frame
---@param resolvedFrameProps table<string, table<string, any>>
---@return Frame
function FrameBuilder.BuildRootFrame(node, parentFrame, resolvedFrameProps)
    local name = FrameBuilder.GenerateFrameName(node.guid, "Root")
    local root = CreateFrame("Frame", name, parentFrame)


    root:SetSize(node.layout.size.width, node.layout.size.height)
    root:SetPoint(node.transform.point, parentFrame, node.transform.relativePoint, node.transform.offsetX, node.transform.offsetY)
    root:SetScale(node.transform.scale)

    -- Adding movement scripts, starts disabled
    root:SetScript("OnMouseDown", function(self, button)
        self:StartMoving()
    end)
    root:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
        
    end)
    root:SetMovable(true)
    root:EnableMouse(false)

    root.frames = {}

    for _, frameDescriptor in pairs(node.frames) do
        local frame = FrameBuilder.BuildFrameFromDescriptor(node, root, frameDescriptor, resolvedFrameProps[frameDescriptor.name])
        root.frames[frameDescriptor.name] = {frame = frame, descriptor = frameDescriptor}
    end

    return root
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
    frame.tex = frame:CreateTexture()

    frame.cooldowns = {}

    for i, _ in ipairs(frameDescriptor.props.cooldowns) do 
        local cdName = FrameBuilder.GenerateFrameName(node.guid, frameDescriptor.name) .. "-" .. i
        local cdFrame = CreateFrame("Cooldown", cdName, frame, "CooldownFrameTemplate")

        cdFrame:SetSize(node.layout.size.width, node.layout.size.height)
        cdFrame:SetAllPoints(frame)
        cdFrame:SetScale(frameDescriptor.transform.scale)
        table.insert(frame.cooldowns, cdFrame)
    end

    FrameBuilder.ApplyIconProps(frame, resolvedProps)
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

    FrameBuilder.ApplyTextProps(frame, resolvedProps)
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

    FrameBuilder.ApplyBarProps(frame, resolvedProps)
    return frame
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
---@param resolvedProps table<string, any>
---@return Frame
function FrameBuilder.BuildFrameFromDescriptor(node, rootFrame, frameDescriptor, resolvedProps)
    local creator = creators[frameDescriptor.type]
    return creator(node, rootFrame, frameDescriptor, resolvedProps)
end

function FrameBuilder.ApplyIconProps(frame, resolvedProps)
    local color = resolvedProps.colorMask
    local icon = resolvedProps.icon
    
    frame.tex:SetAllPoints(frame)
    frame.tex:SetTexture(icon or 134400)
    frame.tex:SetVertexColor(color.r, color.g, color.b, color.a)

    for i, cd in ipairs(frame.cooldowns) do
        FrameBuilder.ApplyCooldownProps(cd, resolvedProps.cooldowns[i])
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
    frame:GetStatusBarTexture():SetVertexColor(color.r, color.g, color.b, color.a)

    -- Default min/max (will be updated via bindings later)
    frame:SetMinMaxValues(0, 100)
    frame:SetValue(50)
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