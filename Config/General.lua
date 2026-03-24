-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Config/General.lua
-- Version: @project-version@
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in
-- derivative works without express written permission.
-------------------------------------------------------------------------------


local addonName, addonTable = ...
---@class AscensionCastBar
local AscensionCastBar = addonTable.main or LibStub("AceAddon-3.0"):GetAddon("Ascension Cast Bar")

-- Registry for the General tab in the modular system
addonTable.tabs = addonTable.tabs or {}
local GeneralTab = {}

---Main rendering function for the General tab
---@param layout table The layoutModel instance defined in Config.lua
---@param profile table Reference to self.db.profile
function GeneralTab:Render(layout, profile)
    
    -- -------------------------------------------------------------------------------
    -- SECCIÓN: SETUP & TESTING
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Setup & Testing" })
    layout:beginSection()
        
        -- Toggle: Enable Test Mode
        layout:createToggle({
            text = "Enable Test Mode",
            get = function() return profile.previewEnabled end,
            set = function(val)
                profile.previewEnabled = val
                if not val then profile.testAttached = false end
                AscensionCastBar:ToggleTestMode(val)
            end
        })

        -- Dropdown: Animation Type (Only if test mode is enabled)
        layout:createDropdown({
            text = "Animation Type",
            values = { ["Cast"] = "Normal Cast", ["Channel"] = "Channel", ["Empowered"] = "Empowered" },
            disabled = function() return not profile.previewEnabled end,
            get = function() return profile.testModeState end,
            set = function(val)
                profile.testModeState = val
                if profile.previewEnabled then AscensionCastBar:ToggleTestMode(true) end
            end
        })

        -- Toggle: Hide Blizzard Cast Bar
        layout:createToggle({
            text = "Hide Blizzard Cast Bar",
            get = function() return profile.hideDefaultCastbar end,
            set = function(val)
                profile.hideDefaultCastbar = val
                AscensionCastBar:UpdateDefaultCastBarVisibility()
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: DIMENSIONS
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Dimensions" })
    layout:beginSection()
        
        -- Slider: Width
        layout:createSlider({
            text = "Bar Width",
            min = 50, max = 1000, step = 1,
            get = function() return profile.manualWidth end,
            set = function(val)
                profile.manualWidth = val
                AscensionCastBar:UpdateAnchor()
            end
        })

        -- Slider: Height
        layout:createSlider({
            text = "Bar Height",
            min = 10, max = 150, step = 1,
            get = function() return profile.manualHeight end,
            set = function(val)
                profile.manualHeight = val
                profile.height = val -- Sincronización con el valor de escala
                AscensionCastBar.castBar:SetHeight(val)
                AscensionCastBar:UpdateSparkSize()
                AscensionCastBar:UpdateIcon()
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: POSITIONING
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Positioning" })
    layout:beginSection()

        -- Toggle: Attach to UI Frame
        layout:createToggle({
            text = "Attach to UI Frame",
            get = function() return profile.attachToCDM end,
            set = function(val)
                profile.attachToCDM = val
                AscensionCastBar:InitCDMHooks()
                AscensionCastBar:UpdateAnchor()
                -- Force refresh the tab to show/hide coordinates
                AscensionCastBar:SelectTab("general")
            end
        })

        if profile.attachToCDM then
            -- Configuración de Anclaje Automático
            layout:createDropdown({
                text = "Attach Target",
                values = {
                    ["PlayerFrame"] = "Player Frame",
                    ["PersonalResource"] = "Personal Resource Display",
                    ["Buffs"] = "Tracked Buffs (CDM)",
                    ["Essential"] = "Essential Cooldowns (CDM)",
                },
                get = function() return profile.cdmTarget end,
                set = function(val)
                    profile.cdmTarget = val
                    AscensionCastBar:InitCDMHooks()
                    AscensionCastBar:UpdateAnchor()
                end
            })

            layout:createSlider({
                text = "Vertical Offset",
                min = -200, max = 200, step = 1,
                get = function() return profile.cdmYOffset end,
                set = function(val)
                    profile.cdmYOffset = val
                    AscensionCastBar:UpdateAnchor()
                end
            })
        else
            -- Configuración de Anclaje Manual
            layout:createSlider({
                text = "X Offset",
                min = -1000, max = 1000, step = 1,
                get = function() return profile.manualX end,
                set = function(val)
                    profile.manualX = val
                    AscensionCastBar:UpdateAnchor()
                end
            })

            layout:createSlider({
                text = "Y Offset",
                min = -1000, max = 1000, step = 1,
                get = function() return profile.manualY end,
                set = function(val)
                    profile.manualY = val
                    AscensionCastBar:UpdateAnchor()
                end
            })
        end
    layout:endSection()
end

-- Registrar el módulo de la pestaña
addonTable.tabs["general"] = GeneralTab