-- AscensionCastBar.lua
-- Framework: Ace3
-- Author: AkaDoctorCode

local ADDON_NAME = "Ascension Cast Bar"
local AscensionCastBar = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

-- ==========================================================
-- CONSTANTS & DATA
-- ==========================================================

local CHANNEL_TICKS = {
    -- Existing
    ["Drain Life"] = 5, ["Drenar vida"] = 5,
    ["Mind Flay"] = 3, ["Tortura mental"] = 3,
    ["Penance"] = 3, ["Penitencia"] = 3,
    ["Arcane Missiles"] = 5, ["Misiles arcanos"] = 5,
    ["Hurricane"] = 10, ["Huracán"] = 10,
    ["Blizzard"] = 8, ["Ventisca"] = 8,
    ["Rain of Fire"] = 8, ["Lluvia de fuego"] = 8,
    ["Evocation"] = 4, ["Evocación"] = 4,
    ["Tranquility"] = 4, ["Tranquilidad"] = 4,
    ["Divine hymn"] = 4, ["Himno divino"] = 4,
    ["Fire Breath"] = 4, ["Aliento de fuego"] = 4,
    ["Eternity Surge"] = 4, ["Oleada de eternidad"] = 4,
    ["Dream Breath"] = 4, ["Aliento onírico"] = 4,
    ["Spiritbloom"] = 4, ["Flor de espíritu"] = 4,
    ["Upheaval"] = 4, ["Agitación"] = 4,
}

-- ==========================================================
-- DEFAULTS
-- ==========================================================

local BAR_DEFAULT_FONT_PATH = "Interface\\AddOns\\AscensionCastBar\\COLLEGIA.ttf"

local defaults = {
    profile = {
        width = 270, height = 24,
        point = "CENTER", relativePoint = "CENTER", x = 0, y = -85,
        
        -- UPDATED: Shield/Ticks/Colors
        showShield = true, 
        uninterruptibleColor = {0.4, 0.4, 0.4, 1},       
        uninterruptibleBorderGlow = true,                
        uninterruptibleGlowColor = {1, 0, 0, 1},         
        
        showChannelTicks = true, 
        channelTicksColor = {1, 1, 1, 0.5},
        channelTicksThickness = 1,
        
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
        
        -- Shield/Ticks
        showShield = true, uninterruptibleColor = {0.4, 0.4, 0.4, 1},
        showChannelTicks = true, channelTicksColor = {1, 1, 1, 0.5},
        
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
        previewEnabled = false, 
    }
}

-- ==========================================================
-- INITIALIZATION
-- ==========================================================

function AscensionCastBar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AscensionCastBarDB", defaults, "Default")
    
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    self:SetupOptions()
    self:CreateBar()
end

function AscensionCastBar:OnEnable()
    self:UpdateDefaultCastBarVisibility()
    self:InitCDMHooks()
    
    -- Register Events
    self:RegisterEvent("UNIT_SPELLCAST_START")
    self:RegisterEvent("UNIT_SPELLCAST_STOP")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateDefaultCastBarVisibility")
    
    -- Register Empower Events safely
    pcall(function()
        self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
        self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
        self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_UPDATE")
    end)
    
    self:RefreshConfig()
end

function AscensionCastBar:RefreshConfig()
    self:UpdateAnchor()
    self:UpdateSparkSize()
    self:UpdateIcon()
    self:ApplyFont()
    self:UpdateBarColor()
    self:UpdateBackground()
    self:UpdateBorder()
    self:UpdateTextLayout()
    self:UpdateSparkColors()
    self:UpdateDefaultCastBarVisibility()
end

-- ==========================================================
-- CORE FUNCTIONS
-- ==========================================================

function AscensionCastBar:ClampAlpha(v)
    v = tonumber(v) or 0
    if v < 0 then v = 0 elseif v > 1 then v = 1 end
    return v
end

function AscensionCastBar:GetBlizzardCastBars()
    local frames = {}
    if _G["CastingBarFrame"] then table.insert(frames, _G["CastingBarFrame"]) end
    if _G["PlayerCastingBarFrame"] then table.insert(frames, _G["PlayerCastingBarFrame"]) end
    return frames
end

function AscensionCastBar:UpdateDefaultCastBarVisibility()
    local hide = self.db.profile.hideDefaultCastbar
    local frames = self:GetBlizzardCastBars()

    for _, frame in ipairs(frames) do
        if frame then
            if hide then
                frame:UnregisterAllEvents()
                frame:Hide()
            else
                frame:RegisterEvent("UNIT_SPELLCAST_START")
                frame:RegisterEvent("UNIT_SPELLCAST_STOP")
                frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
                frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
            end
        end
    end
end

-- ==========================================================
-- FRAME CREATION & LOGIC
-- ==========================================================

