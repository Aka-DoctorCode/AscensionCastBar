-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: General.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field


local addonName, addonTable = ...
local ADDON_NAME = "Ascension Cast Bar"
---@class AscensionCastBar
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
if not AscensionCastBar then return end

-- Registry for the General tab in the modular system
addonTable.tabs = addonTable.tabs or {}
local GeneralTab = {}

---Main rendering function for the General tab
function GeneralTab:render(layout, profile)
    
    -- -------------------------------------------------------------------------------
    -- SECTION: SETUP & TESTING
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Setup & Testing")
    layout:beginSection()
        
        -- Toggle: Enable Test Mode
        layout:checkbox(nil, "Enable Test Mode", nil, 
            function() return profile.previewEnabled end,
            function(val)
                profile.previewEnabled = val
                if not val then profile.testAttached = false end
                AscensionCastBar:toggleTestMode(val)
                AscensionCastBar:selectTab("general")
            end
        )

        -- Dropdown: Animation Type
        layout:dropdown(nil, "Animation Type", nil,
            { 
                { label = "Normal Cast", value = "Cast" }, 
                { label = "Channel",     value = "Channel" }, 
                { label = "Empowered",   value = "Empowered" } 
            },
            function() return profile.testModeState end,
            function(val)
                profile.testModeState = val
                if profile.previewEnabled then AscensionCastBar:toggleTestMode(true) end
            end
        )

        -- Toggle: Hide Blizzard Cast Bar
        layout:checkbox(nil, "Hide Blizzard Cast Bar", nil,
            function() return profile.hideDefaultCastbar end,
            function(val)
                profile.hideDefaultCastbar = val
                AscensionCastBar:updateDefaultCastBarVisibility()
            end
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: DIMENSIONS & ORIENTATION
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Dimensions & Orientation")
    layout:beginSection()
        layout:dropdown(nil, "Orientation", nil,
            {
                { label = "Horizontal", value = "HORIZONTAL" },
                { label = "Vertical",   value = "VERTICAL" },
            },
            function() return profile.orientation or "HORIZONTAL" end,
            function(val)
                profile.orientation = val
                AscensionCastBar:updateBarOrientation()
                AscensionCastBar:updateAnchor()
                AscensionCastBar:updateSparkSize()
                AscensionCastBar:updateIcon()
                AscensionCastBar:updateTextLayout()
                AscensionCastBar:updateTicks()
                AscensionCastBar:updateLatency()
                AscensionCastBar:selectTab("general")
            end
        )

        local invertDesc = (profile.orientation == "VERTICAL")
            and "Fills downward from top to bottom instead of bottom to top."
            or "Fills from right to left instead of left to right."

        layout:checkbox(nil, "Invert Fill Direction", invertDesc,
            function() return profile.invertFill or (profile.orientation == "VERTICAL" and profile.invertVerticalFill) or false end,
            function(val)
                profile.invertFill = val
                profile.invertVerticalFill = val
                AscensionCastBar:updateBarOrientation()
                AscensionCastBar:updateTicks()
                AscensionCastBar:updateLatency()
            end
        )

        if profile.orientation == "VERTICAL" then
            layout:dropdown(nil, "Vertical Text Layout", nil,
                {
                    { label = "Stacked Inside",    value = "StackedInside" },
                    { label = "Outside Top",        value = "OutsideTop" },
                    { label = "Outside Bottom",     value = "OutsideBottom" },
                    { label = "Outside Right",      value = "OutsideRight" },
                    { label = "Outside Left",       value = "OutsideLeft" },
                    { label = "Default (Horizontal)", value = "Default" },
                },
                function() return profile.verticalTextLayout or "StackedInside" end,
                function(val)
                    profile.verticalTextLayout = val
                    AscensionCastBar:updateTextLayout()
                end
            )
        end

        layout:stepper(nil, "Bar Width", 10, 1000, 1,
            function() return profile.manualWidth end,
            function(val)
                profile.manualWidth = val
                if AscensionCastBar.castBar then AscensionCastBar.castBar:SetWidth(val) end
                AscensionCastBar:updateAnchor()
                AscensionCastBar:updateSparkSize()
                AscensionCastBar:updateIcon()
            end
        )

        layout:stepper(nil, "Bar Height", 10, 1000, 1,
            function() return profile.manualHeight end,
            function(val)
                profile.manualHeight = val
                profile.height = val
                if AscensionCastBar.castBar then AscensionCastBar.castBar:SetHeight(val) end
                AscensionCastBar:updateSparkSize()
                AscensionCastBar:updateIcon()
            end
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: POSITIONING
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Positioning")
    layout:beginSection()

        local stratas = {
            { label = "Tooltip",        value = "TOOLTIP" },
            { label = "Fullscreen Dialog", value = "FULLSCREEN_DIALOG" },
            { label = "Fullscreen",     value = "FULLSCREEN" },
            { label = "Dialog",         value = "DIALOG" },
            { label = "High",           value = "HIGH" },
            { label = "Medium",         value = "MEDIUM" },
            { label = "Low",            value = "LOW" },
            { label = "Background",     value = "BACKGROUND" },
        }

        layout:dropdown(nil, "Frame Strata", nil, stratas,
            function() return profile.frameStrata or "MEDIUM" end,
            function(val)
                profile.frameStrata = val
                AscensionCastBar:updateStrata()
            end
        )

        layout:checkbox(nil, "Attach to UI Frame", "Automatically anchors the cast bar to UI elements (such as player frame).",
            function() return profile.attachToCDM end,
            function(val)
                profile.attachToCDM = val
                AscensionCastBar:initCDMHooks()
                AscensionCastBar:updateAnchor()
                AscensionCastBar:selectTab("general")
            end
        )

        if profile.attachToCDM then
            layout:checkbox(nil, "Test Attachment", "Toggle between testing automatic attachment (ON) or manual position (OFF).",
                function() return profile.testAttached end,
                function(val)
                    profile.testAttached = val
                    profile.previewEnabled = true
                    AscensionCastBar:toggleTestMode(true)
                    AscensionCastBar:updateAnchor()
                end
            )
            -- Automatic Attachment Configuration
            local cdmTargets = {
                { label = "Player Frame", value = "PlayerFrame" },
                { label = "Personal Resource Display", value = "PersonalResource" },
                { label = "Tracked Buffs (CDM)", value = "Buffs" },
                { label = "Essential Cooldowns (CDM)", value = "Essential" },
                { label = "Utility Cooldowns (CDM)", value = "Utility" },
                { label = "Coolinator", value = "Coolinator" },
                { label = "Action Bar 1", value = "ActionBar1" },
                { label = "Action Bar 2", value = "ActionBar2" },
                { label = "Action Bar 3", value = "ActionBar3" },
                { label = "Action Bar 4", value = "ActionBar4" },
                { label = "Action Bar 5", value = "ActionBar5" },
                { label = "Action Bar 6", value = "ActionBar6" },
                { label = "Action Bar 7", value = "ActionBar7" },
                { label = "Action Bar 8", value = "ActionBar8" },
                { label = "Bartender Bar 1", value = "BT4Bar1" },
                { label = "Bartender Bar 2", value = "BT4Bar2" },
                { label = "Bartender Bar 3", value = "BT4Bar3" },
                { label = "Bartender Bar 4", value = "BT4Bar4" },
                { label = "Bartender Bar 5", value = "BT4Bar5" },
                { label = "Bartender Bar 6", value = "BT4Bar6" },
                { label = "Bartender Bar 7", value = "BT4Bar7" },
                { label = "Bartender Bar 8", value = "BT4Bar8" },
                { label = "Bartender Bar 9", value = "BT4Bar9" },
                { label = "Bartender Bar 10", value = "BT4Bar10" },
                { label = "Bartender Pet Bar", value = "BT4PetBar" },
                { label = "Bartender Stance Bar", value = "BT4StanceBar" },
            }

            layout:dropdown(nil, "Attach Target", nil, cdmTargets,
                function() return profile.cdmTarget end,
                function(val)
                    profile.cdmTarget = val
                    AscensionCastBar:initCDMHooks()
                    AscensionCastBar:updateAnchor()
                end
            )

            layout:stepper(nil, "Vertical Offset", -200, 200, 1,
                function() return profile.cdmYOffset end,
                function(val)
                    profile.cdmYOffset = val
                    AscensionCastBar:updateAnchor()
                end
            )
        else
            -- Manual Attachment Configuration
            local anchors = {
                { label = "Center", value = "CENTER" },
                { label = "Top",    value = "TOP" },
                { label = "Bottom", value = "BOTTOM" },
                { label = "Left",   value = "LEFT" },
                { label = "Right",  value = "RIGHT" },
            }

            layout:dropdown(nil, "Anchor Point", nil, anchors,
                function() return profile.point end,
                function(val)
                    profile.point = val
                    AscensionCastBar:updateAnchor()
                end
            )

            layout:dropdown(nil, "Relative Point", nil, anchors,
                function() return profile.relativePoint end,
                function(val)
                    profile.relativePoint = val
                    AscensionCastBar:updateAnchor()
                end
            )

            layout:stepper(nil, "X Offset", -1000, 1000, 1,
                function() return profile.manualX end,
                function(val)
                    profile.manualX = val
                    AscensionCastBar:updateAnchor()
                end
            )

            layout:stepper(nil, "Y Offset", -1000, 1000, 1,
                function() return profile.manualY end,
                function(val)
                    profile.manualY = val
                    AscensionCastBar:updateAnchor()
                end
            )
        end
    layout:endSection()
end

-- Register tab
addonTable.tabs["general"] = GeneralTab