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
    container:SetLayout("Fill")
    container:SetFullHeight(true)
    container:SetFullWidth(true)
    
    if group == "properties" then
        NodesTab.BuildPropertiesPanel(container)
    elseif group == "layout" then
        NodesTab.BuildLayoutPanel(container)
    elseif group == "bindings" then
        NodesTab.BuildBindingsPanel(container)
    end

    container:DoLayout()
end


--------------------------------------------
--- Properties
--------------------------------------------

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


--------------------------------------------
--- Layout
--------------------------------------------

--- Build the layout panel which should help with arranging frames.
---@param container AceGUIContainer
function NodesTab.BuildLayoutPanel(container)
    local runtimeNode = RuntimeNodeManager.lookupTable[NodesTab.selectedNodeGuid]
    local node = runtimeNode.node
    local nodeLayout = node.layout
    local nodeTransform = node.transform
    
    -- Wrap ScrollFrame in SimpleGroup (same as Properties)
    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetHeight(10)
    scrollContainer:SetLayout("Fill")
    container:AddChild(scrollContainer)
    
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scrollContainer:AddChild(scroll)
    
    -- Transform Section
    local transformGroup = AceGUI:Create("InlineGroup")
    transformGroup:SetTitle("Transform")
    transformGroup:SetFullWidth(true)
    transformGroup:SetLayout("Flow")
    scroll:AddChild(transformGroup)
    
    -- Anchor points
    NodesTab.CreateDropdown(transformGroup, "Anchor Point", nodeTransform.point, 0.5, 
        NodesTab.AnchorList, function(value)
            nodeTransform.point = value
            runtimeNode:MarkLayoutAsDirty()
        end)
    
    NodesTab.CreateDropdown(transformGroup, "Relative To", nodeTransform.relativePoint, 0.5,
        NodesTab.AnchorList, function(value)
            nodeTransform.relativePoint = value
            runtimeNode:MarkLayoutAsDirty()
        end)
    
    -- Position
    NodesTab.CreateNumberInput(transformGroup, "X Offset", nodeTransform.offsetX, 0.5, function(value)
        nodeTransform.offsetX = value
        runtimeNode:MarkLayoutAsDirty()
    end)
    
    NodesTab.CreateNumberInput(transformGroup, "Y Offset", nodeTransform.offsetY, 0.5, function(value)
        nodeTransform.offsetY = value
        runtimeNode:MarkLayoutAsDirty()
    end)
    
    -- Scale
    NodesTab.CreateNumberInput(transformGroup, "Scale", nodeTransform.scale or 1, 1, function(value)
        nodeTransform.scale = value
        runtimeNode:MarkLayoutAsDirty()
    end)
    
    -- Size Section
    local sizeGroup = AceGUI:Create("SimpleGroup")
    sizeGroup:SetFullWidth(true)
    sizeGroup:SetLayout("Flow")
    scroll:AddChild(sizeGroup)
    
    NodesTab.CreateNumberInput(sizeGroup, "Width", nodeLayout.size.width, 0.5, function(value)
        nodeLayout.size.width = value
        runtimeNode:MarkLayoutAsDirty()
    end)
    
    NodesTab.CreateNumberInput(sizeGroup, "Height", nodeLayout.size.height, 0.5, function(value)
        nodeLayout.size.height = value
        runtimeNode:MarkLayoutAsDirty()
    end)
    
    -- Dynamic Layout Section
    local dynamicGroup = AceGUI:Create("SimpleGroup")
    dynamicGroup:SetFullWidth(true)
    dynamicGroup:SetLayout("Flow")
    scroll:AddChild(dynamicGroup)
    
    local enabledCheckbox = AceGUI:Create("CheckBox")
    enabledCheckbox:SetLabel("Enable Dynamic Layout")
    enabledCheckbox:SetValue(nodeLayout.dynamic.enabled)
    enabledCheckbox:SetFullWidth(true)
    enabledCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        nodeLayout.dynamic.enabled = value
        runtimeNode:MarkLayoutAsDirty()
        NodesTab.RefreshInspector()
    end)
    dynamicGroup:AddChild(enabledCheckbox)
    
    if nodeLayout.dynamic.enabled then
        -- Axis
        NodesTab.CreateDropdown(dynamicGroup, "Axis", nodeLayout.dynamic.axis, 1,
            {[GroupAxis.Horizontal] = "Horizontal", [GroupAxis.Vertical] = "Vertical"},
            function(value)
                nodeLayout.dynamic.axis = value
                runtimeNode:MarkLayoutAsDirty()
            end)
        
        -- Anchor Mode
        NodesTab.CreateDropdown(dynamicGroup, "Anchor Mode", nodeLayout.dynamic.anchorMode, 1,
            {[GroupAnchorMode.Leading] = "Leading", [GroupAnchorMode.Centered] = "Centered", [GroupAnchorMode.Trailing] = "Trailing"},
            function(value)
                nodeLayout.dynamic.anchorMode = value
                runtimeNode:MarkLayoutAsDirty()
            end)
        
        -- Spacing
        NodesTab.CreateNumberInput(dynamicGroup, "Spacing", nodeLayout.dynamic.spacing, 0.5, function(value)
            nodeLayout.dynamic.spacing = value
            runtimeNode:MarkLayoutAsDirty()
        end)
        
        -- Max Per Row
        NodesTab.CreateNumberInput(dynamicGroup, "Max Per Row", nodeLayout.dynamic.maxPerRow, 0.5, function(value)
            nodeLayout.dynamic.maxPerRow = value
            runtimeNode:MarkLayoutAsDirty()
        end)
        
        -- Collapse
        local collapseCheckbox = AceGUI:Create("CheckBox")
        collapseCheckbox:SetLabel("Collapse Hidden Children")
        collapseCheckbox:SetValue(nodeLayout.dynamic.collapse)
        collapseCheckbox:SetFullWidth(true)
        collapseCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
            nodeLayout.dynamic.collapse = value
            runtimeNode:MarkLayoutAsDirty()
        end)
        dynamicGroup:AddChild(collapseCheckbox)
    end

    container:DoLayout()
