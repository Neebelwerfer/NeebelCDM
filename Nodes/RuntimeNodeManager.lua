RuntimeNodeManager = {
    roots = {},
    lookupTable = {}
}

---comment
---@param nodes table<string, Node>
function RuntimeNodeManager.BuildAll(nodes)
    RuntimeNodeManager.roots = {}
    RuntimeNodeManager.lookupTable = {}

    for _, node in pairs(nodes) do
        if node.parentGuid == nil then
            local rootRuntimeNode = RuntimeNodeManager.BuildRuntimeNode(nodes, node)
            RuntimeNodeManager.lookupTable[rootRuntimeNode.guid] = rootRuntimeNode
            table.insert(RuntimeNodeManager.roots, rootRuntimeNode)
        end
    end
end

---comment
---@param nodes table<string, Node>
---@param node Node
---@param parentRuntimeNode? RuntimeNode
function RuntimeNodeManager.BuildRuntimeNode(nodes, node, parentRuntimeNode)
    local runtimeNode = RuntimeNode:new(node, parentRuntimeNode)

    for _, childNode in pairs(node.children) do
        local childRuntimeNode = RuntimeNodeManager.BuildRuntimeNode(nodes, nodes[childNode], runtimeNode)
        RuntimeNodeManager.lookupTable[childRuntimeNode.guid] = childRuntimeNode
    end

    return runtimeNode
end

function RuntimeNodeManager.UpdateNodes()
    for _, rootRuntimeNode in pairs(RuntimeNodeManager.roots) do
        rootRuntimeNode:Update()
    end
end