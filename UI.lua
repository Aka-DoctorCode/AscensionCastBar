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

-- AscensionCastBar/UI.lua
function AscensionCastBar:GetCDMTargetFrame()
    local target = self.db.profile.cdmTarget
    
    if target == "Buffs" then return _G["BuffIconCooldownViewer"]
    elseif target == "Essential" then return _G["EssentialCooldownViewer"]
    elseif target == "Utility" then return _G["UtilityCooldownViewer"]
    elseif target == "PlayerFrame" then return _G["PlayerFrame"]
    elseif target == "ActionBar1" then return _G["MainMenuBar"]
    elseif target == "ActionBar2" then return _G["MultiBarBottomLeft"]
    elseif target == "ActionBar3" then return _G["MultiBarBottomRight"]
    elseif target == "ActionBar4" then return _G["MultiBarRight"]
    elseif target == "ActionBar5" then return _G["MultiBarLeft"]
    elseif target == "ActionBar6" then return _G["MultiBar5"]
    elseif target == "ActionBar7" then return _G["MultiBar6"]
    elseif target == "ActionBar8" then return _G["MultiBar7"]
    elseif target == "PersonalResource" then return _G["PersonalResourceDisplayFrame"]
    end
    
    return nil
end

function AscensionCastBar:UpdateAnchor()
    if not self.castBar then return end
    
    local db = self.db.profile
    
    if not db.attachToCDM then
        self.castBar:ClearAllPoints()
        self.castBar:SetPoint(db.point, UIParent, db.relativePoint, db.manualX, db.manualY)
        self.castBar:SetWidth(db.manualWidth or 270)
        return
    end

    if db.cdmTarget == "ActionBar1" then
        if not self.actionBar1Proxy then
            self.actionBar1Proxy = CreateFrame("Frame", nil, UIParent)
            self.actionBar1Proxy:SetSize(1,1)
        end
        
        local minX, maxX, minY, maxY
        
        local buttonsFound = false
        for i = 1, 12 do
            local btn = _G["ActionButton" .. i]
            if btn and btn:IsShown() then
                local l, r, t, b = btn:GetLeft(), btn:GetRight(), btn:GetTop(), btn:GetBottom()
                if l and r and t and b then
                    if not minX or l < minX then minX = l end
                    if not maxX or r > maxX then maxX = r end
                    if not minY or b < minY then minY = b end
                    if not maxY or t > maxY then maxY = t end
                    buttonsFound = true
                end
            end
        end

        if buttonsFound then
            local width = maxX - minX
            local height = maxY - minY
            local centerX = (minX + maxX) / 2
            local centerY = (minY + maxY) / 2
            
            self.actionBar1Proxy:ClearAllPoints()
            self.actionBar1Proxy:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
            self.actionBar1Proxy:SetSize(width, height)
            
            self.castBar:ClearAllPoints()
            self.castBar:SetPoint("BOTTOM", self.actionBar1Proxy, "TOP", 0, db.cdmYOffset or 0)
            self.castBar:SetWidth(width > 10 and width or (db.manualWidth or 270))
            return
        else
            self.castBar:ClearAllPoints()
            self.castBar:SetPoint(db.point, UIParent, db.relativePoint, db.manualX, db.manualY)
            self.castBar:SetWidth(db.manualWidth or 270)
            return
        end
    end

    local targetFrame = self:GetCDMTargetFrame()
    
    if targetFrame then
        self.castBar:ClearAllPoints()
        self.castBar:SetPoint("BOTTOM", targetFrame, "TOP", 0, db.cdmYOffset or 0)
        
        local tWidth = targetFrame:GetWidth()
        local maxWidth = UIParent:GetWidth()
        
        if tWidth and tWidth > 10 and tWidth <= maxWidth then
            self.castBar:SetWidth(tWidth)
        else
            self.castBar:SetWidth(db.manualWidth or 270)
        end
    else
        self.castBar:ClearAllPoints()
        self.castBar:SetPoint(db.point, UIParent, db.relativePoint, db.manualX, db.manualY)
        self.castBar:SetWidth(db.manualWidth or 270)
    end
end

