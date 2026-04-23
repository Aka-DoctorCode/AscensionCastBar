-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Appearance.lua
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
local LSM = LibStub("LibSharedMedia-3.0")

-- Registry in the tab system
addonTable.tabs = addonTable.tabs or {}
local AppearanceTab = {}

---Rendering function for the Appearance tab
---@param layout table layoutModel object
---@param profile table Reference to self.db.profile
function AppearanceTab:render(layout, profile)
    if not AscensionCastBar or not AscensionCastBar.defaults then return end
    local defaults = AscensionCastBar.defaults.profile
    if not defaults then return end

    -- -------------------------------------------------------------------------------
    -- SECTION: BAR STYLE (Main Textures and Colors)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Bar Style")
    layout:beginSection()
        
        -- Texture Selector (LSM)
        local textures = {}
        for _, name in ipairs(LSM:List("statusbar")) do
            table.insert(textures, { label = name, value = name })
        end
        layout:dropdown(nil, "Texture", nil, textures,
            function() return profile.barLSMName end,
            function(val)
                profile.barLSMName = val
                AscensionCastBar:updateBarColor()
            end
        )

        -- Bar Color
        layout:checkbox(nil, "Use Class Color", nil,
            function() return profile.useClassColor end,
            function(val)
                profile.useClassColor = val
                AscensionCastBar:updateBarColor()
                AscensionCastBar:selectTab("castbar")
            end
        )

        if not profile.useClassColor then
            layout:colorPicker(nil, "Bar Color",
                function() return unpack(profile.barColor or defaults.barColor or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile.barColor = { r, g, b, a }
                    AscensionCastBar:updateBarColor()
                end, nil, true
            )
            layout:button(nil, "Reset Bar Color", 120, 20, nil, function()
                profile.barColor = { unpack(defaults.barColor or {1,1,1,1}) }
                AscensionCastBar:updateBarColor()
                AscensionCastBar:selectTab("castbar")
            end)
        end

        -- Background Color (BG)
        layout:colorPicker(nil, "Background Color",
            function() return unpack(profile.bgColor or defaults.bgColor or {1,1,1,1}) end,
            function(r, g, b, a)
                profile.bgColor = { r, g, b, a }
                AscensionCastBar:updateBackground()
            end, nil, true
        )
        layout:button(nil, "Reset Background", 120, 20, nil, function()
            profile.bgColor = { unpack(defaults.bgColor or {1,1,1,1}) }
            AscensionCastBar:updateBackground()
            AscensionCastBar:selectTab("castbar")
        end)
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
                AscensionCastBar:updateBorder()
                AscensionCastBar:selectTab("castbar")
            end
        )

        if profile.borderEnabled then
            layout:colorPicker(nil, "Border Color",
                function() return unpack(profile.borderColor or defaults.borderColor or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile.borderColor = { r, g, b, a }
                    AscensionCastBar:updateBorder()
                end, nil, true
            )
            layout:button(nil, "Reset Border Color", 120, 20, nil, function()
                profile.borderColor = { unpack(defaults.borderColor or {1,1,1,1}) }
                AscensionCastBar:updateBorder()
                AscensionCastBar:selectTab("castbar")
            end)

            layout:slider(nil, "Thickness", 1, 10, 1,
                function() return profile.borderThickness end,
                function(val)
                    profile.borderThickness = val
                    AscensionCastBar:updateBorder()
                end
            )
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: ICON & DECORATIONS
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Spell Icon")
    layout:beginSection()
        
        layout:checkbox(nil, "Show Icon", "Muestra el icono del hechizo que se está casteando.",
            function() return profile.showIcon end,
            function(val)
                profile.showIcon = val
                AscensionCastBar:updateIcon()
                AscensionCastBar:selectTab("castbar")
            end
        )

        if profile.showIcon then
            layout:checkbox(nil, "Detach Icon", "Separa el icono de la barra para moverlo libremente.",
                function() return profile.detachIcon end,
                function(val)
                    profile.detachIcon = val
                    AscensionCastBar:updateIcon()
                end
            )

            layout:dropdown(nil, "Position", nil, 
                { 
                    { label = "Left", value = "Left" }, 
                    { label = "Right", value = "Right" } 
                },
                function() return profile.iconAnchor end,
                function(val)
                    profile.iconAnchor = val
                    AscensionCastBar:updateIcon()
                end
            )

            layout:stepper(nil, "Size", 10, 128, 1,
                function() return profile.iconSize end,
                function(val)
                    profile.iconSize = val
                    AscensionCastBar:updateIcon()
                end
            )

            layout:stepper(nil, "Icon X Offset", -200, 200, 1,
                function() return profile.iconX end,
                function(val)
                    profile.iconX = val
                    AscensionCastBar:updateIcon()
                end
            )

            layout:stepper(nil, "Icon Y Offset", -200, 200, 1,
                function() return profile.iconY end,
                function(val)
                    profile.iconY = val
                    AscensionCastBar:updateIcon()
                end
            )
        end
    layout:endSection()
end

-- Register the tab
addonTable.tabs["castbar"] = AppearanceTab