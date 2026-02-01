NeebelCore = LibStub("AceAddon-3.0"):NewAddon("NeebelCDM", "AceConsole-3.0", "AceEvent-3.0")
local addonName, env = ...
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local Timer = LibStub("AceTimer-3.0")
local random = math.random


env.CdManagerCategories = {
    Enum.CooldownViewerCategory.Essential,
    Enum.CooldownViewerCategory.Utility,
    Enum.CooldownViewerCategory.TrackedBar,
    Enum.CooldownViewerCategory.TrackedBuff
}

env.baseSize = 46



local DirtyState = {spellID = {}, auraID = {}}

function NeebelCore:OnInitialize()
	-- Called when the addon is loaded
    local playerLoc = PlayerLocation:CreateFromUnit("player")
    local _, _ , classId = C_PlayerInfo.GetClass(playerLoc)
    NeebelCore.classId = classId
    
    local currentSpecIndex = GetSpecialization()
    if currentSpecIndex then
        local id, currentSpecName =  GetSpecializationInfoForClassID(NeebelCore.classId, currentSpecIndex)
        NeebelCore.specId = id
        NeebelCore.specName = currentSpecName
    else
        return
    end
    
    
    self.pools = CreateFramePoolCollection()
    self.trackedObjects = {}
	self.db = LibStub("AceDB-3.0"):New("NeebelCDM_DB", self.defaults, true)
    self.mainFrame = CreateFrame("Frame", addonName, UIParent)

    self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.options.args.profiles.order = 999
    
	AC:RegisterOptionsTable("NeebelCDM_Options", self.options)
	self.optionsFrame = ACD:AddToBlizOptions("NeebelCDM_Options", "NeebelCDM")
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	AC:RegisterOptionsTable("NeebelCDM_Profiles", profiles)
	ACD:AddToBlizOptions("NeebelCDM_Profiles", "Profiles", "NeebelCDM")

    self:RegisterChatCommand("neebelcdm", "SlashCommand")
    self:RegisterChatCommand("ncdm", "SlashCommand")

    self:BuildSpellLookup()

    local testNode = NodeFactory.CreateIcon()
    testNode.guid = "test-icon-001"
    testNode.layout.size.width = 64
    testNode.layout.size.height = 64
    testNode.transform.point = "CENTER"
    testNode.transform.offsetX = 0
    testNode.transform.offsetY = 0

    -- Add an icon frame descriptor (if not already there by default)
    local iconDescriptor = FrameDescriptionFactory.CreateIconFrame()
    iconDescriptor.props.icon.value = "Interface\\Icons\\Ability_Warrior_Revenge"
    iconDescriptor.layout.size = { width = 64, height = 64 }


    local textDescriptor = FrameDescriptionFactory.CreateTextFrame()
    textDescriptor.props.text.value = "Test"
    textDescriptor.transform.offsetX = 10

    local cooldownDescriptor = FrameDescriptionFactory.CreateCooldownFrame()
    
    
    local barDescriptor = FrameDescriptionFactory.CreateBarFrame()
    barDescriptor.transform.offsetX = 0
    barDescriptor.transform.offsetY = 0
    barDescriptor.layout.size = { width = 256, height = 32 }

    testNode.frames = {
        iconDescriptor,
        textDescriptor,
        cooldownDescriptor,
        barDescriptor
    }

    RuntimeNodeManager:BuildAll({[testNode.guid] = testNode})
    self.trackedObjects[testNode.guid] = testNode


    self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "UpdateCooldown")
    self:RegisterEvent("SPELLS_CHANGED", "SpellChanged")
    self:RegisterEvent("SPELL_UPDATE_CHARGES", "UpdateCharges")
    self:RegisterEvent("UNIT_AURA", "UpdateAuras")
    self:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "SpecChanged")

    Timer:ScheduleRepeatingTimer(OnUpdate, 0.2)
end

function NeebelCore:UpdateCooldown(event, spellId, baseSpellID, category, startRecoveryCategory)
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

function NeebelCore:SpellChanged(event)
    DirtyState["spells"] = true
end

function NeebelCore:UpdateCharges(event)
    DirtyState["charges"] = true
end

function NeebelCore:UpdateAuras(event, unitToken, auraData)
    
end

function NeebelCore:SlashCommand()
    if ACD.OpenFrames["NeebelCDM_Options"] then
        ACD:Close("NeebelCDM_Options")
    else
        ACD:Open("NeebelCDM_Options")
    end
end

function NeebelCore:SpecChanged()
    self:BuildSpellLookup()
end

function OnUpdate()

end


function NeebelCore:BuildSpellLookup()
    local spells = {}
    for i, v in ipairs(env.CdManagerCategories) do
        local categorySet = C_CooldownViewer.GetCooldownViewerCategorySet(v, true)
        if categorySet then
            for i, v in ipairs(categorySet) do
                local spell = CooldownSpell:new(v)
                spells[spell.id] = spell
            end
        end
    end
    env.spellLookup = spells
end

function NeebelCore:OnEnable()
    -- Called when the addon is enabled
end

function NeebelCore:OnDisable()
    -- Called when the addon is disabled
end