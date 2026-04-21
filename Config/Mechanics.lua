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
    -- -------------------------------------------------------------------------------
    -- SECCIÓN: LATENCY (Lag Bar)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Latency & Lag")
    layout:beginSection()
        
        layout:checkbox(nil, "Show Latency (Lag)", nil,
            function() return profile.showLatency end,
            function(val)
                profile.showLatency = val
                AscensionCastBar:UpdateLatency()
                AscensionCastBar:SelectTab("mechanics")
            end
        )

        if profile.showLatency then
            layout:colorPicker(nil, "Latency Color",
                function() return unpack(profile.latencyColor) end,
                function(r, g, b, a)
                    profile.latencyColor = { r, g, b, a }
                    AscensionCastBar:UpdateLatency()
                end, nil, true
            )
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: CHANNELING TICKS (Ticks de hechizos canalizados)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Channeling Ticks")
    layout:beginSection()
        
        layout:checkbox(nil, "Show Ticks", nil,
            function() return profile.showChannelTicks end,
            function(val)
                profile.showChannelTicks = val
                AscensionCastBar:UpdateTicks()
                AscensionCastBar:SelectTab("mechanics")
            end
        )

        if profile.showChannelTicks then
            layout:slider(nil, "Tick Width", 1, 5, 1,
                function() return profile.channelTicksThickness end,
                function(val)
                    profile.channelTicksThickness = val
                    AscensionCastBar:UpdateTicks()
                end
            )

            layout:colorPicker(nil, "Tick Color",
                function() return unpack(profile.channelTicksColor or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile.channelTicksColor = { r, g, b, a }
                    AscensionCastBar:UpdateTicks()
                end, nil, true
            )
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: EMPOWERED SPELLS (Niveles de carga)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Empowered Casts")
    layout:beginSection()
        
        layout:checkbox(nil, "Show Stage Dividers", nil,
            function() return profile.showEmpowerStages end,
            function(val)
                profile.showEmpowerStages = val
                AscensionCastBar:UpdateEmpoweredStages()
            end
        )

        -- Color para el nivel actual alcanzado
        layout:colorPicker(nil, "Reached Stage Color",
            function() return unpack(profile.empoweredReachedColor) end,
            function(r, g, b, a)
                profile.empoweredReachedColor = { r, g, b, a }
            end, nil, true
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: STATUS COLORS (Interrupciones y Fallos)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Feedback Colors")
    layout:beginSection()

        layout:checkbox(nil, "Flash on Interrupted", nil,
            function() return profile.flashInterrupted end,
            function(val) profile.flashInterrupted = val end
        )

        layout:colorPicker(nil, "Interrupted Color",
            function() return unpack(profile.interruptedColor) end,
            function(r, g, b, a)
                profile.interruptedColor = { r, g, b, a }
            end, nil, true
        )

        layout:colorPicker(nil, "Failed/Cancelled Color",
            function() return unpack(profile.failedColor) end,
            function(r, g, b, a)
                profile.failedColor = { r, g, b, a }
            end, nil, true
        )

        layout:colorPicker(nil, "Finished Success Color",
            function() return unpack(profile.successColor) end,
            function(r, g, b, a)
                profile.successColor = { r, g, b, a }
            end, nil, true
        )
    layout:endSection()
end

-- Registrar la pestaña
addonTable.tabs["mechanics"] = MechanicsTab