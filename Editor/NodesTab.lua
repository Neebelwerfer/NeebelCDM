local AceGUI = LibStub("AceGUI-3.0")
local AceHook = LibStub("AceHook-3.0")

NodesTab = {
    nodes = {},
    selectedNodeGuid = nil,
}

function NodesTab.Build(container)
    NodesTab.container = container
    container:SetLayout("Fill")
    
    local treeGroup = AceGUI:Create("TreeGroup")
    treeGroup:SetFullHeight(true)
    treeGroup:SetTree(NodesTab.BuildTree())
    treeGroup:SetCallback("OnGroupSelected", NodesTab.OnNodeSelected)
    container:AddChild(treeGroup)
    NodesTab.treeGroup = treeGroup
    
    -- Select first node
    if not NodesTab.selectedNodeGuid and #RuntimeNodeManager.roots > 0 then
        local firstRoot = RuntimeNodeManager.roots[1]
        treeGroup:SelectByPath(firstRoot.guid)
    end
end

function NodesTab.BuildTree()
    local tree = {}
    
    local addNode = {
        value = "add",
        text = "Add Node",
        icon = AddSign,
    }
    table.insert(tree, addNode)

    for _, runtimeNode in ipairs(RuntimeNodeManager.roots) do
        table.insert(tree, NodesTab.BuildTreeNode(runtimeNode))
    end
    
    return tree
end

function NodesTab.BuildTreeNode(runtimeNode)
    local node = runtimeNode.node
    
    -- Get icon from first binding or use question mark
    -- TODO: Node should store a seperate icon for the node itself
    local icon = QuestionMark
    if node.bindings and #node.bindings > 0 then
        local firstBinding = node.bindings[1]
        if firstBinding.type == DataTypes.Spell then
            local spellInfo = C_Spell.GetSpellInfo(firstBinding.key)
            if spellInfo then
                icon = spellInfo.iconID
            end
        elseif firstBinding.type == DataTypes.Aura then
            local spellInfo = C_Spell.GetSpellInfo(firstBinding.key)
            if spellInfo then
                icon = spellInfo.iconID
            end
        end
    end
    
    local treeNode = {
        value = node.guid,
        text = node.name or "Node",
        icon = icon,
    }
    
    -- Build children
    if #node.children == 0 then return treeNode end
    treeNode.children = {}
    for _, childGuid in ipairs(node.children) do
        local childRuntime = RuntimeNodeManager.lookupTable[childGuid]
        if childRuntime then
            table.insert(treeNode.children, NodesTab.BuildTreeNode(childRuntime))
        end
    end
    
    return treeNode
end


function NodesTab.OpenContextMenu(frame, guid)
    local menu = MenuUtil.CreateContextMenu(frame, function (ownerRegion, description)
        description:CreateTitle(frame.value)

        description:CreateButton("Add Child Node", function()
            NodesTab.ShowAddNodeDialog(guid)
        end)
        
        description:CreateButton("Duplicate", function()
            NodesTab.DuplicateNode(guid)
        end)
        
        -- description:CreateDivider()
        
        -- description:CreateButton("Move Up", function()
        --     NodesTab.MoveNode(guid, -1)
        -- end)
        
        -- description:CreateButton("Move Down", function()
        --     NodesTab.MoveNode(guid, 1)
        -- end)
        
        -- description:CreateDivider()
        
        -- description:CreateButton("Copy", function()
        --     NodesTab.CopyNode(guid)
        -- end)
        
        -- description:CreateButton("Paste as Child", function()
        --     NodesTab.PasteNode(guid)
        -- end)
        
        description:CreateDivider()
        
        description:CreateButton("Rename", function()
            NodesTab.ShowRenameDialog(guid)
        end)
        
        description:CreateButton("Delete", function() --TODO: Make sure to delete the node in the node tables aswell, right now we just do it for the runtime node.
            RuntimeNodeManager.RemoveNode(guid)
        end)
    end)

    --Make menu appear on top
    if menu then
        menu:SetFrameStrata("TOOLTIP")
    end
