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
    if not cb then return end

    -- 1. GET SPELL INFO
    -- We use UnitCastingInfo/UnitChannelInfo to get the authoritative state
        local name, _, texture, startMS, endMS, _, notInt, _, numStages
    if empowered then
        name, _, texture, startMS, endMS, _, notInt, _, _, numStages = UnitChannelInfo("player")
    elseif channel then
        name, _, texture, startMS, endMS, _, _, notInt = UnitChannelInfo("player")
    else
        name, _, texture, startMS, endMS, _, _, _, notInt = UnitCastingInfo("player")
    end

    if not name or not startMS or not endMS then 
        self:HandleCastStop(nil, "player")
        return 
    end
 
    local spellID = self.lastSpellID or name


    -- PREVENT RESTARTS: If the spell was already active, update times but not base start
    if (cb.casting or cb.channeling) and cb.lastSpellID == spellID then
        local rawDuration = (endMS - startMS) / 1000
        -- Safety check: ensure numStages is valid number
        if cb.isEmpowered and (cb.numStages and cb.numStages > 1) then
            local baseStages = cb.numStages - 1
            cb.duration = rawDuration * (cb.numStages / baseStages)
            cb.endTime = cb.startTime + cb.duration
        else
            cb.endTime = endMS / 1000
            cb.duration = rawDuration
        end
        -- Update ticks in case stages changed
        if empowered then self:UpdateTicks(cb.numStages, cb.duration) end
        self:UpdateBarColor()
        return
    end

    -- 2. UPDATE ANCHOR & SIZE
    self:UpdateAnchor()

    local startTime = startMS / 1000
    local rawDuration = (endMS - startMS) / 1000
    cb.lastSpellID = spellID
    cb.lastSpellName = name

    -- 3. CONFIGURE BAR STATE
    cb.casting = not channel
    cb.channeling = channel
    cb.isEmpowered = empowered

    if empowered then
        -- Font of Magic (ID: 408083) increases max stages from 3 to 4.
        local hasFontOfMagic = IsPlayerSpell and IsPlayerSpell(408083)
        local baseStages = (numStages and numStages > 0) and numStages or (hasFontOfMagic and 4 or 3)

        -- Segmentation: levels + 1 (for the hold/auto-launch phase)
        cb.numStages = baseStages + 1
        -- Stretch duration so bar doesn't hit 100% and 0s immediately upon finishing charge,
        -- allowing visualization of that "extra space" later.
        cb.duration = rawDuration * (cb.numStages / baseStages)
        cb.endTime = startTime + cb.duration
    else
        cb.numStages = 0
        cb.duration = rawDuration
        cb.endTime = endMS / 1000
    end

    cb.startTime = startTime
    cb.endTime = cb.endTime or (startTime + cb.duration)
    cb.currentStage = 1
    cb:SetScale(1.0)

    -- 4. UPDATE TEXT AND VISUALS
    -- Apply truncation logic if enabled
    local displayName = name
    if db.truncateSpellName and displayName and string.len(displayName) > db.truncateLength then
        displayName = string.sub(displayName, 1, db.truncateLength) .. "..."
    end

    cb.spellName:SetText(db.showSpellText and displayName or "")

    if db.showIcon and texture then
        cb.icon:SetTexture(texture); cb.icon:Show()
    else
        cb.icon:Hide()
    end

    cb.shield:Hide()

    if empowered then
        self:UpdateTicks(cb.numStages, cb.duration)
    elseif channel then
        self:UpdateTicks(spellID, cb.duration)
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

    -- SPELL QUEUE PROTECTION
    local cName, _, _, cstartMS, cendMS = UnitCastingInfo("player")
    local chName, _, _, chstartMS, chendMS = UnitChannelInfo("player")

    -- Get the new spell's ID
    local newSpellID = self.lastSpellID

    if cName then
        -- Check if it's the SAME spell (refresh) or a NEW spell
        if self.castBar and self.castBar.lastSpellID == newSpellID and self.castBar.lastSpellName == cName then
            -- SAME SPELL: Just update timings smoothly
            self.castBar.startTime = cstartMS / 1000
            self.castBar.endTime = cendMS / 1000
            self.castBar.duration = (cendMS - cstartMS) / 1000
        else
            -- NEW SPELL: Full restart
            self:HandleCastStart("UNIT_SPELLCAST_START", "player")
        end
        return
    end

    if chName then
        -- Same logic for channeled spells
        if self.castBar and self.castBar.lastSpellID == newSpellID and self.castBar.lastSpellName == chName then
            self.castBar.startTime = chstartMS / 1000
            self.castBar.endTime = chendMS / 1000
            self.castBar.duration = (chendMS - chstartMS) / 1000
        else
            self:HandleCastStart("UNIT_SPELLCAST_CHANNEL_START", "player")
        end
        return
    end

    -- TRUE STOP: Reset everything
    if self.castBar then
        self.castBar:SetScale(1.0)
        self.castBar.casting = false
        self.castBar.channeling = false
        self.castBar.isEmpowered = false
        self.castBar.lastSpellID = nil
        self.castBar.lastSpellName = nil
        self.castBar:Hide()
    end
end

