---@class RuntimeNode
---@field node Node
---@field guid string
---@field frames Frame[]
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
    
    -- Build all child frames from descriptors
    for _, frameDescriptor in ipairs(node.frames) do
        local frame = FrameBuilder.BuildFrameFromDescriptor(node, self.rootFrame, frameDescriptor)
        self.frames[frameDescriptor.name] = frame
    end
    
    return self
end

function RuntimeNode:Update()
end