end

--TODO: Dont rebuild Inspector every time
function NodesTab.OnNodeSelected(container, event, path)
    -- Extract GUID from path (last segment after \001)
    for _, button in ipairs(NodesTab.treeGroup.buttons) do --TODO: Make it not hook on addNode, also is this the best way to do this?
        if not AceHook:IsHooked(button, "OnClick") and button.value ~= "add" then
            AceHook:HookScript(button, "OnClick", function(frame, mouseButton)
                if mouseButton == "RightButton" then
                    NodesTab.OpenContextMenu(frame, frame.value)
                end
            end)
        end
    end

    container:ReleaseChildren()
    if path == "add" then
        print("Add Node") -- TODO: Use container to show add templates.
        return
    end


    local guid = path:match("([^\001]+)$")
    NodesTab.selectedNodeGuid = guid

    container:SetLayout("Fill")
    local inspectorTabs = AceGUI:Create("TabGroup")
    inspectorTabs:SetFullHeight(true)
    inspectorTabs:SetFullWidth(true)
    inspectorTabs:SetLayout("Fill")
    inspectorTabs:SetTabs({
        {text="Properties", value="properties"},
        {text="Layout", value="layout"},
        {text="Bindings", value="bindings"}
    })
    inspectorTabs:SetCallback("OnGroupSelected", NodesTab.OnInspectorTabSelected)
    inspectorTabs:SelectTab("properties")
    container:AddChild(inspectorTabs)
    
    -- NodesTab.OnInspectorTabSelected(container, nil, "properties")
end

function NodesTab.OnInspectorTabSelected(container, event, group)
    container:ReleaseChildren()
    
    if group == "properties" then
        NodesTab.BuildPropertiesPanel(container)
    elseif group == "layout" then
        NodesTab.BuildLayoutPanel(container)
    elseif group == "bindings" then
        --NodesTab.BuildBindingsPanel(container)
    end
end


function NodesTab.BuildPropertiesPanel(container)
    local runtimeNode = RuntimeNodeManager.lookupTable[NodesTab.selectedNodeGuid]
    assert(runtimeNode, "Tree nodes not matching runtime nodes")
    
    local node = runtimeNode.node
    
    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    scrollContainer:SetLayout("Fill")
    container:AddChild(scrollContainer)

    -- Scroll frame for all properties
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scrollContainer:AddChild(scroll)
    
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
        NodesTab.Refresh()
    end)
    metaGroup:AddChild(nameInput)
    
    -- Enabled
    local enabledCheckbox = AceGUI:Create("CheckBox")
    enabledCheckbox:SetLabel("Enabled")
    enabledCheckbox:SetValue(node.enabled)
    enabledCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        node.enabled = value
        runtimeNode.rootFrame:SetShown(value)
    end)
    metaGroup:AddChild(enabledCheckbox)
    
    -- --Frame-specific properties for each frame descriptor
    -- for frameName, propertyFrame in pairs(runtimeNode.rootFrame.frames) do
    --     local descriptor = propertyFrame.descriptor
        
    --     local frameGroup = AceGUI:Create("InlineGroup")
    --     frameGroup:SetTitle(frameName .. " (" .. descriptor.type .. ")")
    --     frameGroup:SetFullWidth(true)
    --     frameGroup:SetLayout("Flow")
    --     scroll:AddChild(frameGroup)
        
    --     -- Build type-specific property UI
    --     if descriptor.type == FrameTypes.Icon then
    --         NodesTab.BuildIconProperties(frameGroup, descriptor)
    --     elseif descriptor.type == FrameTypes.Text then
    --         NodesTab.BuildTextProperties(frameGroup, descriptor)
    --     elseif descriptor.type == FrameTypes.Bar then
    --         NodesTab.BuildBarProperties(frameGroup, descriptor)
    --     end
    -- end
end

