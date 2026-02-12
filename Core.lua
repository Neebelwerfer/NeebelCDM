ModularCore = LibStub("AceAddon-3.0"):NewAddon("ModularCDM", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceSerializer-3.0")
local addonName, env = ...
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")



env.CdManagerCategories = {
    Enum.CooldownViewerCategory.Essential,
    Enum.CooldownViewerCategory.Utility,
    Enum.CooldownViewerCategory.TrackedBar,
    Enum.CooldownViewerCategory.TrackedBuff
}

env.baseSize = 46



local DirtyState = {spellID = {}, auraID = {}}

function ModularCore:OnInitialize()
	-- Called when the addon is loaded
    -- local playerLoc = PlayerLocation:CreateFromUnit("player")
    -- local _, _ , classId = C_PlayerInfo.GetClass(playerLoc)
    -- ModularCore.classId = classId
    
    -- local currentSpecIndex = GetSpecialization()
    -- if currentSpecIndex then
    --     local id, currentSpecName =  GetSpecializationInfoForClassID(ModularCore.classId, currentSpecIndex)
    --     ModularCore.specId = id
    --     ModularCore.specName = currentSpecName
    -- else
    --     return
    -- end
    
    
	self.db = LibStub("AceDB-3.0"):New("ModularCDM_DB", self.defaults, true)
    self.mainFrame = CreateFrame("Frame", addonName, UIParent)

    self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.options.args.profiles.order = 999
    
	AC:RegisterOptionsTable("ModularCDM_Options", self.options)
	self.optionsFrame = ACD:AddToBlizOptions("ModularCDM_Options", "ModularCDM")
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	AC:RegisterOptionsTable("ModularCDM_Profiles", profiles)
	ACD:AddToBlizOptions("ModularCDM_Profiles", "Profiles", "ModularCDM")

    self:RegisterChatCommand("ModularCDM", "SlashCommand")
    self:RegisterChatCommand("ncdm", "SlashCommand")


    local dynamicGroup = NodeFactory.CreateDynamicGroup()
    dynamicGroup.guid = "test-dynamic-group-001"
    dynamicGroup.transform.scale = 1
    dynamicGroup.transform.point = "CENTER"
    dynamicGroup.transform.offsetX = 0
    dynamicGroup.transform.offsetY = 0

    local premeditationNode = NodeFactory.CreateIcon()
    premeditationNode.guid = "test-icon-002"
    premeditationNode.layout.size.width = 48
    premeditationNode.layout.size.height = 48
    premeditationNode.transform.point = "CENTER"
    premeditationNode.transform.offsetX = -0
    premeditationNode.transform.offsetY = -0

    local iconDescriptor = FrameDescriptionFactory.CreateIconFrame()
    iconDescriptor.props.icon.resolveType = "binding"
    iconDescriptor.props.icon.value = {binding = "Test Aura", field = "icon"}

    local textDescriptor = FrameDescriptionFactory.CreateTextFrame()
    textDescriptor.props.text.resolveType = "binding"
    textDescriptor.props.text.value = {binding = "Test Aura", field = "stacks"}
    textDescriptor.transform.offsetX = 13
    textDescriptor.transform.offsetY = -13
    textDescriptor.props.fontSize.value = 15

    local stackCooldown = PropertyFactory.DefaultCooldownProperties()
    stackCooldown.cooldown.resolveType = "binding"
    stackCooldown.cooldown.value = {binding = "Test Aura", field = "duration"}
    stackCooldown.reverse.value = true

    iconDescriptor.props.cooldowns = {
        stackCooldown
    }

    premeditationNode.bindings = {
        {
            type = DataTypes.Aura,
            alias = "Test Aura",
            key = 196912,
        }
    }

    premeditationNode.frames = {
        iconDescriptor,
        textDescriptor
    }

    local shadowDanceNode = NodeFactory.CreateIcon()
    assert(shadowDanceNode.layout.dynamic)
    shadowDanceNode.guid = "test-icon-001"
    shadowDanceNode.layout.size.width = 48
    shadowDanceNode.layout.size.height = 48
    shadowDanceNode.transform.point = "CENTER"
    shadowDanceNode.transform.offsetX = 10
    shadowDanceNode.transform.offsetY = -125


    -- Add an icon frame descriptor (if not already there by default)
    local iconDescriptor = FrameDescriptionFactory.CreateIconFrame()
    iconDescriptor.props.icon.resolveType = "binding"
    iconDescriptor.props.icon.value = {binding = "Test Spell", field = "icon"}

    local textDescriptor = FrameDescriptionFactory.CreateTextFrame()
    textDescriptor.props.text.resolveType = "binding"
    textDescriptor.props.text.value = {binding = "Test Spell", field = "charges.current"}
    textDescriptor.transform.offsetX = 13
    textDescriptor.transform.offsetY = -13
    textDescriptor.props.fontSize.value = 15

    local chargeCooldown = PropertyFactory.DefaultCooldownProperties()
    chargeCooldown.cooldown.resolveType = "binding"
    chargeCooldown.cooldown.value = {binding = "Test Spell", field = "charges.cooldown"}
    chargeCooldown.swipe.enabled.value = false
    chargeCooldown.edge.enabled.value = true
    chargeCooldown.hideCountdown.value = true

    local cooldownDescriptor = PropertyFactory.DefaultCooldownProperties()
    cooldownDescriptor.cooldown.resolveType = "binding"
    cooldownDescriptor.cooldown.value = {binding = "Test Spell", field = "cooldown"}
    cooldownDescriptor.swipe.enabled.value = true
    cooldownDescriptor.edge.enabled.value = false

    iconDescriptor.props.cooldowns = {
        chargeCooldown,
        cooldownDescriptor
    }

    shadowDanceNode.frames = {
        iconDescriptor,
        textDescriptor,
    }

    shadowDanceNode.bindings = {
        {
            type = DataTypes.Spell,
            alias = "Test Spell",
            key = 185313
        }
    }

    local testNode = NodeFactory.CreateIcon()
    assert(testNode.layout.dynamic)
    testNode.guid = "test-icon-010"
    testNode.layout.size.width = 48
    testNode.layout.size.height = 48
    testNode.transform.point = "CENTER"
    testNode.transform.offsetX = 10
    testNode.transform.offsetY = -125

    testNode.bindings = {
        {
            type = DataTypes.Spell,
            alias = "Test Spell",
            key = 185313
        }
    }

    -- Add an icon frame descriptor (if not already there by default)
    local iconDescriptor = FrameDescriptionFactory.CreateIconFrame()
    iconDescriptor.props.icon.resolveType = "binding"
    iconDescriptor.props.icon.value = {binding = "Test Spell", field = "icon"}

    testNode.frames = {
        iconDescriptor
    }

    dynamicGroup.children = {
        shadowDanceNode.guid,
        premeditationNode.guid,
        testNode.guid
    }

    shadowDanceNode.parentGuid = dynamicGroup.guid
    premeditationNode.parentGuid = dynamicGroup.guid
    testNode.parentGuid = dynamicGroup.guid

    RuntimeNodeManager.BuildAll({[dynamicGroup.guid] = dynamicGroup, [premeditationNode.guid] = premeditationNode, [shadowDanceNode.guid] = shadowDanceNode, [testNode.guid] = testNode})
    self:ScheduleRepeatingTimer("Update", 0.2)

    -- self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "UpdateCooldown")
    DataContext.Initialize()
end


function ModularCore:UpdateCooldown(event, spellId, baseSpellID, category, startRecoveryCategory)
    if spellId == nil and baseSpellID == nil then
        return
    end

    if spellId then
        DirtyState["spellID"][spellId] = true
    end

    if baseSpellID then
        DirtyState["spellID"][baseSpellID] = true
    end
end

function ModularCore:SpellChanged(event)
    DirtyState["spells"] = true
end

function ModularCore:UpdateCharges(event)
    DirtyState["charges"] = true
end

function ModularCore:SlashCommand()
    if ACD.OpenFrames["ModularCDM_Options"] then
        ACD:Close("ModularCDM_Options")
    else
        ACD:Open("ModularCDM_Options")
    end
end

function ModularCore:SpecChanged()
    self:BuildSpellLookup()
end

function ModularCore:Update()
    DataContext.UpdateContext()

    RuntimeNodeManager.UpdateNodes()
end

function ModularCore:OnEnable()
    -- Called when the addon is enabled
end

function ModularCore:OnDisable()
    -- Called when the addon is disabled
end