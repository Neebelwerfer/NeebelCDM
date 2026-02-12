NodeFactory = {}

-- Enum for template types
---@enum NodeFactory.TemplateTypes
NodeFactory.TemplateTypes = {
    Icon = 1,
    Bar = 2,
    Text = 3,
    IconButton = 4,
    TextButton = 5,
    Empty = 254, -- Used for relative positioning
    DynamicGroup = 255 -- Used for dynamic positioning of children
}

local function DefaultDynamicLayout()
    return {
        enabled = false,
        axis = GroupAxis.Right,
        anchorMode = GroupAnchorMode.Left,
        spacing = 4,
        collapse = true,
        maxPerRow = 5
    }
end

---Create an Icon template (icon + cooldown + text)
---@return Node
function NodeFactory.CreateIcon()
    return Node:New({
        name = "Icon",
        frames = {
            FrameDescriptionFactory.CreateIconFrame(),
            FrameDescriptionFactory.CreateTextFrame()
        },
        layout = {
            size = { width = 36, height = 36 },
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            dynamic = DefaultDynamicLayout()
        }
    })
end

---Create a Bar template
---@return Node
function NodeFactory.CreateBar()
    return Node:New({
        name = "Bar",
        frames = {
            FrameDescriptionFactory.CreateBarFrame()
        },
        layout = {
            size = { width = 200, height = 20 },
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            dynamic = DefaultDynamicLayout()
        }
    })
end

---Create a Text template
---@return Node
function NodeFactory.CreateText()
    return Node:New({
        name = "Text",
        frames = {
            FrameDescriptionFactory.CreateTextFrame()
        },
        layout = {
            size = { width = 100, height = 20 },
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            dynamic = DefaultDynamicLayout()
        }
    })
end

---Create an Empty container
---@return Node
function NodeFactory.CreateEmpty()
    return Node:New({
        name = "Empty",
        frames = {},
        layout = {
            size = { width = 100, height = 100 },
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            dynamic = DefaultDynamicLayout()
        }
    })
end

---Create a Dynamic Group (auto-layout container)
---@return Node
function NodeFactory.CreateDynamicGroup()
    return Node:New({
        name = "Dynamic Group",
        frames = {},
        layout = {
            size = { width = 512, height = 512 },
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            dynamic = {
                enabled = true,
                axis = GroupAxis.Vertical,
                anchorMode = GroupAnchorMode.Leading,
                spacing = 0,
                collapse = false,
                maxPerRow = 0
            }
        }
    })
end

---Create an Icon Button template
---@return Node
function NodeFactory.CreateIconButton()
    return Node:New({
        name = "Icon Button",
        frames = {
            FrameDescriptionFactory.CreateIconFrame()
            -- Would need IconButton frame type with action support
        },
        layout = {
            size = { width = 36, height = 36 },
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            dynamic = DefaultDynamicLayout()
        }
    })
end

---Create a Text Button template
---@return Node
function NodeFactory.CreateTextButton()
    return Node:New({
        name = "Text Button",
        frames = {
            FrameDescriptionFactory.CreateTextFrame()
            -- Would need TextButton frame type with action support
        },
        layout = {
            size = { width = 100, height = 30 },
            padding = { left = 5, right = 5, top = 5, bottom = 5 },
            dynamic = DefaultDynamicLayout()
        }
    })
end

local Creator = {
    [NodeFactory.TemplateTypes.Icon] = NodeFactory.CreateIcon,
    [NodeFactory.TemplateTypes.Bar] = NodeFactory.CreateBar,
    [NodeFactory.TemplateTypes.Text] = NodeFactory.CreateText,
    [NodeFactory.TemplateTypes.IconButton] = NodeFactory.CreateIconButton,
    [NodeFactory.TemplateTypes.TextButton] = NodeFactory.CreateTextButton,
    [NodeFactory.TemplateTypes.Empty] = NodeFactory.CreateEmpty,
    [NodeFactory.TemplateTypes.DynamicGroup] = NodeFactory.CreateDynamicGroup
}

---@param templateType NodeFactory.TemplateTypes
---@return Node?
function NodeFactory.Create(templateType)
    if not Creator[templateType] then
        return nil
    end
    return Creator[templateType]()
end