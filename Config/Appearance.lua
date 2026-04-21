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
    layout:header(nil, "Bar Style")
    layout:beginSection()
        
        -- Texture Selector (LSM)
        layout:dropdown(nil, "Texture", LSM:List("statusbar"),
            function() return profile.barLSMName end,
            function(val)
                profile.barLSMName = val
                AscensionCastBar:UpdateBarTexture()
            end
        )

        -- Bar Color
        layout:checkbox(nil, "Use Class Color", nil,
            function() return profile.useClassColor end,
            function(val)
                profile.useClassColor = val
                AscensionCastBar:UpdateBarColor()
                AscensionCastBar:SelectTab("castbar")
            end
        )

        if not profile.useClassColor then
            layout:colorPicker(nil, "Bar Color",
                function() return unpack(profile.barColor) end,
                function(r, g, b, a)
                    profile.barColor = { r, g, b, a }
                    AscensionCastBar:UpdateBarColor()
                end, nil, true
            )
        end

        -- Background Color (BG)
        layout:colorPicker(nil, "Background Color",
            function() return unpack(profile.bgColor) end,
            function(r, g, b, a)
                profile.bgColor = { r, g, b, a }
                AscensionCastBar:UpdateBackground()
            end, nil, true
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: BORDER (Bar Borders)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Border")
    layout:beginSection()
        
        layout:checkbox(nil, "Enable Border", nil,
            function() return profile.borderEnabled end,
            function(val)
                profile.borderEnabled = val
                AscensionCastBar:UpdateBorder()
                AscensionCastBar:SelectTab("castbar")
            end
        )

        if profile.borderEnabled then
            layout:colorPicker(nil, "Border Color",
                function() return unpack(profile.borderColor) end,
                function(r, g, b, a)
                    profile.borderColor = { r, g, b, a }
                    AscensionCastBar:UpdateBorder()
                end, nil, true
            )

            layout:slider(nil, "Thickness", 1, 10, 1,
                function() return profile.borderThickness end,
                function(val)
                    profile.borderThickness = val
                    AscensionCastBar:UpdateBorder()
                end
            )
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: SPELL ICON
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Spell Icon")
    layout:beginSection()
        
        layout:checkbox(nil, "Show Icon", nil,
            function() return profile.showIcon end,
            function(val)
                profile.showIcon = val
                AscensionCastBar:UpdateIcon()
                AscensionCastBar:SelectTab("castbar")
            end
        )

        if profile.showIcon then
            layout:checkbox(nil, "Detach Icon", nil,
                function() return profile.detachIcon end,
                function(val)
                    profile.detachIcon = val
                    AscensionCastBar:UpdateIcon()
                end
            )

            layout:dropdown(nil, "Position", { ["Left"] = "Left", ["Right"] = "Right" },
                function() return profile.iconAnchor end,
                function(val)
                    profile.iconAnchor = val
                    AscensionCastBar:UpdateIcon()
                end
            )

            layout:slider(nil, "Size", 10, 128, 1,
                function() return profile.iconSize end,
                function(val)
                    profile.iconSize = val
                    AscensionCastBar:UpdateIcon()
                end
            )

            -- Position Sliders (X/Y)
            layout:slider(nil, "Icon X Offset", -200, 200, 1,
                function() return profile.iconX end,
                function(val)
                    profile.iconX = val
                    AscensionCastBar:UpdateIcon()
                end
            )

            layout:slider(nil, "Icon Y Offset", -200, 200, 1,
                function() return profile.iconY end,
                function(val)
                    profile.iconY = val
                    AscensionCastBar:UpdateIcon()
                end
            )
        end
    layout:endSection()
end

-- Register the tab
addonTable.tabs["castbar"] = AppearanceTab