-- UI.lua
local ADDON_NAME = "Ascension Cast Bar"
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local LSM = LibStub("LibSharedMedia-3.0")

-- ==========================================================
-- FRAME CREATION
-- ==========================================================

function AscensionCastBar:CreateBar()
    -- Create an invisible anchor frame
    if not self.anchorFrame then
        self.anchorFrame = CreateFrame("Frame", nil, UIParent)
    end
    self.anchorFrame:SetSize(1, 1) -- Minimal size, just for positioning

    -- IMPORTANT: The cast bar is now a child of 'self.anchorFrame'
    local castBar = CreateFrame("StatusBar", "AscensionCastBarFrame", self.anchorFrame)
    castBar:SetClipsChildren(false)
    
    -- FIXED: Changed 'width' to 'manualWidth' and added safety defaults
    local width = self.db.profile.manualWidth or 270
    local height = self.db.profile.manualHeight or 24
    castBar:SetSize(width, height)

    -- The bar always stays in the exact center (0,0) of its invisible parent
    castBar:ClearAllPoints()
    castBar:SetPoint("CENTER", self.anchorFrame, "CENTER", 0, 0)

    castBar:SetFrameStrata("MEDIUM"); castBar:SetFrameLevel(10); castBar:Hide()
    self.castBar = castBar

    -- Bar Texture
    castBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")

    -- Background
    castBar.bg = castBar:CreateTexture(nil, "BACKGROUND")
    castBar.bg:SetAllPoints()

    -- Glow Frame
    castBar.glowFrame = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
    castBar.glowFrame:SetFrameLevel(9)
    castBar.glowFrame:SetPoint("TOPLEFT", -6, 6)
    castBar.glowFrame:SetPoint("BOTTOMRIGHT", 6, -6)
    castBar.glowFrame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Glow",
        edgeSize = 16,
    })
    castBar.glowFrame:Hide()

    -- Ticks
    castBar.ticksFrame = CreateFrame("Frame", nil, castBar)
    castBar.ticksFrame:SetAllPoints()
    castBar.ticksFrame:SetFrameLevel(15)
    castBar.ticks = {}

    -- Icon & Shield & Latency
    castBar.icon = castBar:CreateTexture(nil, "OVERLAY")
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
    castBar.sparkTail = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail:SetAtlas(
        "AftLevelup-SoftCloud", true); castBar.sparkTail:SetBlendMode("ADD")
    castBar.sparkTail2 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail2:SetAtlas(
        "AftLevelup-SoftCloud", true); castBar.sparkTail2:SetTexCoord(0, 1, 1, 0); castBar.sparkTail2:SetBlendMode("ADD")
    castBar.sparkTail3 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail3:SetAtlas(
        "AftLevelup-SoftCloud", true); castBar.sparkTail3:SetBlendMode("ADD")
    castBar.sparkTail4 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail4:SetAtlas(
        "AftLevelup-SoftCloud", true); castBar.sparkTail4:SetTexCoord(0, 1, 1, 0); castBar.sparkTail4:SetBlendMode("ADD")

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
    castBar.border = {
        top = castBar:CreateTexture(nil, "OVERLAY"),
        bottom = castBar:CreateTexture(nil, "OVERLAY"),
        left =
            castBar:CreateTexture(nil, "OVERLAY"),
        right = castBar:CreateTexture(nil, "OVERLAY")
    }
    castBar.border.top:SetPoint("TOPLEFT", 0, 0); castBar.border.top:SetPoint("TOPRIGHT", 0, 0);
    castBar.border.bottom:SetPoint("BOTTOMLEFT", 0, 0); castBar.border.bottom:SetPoint("BOTTOMRIGHT", 0, 0)
    castBar.border.left:SetPoint("TOPLEFT", 0, 0); castBar.border.left:SetPoint("BOTTOMLEFT", 0, 0);
    castBar.border.right:SetPoint("TOPRIGHT", 0, 0); castBar.border.right:SetPoint("BOTTOMRIGHT", 0, 0)

    -- OnUpdate Loop
    castBar:SetScript("OnUpdate", function(f, elapsed) self:OnFrameUpdate(f, elapsed) end)
end

-- ==========================================================
-- LAYOUT & ANCHORING
-- ==========================================================

