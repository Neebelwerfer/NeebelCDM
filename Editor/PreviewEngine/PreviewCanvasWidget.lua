local _, ns = ...
local AceGUI = LibStub("AceGUI-3.0")
local Type = "PreviewCanvas"
local Version = 1
local previewNode = ns.Editor.Preview.PreviewNode
local previewDataProvider = ns.Editor.Preview.PreviewDataProvider


local function BuildCanvas(widget, frame)
    local canvas = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    canvas:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 1
    })
    canvas:SetBackdropColor(0, 0, 0, 0.8)
    -- canvas:SetSize(height, width * 0.7)
    canvas:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    canvas:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    widget.canvas = canvas

    local viewport = CreateFrame("Frame", nil, canvas)
    viewport:SetClipsChildren(true)
    widget.viewport = viewport

    local scaleSlider = CreateFrame("Slider", nil, canvas, "OptionsSliderTemplate")
    scaleSlider:SetPoint("BOTTOMLEFT", 10, 10)
    scaleSlider:SetMinMaxValues(0.5, 3)
    scaleSlider:SetValue(1)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:SetScript("OnValueChanged", function(self, value)
            widget:SetNodeScale(value)
            widget.scaleNumber.scaleText:SetText(string.format("%.1f", value))
    end)
    widget.scaleSlider = scaleSlider

    local scaleNumber = CreateFrame("Frame", nil, scaleSlider)
    local scaleText = scaleNumber:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleText:SetText("1")
    scaleNumber.scaleText = scaleText
    local scaleSliderWidth = scaleSlider:GetWidth()
    scaleNumber:SetSize(scaleSliderWidth, 20)
    scaleNumber:SetPoint("CENTER", scaleSlider, "CENTER", scaleSliderWidth / 2 + 12, 0)
    scaleNumber.scaleText:SetAllPoints(scaleNumber)
    widget.scaleNumber = scaleNumber
    
    -- Update loop for the previewEngine
    canvas:SetScript("OnUpdate", function(self, deltaTime)
        previewDataProvider.Update(deltaTime)

        if widget.node then
            widget.node:Update(deltaTime)
        end
    end)
end

local function BuildComponentList(widget, frame)
    local inspector = AceGUI:Create("InlineGroup")
    inspector:SetTitle("Inspector")
    inspector.frame:SetParent(frame)
    inspector.frame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, 0)
    inspector.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 0)
    inspector:SetLayout("List")

    inspector.SetupNode = function(self, node)
        self:ReleaseChildren()

        local first = true
        for _, frameDescriptor in pairs(node.frames) do
            local button = AceGUI:Create("Button")
            button:SetText(frameDescriptor.name)
            button:SetFullWidth(true)
            
            local tex = "Interface\\Buttons\\WHITE8X8"
            button.frame:SetNormalTexture(tex)
            button.frame:SetPushedTexture(tex)
            button.frame:SetHighlightTexture(tex)
            button.frame:SetDisabledTexture(tex)
            
            button.frame:GetNormalTexture():SetVertexColor(0.1,0.1,0.1,0.9)
            button.frame:GetPushedTexture():SetVertexColor(0.05,0.05,0.05,1)
            button.frame:GetHighlightTexture():SetVertexColor(1,1,1,0.1)
            button.frame:GetDisabledTexture():SetVertexColor(0.2,0.2,0.2,0.5)

            button:SetCallback("OnClick", function(button)
                widget:Fire("OnComponentSelected", frameDescriptor)
                button:SetDisabled(true)
                if inspector.selected then
                    inspector.selected:SetDisabled(false)
                end
                inspector.selected = button
            end)

            if first then
                widget:Fire("OnComponentSelected", frameDescriptor)
                inspector.selected = button
                button:SetDisabled(true)
                first = false
            end

            self:AddChild(button)
        end
    end

    widget.componentList = inspector
end


local function Constructor()
    local frame = CreateFrame("Frame", nil)
    frame:EnableMouse(true)

    local widget = {
        type = Type,
        frame = frame,
    }
    BuildCanvas(widget, frame)
    BuildComponentList(widget, frame)

    function widget:OnWidthSet(width)
        self.canvas:SetWidth(width)

        local inspectorWidth = math.max(200, width * 0.3)
        self.componentList:SetWidth(inspectorWidth)

        local viewportWidth = width - inspectorWidth - 10
        self.viewport:ClearAllPoints()
        self.viewport:SetPoint("TOPLEFT", self.canvas, "TOPLEFT", 0, 0)
        self.viewport:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", 0, 0)
        self.viewport:SetWidth(viewportWidth)
    end

    function widget:OnHeightSet(height)
        self.frame:SetHeight(height)
        self.canvas:SetHeight(height)
        self.viewport:SetHeight(height)

        self.componentList:SetHeight(height)
    end

    function widget:ClearNode()
        if not widget.node then return end
        widget.node:Destroy()
        -- widget.propertyList:Destroy()
        widget.node = nil
    end

    function widget:SetNode(node)
        if widget.node then
            widget:ClearNode()
        end

        widget.node = previewNode:new(node, self.viewport)
        widget.componentList:SetupNode(node)
        previewDataProvider.Restart()
    end

    function widget:SetNodeScale(scale)
        if widget.node then
            widget.node.rootFrame:SetScale(scale)
        end
    end
    -- widget:SetNodes(nodeDefinitions)
    -- widget:SelectNode(nodeId)
    -- widget:SetEditMode(enabled)
    -- widget:SetPreviewContext(context)
    -- widget:Clear()

    -- widget:Fire("OnFrameSelected", frame)
    -- widget:Fire("OnNodeMoved", node)
    

    -- Required by AceGUI
    widget.OnAcquire = function(self)
        self.frame:Show()
    end

    widget.OnRelease = function(self)
        self.frame:Hide()
        self:ClearNode()
        self.scaleNumber.scaleText:SetText("1")
        self.scaleSlider:SetValue(1)
        self.componentList:ReleaseChildren()
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)