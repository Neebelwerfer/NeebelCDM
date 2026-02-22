local addonName, ns = ...

ns.Core   = ns.Core   or {}
ns.Data   = ns.Data   or {}
ns.Nodes  = ns.Nodes  or {}
ns.Frames = ns.Frames or {}
ns.Editor = ns.Editor or {}

ns.Core.ModularCore = LibStub("AceAddon-3.0"):NewAddon("ModularCDM", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceSerializer-3.0")
local ModularCore = ns.Core.ModularCore

local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")


ns.CdManagerCategories = {
    Enum.CooldownViewerCategory.Essential,
    Enum.CooldownViewerCategory.Utility,
    Enum.CooldownViewerCategory.TrackedBar,
    Enum.CooldownViewerCategory.TrackedBuff
}

ns.baseSize = 46



local DirtyState = {spellID = {}, auraID = {}}

function ModularCore:OnInitialize()
    local NodeFactory = ns.Nodes.NodeFactory
    local FrameDescriptionFactory = ns.Frames.FrameDescriptionFactory
    local PropertyFactory = ns.Frames.PropertyFactory

	self.db = LibStub("AceDB-3.0"):New("ModularCDM_DB", self.defaults, true)
    
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	AC:RegisterOptionsTable("ModularCDM_Profiles", profiles)
	ACD:AddToBlizOptions("ModularCDM_Profiles", "ModularCDM")

    self:RegisterChatCommand("ModularCDM", "SlashCommand")
    self:RegisterChatCommand("mcdm", "SlashCommand")


    local dynamicGroup = NodeFactory.CreateDynamicGroup()
    dynamicGroup.guid = "test-dynamic-group-001"
    dynamicGroup.transform.scale = 1
    dynamicGroup.transform.point = "CENTER"
    dynamicGroup.transform.offsetX = -0
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
    textDescriptor.props.text.value = "{Test Aura:stacks}"
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
            type = ns.Core.DataTypes.Aura,
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
    textDescriptor.props.text.value = "{Test Spell:charges.current}:{Test Spell:charges.max}"
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
            type = ns.Core.DataTypes.Spell,
            alias = "Test Spell",
            key = 185313
        }
    }

    local testNode = ns.Nodes.NodeFactory.CreateIcon()
    assert(testNode.layout.dynamic)
    testNode.guid = "test-icon-010"
    testNode.layout.size.width = 48
    testNode.layout.size.height = 48
    testNode.transform.point = "CENTER"
    testNode.transform.offsetX = 10
    testNode.transform.offsetY = -125

    testNode.bindings = {
        {
            type = ns.Core.DataTypes.Spell,
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

    ns.Nodes.RuntimeNodeManager.BuildAll({[dynamicGroup.guid] = dynamicGroup, [premeditationNode.guid] = premeditationNode, [shadowDanceNode.guid] = shadowDanceNode, [testNode.guid] = testNode})
    self:ScheduleRepeatingTimer("Update", 0.2)

    ns.Core.BlizzardCDMHandler.Initialize()
    ns.Data.DataContext.Initialize()
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
    if ns.Editor.EditorManager.IsOpen() then
        ns.Editor.EditorManager.Close()
        return
    end
    ns.Editor.EditorManager.Open()
end

function ModularCore:SpecChanged()
    self:BuildSpellLookup()
end

function ModularCore:Update()
    ns.Data.DataContext.UpdateContext()

    ns.Nodes.RuntimeNodeManager.UpdateNodes()
end