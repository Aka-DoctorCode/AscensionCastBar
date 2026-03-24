-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Config/Mechanics.lua
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

-- Registry for the Mechanics tab
addonTable.tabs = addonTable.tabs or {}
local MechanicsTab = {}

---Rendering function for the Mechanics tab
---@param layout table layoutModel object
---@param profile table Reference to self.db.profile
function MechanicsTab:Render(layout, profile)
    local defaults = AscensionCastBar.defaults.profile

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: LATENCY (Lag Bar)
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Latency & Lag" })
    layout:beginSection()
        
        layout:createToggle({
            text = "Show Latency (Lag)",
            get = function() return profile.showLatency end,
            set = function(val)
                profile.showLatency = val
                AscensionCastBar:UpdateLatency()
            end
        })

        layout:createColorPicker({
            text = "Latency Color",
            disabled = function() return not profile.showLatency end,
            get = function() return unpack(profile.latencyColor) end,
            set = function(r, g, b, a)
                profile.latencyColor = { r, g, b, a }
                AscensionCastBar:UpdateLatency()
            end,
            onReset = function()
                profile.latencyColor = { unpack(defaults.latencyColor) }
                AscensionCastBar:UpdateLatency()
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: CHANNELING TICKS (Ticks de hechizos canalizados)
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Channeling Ticks" })
    layout:beginSection()
        
        layout:createToggle({
            text = "Show Ticks",
            get = function() return profile.showChannelTicks end,
            set = function(val)
                profile.showChannelTicks = val
                AscensionCastBar:UpdateTicks()
            end
        })

        layout:createSlider({
            text = "Tick Width",
            min = 1, max = 5, step = 1,
            disabled = function() return not profile.showChannelTicks end,
            get = function() return profile.channelTicksThickness end,
            set = function(val)
                profile.channelTicksThickness = val
                AscensionCastBar:UpdateTicks()
            end
        })

        layout:createColorPicker({
            text = "Tick Color",
            disabled = function() return not profile.showChannelTicks end,
            get = function() return unpack(profile.channelTicksColor or {1,1,1,1}) end,
            set = function(r, g, b, a)
                profile.channelTicksColor = { r, g, b, a }
                AscensionCastBar:UpdateTicks()
            end,
            onReset = function()
                profile.channelTicksColor = { unpack(defaults.channelTicksColor) }
                AscensionCastBar:UpdateTicks()
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: EMPOWERED SPELLS (Niveles de carga)
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Empowered Casts" })
    layout:beginSection()
        
        layout:createToggle({
            text = "Show Stage Dividers",
            get = function() return profile.showEmpowerStages end,
            set = function(val)
                profile.showEmpowerStages = val
                AscensionCastBar:UpdateEmpoweredStages()
            end
        })

        -- Color para el nivel actual alcanzado
        layout:createColorPicker({
            text = "Reached Stage Color",
            get = function() return unpack(profile.empoweredReachedColor) end,
            set = function(r, g, b, a)
                profile.empoweredReachedColor = { r, g, b, a }
            end,
            onReset = function()
                profile.empoweredReachedColor = { unpack(defaults.empoweredReachedColor) }
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: STATUS COLORS (Interrupciones y Fallos)
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Feedback Colors" })
    layout:beginSection()

        layout:createToggle({
            text = "Flash on Interrupted",
            get = function() return profile.flashInterrupted end,
            set = function(val) profile.flashInterrupted = val end
        })

        layout:createColorPicker({
            text = "Interrupted Color",
            get = function() return unpack(profile.interruptedColor) end,
            set = function(r, g, b, a)
                profile.interruptedColor = { r, g, b, a }
            end,
            onReset = function()
                profile.interruptedColor = { unpack(defaults.interruptedColor) }
            end
        })

        layout:createColorPicker({
            text = "Failed/Cancelled Color",
            get = function() return unpack(profile.failedColor) end,
            set = function(r, g, b, a)
                profile.failedColor = { r, g, b, a }
            end,
            onReset = function()
                profile.failedColor = { unpack(defaults.failedColor) }
            end
        })

        layout:createColorPicker({
            text = "Finished Success Color",
            get = function() return unpack(profile.successColor) end,
            set = function(r, g, b, a)
                profile.successColor = { r, g, b, a }
            end,
            onReset = function()
                profile.successColor = { unpack(defaults.successColor) }
            end
        })
    layout:endSection()
end

-- Registrar la pestaña
addonTable.tabs["mechanics"] = MechanicsTab