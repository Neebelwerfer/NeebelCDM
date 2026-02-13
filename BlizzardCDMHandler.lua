local hook = LibStub("AceHook-3.0")

BlizzardCDMHandler = {
    initialized = false,
    options = nil
}

--- The blizzard CDM frames
--- BuffIconCooldownViewer
--- BuffBarCooldownViewer
--- EssentialCooldownViewer
--- UtilityCooldownViewer

function BlizzardCDMHandler.Initialize()
    if BlizzardCDMHandler.initialized then
        return
    end

    BlizzardCDMHandler.initialized = true

    local options = ModularCore.db.profiles.cdmOptions

    if options == nil then
        options = {
            disableAll = false,
            disableBuffIcons = false,
            disableBuffBars = false,
            disableEssentialCooldowns = false,
            disableUtilityCooldowns = false,
            disabledIds = {}
        }
        ModularCore.db.profiles.cdmOptions = options
    end

    BlizzardCDMHandler.options = options

    hook:SecureHook(BuffIconCooldownViewer, "RefreshLayout", function(self, ...) ---TODO: This seems kind of weak, could break; Works for now
        BlizzardCDMHandler.UpdateVisibility()
    end)
end

---Update the visiblity state of the different Blizzard CDM managers
---Currently the implementation feels a bit hacky. TODO: Research cleaner way?
function BlizzardCDMHandler.UpdateVisibility()
    if not BlizzardCDMHandler.initialized then
        return
    end
    if BlizzardCDMHandler.options.disableAll then
        BuffIconCooldownViewer:Hide()
        BuffBarCooldownViewer:Hide()
        EssentialCooldownViewer:Hide()
        UtilityCooldownViewer:Hide()
    else
        BuffIconCooldownViewer:SetShown(not BlizzardCDMHandler.options.disableBuffIcons)
        BuffBarCooldownViewer:SetShown(not BlizzardCDMHandler.options.disableBuffBars)
        EssentialCooldownViewer:SetShown(not BlizzardCDMHandler.options.disableEssentialCooldowns)
        UtilityCooldownViewer:SetShown(not BlizzardCDMHandler.options.disableUtilityCooldowns)

        -- for _, viewer in pairs({ BuffIconCooldownViewer, BuffBarCooldownViewer, EssentialCooldownViewer, UtilityCooldownViewer }) do
        --     for _, child in pairs(viewer:GetLayoutChildren()) do
        --         local disabled = false
        --         for id, _ in pairs(BlizzardCDMHandler.options.disabledIds) do
        --             local spellID = C_Spell.GetSpellInfo(id).spellID
        --             if child:SpellIDMatchesAnyAssociatedSpellIDs(spellID) then
        --                 child:Hide()
        --                 disabled = true
        --                 break
        --             end
        --         end

        --         if not disabled then
        --             child:Show()
        --         end
        --     end
        -- end
    end
end

---comment
---@param option "disableAll" | "disableBuffIcons" | "disableBuffBars" | "disableEssentialCooldowns" | "disableUtilityCooldowns"
---@param value boolean
function BlizzardCDMHandler.SetDisabled(option, value)
    BlizzardCDMHandler.options[option] = value

    BlizzardCDMHandler.UpdateVisibility()
end

---comment
---@param option "disableAll" | "disableBuffIconsz½" | "disableBuffBars" | "disableEssentialCooldowns" | "disableUtilityCooldowns"
function BlizzardCDMHandler.GetValue(option)
    return BlizzardCDMHandler.options[option]
end

function BlizzardCDMHandler.GetOptions()
    return BlizzardCDMHandler.options
end

function BlizzardCDMHandler.AddDisabledID(id)
    if C_Spell.DoesSpellExist(id) then
        BlizzardCDMHandler.options.disabledIds[id] = true

        BlizzardCDMHandler.UpdateVisibility()
    end
end

function BlizzardCDMHandler.RemoveDisabledID(id)
    BlizzardCDMHandler.options.disabledIds[id] = nil

    BlizzardCDMHandler.UpdateVisibility()
end