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
    canvas:SetPoint("CENTER", frame, "CENTER", 0, 0)
    widget.canvas = canvas

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


local function ButtonReset(_, frame)
    frame:ClearAllPoints()
    frame:SetParent(nil)
    frame:Hide()

    frame:SetScript("OnMouseUp", nil)
end

local function ButtonInit(frame)
    frame.text =  frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1, 1)
    end)
    frame:SetScript("OnLeave", function(self)
        self.text:SetTextColor(1, 1, 1, 0.8)
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 1
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
end

local buttonPool = CreateFramePool("Frame", nil, "BackdropTemplate", ButtonReset, nil, ButtonInit)

local function CreatePropertyButton(parent)

    local button = buttonPool:Acquire()
    button:SetParent(parent)
    button:SetHeight(20)

    button.SetText = function(self, text)
        self.text:SetText(text)
    end

    button:Show()
    return button
end

local function DestroyPropertyButton(button)
    buttonPool:Release(button)
end

local function BuildPropertyList(frame)
    local propertyList = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    propertyList:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",

    })

    propertyList:SetBackdropColor(0, 0, 0, 0.8)
    
    propertyList.buttons = {}
    propertyList.Destroy = function (self)
        for _, button in pairs(self.buttons) do
            DestroyPropertyButton(button)
        end
        table.wipe(self.buttons)
    end

    propertyList.SetupNode = function (self, node)
        for i, frameDescriptor in ipairs(node.frames) do
            local offset = 10 + (i - 1) * 19

            local button = CreatePropertyButton(self)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -offset)
            button:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, -offset)
            button:SetText(frameDescriptor.name)
            table.insert(self.buttons, button)
        end

        local button = CreatePropertyButton(self)
        button:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -10 - (#self.buttons) * 19)
        button:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, -10 - (#self.buttons) * 19)
        button:SetText("Add Component")
        table.insert(self.buttons, button)
    end



    

    return propertyList
end


local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:EnableMouse(true)

    local widget = {
        type = Type,
        frame = frame,
    }
    
    BuildCanvas(widget, frame)
    local propertyList = BuildPropertyList(frame)
    widget.propertyList = propertyList


    function widget:SetWidth(width)
        self.frame:SetWidth(width)
        self.canvas:SetWidth(width * 0.70)
        self.canvas:SetPoint("CENTER", self.frame, "CENTER", -width * 0.35 * 0.5 + 10, 0) --TODO: I dont like this. should be cleaned up.

        self.propertyList:SetWidth(width * 0.3)
        self.propertyList:SetPoint("CENTER", self.frame, "CENTER", width * 0.35, 0)
        
    end

    function widget:SetHeight(height)
        self.frame:SetHeight(height)
        self.canvas:SetHeight(height)
        self.propertyList:SetHeight(height)
    end

    function widget:ClearNode()
        if not widget.node then return end
        widget.node:Destroy()
        widget.propertyList:Destroy()
        widget.node = nil
    end

    function widget:SetNode(node)
        if widget.node then
            widget:ClearNode()
        end
        widget.node = previewNode:new(node, self.canvas)
        widget.propertyList:SetupNode(node)
        previewDataProvider.Restart()
    end

    function widget:SetNodeScale(scale)
        if widget.node then
            widget.node.rootFrame:SetScale(scale)
        end
    end

    function widget:OnWidthSet(width)
        self.frame:SetWidth(width)
    end

    function widget:OnHeightSet(height)
        self.frame:SetHeight(height)
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
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)