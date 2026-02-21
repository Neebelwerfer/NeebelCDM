local _, ns = ...
local AceGUI = LibStub("AceGUI-3.0")
local FrameTypes = ns.Frames.FrameTypes
local RuntimeNodeManager = ns.Nodes.RuntimeNodeManager

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
        
        local frameGroup = AceGUI:Create("InlineGroup")
        frameGroup:SetTitle(frameName .. " (" .. descriptor.type .. ")")
        frameGroup:SetFullWidth(true)
        frameGroup:SetLayout("Flow")
        scroll:AddChild(frameGroup)
        
        -- Build type-specific property UI
        if descriptor.type == FrameTypes.Icon then
            PropertiesPanel.BuildIconProperties(frameGroup, descriptor, runtimeNode)
        -- elseif descriptor.type == FrameTypes.Text then
        --     NodesTab.BuildTextProperties(frameGroup, descriptor)
        -- elseif descriptor.type == FrameTypes.Bar then
        --     NodesTab.BuildBarProperties(frameGroup, descriptor)
        end
    end
end

function PropertiesPanel.BuildIconProperties(container, descriptor, runtimeNode)
    local NodesTab = ns.Editor.NodesTab
    local props = descriptor.props
    
    -- Color Mask
    local colorGroup = AceGUI:Create("SimpleGroup")
    colorGroup:SetFullWidth(true)
    colorGroup:SetLayout("Flow")
    container:AddChild(colorGroup)
    
    local colorHeading = AceGUI:Create("Label")
    colorHeading:SetText("Color Mask")
    colorHeading:SetFontObject(GameFontNormalLarge)
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
end