function AscensionCastBar:InitCDMHooks()
    local db = self.db.profile
    if not db.attachToCDM then return end

    -- 1. Setup Edit Mode events (just in case)
    if not self.editModeEventsRegistered then
        pcall(function() self:RegisterEvent("EDIT_MODE_LAYOUT_APPLIED", "UpdateAnchor") end)
        pcall(function() self:RegisterEvent("EDIT_MODE_LAYOUT_UPDATED", "UpdateAnchor") end)
        self.editModeEventsRegistered = true
    end

    -- 2. Clean up Personal Resource events if not used
    if db.cdmTarget ~= "PersonalResource" then
        if self.UnregisterEvent then
            pcall(function() self:UnregisterEvent("NAME_PLATE_UNIT_ADDED") end)
            pcall(function() self:UnregisterEvent("NAME_PLATE_UNIT_REMOVED") end)
        end
    else
        self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "UpdateAnchor")
        self:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "UpdateAnchor")
        self:UpdateAnchor()
        return
    end

    -- 3. TARGET SEARCH LOGIC
    local targetFrame = self:GetCDMTargetFrame()

    if targetFrame then
        -- === CASE A: FRAME FOUND ===
        if self.lastHookedFrame ~= targetFrame then
            self.lastHookedFrame = targetFrame
            
            local updateFunc = function() 
                if self.db.profile.attachToCDM then self:UpdateAnchor() end 
            end
            
            pcall(function()
                hooksecurefunc(targetFrame, "SetPoint", updateFunc)
                hooksecurefunc(targetFrame, "Show", updateFunc)
                hooksecurefunc(targetFrame, "Hide", updateFunc)
                hooksecurefunc(targetFrame, "SetSize", updateFunc)
                hooksecurefunc(targetFrame, "SetWidth", updateFunc)
                hooksecurefunc(targetFrame, "SetHeight", updateFunc)
                if targetFrame.HasScript and targetFrame:HasScript("OnSizeChanged") then
                    targetFrame:HookScript("OnSizeChanged", updateFunc)
                end
            end)
            
            self:UpdateAnchor()
        end
        
        -- Stop the search timer if it exists (Success)
        if self.cdmFinderTimer then
            self.cdmFinderTimer:Cancel()
            self.cdmFinderTimer = nil
        end
        
    else
        -- === CASE B: FRAME NOT FOUND YET ===
        -- Create a ticker to search every 1 second (Max 60 seconds)
        if not self.cdmFinderTimer then
            self.cdmFinderTimer = C_Timer.NewTicker(1, function()
                local tf = self:GetCDMTargetFrame()
                if tf then
                    self:InitCDMHooks() -- Call myself to hook it
                end
            end, 60)
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
    -- if cb.isEmpowered and cb.currentStage then
    --     local s = cb.currentStage
    --     local c = db.empowerStage1Color
    --     local scaleMultiplier = 1 + ((s - 1) * 0.05)
    --     cb:SetScale(scaleMultiplier)
        if cb.isEmpowered and cb.currentStage then
        local s = cb.currentStage
        local c = db.empowerStage1Color
        
        -- Reset scale to normal to avoid conflicts
        cb:SetScale(1.0) 
        
        -- Calculate 5% width increase per stage based on manualWidth
        local baseWidth = db.manualWidth or 270
        local widthMultiplier = 1 + ((s - 1) * 0.05)
        cb:SetWidth(baseWidth * widthMultiplier)

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
        local classColor = C_ClassColor.GetClassColor(playerClass) or { r = 1, g = 1, b = 1 }
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

function AscensionCastBar:UpdateTicks(countOrName, duration)
    self:HideTicks()
    if not self.db.profile.showChannelTicks then return end

    local count = 0
    local isEmpowered = type(countOrName) == "number"

    if isEmpowered then
        count = countOrName
    else
        count = self.CHANNEL_TICKS[countOrName]
    end

    if not count or count < 1 then return end

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

