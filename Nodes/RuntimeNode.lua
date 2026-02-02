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
    
    -- Determine parent frame
    local parentFrame = parentRuntimeNode and parentRuntimeNode.rootFrame or UIParent
    
    -- Build root frame
    self.rootFrame = FrameBuilder.BuildRootFrame(node, parentFrame)

    -- Register Bindings
    for _, binding in ipairs(node.bindings) do
        DataContext.RegisterBinding(self.guid, binding)
    end
    
    -- Build all child frames from descriptors
    for _, frameDescriptor in ipairs(node.frames) do
        local resolvedProps = self:ResolvePropsForFrame(frameDescriptor)
        local frame = FrameBuilder.BuildFrameFromDescriptor(node, self.rootFrame, frameDescriptor, resolvedProps)
        self.frames[frameDescriptor.name] = {frame = frame, descriptor = frameDescriptor}
    end

    return self
end


function RuntimeNode:Update()
    for _, frame in pairs(self.frames) do
        self:UpdateFrame(frame.frame, frame.descriptor)
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

end

function RuntimeNode:ResolvePropsForFrame(frameDescription)
    local resolvedProps = {}

    for propName, prop in pairs(frameDescription.props) do
        if prop.resolveType == "static" then
            resolvedProps[propName] = prop.value
        elseif prop.resolveType == "binding" then
            if prop.value then
                local binding = self:FindBinding(prop.value.binding)
                if binding then
                    local field = prop.value.field
                    local value = DataContext.ResolveBinding(binding.type, binding.key, field)
                    if value then
                        resolvedProps[propName] = value
                    end
                end
            end
        end
    end

    return resolvedProps
end
