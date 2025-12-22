local ADDON_NAME = "Ascension Cast Bar"
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local LSM = LibStub("LibSharedMedia-3.0")

-- ==========================================================
-- DEFAULTS
-- ==========================================================

local BAR_DEFAULT_FONT_PATH = "Interface\\AddOns\\AscensionCastBar\\COLLEGIA.ttf"

AscensionCastBar.defaults = {
    profile = {
        width = 270, height = 24,
        point = "CENTER", relativePoint = "CENTER", x = 0, y = -85,
        
        -- Empower Colors
        empowerStage1Color = {0, 1, 0, 1},       -- Green
        empowerStage2Color = {1, 1, 0, 1},       -- Yellow
        empowerStage3Color = {1, 0.64, 0, 1},    -- Orange
        empowerStage4Color = {1, 0, 0, 1},       -- Red
        empowerStage5Color = {0.6, 0, 1, 1},     -- Purple (Default)
        
        -- Channel Ticks
        showChannelTicks = true, 
        showChannelTicks = true, 
        channelTicksColor = {1, 1, 1, 0.5},
        channelTicksThickness = 1,
        
        -- Channel Colors
        useChannelColor = true,                          
        channelColor = {0.5, 0.5, 1, 1},                 
        channelBorderGlow = false,                       
        channelGlowColor = {0, 0.8, 1, 1},

        -- Fonts/Text
        spellNameFontSize = 14, timerFontSize = 14, 
        fontPath = BAR_DEFAULT_FONT_PATH,
        fontColor = {0.8078, 1, 0.9529, 1},
        showSpellText = true, showTimerText = true,
        spellNameFontLSM = "Expressway, Bold", timerFontLSM = "Boris Black Bloxx",
        detachText = false, textX = 0, textY = 40, textWidth = 270,
        textBackdropEnabled = false, textBackdropColor = {0, 0, 0, 0.5},
        timerFormat = "Remaining", truncateSpellName = false, truncateLength = 30,
        
        -- Colors
        barColor = {0, 0.0274, 0.2509, 1}, barLSMName = "Solid", useClassColor = false,
        
        -- Anim
        enableSpark = true, enableTails = true, animStyle = "Comet",
        sparkColor = {0.937, 0.984, 1, 1}, glowColor = {1, 1, 1, 1},
        sparkIntensity = 1, glowIntensity = 0.5, sparkScale = 3, sparkOffset = 1.27, headLengthOffset = -23,
        
        -- Tail Colors
        tailLength = 200, tailOffset = -14.68,
        tail1Color = {1, 0, 0.09, 1}, tail1Intensity = 1, tail1Length = 95,
        tail2Color = {0, 0.98, 1, 1}, tail2Intensity = 0.42, tail2Length = 215,
        tail3Color = {0, 1, 0.22, 1}, tail3Intensity = 0.68, tail3Length = 80,
        tail4Color = {1, 0, 0.8, 1}, tail4Intensity = 0.61, tail4Length = 150,
        
        -- Icon
        showIcon = false, detachIcon = false, iconAnchor = "Left", iconSize = 24, iconX = 0, iconY = 0,
        
        -- BG
        bgColor = {0, 0, 0, 0.65}, borderEnabled = true, borderColor = {0, 0, 0, 1}, borderThickness = 2,
        
        -- Behavior
        hideTimerOnChannel = false, hideDefaultCastbar = true,
        reverseChanneling = false,
        showLatency = true, latencyColor = {1, 0, 0, 0.5}, latencyMaxPercent = 1.0,
        
        -- CDM
        attachToCDM = false, cdmTarget = "Auto", cdmFrameName = "CooldownManagerFrame", cdmYOffset = -5,
        previewEnabled = false, testModeState = "Cast",
    }
}

-- ==========================================================
-- ACE CONFIG (OPTIONS)
-- ==========================================================

