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
    layout:createHeader({ text = "Global Font Settings" })
    layout:beginSection()
        
        -- Selector de Fuente (LSM)
        layout:createDropdown({
            text = "Font Face",
            values = LSM:List("font"),
            get = function() return profile.spellNameFontLSM end,
            set = function(val)
                profile.spellNameFontLSM = val
                profile.timerFontLSM = val
                AscensionCastBar:ApplyFont()
            end
        })

        -- Outline (Borde de fuente)
        layout:createDropdown({
            text = "Font Outline",
            values = { 
                ["NONE"] = "None", 
                ["OUTLINE"] = "Outline", 
                ["THICKOUTLINE"] = "Thick Outline", 
                ["MONOCHROME"] = "Monochrome" 
            },
            get = function() return profile.outline end,
            set = function(val)
                profile.outline = val
                AscensionCastBar:ApplyFont()
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: SPELL NAME (Configuración del nombre del hechizo)
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Spell Name" })
    layout:beginSection()
        
        layout:createToggle({
            text = "Show Name",
            get = function() return profile.showSpellText end,
            set = function(val)
                profile.showSpellText = val
                AscensionCastBar:UpdateTextVisibility()
            end
        })

        layout:createToggle({
            text = "Truncate Name",
            get = function() return profile.truncateSpellName end,
            set = function(val) 
                profile.truncateSpellName = val 
                AscensionCastBar:SelectTab("text") -- Refrescar para mostrar slider de longitud
            end
        })

        if profile.truncateSpellName then
            layout:createSlider({
                text = "Max Characters",
                min = 5, max = 100, step = 1,
                get = function() return profile.truncateLength end,
                set = function(val) profile.truncateLength = val end
            })
        end

        layout:createSlider({
            text = "Size",
            min = 8, max = 32, step = 1,
            get = function() return profile.spellNameFontSize end,
            set = function(val)
                profile.spellNameFontSize = val
                AscensionCastBar:ApplyFont()
            end
        })

        layout:createColorPicker({
            text = "Color",
            get = function() return unpack(profile.fontColor) end,
            set = function(r, g, b, a)
                profile.fontColor = { r, g, b, a }
                AscensionCastBar:ApplyFont()
            end,
            onReset = function()
                profile.fontColor = { unpack(defaults.fontColor) }
                AscensionCastBar:ApplyFont()
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: TIMER (Configuración del tiempo)
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Timer" })
    layout:beginSection()
        
        layout:createToggle({
            text = "Show Timer",
            get = function() return profile.showTimerText end,
            set = function(val) profile.showTimerText = val end
        })

        layout:createToggle({
            text = "Hide on Channel",
            get = function() return profile.hideTimerOnChannel end,
            set = function(val) profile.hideTimerOnChannel = val end
        })

        layout:createDropdown({
            text = "Format",
            values = { ["Remaining"] = "Remaining", ["Duration"] = "Duration", ["Total"] = "Total" },
            get = function() return profile.timerFormat end,
            set = function(val) profile.timerFormat = val end
        })

        layout:createSlider({
            text = "Size",
            min = 8, max = 32, step = 1,
            get = function() return profile.timerFontSize end,
            set = function(val)
                profile.timerFontSize = val
                AscensionCastBar:ApplyFont()
            end
        })

        layout:createToggle({
            text = "Use Shared Color",
            get = function() return profile.useSharedColor end,
            set = function(val)
                profile.useSharedColor = val
                AscensionCastBar:ApplyFont()
                AscensionCastBar:SelectTab("text") -- Ocultar/Mostrar el picker de abajo
            end
        })

        if not profile.useSharedColor then
            layout:createColorPicker({
                text = "Timer Color",
                get = function() return unpack(profile.timerColor) end,
                set = function(r, g, b, a)
                    profile.timerColor = { r, g, b, a }
                    AscensionCastBar:ApplyFont()
                end,
                onReset = function()
                    profile.timerColor = { unpack(defaults.timerColor) }
                    AscensionCastBar:ApplyFont()
                end
            })
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: POSITIONING & BACKDROP
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Positioning & Backdrop" })
    layout:beginSection()

        layout:createToggle({
            text = "Detach Text",
            get = function() return profile.detachText end,
            set = function(val)
                profile.detachText = val
                AscensionCastBar:UpdateTextLayout()
                AscensionCastBar:SelectTab("text")
            end
        })

        if profile.detachText then
            layout:createSlider({
                text = "X Offset",
                min = -200, max = 200, step = 1,
                get = function() return profile.textX end,
                set = function(val)
                    profile.textX = val
                    AscensionCastBar:UpdateTextLayout()
                end
            })

            layout:createSlider({
                text = "Y Offset",
                min = -200, max = 200, step = 1,
                get = function() return profile.textY end,
                set = function(val)
                    profile.textY = val
                    AscensionCastBar:UpdateTextLayout()
                end
            })

            layout:createSlider({
                text = "Text Area Width",
                min = 50, max = 500, step = 1,
                get = function() return profile.textWidth end,
                set = function(val)
                    profile.textWidth = val
                    AscensionCastBar:UpdateTextLayout()
                end
            })
        end

        layout:createToggle({
            text = "Enable Backdrop",
            get = function() return profile.textBackdropEnabled end,
            set = function(val)
                profile.textBackdropEnabled = val
                AscensionCastBar:UpdateTextLayout()
                AscensionCastBar:SelectTab("text")
            end
        })

        if profile.textBackdropEnabled then
            layout:createColorPicker({
                text = "Backdrop Color",
                get = function() return unpack(profile.textBackdropColor) end,
                set = function(r, g, b, a)
                    profile.textBackdropColor = { r, g, b, a }
                    AscensionCastBar:UpdateTextLayout()
                end,
                onReset = function()
                    profile.textBackdropColor = { unpack(defaults.textBackdropColor) }
                    AscensionCastBar:UpdateTextLayout()
                end
            })
        end
    layout:endSection()
end

-- Registrar la pestaña
addonTable.tabs["text"] = TextTab