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
    -- -------------------------------------------------------------------------------
    -- SECCIÓN: SETUP & TESTING
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Setup & Testing")
    layout:beginSection()
        
        -- Toggle: Enable Test Mode
        layout:checkbox(nil, "Enable Test Mode", nil, 
            function() return profile.previewEnabled end,
            function(val)
                profile.previewEnabled = val
                if not val then profile.testAttached = false end
                AscensionCastBar:ToggleTestMode(val)
                AscensionCastBar:SelectTab("general")
            end
        )

        -- Dropdown: Animation Type
        layout:dropdown(nil, "Animation Type", 
            { ["Cast"] = "Normal Cast", ["Channel"] = "Channel", ["Empowered"] = "Empowered" },
            function() return profile.testModeState end,
            function(val)
                profile.testModeState = val
                if profile.previewEnabled then AscensionCastBar:ToggleTestMode(true) end
            end
        )

        -- Toggle: Hide Blizzard Cast Bar
        layout:checkbox(nil, "Hide Blizzard Cast Bar", nil,
            function() return profile.hideDefaultCastbar end,
            function(val)
                profile.hideDefaultCastbar = val
                AscensionCastBar:UpdateDefaultCastBarVisibility()
            end
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: DIMENSIONS
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Dimensions")
    layout:beginSection()
        
        -- Slider: Width
        layout:slider(nil, "Bar Width", 50, 1000, 1,
            function() return profile.manualWidth end,
            function(val)
                profile.manualWidth = val
                AscensionCastBar:UpdateAnchor()
            end
        )

        -- Slider: Height
        layout:slider(nil, "Bar Height", 10, 150, 1,
            function() return profile.manualHeight end,
            function(val)
                profile.manualHeight = val
                profile.height = val
                AscensionCastBar.castBar:SetHeight(val)
                AscensionCastBar:UpdateSparkSize()
                AscensionCastBar:UpdateIcon()
            end
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: POSITIONING
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Positioning")
    layout:beginSection()

        -- Toggle: Attach to UI Frame
        layout:checkbox(nil, "Attach to UI Frame", nil,
            function() return profile.attachToCDM end,
            function(val)
                profile.attachToCDM = val
                AscensionCastBar:InitCDMHooks()
                AscensionCastBar:UpdateAnchor()
                AscensionCastBar:SelectTab("general")
            end
        )

        if profile.attachToCDM then
            -- Configuración de Anclaje Automático
            layout:dropdown(nil, "Attach Target",
                {
                    ["PlayerFrame"] = "Player Frame",
                    ["PersonalResource"] = "Personal Resource Display",
                    ["Buffs"] = "Tracked Buffs (CDM)",
                    ["Essential"] = "Essential Cooldowns (CDM)",
                },
                function() return profile.cdmTarget end,
                function(val)
                    profile.cdmTarget = val
                    AscensionCastBar:InitCDMHooks()
                    AscensionCastBar:UpdateAnchor()
                end
            )

            layout:slider(nil, "Vertical Offset", -200, 200, 1,
                function() return profile.cdmYOffset end,
                function(val)
                    profile.cdmYOffset = val
                    AscensionCastBar:UpdateAnchor()
                end
            )
        else
            -- Configuración de Anclaje Manual
            layout:slider(nil, "X Offset", -1000, 1000, 1,
                function() return profile.manualX end,
                function(val)
                    profile.manualX = val
                    AscensionCastBar:UpdateAnchor()
                end
            )

            layout:slider(nil, "Y Offset", -1000, 1000, 1,
                function() return profile.manualY end,
                function(val)
                    profile.manualY = val
                    AscensionCastBar:UpdateAnchor()
                end
            )
        end
    layout:endSection()
end

-- Registrar el módulo de la pestaña
addonTable.tabs["general"] = GeneralTab