function AscensionCastBar:SetupOptions()
    local options = {
        name = ADDON_NAME,
        handler = AscensionCastBar,
        type = "group",
        args = {
            general = {
                name = "General",
                type = "group",
                order = 1,
                args = {
                    -- Replaced unlock with Sliders
                    xOffset = {
                        name = "X Position",
                        type = "range", min = -1000, max = 1000, step = 1, order = 1,
                        get = function(info) return self.db.profile.x end,
                        set = function(info, val) self.db.profile.x = val; self:UpdateAnchor() end,
                    },
                    yOffset = {
                        name = "Y Position",
                        type = "range", min = -1000, max = 1000, step = 1, order = 2,
                        get = function(info) return self.db.profile.y end,
                        set = function(info, val) self.db.profile.y = val; self:UpdateAnchor() end,
                    },
                    preview = {
                        name = "Test Mode",
                        desc = "Show a preview cast to configure visuals.",
                        type = "toggle",
                        order = 3,
                        get = function(info) return self.db.profile.previewEnabled end,
                        set = function(info, val) self.db.profile.previewEnabled = val; self:ToggleTestMode(val) end,
                    },
                    testModeState = {
                        name = "Test State",
                        desc = "Select which type of cast to simulate.",
                        type = "select",
                        order = 3.5,
                        values = {["Cast"]="Cast", ["Channel"]="Channel", ["Empowered"]="Empowered"},
                        disabled = function() return not self.db.profile.previewEnabled end,
                        get = function(info) return self.db.profile.testModeState end,
                        set = function(info, val) self.db.profile.testModeState = val; self:ToggleTestMode(true) end,
                    },
                    hideBlizzard = {
                        name = "Hide Blizzard Castbar",
                        type = "toggle",
                        order = 4,
                        get = function(info) return self.db.profile.hideDefaultCastbar end,
                        set = function(info, val) self.db.profile.hideDefaultCastbar = val; self:UpdateDefaultCastBarVisibility() end,
                    },
                    width = {
                        name = "Width",
                        type = "range", min = 100, max = 600, step = 1, order = 10,
                        get = function(info) return self.db.profile.width end,
                        set = function(info, val) self.db.profile.width = val; self:UpdateAnchor() end,
                    },
                    height = {
                        name = "Height",
                        type = "range", min = 10, max = 100, step = 1, order = 11,
                        get = function(info) return self.db.profile.height end,
                        set = function(info, val) self.db.profile.height = val; self.castBar:SetHeight(val); self:UpdateSparkSize(); self:UpdateIcon() end,
                    },
                }
            },
            visuals = {
                name = "Visuals",
                type = "group",
                order = 2,
                args = {
                    headerColors = { name = "Colors", type = "header", order = 0 },
                    useClassColor = {
                        name = "Use Class Color",
                        type = "toggle", order = 1,
                        get = function(info) return self.db.profile.useClassColor end,
                        set = function(info, val) self.db.profile.useClassColor = val; self:UpdateBarColor() end,
                    },
                    barColor = {
                        name = "Bar Color",
                        type = "color", hasAlpha = true, order = 2,
                        get = function(info) local c = self.db.profile.barColor; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.barColor = {r, g, b, a}; self:UpdateBarColor() end,
                    },
                    bgColor = {
                        name = "Background Color",
                        type = "color", hasAlpha = true, order = 3,
                        get = function(info) local c = self.db.profile.bgColor; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.bgColor = {r, g, b, a}; self:UpdateBackground() end,
                    },
                    headerBorder = { name = "Border", type = "header", order = 10 },
                    borderEnabled = {
                        name = "Enable Border",
                        type = "toggle", order = 11,
                        get = function(info) return self.db.profile.borderEnabled end,
                        set = function(info, val) self.db.profile.borderEnabled = val; self:UpdateBorder() end,
                    },
                    borderColor = {
                        name = "Border Color",
                        type = "color", hasAlpha = true, order = 12,
                        get = function(info) local c = self.db.profile.borderColor; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.borderColor = {r, g, b, a}; self:UpdateBorder() end,
                    },
                    borderThickness = {
                        name = "Thickness",
                        type = "range", min=1, max=10, step=1, order=13,
                        get = function(info) return self.db.profile.borderThickness end,
                        set = function(info, val) self.db.profile.borderThickness = val; self:UpdateBorder() end,
                    },
                    headerIcon = { name = "Icon", type = "header", order = 20 },
                    showIcon = {
                        name = "Show Icon", type = "toggle", order = 21,
                        get = function(info) return self.db.profile.showIcon end,
                        set = function(info, val) self.db.profile.showIcon = val; self:UpdateIcon() end,
                    },
                    detachIcon = {
                        name = "Detach Icon", type = "toggle", order = 22,
                        get = function(info) return self.db.profile.detachIcon end,
                        set = function(info, val) self.db.profile.detachIcon = val; self:UpdateIcon() end,
                    },
                    iconAnchor = {
                        name = "Icon Position", type = "select", values = {["Left"]="Left", ["Right"]="Right"}, order = 23,
                        get = function(info) return self.db.profile.iconAnchor end,
                        set = function(info, val) self.db.profile.iconAnchor = val; self:UpdateIcon() end,
                    },
                    iconSize = {
                        name = "Icon Size", type = "range", min=10, max=128, step=1, order=24,
                        get = function(info) return self.db.profile.iconSize end,
                        set = function(info, val) self.db.profile.iconSize = val; self:UpdateIcon() end,
                    },
                    iconX = {
                        name = "Icon X", type = "range", min=-200, max=200, step=1, order=25,
                        get = function(info) return self.db.profile.iconX end,
                        set = function(info, val) self.db.profile.iconX = val; self:UpdateIcon() end,
                    },
                    iconY = {
                        name = "Icon Y", type = "range", min=-200, max=200, step=1, order=26,
                        get = function(info) return self.db.profile.iconY end,
                        set = function(info, val) self.db.profile.iconY = val; self:UpdateIcon() end,
                    },
                    headerCombat = { name = "Combat & Channels", type = "header", order = 30 },
                    
                    -- CHANNELS
                    spacer1 = { name = " ", type = "description", order = 35 },
                    showChannelTicks = {
                        name = "Show Ticks", type = "toggle", order = 36,
                        get = function(info) return self.db.profile.showChannelTicks end,
                        set = function(info, val) self.db.profile.showChannelTicks = val end,
                    },
                    channelTicksThickness = {
                        name = "Tick Thickness",
                        type = "range", min = 1, max = 10, step = 1, order = 36.1,
                        disabled = function() return not self.db.profile.showChannelTicks end,
                        get = function(info) return self.db.profile.channelTicksThickness end,
                        set = function(info, val) self.db.profile.channelTicksThickness = val end,
                    },
                    channelTicksColor = {
                        name = "Tick Color",
                        type = "color", hasAlpha = true, order = 36.2,
                        disabled = function() return not self.db.profile.showChannelTicks end,
                        get = function(info) 
                            local c = self.db.profile.channelTicksColor
                            return c[1], c[2], c[3], c[4] 
                        end,
                        set = function(info, r, g, b, a) 
                            self.db.profile.channelTicksColor = {r, g, b, a} 
                        end,
                    },
                    headerEmpower = { name = "Empowered Spells", type = "header", order = 45 },
                    
                    empowerStage1Color = {
                        name = "Stage 1 (Start)", type = "color", hasAlpha = true, order = 46,
                        get = function(info) local c = self.db.profile.empowerStage1Color; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.empowerStage1Color = {r, g, b, a} end,
                    },
                    empowerStage2Color = {
                        name = "Stage 2", type = "color", hasAlpha = true, order = 47,
                        get = function(info) local c = self.db.profile.empowerStage2Color; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.empowerStage2Color = {r, g, b, a} end,
                    },
                    empowerStage3Color = {
                        name = "Stage 3", type = "color", hasAlpha = true, order = 48,
                        get = function(info) local c = self.db.profile.empowerStage3Color; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.empowerStage3Color = {r, g, b, a} end,
                    },
                    empowerStage4Color = {
                        name = "Stage 4 Color", type = "color", hasAlpha = true, order = 49,
                        get = function(info) local c = self.db.profile.empowerStage4Color; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.empowerStage4Color = {r, g, b, a} end,
                    },
                    empowerStage5Color = {
                        name = "Stage 5 (Max Hold)", desc = "Color for the extra final stage.", type = "color", hasAlpha = true, order = 50,
                        get = function(info) local c = self.db.profile.empowerStage5Color; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.empowerStage5Color = {r, g, b, a} end,
                    },
                    useChannelColor = {
                        name = "Custom Channel Color", desc="Use a specific color for channeled spells.", type = "toggle", order = 37,
                        get = function(info) return self.db.profile.useChannelColor end,
                        set = function(info, val) self.db.profile.useChannelColor = val end,
                    },
                    channelColor = {
                        name = "Channel Bar Color", type = "color", hasAlpha = true, order = 38,
                        disabled = function() return not self.db.profile.useChannelColor end,
                        get = function(info) local c = self.db.profile.channelColor; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.channelColor = {r, g, b, a}; end,
                    },
                    channelBorderGlow = {
                        name = "Channel Glow", desc="Glow the border when channeling.", type = "toggle", order = 39,
                        get = function(info) return self.db.profile.channelBorderGlow end,
                        set = function(info, val) self.db.profile.channelBorderGlow = val end,
                    },
                    channelGlowColor = {
                        name = "Channel Glow Color", type = "color", hasAlpha = true, order = 40,
                        disabled = function() return not self.db.profile.channelBorderGlow end,
                        get = function(info) local c = self.db.profile.channelGlowColor; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.channelGlowColor = {r, g, b, a}; end,
                    },
                    
                    reverseChanneling = {
                        name = "Reverse Channeling", desc = "Fill bar instead of empty for channels.", type = "toggle", order = 41,
                        get = function(info) return self.db.profile.reverseChanneling end,
                        set = function(info, val) self.db.profile.reverseChanneling = val end,
                    },
                    showLatency = {
                        name = "Show Latency", type = "toggle", order = 34.5,
                        get = function(info) return self.db.profile.showLatency end,
                        set = function(info, val) self.db.profile.showLatency = val end,
                    },
                }
            },
            text = {
                name = "Text",
                type = "group",
                order = 3,
                args = {
                    showSpellText = {
                        name = "Show Spell Name", type = "toggle", order = 1,
                        get = function(info) return self.db.profile.showSpellText end,
                        set = function(info, val) self.db.profile.showSpellText = val end,
                    },
                    showTimerText = {
                        name = "Show Timer", type = "toggle", order = 2,
                        get = function(info) return self.db.profile.showTimerText end,
                        set = function(info, val) self.db.profile.showTimerText = val end,
                    },
                    hideTimerOnChannel = {
                        name = "Hide Timer on Channel", type = "toggle", order = 3,
                        get = function(info) return self.db.profile.hideTimerOnChannel end,
                        set = function(info, val) self.db.profile.hideTimerOnChannel = val end,
                    },
                    timerFormat = {
                        name = "Timer Format", type = "select", values = {["Remaining"]="Remaining", ["Duration"]="Duration", ["Total"]="Total"}, order = 4,
                        get = function(info) return self.db.profile.timerFormat end,
                        set = function(info, val) self.db.profile.timerFormat = val end,
                    },
                    truncateSpellName = {
                        name = "Truncate Name", type = "toggle", order = 5,
                        get = function(info) return self.db.profile.truncateSpellName end,
                        set = function(info, val) self.db.profile.truncateSpellName = val end,
                    },
                    truncateLength = {
                        name = "Max Characters", type = "range", min=5, max=100, step=1, order = 6,
                        get = function(info) return self.db.profile.truncateLength end,
                        set = function(info, val) self.db.profile.truncateLength = val end,
                    },
                    fontSizeSpell = {
                        name = "Spell Font Size", type = "range", min=8, max=32, step=1, order=10,
                        get = function(info) return self.db.profile.spellNameFontSize end,
                        set = function(info, val) self.db.profile.spellNameFontSize = val; self:ApplyFont() end,
                    },
                    fontSizeTimer = {
                        name = "Timer Font Size", type = "range", min=8, max=32, step=1, order=11,
                        get = function(info) return self.db.profile.timerFontSize end,
                        set = function(info, val) self.db.profile.timerFontSize = val; self:ApplyFont() end,
                    },
                    font = {
                        name = "Font", type = "select", dialogControl = 'LSM30_Font', values = LSM:HashTable("font"), order = 12,
                        get = function(info) return self.db.profile.spellNameFontLSM end,
                        set = function(info, val) self.db.profile.spellNameFontLSM = val; self.db.profile.timerFontLSM = val; self:ApplyFont() end,
                    },
                }
            },
            effects = {
                name = "Effects",
                type = "group",
                order = 4,
                args = {
                    enableSpark = {
                        name = "Enable Spark", type = "toggle", order = 1,
                        get = function(info) return self.db.profile.enableSpark end,
                        set = function(info, val) self.db.profile.enableSpark = val end,
                    },
                    animStyle = {
                        name = "Animation Style", type = "select", order = 2,
                        values = {
                            ["Comet"] = "Comet", ["Orb"] = "Orb", ["Flux"] = "Flux", ["Helix"] = "Helix", 
                            ["Vortex"] = "Vortex", ["Pulse"] = "Pulse", ["Starfall"] = "Starfall", ["Wave"] = "Wave", 
                            ["Particles"] = "Particles", ["Scanline"] = "Scanline", ["Glitch"] = "Glitch", 
                            ["Lightning"] = "Lightning", ["Rainbow"] = "Rainbow"
                        },
                        get = function(info) return self.db.profile.animStyle end,
                        set = function(info, val) self.db.profile.animStyle = val end,
                    },
                    sparkIntensity = {
                        name = "Intensity", type = "range", min=0, max=5, step=0.05, order=3,
                        get = function(info) return self.db.profile.sparkIntensity end,
                        set = function(info, val) self.db.profile.sparkIntensity = val end,
                    },
                    sparkScale = {
                        name = "Scale", type = "range", min=0.5, max=3, step=0.1, order=4,
                        get = function(info) return self.db.profile.sparkScale end,
                        set = function(info, val) self.db.profile.sparkScale = val; self:UpdateSparkSize() end,
                    },
                    sparkOffset = {
                        name = "Horizontal Offset", type = "range", min=-100, max=100, step=0.1, order=4.5,
                        get = function(info) return self.db.profile.sparkOffset end,
                        set = function(info, val) self.db.profile.sparkOffset = val end,
                    },
                    sparkColor = {
                        name = "Spark Head Color", type = "color", hasAlpha = true, order=5,
                        get = function(info) local c = self.db.profile.sparkColor; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.sparkColor = {r,g,b,a}; self:UpdateSparkColors() end,
                    },
                    headerTails = { name = "Individual Tail Settings", type = "header", order = 10 },
                    enableTails = {
                        name = "Enable Tails", type = "toggle", order = 11,
                        get = function(info) return self.db.profile.enableTails end,
                        set = function(info, val) self.db.profile.enableTails = val end,
                    },
                    tail1Group = {
                        name = "Tail 1 (Primary)", type = "group", inline = true, order = 12,
                        args = {
                            color = {
                                name = "Color", type = "color", hasAlpha = true, order = 1,
                                get = function(info) local c = self.db.profile.tail1Color; return c[1], c[2], c[3], c[4] end,
                                set = function(info, r, g, b, a) self.db.profile.tail1Color = {r,g,b,a}; self:UpdateSparkColors() end,
                            },
                            intensity = {
                                name = "Intensity", type = "range", min=0, max=5, step=0.05, order = 2,
                                get = function(info) return self.db.profile.tail1Intensity end,
                                set = function(info, val) self.db.profile.tail1Intensity = val end,
                            },
                            length = {
                                name = "Length", type = "range", min=10, max=400, step=1, order = 3,
                                get = function(info) return self.db.profile.tail1Length end,
                                set = function(info, val) self.db.profile.tail1Length = val; self:UpdateSparkSize() end,
                            },
                        }
                    },
                    tail2Group = {
                        name = "Tail 2", type = "group", inline = true, order = 13,
                        args = {
                            color = {
                                name = "Color", type = "color", hasAlpha = true, order = 1,
                                get = function(info) local c = self.db.profile.tail2Color; return c[1], c[2], c[3], c[4] end,
                                set = function(info, r, g, b, a) self.db.profile.tail2Color = {r,g,b,a}; self:UpdateSparkColors() end,
                            },
                            intensity = {
                                name = "Intensity", type = "range", min=0, max=5, step=0.05, order = 2,
                                get = function(info) return self.db.profile.tail2Intensity end,
                                set = function(info, val) self.db.profile.tail2Intensity = val end,
                            },
                            length = {
                                name = "Length", type = "range", min=10, max=400, step=1, order = 3,
                                get = function(info) return self.db.profile.tail2Length end,
                                set = function(info, val) self.db.profile.tail2Length = val; self:UpdateSparkSize() end,
                            },
                        }
                    },
                    tail3Group = {
                        name = "Tail 3", type = "group", inline = true, order = 14,
                        args = {
                            color = {
                                name = "Color", type = "color", hasAlpha = true, order = 1,
                                get = function(info) local c = self.db.profile.tail3Color; return c[1], c[2], c[3], c[4] end,
                                set = function(info, r, g, b, a) self.db.profile.tail3Color = {r,g,b,a}; self:UpdateSparkColors() end,
                            },
                            intensity = {
                                name = "Intensity", type = "range", min=0, max=5, step=0.05, order = 2,
                                get = function(info) return self.db.profile.tail3Intensity end,
                                set = function(info, val) self.db.profile.tail3Intensity = val end,
                            },
                            length = {
                                name = "Length", type = "range", min=10, max=400, step=1, order = 3,
                                get = function(info) return self.db.profile.tail3Length end,
                                set = function(info, val) self.db.profile.tail3Length = val; self:UpdateSparkSize() end,
                            },
                        }
                    },
                    tail4Group = {
                        name = "Tail 4", type = "group", inline = true, order = 15,
                        args = {
                            color = {
                                name = "Color", type = "color", hasAlpha = true, order = 1,
                                get = function(info) local c = self.db.profile.tail4Color; return c[1], c[2], c[3], c[4] end,
                                set = function(info, r, g, b, a) self.db.profile.tail4Color = {r,g,b,a}; self:UpdateSparkColors() end,
                            },
                            intensity = {
                                name = "Intensity", type = "range", min=0, max=5, step=0.05, order = 2,
                                get = function(info) return self.db.profile.tail4Intensity end,
                                set = function(info, val) self.db.profile.tail4Intensity = val end,
                            },
                            length = {
                                name = "Length", type = "range", min=10, max=400, step=1, order = 3,
                                get = function(info) return self.db.profile.tail4Length end,
                                set = function(info, val) self.db.profile.tail4Length = val; self:UpdateSparkSize() end,
                            },
                        }
                    },
                }
            },
            integration = {
                name = "Integration",
                type = "group",
                order = 5,
                args = {
                    desc = { name = "Cooldown Manager (CDM) Integration", type = "description", order = 0 },
                    attachToCDM = {
                        name = "Attach to CDM", type = "toggle", order = 1,
                        get = function(info) return self.db.profile.attachToCDM end,
                        set = function(info, val) self.db.profile.attachToCDM = val; self:InitCDMHooks(); self:UpdateAnchor() end,
                    },
                    cdmTarget = {
                        name = "Target Frame", 
                        type = "select", 
                        values = {["Auto"]="Auto", ["Buffs"]="Buffs", ["Essential"]="Essential", ["Utility"]="Utility", ["Custom"]="Custom"}, 
                        order = 2,
                        get = function(info) return self.db.profile.cdmTarget end,
                        set = function(info, val) self.db.profile.cdmTarget = val; self:InitCDMHooks(); self:UpdateAnchor() end,
                    },
                    cdmFrameName = {
                        name = "Custom Frame Name", type = "input", order = 3,
                        desc = "E.g. MyCustomFrame or ElvUI_PlayerCastBar",
                        disabled = function() return self.db.profile.cdmTarget ~= "Custom" end,
                        get = function(info) return self.db.profile.cdmFrameName end,
                        set = function(info, val) self.db.profile.cdmFrameName = val; self:UpdateAnchor() end,
                    },
                    cdmYOffset = {
                        name = "Y Offset", type = "range", min = -100, max = 100, step = 1, order = 4,
                        get = function(info) return self.db.profile.cdmYOffset end,
                        set = function(info, val) self.db.profile.cdmYOffset = val; self:UpdateAnchor() end,
                    },
                }
            },
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
        }
    }
    
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, ADDON_NAME)
end