function AscensionCastBar:CreateBar()
    local castBar = CreateFrame("StatusBar", "AscensionCastBarFrame", UIParent)
    castBar:SetClipsChildren(false) 
    castBar:SetSize(self.db.profile.width, self.db.profile.height)
    castBar:SetFrameStrata("MEDIUM"); castBar:SetFrameLevel(10); castBar:Hide()
    self.castBar = castBar

    -- Bar Texture
    castBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    
    -- Background
    castBar.bg = castBar:CreateTexture(nil,"BACKGROUND")
    castBar.bg:SetAllPoints()
    
    -- === NEW: GLOW FRAME (Fixed with BackdropTemplate) ===
    -- Added "BackdropTemplate" to the 4th argument so SetBackdrop works
    castBar.glowFrame = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
    castBar.glowFrame:SetFrameLevel(9) -- Below the main bar (Level 10)
    castBar.glowFrame:SetPoint("TOPLEFT", -6, 6)
    castBar.glowFrame:SetPoint("BOTTOMRIGHT", 6, -6)
    castBar.glowFrame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Glow", 
        edgeSize = 16,
    })
    castBar.glowFrame:Hide()
    -- =====================================================

    -- Ticks
    castBar.ticksFrame = CreateFrame("Frame", nil, castBar)
    castBar.ticksFrame:SetAllPoints()
    castBar.ticksFrame:SetFrameLevel(15)
    castBar.ticks = {}

    -- Icon & Shield & Latency
    castBar.icon = castBar:CreateTexture(nil,"OVERLAY")
    castBar.shield = castBar:CreateTexture(nil, "OVERLAY", nil, 5)
    castBar.shield:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
    castBar.shield:SetSize(16, 16); castBar.shield:Hide()
    castBar.latency = castBar:CreateTexture(nil, "OVERLAY", nil, 2)
    castBar.latency:Hide()

    -- Spark Components
    castBar.tailMask = CreateFrame("Frame", nil, castBar)
    castBar.tailMask:SetPoint("TOPLEFT", 0, 0); castBar.tailMask:SetPoint("BOTTOMLEFT", 0, 0)
    castBar.tailMask:SetClipsChildren(true)

    castBar.sparkHead = castBar:CreateTexture(nil, "OVERLAY", nil, 7)
    castBar.sparkHead:SetAtlas("pvpscoreboard-header-glow", true)
    castBar.sparkHead:SetBlendMode("ADD")
    if castBar.sparkHead.SetRotation then castBar.sparkHead:SetRotation(math.rad(90)) end

    -- Tails
    castBar.sparkTail = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail:SetAtlas("AftLevelup-SoftCloud", true); castBar.sparkTail:SetBlendMode("ADD")
    castBar.sparkTail2 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail2:SetAtlas("AftLevelup-SoftCloud", true); castBar.sparkTail2:SetTexCoord(0, 1, 1, 0); castBar.sparkTail2:SetBlendMode("ADD")
    castBar.sparkTail3 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail3:SetAtlas("AftLevelup-SoftCloud", true); castBar.sparkTail3:SetBlendMode("ADD")
    castBar.sparkTail4 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail4:SetAtlas("AftLevelup-SoftCloud", true); castBar.sparkTail4:SetTexCoord(0, 1, 1, 0); castBar.sparkTail4:SetBlendMode("ADD")
    
    castBar.sparkGlow = castBar:CreateTexture(nil, "OVERLAY", nil, 6)
    castBar.sparkGlow:SetTexture("Interface\\CastingBar\\UI-CastingBar-Pushback")
    castBar.sparkGlow:SetBlendMode("ADD")

    -- Text Context
    castBar.textCtx = CreateFrame("Frame", nil, castBar); castBar.textCtx:SetFrameLevel(20)
    castBar.textCtx.bg = castBar.textCtx:CreateTexture(nil, "BACKGROUND"); castBar.textCtx.bg:SetAllPoints()
    
    castBar.spellName = castBar.textCtx:CreateFontString(nil, "OVERLAY"); 
    castBar.spellName:SetDrawLayer("OVERLAY", 7); 
    castBar.spellName:SetJustifyH("LEFT")
    
    castBar.timer = castBar.textCtx:CreateFontString(nil, "OVERLAY"); 
    castBar.timer:SetDrawLayer("OVERLAY", 7); 
    castBar.timer:SetJustifyH("RIGHT")

    -- Borders
    castBar.border = { top=castBar:CreateTexture(nil,"OVERLAY"), bottom=castBar:CreateTexture(nil,"OVERLAY"), left=castBar:CreateTexture(nil,"OVERLAY"), right=castBar:CreateTexture(nil,"OVERLAY") }
    castBar.border.top:SetPoint("TOPLEFT",0,0); castBar.border.top:SetPoint("TOPRIGHT",0,0); 
    castBar.border.bottom:SetPoint("BOTTOMLEFT",0,0); castBar.border.bottom:SetPoint("BOTTOMRIGHT",0,0)
    castBar.border.left:SetPoint("TOPLEFT",0,0); castBar.border.left:SetPoint("BOTTOMLEFT",0,0); 
    castBar.border.right:SetPoint("TOPRIGHT",0,0); castBar.border.right:SetPoint("BOTTOMRIGHT",0,0)

    -- OnUpdate Loop
    castBar:SetScript("OnUpdate", function(f, elapsed) self:OnFrameUpdate(f, elapsed) end)
end

function AscensionCastBar:UpdateAnchor()
    if not self.castBar then return end
    local db = self.db.profile
    self.castBar:ClearAllPoints()
    local parentFrame, isAttached = nil, false
    
    if db.attachToCDM then
         local target = db.cdmTarget or "Auto"
         if target == "Essential" then 
            if _G["EssentialCooldownViewer"] and _G["EssentialCooldownViewer"]:IsShown() then parentFrame = _G["EssentialCooldownViewer"] end
         elseif target == "Utility" then 
            if _G["UtilityCooldownViewer"] and _G["UtilityCooldownViewer"]:IsShown() then parentFrame = _G["UtilityCooldownViewer"] end
         elseif target == "Custom" then 
            if db.cdmFrameName and db.cdmFrameName ~= "" then parentFrame = _G[db.cdmFrameName] end
         else -- Auto
             if _G["EssentialCooldownViewer"] and _G["EssentialCooldownViewer"]:IsShown() then parentFrame = _G["EssentialCooldownViewer"]
             elseif _G["UtilityCooldownViewer"] and _G["UtilityCooldownViewer"]:IsShown() then parentFrame = _G["UtilityCooldownViewer"]
             elseif db.cdmFrameName and db.cdmFrameName ~= "" then parentFrame = _G[db.cdmFrameName] end
         end
    end

    if parentFrame then
        isAttached = true
        self.castBar:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 0, db.cdmYOffset or -5)
        local w = parentFrame:GetWidth()
        if w and w > 1 then self.castBar:SetWidth(w) end
    else
        self.castBar:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y)
        self.castBar:SetWidth(db.width)
    end
    
    if self.castBar.ticksFrame then self.castBar.ticksFrame:SetWidth(self.castBar:GetWidth()) end
    self:UpdateSparkSize()
    self:UpdateTextLayout()
end

function AscensionCastBar:InitCDMHooks()
    if self.hooksDefined then return end
    local function OnCDMResize(_, width)
        if self.db.profile.attachToCDM then self:UpdateAnchor() end
    end
    
    if _G["EssentialCooldownViewer"] then 
        self:HookScript(_G["EssentialCooldownViewer"], "OnSizeChanged", OnCDMResize)
        self:HookScript(_G["EssentialCooldownViewer"], "OnShow", OnCDMResize)
        self:HookScript(_G["EssentialCooldownViewer"], "OnHide", OnCDMResize)
    end
    if _G["UtilityCooldownViewer"] then 
        self:HookScript(_G["UtilityCooldownViewer"], "OnSizeChanged", OnCDMResize)
        self:HookScript(_G["UtilityCooldownViewer"], "OnShow", OnCDMResize)
        self:HookScript(_G["UtilityCooldownViewer"], "OnHide", OnCDMResize)
    end
    self.hooksDefined = true
end

-- ==========================================================
-- VISUAL UPDATES
-- ==========================================================

function AscensionCastBar:UpdateBackground()
    local c = self.db.profile.bgColor
    self.castBar.bg:SetColorTexture(c[1], c[2], c[3], c[4])
end

function AscensionCastBar:UpdateBorder()
    local db = self.db.profile
    local t, c = db.borderThickness, db.borderColor
    for _, tx in pairs(self.castBar.border) do 
        tx:SetShown(db.borderEnabled)
        tx:SetColorTexture(c[1],c[2],c[3],c[4]) 
    end
    self.castBar.border.top:SetHeight(t); self.castBar.border.bottom:SetHeight(t)
    self.castBar.border.left:SetWidth(t); self.castBar.border.right:SetWidth(t)
end