function AscensionCastBar:CreateActionBar1Proxy()
    if self.actionBar1Proxy and self.actionBar1Proxy:IsVisible() then
        return self.actionBar1Proxy
    end
    
    -- Crear frame proxy invisible
    self.actionBar1Proxy = CreateFrame("Frame", "AscensionCastBar_ActionBar1Proxy", UIParent)
    self.actionBar1Proxy:SetSize(1, 1)
    
    -- Encontrar todos los botones de la Action Bar 1
    local buttons = {}
    for i = 1, 12 do
        local button = _G["ActionButton"..i]
        if button and button:IsVisible() then
            table.insert(buttons, button)
        end
    end
    
    if #buttons == 0 then
        -- Fallback: usar posición por defecto de la Action Bar 1
        self.actionBar1Proxy:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 40)
        self.actionBar1Proxy:SetSize(500, 50)
        return self.actionBar1Proxy
    end
    
    -- Calcular bounding box de todos los botones
    local minX, maxX, minY, maxY
    
    for i, button in ipairs(buttons) do
        local left = button:GetLeft()
        local right = button:GetRight()
        local bottom = button:GetBottom()
        local top = button:GetTop()
        
        if left and right and bottom and top then
            if not minX or left < minX then minX = left end
            if not maxX or right > maxX then maxX = right end
            if not minY or bottom < minY then minY = bottom end
            if not maxY or top > maxY then maxY = top end
        end
    end
    
    if minX and maxX and minY and maxY then
        -- Posicionar el proxy en el centro del bounding box
        local centerX = (minX + maxX) / 2
        local centerY = (minY + maxY) / 2
        local width = maxX - minX
        local height = maxY - minY
        
        self.actionBar1Proxy:ClearAllPoints()
        self.actionBar1Proxy:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
        self.actionBar1Proxy:SetSize(width, height)
    else
        -- Fallback si no podemos calcular las posiciones
        self.actionBar1Proxy:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 40)
        self.actionBar1Proxy:SetSize(500, 50)
    end
    
    -- Configurar actualización periódica
    self.actionBar1Proxy.updateTimer = 0
    self.actionBar1Proxy:SetScript("OnUpdate", function(self, elapsed)
        self.updateTimer = self.updateTimer + elapsed
        if self.updateTimer > 0.5 then  -- Actualizar cada 0.5 segundos
            self.updateTimer = 0
            AscensionCastBar:UpdateActionBar1Proxy()
        end
    end)
    
    return self.actionBar1Proxy
end

-- Función para actualizar la posición del proxy
function AscensionCastBar:UpdateActionBar1Proxy()
    if not self.actionBar1Proxy then
        return
    end
    
    local buttons = {}
    for i = 1, 12 do
        local button = _G["ActionButton"..i]
        if button and button:IsVisible() then
            table.insert(buttons, button)
        end
    end
    
    if #buttons == 0 then return end
    
    local minX, maxX, minY, maxY
    
    for i, button in ipairs(buttons) do
        local left = button:GetLeft()
        local right = button:GetRight()
        local bottom = button:GetBottom()
        local top = button:GetTop()
        
        if left and right and bottom and top then
            if not minX or left < minX then minX = left end
            if not maxX or right > maxX then maxX = right end
            if not minY or bottom < minY then minY = bottom end
            if not maxY or top > maxY then maxY = top end
        end
    end
    
    if minX and maxX and minY and maxY then
        local centerX = (minX + maxX) / 2
        local centerY = (minY + maxY) / 2
        local width = maxX - minX
        local height = maxY - minY
        
        self.actionBar1Proxy:ClearAllPoints()
        self.actionBar1Proxy:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
        self.actionBar1Proxy:SetSize(width, height)
        
        -- SOLO si la cast bar está visible y adjuntada a ActionBar1, actualizarla
        if self.castBar and self.castBar:IsShown() and 
           self.db.profile.attachToCDM and self.db.profile.cdmTarget == "ActionBar1" then
            -- Actualizar la posición sin crear un bucle
            self.castBar:ClearAllPoints()
            self.castBar:SetPoint("BOTTOM", self.actionBar1Proxy, "TOP", 0, self.db.profile.cdmYOffset or 0)
            
            if width > 50 then
                self.castBar:SetWidth(width)
            end
        end
    end
end