function NodesTab.BuildIconProperties(container, descriptor)
    local props = descriptor.props
    
    -- Icon texture
    NodesTab.BuildPropEditor(container, "Icon", props.icon, "string", function(value)
        props.icon.value = value
        NodesTab.UpdateFrames()
    end)
    
    -- Color mask
    NodesTab.BuildColorEditor(container, "Color Mask", props.colorMask, function(r, g, b, a)
        props.colorMask.value = {r=r, g=g, b=b, a=a}
        NodesTab.UpdateFrames()
    end)
    
    -- Cooldowns (if any)
    if #props.cooldowns > 0 then
        local cdGroup = AceGUI:Create("InlineGroup")
        cdGroup:SetTitle("Cooldowns")
        cdGroup:SetFullWidth(true)
        cdGroup:SetLayout("Flow")
        container:AddChild(cdGroup)
        
        -- List each cooldown
        for i, cd in ipairs(props.cooldowns) do
            local label = AceGUI:Create("Heading")
            label:SetText("Cooldown " .. i)
            label:SetFullWidth(true)
            cdGroup:AddChild(label)
            
            -- Cooldown properties...
        end
    end
end

function NodesTab.BuildTextProperties(container, descriptor)
    local props = descriptor.props
    
    -- Text content
    NodesTab.BuildPropEditor(container, "Text", props.text, "string", function(value)
        props.text.value = value
        NodesTab.UpdateFrames()
    end)
    
    -- Font size
    NodesTab.BuildPropEditor(container, "Font Size", props.fontSize, "number", function(value)
        props.fontSize.value = tonumber(value)
        NodesTab.UpdateFrames()
    end)
    
    -- Color
    NodesTab.BuildColorEditor(container, "Color", props.color, function(r, g, b, a)
        props.color.value = {r=r, g=g, b=b, a=a}
        NodesTab.UpdateFrames()
    end)
end

function NodesTab.BuildPropEditor(container, label, propDescriptor, valueType, onChanged)
    -- Show resolve type toggle
    if propDescriptor.allowedResolveTypes and #propDescriptor.allowedResolveTypes > 1 then
        local dropdown = AceGUI:Create("Dropdown")
        dropdown:SetLabel(label .. " (Mode)")
        dropdown:SetList({static="Static", binding="Binding"})
        dropdown:SetValue(propDescriptor.resolveType)
        dropdown:SetFullWidth(true)
        dropdown:SetCallback("OnValueChanged", function(widget, event, value)
            propDescriptor.resolveType = value
            NodesTab.RefreshInspector()
        end)
        container:AddChild(dropdown)
    end
    
    -- Show appropriate input based on resolve type
    if propDescriptor.resolveType == "static" then
        local input = AceGUI:Create("EditBox")
        input:SetLabel(label)
        input:SetText(tostring(propDescriptor.value))
        input:SetFullWidth(true)
        input:SetCallback("OnEnterPressed", function(widget, event, text)
            onChanged(text)
        end)
        container:AddChild(input)
    else
        -- Binding mode - show binding selector
        local bindingLabel = AceGUI:Create("Label")
        bindingLabel:SetText(label .. ": Bound to " .. (propDescriptor.value.binding or "none"))
        bindingLabel:SetFullWidth(true)
        container:AddChild(bindingLabel)
    end
end