function AscensionCastBar:UpdateBarColor(isUninterruptible)
    local db = self.db.profile
    local cb = self.castBar
    
    if not cb.glowFrame then return end -- Safety check
    cb.glowFrame:Hide()

    -- 1. Uninterruptible (Shield)
    if isUninterruptible and db.showShield then 
        local c = db.uninterruptibleColor
        cb:SetStatusBarColor(c[1], c[2], c[3], c[4])
        
        if db.uninterruptibleBorderGlow then
            local gc = db.uninterruptibleGlowColor
            cb.glowFrame:SetBackdropBorderColor(gc[1], gc[2], gc[3], gc[4])
            cb.glowFrame:Show()
        end

    -- 2. Channeling
    elseif cb.channeling and db.useChannelColor then
        local c = db.channelColor
        cb:SetStatusBarColor(c[1], c[2], c[3], c[4])
        
        if db.channelBorderGlow then
            local gc = db.channelGlowColor
            cb.glowFrame:SetBackdropBorderColor(gc[1], gc[2], gc[3], gc[4])
            cb.glowFrame:Show()
        end

    -- 3. Standard
    elseif db.useClassColor then 
        local _, playerClass = UnitClass("player")
        local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerClass]) or {r=1,g=1,b=1}
        cb:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
    else 
        local c = db.barColor
        cb:SetStatusBarColor(c[1], c[2], c[3], c[4]) 
    end
    
    local tex = LSM:Fetch("statusbar", db.barLSMName) or "Interface\\TARGETINGFRAME\\UI-StatusBar"
    cb:SetStatusBarTexture(tex)
end

function AscensionCastBar:UpdateIcon()
    local db = self.db.profile
    if db.showIcon then
        self.castBar.icon:Show()
        local h = db.height
        if db.detachIcon then 
            self.castBar.icon:SetSize(db.iconSize, db.iconSize)
            self.castBar.icon:ClearAllPoints()
            if db.iconAnchor == "Left" then 
                self.castBar.icon:SetPoint("RIGHT", self.castBar, "LEFT", db.iconX, db.iconY) 
            else 
                self.castBar.icon:SetPoint("LEFT", self.castBar, "RIGHT", db.iconX, db.iconY) 
            end
        else 
            self.castBar.icon:SetSize(h, h)
            self.castBar.icon:ClearAllPoints()
            if db.iconAnchor == "Left" then 
                self.castBar.icon:SetPoint("LEFT", self.castBar, "LEFT", 0, 0) 
            else 
                self.castBar.icon:SetPoint("RIGHT", self.castBar, "RIGHT", 0, 0) 
            end
        end
    else 
        self.castBar.icon:Hide() 
    end
    if not db.detachText then self:UpdateTextLayout() end
end

function AscensionCastBar:UpdateTextLayout()
    local db = self.db.profile
    local cb = self.castBar
    if not cb.textCtx then return end
    
    if db.detachText then
        cb.textCtx:ClearAllPoints()
        cb.textCtx:SetPoint("CENTER", UIParent, "CENTER", db.textX, db.textY)
        cb.textCtx:SetSize(db.textWidth, db.spellNameFontSize + 6)
        local c = db.textBackdropColor
        cb.textCtx.bg:SetColorTexture(c[1],c[2],c[3], db.textBackdropEnabled and c[4] or 0)
        
        cb.spellName:ClearAllPoints(); cb.spellName:SetPoint("LEFT", cb.textCtx, "LEFT", 5, 0); cb.spellName:SetPoint("RIGHT", cb.timer, "LEFT", -5, 0)
        cb.timer:ClearAllPoints(); cb.timer:SetPoint("RIGHT", cb.textCtx, "RIGHT", -5, 0)
    else
        cb.textCtx:ClearAllPoints(); cb.textCtx:SetAllPoints(cb); cb.textCtx.bg:SetColorTexture(0,0,0,0)
        cb.spellName:ClearAllPoints(); cb.timer:ClearAllPoints()
        
        local iconW = 0
        if db.showIcon and not db.detachIcon then iconW = db.height end
        
        if iconW > 0 then
            if db.iconAnchor == "Left" then 
                cb.spellName:SetPoint("LEFT", cb.textCtx, "LEFT", iconW + 6, 0)
                cb.timer:SetPoint("RIGHT", cb.textCtx, "RIGHT", -5, 0)
            else 
                cb.spellName:SetPoint("LEFT", cb.textCtx, "LEFT", 5, 0)
                cb.timer:SetPoint("RIGHT", cb.textCtx, "RIGHT", -iconW - 5, 0) 
            end
        else 
            cb.spellName:SetPoint("LEFT", cb.textCtx, "LEFT", 5, 0)
            cb.timer:SetPoint("RIGHT", cb.textCtx, "RIGHT", -5, 0) 
        end
    end
end

function AscensionCastBar:ApplyFont()
    local db = self.db.profile
    local cb = self.castBar
    local r,g,b,a = unpack(db.fontColor)
    local sP = LSM:Fetch("font", db.spellNameFontLSM) or db.fontPath
    local tP = LSM:Fetch("font", db.timerFontLSM) or db.fontPath
    
    cb.spellName:SetFont(sP, db.spellNameFontSize, "OUTLINE")
    cb.spellName:SetTextColor(r,g,b,a)
    
    cb.timer:SetFont(tP, db.timerFontSize, "OUTLINE")
    cb.timer:SetTextColor(r,g,b,a)
end

-- ==========================================================
-- ANIMATION / SPARK ENGINE
-- ==========================================================

function AscensionCastBar:UpdateSparkColors()
    local db = self.db.profile
    local s, g = db.sparkColor, db.glowColor
    self.castBar.sparkHead:SetVertexColor(s[1], s[2], s[3], s[4])
    self.castBar.sparkGlow:SetVertexColor(g[1], g[2], g[3], g[4])
    
    local t1, t2, t3, t4 = db.tail1Color, db.tail2Color, db.tail3Color, db.tail4Color
    self.castBar.sparkTail:SetVertexColor(t1[1],t1[2],t1[3],t1[4])
    self.castBar.sparkTail2:SetVertexColor(t2[1],t2[2],t2[3],t2[4])
    self.castBar.sparkTail3:SetVertexColor(t3[1],t3[2],t3[3],t3[4])
    self.castBar.sparkTail4:SetVertexColor(t4[1],t4[2],t4[3],t4[4])
end

function AscensionCastBar:UpdateSparkSize()
    local db = self.db.profile
    local sc, h = db.sparkScale, db.height
    local cb = self.castBar
    
    cb.sparkHead:SetSize(32*sc, h*2*sc)
    cb.sparkGlow:SetSize(190*sc, h*2.4)
    cb.sparkTail:SetSize(db.tail1Length*sc, h*1.4)
    cb.sparkTail2:SetSize(db.tail2Length*sc, h*1.1)
    cb.sparkTail3:SetSize(db.tail3Length*sc, h*1.4)
    cb.sparkTail4:SetSize(db.tail4Length*sc, h*1.1)
    
    if cb.tailMask then cb.tailMask:SetWidth(cb:GetWidth()) end
