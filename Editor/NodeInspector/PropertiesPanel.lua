local _, ns = ...
local AceGUI = LibStub("AceGUI-3.0")
local FrameTypes = ns.Frames.FrameTypes
local DataTypes = ns.Core.DataTypes
local RuntimeNodeManager = ns.Nodes.RuntimeNodeManager
local PropertyFactory = ns.Frames.PropertyFactory


local PropertiesPanel = {}
ns.Editor.PropertiesPanel = PropertiesPanel

function PropertiesPanel.Build(container)
    local NodesTab = ns.Editor.NodesTab --TODO: Look at the dependency graph for this
    local runtimeNode = RuntimeNodeManager.lookupTable[NodesTab.selectedNodeGuid]
    assert(runtimeNode, "Tree nodes not matching runtime nodes")
    
    local node = runtimeNode.node

    -- Scroll frame for all properties
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    container:AddChild(scroll)
    
    -- Node metadata
    local metaGroup = AceGUI:Create("InlineGroup")
    metaGroup:SetTitle("General Properties")
    metaGroup:SetFullWidth(true)
    metaGroup:SetLayout("Flow")
    scroll:AddChild(metaGroup)
    
    -- Name
    local nameInput = AceGUI:Create("EditBox")
    nameInput:SetLabel("Node Name")
    nameInput:SetText(node.name or "")
    nameInput:SetFullWidth(true)
    nameInput:SetCallback("OnEnterPressed", function(widget, event, text)
        node.name = text
        NodesTab.Repaint()
    end)
    metaGroup:AddChild(nameInput)

    
    --Frame-specific properties for each frame descriptor
    for frameName, propertyFrame in pairs(runtimeNode.rootFrame.frames) do
        local descriptor = propertyFrame.descriptor
        
        local frameType = nil
        for k, v in pairs(FrameTypes) do
            if v == descriptor.type then
                frameType = k
                break
            end
        end
        if not frameType then
            error("Unknown frame type: " .. descriptor.type)
        end

        local frameGroup = AceGUI:Create("InlineGroup")
        frameGroup:SetTitle(frameName .. " (" .. frameType .. ")")
        frameGroup:SetFullWidth(true)
        frameGroup:SetLayout("Flow")
        scroll:AddChild(frameGroup)
        
        -- Build type-specific property UI
        if descriptor.type == FrameTypes.Icon then
            PropertiesPanel.BuildIconProperties(frameGroup, descriptor, runtimeNode)
        elseif descriptor.type == FrameTypes.Text then
            PropertiesPanel.BuildTextProperties(frameGroup, descriptor, runtimeNode)
        elseif descriptor.type == FrameTypes.Bar then
            PropertiesPanel.BuildBarProperties(frameGroup, descriptor, runtimeNode)
        end
    end
    scroll:DoLayout()
end

