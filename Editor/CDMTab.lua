local AceGUI = LibStub("AceGUI-3.0")
CDMTab = {}

function CDMTab.Build(container)

    CDMTab.container = container
    local cdmOptions = BlizzardCDMHandler.GetOptions()
    assert(cdmOptions, "CDM options not found")

    local topGroup = AceGUI:Create("SimpleGroup")
    topGroup:SetFullWidth(true)
    topGroup:SetFullHeight(true)
    topGroup:SetLayout("Flow")
    container:AddChild(topGroup)

    local information = AceGUI:Create("Label")
    information:SetText("Here you can control what you want to disable or keep enabled from the Blizzard Cooldown Manager")
    information:SetFullWidth(true)
    topGroup:AddChild(information)

    local header = AceGUI:Create("Heading")
    header:SetFullWidth(true)
    topGroup:AddChild(header)

    topGroup:AddChild(CDMTab.DisableCheckbox("Disable All", "disableAll", cdmOptions.disableAll, false))

    local generalOptions = AceGUI:Create("InlineGroup")
    generalOptions:SetFullWidth(true)
    generalOptions:SetAutoAdjustHeight(true)
    generalOptions:SetLayout("List")
    generalOptions:SetTitle("General load Options")
    topGroup:AddChild(generalOptions)

    generalOptions:AddChild(CDMTab.DisableCheckbox("Disable Buff Icons", "disableBuffIcons", cdmOptions.disableBuffIcons, cdmOptions.disableAll))
    generalOptions:AddChild(CDMTab.DisableCheckbox("Disable Buff Bars", "disableBuffBars", cdmOptions.disableBuffBars, cdmOptions.disableAll))
    generalOptions:AddChild(CDMTab.DisableCheckbox("Disable Essential Cooldowns", "disableEssentialCooldowns", cdmOptions.disableEssentialCooldowns, cdmOptions.disableAll))
    generalOptions:AddChild(CDMTab.DisableCheckbox("Disable Utility Cooldowns", "disableUtilityCooldowns", cdmOptions.disableUtilityCooldowns, cdmOptions.disableAll))


    --- List of specific buffs/cooldown that should be disabled
    local SpecificOptions = AceGUI:Create("InlineGroup")
    SpecificOptions:SetFullWidth(true)
    SpecificOptions:SetFullHeight(true)
    SpecificOptions:SetLayout("List")
    SpecificOptions:SetTitle("Specific load Options")
    topGroup:AddChild(SpecificOptions)

    local idInput = AceGUI:Create("EditBox")
    idInput:SetLabel("ID")
    idInput:SetDisabled(cdmOptions.disableAll)
    idInput:SetCallback("OnEnterPressed", function(widget, callback, value) CDMTab.AddDisabledID(value)  end)
    SpecificOptions:AddChild(idInput)

    local scanButton = AceGUI:Create("Button")
    scanButton:SetText("Get Ids from CDM")
    scanButton:SetDisabled(cdmOptions.disableAll)
    scanButton:SetCallback("OnClick", function(widget, callback, value) CDMTab.GetAndAddIdsFromCdm()  end)
    SpecificOptions:AddChild(scanButton)

    local disabledIdsContainer = AceGUI:Create("SimpleGroup")
    disabledIdsContainer:SetFullWidth(true)
    disabledIdsContainer:SetLayout("Flow")
    disabledIdsContainer:SetFullHeight(true)
    SpecificOptions:AddChild(disabledIdsContainer)

    for id, _ in pairs(cdmOptions.disabledIds) do
        disabledIdsContainer:AddChild(CDMTab.BuildSpecificId(id))
    end
end

function CDMTab.BuildSpecificId(id)
    local spellInfo = C_Spell.GetSpellInfo(id)
    local idLabel = AceGUI:Create("Label")

    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetRelativeWidth(0.50)
    group:SetHeight(20)
    group:AddChild(idLabel)

    idLabel:SetText(spellInfo.name .. " (" .. id .. ")")
    idLabel:SetImage(spellInfo.iconID or QuestionMark)
    idLabel:SetRelativeWidth(0.33)
    idLabel:SetImageSize(16, 16)
    idLabel:SetHeight(16)

    local removeButton = AceGUI:Create("Button")
    removeButton:SetText("X")
    removeButton:SetWidth(30)
    removeButton:SetHeight(30)
    removeButton:SetCallback("OnClick", function(widget, callback, value) CDMTab.RemoveDisabledID(id)  end)
    group:AddChild(removeButton)

    return group
end


function CDMTab.SetOption(option, value)
    BlizzardCDMHandler.SetDisabled(option, value)
    CDMTab.Refresh()
end


function CDMTab.AddDisabledID(id)
    BlizzardCDMHandler.AddDisabledID(id)
    CDMTab.Refresh()
end

function CDMTab.RemoveDisabledID(id)
    BlizzardCDMHandler.RemoveDisabledID(id)
    CDMTab.Refresh()
end

function CDMTab.GetAndAddIdsFromCdm()
    CDMTab.Refresh()
end

function CDMTab.Refresh()
    CDMTab.container:ReleaseChildren()
    CDMTab.Build(CDMTab.container)
end


function CDMTab.DisableCheckbox(label, option, value, disabled)
    local checkBox = AceGUI:Create("CheckBox")
    checkBox:SetLabel(label)
    checkBox:SetValue(value)
    checkBox:SetDisabled(disabled)
    checkBox:SetCallback("OnValueChanged", function(widget, callback, value) CDMTab.SetOption(option, value)  end)
    return checkBox
end