end

function AscensionCastBar:ResetParticles()
    if self.castBar.particles then 
        for _, p in ipairs(self.castBar.particles) do p:Hide() end 
    end
    self.castBar.lastParticleTime = 0
end

function AscensionCastBar:UpdateSpark(progress, tailProgress)
    local db = self.db.profile
    local castBar = self.castBar
    
    -- Cleanup overlays
    if castBar.waveOverlay then castBar.waveOverlay:Hide() end
    if castBar.scanLine then castBar.scanLine:Hide() end
    if castBar.rainbowOverlay then castBar.rainbowOverlay:Hide() end
    if castBar.glitchLayers then for _, g in ipairs(castBar.glitchLayers) do g:Hide() end end
    if castBar.lightningSegments then for _, l in ipairs(castBar.lightningSegments) do l:Hide() end end
    if db.animStyle ~= "Particles" and castBar.particles then for _, p in ipairs(castBar.particles) do p:Hide() end end

    if not db.enableSpark or not progress or progress<=0 or progress>=1 then 
        castBar.sparkHead:Hide(); castBar.sparkGlow:Hide()
        castBar.sparkTail:Hide(); castBar.sparkTail2:Hide()
        castBar.sparkTail3:Hide(); castBar.sparkTail4:Hide()
        return 
    end

    local w = castBar:GetWidth()
    local style = db.animStyle
    local offset = w * progress
    local b = db.borderEnabled and db.borderThickness or 0
    local tP = tailProgress or 0
    local time = GetTime()
    
    local effOffset = (db.headLengthOffset) * (w / (270)) 
    castBar.sparkHead:ClearAllPoints()
    castBar.sparkHead:SetPoint("CENTER", castBar, "LEFT", offset + db.sparkOffset + effOffset, 0)
    castBar.sparkHead:SetAlpha(self:ClampAlpha(db.sparkIntensity))
    castBar.sparkHead:Show()
    castBar.sparkGlow:ClearAllPoints()
    castBar.sparkGlow:SetPoint("CENTER", castBar.sparkHead, "CENTER", 0, 0)

    if castBar.tailMask then
        local aw = offset - (b>0 and b or 0)
        if aw < 0 then aw = 0 end
        if aw > w then aw = w end
        castBar.tailMask:SetWidth(aw)
    end

    if not db.enableTails or (style == "Wave" or style == "Scanline" or style == "Rainbow" or style == "Glitch") then
         castBar.sparkTail:Hide(); castBar.sparkTail2:Hide(); castBar.sparkTail3:Hide(); castBar.sparkTail4:Hide()
    end

    -- STYLE: ORB
    if style == "Orb" then
        castBar.sparkGlow:Show()
        local rotSpeed = time * 8
        local radius = db.height * 0.4 
        local function SpinOrb(tex, angleOffset, intense)
            tex:ClearAllPoints()
            local x = math.cos(rotSpeed + angleOffset) * radius
            local y = math.sin(rotSpeed + angleOffset) * radius
            tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", x, y)
            tex:SetAlpha(self:ClampAlpha(intense) * 1.0)
            tex:Show()
        end
        if db.enableTails then
            SpinOrb(castBar.sparkTail, 0, db.tail1Intensity)
            SpinOrb(castBar.sparkTail2, math.pi/2, db.tail2Intensity)
            SpinOrb(castBar.sparkTail3, math.pi, db.tail3Intensity)
            SpinOrb(castBar.sparkTail4, -math.pi/2, db.tail4Intensity)
        end
        local pulse = 0.5 + 0.5 * math.sin(time * 8)
        castBar.sparkGlow:SetAlpha(self:ClampAlpha(db.glowIntensity) * (0.6 + 0.4*pulse))

    -- STYLE: VORTEX
    elseif style == "Vortex" then
        castBar.sparkGlow:Show()
        local radius = db.height * 0.9
        local speed = 8
        local function Orbit(tex, idx, intense)
            tex:ClearAllPoints()
            local angle = (time * speed) + (offset * 0.05) - (idx * 0.8)
            local r = radius * (1 - (idx * 0.2))
            local x = math.cos(angle) * r
            local y = math.sin(angle) * r
            tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", x, y)
            tex:SetSize(db.height * 0.7, db.height * 0.7)
            tex:SetAlpha(self:ClampAlpha(intense) * tP)
            tex:Show()
        end
        if db.enableTails then
            Orbit(castBar.sparkTail, 0, db.tail1Intensity)
            Orbit(castBar.sparkTail2, 1, db.tail2Intensity)
            Orbit(castBar.sparkTail3, 2, db.tail3Intensity)
            Orbit(castBar.sparkTail4, 3, db.tail4Intensity)
        end

    -- STYLE: PULSE
    elseif style == "Pulse" then
        castBar.sparkGlow:Show()
        local maxScale = 2.5
        local function Ripple(tex, offsetTime, intense)
            tex:ClearAllPoints()
            tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", 0, 0)
            local cycle = (time + offsetTime) % 1
            local size = db.height * 2 * (0.2 + cycle * maxScale) 
            tex:SetSize(size, size)
            local fade = 1 - (cycle * cycle)
            tex:SetAlpha(self:ClampAlpha(intense) * fade)
            tex:Show()
        end
        if db.enableTails then
            Ripple(castBar.sparkTail, 0.0, db.tail1Intensity)
            Ripple(castBar.sparkTail2, 0.3, db.tail2Intensity)
            Ripple(castBar.sparkTail3, 0.6, db.tail3Intensity)
            Ripple(castBar.sparkTail4, 0.9, db.tail4Intensity)
        end

    -- STYLE: STARFALL
    elseif style == "Starfall" then
         castBar.sparkGlow:Hide()
         local h = db.height
         local function Fall(tex, driftBase, speed, intense)
             tex:ClearAllPoints()
             local fallY = -((time * speed * 15) % (h*2.5)) + h
             local sway = math.sin(time * 3 + driftBase) * 8 
             tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", driftBase + sway, fallY)
             tex:SetAlpha(self:ClampAlpha(intense) * (1 - math.abs(fallY)/(h*1.5)))
             tex:Show()
         end
         if db.enableTails then
             Fall(castBar.sparkTail, -10, 2.5, db.tail1Intensity)
             Fall(castBar.sparkTail2, 10, 3.8, db.tail2Intensity)
             Fall(castBar.sparkTail3, -20, 1.5, db.tail3Intensity)
             Fall(castBar.sparkTail4, 20, 3.0, db.tail4Intensity)
         end

    -- STYLE: FLUX
    elseif style == "Flux" then
        castBar.sparkGlow:Hide() 
        local dm = w * 0.05
        local jitterY = 3.5
        local jitterX = 2.5
        local function Flux(tex, baseOff, drift, intense)
            tex:ClearAllPoints()
            local rY = (math.random() * jitterY * 2) - jitterY
            local rX = (math.random() * jitterX * 2) - jitterX
            local x = math.max(b, math.min(w-b, offset - baseOff + drift + rX))
            tex:SetPoint("CENTER", castBar.tailMask, "LEFT", x, rY)
            tex:SetAlpha(self:ClampAlpha(intense) * tP)
            tex:Show()
        end
        if db.enableTails then
            Flux(castBar.sparkTail, 20, -dm*tP, db.tail1Intensity)
            Flux(castBar.sparkTail2, 35, dm*tP, db.tail2Intensity)
            Flux(castBar.sparkTail3, 20, -dm*tP, db.tail3Intensity)
            Flux(castBar.sparkTail4, 35, dm*tP, db.tail4Intensity)
        end

    -- STYLE: HELIX
    elseif style == "Helix" then
         castBar.sparkGlow:Show()
         local dm = w * 0.1
         local amp = db.height * 0.4
         local waveSpeed = 8
         local sv = math.sin(time * waveSpeed + (offset * 0.05)) * amp
         local cv = math.cos(time * waveSpeed + (offset * 0.05)) * amp
         local function Helix(tex, baseOff, drift, yOff, intense)
             tex:ClearAllPoints()
             local x = math.max(b, math.min(w-b, offset - baseOff + drift))
             tex:SetPoint("CENTER", castBar.tailMask, "LEFT", x, yOff)
             tex:SetAlpha(self:ClampAlpha(intense) * tP)
             tex:Show()
         end
         if db.enableTails then
             Helix(castBar.sparkTail, 20, -dm*tP, sv, db.tail1Intensity)
             Helix(castBar.sparkTail2, 35, dm*tP, -sv, db.tail2Intensity)
             Helix(castBar.sparkTail3, 25, -dm*tP, cv, db.tail3Intensity)
             Helix(castBar.sparkTail4, 30, dm*tP, -cv, db.tail4Intensity)
         end

    -- STYLE: WAVE
    elseif style == "Wave" then
        castBar.sparkGlow:Hide()
        castBar.sparkHead:Hide() 
        if not castBar.waveOverlay then
            castBar.waveOverlay = castBar:CreateTexture(nil, "ARTWORK")
            castBar.waveOverlay:SetBlendMode("ADD")
            castBar.waveOverlay:SetAllPoints()
            castBar.waveOverlay:SetGradient("HORIZONTAL", CreateColor(1,1,1,0), CreateColor(1,1,1,0.5), CreateColor(1,1,1,0))
        end
        local wOff = (time * 2.0) % 1
        castBar.waveOverlay:SetTexCoord(wOff, wOff + 1, 0, 1)
        local wH = 5 * math.sin(time * 2) 
        castBar.waveOverlay:ClearAllPoints()
        castBar.waveOverlay:SetPoint("TOPLEFT", castBar, "TOPLEFT", 0, wH)
        castBar.waveOverlay:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 0, wH)
        local wc = db.tail2Color
        castBar.waveOverlay:SetVertexColor(wc[1], wc[2], wc[3], 0.3 * (0.5 + progress * 0.5))
        castBar.waveOverlay:Show()

    -- STYLE: PARTICLES
    elseif style == "Particles" then
         castBar.sparkGlow:Show()
         if not castBar.particles then castBar.particles = {} end
         if not castBar.lastParticleTime then castBar.lastParticleTime = 0 end
         if (time - castBar.lastParticleTime) > 0.05 then
             local p = nil
             for _, v in ipairs(castBar.particles) do if not v:IsShown() then p=v; break end end
             if not p then 
                p = castBar.tailMask:CreateTexture(nil, "OVERLAY")
                p:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
                p:SetBlendMode("ADD")
                table.insert(castBar.particles, p)
             end
             p.life = 1.0
             p.sx = offset
             p.sy = 0
             p.vx = (math.random()-0.5)*10
             p.vy = 20 + math.random()*30
             p:SetSize(8,8)
             p:Show()
             castBar.lastParticleTime = time
         end
         for _, p in ipairs(castBar.particles) do
             if p:IsShown() then
                 p.life = p.life - 0.05
                 if p.life <= 0 then 
                    p:Hide() 
                 else
                     p.sx = p.sx + p.vx * 0.05
                     p.sy = p.sy + p.vy * 0.05
                     p:ClearAllPoints()
                     p:SetPoint("CENTER", castBar.tailMask, "LEFT", p.sx, p.sy)
                     local pc = db.sparkColor
                     p:SetVertexColor(pc[1], pc[2], pc[3], p.life)
                 end
             end
         end

    -- STYLE: SCANLINE
    elseif style == "Scanline" then
         castBar.sparkHead:Hide()
         castBar.sparkGlow:Hide()
         if not castBar.scanLine then
             castBar.scanLine = castBar:CreateTexture(nil, "OVERLAY")
             castBar.scanLine:SetColorTexture(1, 1, 1, 1)
             castBar.scanLine:SetBlendMode("ADD")
             castBar.scanLine:SetSize(4, db.height)
         end
         local slP = (time % 1.5) / 1.5
         if slP > 0.5 then slP = 1 - slP end
         local slX = w * ((math.sin(time * 3) + 1) / 2)
         castBar.scanLine:ClearAllPoints()
         castBar.scanLine:SetPoint("CENTER", castBar, "LEFT", slX, 0)
         local sc = db.tail1Color
         castBar.scanLine:SetVertexColor(sc[1], sc[2], sc[3], 0.8)
         castBar.scanLine:Show()

    -- STYLE: GLITCH
    elseif style == "Glitch" then
         castBar.sparkHead:Hide()
         if not castBar.glitchLayers then
             castBar.glitchLayers = {}
             for i=1,3 do 
                local g = castBar:CreateTexture(nil,"OVERLAY")
                g:SetColorTexture(1,1,1,0.2)
                g:SetBlendMode("ADD")
                table.insert(castBar.glitchLayers, g) 
            end
         end
         for i, g in ipairs(castBar.glitchLayers) do
             if math.random() < 0.1 then
                 local r = math.random()>0.5 and 1 or 0
                 local gr = math.random()>0.5 and 1 or 0
                 local bl = math.random()>0.5 and 1 or 0
                 g:SetVertexColor(r,gr,bl, 0.3)
                 g:ClearAllPoints()
                 local ox = math.random(-5,5)
                 local oy = math.random(-2,2)
                 g:SetPoint("TOPLEFT", castBar, "TOPLEFT", ox, oy)
                 g:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", ox, oy)
                 g:Show()
             else 
                g:Hide() 
            end
         end

    -- STYLE: LIGHTNING
    elseif style == "Lightning" then
         castBar.sparkGlow:Show()
         if not castBar.lightningSegments then castBar.lightningSegments = {} end
         for i=1, 3 do
             local l = castBar.lightningSegments[i]
             if not l then 
                l = castBar:CreateTexture(nil, "OVERLAY")
                l:SetColorTexture(1,1,1,1)
                l:SetBlendMode("ADD")
                castBar.lightningSegments[i] = l 
             end
             if math.random() < 0.3 then
                 local tx = math.random(0, w)
                 local ty = math.random(0, db.height)
                 local dx = tx - offset
                 local dy = ty - (db.height/2)
                 local len = math.sqrt(dx*dx + dy*dy)
                 local ang = math.atan2(dy, dx)
                 l:SetSize(len, 2)
                 l:ClearAllPoints()
                 l:SetPoint("CENTER", castBar, "LEFT", offset, 0)
                 l:SetRotation(ang)
                 local lc = db.tail3Color
                 l:SetVertexColor(lc[1], lc[2], lc[3], 0.6)
                 l:Show()
             else 
                l:Hide() 
            end
         end

    -- STYLE: RAINBOW
    elseif style == "Rainbow" then
         castBar.sparkHead:Hide()
         castBar.sparkGlow:Hide()
         if not castBar.rainbowOverlay then
             castBar.rainbowOverlay = castBar:CreateTexture(nil, "ARTWORK")
             castBar.rainbowOverlay:SetBlendMode("ADD")
             castBar.rainbowOverlay:SetAllPoints()
             castBar.rainbowOverlay:SetGradient("HORIZONTAL", CreateColor(1,0,0,1), CreateColor(1,1,0,1), CreateColor(0,1,0,1), CreateColor(0,1,1,1), CreateColor(0,0,1,1), CreateColor(1,0,1,1))
         end
         local ro = (time * 0.5) % 1
         castBar.rainbowOverlay:SetTexCoord(ro, ro+1, 0, 1)
         castBar.rainbowOverlay:SetAlpha(0.3 + progress * 0.7)
         castBar.rainbowOverlay:Show()

    -- DEFAULT: COMET
    else 
        castBar.sparkGlow:Show()
        local function Comet(tex, rel_pos, int)
            tex:ClearAllPoints()
            local trailX = offset - (rel_pos * w) 
            tex:SetPoint("CENTER", castBar.tailMask, "LEFT", math.max(b, math.min(w-b, trailX)), 0)
            tex:SetAlpha(self:ClampAlpha(int)*tP)
            tex:Show()
        end
        if db.enableTails then
            Comet(castBar.sparkTail, 0.05, db.tail1Intensity)
            Comet(castBar.sparkTail2, 0.10, db.tail2Intensity)
            Comet(castBar.sparkTail3, 0.15, db.tail3Intensity)
            Comet(castBar.sparkTail4, 0.20, db.tail4Intensity)
        end
    end