function AscensionCastBar:UpdateAnchor()
    local db = self.db.profile
    if not self.anchorFrame or not self.castBar then return end

    local targetFrame = nil
    local useAttached = false

    -- 1. Determine if we should use attached mode
    if db.testAttached or db.attachToCDM then
        -- In testAttached mode OR when attachToCDM is enabled
        if db.attachToCDM then
            -- Only try to find actual CDM frame if attachToCDM is true
            if db.cdmTarget == "Auto" then
                targetFrame = _G["EssentialCooldownViewer"] or _G["EssentialCooldownsFrame"]
            elseif db.cdmTarget == "Buffs" then
                targetFrame = _G["TrackedBuffsViewer"] or _G["TrackedBuffsFrame"]
            elseif db.cdmTarget == "Essential" then
                targetFrame = _G["EssentialCooldownViewer"] or _G["EssentialCooldownsFrame"]
            elseif db.cdmTarget == "Utility" then
                targetFrame = _G["UtilityCooldownViewer"] or _G["UtilityCooldownsFrame"]
            else -- Custom
                if db.cdmFrameName then
                    targetFrame = _G[db.cdmFrameName]
                end
            end
        end

        -- Check if we have a valid target frame OR we're in testAttached mode
        if db.testAttached or (targetFrame and type(targetFrame) == "table" and targetFrame.GetWidth and targetFrame:IsVisible()) then
            useAttached = true

            -- If we're in testAttached mode but no target frame exists, simulate one
            if db.testAttached and not targetFrame then
                targetFrame = {
                    GetWidth = function() return db.manualWidth end,
                    GetHeight = function() return 30 end,
                    IsVisible = function() return true end
                }
            end
        end
    end

    if useAttached then
        -- === ATTACHED MODE ===
        if db.testAttached and not self.testAttachedFrame then
            -- Create a simulated frame for testing attached position
            self.testAttachedFrame = CreateFrame("Frame", nil, UIParent)
            self.testAttachedFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
            self.testAttachedFrame:SetSize(db.manualWidth, 30)
        end

        local actualFrame = targetFrame or self.testAttachedFrame
        if not actualFrame then
            -- Fallback to manual mode if no frame
            useAttached = false
        else
            self.anchorFrame:ClearAllPoints()
            self.anchorFrame:SetPoint("TOP", actualFrame, "BOTTOM", 0, db.cdmYOffset)

            -- Match target frame width
            local width = actualFrame:GetWidth()
            if width and width > 10 then
                self.castBar:SetWidth(width)
            else
                self.castBar:SetWidth(db.manualWidth) -- Fallback
            end

            -- Use Attached Height
            self.castBar:SetHeight(db.height)
        end
    end

    if not useAttached then
        -- === MANUAL / FALLBACK MODE ===
        if self.testAttachedFrame then
            self.testAttachedFrame:Hide()
        end

        self.anchorFrame:ClearAllPoints()
        self.anchorFrame:SetPoint(db.point, UIParent, db.relativePoint, db.manualX, db.manualY)

        -- Use Manual Size
        self.castBar:SetWidth(db.manualWidth)
        self.castBar:SetHeight(db.manualHeight)
    end

    self.castBar:ClearAllPoints()
    self.castBar:SetPoint("CENTER", self.anchorFrame, "CENTER", 0, 0)

    -- Update dependent visuals
    self:UpdateSparkSize()
    self:UpdateIcon()
    if self.UpdateTextLayout then self:UpdateTextLayout() end
end

function AscensionCastBar:InitCDMHooks()
    local db = self.db.profile
    if not db.attachToCDM then
        if self.lastHookedFrame then
            -- Note: We can't easily unhook hooksecurefunc, but we can stop reacting to it.
            self.lastHookedFrame = nil
        end
        return
    end

    local targetFrame
    if db.cdmTarget == "Auto" then
        targetFrame = _G["EssentialCooldownViewer"] or _G["EssentialCooldownsFrame"]
    elseif db.cdmTarget == "Buffs" then
        targetFrame = _G["TrackedBuffsViewer"] or _G["TrackedBuffsFrame"]
    elseif db.cdmTarget == "Essential" then
        targetFrame = _G["EssentialCooldownViewer"] or _G["EssentialCooldownsFrame"]
    elseif db.cdmTarget == "Utility" then
        targetFrame = _G["UtilityCooldownViewer"] or _G["UtilityCooldownsFrame"]
    else
        targetFrame = _G[db.cdmFrameName]
    end

    if targetFrame and type(targetFrame) == "table" then
        if self.lastHookedFrame ~= targetFrame then
            self.lastHookedFrame = targetFrame

            -- Use hooksecurefunc for perfect sync
            local hookFunc = function()
                if self.db.profile.attachToCDM and self.lastHookedFrame == targetFrame then
                    self:UpdateAnchor()
                end
            end

            pcall(function()
                hooksecurefunc(targetFrame, "SetSize", hookFunc)
                hooksecurefunc(targetFrame, "Show", hookFunc)
                hooksecurefunc(targetFrame, "Hide", hookFunc)
                -- Keep script hooks just in case
                self:HookScript(targetFrame, "OnShow", "UpdateAnchor")
                self:HookScript(targetFrame, "OnHide", "UpdateAnchor")
                self:HookScript(targetFrame, "OnSizeChanged", "UpdateAnchor")
            end)
        end
        self:UpdateAnchor()
        self.cdmRetryCount = 0
    else
        -- Retry with safety counter
        self.cdmRetryCount = (self.cdmRetryCount or 0) + 1
        if self.cdmRetryCount < 15 then
            C_Timer.After(2, function() self:InitCDMHooks() end)
        end
    end
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
        tx:SetColorTexture(c[1], c[2], c[3], c[4])
    end
    self.castBar.border.top:SetHeight(t); self.castBar.border.bottom:SetHeight(t)
    self.castBar.border.left:SetWidth(t); self.castBar.border.right:SetWidth(t)
