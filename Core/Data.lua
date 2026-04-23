-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Data.lua
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

-------------------------------------------------------------------------------
-- CONSTANTS (from Constants.lua)
-------------------------------------------------------------------------------

AscensionCastBar.barDefaultFontPath = "Interface\\AddOns\\AscensionCastBar\\COLLEGIA.ttf"

AscensionCastBar.channelTicks = {
    -- Warrior Spells
    [436358] = 3,         -- Demolish
    -- Warlock Spells
    [234153] = 5,         -- Drain Life
    [198590] = 5,         -- Drain Soul
    [196447] = function() -- Channel Demonfire
        return  C_SpellBook.IsSpellKnown(387166) and 17 or 15
    end,
    -- Mage Spells
    [205021] = 8,                               -- Ray of Frost
    [12051] = 10,                               -- Evocation
    [5143] = function()                         -- Arcane Missiles
        return  C_SpellBook.IsSpellKnown(236628) and 7 or 5 -- Amplification
    end,
    -- Evoker Spells
    [356995] = function()                        -- Disintegrate
        return  C_SpellBook.IsSpellKnown(1219723) and 5 or 4 -- Azure Celerity
    end,
    -- Druid Spells
    [740] = 7,                                        -- Tranquility
    [391528] = function()                             -- Convoke the Spirits
        local hasReducedTicks =  C_SpellBook.IsSpellKnown(393991) -- Elune's Guidance
            or  C_SpellBook.IsSpellKnown(391548)                  -- Ashamane's Guidance
            or  C_SpellBook.IsSpellKnown(393414)                  -- Ursoc's Guidance
            or  C_SpellBook.IsSpellKnown(393371)                  -- Cenarius' Guidance
        if hasReducedTicks then
            return 12
        end
        return 16
    end,
    -- Demon Hunter
    [473728] = 22,                -- Void Ray
    [198013] = 13,                -- Eye Beam
    [212084] = 12,                -- Fel Devastation
    -- Monk
    [113656] = 5,                 -- Fists of Fury
    [115175] = 12,                -- Soothing Mist
    [117952] = 5,                 -- Crackling Jade Lightning
    [322729 or 101546] = 4,       -- Spinning Crane Kick
    [443028] = 5,                 -- Celestial Conduit Mistweaver
    [1238989] = 5,                -- Celestial Conduit Windwalker
    [115294] = function(duration) -- Mana Tea
        local UnitAuras = _G.C_UnitAuras
        if UnitAuras then
            local auraData = UnitAuras.GetAuraDataBySpellIdentifier("player", 115867)
            if auraData and auraData.applications and auraData.applications > 0 then
                return auraData.applications
            end
        end

        if duration and duration > 0 then
            local haste = _G.UnitSpellHaste("player") or 0
            local hasteMult = 1 + (haste / 100)
            local estimatedStacks = (duration * hasteMult) / 0.5
            return math.floor(estimatedStacks + 0.5)
        end
        return 1
    end,
    -- Priest Spells
    [15407] = 6,                                -- Mind Flay
    [391403] = 4,                               -- Mind Flay: Insanity
    [263165] = 5,                               -- Void Torrent
    [64843] = 5,                                -- Divine Hymn
    [47540] = function()                        --Penance
        return  C_SpellBook.IsSpellKnown(193134) and 4 or 3 -- Guiding Light
    end,
    -- Hunter Spells
    [257044] = function()                        -- Rapid Fire
        return  C_SpellBook.IsSpellKnown(459794) and 10 or 7 -- Quick Draw
    end,
    [1261193] = 4,                               -- Boomstick
}

AscensionCastBar.animationStyleParams = {
    Comet = {
        tailOffset = 0,
        headLengthOffset = 0,
        tailLength = 200,
        tails = 4,
    },
    Orb = {
        rotationSpeed = 8,
        radiusMultiplier = 0.4,
        glowPulse = 1.0,
        tails = 4,
    },
    Pulse = {
        maxScale = 2.5,
        rippleCycle = 1,
        fadeSpeed = 1.0,
        tails = 4,
    },
    Starfall = {
        fallSpeed = 2.5,
        swayAmount = 8,
        particleSpeed = 3.8,
        tails = 4,
    },
    Flux = {
        jitterY = 3.5,
        jitterX = 2.5,
        driftMultiplier = 0.05,
        tails = 4,
    },
    Helix = {
        driftMultiplier = 0.1,
        amplitude = 0.4,
        waveSpeed = 8,
        tails = 4,
    },
    Wave = {
        waveCount = 3,
        waveSpeed = 0.4,
        amplitude = 0.05,
        waveWidth = 0.25,
        tails = 0, -- Wave doesn't use traditional tails
    },
    Glitch = {
        glitchChance = 0.1,
        maxOffset = 5,
        colorIntensity = 0.3,
        tails = 0,
    },
    Lightning = {
        lightningChance = 0.3,
        segmentCount = 3,
        tailCount = 0, -- Uses segments instead of tails
    }
}

AscensionCastBar.stageTints = {
    { 0.20, 0.80, 0.20, 0.4 }, -- Stage 1 (green)
    { 0.95, 0.85, 0.20, 0.4 }, -- Stage 2 (yellow)
    { 1.00, 0.55, 0.15, 0.4 }, -- Stage 3 (orange)
    { 1.00, 0.20, 0.20, 0.4 }, -- Stage 4 (red)
    { 0.85, 0.35, 1.00, 0.4 }, -- Stage 5+ (purple)
}

-------------------------------------------------------------------------------
-- DEFAULTS (from Config/Defaults.lua)
-------------------------------------------------------------------------------


