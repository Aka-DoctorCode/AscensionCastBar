-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Text.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field


local addonName, addonTable = ...
local ADDON_NAME = "Ascension Cast Bar"
---@class AscensionCastBar
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
if not AscensionCastBar then return end
local LSM = LibStub("LibSharedMedia-3.0")

-- Registry for the Text tab
addonTable.tabs = addonTable.tabs or {}
local TextTab = {}

---Rendering function for the Text tab
function TextTab:render(layout, profile)
    if not AscensionCastBar or not AscensionCastBar.defaults then return end
    local defaults = AscensionCastBar.defaults.profile
    if not defaults then return end

    -- -------------------------------------------------------------------------------
    -- SECTION: GLOBAL FONT SETTINGS
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Global Font Settings")
    layout:beginSection()
        
        -- Font Face (LSM)
        local fonts = {}
        for _, name in ipairs(LSM:List("font")) do
            table.insert(fonts, { label = name, value = name })
        end
        layout:dropdown(nil, "Font Face", nil, fonts,
            function() return profile.spellNameFontLSM end,
            function(val)
                profile.spellNameFontLSM = val
                profile.timerFontLSM = val
                AscensionCastBar:applyFont()
            end
        )

        -- Font Outline / Shadow
        layout:dropdown(nil, "Font Outline", nil,
            { 
                { label = "None",             value = "NONE" }, 
                { label = "Outline",          value = "OUTLINE" }, 
                { label = "Thick Outline",    value = "THICKOUTLINE" }, 
                { label = "Shadow",           value = "SHADOW" },
                { label = "Outline + Shadow", value = "OUTLINESHADOW" },
                { label = "Monochrome",       value = "MONOCHROME" } 
            },
            function() return profile.outline end,
            function(val)
                local oldOutline = profile.outline
                profile.outline = val
                AscensionCastBar:applyFont()
                local wasShadow = (oldOutline == "SHADOW" or oldOutline == "OUTLINESHADOW")
                local isShadow = (val == "SHADOW" or val == "OUTLINESHADOW")
                if wasShadow ~= isShadow then
                    AscensionCastBar:selectTab("text")
                end
            end
        )

        if profile.outline == "SHADOW" or profile.outline == "OUTLINESHADOW" then
            layout:stepper(nil, "Shadow Thickness", 1, 10, 1,
                function() return profile.shadowThickness end,
                function(val)
                    profile.shadowThickness = val
                    AscensionCastBar:applyFont()
                end
            )

            layout:stepper(nil, "Shadow Offset X", -10, 10, 1,
                function() return profile.shadowOffsetX end,
                function(val)
                    profile.shadowOffsetX = val
                    AscensionCastBar:applyFont()
                end
            )

            layout:stepper(nil, "Shadow Offset Y", -10, 10, 1,
                function() return profile.shadowOffsetY end,
                function(val)
                    profile.shadowOffsetY = val
                    AscensionCastBar:applyFont()
                end
            )

            layout:colorPicker(nil, "Shadow Color", nil,
                function() return unpack(profile.shadowColor or defaults.shadowColor or {0,0,0,1}) end,
                function(r, g, b, a)
                    profile.shadowColor = { r, g, b, a }
                    AscensionCastBar:applyFont()
                end
            )

            layout:button(nil, "Reset Shadow Color", "", 140, 24, nil, function()
                profile.shadowColor = { unpack(defaults.shadowColor or {0,0,0,1}) }
                AscensionCastBar:applyFont()
                AscensionCastBar:selectTab("text")
            end)
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: SPELL NAME
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Spell Name")
    layout:beginSection()
        
        layout:checkbox(nil, "Show Name", "Show spell name on the cast bar.",
            function() return profile.showSpellText end,
            function(val)
                profile.showSpellText = val
                AscensionCastBar:updateTextVisibility()
            end
        )

        layout:checkbox(nil, "Truncate Name", "Truncate long spell names to fit the bar.",
            function() return profile.truncateSpellName end,
            function(val) 
                profile.truncateSpellName = val 
                AscensionCastBar:selectTab("text")
            end
        )

        if profile.truncateSpellName then
            layout:stepper(nil, "Max Characters", 5, 100, 1,
                function() return profile.truncateLength end,
                function(val) profile.truncateLength = val end
            )
        end

        layout:stepper(nil, "Size", 8, 32, 1,
            function() return profile.spellNameFontSize end,
            function(val)
                profile.spellNameFontSize = val
                AscensionCastBar:applyFont()
            end
        )

        layout:colorPicker(nil, "Color", nil,
            function() return unpack(profile.fontColor or defaults.fontColor or {1,1,1,1}) end,
            function(r, g, b, a)
                profile.fontColor = { r, g, b, a }
                AscensionCastBar:applyFont()
            end
        )
        layout:button(nil, "Reset Text Color", "", 140, 24, nil, function()
            profile.fontColor = { unpack(defaults.fontColor or {1,1,1,1}) }
            AscensionCastBar:applyFont()
            AscensionCastBar:selectTab("text")
        end)
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: TIMER
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Timer")
    layout:beginSection()
        
        layout:checkbox(nil, "Show Timer", "Show remaining or elapsed cast time.",
            function() return profile.showTimerText end,
            function(val) profile.showTimerText = val end
        )

        layout:checkbox(nil, "Hide on Channel", "Hide timer text when channeling.",
            function() return profile.hideTimerOnChannel end,
            function(val) profile.hideTimerOnChannel = val end
        )

        layout:dropdown(nil, "Format", nil, 
            { 
                { label = "Remaining", value = "Remaining" }, 
                { label = "Duration",  value = "Duration" }, 
                { label = "Total",     value = "Total" } 
            },
            function() return profile.timerFormat end,
            function(val) profile.timerFormat = val end
        )

        layout:stepper(nil, "Size", 8, 32, 1,
            function() return profile.timerFontSize end,
            function(val)
                profile.timerFontSize = val
                AscensionCastBar:applyFont()
            end
        )

        layout:checkbox(nil, "Use Shared Color", "Use the same color as the spell name.",
            function() return profile.useSharedColor end,
            function(val)
                profile.useSharedColor = val
                AscensionCastBar:applyFont()
                AscensionCastBar:selectTab("text")
            end
        )

        if not profile.useSharedColor then
            layout:colorPicker(nil, "Timer Color", nil,
                function() return unpack(profile.timerColor or defaults.timerColor or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile.timerColor = { r, g, b, a }
                    AscensionCastBar:applyFont()
                end
            )
            layout:button(nil, "Reset Timer Color", "", 140, 24, nil, function()
                profile.timerColor = { unpack(defaults.timerColor or {1,1,1,1}) }
                AscensionCastBar:applyFont()
                AscensionCastBar:selectTab("text")
            end)
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: POSITIONING & BACKDROP
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Positioning & Backdrop")
    layout:beginSection()

    layout:checkbox(nil, "Detach Text", "Detach text positioning from the cast bar.",
        function() return profile.detachText end,
        function(val)
            profile.detachText = val
            AscensionCastBar:updateTextLayout()
            AscensionCastBar:selectTab("text")
        end
    )

    if profile.detachText then
        layout:stepper(nil, "X Offset", -500, 500, 1,
            function() return profile.textX end,
            function(val)
                profile.textX = val
                AscensionCastBar:updateTextLayout()
            end
        )

        layout:stepper(nil, "Y Offset", -500, 500, 1,
            function() return profile.textY end,
            function(val)
                profile.textY = val
                AscensionCastBar:updateTextLayout()
            end
        )

        layout:stepper(nil, "Area Width", 50, 1000, 5,
            function() return profile.textWidth end,
            function(val)
                profile.textWidth = val
                AscensionCastBar:updateTextLayout()
            end
        )
    end

    layout:checkbox(nil, "Enable Backdrop", "Show backdrop behind text to improve readability.",
        function() return profile.textBackdropEnabled end,
        function(val)
            profile.textBackdropEnabled = val
            AscensionCastBar:updateTextLayout()
            AscensionCastBar:selectTab("text")
        end
    )

    if profile.textBackdropEnabled then
        layout:colorPicker(nil, "Backdrop Color", nil,
            function() return unpack(profile.textBackdropColor or defaults.textBackdropColor or {0,0,0,0.5}) end,
            function(r, g, b, a)
                profile.textBackdropColor = { r, g, b, a }
                AscensionCastBar:updateTextLayout()
            end
        )
        layout:button(nil, "Reset Backdrop Color", "", 140, 24, nil, function()
            profile.textBackdropColor = { unpack(defaults.textBackdropColor or {0,0,0,0.5}) }
            AscensionCastBar:updateTextLayout()
            AscensionCastBar:selectTab("text")
        end)
    end
    layout:endSection()
end

-- Register tab
addonTable.tabs["text"] = TextTab