end

-- ==========================================================
-- EVENT HANDLERS
-- ==========================================================

function AscensionCastBar:HideTicks() 
    for _, tick in ipairs(self.castBar.ticks) do tick:Hide() end 
end

function AscensionCastBar:UpdateTicks(spellName, duration)
    self:HideTicks()
    if not self.db.profile.showChannelTicks then return end
    
    local count = CHANNEL_TICKS[spellName]
    if not count or count < 1 then return end
    
    local db = self.db.profile
    local c = db.channelTicksColor
    local thickness = db.channelTicksThickness or 1 -- Use the new setting
    local w = self.castBar:GetWidth() / count
    
    for i = 1, count - 1 do
         local tick = self.castBar.ticks[i]
         if not tick then 
            tick = self.castBar.ticksFrame:CreateTexture(nil, "OVERLAY")
            self.castBar.ticks[i] = tick 
        end
         tick:ClearAllPoints()
         tick:SetPoint("CENTER", self.castBar, "LEFT", w * i, 0)
         tick:SetSize(thickness, self.castBar:GetHeight()) -- Apply thickness here
         tick:SetColorTexture(c[1], c[2], c[3], c[4])
         tick:Show()
    end
end

function AscensionCastBar:UpdateLatencyBar(castBar)
    local db = self.db.profile
    if not db.showLatency then castBar.latency:Hide() return end
    if not (castBar.casting or castBar.channeling) then castBar.latency:Hide() return end
    
    local _, _, homeMS, worldMS = GetNetStats()
    local ms = math.max(homeMS or 0, worldMS or 0)
    if ms <= 0 then castBar.latency:Hide() return end
    
    local frac = (ms / 1000) / (castBar.duration or 1)
    if frac > db.latencyMaxPercent then frac = db.latencyMaxPercent end
    
    local w = castBar:GetWidth() * frac
    local minW = 2
    if w < minW then w = minW end
    if w <= 0.5 then castBar.latency:Hide() return end
    
    castBar.latency:ClearAllPoints()
    local b = db.borderEnabled and db.borderThickness or 0
    
    -- Determine direction
    local isFilling = false
    if castBar.isEmpowered or castBar.casting then 
        isFilling = true
    elseif castBar.channeling and db.reverseChanneling then
        isFilling = true
    end

    if not isFilling then 
        -- Emptying (Left)
        castBar.latency:SetPoint("TOPLEFT", castBar, "TOPLEFT", b, -b)
        castBar.latency:SetPoint("BOTTOMLEFT", castBar, "BOTTOMLEFT", b, b)
    else 
        -- Filling (Right)
        castBar.latency:SetPoint("TOPRIGHT", castBar, "TOPRIGHT", -b, -b)
        castBar.latency:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", -b, b)
    end
    
    castBar.latency:SetWidth(w)
    local c = db.latencyColor
    castBar.latency:SetColorTexture(c[1],c[2],c[3],c[4])
    castBar.latency:Show()