AscensionCastBar.defaults = {
    profile = {
        height = 24,
        frameStrata = "MEDIUM",
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
        fontPath = AscensionCastBar.barDefaultFontPath,
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

        -- Feedback Colors
        flashInterrupted = true,
        interruptedColor = { 0.937, 0.266, 0.266, 1.0 },
        failedColor = { 0.5, 0.5, 0.5, 1.0 },
        successColor = { 0.062, 0.725, 0.505, 1.0 },

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

-------------------------------------------------------------------------------
-- STYLES (from Styles.lua)
-------------------------------------------------------------------------------

---@cast AscensionCastBar AscensionCastBar

-------------------------------------------------------------------------------
-- CONSTANTS & COLORS
-------------------------------------------------------------------------------

-- Using a semantic naming convention for better maintenance
AscensionCastBar.colors = {
    -- Brand Colors
    primary           = { 0.498, 0.075, 0.925, 1.0 },  -- #7F13EC (Main Accent)
    gold              = { 1.000, 0.800, 0.200, 1.0 },  -- #FFCC33 (Headers/Titles)
    -- Backgrounds & Surfaces
    backgroundDark    = { 0.020, 0.020, 0.031, 0.95 }, -- #050508 (Main Window)
    surfaceDark       = { 0.047, 0.039, 0.082, 1.0 },  -- #0C0A15 (Cards/Groups)
    surfaceHighlight  = { 0.165, 0.141, 0.239, 1.0 },  -- #2A243D (Hover/Selected)
    -- Utility Details
    blackDetail       = { 0.0, 0.0, 0.0, 1.0 },        -- #000000
    whiteDetail       = { 1.0, 1.0, 1.0, 1.0 },        -- #FFFFFF
    -- Typography
    textLight         = { 0.886, 0.910, 0.941, 1.0 },  -- #E2E8F0 (High Emphasis)
    textDim           = { 0.580, 0.640, 0.720, 1.0 },  -- #94A3B7 (Low Emphasis/Labels)
    -- Sidebar State Colors
    sidebarBg         = { 0.10, 0.10, 0.10, 0.95 },    -- #1A1A1A
    sidebarHover      = { 0.20, 0.20, 0.20, 0.5 },     -- #333333
    sidebarAccent     = { 0.00, 0.48, 1.00, 0.95 },    -- #007AFF
    sidebarActive     = { 0.00, 0.40, 1.00, 0.2 },     -- #0066FF
    -- Semantic UI States (New)
    success           = { 0.062, 0.725, 0.505, 1.0 },  -- #10B981
    warning           = { 0.960, 0.619, 0.043, 1.0 },  -- #F59E0B
    error             = { 0.937, 0.266, 0.266, 1.0 },  -- #EF4444
}

AscensionCastBar.files = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    arrow    = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up",
    close    = "Interface\\Buttons\\UI-Panel-CloseButton",
    maximize = "Interface\\Buttons\\ui-panel-hidebutton-up",
    minimize = "Interface\\Buttons\\ui-panel-hidebutton-disabled",
}

-------------------------------------------------------------------------------
-- UI/UX MESH
-------------------------------------------------------------------------------

AscensionCastBar.menuStyle = {
    -- Frame Layout
    sidebarWidth        = 160,    -- Total width of the left navigation sidebar
    sidebarAccentWidth  = 3,      -- Thickness of the vertical colored strip for the active tab
    contentPadding      = 16,     -- Internal margin between the frame edges and the content
    headerSpacing       = 32,     -- Vertical distance between major category sections
    labelSpacing        = 16,     -- Vertical distance after a standalone text label
    
    -- Title & Typography
    titleTop            = -16,    -- Y-offset for the main addon title at the top-left
    titleLeft           = 16,     -- X-offset for the main addon title at the top-left
    headerFont          = "GameFontNormalHuge",    -- Blizzard font object for main category titles
    labelFont           = "GameFontHighlightLarge", -- Blizzard font object for standard control labels
    descFont            = "GameFontHighlightMedium",      -- Blizzard font object for tooltips or descriptions
    
    -- Sidebar Tabs
    tabWidth            = 144,    -- Horizontal width of each button in the sidebar
    tabHeight           = 30,     -- Vertical height of each button in the sidebar
    tabSpacing          = 6,      -- Vertical gap between consecutive sidebar buttons
    
    -- Interactive Elements
    checkboxSize        = 36,     -- Width and height dimensions for checkbox squares
    checkboxSpacing     = 40,     -- Total vertical space reserved for a checkbox row
    sliderWidth         = 160,    -- Horizontal length of the slider's interactive bar
    sliderSpacing       = 56,     -- Total vertical height for a slider (Label + Bar + EditBox)
    dropdownWidth       = 160,    -- Horizontal length of the dropdown menu button
    dropdownHeight      = 48,     -- Total vertical height allocated for a dropdown component
    colorPickerSize     = 24,     -- Width and height for the color swatch square
    colorPickerSpacing  = 32,     -- Total vertical height reserved for a color picker row
    
    -- Buttons & Inputs
    buttonHeight        = 24,     -- Standard height for utility buttons (e.g., Reset, +/-)
    editBoxHeight       = 28,     -- Standard height for numerical input boxes
    backdropEdgeSize    = 8,      -- Thickness of the frame borders and corners
    
    -- Aesthetic Defaults
    uiHeaderColor       = AscensionCastBar.colors.gold,           -- Default header text color (#FFCC33)
    uiBackgroundColor   = AscensionCastBar.colors.backgroundDark, -- Main window backdrop color (#050508)
    sectionBgColor      = AscensionCastBar.colors.surfaceDark,    -- Background color for "Card" groups (#0C0A15)
}