end

function AscensionCastBar:UpdateBarColor()
    local db = self.db.profile
    local cb = self.castBar

    if not cb.glowFrame then return end
    cb.glowFrame:Hide()

    -- 1. EMPOWERED
    if cb.isEmpowered and cb.currentStage then
        local s = cb.currentStage
        local c = db.empowerStage1Color
        local scaleMultiplier = 1 + ((s - 1) * 0.05)
        cb:SetScale(scaleMultiplier)

        if s >= 5 then
            c = db.empowerStage5Color
        elseif s == 4 then
            c = db.empowerStage4Color
        elseif s == 3 then
            c = db.empowerStage3Color
        elseif s == 2 then
            c = db.empowerStage2Color
        end

        cb:SetStatusBarColor(c[1], c[2], c[3], c[4])

        if s >= cb.numStages then
            cb.glowFrame:SetBackdropBorderColor(c[1], c[2], c[3], 1)
            cb.glowFrame:Show()
        end
        return
    else
        cb:SetScale(1.0)
    end

    -- 2. CHANNEL
    if cb.channeling and db.useChannelColor then
        local c = db.channelColor
        cb:SetStatusBarColor(c[1], c[2], c[3], c[4])
        if db.channelBorderGlow then
            local gc = db.channelGlowColor
            cb.glowFrame:SetBackdropBorderColor(gc[1], gc[2], gc[3], gc[4])
            cb.glowFrame:Show()
        end

        -- 3. NORMAL CAST (Class Color)
    elseif db.useClassColor then
        local _, playerClass = UnitClass("player")
        local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerClass]) or { r = 1, g = 1, b = 1 }
        cb:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)

        -- 4. NORMAL CAST (Custom Color)
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
        cb.textCtx.bg:SetColorTexture(c[1], c[2], c[3], db.textBackdropEnabled and c[4] or 0)

        cb.spellName:ClearAllPoints(); cb.spellName:SetPoint("LEFT", cb.textCtx, "LEFT", 5, 0); cb.spellName:SetPoint(
            "RIGHT", cb.timer, "LEFT", -5, 0)
        cb.timer:ClearAllPoints(); cb.timer:SetPoint("RIGHT", cb.textCtx, "RIGHT", -5, 0)
    else
        cb.textCtx:ClearAllPoints(); cb.textCtx:SetAllPoints(cb); cb.textCtx.bg:SetColorTexture(0, 0, 0, 0)
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
    local r, g, b, a = unpack(db.fontColor)
    local sP = LSM:Fetch("font", db.spellNameFontLSM) or self.BAR_DEFAULT_FONT_PATH
    local tP = LSM:Fetch("font", db.timerFontLSM) or self.BAR_DEFAULT_FONT_PATH

    cb.spellName:SetFont(sP, db.spellNameFontSize, "OUTLINE")
    cb.spellName:SetTextColor(r, g, b, a)

    cb.timer:SetFont(tP, db.timerFontSize, "OUTLINE")
    cb.timer:SetTextColor(r, g, b, a)
end

function AscensionCastBar:HideTicks()
    for _, tick in ipairs(self.castBar.ticks) do tick:Hide() end
end