end

-- Shared Logic helper
function AscensionCastBar:HandleCastStart(unit, channel, empowered)
    if unit and unit~="player" then return end
    local db = self.db.profile
    local cb = self.castBar
    
    local name, _, texture, startMS, endMS, notInt
    local startTime, endTime
    
    -- 1. GET CAST INFO
    if empowered then
        -- FIX: Empowered spells are now Channels in 11.0+
        name, _, texture, startMS, endMS, _, _, _, notInt = UnitChannelInfo("player")
    elseif channel then
        -- Standard Channel
        name, _, texture, startMS, endMS, _, _, _, notInt = UnitChannelInfo("player")
    else
        -- Standard Cast
        name, _, texture, startMS, endMS, _, _, _, notInt = UnitCastingInfo("player")
    end
    
    -- 2. VALIDATE & CALCULATE TIMES
    if not name then return end
    
    if not startMS or not endMS then return end
    endTime = endMS / 1000
    startTime = startMS / 1000
    cb.duration = (endMS - startMS) / 1000

    -- 3. SETUP BAR STATE
    cb.casting = not channel
    cb.channeling = channel
    cb.isEmpowered = empowered
    
    -- Detect simulated empower via channel (Ascension mechanic fallback)
    if channel and EMPOWERED_SPELLS[name] then cb.isEmpowered = true end

    cb.startTime = startTime
    cb.endTime = endTime
    
    -- 4. UPDATE TEXT
    local displayName = name
    if db.truncateSpellName and #name > db.truncateLength then
        displayName = string.sub(name, 1, db.truncateLength).."..."
    end
    
    cb.spellName:SetText(db.showSpellText and displayName or "")
    if db.showIcon and texture then 
        cb.icon:SetTexture(texture); cb.icon:Show() 
    else 
        cb.icon:Hide() 
    end
    
    -- 5. UPDATE VISUALS
    if notInt and db.showShield then cb.shield:Show() else cb.shield:Hide() end
    
    if channel or empowered then 
        self:UpdateTicks(name, cb.duration) 
    else 
        self:HideTicks() 
    end
    
    self:ApplyFont()
    self:UpdateBarColor(notInt)
    self:UpdateBorder()
    self:UpdateBackground()
    self:UpdateIcon()
    self:UpdateSparkColors()
    
    cb:Show()
    cb.latency:Hide()
    self:ResetParticles()