function PropertiesPanel.BuildIconProperties(container, descriptor, runtimeNode)
    local NodesTab = ns.Editor.NodesTab
    local props = descriptor.props
    local transform = descriptor.transform

    local offsetX = AceGUI:Create("EditBox")
    offsetX:SetLabel("Offset X")
    offsetX:SetText(transform.offsetX)
    offsetX:SetRelativeWidth(0.5)
    offsetX:SetCallback("OnEnterPressed", function(widget, event, value)
        value = tonumber(value)
        if value then
            transform.offsetX = tonumber(value)
            runtimeNode:MarkLayoutAsDirty()
        else
            widget:SetText(transform.offsetX)
        end
    end)
    container:AddChild(offsetX)

    local offsetY = AceGUI:Create("EditBox")
    offsetY:SetLabel("Offset Y")
    offsetY:SetText(transform.offsetY)
    offsetY:SetRelativeWidth(0.5)
    offsetY:SetCallback("OnEnterPressed", function(widget, event, value)
        value = tonumber(value)
        if value then
            transform.offsetX = tonumber(value)
            runtimeNode:MarkLayoutAsDirty()
        else
            widget:SetText(transform.offsetY)
        end
    end)
    container:AddChild(offsetY)
    
    -- Color Mask
    local colorGroup = AceGUI:Create("SimpleGroup")
    colorGroup:SetFullWidth(true)
    colorGroup:SetLayout("Flow")
    container:AddChild(colorGroup)
    
    local colorHeading = AceGUI:Create("Heading")
    colorHeading:SetText("Color Mask")
    colorHeading:SetFullWidth(true)
    colorGroup:AddChild(colorHeading)
    
    -- Check if bound or static        
    local color = props.colorMask.value or {r=1, g=1, b=1, a=1}
    
    local colorPicker = AceGUI:Create("ColorPicker")
    colorPicker:SetColor(color.r, color.g, color.b, color.a)
    colorPicker:SetHasAlpha(true)
    colorPicker:SetCallback("OnValueChanged", function(widget, event, r, g, b, a)
        props.colorMask.value = { r=r, g=g, b=b, a=a}
    end)
    colorGroup:AddChild(colorPicker)

    -- Icon Texture (with binding support)
    local iconGroup = AceGUI:Create("SimpleGroup")
    iconGroup:SetFullWidth(true)
    iconGroup:SetLayout("Flow")
    container:AddChild(iconGroup)
    
    local iconLabel = AceGUI:Create("Label")
    iconLabel:SetText("Icon Texture")
    iconLabel:SetFontObject(GameFontNormalLarge)
    iconLabel:SetFullWidth(true)
    iconGroup:AddChild(iconLabel)
    
    -- Resolve type dropdown (static vs binding)
    local modeDropdown = AceGUI:Create("Dropdown")
    modeDropdown:SetLabel("Source")
    modeDropdown:SetList({static="Static", binding="Binding"})
    modeDropdown:SetValue(props.icon.resolveType)
    modeDropdown:SetRelativeWidth(0.5)
    modeDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        props.icon.resolveType = value
        NodesTab.RepaintInspector()
    end)
    iconGroup:AddChild(modeDropdown)
    
    -- Show appropriate editor based on mode
    if props.icon.resolveType == "static" then
        if type(props.icon.value) == "table" then
            props.icon.value = ""
        end

        -- Static: texture ID or path input
        local textureInput = AceGUI:Create("EditBox")
        textureInput:SetLabel("Texture ID or Path")
        textureInput:SetText(tostring(props.icon.value))
        textureInput:SetRelativeWidth(0.5)
        textureInput:DisableButton(true)
        textureInput:SetCallback("OnEnterPressed", function(widget, event, text)
            props.icon.value = tonumber(text) or text
        end)
        iconGroup:AddChild(textureInput)
        
    else
        -- Binding: dropdown of available bindings
        local bindingDropdown = AceGUI:Create("Dropdown")
        bindingDropdown:SetLabel("Bind To")
        
        -- Build list from node's bindings
        local bindingList = {}
        for _, binding in ipairs(runtimeNode.node.bindings) do
            bindingList[binding.alias] = binding.alias
        end
        
        bindingDropdown:SetList(bindingList)
        bindingDropdown:SetValue(props.icon.value.binding or "")
        bindingDropdown:SetRelativeWidth(0.5)
        bindingDropdown:SetCallback("OnValueChanged", function(widget, event, value) -- For the binding for icon we can always assume field is "icon"
            props.icon.value = {binding = value, field = "icon"}
        end)
        iconGroup:AddChild(bindingDropdown)
    end

    for i, cooldown in ipairs(props.cooldowns) do
        PropertiesPanel.DrawCooldown(runtimeNode, container, cooldown, i)
    end
    local addCooldownFrame = AceGUI:Create("Button")
    addCooldownFrame:SetText("Add Cooldown Frame")
    addCooldownFrame:SetCallback("OnClick", function(widget, event, value)
        table.insert(props.cooldowns, PropertyFactory.DefaultCooldownProperties())
        runtimeNode:MarkFramesAsDirty()
        ns.Editor.NodesTab.RepaintInspector()
    end)
    container:AddChild(addCooldownFrame)
end

