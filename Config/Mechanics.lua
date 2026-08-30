-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Mechanics.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field


local addonName, addonTable = ...
local ADDON_NAME = "Ascension Cast Bar"
---@class AscensionCastBar
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

-- Registry for the Mechanics tab
addonTable.tabs = addonTable.tabs or {}
local MechanicsTab = {}

---Rendering function for the Mechanics tab
function MechanicsTab:render(layout, profile)
    if not AscensionCastBar or not AscensionCastBar.defaults then return end
    local defaults = AscensionCastBar.defaults.profile
    if not defaults then return end

    -- -------------------------------------------------------------------------------
    -- SECTION: LATENCY (Lag Bar)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Latency & Lag")
    layout:beginSection()
        
        layout:checkbox(nil, "Show Latency (Lag)", nil,
            function() return profile.showLatency end,
            function(val)
                profile.showLatency = val
                AscensionCastBar:updateLatency()
                AscensionCastBar:selectTab("mechanics")
            end
        )

        if profile.showLatency then
            layout:colorPicker(nil, "Latency Color", nil,
                function() return unpack(profile.latencyColor or defaults.latencyColor or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile.latencyColor = { r, g, b, a }
                    AscensionCastBar:updateLatency()
                end
            )

            layout:slider(nil, "Max Width Percent", 0.01, 1, 0.01,
                function() return profile.latencyMaxPercent or 0.5 end,
                function(val) profile.latencyMaxPercent = val end
            )
            layout:button(nil, "Reset Latency Color", "", 160, 24, nil, function()
                profile.latencyColor = { unpack(defaults.latencyColor or {1,1,1,1}) }
                AscensionCastBar:updateLatency()
                AscensionCastBar:selectTab("mechanics")
            end)
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: CHANNELING TICKS
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Channeled Spells")
    layout:beginSection()

        layout:checkbox(nil, "Reverse Channel", "Reverse bar fill progress when channeling.",
            function() return profile.reverseChanneling end,
            function(val)
                profile.reverseChanneling = val
                if profile.previewEnabled then AscensionCastBar:toggleTestMode(true) end
            end
        )
        
        layout:checkbox(nil, "Show Ticks", "Show visual tick dividers on channeled spells.",
            function() return profile.showChannelTicks end,
            function(val)
                profile.showChannelTicks = val
                AscensionCastBar:updateTicks()
                AscensionCastBar:selectTab("mechanics")
            end
        )

        if profile.showChannelTicks then
            layout:stepper(nil, "Tick Thickness", 1, 10, 1,
                function() return profile.channelTicksThickness end,
                function(val)
                    profile.channelTicksThickness = val
                    AscensionCastBar:updateTicks()
                end
            )

            layout:colorPicker(nil, "Tick Color", nil,
                function() return unpack(profile.channelTicksColor or defaults.channelTicksColor or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile.channelTicksColor = { r, g, b, a }
                    AscensionCastBar:updateTicks()
                end
            )
            layout:button(nil, "Reset Tick Color", "", 160, 24, nil, function()
                profile.channelTicksColor = { unpack(defaults.channelTicksColor or {1,1,1,1}) }
                AscensionCastBar:updateTicks()
                AscensionCastBar:selectTab("mechanics")
            end)
        end

        layout:checkbox(nil, "Custom Channel Color", "Use custom cast bar color when channeling.",
            function() return profile.useChannelColor end,
            function(val)
                profile.useChannelColor = val
                AscensionCastBar:updateBarColor()
                AscensionCastBar:selectTab("mechanics")
            end
        )

        if profile.useChannelColor then
            layout:colorPicker(nil, "Channel Color", nil,
                function() return unpack(profile.channelColor or defaults.channelColor or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile.channelColor = { r, g, b, a }
                    AscensionCastBar:updateBarColor()
                end
            )
            layout:button(nil, "Reset Channel Color", "", 160, 24, nil, function()
                profile.channelColor = { unpack(defaults.channelColor or {1,1,1,1}) }
                AscensionCastBar:updateBarColor()
                AscensionCastBar:selectTab("mechanics")
            end)
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: EMPOWERED SPELLS
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Empowered Casts (Evoker)")
    layout:beginSection()
        
        layout:checkbox(nil, "Scale Bar Width", "Scale bar width as charge stages increase.",
            function() return profile.empowerWidthScale end,
            function(val)
                profile.empowerWidthScale = val
                AscensionCastBar:updateBarColor()
            end
        )

        for i = 1, 5 do
            layout:colorPicker(nil, "Stage " .. i .. " Color", nil,
                function() return unpack(profile["empowerStage" .. i .. "Color"] or defaults["empowerStage" .. i .. "Color"] or {1,1,1,1}) end,
                function(r, g, b, a)
                    profile["empowerStage" .. i .. "Color"] = { r, g, b, a }
                    AscensionCastBar:updateBarColor()
                end
            )
            layout:button(nil, "Reset Stage " .. i, "", 140, 24, nil, function()
                profile["empowerStage" .. i .. "Color"] = { unpack(defaults["empowerStage" .. i .. "Color"] or {1,1,1,1}) }
                AscensionCastBar:updateBarColor()
                AscensionCastBar:selectTab("mechanics")
            end)
        end

        layout:checkbox(nil, "Show Stage Dividers", "Show vertical divider lines between charge stages.",
            function() return profile.showEmpowerStages end,
            function(val)
                profile.showEmpowerStages = val
                AscensionCastBar:updateTicks()
            end
        )
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECTION: STATUS COLORS
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Feedback Colors")
    layout:beginSection()

        layout:checkbox(nil, "Flash on Interrupted", nil,
            function() return profile.flashInterrupted end,
            function(val) profile.flashInterrupted = val end
        )

        layout:colorPicker(nil, "Interrupted Color", nil,
            function() return unpack(profile.interruptedColor or defaults.interruptedColor or {1,1,1,1}) end,
            function(r, g, b, a)
                profile.interruptedColor = { r, g, b, a }
            end
        )
        layout:button(nil, "Reset Interrupted", "", 160, 24, nil, function()
            profile.interruptedColor = { unpack(defaults.interruptedColor or {1,1,1,1}) }
            AscensionCastBar:selectTab("mechanics")
        end)

        layout:colorPicker(nil, "Failed/Cancelled Color", nil,
            function() return unpack(profile.failedColor or defaults.failedColor or {1,1,1,1}) end,
            function(r, g, b, a)
                profile.failedColor = { r, g, b, a }
            end
        )
        layout:button(nil, "Reset Failed", "", 160, 24, nil, function()
            profile.failedColor = { unpack(defaults.failedColor or {1,1,1,1}) }
            AscensionCastBar:selectTab("mechanics")
        end)

        layout:colorPicker(nil, "Finished Success Color", nil,
            function() return unpack(profile.successColor or defaults.successColor or {1,1,1,1}) end,
            function(r, g, b, a)
                profile.successColor = { r, g, b, a }
            end
        )
        layout:button(nil, "Reset Success", "", 160, 24, nil, function()
            profile.successColor = { unpack(defaults.successColor or {1,1,1,1}) }
            AscensionCastBar:selectTab("mechanics")
        end)
    layout:endSection()
end

-- Register tab
addonTable.tabs["mechanics"] = MechanicsTab