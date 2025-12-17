-- AscensionCastBar.lua
-- Addon: AscensionCastBar
-- SavedVariables: AscensionCastBarDB

local ADDON_NAME = "AscensionCastBar"
local ADDON_TITLE = "Ascension Cast Bar"

-- ============================================================================
-- 1. TABLAS DE DATOS (QUARTZ & ASCENSION)
-- ============================================================================

local WoWRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local GetSpellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo

-- Tabla de Ticks (Integración Quartz)
local channelingTicks = {
    -- Sacerdote
    [GetSpellName(64843) or "Himno divino"] = 4,
    [GetSpellName(15407) or "Tortura mental"] = 3, 
    [GetSpellName(47540) or "Penitencia"] = 3,
    -- Mago
    [GetSpellName(5143) or "Misiles arcanos"] = 5,
    [GetSpellName(12051) or "Evocación"] = 4,
    [GetSpellName(10) or "Ventisca"] = 8,
    -- Druida
    [GetSpellName(740) or "Tranquilidad"] = 4,
    [GetSpellName(16914) or "Huracán"] = 10,
    -- Brujo
    [GetSpellName(234153) or "Drenar vida"] = 5,
    [GetSpellName(198590) or "Drenar alma"] = 5,
    [GetSpellName(5740) or "Lluvia de fuego"] = 8,
    -- Evocador
    [GetSpellName(356995) or "Desintegrar"] = 3,
    -- Nombres en Inglés / Servidores Privados
    ["Mind Flay"] = 3, ["Drain Life"] = 5, ["Blizzard"] = 8, ["Hurricane"] = 10, ["Penance"] = 3,
    ["Divine Hyatt"] = 4, ["Rain of Fire"] = 8, ["Evocation"] = 4, ["Arcane Missiles"] = 5
}

-- Lista de Hechizos Empowered (Siempre llenan la barra)
local EMPOWERED_SPELLS = {
    ["Fire Breath"] = true, ["Aliento de fuego"] = true,
    ["Eternity Surge"] = true, ["Oleada de eternidad"] = true,
    ["Dream Breath"] = true, ["Aliento onírico"] = true,
    ["Spiritbloom"] = true, ["Flor de espíritu"] = true,
    ["Upheaval"] = true, 
}

-- ============================================================================
-- 2. FUNCIONES AUXILIARES
-- ============================================================================

local function GetBlizzardCastBars()
    local frames = {}
    if _G["CastingBarFrame"] then table.insert(frames, _G["CastingBarFrame"]) end
    if _G["PlayerCastingBarFrame"] then table.insert(frames, _G["PlayerCastingBarFrame"]) end
    return frames
end

local function UpdateDefaultCastBarVisibility()
    local hide = AscensionCastBarDB and AscensionCastBarDB.profiles and AscensionCastBarDB.activeProfile and AscensionCastBarDB.profiles[AscensionCastBarDB.activeProfile].hideDefaultCastbar
    local frames = GetBlizzardCastBars()

    for _, frame in ipairs(frames) do
        if frame then
            if hide then
                frame:UnregisterAllEvents()
                frame:Hide()
            else
                frame:RegisterEvent("UNIT_SPELLCAST_START")
                frame:RegisterEvent("UNIT_SPELLCAST_STOP")
                frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
                frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
                frame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
                frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
                frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
                frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
                pcall(function() 
                    frame:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
                    frame:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
                    frame:RegisterEvent("UNIT_SPELLCAST_EMPOWER_UPDATE")
                end)
                frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            end
        end
    end
end

local function UpdateConfigControls(db)
    local ddTimerFormat = _G["ACB_DD_3timerFormat"]
    if ddTimerFormat then UIDropDownMenu_SetText(ddTimerFormat, db.timerFormat or "Remaining") end
    
    local ddAnimStyle = _G["ACB_DD_4animStyle"]
    if ddAnimStyle then UIDropDownMenu_SetText(ddAnimStyle, db.animStyle or "Comet") end
    
    local ddCDMTarget = _G["ACB_DD_5cdmTarget"]
    if ddCDMTarget then UIDropDownMenu_SetText(ddCDMTarget, db.cdmTarget or "Auto") end
    
    local ddIconAnchor = _G["ACB_DD_2iconAnchor"]
    if ddIconAnchor then UIDropDownMenu_SetText(ddIconAnchor, db.iconAnchor or "Left") end
end

-- ============================================================================
-- 3. INICIALIZACIÓN PRINCIPAL
-- ============================================================================

