local _, ns = ...

---@class RuntimeNode
---@field node Node
---@field guid string
---@field frames table<string, PropertyFrame>
---@field rootFrame Frame
---@field parentRuntimeNode? RuntimeNode
---@field internalState table

local RuntimeNode = {}
RuntimeNode.__index = RuntimeNode
ns.Nodes.RuntimeNode = RuntimeNode

local Core = ns.Core
local Data = ns.Data

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
        dirtyFrames = false,
        visible = true
    }
    
    -- Register Bindings
    for _, binding in ipairs(node.bindings) do
        Data.DataContext.RegisterBinding(runtimeNode.guid, binding)
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
        local childRuntimeNode = ns.Nodes.RuntimeNodeManager.lookupTable[childGuid] -- TODO: Should runtime node know about manager? Maybe manager handle this or we pass the lookupTable down
        childRuntimeNode:Update()
    end

    if self.internalState.dirtyFrames then
        self:RebuildFrames()
        self.internalState.dirtyFrames = false
    end

    if self.internalState.dirtyLayout then
        self:UpdateTransforms()
        if self.node.layout.dynamic.enabled then
            self:ApplyDynamicLayout()
        end
        self.internalState.dirtyLayout = false
    end
end

function RuntimeNode:RebuildFrames()
    self.rootFrame:Destroy()
    self.rootFrame = FrameBuilder.BuildRootFrame(self.node, self.parentRuntimeNode and self.parentRuntimeNode.rootFrame or UIParent)

    self:MarkLayoutAsDirty()
end

function RuntimeNode:MarkFramesAsDirty()
    self.internalState.dirtyFrames = true
end


function RuntimeNode:Destroy() --TODO: Should this cleanup children itself? I think it should
    self.rootFrame:Destroy() -- The root frame destroys itself and its children returning them to the frame pool

    for _, binding in ipairs(self.node.bindings) do
        Data.DataContext.UnregisterBinding(self.guid, binding)
    end
    if self.parentRuntimeNode then
        self.parentRuntimeNode:MarkLayoutAsDirty()
    end
end

function RuntimeNode:AddBinding(binding)
    table.insert(self.node.bindings, binding)
    Data.DataContext.RegisterBinding(self.node.guid, binding)
end

function RuntimeNode:UpdateBinding(index, newBinding)
    Data.DataContext.UnregisterBinding(self.node.guid, self.node.bindings[index])
    self.node.bindings[index] = newBinding
    Data.DataContext.RegisterBinding(self.node.guid, newBinding)
end

function RuntimeNode:RemoveBinding(index)
    local binding = self.node.bindings[index]
    Data.DataContext.UnregisterBinding(self.node.guid, binding)
    table.remove(self.node.bindings, index)
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
        local childRuntimeNode = ns.Nodes.RuntimeNodeManager.lookupTable[childGuid] -- TODO: Another lookupTable reference!
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
    local isHorizontal = layout.axis == Core.GroupAxis.Horizontal
    
    --- Calculate Size
    local totalSize = 0
    for _, child in pairs(children) do
        totalSize = totalSize + (isHorizontal and child.rootFrame:GetWidth() or child.rootFrame:GetHeight())
    end
    totalSize = totalSize + (spacing * math.max(0, #children - 1))

    local currentOffset = 0
    local step = 1
    local centerOffset = 0

    if anchorMode == Core.GroupAnchorMode.Centered then
        currentOffset = -totalSize / 2
        centerOffset = 0.5
    elseif anchorMode == Core.GroupAnchorMode.Trailing then
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
    elseif prop.resolveType == "binding" then
        if prop.value then
            local binding = self:FindBinding(prop.value.binding)
            if binding then
                local field = prop.value.field
                local value = Data.DataContext.ResolveBinding(binding.type, binding.key, field)
                return value
            end
        end
        return nil
    elseif prop.resolveType == "template" then --TODO: Look into caching here!!
        local bindings = {}
        -- find bindings from the template indicated by {binding:field}
        for alias, field in string.gmatch(prop.value, "{([^}:]+):([^}]+)}") do
            local binding = self:FindBinding(alias)
            if binding then
                if not bindings[alias..":"..field] then
                    bindings[alias..":"..field] = Data.DataContext.ResolveBinding(binding.type, binding.key, field)
                end
            end
        end

        local text = prop.value
        for key, value in pairs(bindings) do
            text = string.gsub(text, "{"..key.."}", value)
        end
        
        return text
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