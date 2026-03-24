-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Config/Defaults.lua
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
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

local BAR_DEFAULT_FONT_PATH = "Interface\\AddOns\\AscensionCastBar\\COLLEGIA.ttf"

AscensionCastBar.defaults = {
    profile = {
        height = 24,
        testAttached = false,

        -- Manual
        manualWidth = 270,
        manualHeight = 24,
        point = "CENTER",
        relativePoint = "CENTER",
        manualX = 0,
        manualY = -85,

        -- Empower Colors
        empowerStage1Color = { 0, 1, 0, 1 },    -- Green
        empowerStage2Color = { 1, 1, 0, 1 },    -- Yellow
        empowerStage3Color = { 1, 0.64, 0, 1 }, -- Orange
        empowerStage4Color = { 1, 0, 0, 1 },    -- Red
        empowerStage5Color = { 0.6, 0, 1, 1 },  -- Purple (Default)
        empowerWidthScale = true,

        -- Channel Ticks
        showChannelTicks = true,
        channelTicksColor = { 1, 1, 1, 0.5 },
        channelTicksThickness = 1,

        -- Channel Colors
        useChannelColor = true,
        channelColor = { 0.5, 0.5, 1, 1 },

        -- Fonts/Text
        spellNameFontSize = 14,
        timerFontSize = 14,
        fontPath = BAR_DEFAULT_FONT_PATH,
        fontColor = { 0.8, 1, 0.95, 1 },
        outlineColor = { 0, 0, 0, 1 },
        outlineThickness = 1,
        showSpellText = true,
        showTimerText = true,
        spellNameFontLSM = "Expressway, Bold",
        timerFontLSM = "Boris Black Bloxx",
        outline = "OUTLINE",
        useSharedColor = true,
        timerColor = { 0.8, 1, 0.95, 1 },
        detachText = false,
        textX = 0,
        textY = 40,
        textWidth = 270,
        textBackdropEnabled = false,
        textBackdropColor = { 0, 0, 0, 0.5 },
        timerFormat = "Remaining",
        truncateSpellName = false,
        truncateLength = 30,

        -- Colors
        barColor = { 0, 0, 0.25, 1 },
        barLSMName = "Solid",
        useClassColor = false,

        -- Anim
        enableSpark = true,
        enableTails = true,
        animStyle = "Comet",
        sparkColor = { 1, 1, 1, 0.9 },
        glowColor = { 1, 1, 1, 1 },
        sparkIntensity = 1,
        glowIntensity = 0.5,
        sparkScale = 3,
        sparkOffset = 0,
        headLengthOffset = 0,

        -- Tail Colors
        tailLength = 200,
        tailOffset = 0,
        tail1Color = { 1, 0, 0, 1 },
        tail1Intensity = 1,
        tail1Length = 95,
        tail2Color = { 0, 1, 1, 1 },
        tail2Intensity = 0.4,
        tail2Length = 215,
        tail3Color = { 0, 1, 0.2, 1 },
        tail3Intensity = 0.6,
        tail3Length = 80,
        tail4Color = { 1, 0, 0.8, 1 },
        tail4Intensity = 0.6,
        tail4Length = 150,

        -- Icon
        showIcon = false,
        detachIcon = false,
        iconAnchor = "Left",
        iconSize = 24,
        iconX = 0,
        iconY = 0,

        -- BG
        bgColor = { 0, 0, 0, 0.65 },
        borderEnabled = true,
        borderColor = { 0, 0, 0, 1 },
        borderThickness = 2,

        -- Behavior
        hideTimerOnChannel = false,
        hideDefaultCastbar = true,
        reverseChanneling = false,
        showLatency = true,
        latencyColor = { 1, 0, 0, 0.5 },
        latencyMaxPercent = 0.5,

        -- CDM
        attachToCDM = false,
        cdmTarget = "PlayerFrame",
        cdmYOffset = -5,
        previewEnabled = false,
        testModeState = "Cast",

        -- Animation Parameters by Style
        animationParams = {
            Comet = {
                tailOffset = 0,
                headLengthOffset = 0,
                tailLength = 200,
            },
            Orb = {
                rotationSpeed = 8,
                radiusMultiplier = 0.4,
                glowPulse = 1.0,
            },
            Pulse = {
                maxScale = 2.5,
                rippleCycle = 1,
                fadeSpeed = 1.0,
            },
            Starfall = {
                fallSpeed = 2.5,
                swayAmount = 8,
                particleSpeed = 3.8,
            },
            Flux = {
                jitterY = 3.5,
                jitterX = 2.5,
                driftMultiplier = 0.05,
            },
            Helix = {
                driftMultiplier = 0.1,
                amplitude = 0.4,
                waveSpeed = 8,
            },
            Wave = {
                waveCount = 3,
                waveSpeed = 0.4,
                amplitude = 0.05,
                waveWidth = 0.25,
            },
            Glitch = {
                glitchChance = 0.1,
                maxOffset = 5,
                colorIntensity = 0.3,
            },
            Lightning = {
                lightningChance = 0.3,
                segmentCount = 3,
            }
        }
    }
}