local function InitializeAscensionCastBar()
    -- Base de Datos y Perfiles
    if not AscensionCastBarDB then AscensionCastBarDB = {} end
    if not AscensionCastBarDB.profiles then AscensionCastBarDB.profiles = {} end
    if not AscensionCastBarDB.activeProfile then AscensionCastBarDB.activeProfile = "Default" end
    
    if AscensionCastBarDB.width then
        AscensionCastBarDB.profiles["Default"] = {}
        for k, v in pairs(AscensionCastBarDB) do
            if k ~= "profiles" and k ~= "activeProfile" then
                AscensionCastBarDB.profiles["Default"][k] = v
                AscensionCastBarDB[k] = nil
            end
        end
    end
    
    if not AscensionCastBarDB.profiles["Default"] then AscensionCastBarDB.profiles["Default"] = {} end
    local db = AscensionCastBarDB.profiles[AscensionCastBarDB.activeProfile]

    if db.fontPath == "FontsFRIZQT__.TTF" then db.fontPath = "Fonts\\FRIZQT__.TTF" end
    local BAR_DEFAULT_FONT_PATH = "Interface\\AddOns\\AscensionCastBar\\COLLEGIA.ttf"

    local function ClampAlpha(v) v = tonumber(v) or 0; if v < 0 then v = 0 elseif v > 1 then v = 1 end return v end

    local defaults = {
        width = 270, cdmLayoutWidth = 270, height = 24,
        point = "CENTER", relativePoint = "CENTER", x = 0, y = -85,
        unlock = true,
        -- Fonts/Text
        spellNameFontSize = 14, timerFontSize = 14, fontPath = BAR_DEFAULT_FONT_PATH,
        fontColor = {0.80784320831299, 1, 0.95294123888016, 1},
        showSpellText = true, showTimerText = true,
        spellNameFontLSM = "Expressway, Bold", timerFontLSM = "Boris Black Bloxx", fontLSMName = "Expressway, Bold",
        detachText = false, textX = 0, textY = 40, textWidth = 270,
        textBackdropEnabled = false, textBackdropColor = {0, 0, 0, 0.5},
        timerFormat = "Remaining", truncateSpellName = false, truncateLength = 30,
        -- Colors
        barColor = {0, 0.027450982481241, 0.25098040699959, 1}, barLSMName = "Solid", useClassColor = false,
        -- Shield/Ticks
        showShield = true, uninterruptibleColor = {0.4, 0.4, 0.4, 1},
        showChannelTicks = true, channelTicksColor = {1, 1, 1, 0.5},
        -- Anim
        enableSpark = true, enableTails = true, animStyle = "Comet",
        sparkColor = {0.937, 0.984, 1, 1}, glowColor = {1, 1, 1, 1},
        sparkIntensity = 1, glowIntensity = 0.5, sparkScale = 3, sparkOffset = 1.27, headLengthOffset = -23,
        tailLength = 200, tailOffset = -14.68,
        tail1Color = {1, 0, 0.09, 1}, tail1Intensity = 1, tail1Length = 95, tail1Offset = 200,
        tail2Color = {0, 0.98, 1, 1}, tail2Intensity = 0.42, tail2Length = 215, tail2Offset = 84,
        tail3Color = {0, 1, 0.22, 1}, tail3Intensity = 0.68, tail3Length = 80, tail3Offset = 187,
        tail4Color = {1, 0, 0.8, 1}, tail4Intensity = 0.61, tail4Length = 150, tail4Offset = 58,
        -- Icon
        showIcon = false, detachIcon = false, iconAnchor = "Left", iconSize = 24, iconX = 0, iconY = 0,
        -- BG
        bgColor = {0, 0, 0, 0.65}, borderEnabled = true, borderColor = {0, 0, 0, 1}, borderThickness = 2,
        -- Behavior
        hideTimerOnChannel = false, hideDefaultCastbar = true,
        reverseChanneling = false, -- OPCION QUARTZ REVERSE
        showLatency = true, latencyColor = {1, 0, 0, 0.5}, latencyMaxPercent = 1.0,
        -- CDM
        attachToCDM = false, cdmTarget = "Auto", cdmFrameName = "CooldownManagerFrame", cdmYOffset = -5,
        previewEnabled = false, barDraggable = true,
    }

    for k,v in pairs(defaults) do if db[k] == nil then db[k] = v end end

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local _, playerClass = UnitClass("player")
    local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerClass]) or {r=1,g=1,b=1}
    
    local UpdateAnchor, UpdateSparkSize, UpdateTextLayout, ReloadProfile, UpdateIcon

    -- FRAME DE LA BARRA
    local castBar = CreateFrame("StatusBar","AscensionCastBarFrame",UIParent)
    castBar:SetClipsChildren(false) 
    castBar:SetSize(db.width, db.height)
    castBar:SetFrameStrata("MEDIUM"); castBar:SetFrameLevel(10); castBar:Hide()
    castBar.unit = "player" -- Necesario para Empowered APIs

    UpdateAnchor = function()
        if not castBar then return end
        castBar:ClearAllPoints()
        local parentFrame, isAttached = nil, false
        
        if db.attachToCDM then
             local target = db.cdmTarget or "Auto"
             if target == "Essential" then if _G["EssentialCooldownViewer"] and _G["EssentialCooldownViewer"]:IsShown() then parentFrame = _G["EssentialCooldownViewer"] end
             elseif target == "Utility" then if _G["UtilityCooldownViewer"] and _G["UtilityCooldownViewer"]:IsShown() then parentFrame = _G["UtilityCooldownViewer"] end
             elseif target == "Custom" then if db.cdmFrameName and db.cdmFrameName ~= "" then parentFrame = _G[db.cdmFrameName] end
             else -- Auto
                 if _G["EssentialCooldownViewer"] and _G["EssentialCooldownViewer"]:IsShown() then parentFrame = _G["EssentialCooldownViewer"]
                 elseif _G["UtilityCooldownViewer"] and _G["UtilityCooldownViewer"]:IsShown() then parentFrame = _G["UtilityCooldownViewer"]
                 elseif db.cdmFrameName and db.cdmFrameName ~= "" then parentFrame = _G[db.cdmFrameName] end
             end
        end

        if parentFrame then
            isAttached = true
            castBar:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 0, db.cdmYOffset or -5)
            local w = parentFrame:GetWidth()
            if w and w > 1 then castBar:SetWidth(w) end
        else
            castBar:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y)
            castBar:SetWidth(db.width)
        end
        
        if UpdateSparkSize then UpdateSparkSize() end
        if UpdateTextLayout then UpdateTextLayout() end
        if castBar.ticksFrame then castBar.ticksFrame:SetWidth(castBar:GetWidth()) end
        return isAttached
    end
    
    local hooksDefined = false
    local function InitCDMHooks()
        if hooksDefined then return end
        local function OnCDMResize(_, width)
            if db.attachToCDM then UpdateAnchor() end
        end
        if _G["EssentialCooldownViewer"] then hooksecurefunc(_G["EssentialCooldownViewer"], "SetSize", OnCDMResize); hooksecurefunc(_G["EssentialCooldownViewer"], "Show", OnCDMResize); hooksecurefunc(_G["EssentialCooldownViewer"], "Hide", OnCDMResize) end
        if _G["UtilityCooldownViewer"] then hooksecurefunc(_G["UtilityCooldownViewer"], "SetSize", OnCDMResize); hooksecurefunc(_G["UtilityCooldownViewer"], "Show", OnCDMResize); hooksecurefunc(_G["UtilityCooldownViewer"], "Hide", OnCDMResize) end
        hooksDefined = true
        UpdateAnchor()
    end
    UpdateAnchor()

    castBar:SetMovable(true); castBar:EnableMouse(true); castBar:RegisterForDrag("LeftButton"); castBar:SetClampedToScreen(true)
    castBar:SetScript("OnDragStart", function(self) if db.barDraggable and not db.attachToCDM then self:StartMoving(); self.isMoving = true end end)
    castBar:SetScript("OnDragStop", function(self)
        if not self.isMoving then return end
        self:StopMovingOrSizing(); self.isMoving = false
        local ui = UIParent; local cx, cy = self:GetCenter(); local ux, uy = ui:GetCenter()
        if not (cx and cy and ux and uy) then return end
        db.point = "CENTER"; db.relativePoint = "CENTER"; db.x = cx - ux; db.y = cy - uy
        self:ClearAllPoints(); self:SetPoint("CENTER", ui, "CENTER", db.x, db.y)
    end)

    local function GetBarTexture() if LSM and db.barLSMName then return LSM:Fetch("statusbar", db.barLSMName) or "Interface\\TARGETINGFRAME\\UI-StatusBar" else return "Interface\\TARGETINGFRAME\\UI-StatusBar" end end
    pcall(function() castBar:SetStatusBarTexture(GetBarTexture()) end)

    castBar.bg = castBar:CreateTexture(nil,"BACKGROUND"); castBar.bg:SetAllPoints()
    local function UpdateBackground() local c = db.bgColor or {0,0,0,0.7}; castBar.bg:SetColorTexture(c[1], c[2], c[3], c[4] or 0.7) end
    UpdateBackground()

    castBar.lightOverlay = castBar:CreateTexture(nil, "ARTWORK"); castBar.lightOverlay:SetColorTexture(1, 1, 1, 1); castBar.lightOverlay:SetBlendMode("ADD"); castBar.lightOverlay:SetAlpha(0); castBar.lightOverlay:Hide()
    castBar.tailMask = CreateFrame("Frame", nil, castBar); castBar.tailMask:SetPoint("TOPLEFT", 0, 0); castBar.tailMask:SetPoint("BOTTOMLEFT", 0, 0); castBar.tailMask:SetWidth(db.width); castBar.tailMask:SetClipsChildren(true)

    local function UpdateLightOverlayAnchor()
        if not castBar.lightOverlay then return end
        local tex = castBar:GetStatusBarTexture()
        if tex then
            local b = (db.borderEnabled and (db.borderThickness or 1)) or 0
            if b > 0 then castBar.lightOverlay:ClearAllPoints(); castBar.lightOverlay:SetPoint("TOPLEFT", tex, "TOPLEFT", b, -b); castBar.lightOverlay:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", -b, b)
            else castBar.lightOverlay:SetAllPoints(tex) end
        end
    end
    
    -- ==========================================================
    -- LÓGICA DE TICKS (QUARTZ)
    -- ==========================================================
    castBar.ticksFrame = CreateFrame("Frame", nil, castBar); castBar.ticksFrame:SetAllPoints(); castBar.ticksFrame:SetFrameLevel(15); castBar.ticks = {}
    
    local function HideTicks() 
        for _, tick in ipairs(castBar.ticks) do tick:Hide() end 
        -- Ocultar pips de empowered si existen
        if castBar.stagePips then for _, pip in ipairs(castBar.stagePips) do pip:Hide() end end
    end

    local function getChannelingTicks(spellName, spellID)
        local ticks = 0
        if spellID then ticks = channelingTicks[spellID] end
        if not ticks or ticks == 0 then ticks = channelingTicks[spellName] end
        return ticks or 0
    end

    local function DrawTicks()
        HideTicks()
        if not db.showChannelTicks or not castBar.tickPositions then return end
        
        local c = db.channelTicksColor or {1,1,1,0.5}
        local width = castBar:GetWidth()
        local duration = castBar.channelingDuration or (castBar.endTime - castBar.startTime)
        if duration <= 0 then return end

        for i, posTime in ipairs(castBar.tickPositions) do
            local tick = castBar.ticks[i]
            if not tick then 
                tick = castBar.ticksFrame:CreateTexture(nil, "OVERLAY")
                tick:SetWidth(1)
                tick:SetHeight(castBar:GetHeight())
                table.insert(castBar.ticks, tick) 
            end
            
            local pct = posTime / duration
            if db.reverseChanneling then pct = 1 - pct end

            if pct > 0 and pct < 1 then
                tick:ClearAllPoints()
                tick:SetColorTexture(c[1],c[2],c[3],c[4])
                tick:SetPoint("CENTER", castBar, "LEFT", width * pct, 0)
                tick:Show()
            else
                tick:Hide()
            end
        end
    end

    castBar.icon = castBar:CreateTexture(nil,"OVERLAY"); castBar.icon:SetSize(db.iconSize, db.iconSize); castBar.icon:Hide()
    castBar.shield = castBar:CreateTexture(nil, "OVERLAY", nil, 5); castBar.shield:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online"); castBar.shield:SetSize(16, 16); castBar.shield:Hide()
    castBar.latency = castBar:CreateTexture(nil, "OVERLAY", nil, 2); castBar.latency:Hide()

    -- ==========================================================
    -- ANIMACIONES / SPARK
    -- ==========================================================
    castBar.sparkHead = castBar:CreateTexture(nil, "OVERLAY", nil, 7); castBar.sparkHead:SetAtlas("pvpscoreboard-header-glow", true); castBar.sparkHead:SetBlendMode("ADD"); if castBar.sparkHead.SetRotation then castBar.sparkHead:SetRotation(math.rad(90)) end
    castBar.sparkTail = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail:SetAtlas("AftLevelup-SoftCloud", true); castBar.sparkTail:SetBlendMode("ADD")
    castBar.sparkTail2 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail2:SetAtlas("AftLevelup-SoftCloud", true); castBar.sparkTail2:SetTexCoord(0, 1, 1, 0); castBar.sparkTail2:SetBlendMode("ADD")
    castBar.sparkTail3 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail3:SetAtlas("AftLevelup-SoftCloud", true); castBar.sparkTail3:SetBlendMode("ADD")
    castBar.sparkTail4 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail4:SetAtlas("AftLevelup-SoftCloud", true); castBar.sparkTail4:SetTexCoord(0, 1, 1, 0); castBar.sparkTail4:SetBlendMode("ADD")
    castBar.sparkGlow = castBar:CreateTexture(nil, "OVERLAY", nil, 6); castBar.sparkGlow:SetTexture("Interface\\CastingBar\\UI-CastingBar-Pushback"); castBar.sparkGlow:SetBlendMode("ADD")
    castBar.spark = castBar.sparkHead

    local function UpdateSparkColors()
        local s, g = db.sparkColor or {1,1,1,1}, db.glowColor or {1,1,1,1}
        castBar.sparkHead:SetVertexColor(s[1], s[2], s[3], s[4]); castBar.sparkGlow:SetVertexColor(g[1], g[2], g[3], g[4])
        local t1, t2, t3, t4 = db.tail1Color or {1,0,0,1}, db.tail2Color or {0,1,1,1}, db.tail3Color or {0,1,0,1}, db.tail4Color or {1,0,1,1}
        castBar.sparkTail:SetVertexColor(t1[1],t1[2],t1[3],t1[4]); castBar.sparkTail2:SetVertexColor(t2[1],t2[2],t2[3],t2[4])
        castBar.sparkTail3:SetVertexColor(t3[1],t3[2],t3[3],t3[4]); castBar.sparkTail4:SetVertexColor(t4[1],t4[2],t4[3],t4[4])
    end
    UpdateSparkColors()

    UpdateSparkSize = function()
        if not castBar.sparkHead then return end
        local sc, h = db.sparkScale or 1.8, db.height or 20
        castBar.sparkHead:SetSize(32*sc, h*2*sc); castBar.sparkGlow:SetSize(190*sc, h*2.4)
        castBar.sparkTail:SetSize((db.tail1Length or 90)*sc, h*1.4); castBar.sparkTail2:SetSize((db.tail2Length or 60)*sc, h*1.1)
        castBar.sparkTail3:SetSize((db.tail3Length or 90)*sc, h*1.4); castBar.sparkTail4:SetSize((db.tail4Length or 60)*sc, h*1.1)
        if castBar.tailMask then castBar.tailMask:SetWidth(castBar:GetWidth()) end
    end
    UpdateSparkSize()

    local function ResetParticles()
        if castBar.particles then for _, p in ipairs(castBar.particles) do p:Hide() end end
        castBar.lastParticleTime = 0
    end

    local function UpdateSpark(progress, tailProgress)
        if castBar.waveOverlay then castBar.waveOverlay:Hide() end
        if castBar.scanLine then castBar.scanLine:Hide() end
        if castBar.rainbowOverlay then castBar.rainbowOverlay:Hide() end
        if castBar.glitchLayers then for _, g in ipairs(castBar.glitchLayers) do g:Hide() end end
        if castBar.lightningSegments then for _, l in ipairs(castBar.lightningSegments) do l:Hide() end end
        if db.animStyle ~= "Particles" and castBar.particles then for _, p in ipairs(castBar.particles) do p:Hide() end end

        if not castBar.sparkHead then return end

        if not db.enableSpark or not progress or progress<=0 or progress>=1 then 
            castBar.sparkHead:Hide(); castBar.sparkGlow:Hide()
            castBar.sparkTail:Hide(); castBar.sparkTail2:Hide(); castBar.sparkTail3:Hide(); castBar.sparkTail4:Hide()
            return 
        end

        local w, style = castBar:GetWidth(), db.animStyle or "Comet"
        local offset = w * progress
        local b = (db.borderEnabled and (db.borderThickness or 1)) or 0
        local tP = tailProgress or 0
        local time = GetTime()
        
        local effOffset = (db.headLengthOffset or -23) * (w / (defaults.width or 270))
        castBar.sparkHead:ClearAllPoints()
        castBar.sparkHead:SetPoint("CENTER", castBar, "LEFT", offset + (db.sparkOffset or 0) + effOffset, 0)
        castBar.sparkHead:SetAlpha(ClampAlpha(db.sparkIntensity or 1)); castBar.sparkHead:Show()
        castBar.sparkGlow:ClearAllPoints(); castBar.sparkGlow:SetPoint("CENTER", castBar.sparkHead, "CENTER", 0, 0)

        if castBar.tailMask then
            local aw = offset - (b>0 and b or 0); if aw<0 then aw=0 end; if aw>w then aw=w end
            castBar.tailMask:SetWidth(aw)
        end

        if not db.enableTails or (style == "Wave" or style == "Scanline" or style == "Rainbow" or style == "Glitch") then
             castBar.sparkTail:Hide(); castBar.sparkTail2:Hide(); castBar.sparkTail3:Hide(); castBar.sparkTail4:Hide()
        end

        if style == "Orb" then
            castBar.sparkGlow:Show(); local rotSpeed = time * 8; local radius = (db.height or 24) * 0.4 
            local function SpinOrb(tex, angleOffset, intense) tex:ClearAllPoints(); local x = math.cos(rotSpeed + angleOffset) * radius; local y = math.sin(rotSpeed + angleOffset) * radius; tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", x, y); tex:SetAlpha(ClampAlpha(intense) * 1.0); tex:Show() end
            if db.enableTails then SpinOrb(castBar.sparkTail, 0, db.tail1Intensity or 0.6); SpinOrb(castBar.sparkTail2, math.pi/2, db.tail2Intensity or 0.6); SpinOrb(castBar.sparkTail3, math.pi, db.tail3Intensity or 0.6); SpinOrb(castBar.sparkTail4, -math.pi/2, db.tail4Intensity or 0.6) end
            local pulse = 0.5 + 0.5 * math.sin(time * 8); castBar.sparkGlow:SetAlpha(ClampAlpha(db.glowIntensity or 0.5) * (0.6 + 0.4*pulse))
        elseif style == "Vortex" then
            castBar.sparkGlow:Show(); local radius = (db.height or 24) * 0.9; local speed = 8
            local function Orbit(tex, idx, intense) tex:ClearAllPoints(); local angle = (time * speed) + (offset * 0.05) - (idx * 0.8); local r = radius * (1 - (idx * 0.2)); local x = math.cos(angle) * r; local y = math.sin(angle) * r; tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", x, y); local sz = (db.height or 24) * 0.7; tex:SetSize(sz, sz); tex:SetAlpha(ClampAlpha(intense) * tP); tex:Show() end
            if db.enableTails then Orbit(castBar.sparkTail, 0, db.tail1Intensity or 0.35); Orbit(castBar.sparkTail2, 1, db.tail2Intensity or 0.22); Orbit(castBar.sparkTail3, 2, db.tail3Intensity or 0.28); Orbit(castBar.sparkTail4, 3, db.tail4Intensity or 0.18) end
        elseif style == "Pulse" then
            castBar.sparkGlow:Show(); local maxScale = 2.5
            local function Ripple(tex, offsetTime, intense) tex:ClearAllPoints(); tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", 0, 0); local cycle = (time + offsetTime) % 1; local size = (db.height or 24) * 2 * (0.2 + cycle * maxScale); tex:SetSize(size, size); local fade = 1 - (cycle * cycle); tex:SetAlpha(ClampAlpha(intense) * fade); tex:Show() end
            if db.enableTails then Ripple(castBar.sparkTail, 0.0, db.tail1Intensity or 0.35); Ripple(castBar.sparkTail2, 0.3, db.tail2Intensity or 0.22); Ripple(castBar.sparkTail3, 0.6, db.tail3Intensity or 0.28); Ripple(castBar.sparkTail4, 0.9, db.tail4Intensity or 0.18) end
        elseif style == "Starfall" then
             castBar.sparkGlow:Hide(); local h = db.height or 24
             local function Fall(tex, driftBase, speed, intense) tex:ClearAllPoints(); local fallY = -((time * speed * 15) % (h*2.5)) + h; local sway = math.sin(time * 3 + driftBase) * 8; tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", driftBase + sway, fallY); tex:SetAlpha(ClampAlpha(intense) * (1 - math.abs(fallY)/(h*1.5))); tex:Show() end
             if db.enableTails then Fall(castBar.sparkTail, -10, 2.5, db.tail1Intensity or 0.4); Fall(castBar.sparkTail2, 10, 3.8, db.tail2Intensity or 0.3); Fall(castBar.sparkTail3, -20, 1.5, db.tail3Intensity or 0.4); Fall(castBar.sparkTail4, 20, 3.0, db.tail4Intensity or 0.3) end
        elseif style == "Flux" then
            castBar.sparkGlow:Hide(); local dm = w * 0.05; local jitterY = 3.5; local jitterX = 2.5
            local function Flux(tex, baseOff, drift, intense) tex:ClearAllPoints(); local rY = (math.random() * jitterY * 2) - jitterY; local rX = (math.random() * jitterX * 2) - jitterX; local x = math.max(b, math.min(w-b, offset - baseOff + drift + rX)); tex:SetPoint("CENTER", castBar.tailMask, "LEFT", x, rY); tex:SetAlpha(ClampAlpha(intense) * tP); tex:Show() end
            if db.enableTails then Flux(castBar.sparkTail, 20, -dm*tP, db.tail1Intensity or 0.35); Flux(castBar.sparkTail2, 35, dm*tP, db.tail2Intensity or 0.22); Flux(castBar.sparkTail3, 20, -dm*tP, db.tail3Intensity or 0.28); Flux(castBar.sparkTail4, 35, dm*tP, db.tail4Intensity or 0.18) end
        elseif style == "Helix" then
             castBar.sparkGlow:Show(); local dm = w * 0.1; local amp = (db.height or 24) * 0.4; local waveSpeed = 8; local sv = math.sin(time * waveSpeed + (offset * 0.05)) * amp; local cv = math.cos(time * waveSpeed + (offset * 0.05)) * amp
             local function Helix(tex, baseOff, drift, yOff, intense) tex:ClearAllPoints(); local x = math.max(b, math.min(w-b, offset - baseOff + drift)); tex:SetPoint("CENTER", castBar.tailMask, "LEFT", x, yOff); tex:SetAlpha(ClampAlpha(intense) * tP); tex:Show() end
             if db.enableTails then Helix(castBar.sparkTail, 20, -dm*tP, sv, db.tail1Intensity or 0.35); Helix(castBar.sparkTail2, 35, dm*tP, -sv, db.tail2Intensity or 0.22); Helix(castBar.sparkTail3, 25, -dm*tP, cv, db.tail3Intensity or 0.28); Helix(castBar.sparkTail4, 30, dm*tP, -cv, db.tail4Intensity or 0.18) end
        elseif style == "Wave" then
            castBar.sparkGlow:Hide(); castBar.sparkHead:Hide() 
            if not castBar.waveOverlay then castBar.waveOverlay = castBar:CreateTexture(nil, "ARTWORK"); castBar.waveOverlay:SetBlendMode("ADD"); castBar.waveOverlay:SetAllPoints(); castBar.waveOverlay:SetGradient("HORIZONTAL", CreateColor(1,1,1,0), CreateColor(1,1,1,0.5), CreateColor(1,1,1,0)) end
            local wOff = (time * 2.0) % 1; castBar.waveOverlay:SetTexCoord(wOff, wOff + 1, 0, 1); local wH = 5 * math.sin(time * 2); castBar.waveOverlay:ClearAllPoints(); castBar.waveOverlay:SetPoint("TOPLEFT", castBar, "TOPLEFT", 0, wH); castBar.waveOverlay:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 0, wH)
            local wc = db.tail2Color or {0.3, 0.6, 1, 0.3}; castBar.waveOverlay:SetVertexColor(wc[1], wc[2], wc[3], 0.3 * (0.5 + progress * 0.5)); castBar.waveOverlay:Show()
        elseif style == "Particles" then
             castBar.sparkGlow:Show(); if not castBar.particles then castBar.particles = {} end; if not castBar.lastParticleTime then castBar.lastParticleTime = 0 end
             if (time - castBar.lastParticleTime) > 0.05 then local p = nil; for _, v in ipairs(castBar.particles) do if not v:IsShown() then p=v; break end end; if not p then p = castBar.tailMask:CreateTexture(nil, "OVERLAY"); p:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark"); p:SetBlendMode("ADD"); table.insert(castBar.particles, p) end; p.life = 1.0; p.sx = offset; p.sy = 0; p.vx = (math.random()-0.5)*10; p.vy = 20 + math.random()*30; p:SetSize(8,8); p:Show(); castBar.lastParticleTime = time end
             for _, p in ipairs(castBar.particles) do if p:IsShown() then p.life = p.life - 0.05; if p.life <= 0 then p:Hide() else p.sx = p.sx + p.vx * 0.05; p.sy = p.sy + p.vy * 0.05; p:ClearAllPoints(); p:SetPoint("CENTER", castBar.tailMask, "LEFT", p.sx, p.sy); local pc = db.sparkColor or {1,1,1,1}; p:SetVertexColor(pc[1], pc[2], pc[3], p.life) end end end
        elseif style == "Scanline" then
             castBar.sparkHead:Hide(); castBar.sparkGlow:Hide(); if not castBar.scanLine then castBar.scanLine = castBar:CreateTexture(nil, "OVERLAY"); castBar.scanLine:SetColorTexture(1, 1, 1, 1); castBar.scanLine:SetBlendMode("ADD"); castBar.scanLine:SetSize(4, db.height or 24) end
             local slP = (time % 1.5) / 1.5; if slP > 0.5 then slP = 1 - slP end; local slX = w * ((math.sin(time * 3) + 1) / 2); castBar.scanLine:ClearAllPoints(); castBar.scanLine:SetPoint("CENTER", castBar, "LEFT", slX, 0); local sc = db.tail1Color or {1,1,1,0.8}; castBar.scanLine:SetVertexColor(sc[1], sc[2], sc[3], 0.8); castBar.scanLine:Show()
        elseif style == "Glitch" then
             castBar.sparkHead:Hide(); if not castBar.glitchLayers then castBar.glitchLayers = {}; for i=1,3 do local g = castBar:CreateTexture(nil,"OVERLAY"); g:SetColorTexture(1,1,1,0.2); g:SetBlendMode("ADD"); table.insert(castBar.glitchLayers, g) end end
             for i, g in ipairs(castBar.glitchLayers) do if math.random() < 0.1 then local r = math.random()>0.5 and 1 or 0; local gr = math.random()>0.5 and 1 or 0; local bl = math.random()>0.5 and 1 or 0; g:SetVertexColor(r,gr,bl, 0.3); g:ClearAllPoints(); local ox = math.random(-5,5); local oy = math.random(-2,2); g:SetPoint("TOPLEFT", castBar, "TOPLEFT", ox, oy); g:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", ox, oy); g:Show() else g:Hide() end end
        elseif style == "Lightning" then
             castBar.sparkGlow:Show(); if not castBar.lightningSegments then castBar.lightningSegments = {} end
             for i=1, 3 do local l = castBar.lightningSegments[i]; if not l then l = castBar:CreateTexture(nil, "OVERLAY"); l:SetColorTexture(1,1,1,1); l:SetBlendMode("ADD"); castBar.lightningSegments[i] = l end
             if math.random() < 0.3 then local tx = math.random(0, w); local ty = math.random(0, db.height or 24); local dx = tx - offset; local dy = ty - ((db.height or 24)/2); local len = math.sqrt(dx*dx + dy*dy); local ang = math.atan2(dy, dx); l:SetSize(len, 2); l:ClearAllPoints(); l:SetPoint("CENTER", castBar, "LEFT", offset, 0); l:SetRotation(ang); local lc = db.tail3Color or {0, 0.8, 1, 0.8}; l:SetVertexColor(lc[1], lc[2], lc[3], 0.6); l:Show() else l:Hide() end end
        elseif style == "Rainbow" then
             castBar.sparkHead:Hide(); castBar.sparkGlow:Hide(); if not castBar.rainbowOverlay then castBar.rainbowOverlay = castBar:CreateTexture(nil, "ARTWORK"); castBar.rainbowOverlay:SetBlendMode("ADD"); castBar.rainbowOverlay:SetAllPoints(); castBar.rainbowOverlay:SetGradient("HORIZONTAL", CreateColor(1,0,0,1), CreateColor(1,1,0,1), CreateColor(0,1,0,1), CreateColor(0,1,1,1), CreateColor(0,0,1,1), CreateColor(1,0,1,1)) end
             local ro = (time * 0.5) % 1; castBar.rainbowOverlay:SetTexCoord(ro, ro+1, 0, 1); castBar.rainbowOverlay:SetAlpha(0.3 + progress * 0.7); castBar.rainbowOverlay:Show()
        else -- Comet
            castBar.sparkGlow:Show()
            local function Comet(tex, rel_pos, int) tex:ClearAllPoints(); local trailX = offset - (rel_pos * w); tex:SetPoint("CENTER", castBar.tailMask, "LEFT", math.max(b, math.min(w-b, trailX)), 0); tex:SetAlpha(ClampAlpha(int)*tP); tex:Show() end
            if db.enableTails then Comet(castBar.sparkTail, 0.05, db.tail1Intensity or 0.35); Comet(castBar.sparkTail2, 0.10, db.tail2Intensity or 0.22); Comet(castBar.sparkTail3, 0.15, db.tail3Intensity or 0.28); Comet(castBar.sparkTail4, 0.20, db.tail4Intensity or 0.18) end
        end
    end

    castBar.textCtx = CreateFrame("Frame", nil, castBar); castBar.textCtx:SetFrameLevel(20)
    castBar.textCtx.bg = castBar.textCtx:CreateTexture(nil, "BACKGROUND"); castBar.textCtx.bg:SetAllPoints(); castBar.textCtx.bg:SetColorTexture(0,0,0,0)
    castBar.spellName = castBar.textCtx:CreateFontString(nil, "OVERLAY"); castBar.spellName:SetDrawLayer("OVERLAY", 7); castBar.spellName:SetJustifyH("LEFT")
    castBar.timer = castBar.textCtx:CreateFontString(nil, "OVERLAY"); castBar.timer:SetDrawLayer("OVERLAY", 7); castBar.timer:SetJustifyH("RIGHT")

    local function ApplyFont()
        local r,g,b,a = unpack(db.fontColor or {1,1,1,1})
        local sP, tP = db.fontPath, db.fontPath
        if LSM then if db.spellNameFontLSM then sP = LSM:Fetch("font", db.spellNameFontLSM) or sP end; if db.timerFontLSM then tP = LSM:Fetch("font", db.timerFontLSM) or tP end end
        local function SF(fs, p, s) fs:SetFont(p or BAR_DEFAULT_FONT_PATH, s, "OUTLINE") end
        SF(castBar.spellName, sP, db.spellNameFontSize); castBar.spellName:SetShadowOffset(1,-1); castBar.spellName:SetShadowColor(0,0,0,0.5); castBar.spellName:SetTextColor(r,g,b,a)
        SF(castBar.timer, tP, db.timerFontSize); castBar.timer:SetShadowOffset(1,-1); castBar.timer:SetShadowColor(0,0,0,0.5); castBar.timer:SetTextColor(r,g,b,a)
    end
    ApplyFont()
    
    UpdateTextLayout = function()
        if not castBar.textCtx then return end
        if db.detachText then
            castBar.textCtx:ClearAllPoints(); castBar.textCtx:SetPoint("CENTER", UIParent, "CENTER", db.textX or 0, db.textY or 0)
            castBar.textCtx:SetSize(db.textWidth or 250, (db.spellNameFontSize or 14) + 6)
            local c = db.textBackdropColor or {0,0,0,0.5}
            castBar.textCtx.bg:SetColorTexture(c[1],c[2],c[3], db.textBackdropEnabled and c[4] or 0)
            castBar.spellName:ClearAllPoints(); castBar.spellName:SetPoint("LEFT", castBar.textCtx, "LEFT", 5, 0); castBar.spellName:SetPoint("RIGHT", castBar.timer, "LEFT", -5, 0)
            castBar.timer:ClearAllPoints(); castBar.timer:SetPoint("RIGHT", castBar.textCtx, "RIGHT", -5, 0)
        else
            castBar.textCtx:ClearAllPoints(); castBar.textCtx:SetAllPoints(castBar); castBar.textCtx.bg:SetColorTexture(0,0,0,0)
            castBar.spellName:ClearAllPoints(); castBar.timer:ClearAllPoints()
            local iconW = 0; if db.showIcon and not db.detachIcon then iconW = (db.height or 24) end
            local anchor = db.iconAnchor or "Left"
            if iconW > 0 then
                if anchor == "Left" then castBar.spellName:SetPoint("LEFT", castBar.textCtx, "LEFT", iconW + 6, 0); castBar.timer:SetPoint("RIGHT", castBar.textCtx, "RIGHT", -5, 0)
                else castBar.spellName:SetPoint("LEFT", castBar.textCtx, "LEFT", 5, 0); castBar.timer:SetPoint("RIGHT", castBar.textCtx, "RIGHT", -iconW - 5, 0) end
            else castBar.spellName:SetPoint("LEFT", castBar.textCtx, "LEFT", 5, 0); castBar.timer:SetPoint("RIGHT", castBar.textCtx, "RIGHT", -5, 0) end
        end
    end
    UpdateTextLayout()

    castBar.border = { top=castBar:CreateTexture(nil,"OVERLAY"), bottom=castBar:CreateTexture(nil,"OVERLAY"), left=castBar:CreateTexture(nil,"OVERLAY"), right=castBar:CreateTexture(nil,"OVERLAY") }
    castBar.border.top:SetPoint("TOPLEFT",0,0); castBar.border.top:SetPoint("TOPRIGHT",0,0); castBar.border.bottom:SetPoint("BOTTOMLEFT",0,0); castBar.border.bottom:SetPoint("BOTTOMRIGHT",0,0)
    castBar.border.left:SetPoint("TOPLEFT",0,0); castBar.border.left:SetPoint("BOTTOMLEFT",0,0); castBar.border.right:SetPoint("TOPRIGHT",0,0); castBar.border.right:SetPoint("BOTTOMRIGHT",0,0)

    local function UpdateBorder()
        local t, c = db.borderThickness or 1, db.borderColor or {0,0,0,1}
        for _, tx in pairs(castBar.border) do tx:SetShown(db.borderEnabled); tx:SetColorTexture(c[1],c[2],c[3],c[4]) end
        castBar.border.top:SetHeight(t); castBar.border.bottom:SetHeight(t); castBar.border.left:SetWidth(t); castBar.border.right:SetWidth(t)
    end
    UpdateBorder()

    UpdateIcon = function()
        if db.showIcon then
            castBar.icon:Show(); local h = db.height or 24
            if db.detachIcon then 
                castBar.icon:SetSize(db.iconSize or 24, db.iconSize or 24); castBar.icon:ClearAllPoints()
                local anchor = db.iconAnchor or "Left"; local offX = db.iconX or 0; local offY = db.iconY or 0
                if anchor == "Left" then castBar.icon:SetPoint("RIGHT", castBar, "LEFT", offX, offY) else castBar.icon:SetPoint("LEFT", castBar, "RIGHT", offX, offY) end
            else 
                castBar.icon:SetSize(h, h); castBar.icon:ClearAllPoints(); local anchor = db.iconAnchor or "Left"
                if anchor == "Left" then castBar.icon:SetPoint("LEFT", castBar, "LEFT", 0, 0) else castBar.icon:SetPoint("RIGHT", castBar, "RIGHT", 0, 0) end
            end
        else castBar.icon:Hide() end
        if not db.detachText then UpdateTextLayout() end
    end
    UpdateIcon()

    local function UpdateBarColor(isUninterruptible)
        if isUninterruptible and db.showShield then local c = db.uninterruptibleColor or {0.4, 0.4, 0.4, 1}; castBar:SetStatusBarColor(c[1], c[2], c[3], c[4])
        elseif db.useClassColor then castBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
        else local c = db.barColor or {1,0.7,0,1}; castBar:SetStatusBarColor(c[1], c[2], c[3], c[4]) end
    end
    UpdateBarColor()

    -- ==========================================================
    -- LÓGICA EMPOWERED (QUARTZ INTEGRATION)
    -- ==========================================================
    
    local function GetStageDuration(bar, stage)
        -- Fallback si no hay API (ej. Cliente viejo)
        if not C_Spell or not GetUnitEmpowerStageDuration then return -1 end
        if stage == bar.NumStages then return GetUnitEmpowerHoldAtMaxTime(bar.unit) else return GetUnitEmpowerStageDuration(bar.unit, stage - 1) end
    end

    local function AddStages(bar, numStages)
        bar.CurrSpellStage = -1; bar.NumStages = numStages + 1; bar.StagePoints = {}
        local sumDuration = 0
        local stageMaxValue = (bar.duration or 1) * 1000 
        -- Limpiar Pips anteriores
        if bar.stagePips then for _, pip in ipairs(bar.stagePips) do pip:Hide() end end
        if not bar.stagePips then bar.stagePips = {} end

        for i = 1, bar.NumStages - 1 do
            local duration = GetStageDuration(bar, i)
            if duration and duration > -1 then
                sumDuration = sumDuration + duration
                bar.StagePoints[i] = sumDuration
                -- Lógica visual: Crear separador (Pip)
                local percentage = sumDuration / stageMaxValue
                if percentage > 0 and percentage < 1 then
                    local pip = bar.stagePips[i]
                    if not pip then pip = bar:CreateTexture(nil, "OVERLAY", nil, 7); pip:SetColorTexture(0, 0, 0, 1); pip:SetWidth(2); table.insert(bar.stagePips, pip) end
                    pip:ClearAllPoints(); pip:SetPoint("TOP", bar, "TOP", 0, 0); pip:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
                    local x = bar:GetWidth() * percentage; pip:SetPoint("CENTER", bar, "LEFT", x, 0); pip:Show()
                end
            end
        end
    end

    local function UpdateStageLogic(bar)
        if not bar.StagePoints then return end
        local currentStage = 0
        local currentProgress = bar:GetValue() * (bar.duration or 1) * 1000
        for i = 1, bar.NumStages do
            if bar.StagePoints[i] then
                if currentProgress > bar.StagePoints[i] then currentStage = i else break end
            end
        end
        if (currentStage ~= bar.CurrSpellStage and currentStage > -1 and currentStage <= bar.NumStages) then
            bar.CurrSpellStage = currentStage
            -- Aquí podrías añadir un flash o sonido de cambio de etapa
        end
    end

    -- ==========================================================
    -- EVENTOS Y ACTUALIZACIÓN
    -- ==========================================================
    local function OnCast(self,event,unit,...)
        if unit and unit~="player" then return end
        local function GetFmtName(name) if db.truncateSpellName and name then local l = db.truncateLength or 30; if #name > l then return string.sub(name,1,l).."..." end end return name or "" end
        
        -- 1. EMPOWERED
        if event == "UNIT_SPELLCAST_EMPOWER_START" then
            local name, _, texture, startMS, endMS, _, _, _, notInt, numStages = UnitEmpowerCastingInfo("player")
            if not name then return end
            self.casting = true; self.channeling = false; self.isEmpowered = true
            self.startTime = startMS/1000; self.endTime = endMS/1000; self.duration = self.endTime - self.startTime
            
            -- Quartz Logic:
            AddStages(self, numStages or 1)

            self.spellName:SetText(db.showSpellText ~= false and GetFmtName(name) or ""); if db.showIcon and texture then self.icon:SetTexture(texture); self.icon:Show() else self.icon:Hide() end
            if notInt and db.showShield then self.shield:Show() else self.shield:Hide() end; HideTicks()
            ApplyFont(); UpdateBarColor(notInt); UpdateBorder(); UpdateBackground(); UpdateIcon(); self:Show(); castBar.latency:Hide()
            ResetParticles()

        -- 2. CASTING NORMAL
        elseif event=="UNIT_SPELLCAST_START" then
            local name, _, texture, startMS, endMS, _, _, _, notInt = UnitCastingInfo("player")
            if not name then return end
            self.casting=true; self.channeling=false; self.isEmpowered=false; self.startTime=startMS/1000; self.endTime=endMS/1000; self.duration=self.endTime-self.startTime
            self.spellName:SetText(db.showSpellText ~= false and GetFmtName(name) or ""); if db.showIcon and texture then self.icon:SetTexture(texture); self.icon:Show() else self.icon:Hide() end
            if notInt and db.showShield then self.shield:Show() else self.shield:Hide() end; HideTicks()
            ApplyFont(); UpdateBarColor(notInt); UpdateBorder(); UpdateBackground(); UpdateIcon(); self:Show(); castBar.latency:Hide()
            ResetParticles()
            
        -- 3. CHANNELING (QUARTZ LOGIC)
        elseif event=="UNIT_SPELLCAST_CHANNEL_START" then
            local name, _, texture, startMS, endMS, _, _, spellID, notInt = UnitChannelInfo("player")
            if not name then return end
            
            self.casting=false; self.channeling=true; self.startTime=startMS/1000; self.endTime=endMS/1000; self.duration=self.endTime-self.startTime
            
            if EMPOWERED_SPELLS[name] then self.isEmpowered = true else self.isEmpowered = false end
            
            -- QUARTZ CALCULATION
            self.channelingDuration = self.duration
            self.totalTicks = getChannelingTicks(name, spellID)
            self.tickDuration = self.totalTicks > 0 and (self.channelingDuration / self.totalTicks) or 0
            self.tickPositions = {}
            for i = 1, self.totalTicks do
                self.tickPositions[i] = self.channelingDuration - (i - 1) * self.tickDuration
            end
            DrawTicks() -- Dibujar usando nueva lógica

            self.spellName:SetText(db.showSpellText ~= false and GetFmtName(name) or ""); if db.showIcon and texture then self.icon:SetTexture(texture); self.icon:Show() else self.icon:Hide() end
            if notInt and db.showShield then self.shield:Show() else self.shield:Hide() end; 
            ApplyFont(); UpdateBarColor(notInt); UpdateBorder(); UpdateBackground(); UpdateIcon(); self:Show(); castBar.latency:Hide()
            ResetParticles()
            
        elseif event=="UNIT_SPELLCAST_CHANNEL_UPDATE" or event=="UNIT_SPELLCAST_EMPOWER_UPDATE" then
            local _, _, _, startMS, endMS = UnitChannelInfo("player")
            if not startMS and event=="UNIT_SPELLCAST_EMPOWER_UPDATE" then startMS, endMS = select(4, UnitEmpowerCastingInfo("player")) end
            if startMS then self.startTime=startMS/1000; self.endTime=endMS/1000; self.duration=self.endTime-self.startTime end
            
        elseif event=="UNIT_SPELLCAST_STOP" or event=="UNIT_SPELLCAST_CHANNEL_STOP" or event=="UNIT_SPELLCAST_EMPOWER_STOP" or event=="UNIT_SPELLCAST_FAILED" or event=="UNIT_SPELLCAST_INTERRUPTED" then
            local cname, _, ctex, cstartMS, cendMS, _, _, _, cNotInt = UnitChannelInfo("player")
            if cname then
                self.casting=false; self.channeling=true; self.startTime=cstartMS/1000; self.endTime=cendMS/1000; self.duration=self.endTime-self.startTime
                if EMPOWERED_SPELLS[cname] then self.isEmpowered = true else self.isEmpowered = false end
                self.spellName:SetText(GetFmtName(cname)); if db.showIcon and ctex then self.icon:SetTexture(ctex); self.icon:Show() else self.icon:Hide() end
                if cNotInt and db.showShield then self.shield:Show() else self.shield:Hide() end; 
                -- Update Ticks on refresh
                DrawTicks()
                ApplyFont(); UpdateBarColor(cNotInt); UpdateBorder(); UpdateBackground(); UpdateIcon(); self:Show(); castBar.latency:Hide(); return
            end
            local name, _, texture, startMS, endMS, _, _, _, notInt = UnitCastingInfo("player")
            if name then
                self.casting=true; self.channeling=false; self.isEmpowered=false; self.startTime=startMS/1000; self.endTime=endMS/1000; self.duration=self.endTime-self.startTime
                self.spellName:SetText(db.showSpellText ~= false and GetFmtName(name) or ""); if db.showIcon and texture then self.icon:SetTexture(texture); self.icon:Show() else self.icon:Hide() end
                if notInt and db.showShield then self.shield:Show() else self.shield:Hide() end; HideTicks()
                ApplyFont(); UpdateBarColor(notInt); UpdateBorder(); UpdateBackground(); UpdateIcon(); self:Show(); castBar.latency:Hide(); return
            end
            self.casting=false; self.channeling=false; self.spellName:SetText(""); self.timer:SetText(""); self.icon:Hide(); self.shield:Hide(); HideTicks(); self:Hide()
        end
    end
    -- Register Events
    castBar:RegisterEvent("UNIT_SPELLCAST_START"); castBar:RegisterEvent("UNIT_SPELLCAST_STOP"); castBar:RegisterEvent("UNIT_SPELLCAST_FAILED"); castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START"); castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP"); castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    pcall(function()
        castBar:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
        castBar:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
        castBar:RegisterEvent("UNIT_SPELLCAST_EMPOWER_UPDATE")
    end)
    castBar:SetScript("OnEvent",OnCast)

    local function UpdateLatencyBar()
        if not db.showLatency then castBar.latency:Hide() return end
        if not (castBar.casting or castBar.channeling) then castBar.latency:Hide() return end
        local _, _, homeMS, worldMS = GetNetStats(); local ms = math.max(homeMS or 0, worldMS or 0)
        if ms <= 0 then castBar.latency:Hide() return end
        local frac = (ms / 1000) / (castBar.duration or 1); if frac > db.latencyMaxPercent then frac = db.latencyMaxPercent end
        local w = castBar:GetWidth() * frac; local minW = 2; if w < minW then w = minW end; if w <= 0.5 then castBar.latency:Hide() return end
        castBar.latency:ClearAllPoints(); local b = (db.borderEnabled and (db.borderThickness or 1)) or 0
        
        -- Logic Reverse/Empower Latency Direction
        local isFilling = false
        if castBar.isEmpowered or castBar.casting then isFilling = true
        elseif castBar.channeling and db.reverseChanneling then isFilling = true end

        if not isFilling then 
            castBar.latency:SetPoint("TOPLEFT", castBar, "TOPLEFT", b, -b); castBar.latency:SetPoint("BOTTOMLEFT", castBar, "BOTTOMLEFT", b, b); castBar.latency:SetWidth(w)
        else 
            castBar.latency:SetPoint("TOPRIGHT", castBar, "TOPRIGHT", -b, -b); castBar.latency:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", -b, b); castBar.latency:SetWidth(w)
        end
        local c = db.latencyColor or {1,0,0,0.5}; castBar.latency:SetColorTexture(c[1],c[2],c[3],c[4]); castBar.latency:Show()
    end

    castBar:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()
        local function GetFmtTimer(rem, dur)
            if db.showTimerText == false then return "" end
            local f = db.timerFormat or "Remaining"
            if f == "Duration" then return string.format("%.1f / %.1f", math.max(0, rem), dur) elseif f == "Total" then return string.format("%.1f", dur) else return string.format("%.1f", math.max(0, rem)) end
        end
        local function Upd(val, dur)
            self:SetMinMaxValues(0, dur); self:SetValue(val)
            local prog = 0; if dur > 0 then prog = val / dur end
            local isEmptying = (self.channeling and not self.isEmpowered and not db.reverseChanneling)
            UpdateSpark(prog, isEmptying and (1-prog) or prog)
        end

        if db.previewEnabled and not self.casting and not self.channeling then
            if not self.previewStart then self.previewStart = now end
            local dur = 3; local elap = (now - self.previewStart) % dur
            self.spellName:SetText("Preview Spell"); self.timer:SetText(GetFmtTimer(dur-elap, dur))
            Upd(elap, dur); UpdateBorder(); UpdateBackground(); UpdateIcon(); UpdateSparkColors(); self:Show(); UpdateLatencyBar() 
            if db.showIcon and castBar.icon:IsShown() then castBar.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
            return
        end
        if self.casting then
            local elap = now - (self.startTime or now); elap = math.max(0, math.min(elap, self.duration or 0))
            self.timer:SetText(GetFmtTimer((self.endTime or 0) - now, self.duration))
            Upd(elap, self.duration); UpdateLatencyBar(); return
        end
        if self.channeling then
            local rem = (self.endTime or now) - now; rem = math.max(0, rem)
            if self.isEmpowered or db.reverseChanneling then
                -- LLENAR (Empty -> Full)
                local elap = now - self.startTime
                if db.hideTimerOnChannel then self.timer:SetText("") else self.timer:SetText(GetFmtTimer(rem, self.duration)) end 
                Upd(elap, self.duration)
                if self.isEmpowered and self.StagePoints then UpdateStageLogic(self) end -- Check Empower Stages
            else
                -- VACIAR (Full -> Empty)
                if db.hideTimerOnChannel then self.timer:SetText("") else self.timer:SetText(GetFmtTimer(rem, self.duration)) end
                Upd(rem, self.duration)
            end
            UpdateLatencyBar(); return
        end
        self:SetValue(0); self.spellName:SetText(""); self.timer:SetText(""); self.icon:Hide(); self.shield:Hide(); HideTicks(); UpdateSpark(0,0); self:Hide()
    end)

    ReloadProfile = function()
        db = AscensionCastBarDB.profiles[AscensionCastBarDB.activeProfile]
        UpdateAnchor(); UpdateSparkSize(); UpdateIcon(); ApplyFont(); UpdateBarColor()
        UpdateBackground(); UpdateBorder(); UpdateTextLayout(); UpdateSparkColors()
        UpdateDefaultCastBarVisibility() 
        UpdateConfigControls(db)
        print(ADDON_TITLE..": Switched to profile '"..AscensionCastBarDB.activeProfile.."'.")
    end

    -- ==========================================================
    -- ===== UI CONFIGURATION - TABBED SYSTEM =====
    -- ==========================================================
    
    local configPanel = CreateFrame("Frame", "AscensionCastBarOptionsPanel", UIParent)
    configPanel.name = ADDON_TITLE
    if InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(configPanel) else local c = Settings.RegisterCanvasLayoutCategory(configPanel, ADDON_TITLE); Settings.RegisterAddOnCategory(c) end

    local mainTitle = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mainTitle:SetPoint("TOPLEFT", 16, -16); mainTitle:SetText(ADDON_TITLE .. " Settings")

    configPanel:SetScript("OnShow", function(self) 
        db = AscensionCastBarDB.profiles[AscensionCastBarDB.activeProfile] or defaults 
        UpdateConfigControls(db) 
        local pDD = _G["ACBProfDrop"]
        if pDD then UIDropDownMenu_SetText(pDD, AscensionCastBarDB.activeProfile) end
    end)

    local tabs = {}
    local contentFrames = {}
    local tabNames = {"General", "Visuals", "Text", "Effects", "Integration"}
    local selectedTab = 1

    local function SelectTab(id)
        selectedTab = id
        for i, tab in ipairs(tabs) do
            if i == id then
                tab:LockHighlight(); tab:SetEnabled(false) 
                if contentFrames[i] then contentFrames[i]:Show() end
            else
                tab:UnlockHighlight(); tab:SetEnabled(true)
                if contentFrames[i] then contentFrames[i]:Hide() end
            end
        end
    end

    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, configPanel, "UIPanelButtonTemplate")
        tab:SetSize(90, 24)
        if i == 1 then tab:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 15, -50)
        else tab:SetPoint("LEFT", tabs[i-1], "RIGHT", 5, 0) end
        tab:SetText(name)
        tab:SetScript("OnClick", function() SelectTab(i) end)
        tabs[i] = tab
        
        local scrollFrame = CreateFrame("ScrollFrame", nil, configPanel, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 15, -85); scrollFrame:SetPoint("BOTTOMRIGHT", -35, 15)
        local scrollChild = CreateFrame("Frame"); scrollFrame:SetScrollChild(scrollChild); scrollChild:SetSize(580, 500)
        scrollFrame:Hide()
        contentFrames[i] = scrollFrame
        tabs[i].child = scrollChild; tabs[i].cY = -10
    end

    local function AddHeader(tabId, text)
        local p = tabs[tabId].child; local y = tabs[tabId].cY
        local fs = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); fs:SetPoint("TOPLEFT", 10, y); fs:SetText(text)
        tabs[tabId].cY = y - 30
    end
    local function AddCheckbox(tabId, label, dbKey, cbFunc)
        local p = tabs[tabId].child; local y = tabs[tabId].cY
        local cb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate"); cb:SetPoint("TOPLEFT", 10, y); cb.text:SetText(label); cb:SetChecked(db[dbKey] or false)
        cb:SetScript("OnClick", function(self) db[dbKey] = self:GetChecked(); if cbFunc then cbFunc(db[dbKey]) end end)
        tabs[tabId].cY = y - 30
    end
    local function AddSlider(tabId, label, dbKey, min, max, step, cbFunc)
        local p = tabs[tabId].child; local y = tabs[tabId].cY
        local sName = "ACB_Sl_"..tabId.."_"..dbKey
        local sl = CreateFrame("Slider", sName, p, "OptionsSliderTemplate"); sl:SetPoint("TOPLEFT", 35, y-15); sl:SetWidth(180)
        sl:SetMinMaxValues(min, max); sl:SetValueStep(step); sl:SetObeyStepOnDrag(true); sl:SetValue(db[dbKey] or min)
        _G[sName.."Text"]:SetText(label); _G[sName.."Low"]:SetText(min); _G[sName.."High"]:SetText(max)
        local eb = CreateFrame("EditBox", nil, p, "InputBoxTemplate"); eb:SetSize(45, 20); eb:SetPoint("LEFT", sl, "RIGHT", 10, 0); eb:SetAutoFocus(false); eb:SetText(format("%.2f", db[dbKey] or min))
        local bM = CreateFrame("Button", nil, p, "UIPanelButtonTemplate"); bM:SetSize(20,20); bM:SetPoint("RIGHT", sl, "LEFT", -5, 0); bM:SetText("-")
        bM:SetScript("OnClick", function() local v = (db[dbKey] or min) - step; if v < min then v = min end; sl:SetValue(v) end)
        local bP = CreateFrame("Button", nil, p, "UIPanelButtonTemplate"); bP:SetSize(20,20); bP:SetPoint("LEFT", eb, "RIGHT", 5, 0); bP:SetText("+")
        bP:SetScript("OnClick", function() local v = (db[dbKey] or min) + step; if v > max then v = max end; sl:SetValue(v) end)
        sl:SetScript("OnValueChanged", function(self, v) v = math.floor((v/step)+0.5)*step; db[dbKey] = v; eb:SetText(format("%.2f", v)); if cbFunc then cbFunc(v) end end)
        eb:SetScript("OnEnterPressed", function(self) local v = tonumber(self:GetText()); if v then sl:SetValue(v) end; self:ClearFocus() end)
        tabs[tabId].cY = y - 50
    end
    local function AddColor(tabId, label, dbKey)
        local p = tabs[tabId].child; local y = tabs[tabId].cY
        local b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate"); b:SetSize(140, 22); b:SetPoint("TOPLEFT", 10, y); b:SetText(label)
        b:SetScript("OnClick", function()
            local c = db[dbKey] or {1,1,1,1}
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = function() local r,g,b = ColorPickerFrame:GetColorRGB(); local a = ColorPickerFrame:GetColorAlpha(); db[dbKey] = {r,g,b,a}; UpdateBarColor(); ApplyFont(); UpdateBackground(); UpdateBorder(); UpdateTextLayout(); UpdateSparkColors() end,
                opacityFunc = function() local r,g,b = ColorPickerFrame:GetColorRGB(); local a = ColorPickerFrame:GetColorAlpha(); db[dbKey] = {r,g,b,a}; UpdateBarColor(); ApplyFont(); UpdateBackground(); UpdateBorder(); UpdateTextLayout(); UpdateSparkColors() end,
                hasOpacity = true, opacity = c[4], r=c[1], g=c[2], b=c[3]
            })
        end)
        tabs[tabId].cY = y - 30
    end
    local function AddDropdown(tabId, label, dbKey, options, cbFunc)
        local p = tabs[tabId].child; local y = tabs[tabId].cY
        local fs = p:CreateFontString(nil, "OVERLAY", "GameFontNormal"); fs:SetPoint("TOPLEFT", 10, y-3); fs:SetText(label)
        local dd = CreateFrame("Frame", "ACB_DD_"..tabId..dbKey, p, "UIDropDownMenuTemplate")
        dd:SetPoint("LEFT", fs, "RIGHT", -10, 0)
        UIDropDownMenu_SetWidth(dd, 130)
        UIDropDownMenu_SetText(dd, db[dbKey] or options[1]) 
        UIDropDownMenu_Initialize(dd, function(self, level)
            for _, opt in ipairs(options) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = opt
                info.checked = (db[dbKey] == opt)
                info.func = function() 
                    db[dbKey] = opt
                    UIDropDownMenu_SetText(dd, opt)
                    if cbFunc then cbFunc(opt) end 
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        tabs[tabId].cY = y - 35
    end

    -- TAB 1: GENERAL
    local T_GEN = 1
    AddHeader(T_GEN, "Profile Management")
    
    local profList = {}
    for name, _ in pairs(AscensionCastBarDB.profiles) do table.insert(profList, name) end
    local pDD = CreateFrame("Frame", "ACBProfDrop", tabs[T_GEN].child, "UIDropDownMenuTemplate")
    pDD:SetPoint("TOPLEFT", -5, tabs[T_GEN].cY); tabs[T_GEN].cY = tabs[T_GEN].cY - 35
    local function InitP(self, level)
        for name, _ in pairs(AscensionCastBarDB.profiles) do
            local info = UIDropDownMenu_CreateInfo(); info.text = name; info.checked = (name == AscensionCastBarDB.activeProfile)
            info.func = function() AscensionCastBarDB.activeProfile = name; UIDropDownMenu_SetText(pDD, name); ReloadProfile() end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(pDD, InitP); UIDropDownMenu_SetText(pDD, AscensionCastBarDB.activeProfile)

    local tempProf = ""
    local ebProf = CreateFrame("EditBox", nil, tabs[T_GEN].child, "InputBoxTemplate"); ebProf:SetSize(150, 20); ebProf:SetPoint("TOPLEFT", 10, tabs[T_GEN].cY); ebProf:SetAutoFocus(false)
    ebProf:SetScript("OnTextChanged", function(self) tempProf = self:GetText() end)
    local btnNew = CreateFrame("Button", nil, tabs[T_GEN].child, "UIPanelButtonTemplate"); btnNew:SetSize(80, 22); btnNew:SetPoint("LEFT", ebProf, "RIGHT", 5, 0); btnNew:SetText("Create")
    btnNew:SetScript("OnClick", function() if tempProf ~= "" and not AscensionCastBarDB.profiles[tempProf] then AscensionCastBarDB.profiles[tempProf] = {}; for k,v in pairs(db) do AscensionCastBarDB.profiles[tempProf][k] = v end; AscensionCastBarDB.activeProfile = tempProf; UIDropDownMenu_SetText(pDD, tempProf); ReloadProfile() end end)
    local btnDel = CreateFrame("Button", nil, tabs[T_GEN].child, "UIPanelButtonTemplate"); btnDel:SetSize(80, 22); btnDel:SetPoint("LEFT", btnNew, "RIGHT", 5, 0); btnDel:SetText("Delete")
    btnDel:SetScript("OnClick", function() if AscensionCastBarDB.activeProfile ~= "Default" then AscensionCastBarDB.profiles[AscensionCastBarDB.activeProfile] = nil; AscensionCastBarDB.activeProfile = "Default"; UIDropDownMenu_SetText(pDD, "Default"); ReloadProfile() end end)
    tabs[T_GEN].cY = tabs[T_GEN].cY - 35

    AddHeader(T_GEN, "Dimensions & Layout")
    AddSlider(T_GEN, "Width (Base)", "width", 100, 600, 1, function() UpdateAnchor() end)
    AddSlider(T_GEN, "Height", "height", 10, 100, 1, function(v) castBar:SetHeight(v); UpdateSparkSize(); UpdateIcon() end)
    
    AddHeader(T_GEN, "Behavior")
    AddCheckbox(T_GEN, "Enable Test Mode", "previewEnabled", function(v) castBar.previewStart = nil; if v then castBar:Show() else castBar:Hide() end end)
    AddCheckbox(T_GEN, "Unlock / Draggable", "barDraggable")
    AddCheckbox(T_GEN, "Hide Blizzard Castbar", "hideDefaultCastbar", function(v) UpdateDefaultCastBarVisibility() end)

    local btnDef = CreateFrame("Button", nil, tabs[T_GEN].child, "UIPanelButtonTemplate")
    btnDef:SetSize(140, 22); btnDef:SetPoint("TOPLEFT", 10, tabs[T_GEN].cY - 10); btnDef:SetText("Restore Defaults")
    btnDef:SetScript("OnClick", function()
        for k,v in pairs(defaults) do db[k] = v end
        ReloadProfile()
        print(ADDON_TITLE..": Defaults restored for profile '"..AscensionCastBarDB.activeProfile.."'.")
    end)
    tabs[T_GEN].cY = tabs[T_GEN].cY - 40

    -- TAB 2: VISUALS
    local T_VIS = 2
    AddHeader(T_VIS, "Bar Appearance")
    AddCheckbox(T_VIS, "Use Class Color", "useClassColor", UpdateBarColor)
    AddColor(T_VIS, "Bar Color", "barColor")
    AddColor(T_VIS, "Background Color", "bgColor")
    AddCheckbox(T_VIS, "Enable Border", "borderEnabled", UpdateBorder)
    AddColor(T_VIS, "Border Color", "borderColor")
    AddSlider(T_VIS, "Border Thickness", "borderThickness", 1, 5, 1, UpdateBorder)

    AddHeader(T_VIS, "Icons & Indicators")
    AddCheckbox(T_VIS, "Show Spell Icon", "showIcon", UpdateIcon)
    AddCheckbox(T_VIS, "Detach Icon", "detachIcon", UpdateIcon)
    AddDropdown(T_VIS, "Icon Position", "iconAnchor", {"Left", "Right"}, UpdateIcon)
    AddSlider(T_VIS, "Icon Size (Detached)", "iconSize", 10, 64, 1, UpdateIcon)
    AddSlider(T_VIS, "Offset X (Detached)", "iconX", -200, 200, 1, UpdateIcon)
    AddSlider(T_VIS, "Offset Y (Detached)", "iconY", -200, 200, 1, UpdateIcon)

    AddHeader(T_VIS, "Combat Features")
    AddCheckbox(T_VIS, "Uninterruptible Shield", "showShield")
    AddColor(T_VIS, "Shielded Bar Color", "uninterruptibleColor")
    AddCheckbox(T_VIS, "Show Channel Ticks", "showChannelTicks")
    AddColor(T_VIS, "Ticks Color", "channelTicksColor")
    AddCheckbox(T_VIS, "Reverse Channeling", "reverseChanneling") -- NUEVA OPCION
    AddCheckbox(T_VIS, "Show Latency (Lag)", "showLatency")
    AddColor(T_VIS, "Latency Color", "latencyColor")
    AddSlider(T_VIS, "Latency Max Coverage (%)", "latencyMaxPercent", 0.1, 1.0, 0.05)

    -- TAB 3: TEXT
    local T_TXT = 3
    AddHeader(T_TXT, "Text Content")
    AddCheckbox(T_TXT, "Show Spell Name", "showSpellText")
    AddCheckbox(T_TXT, "Show Timer Text", "showTimerText")
    AddCheckbox(T_TXT, "Hide Timer on Channel", "hideTimerOnChannel")
    AddDropdown(T_TXT, "Timer Format", "timerFormat", {"Remaining", "Duration", "Total"})
    
    AddHeader(T_TXT, "Text Style")
    AddSlider(T_TXT, "Spell Name Font Size", "spellNameFontSize", 8, 32, 1, ApplyFont)
    AddSlider(T_TXT, "Timer Font Size", "timerFontSize", 8, 32, 1, ApplyFont)
    AddColor(T_TXT, "Font Color", "fontColor")
    AddCheckbox(T_TXT, "Truncate Spell Name", "truncateSpellName")
    AddSlider(T_TXT, "Max Characters", "truncateLength", 5, 100, 1)

    -- TAB 4: EFFECTS
    local T_FX = 4
    AddHeader(T_FX, "Animation Settings (Experimental)")
    AddCheckbox(T_FX, "Enable Spark", "enableSpark")
    AddDropdown(T_FX, "Style", "animStyle", {"Comet", "Orb", "Flux", "Helix", "Vortex", "Pulse", "Starfall", "Wave", "Particles", "Scanline", "Glitch", "Lightning", "Rainbow"})
    AddCheckbox(T_FX, "Enable Tails", "enableTails")
    AddSlider(T_FX, "Spark Intensity", "sparkIntensity", 0, 1, 0.05)
    AddSlider(T_FX, "Glow Intensity", "glowIntensity", 0, 1, 0.05)
    AddSlider(T_FX, "Scale", "sparkScale", 0.5, 3, 0.1, UpdateSparkSize)
    
    AddHeader(T_FX, "Fine Tuning")
    AddSlider(T_FX, "Spark Head Offset", "sparkOffset", -5, 5, 0.1)
    AddSlider(T_FX, "Head Length Offset", "headLengthOffset", -50, 50, 1)
    
    AddHeader(T_FX, "Colors")
    AddColor(T_FX, "Spark Head", "sparkColor")
    AddColor(T_FX, "Spark Glow", "glowColor")
    AddColor(T_FX, "Tail 1", "tail1Color")
    AddColor(T_FX, "Tail 2", "tail2Color")
    AddColor(T_FX, "Tail 3", "tail3Color")
    AddColor(T_FX, "Tail 4", "tail4Color")

    -- TAB 5: INTEGRATION
    local T_INT = 5
    AddHeader(T_INT, "Cooldown Manager Integration")
    AddCheckbox(T_INT, "Attach to CDM", "attachToCDM", UpdateAnchor)
    AddDropdown(T_INT, "Target Frame", "cdmTarget", {"Auto", "Essential", "Utility", "Custom"}, UpdateAnchor)
    AddSlider(T_INT, "Vertical Offset", "cdmYOffset", -100, 100, 1, UpdateAnchor)
    
    local ef = CreateFrame("EditBox", nil, tabs[T_INT].child, "InputBoxTemplate"); ef:SetSize(200, 20); ef:SetPoint("TOPLEFT", 10, tabs[T_INT].cY - 20); ef:SetAutoFocus(false); ef:SetText(db.cdmFrameName or "")
    ef:SetScript("OnEnterPressed", function(self) db.cdmFrameName = self:GetText(); UpdateAnchor(); self:ClearFocus() end)
    local fl = tabs[T_INT].child:CreateFontString(nil, "OVERLAY", "GameFontNormal"); fl:SetPoint("BOTTOMLEFT", ef, "TOPLEFT", 0, 2); fl:SetText("Custom Frame Name:")

    SelectTab(1)
    UpdateDefaultCastBarVisibility()

    SLASH_ASCENSIONCASTBAR1 = "/acb"
    SLASH_ASCENSIONCASTBAR2 = "/ascensioncastbar"
    SlashCmdList["ASCENSIONCASTBAR"] = function() if InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory(configPanel) else Settings.OpenToCategory(ADDON_TITLE) end end
end

local loader = CreateFrame("Frame"); loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent",function(self,event,addonName) if addonName == ADDON_NAME then InitializeAscensionCastBar() end end)