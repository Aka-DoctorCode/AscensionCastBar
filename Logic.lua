-- Logic.lua
local ADDON_NAME = "Ascension Cast Bar"
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

-- Shared Logic helper
function AscensionCastBar:HandleCastStart(event, unit, ...)
    local channel = false
    local empowered = false
    
    if event == "UNIT_SPELLCAST_CHANNEL_START" then 
        channel = true
    elseif event == "UNIT_SPELLCAST_EMPOWER_START" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then 
        channel = true; empowered = true 
    end
    
    if unit and unit ~= "player" then return end
    
    local db = self.db.profile
    local cb = self.castBar
    
    -- 1. ACTUALIZAR ANCLAJE Y TAMAÑO
    self:UpdateAnchor()
    
    local name, _, texture, startMS, endMS, notInt, numStages
    local startTime, endTime
    
    -- 2. OBTENER INFORMACIÓN DEL HECHIZO
    if empowered then
        name, _, texture, startMS, endMS, _, _, _, _, numStages = UnitChannelInfo("player")
    elseif channel then
        name, _, texture, startMS, endMS, _, _, _, notInt = UnitChannelInfo("player")
    else
        name, _, texture, startMS, endMS, _, _, _, notInt = UnitCastingInfo("player")
    end
    
    if not name or not startMS or not endMS then return end
    
    endTime = endMS / 1000
    startTime = startMS / 1000
    cb.duration = (endMS - startMS) / 1000

    -- 3. CONFIGURAR ESTADO DE LA BARRA
    cb.casting = not channel
    cb.channeling = channel
    cb.isEmpowered = empowered
    cb.numStages = numStages or 0
    
    if empowered then
        if cb.numStages == 0 then cb.numStages = 5 else cb.numStages = cb.numStages + 1 end
    end

    cb.startTime = startTime
    cb.endTime = endTime
    cb.currentStage = 1 
    cb:SetScale(1.0)
    
    -- 4. ACTUALIZAR TEXTO Y VISUALES
    cb.spellName:SetText(db.showSpellText and name or "")
    if db.showIcon and texture then 
        cb.icon:SetTexture(texture); cb.icon:Show() 
    else 
        cb.icon:Hide() 
    end
    
    if notInt and db.showShield then cb.shield:Show() else cb.shield:Hide() end
    
    if empowered then
        self:UpdateTicks(cb.numStages, cb.duration)
    elseif channel then
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
end

function AscensionCastBar:HandleCastStop(event, unit)
    if unit and unit ~= "player" then return end
    
    if self.castBar then
        self.castBar:SetScale(1.0)
    end
    
    self.castBar.casting = false
    self.castBar.channeling = false
    self.castBar.isEmpowered = false
    self.castBar:Hide()
end

function AscensionCastBar:StopCast()
    local cb = self.castBar
    local cname, _, ctex, cstartMS, cendMS, _, _, _, cNotInt = UnitChannelInfo("player")
    if cname then
        self:HandleCastStart("UNIT_SPELLCAST_CHANNEL_START", "player")
        return
    end
    
    local name, _, texture, startMS, endMS, _, _, _, notInt = UnitCastingInfo("player")
    if name then
        self:HandleCastStart("UNIT_SPELLCAST_START", "player")
        return
    end
    
    cb.casting=false; cb.channeling=false
    cb.spellName:SetText(""); cb.timer:SetText("")
    cb.icon:Hide(); cb.shield:Hide()
    self:HideTicks()
    self:UpdateSpark(0,0)
    
    if not self.db.profile.previewEnabled then
        cb:Hide()
    end
end

function AscensionCastBar:ToggleTestMode(val)
    local cb = self.castBar
    if not cb then return end
    
    if val then
        cb.casting = true
        cb.duration = 10
        cb.startTime = GetTime()
        cb.endTime = GetTime() + 10
        cb.spellName:SetText("Test Spell")
        cb.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
        cb.icon:Show()
        self:UpdateBarColor(false)
        self:UpdateAnchor()
        cb:Show()
    else
        cb.casting = false
        cb.channeling = false
        cb:Hide()
    end
end

-- ==========================================================
-- ON UPDATE (ANIMATION LOOP)
-- ==========================================================

function AscensionCastBar:OnFrameUpdate(selfFrame, elapsed)
    local now = GetTime()
    local db = self.db.profile
    
    local function GetFmtTimer(rem, dur)
        if not db.showTimerText then return "" end
        local f = db.timerFormat
        if f == "Duration" then return string.format("%.1f / %.1f", math.max(0, rem), dur) 
        elseif f == "Total" then return string.format("%.1f", dur) 
        else return string.format("%.1f", math.max(0, rem)) end
    end

    local function Upd(val, dur, forceEmptying)
        selfFrame:SetMinMaxValues(0, dur)
        selfFrame:SetValue(val)
        local prog = 0
        if dur > 0 then prog = val / dur end
        local isEmptying = forceEmptying
        if isEmptying == nil then
             isEmptying = (selfFrame.channeling and not selfFrame.isEmpowered and not db.reverseChanneling)
        end
        self:UpdateSpark(prog, isEmptying and (1-prog) or prog)
    end

    if selfFrame.casting or selfFrame.channeling then
        local isCasting = selfFrame.casting
        local start = selfFrame.startTime or now
        local duration = selfFrame.duration or 1
        local endTime = selfFrame.endTime or (start + duration)
        
        -- Loop the test mode cast
        if db.previewEnabled and now > endTime then
            selfFrame.startTime = now
            selfFrame.endTime = now + duration
            start = selfFrame.startTime
            endTime = selfFrame.endTime
        end

        if isCasting then
            local elap = now - start
            elap = math.max(0, math.min(elap, duration))
            selfFrame.timer:SetText(GetFmtTimer(endTime - now, duration))
            Upd(elap, duration)
            self:UpdateLatencyBar(selfFrame)
        else -- Channeling
            local rem = endTime - now
            rem = math.max(0, rem)
            local elap = now - start
            
            if selfFrame.isEmpowered then
                local pct = math.max(0, math.min(elap / duration, 1))
                local stages = selfFrame.numStages or 1
                if stages < 1 then stages = 1 end
                
                local currentStage = math.floor(pct * stages) + 1
                if currentStage > stages then currentStage = stages end
                
                if currentStage ~= selfFrame.currentStage then
                    selfFrame.currentStage = currentStage
                    self:UpdateBarColor()
                end
                
                selfFrame.timer:SetText(db.hideTimerOnChannel and "" or GetFmtTimer(rem, duration))
                Upd(elap, duration, false) 
            elseif db.reverseChanneling then
                selfFrame.timer:SetText(db.hideTimerOnChannel and "" or GetFmtTimer(rem, duration))
                Upd(elap, duration, false)
            else
                selfFrame.timer:SetText(db.hideTimerOnChannel and "" or GetFmtTimer(rem, duration))
                Upd(rem, duration, true)
            end
            self:UpdateLatencyBar(selfFrame)
        end
        return
    end

    if not db.previewEnabled then
        selfFrame:SetValue(0); selfFrame.spellName:SetText(""); selfFrame.timer:SetText("")
        selfFrame.icon:Hide(); selfFrame.shield:Hide()
        self:HideTicks()
        self:UpdateSpark(0,0)
        selfFrame:Hide()
    end
end