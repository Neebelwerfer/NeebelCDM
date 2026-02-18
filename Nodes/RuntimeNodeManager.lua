RuntimeNodeManager = {
    roots = {},
    lookupTable = {}
}

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

---Update each node recursively
function RuntimeNodeManager.UpdateNodes()
    for _, rootRuntimeNode in pairs(RuntimeNodeManager.roots) do
        rootRuntimeNode:Update()
    end
end

---Remove a node and all the child nodes
---@param guid string
function RuntimeNodeManager.RemoveNode(guid)
    local runtimeNode = RuntimeNodeManager.lookupTable[guid]
    assert(runtimeNode, "Node not found")

    -- TODO: Should the RuntimeNode handle this?
    -- Recursively destroy children first
    for _, childGuid in ipairs(runtimeNode.node.children) do
        RuntimeNodeManager.RemoveNode(childGuid)
    end

    
    local parent = runtimeNode.parentRuntimeNode
    if not parent then
        for i, root in ipairs(RuntimeNodeManager.roots) do
            if root.guid == guid then
                table.remove(RuntimeNodeManager.roots, i)
                break
            end
        end
    else
        for i, childGuid in ipairs(parent.node.children) do
            if childGuid == guid then
                table.remove(parent.node.children, i)
                break
            end
        end
    end

    runtimeNode:Destroy()
    RuntimeNodeManager.lookupTable[guid] = nil
end