function AscensionCastBar:StopCast()
    local cb = self.castBar
    if not cb then return end

    -- Check if we are actually casting/channeling before forcing a stop
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

    -- True stop
    cb.casting = false; cb.channeling = false; cb.lastSpellName = nil
    cb.spellName:SetText(""); cb.timer:SetText("")
    cb.icon:Hide(); cb.shield:Hide()
    self:HideTicks()
    self:UpdateSpark(0, 0)

    if not self.db.profile.previewEnabled then
        cb:Hide()
    end
end

function AscensionCastBar:GetEmpoweredStageWeights(numStages)
    -- Validate input
    if not numStages or type(numStages) ~= "number" or numStages < 1 then
        numStages = 1
    end
    -- Known stage configurations
    if numStages == 4 then     -- 3 Levels + 1 Hold
        return { 1.5, 1.0, 1.0, 1.5 }
    elseif numStages == 5 then -- 4 Levels + 1 Hold
        return { 1.5, 1.0, 1.0, 1.0, 1.5 }
    end  
    -- Fallback for any other number of stages
    local weights = {}
    for i = 1, numStages do 
        weights[i] = 1.0 
    end
    -- Ensure at least one weight
    if #weights == 0 then
        weights[1] = 1.0
    end
    return weights
end

function AscensionCastBar:ToggleTestMode(val)
    local cb = self.castBar
    if not cb then return end

    local db = self.db.profile
    if val then
        local state = db.testModeState or "Cast"
        cb.casting = (state == "Cast")
        cb.channeling = (state == "Channel" or state == "Empowered")
        cb.isEmpowered = (state == "Empowered")

        cb.duration = 10
        cb.startTime = GetTime()
        cb.endTime = GetTime() + 10
        cb.spellName:SetText("Test " .. state)
        cb.lastSpellName = "Test Spell"
        cb.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
        cb.icon:Show()

        if cb.isEmpowered then
            local hasFontOfMagic = IsPlayerSpell and IsPlayerSpell(408083)
            cb.numStages = hasFontOfMagic and 5 or 4
            self:UpdateTicks(cb.numStages, cb.duration)
        elseif cb.channeling then
            self:UpdateTicks("Test", cb.duration)
        else
            self:HideTicks()
        end

        self:UpdateBarColor()
        self:UpdateAnchor() -- Make sure anchor is updated for test mode
        cb:Show()
    else
        cb.casting = false
        cb.channeling = false
        cb.isEmpowered = false
        cb.lastSpellName = nil

        -- Clean up test attached frame
        if self.testAttachedFrame then
            self.testAttachedFrame:Hide()
        end

        if not db.previewEnabled then
            cb:Hide()
        end
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
        if f == "Duration" then
            return string.format("%.1f / %.1f", math.max(0, rem), dur)
        elseif f == "Total" then
            return string.format("%.1f", dur)
        else
            return string.format("%.1f", math.max(0, rem))
        end
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
        self:UpdateSpark(prog, isEmptying and (1 - prog) or prog)
    end

    if selfFrame.casting or selfFrame.channeling then
        local isCasting = selfFrame.casting
        local start = selfFrame.startTime or now
        local duration = selfFrame.duration or 1
        local endTime = selfFrame.endTime or (start + duration)

        -- Loop the test mode ONLY for the test spell
        if db.previewEnabled and selfFrame.lastSpellName == "Test Spell" and now > endTime then
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
                local weights = self:GetEmpoweredStageWeights(stages)

                -- Calculate current stage based on weights
                local currentStage = 1
                local cumulative = 0
                local totalWeight = 0
                for _, w in ipairs(weights) do totalWeight = totalWeight + w end

                for i, w in ipairs(weights) do
                    cumulative = cumulative + (w / totalWeight)
                    if pct <= cumulative then
                        currentStage = i
                        break
                    end
                end
                if pct > 0.99 then currentStage = stages end

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
        selfFrame:SetValue(0)
        selfFrame.spellName:SetText("")
        selfFrame.timer:SetText("")
        selfFrame.icon:Hide()
        selfFrame.shield:Hide()
        self:HideTicks()
        self:UpdateSpark(0, 0)
        self:HideAllSparkElements()
        selfFrame.casting = false
        selfFrame.channeling = false
        selfFrame.isEmpowered = false
        selfFrame.lastSpellID = nil
        selfFrame.lastSpellName = nil
        
        selfFrame:Hide()
    end
end

function AscensionCastBar:FlashInstantSpell(spellName, spellID)
    local db = self.db.profile
    local cb = self.castBar
    
    if not cb or not db.enableSpark then return end
    
    -- Quick display for 0.5 seconds
    cb.spellName:SetText(spellName)
    cb.lastSpellID = spellID
    cb.lastSpellName = spellName
    
    -- Show a quick spark flash
    cb:Show()
    self:UpdateSpark(1.0, 1.0)  -- Full spark
    
    -- Schedule hide
    C_Timer.After(0.5, function()
        if cb.lastSpellID == spellID then  -- Only hide if still showing this spell
            cb.spellName:SetText("")
            self:UpdateSpark(0, 0)
            if not (cb.casting or cb.channeling) then
                cb:Hide()
            end
        end
    end)
end