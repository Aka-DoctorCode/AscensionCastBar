-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Config/Appearance.lua
-- Version: @project-version@
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in
-- derivative works without express written permission.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
---@class AscensionCastBar
local AscensionCastBar = addonTable.main or LibStub("AceAddon-3.0"):GetAddon("Ascension Cast Bar")
local LSM = LibStub("LibSharedMedia-3.0")

-- Registry in the tab system
addonTable.tabs = addonTable.tabs or {}
local AppearanceTab = {}

---Rendering function for the Appearance tab
---@param layout table layoutModel object
---@param profile table Reference to self.db.profile
function AppearanceTab:Render(layout, profile)
    local defaults = AscensionCastBar.defaults.profile

    -- -------------------------------------------------------------------------------
    -- SECTION: BAR STYLE (Main Textures and Colors)
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Bar Style" })
    layout:beginSection()
        
        -- Texture Selector (LSM)
        layout:createDropdown({
            text = "Texture",
            values = LSM:List("statusbar"),
            get = function() return profile.barLSMName end,
            set = function(val)
                profile.barLSMName = val
                AscensionCastBar:UpdateBarTexture()
            end
        })

        -- Bar Color
        layout:createToggle({
            text = "Use Class Color",
            get = function() return profile.useClassColor end,
            set = function(val)
                profile.useClassColor = val
                AscensionCastBar:UpdateBarColor()
            end
        })

        layout:createColorPicker({
            text = "Bar Color",
            disabled = function() return profile.useClassColor end,
            get = function() return unpack(profile.barColor) end,
            set = function(r, g, b, a)
                profile.barColor = { r, g, b, a }
                AscensionCastBar:UpdateBarColor()
            end,
            onReset = function()
                profile.barColor = { unpack(defaults.barColor) }
                AscensionCastBar:UpdateBarColor()
            end
        })

        -- Background Color (BG)
        layout:createColorPicker({
            text = "Background Color",
            get = function() return unpack(profile.bgColor) end,
            set = function(r, g, b, a)
                profile.bgColor = { r, g, b, a }
                AscensionCastBar:UpdateBackground()
            end,
            onReset = function()
                profile.bgColor = { unpack(defaults.bgColor) }
                AscensionCastBar:UpdateBackground()
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: BORDER (Bar Borders)
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Border" })
    layout:beginSection()
        
        layout:createToggle({
            text = "Enable Border",
            get = function() return profile.borderEnabled end,
            set = function(val)
                profile.borderEnabled = val
                AscensionCastBar:UpdateBorder()
            end
        })

        layout:createColorPicker({
            text = "Border Color",
            disabled = function() return not profile.borderEnabled end,
            get = function() return unpack(profile.borderColor) end,
            set = function(r, g, b, a)
                profile.borderColor = { r, g, b, a }
                AscensionCastBar:UpdateBorder()
            end,
            onReset = function()
                profile.borderColor = { unpack(defaults.borderColor) }
                AscensionCastBar:UpdateBorder()
            end
        })

        layout:createSlider({
            text = "Thickness",
            min = 1, max = 10, step = 1,
            disabled = function() return not profile.borderEnabled end,
            get = function() return profile.borderThickness end,
            set = function(val)
                profile.borderThickness = val
                AscensionCastBar:UpdateBorder()
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: SPELL ICON
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Spell Icon" })
    layout:beginSection()
        
        layout:createToggle({
            text = "Show Icon",
            get = function() return profile.showIcon end,
            set = function(val)
                profile.showIcon = val
                AscensionCastBar:UpdateIcon()
                -- Refresh to show/hide icon options
                AscensionCastBar:SelectTab("castbar")
            end
        })

        if profile.showIcon then
            layout:createToggle({
                text = "Detach Icon",
                get = function() return profile.detachIcon end,
                set = function(val)
                    profile.detachIcon = val
                    AscensionCastBar:UpdateIcon()
                end
            })

            layout:createDropdown({
                text = "Position",
                values = { ["Left"] = "Left", ["Right"] = "Right" },
                get = function() return profile.iconAnchor end,
                set = function(val)
                    profile.iconAnchor = val
                    AscensionCastBar:UpdateIcon()
                end
            })

            layout:createSlider({
                text = "Size",
                min = 10, max = 128, step = 1,
                get = function() return profile.iconSize end,
                set = function(val)
                    profile.iconSize = val
                    AscensionCastBar:UpdateIcon()
                end
            })

            -- Position Sliders (X/Y)
            layout:createSlider({
                text = "Icon X Offset",
                min = -200, max = 200, step = 1,
                get = function() return profile.iconX end,
                set = function(val)
                    profile.iconX = val
                    AscensionCastBar:UpdateIcon()
                end
            })

            layout:createSlider({
                text = "Icon Y Offset",
                min = -200, max = 200, step = 1,
                get = function() return profile.iconY end,
                set = function(val)
                    profile.iconY = val
                    AscensionCastBar:UpdateIcon()
                end
            })
        end
    layout:endSection()
end

-- Register the tab
addonTable.tabs["castbar"] = AppearanceTab