function PropertiesPanel.DrawCooldown(runtimeNode,container, cooldown, i)
    local cooldownGroup = AceGUI:Create("InlineGroup")
    cooldownGroup:SetTitle("Cooldown Frame " .. i)
    cooldownGroup:SetFullWidth(true)
    cooldownGroup:SetLayout("Flow")
    container:AddChild(cooldownGroup)

        -- Cooldown Binding Section
    local bindingHeading = AceGUI:Create("Heading")
    bindingHeading:SetText("Cooldown Source")
    bindingHeading:SetFullWidth(true)
    cooldownGroup:AddChild(bindingHeading)
    
    -- Binding dropdown
    local bindingDropdown = AceGUI:Create("Dropdown")
    bindingDropdown:SetLabel("Bind To")
    
    local bindingList = {}
    for _, binding in ipairs(runtimeNode.node.bindings) do
        bindingList[binding.alias] = binding.alias
    end
    
    bindingDropdown:SetList(bindingList)
    bindingDropdown:SetValue(cooldown.cooldown.value.binding or "")
    bindingDropdown:SetRelativeWidth(0.5)
    bindingDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        cooldown.cooldown.value.binding = value
        ns.Editor.NodesTab.RepaintInspector()
    end)
    cooldownGroup:AddChild(bindingDropdown)
    
    -- Field dropdown (contextual based on binding type)
    local fieldDropdown = AceGUI:Create("Dropdown")
    fieldDropdown:SetLabel("Field")
    
    -- Determine available fields based on binding type
    local fieldList = {}
    if cooldown.cooldown.value.binding then
        -- Find the binding to get its type
        local binding = nil
        for _, b in ipairs(runtimeNode.node.bindings) do
            if b.alias == cooldown.cooldown.value.binding then
                binding = b
                break
            end
        end
        
        if binding then
            if binding.type == DataTypes.Spell then
                fieldList = {["cooldown"]="Cooldown", ["charges.cooldown"]="Charges"}
            elseif binding.type == DataTypes.Aura then
                fieldList = {["duration"]="Duration"}
            end
        end
    end
    
    fieldDropdown:SetList(fieldList)
    fieldDropdown:SetValue(cooldown.cooldown.value.field)
    fieldDropdown:SetRelativeWidth(0.5)
    fieldDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        cooldown.cooldown.value.field = value
    end)
    cooldownGroup:AddChild(fieldDropdown)
    
    -- Visual settings heading
    local visualHeading = AceGUI:Create("Heading")
    visualHeading:SetText("Visual Settings")
    visualHeading:SetFullWidth(true)
    cooldownGroup:AddChild(visualHeading)

    local hideCountdown = AceGUI:Create("CheckBox")
    hideCountdown:SetLabel("Hide Countdown")
    hideCountdown:SetValue(cooldown.hideCountdown.value)
    hideCountdown:SetRelativeWidth(0.5)
    hideCountdown:SetCallback("OnValueChanged", function(widget, event, value)
        cooldown.hideCountdown.value = value
    end)
    cooldownGroup:AddChild(hideCountdown)

    local reverse = AceGUI:Create("CheckBox")
    reverse:SetLabel("Reverse")
    reverse:SetValue(cooldown.reverse.value)
    reverse:SetRelativeWidth(0.5)
    reverse:SetCallback("OnValueChanged", function(widget, event, value)
        cooldown.reverse.value = value
    end)
    cooldownGroup:AddChild(reverse)

    local swipeHeading = AceGUI:Create("Heading")
    swipeHeading:SetText("Swipe")
    swipeHeading:SetFullWidth(true)
    cooldownGroup:AddChild(swipeHeading)

    local swipeEnabled = AceGUI:Create("CheckBox")
    swipeEnabled:SetLabel("Swipe Enabled")
    swipeEnabled:SetValue(cooldown.swipe.enabled.value)
    swipeEnabled:SetRelativeWidth(0.5)
    swipeEnabled:SetCallback("OnValueChanged", function(widget, event, value)
        cooldown.swipe.enabled.value = value
    end)
    cooldownGroup:AddChild(swipeEnabled)

    local swipeColor = AceGUI:Create("ColorPicker")
    swipeColor:SetColor(cooldown.swipe.color.value.r, cooldown.swipe.color.value.g, cooldown.swipe.color.value.b, cooldown.swipe.color.value.a)
    swipeColor:SetHasAlpha(true)
    swipeColor:SetRelativeWidth(0.5)
    swipeColor:SetCallback("OnValueChanged", function(widget, event, r, g, b, a)
        cooldown.swipe.color.value = { r=r, g=g, b=b, a=a}
    end)
    cooldownGroup:AddChild(swipeColor)

    local edgeHeading = AceGUI:Create("Heading")
    edgeHeading:SetText("Edge")
    edgeHeading:SetFullWidth(true)
    cooldownGroup:AddChild(edgeHeading)

    local edgeEnabled = AceGUI:Create("CheckBox")
    edgeEnabled:SetLabel("Edge Enabled")
    edgeEnabled:SetValue(cooldown.edge.enabled.value)
    edgeEnabled:SetRelativeWidth(0.33)
    edgeEnabled:SetCallback("OnValueChanged", function(widget, event, value)
        cooldown.edge.enabled.value = value
    end)
    cooldownGroup:AddChild(edgeEnabled)

    local edgeColor = AceGUI:Create("ColorPicker")
    edgeColor:SetColor(cooldown.edge.color.value.r, cooldown.edge.color.value.g, cooldown.edge.color.value.b, cooldown.edge.color.value.a)
    edgeColor:SetHasAlpha(true)
    edgeColor:SetRelativeWidth(0.33)
    edgeColor:SetCallback("OnValueChanged", function(widget, event, r, g, b, a)
        cooldown.edge.color.value = { r=r, g=g, b=b, a=a}
    end)
    cooldownGroup:AddChild(edgeColor)

    local edgeScale = AceGUI:Create("Slider")
    edgeScale:SetLabel("Edge Scale")
    edgeScale:SetValue(cooldown.edge.scale.value)
    edgeScale:SetRelativeWidth(0.33)
    edgeScale:SetCallback("OnValueChanged", function(widget, event, value)
        cooldown.edge.scale.value = value
    end)
    cooldownGroup:AddChild(edgeScale)


    local blingHeading = AceGUI:Create("Heading")
    blingHeading:SetText("Bling")
    blingHeading:SetFullWidth(true)
    cooldownGroup:AddChild(blingHeading)

    local blingEnabled = AceGUI:Create("CheckBox")
    blingEnabled:SetLabel("Bling Enabled")
    blingEnabled:SetValue(cooldown.bling.enabled.value)
    blingEnabled:SetRelativeWidth(0.33)
    blingEnabled:SetCallback("OnValueChanged", function(widget, event, value)
        cooldown.bling.enabled.value = value
    end)
    cooldownGroup:AddChild(blingEnabled)

    local blingColor = AceGUI:Create("ColorPicker")
    blingColor:SetColor(cooldown.bling.color.value.r, cooldown.bling.color.value.g, cooldown.bling.color.value.b, cooldown.bling.color.value.a)
    blingColor:SetHasAlpha(true)
    blingColor:SetRelativeWidth(0.33)
    blingColor:SetCallback("OnValueChanged", function(widget, event, r, g, b, a)
        cooldown.bling.color.value = { r=r, g=g, b=b, a=a}
    end)
    cooldownGroup:AddChild(blingColor)
