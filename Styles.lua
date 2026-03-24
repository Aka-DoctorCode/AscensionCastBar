-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Styles.lua
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