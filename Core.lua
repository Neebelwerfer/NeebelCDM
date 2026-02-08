NeebelCore = LibStub("AceAddon-3.0"):NewAddon("NeebelCDM", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceSerializer-3.0")
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
            key = 457052,
        }
    }

    premeditationNode.frames = {
        iconDescriptor,
        textDescriptor
    }

    local shadowDanceNode = NodeFactory.CreateIcon()
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

    RuntimeNodeManager:BuildAll({[shadowDanceNode.guid] = shadowDanceNode, [premeditationNode.guid] = premeditationNode})
    self:ScheduleRepeatingTimer("Update", 0.5)

    self:RegisterEvent("UNIT_AURA", "UpdateAuras")
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "UpdateCooldown")
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

TableTest = {}
---comment
---@param event any
---@param unit any
---@param info UnitAuraUpdateInfo
function NeebelCore:UpdateAuras(event, unit, info)
	-- if info.isFullUpdate then
	-- 	print("full update") -- loop over all auras, etc
    --     for i = 1, 40 do
    --         local data = C_UnitAuras.GetAuraDataBySlot(unit, i)
    --         if data then
    --             print(data.name, issecretvalue(data.spellID), issecretvalue(data.auraInstanceID))
    --         end
    --     end
	-- 	return
	-- end
	-- if info.addedAuras then
	-- 	local t = ""
	-- 	for _, v in pairs(info.addedAuras) do
    --         t = t .. format("%d(%s)", v.auraInstanceID, v.name)
    --         print(v.name, issecretvalue(v.spellId), v.spellId)
	-- 	end
	-- 	print(unit, "|cnGREEN_FONT_COLOR:added|r", t)
	-- end
	-- if info.updatedAuraInstanceIDs then
	-- 	local t = ""
	-- 	for _, v in pairs(info.updatedAuraInstanceIDs) do
	-- 		local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, v)
    --         TableTest[aura.spellId] = aura
    --         t = t .. format("%d(%s)", v, aura.name)
	-- 	end
	-- 	print(unit, "|cnYELLOW_FONT_COLOR:updated|r", t)
	-- end
	-- if info.removedAuraInstanceIDs then
	-- 	local t = ""
	-- 	for _, v in pairs(info.removedAuraInstanceIDs) do
	-- 		t = t .. format("%d", v)
	-- 	end
	-- 	print(unit, "|cnRED_FONT_COLOR:removed|r", t)
	-- end

    -- if TableTest[196912] then
    --     print("test")
    -- end
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

function NeebelCore:Update()
    DataContext.UpdateContext()

    RuntimeNodeManager:UpdateNodes()
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