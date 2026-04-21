-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Config/Text.lua
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
local LSM = LibStub("LibSharedMedia-3.0")

-- Registry for the Text tab
addonTable.tabs = addonTable.tabs or {}
local TextTab = {}

---Rendering function for the Text tab
---@param layout table layoutModel object
---@param profile table Reference to self.db.profile
function TextTab:Render(layout, profile)
    local defaults = AscensionCastBar.defaults.profile

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: GLOBAL FONT SETTINGS
    -- -------------------------------------------------------------------------------
    -- -------------------------------------------------------------------------------
    -- SECCIÓN: GLOBAL FONT SETTINGS
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Global Font Settings")
    layout:beginSection()
        
        -- Selector de Fuente (LSM)
        layout:dropdown(nil, "Font Face", LSM:List("font"),
            function() return profile.spellNameFontLSM end,
            function(val)
                profile.spellNameFontLSM = val
                profile.timerFontLSM = val
                AscensionCastBar:ApplyFont()
            end
        )

        -- Outline (Borde de fuente)
        layout:dropdown(nil, "Font Outline",
            { 
                ["NONE"] = "None", 
                ["OUTLINE"] = "Outline", 
                ["THICKOUTLINE"] = "Thick Outline", 
                ["MONOCHROME"] = "Monochrome" 
            },
            function() return profile.outline end,
            function(val)
                profile.outline = val
                AscensionCastBar:ApplyFont()
            end
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: SPELL NAME (Configuración del nombre del hechizo)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Spell Name")
    layout:beginSection()
        
        layout:checkbox(nil, "Show Name", nil,
            function() return profile.showSpellText end,
            function(val)
                profile.showSpellText = val
                AscensionCastBar:UpdateTextVisibility()
            end
        )

        layout:checkbox(nil, "Truncate Name", nil,
            function() return profile.truncateSpellName end,
            function(val) 
                profile.truncateSpellName = val 
                AscensionCastBar:SelectTab("text")
            end
        )

        if profile.truncateSpellName then
            layout:slider(nil, "Max Characters", 5, 100, 1,
                function() return profile.truncateLength end,
                function(val) profile.truncateLength = val end
            )
        end

        layout:slider(nil, "Size", 8, 32, 1,
            function() return profile.spellNameFontSize end,
            function(val)
                profile.spellNameFontSize = val
                AscensionCastBar:ApplyFont()
            end
        )

        layout:colorPicker(nil, "Color",
            function() return unpack(profile.fontColor) end,
            function(r, g, b, a)
                profile.fontColor = { r, g, b, a }
                AscensionCastBar:ApplyFont()
            end, nil, true
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: TIMER (Configuración del tiempo)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Timer")
    layout:beginSection()
        
        layout:checkbox(nil, "Show Timer", nil,
            function() return profile.showTimerText end,
            function(val) profile.showTimerText = val end
        )

        layout:checkbox(nil, "Hide on Channel", nil,
            function() return profile.hideTimerOnChannel end,
            function(val) profile.hideTimerOnChannel = val end
        )

        layout:dropdown(nil, "Format", { ["Remaining"] = "Remaining", ["Duration"] = "Duration", ["Total"] = "Total" },
            function() return profile.timerFormat end,
            function(val) profile.timerFormat = val end
        )

        layout:slider(nil, "Size", 8, 32, 1,
            function() return profile.timerFontSize end,
            function(val)
                profile.timerFontSize = val
                AscensionCastBar:ApplyFont()
            end
        )

        layout:checkbox(nil, "Use Shared Color", nil,
            function() return profile.useSharedColor end,
            function(val)
                profile.useSharedColor = val
                AscensionCastBar:ApplyFont()
                AscensionCastBar:SelectTab("text")
            end
        )

        if not profile.useSharedColor then
            layout:colorPicker(nil, "Timer Color",
                function() return unpack(profile.timerColor) end,
                function(r, g, b, a)
                    profile.timerColor = { r, g, b, a }
                    AscensionCastBar:ApplyFont()
                end, nil, true
            )
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: POSITIONING & BACKDROP
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Positioning & Backdrop")
    layout:beginSection()

        layout:checkbox(nil, "Detach Text", nil,
            function() return profile.detachText end,
            function(val)
                profile.detachText = val
                AscensionCastBar:UpdateTextLayout()
                AscensionCastBar:SelectTab("text")
            end
        )

        if profile.detachText then
            layout:slider(nil, "X Offset", -200, 200, 1,
                function() return profile.textX end,
                function(val)
                    profile.textX = val
                    AscensionCastBar:UpdateTextLayout()
                end
            )

            layout:slider(nil, "Y Offset", -200, 200, 1,
                function() return profile.textY end,
                function(val)
                    profile.textY = val
                    AscensionCastBar:UpdateTextLayout()
                end
            )

            layout:slider(nil, "Text Area Width", 50, 500, 1,
                function() return profile.textWidth end,
                function(val)
                    profile.textWidth = val
                    AscensionCastBar:UpdateTextLayout()
                end
            )
        end

        layout:checkbox(nil, "Enable Backdrop", nil,
            function() return profile.textBackdropEnabled end,
            function(val)
                profile.textBackdropEnabled = val
                AscensionCastBar:UpdateTextLayout()
                AscensionCastBar:SelectTab("text")
            end
        )

        if profile.textBackdropEnabled then
            layout:colorPicker(nil, "Backdrop Color",
                function() return unpack(profile.textBackdropColor) end,
                function(r, g, b, a)
                    profile.textBackdropColor = { r, g, b, a }
                    AscensionCastBar:UpdateTextLayout()
                end, nil, true
            )
        end
    layout:endSection()
    layout:endSection()
end

-- Registrar la pestaña
addonTable.tabs["text"] = TextTab