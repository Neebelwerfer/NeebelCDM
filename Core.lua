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

    self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "UpdateCooldown")
    self:RegisterEvent("SPELLS_CHANGED", "SpellChanged")
    self:RegisterEvent("SPELL_UPDATE_CHARGES", "UpdateCharges")
    self:RegisterEvent("UNIT_AURA", "UpdateAuras")
    self:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "SpecChanged")

    local counter = 0
    for k, v in pairs(env.spellLookup) do
        if(k == 185313 or k == 121471) then
            local guid = GenerateGUID()
            local item = TrackedObject.CreateTrackedSpell(guid, k, UIParent, nil)
            item:SetPoint("CENTER", env.baseSize * (1 + counter), 0)
            self.trackedObjects[guid] = item
            counter = counter + 1
        end
    end

    self.db.profile.trackedObjects = self.db.profile.trackedObjects or {}
    local shadowBlades = CreateTrackedSpell(121471)
    local shadowDance = CreateTrackedSpell(185313)

    if shadowBlades then
        self.db.profile.trackedObjects[shadowBlades.guid] = shadowBlades
    end

    if shadowDance then
        self.db.profile.trackedObjects[shadowDance.guid] = shadowDance
    end

    BuildModelGraph(self.db.profile.trackedObjects, self.db.profile.groups)
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
    for k, v in pairs(NeebelCore.trackedObjects) do
        v:Update(DirtyState)
    end
    
    DirtyState = {spellID = {}, auraID = {}}
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