--- Build the layout panel which should help with arranging frames.
---@param container AceGUIContainer
function NodesTab.BuildLayoutPanel(container)
    local runtimeNode = RuntimeNodeManager.lookupTable[NodesTab.selectedNodeGuid]
    local nodeLayout = runtimeNode.node.layout
    local nodeTransform = runtimeNode.node.transform
    
    local group = AceGUI:Create("SimpleGroup")
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    container:AddChild(group)

    --Alignment
    local alignmentGroup = AceGUI:Create("InlineGroup")
    alignmentGroup:SetTitle("Alignment")
    alignmentGroup:SetFullWidth(true)
    alignmentGroup:SetLayout("Flow")
    group:AddChild(alignmentGroup)

    local anchor = AceGUI:Create("Dropdown")
    anchor:SetLabel("Anchor")
    anchor:SetList({TOPLEFT="Top Left", TOP="Top", TOPRIGHT="Top Right", LEFT="Left", CENTER="Center", RIGHT="Right", BOTTOMLEFT="Bottom Left", BOTTOM="Bottom", BOTTOMRIGHT="Bottom Right"})
    anchor:SetValue(nodeTransform.point)
    anchor:SetRelativeWidth(0.5)
    anchor:SetCallback("OnValueChanged", function(widget, event, value)
        print ("Anchor changed to " .. value)
        nodeTransform.point = value
        runtimeNode:MarkLayoutAsDirty()
    end)
    alignmentGroup:AddChild(anchor)

    local relative = AceGUI:Create("Dropdown")
    relative:SetLabel("Relative To")
    relative:SetList({TOPLEFT="Top Left", TOP="Top", TOPRIGHT="Top Right", LEFT="Left", CENTER="Center", RIGHT="Right", BOTTOMLEFT="Bottom Left", BOTTOM="Bottom", BOTTOMRIGHT="Bottom Right"})
    relative:SetValue(nodeTransform.relativePoint)
    relative:SetRelativeWidth(0.5)
    relative:SetCallback("OnValueChanged", function(widget, event, value)
        nodeTransform.relativePoint = value
        runtimeNode:MarkLayoutAsDirty()
    end)
    alignmentGroup:AddChild(relative)
    
    --Position
    local positionGroup = AceGUI:Create("InlineGroup")
    positionGroup:SetTitle("Position")
    positionGroup:SetFullWidth(true)
    positionGroup:SetLayout("Flow")
    group:AddChild(positionGroup)
    
    local x = AceGUI:Create("EditBox")
    x:SetLabel("X")
    x:SetText(tostring(nodeTransform.offsetX))
    x:SetRelativeWidth(0.5)
    x:SetCallback("OnEnterPressed", function(widget, event, text)
        nodeTransform.offsetX = tonumber(text)
        runtimeNode:MarkLayoutAsDirty()
    end)
    positionGroup:AddChild(x)
    
    local y = AceGUI:Create("EditBox")
    y:SetLabel("Y")
    y:SetText(tostring(nodeTransform.offsetY))
    y:SetRelativeWidth(0.5)
    y:SetCallback("OnEnterPressed", function(widget, event, text)
        nodeTransform.offsetY = tonumber(text)
        runtimeNode:MarkLayoutAsDirty()
    end)
    positionGroup:AddChild(y)
    
    --Size
    local sizeGroup = AceGUI:Create("InlineGroup")
    sizeGroup:SetTitle("Size")
    sizeGroup:SetFullWidth(true)
    sizeGroup:SetLayout("Flow")
    group:AddChild(sizeGroup)

    local width = AceGUI:Create("EditBox")
    width:SetLabel("Width")
    width:SetText(tostring(nodeLayout.size.width))
    width:SetRelativeWidth(0.5)
    width:SetCallback("OnEnterPressed", function(widget, event, text)
        nodeLayout.size.width = tonumber(text)
        runtimeNode:MarkLayoutAsDirty()
    end)
    sizeGroup:AddChild(width)
    
    local height = AceGUI:Create("EditBox")
    height:SetLabel("Height")
    height:SetText(tostring(nodeLayout.size.height))
    height:SetRelativeWidth(0.5)
    height:SetCallback("OnEnterPressed", function(widget, event, text)
        nodeLayout.size.height = tonumber(text)
        runtimeNode:MarkLayoutAsDirty()
    end)
    sizeGroup:AddChild(height)
    
end

--TODO: Dont rebuild the whole ui everytime. Right now its just easier
function NodesTab.Refresh()
    NodesTab.container:ReleaseChildren()
    NodesTab.Build(NodesTab.container)
end