end

function PropertiesPanel.BuildTextProperties(container, descriptor, runtimeNode)
    local props = descriptor.props
    local transform = descriptor.transform

    local offsetX = AceGUI:Create("EditBox")
    offsetX:SetLabel("Offset X")
    offsetX:SetText(transform.offsetX)
    offsetX:SetRelativeWidth(0.5)
    offsetX:SetCallback("OnEnterPressed", function(widget, event, value)
        value = tonumber(value)
        if value then
            transform.offsetX = tonumber(value)
            runtimeNode:MarkLayoutAsDirty()
        else
            widget:SetText(transform.offsetX)
        end
    end)
    container:AddChild(offsetX)

    local offsetY = AceGUI:Create("EditBox")
    offsetY:SetLabel("Offset Y")
    offsetY:SetText(transform.offsetY)
    offsetY:SetRelativeWidth(0.5)
    offsetY:SetCallback("OnEnterPressed", function(widget, event, value)
        value = tonumber(value)
        if value then
            transform.offsetX = tonumber(value)
            runtimeNode:MarkLayoutAsDirty()
        else
            widget:SetText(transform.offsetY)
        end
    end)
    container:AddChild(offsetY)

    local fontSize = AceGUI:Create("Slider")
    fontSize:SetLabel("Font Size")
    fontSize:SetValue(props.fontSize.value)
    fontSize:SetSliderValues(8, 24, 1)
    fontSize:SetCallback("OnValueChanged", function(widget, event, value)
        props.fontSize.value = value
    end)
    container:AddChild(fontSize)

    local fontColor = AceGUI:Create("ColorPicker")
    fontColor:SetColor(props.color.value.r, props.color.value.g, props.color.value.b, props.color.value.a)
    fontColor:SetHasAlpha(true)
    fontColor:SetCallback("OnValueChanged", function(widget, event, r, g, b, a)
        props.color.value = { r=r, g=g, b=b, a=a}
    end)
    container:AddChild(fontColor)


    local text = AceGUI:Create("MultiLineEditBox")
    text:SetNumLines(3)
    text:SetRelativeWidth(1)
    text:SetText(props.text.value)
    text:SetCallback("OnEnterPressed", function(widget, event, value)
        props.text.value = value
    end)
    container:AddChild(text)
end

function PropertiesPanel.BuildBarProperties(container, descriptor, runtimeNode)
    local transform = descriptor.transform

    local offsetX = AceGUI:Create("EditBox")
    offsetX:SetLabel("Offset X")
    offsetX:SetText(transform.offsetX)
    offsetX:SetRelativeWidth(0.5)
    offsetX:SetCallback("OnEnterPressed", function(widget, event, value)
        value = tonumber(value)
        if value then
            transform.offsetX = tonumber(value)
            runtimeNode:MarkLayoutAsDirty()
        else
            widget:SetText(transform.offsetX)
        end
    end)
    container:AddChild(offsetX)

    local offsetY = AceGUI:Create("EditBox")
    offsetY:SetLabel("Offset Y")
    offsetY:SetText(transform.offsetY)
    offsetY:SetRelativeWidth(0.5)
    offsetY:SetCallback("OnEnterPressed", function(widget, event, value)
        value = tonumber(value)
        if value then
            transform.offsetX = tonumber(value)
            runtimeNode:MarkLayoutAsDirty()
        else
            widget:SetText(transform.offsetY)
        end
    end)
    container:AddChild(offsetY)
end