end

-- Helper Functions

NodesTab.AnchorList = {
        TOPLEFT = "Top Left",
        TOP = "Top",
        TOPRIGHT = "Top Right",
        LEFT = "Left",
        CENTER = "Center",
        RIGHT = "Right",
        BOTTOMLEFT = "Bottom Left",
        BOTTOM = "Bottom",
        BOTTOMRIGHT = "Bottom Right"
    }

function NodesTab.CreateDropdown(container, label, value, width, list, callback)
    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetLabel(label)
    dropdown:SetList(list)
    dropdown:SetValue(value)
    dropdown:SetRelativeWidth(width)
    dropdown:SetCallback("OnValueChanged", function(widget, event, newValue)
        callback(newValue)
    end)
    container:AddChild(dropdown)
    return dropdown
end

function NodesTab.CreateNumberInput(container, label, value, width, callback)
    local input = AceGUI:Create("EditBox")
    input:SetLabel(label)
    input:SetText(tostring(value))
    input:SetRelativeWidth(width)
    input:DisableButton(true)
    input:SetCallback("OnEnterPressed", function(widget, event, text)
        local num = tonumber(text)
        if num then
            callback(num)
        else
            widget:SetText(tostring(value))  -- Reset to previous value
        end
    end)
    container:AddChild(input)
    return input
end

--------------------------------------------
--- Bindings
--------------------------------------------

local DataTypeToString = {
    [DataTypes.Spell] = "Spell",
    [DataTypes.Aura] = "Aura",
    [DataTypes.Item] = "Item",
    [DataTypes.Resource] = "Resource"
}

