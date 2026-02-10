---@class RuntimeNode
---@field node Node
---@field guid string
---@field frames table<string, {frame: Frame, descriptor: FrameDescriptor}>
---@field rootFrame Frame
---@field parentRuntimeNode? RuntimeNode
---@field internalState table
RuntimeNode = {}
RuntimeNode.__index = RuntimeNode

---@param node Node
---@param parentRuntimeNode RuntimeNode?
---@return RuntimeNode
function RuntimeNode:new(node, parentRuntimeNode)
    local self = setmetatable({}, RuntimeNode)
    
    self.node = node
    self.guid = node.guid
    self.parentRuntimeNode = parentRuntimeNode
    self.frames = {}
    
    
    
    -- Register Bindings
    for _, binding in ipairs(node.bindings) do
        DataContext.RegisterBinding(self.guid, binding)
    end
    
    -- Determine parent frame
    local parentFrame = parentRuntimeNode and parentRuntimeNode.rootFrame or UIParent
    
    -- Get all the resolved props 
    -- TODO: Re-think this loop?
    local resolvedPropsPerFrame = {}
    for _, frameDescriptor in ipairs(node.frames) do
        local resolvedProps = self:ResolvePropsForFrame(frameDescriptor)
        resolvedPropsPerFrame[frameDescriptor.name] = resolvedProps
    end

    -- Build root frame and all child frames
    self.rootFrame = FrameBuilder.BuildRootFrame(node, parentFrame, resolvedPropsPerFrame)

    return self
end


function RuntimeNode:Update()
    for _, frameContext in pairs(self.rootFrame.frames) do
        self:UpdateFrame(frameContext.frame, frameContext.descriptor)
    end

    for _, childNode in pairs(self.node.children) do
        local childRuntimeNode = RuntimeNodeManager.lookupTable[childNode.guid]
        childRuntimeNode:Update()
    end
end

---comment
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

---comment
---@param frame Frame
---@param descriptor FrameDescriptor
function RuntimeNode:UpdateFrame(frame, descriptor)
    local resolvedProps = self:ResolvePropsForFrame(descriptor)
    FrameBuilder.UpdateFrameByProps(frame, descriptor, resolvedProps)
end

function RuntimeNode:ResolvePropsForFrame(frameDescription)
    local resolvedProps = {}
    for propName, prop in pairs(frameDescription.props) do
        resolvedProps[propName] = self:ResolveProp(prop)
    end
    return resolvedProps
end

---Recursively resolve a prop (handles nested structures)
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