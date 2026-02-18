---@class RuntimeNode
---@field node Node
---@field guid string
---@field frames table<string, PropertyFrame>
---@field rootFrame Frame
---@field parentRuntimeNode? RuntimeNode
---@field internalState table
RuntimeNode = {}
RuntimeNode.__index = RuntimeNode

---@param node Node
---@param parentRuntimeNode RuntimeNode?
---@return RuntimeNode
function RuntimeNode:new(node, parentRuntimeNode)
    local runtimeNode = setmetatable({}, RuntimeNode)
    
    runtimeNode.node = node
    runtimeNode.guid = node.guid
    runtimeNode.parentRuntimeNode = parentRuntimeNode
    runtimeNode.frames = {}
    runtimeNode.internalState = {
        dirtyLayout = true,
        visible = true
    }
    
    -- Register Bindings
    for _, binding in ipairs(node.bindings) do
        DataContext.RegisterBinding(runtimeNode.guid, binding)
    end
    
    -- Determine parent frame
    local parentFrame = parentRuntimeNode and parentRuntimeNode.rootFrame or UIParent
    -- Build root frame and all child frames
    runtimeNode.rootFrame = FrameBuilder.BuildRootFrame(node, parentFrame)

    return runtimeNode
end

function RuntimeNode:UpdateTransforms()
    local parentFrame = self.parentRuntimeNode and self.parentRuntimeNode.rootFrame or UIParent

    self.rootFrame:ClearAllPoints()
    self.rootFrame:SetSize(self.node.layout.size.width, self.node.layout.size.height)
    self.rootFrame:SetPoint(self.node.transform.point, parentFrame, self.node.transform.relativePoint, self.node.transform.offsetX, self.node.transform.offsetY)
    self.rootFrame:SetScale(self.node.transform.scale)

    for _, frameContext in pairs(self.rootFrame.frames) do
        frameContext:UpdateTransform(self.node.layout)
    end
end

function RuntimeNode:Update()
    for _, frameContext in pairs(self.rootFrame.frames) do
        self:UpdateFrame(frameContext)
    end

    for _, childGuid in pairs(self.node.children) do
        local childRuntimeNode = RuntimeNodeManager.lookupTable[childGuid]
        childRuntimeNode:Update()
    end

    if self.internalState.dirtyLayout then
        self:UpdateTransforms()
        if self.node.layout.dynamic.enabled then
            self:ApplyDynamicLayout()
        end
        self.internalState.dirtyLayout = false
    end
end

function RuntimeNode:Destroy() --TODO: Should this cleanup children itself? I think it should
    self.rootFrame:Destroy() -- The root frame destroys itself and its children returning them to the frame pool

    for _, binding in ipairs(self.node.bindings) do
        DataContext.UnregisterBinding(self.guid, binding)
    end
    if self.parentRuntimeNode then
        self.parentRuntimeNode:MarkLayoutAsDirty()
    end
end

------------------------------------
--- Update layout
------------------------------------

function RuntimeNode:MarkLayoutAsDirty()
    self.internalState.dirtyLayout = true

    if self.parentRuntimeNode then
        self.parentRuntimeNode:MarkLayoutAsDirty()
    end
end

---comment
---@param isVisibleOnly boolean
---@return RuntimeNode[]
function RuntimeNode:GetChildren(isVisibleOnly)
    local visibleChildren = {}
    for _, childGuid in pairs(self.node.children) do
        local childRuntimeNode = RuntimeNodeManager.lookupTable[childGuid]
        if not isVisibleOnly or childRuntimeNode.internalState.visible then
            table.insert(visibleChildren, childRuntimeNode)
        end
    end
    return visibleChildren
end


function RuntimeNode:ApplyDynamicLayout()
    local children = self:GetChildren(self.node.layout.dynamic.collapse)
    if #children == 0 then return end
    local layout = self.node.layout.dynamic
    local anchorMode = self.node.layout.dynamic.anchorMode
    local spacing = self.node.layout.dynamic.spacing
    local isHorizontal = layout.axis == GroupAxis.Horizontal
    
    --- Calculate Size
    local totalSize = 0
    for _, child in pairs(children) do
        totalSize = totalSize + (isHorizontal and child.rootFrame:GetWidth() or child.rootFrame:GetHeight())
    end
    totalSize = totalSize + (spacing * math.max(0, #children - 1))

    local currentOffset = 0
    local step = 1
    local centerOffset = 0

    if anchorMode == GroupAnchorMode.Centered then
        currentOffset = -totalSize / 2
        centerOffset = 0.5
    elseif anchorMode == GroupAnchorMode.Trailing then
        step = -1
    end

    for _, child in pairs(children) do
        child.rootFrame:ClearAllPoints()
        local childHeight = isHorizontal and child.rootFrame:GetWidth() or child.rootFrame:GetHeight()
        local offsetY = currentOffset + childHeight * centerOffset

        if isHorizontal then
            child.rootFrame:SetPoint("CENTER", self.rootFrame, "CENTER", offsetY, 0)
        else
            child.rootFrame:SetPoint("CENTER", self.rootFrame, "CENTER", 0, offsetY)
        end
        currentOffset = currentOffset + (childHeight + spacing) * step
    end
end

------------------------------------
--- Update frames
------------------------------------

--- Updates a frame
---@param frameContext PropertyFrame
function RuntimeNode:UpdateFrame(frameContext)
    local resolvedProps = self:ResolvePropsForFrame(frameContext.descriptor)
    frameContext:UpdateProperties(resolvedProps)
end

--- Updates all properties for a frame
function RuntimeNode:ResolvePropsForFrame(frameDescription)
    local resolvedProps = {}
    for propName, prop in pairs(frameDescription.props) do
        resolvedProps[propName] = self:ResolveProp(prop)
    end
    return resolvedProps
end

--- Recursively resolve a prop (handles nested structures)
function RuntimeNode:ResolveProp(prop)
    -- Handle arrays (like cooldowns)
    if type(prop) == "table" and #prop > 0 then
        local resolved = {}
        for i, item in ipairs(prop) do
            resolved[i] = self:ResolveProp(item)
        end
        return resolved
    end
    
    -- Handle prop descriptors
    if prop.resolveType == "static" then
        return prop.value
    elseif prop.resolveType == "binding" or prop.resolveType == "template" then
        if prop.value then
            local binding = self:FindBinding(prop.value.binding)
            if binding then
                local field = prop.value.field
                local value = DataContext.ResolveBinding(binding.type, binding.key, field)
                return value
            end
        end
        return nil
    end
    
    -- Handle nested objects (like CooldownDescriptor)
    if type(prop) == "table" and prop.resolveType == nil then
        local resolved = {}
        for key, val in pairs(prop) do
            resolved[key] = self:ResolveProp(val)
        end
        return resolved
    end
    
    return prop
end

---Find a binding with specific alias
---@param alias string
---@return BindingDescriptor?
function RuntimeNode:FindBinding(alias)
    for _, binding in ipairs(self.node.bindings) do
        if binding.alias == alias then
            return binding
        end
    end
    return nil
end