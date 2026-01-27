--- Framebuilding mapping TrackedData to frames
local modName, env = ...
local PREFIX_FRAME_NAME = modName .. "_Frame:"
FrameBuilder = {}

function FrameBuilder:GenerateFrameName(guid)
    return PREFIX_FRAME_NAME .. guid
end

local function BuildSpellFrames(trackedData)
    local spellInfo = C_Spell.GetSpellInfo(trackedData.sourceID)
    local chargeInfo = C_Spell.GetSpellCharges(trackedData.sourceID)
    local parentFrame = trackedData.parentGuid and FrameBuilder:GenerateFrameName(trackedData.parentGuid) or UIParent
    local visual = trackedData.visual.icon

    local frame = CreateFrame('Frame', FrameBuilder:GenerateFrameName(trackedData.guid), parentFrame, "BackdropTemplate")
    frame:SetPoint(trackedData.position.point, trackedData.position.relativePoint, trackedData.position.offsetX, trackedData.position.offsetY)
    frame:SetSize(visual.size.width, visual.size.height)
    frame.tex = frame:CreateTexture()
    frame.tex:SetAllPoints()
    frame.tex:SetTexture(spellInfo.icon)
    frame:Show()

    local cdFrame = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cdFrame:SetAllPoints(frame)
    cdFrame:SetDrawEdge(false)
    cdFrame:SetDrawSwipe(true)
    cdFrame:SetSwipeColor(0, 0, 0, 0.8)
    cdFrame:SetReverse(false)

    
    local model = {
        guid = trackedData.guid,
        type = trackedData.type,
        frames = {
            main = frame,
            cd = cdFrame
        },
        trackedData = trackedData,
        hasCharges = chargeInfo and chargeInfo.maxCharges > 1,
        spellData = spellInfo,
        internalState = {
            timers = {},
            currentTimerType = nil
        }
    }

    if chargeInfo and chargeInfo.maxCharges > 1 then
        local chargeFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        chargeFrame:SetAllPoints()
        
        local charges = chargeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        charges:SetPoint("CENTER", frame, "BOTTOMRIGHT", -10, 10)
        charges:SetText(tostring(chargeInfo.currentCharges))

        model.frames["chargeMain"] = chargeFrame
        model.frames["chargesText"] = charges
    end

    return model
end

local function BuildItemFrames(trackedData)
    
end

local function BuildAuraFrames(trackedData)
    
end

local TrackedObjectBuilders = {
    [TrackedObjectTypes.Spell] = BuildSpellFrames,
    [TrackedObjectTypes.Item] = BuildItemFrames,
    [TrackedObjectTypes.Aura] = BuildAuraFrames
}

function FrameBuilder:BuildTrackedObject(trackedData)
    return TrackedObjectBuilders[trackedData.type](trackedData)
end

function FrameBuilder:BuildGroup(groupData)
    local frameName = self:GenerateFrameName(groupData.guid)
    local parentFrame = UIParent
    if groupData.parentGuid then
        parentFrame = self:GenerateFrameName(groupData.parentGuid)
    end

    local frame = CreateFrame('Frame', frameName, parentFrame)
    local position = groupData.position

    frame:SetPoint(position.point, position.relativePoint, position.offsetX, position.offsetY)
    return frame
end