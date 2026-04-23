-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: VisualFX.lua
-- Version: @project-version@
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in
-- derivative works without express written permission.
-------------------------------------------------------------------------------


local addonName, addonTable = ...
local ADDON_NAME = "Ascension Cast Bar"
---@class AscensionCastBar
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
if not AscensionCastBar then return end


addonTable.tabs = addonTable.tabs or {}
local VisualFXTab = {}

---@param layout table layoutModel object
---@param profile table Reference to self.db.profile
function VisualFXTab:render(layout, profile)
    if not AscensionCastBar or not AscensionCastBar.defaults then return end
    local defaults = AscensionCastBar.defaults.profile
    if not defaults then return end

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: MAIN STYLE
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Animation Style")
    layout:beginSection()
        
        local styles = {
            { label = "Comet",     value = "Comet" },
            { label = "Orb",       value = "Orb" },
            { label = "Flux",      value = "Flux" },
            { label = "Helix",     value = "Helix" },
            { label = "Pulse",     value = "Pulse" },
            { label = "Starfall",  value = "Starfall" },
            { label = "Wave",      value = "Wave" },
            { label = "Glitch",    value = "Glitch" },
            { label = "Lightning", value = "Lightning" },
        }

        layout:dropdown(nil, "Main Style", nil, styles,
            function() return profile.animStyle end,
            function(val)
                profile.animStyle = val
                if not profile.animationParams[val] then
                    profile.animationParams[val] = CopyTable(AscensionCastBar.animationStyleParams[val])
                end
                AscensionCastBar:selectTab("visualfx")
            end
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: GLOBAL GLOW & OFFSETS
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Global Glow & Offsets")
    layout:beginSection()

        layout:colorPicker(nil, "Global Glow Color",
            function() return unpack(profile.glowColor or defaults.glowColor or {1,1,1,1}) end,
            function(r, g, b, a)
                profile.glowColor = { r, g, b, a }
                AscensionCastBar:updateSparkColors()
            end, nil, true
        )
        layout:button(nil, "Reset Glow Color", 150, 20, nil, function()
            profile.glowColor = { unpack(defaults.glowColor or {1,1,1,1}) }
            AscensionCastBar:updateSparkColors()
            AscensionCastBar:SelectTab("visualfx")
        end)

        layout:slider(nil, "Glow Intensity", 0, 5, 0.1,
            function() return profile.glowIntensity end,
            function(val) profile.glowIntensity = val end
        )

        layout:slider(nil, "Head Offset (Global)", -100, 100, 1,
            function() return profile.headLengthOffset end,
            function(val) profile.headLengthOffset = val end
        )

        layout:slider(nil, "Tail Offset (Global)", -100, 100, 1,
            function() return profile.tailOffset end,
            function(val) profile.tailOffset = val end
        )

        layout:slider(nil, "Tail Length (Global)", 10, 500, 1,
            function() return profile.tailLength end,
            function(val)
                profile.tailLength = val
                profile.tail1Length = val
                profile.tail2Length = val
                profile.tail3Length = val
                profile.tail4Length = val
                AscensionCastBar:updateSparkSize()
            end
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: SPARK SETTINGS
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Spark Settings")
    layout:beginSection()
        
        layout:checkbox(nil, "Enable Spark", nil,
            function() return profile.enableSpark end,
            function(val)
                profile.enableSpark = val
                AscensionCastBar:updateSparkSize()
                AscensionCastBar:SelectTab("visualfx")
            end
        )

        if profile.enableSpark then
            layout:colorPicker(nil, "Spark Head Color",
                function() return unpack(profile.sparkColor or defaults.sparkColor or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile.sparkColor = { r, g, b, a }
                    AscensionCastBar:updateSparkColors()
                end, nil, true
            )
            layout:button(nil, "Reset Spark Color", 150, 20, nil, function()
                profile.sparkColor = { unpack(defaults.sparkColor or {1,1,1,1}) }
                AscensionCastBar:updateSparkColors()
                AscensionCastBar:SelectTab("visualfx")
            end)

            layout:slider(nil, "Spark Intensity", 0, 5, 0.05,
                function() return profile.sparkIntensity end,
                function(val) profile.sparkIntensity = val end
            )

            layout:slider(nil, "Spark Scale", 0.5, 3, 0.1,
                function() return profile.sparkScale end,
                function(val)
                    profile.sparkScale = val
                    AscensionCastBar:updateSparkSize()
                end
            )

            layout:slider(nil, "Spark X Offset", -100, 100, 0.1,
                function() return profile.sparkOffset end,
                function(val) profile.sparkOffset = val end
            )
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: FINE TUNE ANIMATION
    -- -------------------------------------------------------------------------------
    local currentStyle = profile.animStyle
    if currentStyle and currentStyle ~= "Comet" and profile.animationParams[currentStyle] then
        layout:header(nil, "Fine Tune: " .. currentStyle)
        layout:beginSection()
            
            local params = profile.animationParams[currentStyle]

            if currentStyle == "Orb" then
                layout:slider(nil, "Rotation Speed", 1, 20, 1,
                    function() return params.rotationSpeed end,
                    function(val) params.rotationSpeed = val end
                )
                layout:slider(nil, "Orb Radius", 0.1, 1, 0.1,
                    function() return params.radiusMultiplier end,
                    function(val) params.radiusMultiplier = val end
                )
                layout:slider(nil, "Glow Pulse", 0.1, 2, 0.1,
                    function() return params.glowPulse end,
                    function(val) params.glowPulse = val end
                )
            elseif currentStyle == "Pulse" then
                layout:slider(nil, "Max Scale", 1, 5, 0.1,
                    function() return params.maxScale end,
                    function(val) params.maxScale = val end
                )
                layout:slider(nil, "Ripple Cycle", 0.5, 3, 0.1,
                    function() return params.rippleCycle end,
                    function(val) params.rippleCycle = val end
                )
                layout:slider(nil, "Fade Speed", 0.1, 3, 0.1,
                    function() return params.fadeSpeed end,
                    function(val) params.fadeSpeed = val end
                )
            elseif currentStyle == "Starfall" then
                layout:slider(nil, "Fall Speed", 1, 10, 0.5,
                    function() return params.fallSpeed end,
                    function(val) params.fallSpeed = val end
                )
                layout:slider(nil, "Sway Amount", 0, 20, 1,
                    function() return params.swayAmount end,
                    function(val) params.swayAmount = val end
                )
                layout:slider(nil, "Particle Speed", 0.1, 10, 0.1,
                    function() return params.particleSpeed end,
                    function(val) params.particleSpeed = val end
                )
            elseif currentStyle == "Flux" then
                layout:slider(nil, "Vertical Jitter", 1, 10, 0.5,
                    function() return params.jitterY end,
                    function(val) params.jitterY = val end
                )
                layout:slider(nil, "Horizontal Jitter", 1, 10, 0.5,
                    function() return params.jitterX end,
                    function(val) params.jitterX = val end
                )
                layout:slider(nil, "Drift Speed", 0, 1, 0.01,
                    function() return params.driftMultiplier end,
                    function(val) params.driftMultiplier = val end
                )
            elseif currentStyle == "Helix" then
                layout:slider(nil, "Drift Multiplier", 0.01, 0.3, 0.01,
                    function() return params.driftMultiplier end,
                    function(val) params.driftMultiplier = val end
                )
                layout:slider(nil, "Wave Amplitude", 0.1, 1, 0.1,
                    function() return params.amplitude end,
                    function(val) params.amplitude = val end
                )
                layout:slider(nil, "Wave Speed", 1, 20, 1,
                    function() return params.waveSpeed end,
                    function(val) params.waveSpeed = val end
                )
            elseif currentStyle == "Wave" then
                layout:slider(nil, "Wave Count", 1, 10, 1,
                    function() return params.waveCount end,
                    function(val) params.waveCount = val end
                )
                layout:slider(nil, "Wave Speed", 0.1, 2, 0.1,
                    function() return params.waveSpeed end,
                    function(val) params.waveSpeed = val end
                )
                layout:slider(nil, "Amplitude", 0.01, 0.2, 0.01,
                    function() return params.amplitude end,
                    function(val) params.amplitude = val end
                )
                layout:slider(nil, "Width", 0.1, 0.5, 0.05,
                    function() return params.waveWidth end,
                    function(val) params.waveWidth = val end
                )
            elseif currentStyle == "Glitch" then
                layout:slider(nil, "Glitch Intensity", 0.01, 0.5, 0.01,
                    function() return params.glitchChance end,
                    function(val) params.glitchChance = val end
                )
                layout:slider(nil, "Max Glitch Offset", 1, 20, 1,
                    function() return params.maxOffset end,
                    function(val) params.maxOffset = val end
                )
                layout:slider(nil, "Color Intensity", 0, 1, 0.05,
                    function() return params.colorIntensity end,
                    function(val) params.colorIntensity = val end
                )
            elseif currentStyle == "Lightning" then
                layout:slider(nil, "Frequency", 0.1, 1, 0.1,
                    function() return params.lightningChance end,
                    function(val) params.lightningChance = val end
                )
                layout:slider(nil, "Segment Count", 1, 10, 1,
                    function() return params.segmentCount end,
                    function(val) params.segmentCount = val end
                )
            end

        layout:endSection()
    end

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: MOTION TAILS
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Motion Tails")
    layout:beginSection()
        
        layout:checkbox(nil, "Enable Tails", nil,
            function() return profile.enableTails end,
            function(val)
                profile.enableTails = val
                AscensionCastBar:updateSparkColors()
                AscensionCastBar:SelectTab("visualfx")
            end
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIONES DINÁMICAS: Configuración de cada Capa (1 a 4)
    -- -------------------------------------------------------------------------------
    if profile.enableTails then
        for i = 1, 4 do
            layout:header(nil, "Tail Layer " .. i)
            layout:beginSection()

                -- Color de la capa
                layout:colorPicker("TailColor_" .. i, "Color",
                    function() return unpack(profile["tail" .. i .. "Color"] or defaults["tail" .. i .. "Color"] or {1,1,1,1}) end,
                    function(r, g, b, a)
                        profile["tail" .. i .. "Color"] = { r, g, b, a }
                        AscensionCastBar:updateSparkColors()
                    end, nil, true
                )
                layout:button(nil, "Reset Tail " .. i .. " Color", 150, 20, nil, function()
                    profile["tail" .. i .. "Color"] = { unpack(defaults["tail" .. i .. "Color"] or {1,1,1,1}) }
                    AscensionCastBar:updateSparkColors()
                    AscensionCastBar:SelectTab("visualfx")
                end)

                -- Longitud de la estela
                layout:slider("TailLength_" .. i, "Length", 10, 500, 5,
                    function() return profile["tail" .. i .. "Length"] end,
                    function(val)
                        profile["tail" .. i .. "Length"] = val
                        AscensionCastBar:updateSparkSize()
                    end
                )

                -- Intensidad/Opacidad
                layout:slider("TailIntensity_" .. i, "Intensity", 0, 5, 0.05,
                    function() return profile["tail" .. i .. "Intensity"] end,
                    function(val)
                        profile["tail" .. i .. "Intensity"] = val
                        AscensionCastBar:updateSparkColors()
                    end
                )

            layout:endSection()
        end
    end
    -- -------------------------------------------------------------------------------
    -- SECCIÓN: MAINTENANCE
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Maintenance")
    layout:beginSection()
        layout:button(nil, "Reset Animation Defaults", 250, nil, nil, function()
            local currentStyle = profile.animStyle
            if currentStyle and defaults.animationParams[currentStyle] then
                profile.animationParams[currentStyle] = CopyTable(AscensionCastBar.animationStyleParams[currentStyle])
            end

            -- Reset Global Anim Settings
            local keysToReset = {
                "enableSpark", "enableTails", "sparkColor", "glowColor",
                "sparkIntensity", "glowIntensity", "sparkScale", "sparkOffset", "headLengthOffset",
                "tailLength", "tailOffset",
                "tail1Color", "tail1Intensity", "tail1Length",
                "tail2Color", "tail2Intensity", "tail2Length",
                "tail3Color", "tail3Intensity", "tail3Length",
                "tail4Color", "tail4Intensity", "tail4Length",
            }

            for _, key in ipairs(keysToReset) do
                profile[key] = defaults[key]
            end

            AscensionCastBar:updateSparkColors()
            AscensionCastBar:updateSparkSize()
            AscensionCastBar:SelectTab("visualfx")
        end)
    layout:endSection()
end

-- Registrar la pestaña
addonTable.tabs["visualfx"] = VisualFXTab