end

function AscensionCastBar:UNIT_SPELLCAST_START(event, unit)
    self:HandleCastStart(unit, false, false)
end

function AscensionCastBar:UNIT_SPELLCAST_EMPOWER_START(event, unit)
    self:HandleCastStart(unit, false, true)
end

function AscensionCastBar:UNIT_SPELLCAST_CHANNEL_START(event, unit)
    self:HandleCastStart(unit, true, false)
end

function AscensionCastBar:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit)
    if unit and unit~="player" then return end
    local _, _, _, startMS, endMS = UnitChannelInfo("player")
    if startMS then 
        self.castBar.startTime = startMS/1000
        self.castBar.endTime = endMS/1000
        self.castBar.duration = self.castBar.endTime - self.castBar.startTime 
    end
end

function AscensionCastBar:UNIT_SPELLCAST_EMPOWER_UPDATE(event, unit)
    if unit and unit~="player" then return end
    local _, _, _, startMS, endMS = UnitEmpowerCastingInfo("player")
    if startMS then 
        self.castBar.startTime = startMS/1000
        self.castBar.endTime = endMS/1000
        self.castBar.duration = self.castBar.endTime - self.castBar.startTime 
    end
end

function AscensionCastBar:StopCast()
    local cb = self.castBar
    -- Check if another channel started immediately (chained casts)
    local cname, _, ctex, cstartMS, cendMS, _, _, _, cNotInt = UnitChannelInfo("player")
    if cname then
        self:HandleCastStart("player", true, false)
        return
    end
    
    -- Check if standard cast exists
    local name, _, texture, startMS, endMS, _, _, _, notInt = UnitCastingInfo("player")
    if name then
        self:HandleCastStart("player", false, false)
        return
    end
    
    cb.casting=false; cb.channeling=false
    cb.spellName:SetText(""); cb.timer:SetText("")
    cb.icon:Hide(); cb.shield:Hide()
    self:HideTicks()
    self:UpdateSpark(0,0)
    cb:Hide()
end

function AscensionCastBar:UNIT_SPELLCAST_STOP(event, unit) if unit=="player" then self:StopCast() end end
function AscensionCastBar:UNIT_SPELLCAST_FAILED(event, unit) if unit=="player" then self:StopCast() end end
function AscensionCastBar:UNIT_SPELLCAST_INTERRUPTED(event, unit) if unit=="player" then self:StopCast() end end
function AscensionCastBar:UNIT_SPELLCAST_CHANNEL_STOP(event, unit) if unit=="player" then self:StopCast() end end
function AscensionCastBar:UNIT_SPELLCAST_EMPOWER_STOP(event, unit) if unit=="player" then self:StopCast() end end


-- ==========================================================
-- ON UPDATE (ANIMATION LOOP)
-- ==========================================================

