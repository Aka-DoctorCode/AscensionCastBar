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
---@type AscensionCastBar
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
                function() return unpack(profile.latencyColor or defaults.latencyColor or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile.latencyColor = { r, g, b, a }
                    AscensionCastBar:UpdateLatency()
                end, nil, true
            )

            layout:slider(nil, "Max Width Percent", 0.01, 1, 0.01,
                function() return profile.latencyMaxPercent or 0.5 end,
                function(val) profile.latencyMaxPercent = val end
            )
            layout:button(nil, "Reset Latency Color", 150, 20, nil, function()
                profile.latencyColor = { unpack(defaults.latencyColor) }
                AscensionCastBar:UpdateLatency()
                AscensionCastBar:SelectTab("mechanics")
            end)
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: CHANNELING TICKS (Ticks de hechizos canalizados)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Channeled Spells")
    layout:beginSection()

        layout:checkbox(nil, "Reverse Channel", "Invierte el progreso de la barra al canalizar (se llena en lugar de vaciarse).",
            function() return profile.reverseChanneling end,
            function(val)
                profile.reverseChanneling = val
                if profile.previewEnabled then AscensionCastBar:ToggleTestMode(true) end
            end
        )
        
        layout:checkbox(nil, "Show Ticks", "Muestra divisiones visuales en los intervalos de daño/sanación de canalizados.",
            function() return profile.showChannelTicks end,
            function(val)
                profile.showChannelTicks = val
                AscensionCastBar:UpdateTicks()
                AscensionCastBar:SelectTab("mechanics")
            end
        )

        if profile.showChannelTicks then
            layout:stepper(nil, "Tick Thickness", 1, 10, 1,
                function() return profile.channelTicksThickness end,
                function(val)
                    profile.channelTicksThickness = val
                    AscensionCastBar:UpdateTicks()
                end
            )

            layout:colorPicker(nil, "Tick Color",
                function() return unpack(profile.channelTicksColor or defaults.channelTicksColor or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile.channelTicksColor = { r, g, b, a }
                    AscensionCastBar:UpdateTicks()
                end, nil, true
            )
            layout:button(nil, "Reset Tick Color", 150, 20, nil, function()
                profile.channelTicksColor = { unpack(defaults.channelTicksColor) }
                AscensionCastBar:UpdateTicks()
                AscensionCastBar:SelectTab("mechanics")
            end)
        end

        layout:checkbox(nil, "Custom Channel Color", "Permite usar un color específico de barra cuando estás canalizando.",
            function() return profile.useChannelColor end,
            function(val)
                profile.useChannelColor = val
                AscensionCastBar:UpdateBarColor()
                AscensionCastBar:SelectTab("mechanics")
            end
        )

        if profile.useChannelColor then
            layout:colorPicker(nil, "Channel Color",
                function() return unpack(profile.channelColor or defaults.channelColor or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile.channelColor = { r, g, b, a }
                    AscensionCastBar:UpdateBarColor()
                end, nil, true
            )
            layout:button(nil, "Reset Channel Color", 150, 20, nil, function()
                profile.channelColor = { unpack(defaults.channelColor) }
                AscensionCastBar:UpdateBarColor()
                AscensionCastBar:SelectTab("mechanics")
            end)
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: EMPOWERED SPELLS (Niveles de carga)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Empowered Casts (Evoker)")
    layout:beginSection()
        
        layout:checkbox(nil, "Scale Bar Width", "Expande horizontalmente la barra a medida que suben los niveles de carga.",
            function() return profile.empowerWidthScale end,
            function(val)
                profile.empowerWidthScale = val
                AscensionCastBar:UpdateBarColor()
            end
        )

        -- Colores para cada nivel
        for i = 1, 5 do
            layout:colorPicker(nil, "Stage " .. i .. " Color",
                function() return unpack(profile["empowerStage" .. i .. "Color"] or defaults["empowerStage" .. i .. "Color"] or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile["empowerStage" .. i .. "Color"] = { r, g, b, a }
                    AscensionCastBar:UpdateBarColor()
                end, nil, true
            )
            layout:button(nil, "Reset Stage " .. i, 120, 20, nil, function()
                profile["empowerStage" .. i .. "Color"] = { unpack(defaults["empowerStage" .. i .. "Color"]) }
                AscensionCastBar:UpdateBarColor()
                AscensionCastBar:SelectTab("mechanics")
            end)
        end

        layout:checkbox(nil, "Show Stage Dividers", "Muestra líneas verticales dividiendo los niveles de carga.",
            function() return profile.showEmpowerStages end,
            function(val)
                profile.showEmpowerStages = val
                AscensionCastBar:UpdateTicks()
            end
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
            function() return unpack(profile.interruptedColor or defaults.interruptedColor or {1,1,1,1}) end,
            function(r, g, b, a)
                profile.interruptedColor = { r, g, b, a }
            end, nil, true
        )
        layout:button(nil, "Reset Interrupted", 150, 20, nil, function()
            profile.interruptedColor = { unpack(defaults.interruptedColor) }
            AscensionCastBar:SelectTab("mechanics")
        end)

        layout:colorPicker(nil, "Failed/Cancelled Color",
            function() return unpack(profile.failedColor or defaults.failedColor or {1,1,1,1}) end,
            function(r, g, b, a)
                profile.failedColor = { r, g, b, a }
            end, nil, true
        )
        layout:button(nil, "Reset Failed", 150, 20, nil, function()
            profile.failedColor = { unpack(defaults.failedColor) }
            AscensionCastBar:SelectTab("mechanics")
        end)

        layout:colorPicker(nil, "Finished Success Color",
            function() return unpack(profile.successColor or defaults.successColor or {1,1,1,1}) end,
            function(r, g, b, a)
                profile.successColor = { r, g, b, a }
            end, nil, true
        )
        layout:button(nil, "Reset Success", 150, 20, nil, function()
            profile.successColor = { unpack(defaults.successColor) }
            AscensionCastBar:SelectTab("mechanics")
        end)
    layout:endSection()
end

-- Registrar la pestaña
addonTable.tabs["mechanics"] = MechanicsTab