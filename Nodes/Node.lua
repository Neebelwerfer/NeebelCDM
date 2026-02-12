Node = {}
Node.__index = Node

---@return Transform
local function DefaultTransform()
    return {
        point = "CENTER",
        relativePoint = "CENTER",
        offsetX = 0,
        offsetY = 0,
        scale = 1
    }
end


---@enum Node.NodeTypes
Node.NodeTypes = {
    Icon = 1,
    Bar = 2,
    Text = 3,
    IconButton = 4,
    TextButton = 5,
    Group = 254, -- Used for relative positioning
    DynamicGroup = 255 -- Used for dynamic positioning of children
}

---@class Layout
---@field size { width: number, height: number }
---@field padding { left: number, right: number, top: number, bottom: number }
---@field dynamic { enabled: boolean, axis: GroupAxis, anchorMode: GroupAnchorMode, spacing: number, collapse: boolean, maxPerRow: number }

---@class Transform
---@field point string
---@field relativePoint? string
---@field offsetX number
---@field offsetY number
---@field scale number

---@class StateDescriptor
---@field name string
---@field condition RuleBindingDescriptor | RuleComposite
---@field nodeOverrides? table<string, any>  -- Override node-level properties
---@field frameOverrides? table<string, table<string, any>>  -- frameOverrides[frameName][propName] = value

---@class Node
---@field guid string
---@field name string
---@field transform Transform
---@field parentGuid? string
---@field children string[] -- Node guids
---@field frames FrameDescriptor[]
---@field bindings BindingDescriptor[]
---@field states StateDescriptor[]  -- Evaluated in order, first match wins
---@field layout Layout
---@field options table
---@field loadRules table
---@field isDirty boolean
---@field meta table

---@return Node
function Node:New(overrides)
    local node = {
        guid = GenerateGUID(),
        transform = DefaultTransform(),
        parentGuid = nil,
        children = {},

        -- Frames defines the frame this node generates
        -- The frame has a type: "Icon", "Bar", "Text", "Base"
        frames = {},
        -- Bindings are the values that are passed to the frames
        bindings = {},
        -- States are evaluated in order and the first match wins
        states = {},


        -- Layout
        layout = {      
            size = {
                width = 0,
                height = 0
            },
            padding = {
                left = 0,
                right = 0,
                top = 0,
                bottom = 0
            },
            dynamic = {
                enabled = false,
                axis = GroupAxis.Horizontal,
                anchorMode = GroupAnchorMode.Centered,
                spacing = 4,
                collapse = true,     -- skip invisible/disabled children
                maxPerRow = 4
            }
        },

        options = {
        },

        loadRules = {
            spec = nil,
            class = nil,
            role = nil,
            never = false,
        },

        isDirty = false,
        meta = {version = 1},
    }

    if overrides then
        for k, v in pairs(overrides) do
            node[k] = v
        end
    end
    setmetatable(node, self)
    return node
end