function AscensionCastBar:OnFrameUpdate(selfFrame, elapsed)
    local now = GetTime()
    local db = self.db.profile
    
    local function GetFmtTimer(rem, dur)
        if not db.showTimerText then return "" end
        local f = db.timerFormat
        if f == "Duration" then 
            return string.format("%.1f / %.1f", math.max(0, rem), dur) 
        elseif f == "Total" then 
            return string.format("%.1f", dur) 
        else 
            return string.format("%.1f", math.max(0, rem)) 
        end
    end

    -- Updated helper to handle Spark Direction
    local function Upd(val, dur, forceEmptying)
        selfFrame:SetMinMaxValues(0, dur)
        selfFrame:SetValue(val)
        local prog = 0
        if dur > 0 then prog = val / dur end
        
        -- Determine if bar is emptying (Standard Channel) or Filling (Cast/Reverse)
        local isEmptying = forceEmptying
        if isEmptying == nil then
             isEmptying = (selfFrame.channeling and not selfFrame.isEmpowered and not db.reverseChanneling)
        end
        
        -- Spark moves backwards if emptying
        self:UpdateSpark(prog, isEmptying and (1-prog) or prog)
    end

    -- ==========================================================
    -- TEST MODE LOGIC (Now simulates all features)
    -- ==========================================================
    if db.previewEnabled and not selfFrame.casting and not selfFrame.channeling then
        if not selfFrame.previewStart then selfFrame.previewStart = now end
        local dur = 3.0
        local elap = (now - selfFrame.previewStart) % dur
        
        selfFrame.spellName:SetText("Preview Spell")
        
        -- 1. Simulate Channel Behavior
        -- If Ticks are enabled, we assume the user wants to see a "Channel".
        -- If "Reverse" is OFF, channels should Empty. If ON, they Fill.
        local simulateChannel = db.showChannelTicks
        local isReverse = db.reverseChanneling
        local isFilling = true 
        
        if simulateChannel and not isReverse then
            isFilling = false -- Standard channel simulation (Emptying)
        end
        
        -- Calculate Value based on direction
        local val = elap
        if not isFilling then
             val = dur - elap
             selfFrame.timer:SetText(GetFmtTimer(val, dur))
        else
             selfFrame.timer:SetText(GetFmtTimer(dur - val, dur))
        end
        
        -- Update Bar & Spark
        Upd(val, dur, not isFilling)
        
        -- 2. Force Ticks (Simulate 'Drain Life' ticks)
        if db.showChannelTicks then
            self:UpdateTicks("Drain Life", dur) 
        else
            self:HideTicks()
        end

        -- 3. Force Latency Display
        if db.showLatency then
             local w = selfFrame:GetWidth()
             local latWidth = w * 0.15 -- Mock 15% latency
             local b = db.borderEnabled and db.borderThickness or 0
             
             selfFrame.latency:ClearAllPoints()
             if not isFilling then
                -- Emptying: Latency on Left
                selfFrame.latency:SetPoint("TOPLEFT", selfFrame, "TOPLEFT", b, -b)
                selfFrame.latency:SetPoint("BOTTOMLEFT", selfFrame, "BOTTOMLEFT", b, b)
             else
                -- Filling: Latency on Right
                selfFrame.latency:SetPoint("TOPRIGHT", selfFrame, "TOPRIGHT", -b, -b)
                selfFrame.latency:SetPoint("BOTTOMRIGHT", selfFrame, "BOTTOMRIGHT", -b, b)
             end
             selfFrame.latency:SetWidth(latWidth)
             local c = db.latencyColor
             selfFrame.latency:SetColorTexture(c[1],c[2],c[3],c[4])
             selfFrame.latency:Show()
        else
            selfFrame.latency:Hide()
        end
        
        -- Force updates for live editing
        self:UpdateBorder(); self:UpdateBackground(); self:UpdateIcon(); self:UpdateSparkColors()
        
        -- === SIMULATE COMBAT / CHANNEL FEATURES ===
        local isUnint = false
        
        -- If simulating Shield, force Uninterruptible color/glow
        if db.showShield then
            selfFrame.shield:Show()
            isUnint = true
        else
            selfFrame.shield:Hide()
        end
        
        -- If simulating Ticks (Channel), force Channel color/glow (if shield is off)
        -- We temporarily set .channeling to true for the Color Update function to detect it
        if db.showChannelTicks and not isUnint then
             selfFrame.channeling = true 
        else
             selfFrame.channeling = false
        end
        
        self:UpdateBarColor(isUnint) -- Apply Colors/Glows
        selfFrame.channeling = false -- Reset state after update so logic doesn't break
        -- ==========================================

        selfFrame:Show()
        if db.showIcon and selfFrame.icon:IsShown() then selfFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
        return
    else
        selfFrame.previewStart = nil
    end

    -- ==========================================================
    -- LIVE GAMEPLAY LOGIC
    -- ==========================================================

    if selfFrame.casting then
        local elap = now - (selfFrame.startTime or now)
        elap = math.max(0, math.min(elap, selfFrame.duration or 0))
        selfFrame.timer:SetText(GetFmtTimer((selfFrame.endTime or 0) - now, selfFrame.duration))
        Upd(elap, selfFrame.duration)
        self:UpdateLatencyBar(selfFrame)
        return
    end

    if selfFrame.channeling then
        local rem = (selfFrame.endTime or now) - now
        rem = math.max(0, rem)
        
        if selfFrame.isEmpowered or db.reverseChanneling then
            -- FILLING (Reverse or Empowered)
            local elap = now - selfFrame.startTime
            selfFrame.timer:SetText(db.hideTimerOnChannel and "" or GetFmtTimer(rem, selfFrame.duration))
            Upd(elap, selfFrame.duration)
        else
            -- EMPTYING (Standard Channel)
            selfFrame.timer:SetText(db.hideTimerOnChannel and "" or GetFmtTimer(rem, selfFrame.duration))
            Upd(rem, selfFrame.duration)
        end
        self:UpdateLatencyBar(selfFrame)
        return
    end

    -- Idle
    selfFrame:SetValue(0); selfFrame.spellName:SetText(""); selfFrame.timer:SetText("")
    selfFrame.icon:Hide(); selfFrame.shield:Hide()
    self:HideTicks()
    self:UpdateSpark(0,0)
    selfFrame:Hide()
end

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
                        set = function(info, val) self.db.profile.previewEnabled = val; self.castBar:SetShown(val) end,
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
                    
                    -- SHIELD / UNINTERRUPTIBLE
                    showShield = {
                        name = "Uninterruptible Shield", type = "toggle", order = 31,
                        get = function(info) return self.db.profile.showShield end,
                        set = function(info, val) self.db.profile.showShield = val end,
                    },
                    uninterruptibleColor = {
                        name = "Shield Bar Color", type = "color", hasAlpha = true, order = 32,
                        get = function(info) local c = self.db.profile.uninterruptibleColor; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.uninterruptibleColor = {r, g, b, a}; end,
                    },
                    uninterruptibleBorderGlow = {
                        name = "Shield Glow", desc="Glow the border when uninterruptible.", type = "toggle", order = 33,
                        get = function(info) return self.db.profile.uninterruptibleBorderGlow end,
                        set = function(info, val) self.db.profile.uninterruptibleBorderGlow = val end,
                    },
                    uninterruptibleGlowColor = {
                        name = "Shield Glow Color", type = "color", hasAlpha = true, order = 34,
                        disabled = function() return not self.db.profile.uninterruptibleBorderGlow end,
                        get = function(info) local c = self.db.profile.uninterruptibleGlowColor; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.uninterruptibleGlowColor = {r, g, b, a}; end,
                    },

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
                        name = "Show Latency", type = "toggle", order = 34,
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
                        name = "Intensity", type = "range", min=0, max=1, step=0.05, order=3,
                        get = function(info) return self.db.profile.sparkIntensity end,
                        set = function(info, val) self.db.profile.sparkIntensity = val end,
                    },
                    sparkScale = {
                        name = "Scale", type = "range", min=0.5, max=3, step=0.1, order=4,
                        get = function(info) return self.db.profile.sparkScale end,
                        set = function(info, val) self.db.profile.sparkScale = val; self:UpdateSparkSize() end,
                    },
                    sparkColor = {
                        name = "Spark Color", type = "color", hasAlpha = true, order=5,
                        get = function(info) local c = self.db.profile.sparkColor; return c[1], c[2], c[3], c[4] end,
                        set = function(info, r, g, b, a) self.db.profile.sparkColor = {r,g,b,a}; self:UpdateSparkColors() end,
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
                        set = function(info, val) self.db.profile.attachToCDM = val; self:UpdateAnchor() end,
                    },
                    cdmTarget = {
                        name = "Target Frame", type = "select", values = {["Auto"]="Auto", ["Essential"]="Essential", ["Utility"]="Utility", ["Custom"]="Custom"}, order = 2,
                        get = function(info) return self.db.profile.cdmTarget end,
                        set = function(info, val) self.db.profile.cdmTarget = val; self:UpdateAnchor() end,
                    },
                    cdmFrameName = {
                        name = "Custom Frame Name (Experimental)", type = "input", order = 3,
                        get = function(info) return self.db.profile.cdmFrameName end,
                        set = function(info, val) self.db.profile.cdmFrameName = val; self:UpdateAnchor() end,
                    },
                    cdmYOffset = {
                        name = "Vertical Offset", type = "range", min=-100, max=100, step=1, order = 4,
                        get = function(info) return self.db.profile.cdmYOffset end,
                        set = function(info, val) self.db.profile.cdmYOffset = val; self:UpdateAnchor() end,
                    },
                }
            },
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db),
        },
    }
    
    -- Register Config
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, ADDON_NAME)
    
    -- Chat Commands
    self:RegisterChatCommand("acb", "OpenConfig")
    self:RegisterChatCommand("ascensioncastbar", "OpenConfig")
end

function AscensionCastBar:OpenConfig()
    LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)
end