function NodesTab.BuildBindingsPanel(container)
    local runtimeNode = RuntimeNodeManager.lookupTable[NodesTab.selectedNodeGuid]
    local node = runtimeNode.node
    
    container:SetLayout("Flow")
    
    -- Add Binding Button
    local addButton = AceGUI:Create("Button")
    addButton:SetText("Add Binding")
    addButton:SetFullWidth(true)
    addButton:SetCallback("OnClick", function()
        NodesTab.ShowBindingEditor(node.guid, nil)  -- nil = create new
    end)
    container:AddChild(addButton)
    
    -- Spacer
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    container:AddChild(spacer)
    
    -- Existing Bindings List
    local bindingsGroup = AceGUI:Create("InlineGroup")
    bindingsGroup:SetTitle("Bindings (" .. #node.bindings .. ")")
    bindingsGroup:SetFullWidth(true)
    bindingsGroup:SetLayout("Flow")
    container:AddChild(bindingsGroup)
    
    if #node.bindings == 0 then
        local emptyLabel = AceGUI:Create("Label")
        emptyLabel:SetText("No bindings. Click 'Add Binding' to create one.")
        emptyLabel:SetFullWidth(true)
        bindingsGroup:AddChild(emptyLabel)
    else
        for i, binding in ipairs(node.bindings) do
            local bindingRow = AceGUI:Create("SimpleGroup")
            bindingRow:SetFullWidth(true)
            bindingRow:SetLayout("Flow")
            bindingsGroup:AddChild(bindingRow)
            
            -- Icon (if available)
            local icon = NodesTab.GetBindingIcon(binding)
            if icon then
                local iconWidget = AceGUI:Create("Icon")
                iconWidget:SetImage(icon)
                iconWidget:SetImageSize(24, 24)
                iconWidget:SetWidth(32)
                bindingRow:AddChild(iconWidget)
            end
            
            -- Alias + Type/ID info
            local infoLabel = AceGUI:Create("Label")
            infoLabel:SetText(string.format("%s\n|cFF888888%s: %s|r", 
                binding.alias, 
                DataTypeToString[binding.type], 
                tostring(binding.key)))
            infoLabel:SetRelativeWidth(0.6)
            bindingRow:AddChild(infoLabel)
            
            -- Edit button
            local editButton = AceGUI:Create("Button")
            editButton:SetText("Edit")
            editButton:SetWidth(60)
            editButton:SetCallback("OnClick", function()
                NodesTab.ShowBindingEditor(node.guid, i)
            end)
            bindingRow:AddChild(editButton)
            
            -- Delete button
            local deleteButton = AceGUI:Create("Button")
            deleteButton:SetText("Delete")
            deleteButton:SetWidth(120)
            deleteButton:SetCallback("OnClick", function()
                runtimeNode:RemoveBinding(i)
                container:ReleaseChildren()
                NodesTab.BuildBindingsPanel(container)
            end)
            bindingRow:AddChild(deleteButton)
        end
    end
end

-- Binding Editor Dialog
function NodesTab.ShowBindingEditor(nodeGuid, bindingIndex)
    local runtimeNode = RuntimeNodeManager.lookupTable[nodeGuid]
    local node = runtimeNode.node
    if not node then return end
    
    local isEdit = bindingIndex ~= nil
    local binding = isEdit and node.bindings[bindingIndex] or {
        type = DataTypes.Spell,
        alias = "",
        key = ""
    }
    
    -- Create editor frame
    local frame = AceGUI:Create("Window")
    frame:SetTitle(isEdit and "Edit Binding" or "Create Binding")
    frame:SetLayout("Flow")
    frame:SetWidth(400)
    frame:SetHeight(300)
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)
    
    -- Type dropdown
    local typeDropdown = AceGUI:Create("Dropdown")
    typeDropdown:SetLabel("Type")
    typeDropdown:SetList({
        [DataTypes.Spell] = "Spell",
        [DataTypes.Aura] = "Aura",
        [DataTypes.Item] = "Item",
        [DataTypes.Resource] = "Resource"
    })
    typeDropdown:SetValue(binding.type)
    typeDropdown:SetFullWidth(true)
    frame:AddChild(typeDropdown)
    
    -- Alias input
    local aliasInput = AceGUI:Create("EditBox")
    aliasInput:SetLabel("Alias (Display Name)")
    aliasInput:SetText(binding.alias)
    aliasInput:SetFullWidth(true)
    aliasInput:DisableButton(true)
    frame:AddChild(aliasInput)
    
    -- Key input
    local keyInput = AceGUI:Create("EditBox")
    keyInput:SetLabel("ID (Spell/Aura/Item/Resource ID)")
    keyInput:SetText(tostring(binding.key))
    keyInput:SetFullWidth(true)
    keyInput:DisableButton(true)
    frame:AddChild(keyInput)
    
    -- Options section (if needed later)
    -- local optionsGroup = AceGUI:Create("InlineGroup")
    -- optionsGroup:SetTitle("Options")
    -- optionsGroup:SetFullWidth(true)
    -- optionsGroup:SetLayout("Flow")
    -- frame:AddChild(optionsGroup)
    
    -- Buttons
    local buttonGroup = AceGUI:Create("SimpleGroup")
    buttonGroup:SetFullWidth(true)
    buttonGroup:SetLayout("Flow")
    frame:AddChild(buttonGroup)
    
    local saveButton = AceGUI:Create("Button")
    saveButton:SetText(isEdit and "Save" or "Create")
    saveButton:SetWidth(120)
    saveButton:SetCallback("OnClick", function()
        local newBinding = {
            type = typeDropdown:GetValue(),
            alias = aliasInput:GetText(),
            key = tonumber(keyInput:GetText()) or keyInput:GetText()
        }
        
        if newBinding.alias == "" or newBinding.key == "" then
            print("Alias and ID are required")
            return
        end
        
        if isEdit then
            runtimeNode:UpdateBinding(bindingIndex, newBinding)
        else
            runtimeNode:AddBinding(newBinding)
        end       
        frame:Hide()
    end)
    buttonGroup:AddChild(saveButton)
end

--------------------------------------------
--- Context Menu
--------------------------------------------

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

--------------------------------------------
--- Utility
--------------------------------------------

function NodesTab.GetBindingIcon(binding)
    if binding.type == DataTypes.Spell or binding.type == DataTypes.Aura then
        local spellInfo = C_Spell.GetSpellInfo(binding.key)
        return spellInfo and spellInfo.iconID
    elseif binding.type == DataTypes.Item then
        local itemInfo = C_Item.GetItemIconByID(binding.key)
        return itemInfo
    end
    return QuestionMark
end


--TODO: Dont rebuild the whole ui everytime. Right now its just easier
function NodesTab.Refresh()
    NodesTab.container:ReleaseChildren()
    NodesTab.Build(NodesTab.container)
end