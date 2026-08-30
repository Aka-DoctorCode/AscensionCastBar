-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Profiles.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

local addonName, addonTable = ...
local ADDON_NAME = "Ascension Cast Bar"
---@class AscensionCastBar
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
if not AscensionCastBar then return end

-- Registry for the Profiles tab
addonTable.tabs = addonTable.tabs or {}
local ProfilesTab = {}

---Rendering function for the Profiles tab
function ProfilesTab:render(layout, profile)
    local db = AscensionCastBar.db

    -- -------------------------------------------------------------------------------
    -- SECTION: ACTIVE PROFILE
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Profile Management")
    layout:header(nil, "Current Profile: |cff00ff00" .. db:GetCurrentProfile() .. "|r")
    layout:beginSection()

        -- Existing profiles selector
        local profiles = db:GetProfiles()
        local profileList = {}
        for _, name in ipairs(profiles) do
            table.insert(profileList, { label = name, value = name })
        end

        layout:dropdown(nil, "Switch to Profile", nil, profileList,
            function() return db:GetCurrentProfile() end,
            function(val)
                db:SetProfile(val)
                AscensionCastBar:refreshConfig()
                AscensionCastBar:selectTab("profiles")
            end
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: MAINTENANCE (Reset & Copy)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Maintenance")
    layout:beginSection()

        layout:button(nil, "Reset Current Profile", "", 200, 24, nil, function()
            StaticPopup_Show("ASCENSION_CASTBAR_RESET_CONFIRM")
        end)

        layout:button(nil, "Create New Profile", "", 200, 24, nil, function()
            StaticPopup_Show("ASCENSION_CASTBAR_NEW_PROFILE")
        end)
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: INFORMATION
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Addon Info")
    layout:header(nil, "Author: Aka-DoctorCode")
    layout:header(nil, "Version: " .. (C_AddOns.GetAddOnMetadata(addonName, "Version") or "4.7"))
    layout:beginSection()
        
        layout:button(nil, "Open Advanced Ace3 Profiles", "", 240, 24, nil, function()
            if AscensionCastBar and AscensionCastBar.optionsFrame then
                local opt = AscensionCastBar.optionsFrame
                if Settings and Settings.OpenToCategory then
                    local catID = (opt.GetID and opt:GetID()) or opt.ID or opt.name
                    pcall(Settings.OpenToCategory, catID)
                elseif _G["InterfaceOptionsFrame_OpenToCategory"] then
                    pcall(_G["InterfaceOptionsFrame_OpenToCategory"], opt)
                end
            end
        end)
    layout:endSection()
end

-- -------------------------------------------------------------------------------
-- CONFIRMATION POPUPS
-- -------------------------------------------------------------------------------
StaticPopupDialogs["ASCENSION_CASTBAR_RESET_CONFIRM"] = {
    text = "Are you sure you want to reset your current profile? All customizations will be lost.",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = function()
        AscensionCastBar.db:ResetProfile()
        AscensionCastBar:refreshConfig()
        if AscensionCastBar.selectTab then AscensionCastBar:selectTab("profiles") end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["ASCENSION_CASTBAR_NEW_PROFILE"] = {
    text = "Enter a name for the new profile:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function(self)
        local name = self.editBox:GetText()
        if name and name ~= "" then
            AscensionCastBar.db:SetProfile(name)
            AscensionCastBar:refreshConfig()
            if AscensionCastBar.selectTab then AscensionCastBar:selectTab("profiles") end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- Register tab
addonTable.tabs["profiles"] = ProfilesTab