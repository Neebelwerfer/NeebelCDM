local function DefaultVisualValues()
    return {
        icon = {
            size = {width = 32, height = 32},
            alpha = 1.0,
            colorMask = {1.0, 1.0, 1.0, 1.0}
        }
    }
end

local function DefaultAuraValues()
    local defaultValues = DefaultVisualValues()
    defaultValues.selectedType = AuraVisualTypes.Icon
    defaultValues.Bar = {
        size = {width = 120, height = 8},
        backgroundColor = {1.0, 1.0, 1.0, 1.0},
        barFillColor = {1.0, 1.0, 1.0, 1.0}
    }
    return defaultValues
end

local function DefaultPositionValues()
    return {
        point = "CENTER",
        relativePoint = nil,
        offsetX = 0,
        offsetY = 0
    }
end

local creators = {
    [TrackedObjectTypes.Spell] = CreateTrackedSpell,
    [TrackedObjectTypes.Item] = CreateTrackedItem,
    [TrackedObjectTypes.Aura] = CreateTrackedAura
}


function CreateTrackedObject(type, id, parentGuid)
    local creator = creators[type]
    if not creator then
        return nil, "Unknown tracked object type"
    end
    return creator(id, parentGuid)
end


function CreateTrackedSpell(spellID, parentGuid)
    if not C_Spell.DoesSpellExist(spellID) then
        return nil, "Spell does not exist"
    end

    return {
        name = "New Spell",
        guid = GenerateGUID(),
        type = TrackedObjectTypes.Spell,
        parentGuid = parentGuid,
        sourceID = spellID,
        visual = DefaultVisualValues(),
        position = DefaultPositionValues(),
        enabled = true
    }
end

function CreateTrackedItem(itemID, parentGuid)
    if not C_Item.DoesItemExistByID(itemID) then
        return nil, "Item does not exist"
    end

    return {
        name = "New Item",
        guid = GenerateGUID(),
        type = TrackedObjectTypes.Item,
        parentGuid = parentGuid,
        sourceID = itemID,
        visual = DefaultVisualValues(),
        position = DefaultPositionValues(),
        enabled = true
    }
end

function CreateTrackedAura(auraID, parentGuid)
    if not C_Spell.DoesSpellExist(auraID) then
        return nil, "Aura does not exist"
    end

    return {
        name = "New Aura",
        guid = GenerateGUID(),
        type = TrackedObjectTypes.Aura,
        parentGuid = parentGuid,
        sourceID = auraID,
        visual = DefaultAuraValues(),
        position = DefaultPositionValues(),
        config = {
            aura = {
                visibility = AuraShowOptions.HideWhenInactive
            }
        },
        enabled = true
    }
end


local function DefaultGroupVisualOptions()
    return {
        background = {
            enabled = false,
            color = {1.0, 1.0, 1.0, 1.0},
        },
        border = {
            enabled = false,
            color = {1.0, 1.0, 1.0, 1.0},
        },
        padding = {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0
        }
    }
end

local function DefaultGroupConfig()
    return {
        group = {
            scale = 1.0,
        }
    }
end

local function DefaultDynamicGroupConfig()
    local config = DefaultGroupConfig()
    config.dynamicGroup = {
        maxPerRow = 6,
        growDirection = GroupGrowDirection.Right,
        spacing = {
            x = 0,
            y = 0
        }
    }
    return config
end

-- Simple Group acting as a container
function CreateObjectGroup(parentGuid)
    return {
        name = "New Group",
        guid = GenerateGUID(),
        dynamic = false,
        parentGuid = parentGuid,
        position = DefaultPositionValues(),
        visual = DefaultGroupVisualOptions(),
        config = DefaultGroupConfig(),
        children = {},
        enabled = true
    }
end

-- Group managing the layout of its children
function CreateDynamicObjectGroup(parentGuid)
    return {
        name = "New Dynamic Group",
        guid = GenerateGUID(),
        dynamic = true,
        parentGuid = parentGuid,
        position = DefaultPositionValues(),
        visual = DefaultGroupVisualOptions(),
        config = DefaultDynamicGroupConfig(),
        children = {},
        enabled = true
    }
end


function AttachObjectToGroup(object, group, order)
    if group.type then
        return false, "Cannot attach object to non-group object"
    end

    group.children = group.children or {}

    if order and order <= #group.children then
        table.insert(group.children, order, object)
    else
        table.insert(group.children, object)
    end

    object.parentGuid = group.guid
    return true
end

function DetachObjectFromGroup(object, group)
    if group.type ~= "Group" then
        return false, "Cannot detach object from non-group object"
    end

    if not group.children then
        return false, "Group has no children"
    end

    for i = 1, #group.children do
        if group.children[i] == object then
            table.remove(group.children, i)
            object.parentGuid = nil
            return true
        end
    end

    return false, "Object not found in group"
end
