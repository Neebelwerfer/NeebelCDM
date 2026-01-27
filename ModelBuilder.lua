local _, env = ...

local function BuildTrackedModel(trackedData)
    return {
        guid = trackedData.guid,
        parentGuid = trackedData.parentGuid,
        type = "Tracked",
        frames = {},
        data = trackedData,
        internalState = {
            timers = {},
            currentTimerType = nil
        },
        dirty = {
            layout = false,
            visuals = false,
            state = false,
        }
    }
end

local function BuildGroupModel(group)
    return {
        guid = group.guid,
        parentGuid = group.parentGuid,
        type = "Group",
        frames = {},
        children = {},
        data = group,
        internalState = {},
        dirty = {
            layout = false,
            visuals = false,
            state = false,
        }
    }
end

local  function BuildModelRegistry(trackedDatas, groups)
    local modelsByGuid = {}

    for _, trackedData in pairs(trackedDatas) do
        local model = BuildTrackedModel(trackedData)
        modelsByGuid[trackedData.guid] = model
    end

    for _, group in pairs(groups) do
        local model = BuildGroupModel(group)
        modelsByGuid[group.guid] = model
    end

    return modelsByGuid
end

local function BuildModelHierarchy(modelsByGuid)
    local roots = {}

    for guid, model in pairs(modelsByGuid) do
        if model.parentGuid then
            local parent = modelsByGuid[model.parentGuid]
            if parent and parent.type == "Group" and model.parentGuid ~= model.guid then
                table.insert(parent.children, model)
            else
                print("Invalid parent for model:", guid)
                roots[guid] = model
            end
        else
            roots[guid] = model
        end
    end
    return roots
end

function DetachFromParent(model, modelsByGuid, roots)
    if not model.parentGuid then return end

    local parent = modelsByGuid[model.parentGuid]
    if parent then
        -- remove from model hierarchy
        for i, child in ipairs(parent.children or {}) do
            if child.guid == model.guid then
                table.remove(parent.children, i)
                break
            end
        end

        -- remove from persisted data
        DetachObjectFromGroup(model.data, parent.data)
    end

    model.parentGuid = nil
    roots[model.guid] = model

    parent.dirty.layout = true
    model.dirty.layout = true
end

function AttachToParent(model, newParentGuid, order, modelsByGuid, roots)
    local parent = modelsByGuid[newParentGuid]
    assert(parent and parent.type == "Group", "Invalid parent")

    roots[model.guid] = nil  -- remove from roots if present
    model.parentGuid = newParentGuid

    parent.children = parent.children or {}
    if order and order <= #parent.children then
        table.insert(parent.children, order, model)
    else
        table.insert(parent.children, model)
    end

    parent.data.children = parent.data.children or {}
    AttachObjectToGroup(model.data, parent.data, order)

    parent.dirty.layout = true
    model.dirty.layout = true
end

-- Builds a model graph from trackedData and groups
function BuildModelGraph(trackedDatas, groups)
    if env.models then
        print("Model graph already built, rebuilding")
    end
    
    local modelsByGuid = BuildModelRegistry(trackedDatas, groups)
    local roots = BuildModelHierarchy(modelsByGuid)
    env.models = {
        roots = roots,
        modelsByGuid = modelsByGuid
    }
end

function RebuildModelGraph(trackedDatas, groups)
    env.models = nil
    BuildModelGraph(trackedDatas, groups)
end

function ReparentModel(modelGuid, newParentGuid)
    local models = env.models.modelsByGuid
    local roots = env.models.roots

    local model = models[modelGuid]
    assert(model, "Model not found")

    DetachFromParent(model, models, roots)

    if newParentGuid then
        AttachToParent(model, newParentGuid, models, roots)
    end
end

-- Deletes a model and all its children from the model graph
function DeleteModel(modelGuid)
    local models = env.models.modelsByGuid
    local roots = env.models.roots
    local model = models[modelGuid]
    if not model then
        print("DeleteModel: model not found", modelGuid)
        return
    end

    -- Recursively delete children first
    if model.children then
        for _, child in ipairs(model.children) do
            DeleteModel(child.guid)
        end
        model.children = nil
    end

    DetachFromParent(model, models, roots)
    if roots[model.guid] then
        roots[model.guid] = nil
    end

    -- FrameBuilder:RemoveFrames(model)

    -- Finally remove from registry
    models[modelGuid] = nil
end