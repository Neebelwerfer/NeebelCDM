RuntimeNodeManager = {}

---comment
---@param nodes table<string, Node>
function RuntimeNodeManager:BuildAll(nodes)
    self.roots = {}
    self.lookupTable = {}

    for _, node in pairs(nodes) do
        if node.parentGuid == nil then
            table.insert(self.roots, node)
        end
    end

    for _, root in pairs(self.roots) do
        self:BuildRuntimeNode(nodes, root, nil)
    end
end


---comment
---@param nodes table<string, Node>
---@param node Node
---@param parentRuntimeNode? RuntimeNode
function RuntimeNodeManager:BuildRuntimeNode(nodes, node, parentRuntimeNode)
    local runtimeNode = RuntimeNode:new(node, parentRuntimeNode)

    self.lookupTable[node.guid] = runtimeNode

    for _, childNode in pairs(node.children) do
        self:BuildRuntimeNode(nodes, nodes[childNode], runtimeNode)
    end
end