function AscensionCastBar:UpdateTicks(spellIDOrCount, duration)
    self:HideTicks()
    if not self.db.profile.showChannelTicks then return end

    local count = 0
    
    -- Determinar si es empowered (número pequeño) o spellID (número grande)
    local isEmpowered = (type(spellIDOrCount) == "number" and spellIDOrCount < 1000)
    
    if isEmpowered then
        -- Es un conteo de etapas para empowered spells
        count = spellIDOrCount
    elseif type(spellIDOrCount) == "number" then
        -- Es un spellID - usar el nuevo sistema condicional
        count = self:CalculateTicks(spellIDOrCount)
        
        -- Si es 0, intentar con tabla legada por nombre (fallback)
        if count == 0 and self.castBar.lastSpellName then
            count = self.CHANNEL_TICKS_LEGACY[self.castBar.lastSpellName] or 0
        end
    elseif type(spellIDOrCount) == "string" then
        -- Es un string (nombre del hechizo) - usar tabla legada
        count = self.CHANNEL_TICKS_LEGACY[spellIDOrCount] or 0
    else
        count = 0
    end

    -- Si aún es 0 y es un canal largo, calcular aproximación
    if count == 0 and duration and duration > 2 then
        count = math.floor(duration / 0.75)  -- Aprox 1 tick cada 0.75s
        count = math.min(count, 10)  -- Máximo 10 ticks
    end

    if count < 1 then return end

    -- Resto del código para dibujar ticks (mantener igual)...
    local db = self.db.profile
    local c = db.channelTicksColor
    local thickness = db.channelTicksThickness or 1
    local width = self.castBar:GetWidth()

    if isEmpowered then
        local weights = self:GetEmpoweredStageWeights(count)
        local totalWeight = 0
        for _, w in ipairs(weights) do totalWeight = totalWeight + w end

        local cumulative = 0
        for i = 1, count - 1 do
            cumulative = cumulative + (weights[i] / totalWeight)
            local tick = self.castBar.ticks[i]
            if not tick then
                tick = self.castBar.ticksFrame:CreateTexture(nil, "OVERLAY")
                self.castBar.ticks[i] = tick
            end
            tick:ClearAllPoints()
            tick:SetPoint("CENTER", self.castBar, "LEFT", width * cumulative, 0)
            tick:SetSize(thickness, self.castBar:GetHeight())
            tick:SetColorTexture(c[1], c[2], c[3], c[4])
            tick:Show()
        end
    else
        local w = width / count
        for i = 1, count - 1 do
            local tick = self.castBar.ticks[i]
            if not tick then
                tick = self.castBar.ticksFrame:CreateTexture(nil, "OVERLAY")
                self.castBar.ticks[i] = tick
            end
            tick:ClearAllPoints()
            tick:SetPoint("CENTER", self.castBar, "LEFT", w * i, 0)
            tick:SetSize(thickness, self.castBar:GetHeight())
            tick:SetColorTexture(c[1], c[2], c[3], c[4])
            tick:Show()
        end
    end
end

function AscensionCastBar:UpdateLatencyBar(castBar)
    local db = self.db.profile
    if not db.showLatency then
        castBar.latency:Hide()
        return
    end
    if not (castBar.casting or castBar.channeling) then
        castBar.latency:Hide()
        return
    end

    local _, _, homeMS, worldMS = GetNetStats()
    local ms = math.max(homeMS or 0, worldMS or 0)
    if ms <= 0 then
        castBar.latency:Hide()
        return
    end

    local frac = (ms / 1000) / (castBar.duration or 1)
    if frac > db.latencyMaxPercent then frac = db.latencyMaxPercent end

    local w = castBar:GetWidth() * frac
    local minW = 2
    if w < minW then w = minW end
    if w <= 0.5 then
        castBar.latency:Hide()
        return
    end

    castBar.latency:ClearAllPoints()
    local b = db.borderEnabled and db.borderThickness or 0

    local isFilling = false
    if castBar.isEmpowered or castBar.casting then
        isFilling = true
    elseif castBar.channeling and db.reverseChanneling then
        isFilling = true
    end

    if not isFilling then
        castBar.latency:SetPoint("TOPLEFT", castBar, "TOPLEFT", b, -b)
        castBar.latency:SetPoint("BOTTOMLEFT", castBar, "BOTTOMLEFT", b, b)
    else
        castBar.latency:SetPoint("TOPRIGHT", castBar, "TOPRIGHT", -b, -b)
        castBar.latency:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", -b, b)
    end

    castBar.latency:SetWidth(w)
    local c = db.latencyColor
    castBar.latency:SetColorTexture(c[1], c[2], c[3], c[4])
    castBar.latency:Show()
end
