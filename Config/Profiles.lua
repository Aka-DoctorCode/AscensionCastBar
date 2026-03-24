-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Config/Profiles.lua
-- Version: @project-version@
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in
-- derivative works without express written permission.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local AscensionCastBar = addonTable.main or LibStub("AceAddon-3.0"):GetAddon("Ascension Cast Bar")

-- Registry for the Profiles tab
addonTable.tabs = addonTable.tabs or {}
local ProfilesTab = {}

---Rendering function for the Profiles tab
---@param layout table layoutModel object
---@param profile table Reference to self.db.profile
function ProfilesTab:Render(layout, profile)
    local db = AscensionCastBar.db -- Referencia al objeto AceDB

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: ACTIVE PROFILE
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Profile Management" })
    layout:beginSection()
        
        -- Mostrar el perfil actual (Informativo)
        layout:createHeader({ 
            text = "Current Profile: |cff00ff00" .. db:GetCurrentProfile() .. "|r",
            isSubHeader = true 
        })

        -- Selector de Perfil existente
        local profiles = db:GetProfiles()
        local profileList = {}
        for _, name in ipairs(profiles) do
            profileList[name] = name
        end

        layout:createDropdown({
            text = "Switch to Profile",
            values = profileList,
            get = function() return db:GetCurrentProfile() end,
            set = function(val)
                db:SetProfile(val)
                -- Refrescar toda la UI tras el cambio de perfil
                AscensionCastBar:RefreshConfig() 
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: MAINTENANCE (Reset & Copy)
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Maintenance" })
    layout:beginSection()

        -- Botón: Resetear Perfil actual
        layout:createButton({
            text = "Reset Current Profile",
            color = { 0.8, 0.2, 0.2 }, -- Rojo para advertir peligro
            onClick = function()
                StaticPopup_Show("ASCENSION_CASTBAR_RESET_CONFIRM")
            end
        })

        -- Botón: Crear Nuevo Perfil (Usando el prompt de Blizzard)
        layout:createButton({
            text = "Create New Profile",
            onClick = function()
                StaticPopup_Show("ASCENSION_CASTBAR_NEW_PROFILE")
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: INFORMATION
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Addon Info" })
    layout:beginSection()
        layout:createHeader({ text = "Author: Aka-DoctorCode", isSubHeader = true })
        layout:createHeader({ text = "Version: " .. (C_AddOns.GetAddOnMetadata(addonName, "Version") or "4.7"), isSubHeader = true })
        
        layout:createButton({
            text = "Open Advanced Ace3 Profiles",
            onClick = function()
                -- Abre el menú estándar de Ace3 por si necesitan borrar o copiar perfiles específicos
                InterfaceOptionsFrame_OpenToCategory(AscensionCastBar.optionsFrame)
                InterfaceOptionsFrame_OpenToCategory(AscensionCastBar.optionsFrame)
            end
        })
    layout:endSection()
end

-- -------------------------------------------------------------------------------
-- POPUPS DE CONFIRMACIÓN (Seguridad)
-- -------------------------------------------------------------------------------
StaticPopupDialogs["ASCENSION_CASTBAR_RESET_CONFIRM"] = {
    text = "Are you sure you want to reset your current profile? All customizations will be lost.",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = function()
        AscensionCastBar.db:ResetProfile()
        AscensionCastBar:RefreshConfig()
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
            AscensionCastBar:RefreshConfig()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- Registrar la pestaña
addonTable.tabs["profiles"] = ProfilesTab