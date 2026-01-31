-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode 
-- File: Logic.lua
-- Version: 12.0.0
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code is the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in 
-- derivative works without express written permission.
-------------------------------------------------------------------------------
local ADDON_NAME = "Ascension Cast Bar"
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

-- Helper to normalize CastInfo return values into a consistent structure
local function GetSafeCastInfo(unit, channel)
    if not unit then return nil end

    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID
    
    if channel then
        name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
    else
        name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
    end

    if type(name) == "table" then
        local data = name
        if not data.name then return nil end 

        return {
            name = data.name,
            text = data.text,
            texture = data.icon or data.texture,
            startTime = data.startTime,
            endTime = data.endTime,
            isTradeSkill = data.isTradeSkill,
            castID = data.castID,
            notInterruptible = (data.isInterruptible == false) or data.notInterruptible,
            spellID = data.spellID,
            numStages = data.numStages or 0,
        }
    end

    if not name then return nil end

    return {
        name = name,
        text = text,
        texture = texture,
        startTime = startTime,
        endTime = endTime,
        isTradeSkill = isTradeSkill,
        spellID = spellID,
        notInterruptible = notInterruptible,
        castID = castID,
        numStages = 0,
    }
end

-- Logic Helpers
function AscensionCastBar:GetFormattedTimer(rem, dur)
    local db = self.db.profile
    if not db.showTimerText then return "" end
    local f = db.timerFormat
    if f == "Duration" then
        return string.format("%.1f / %.1f", math.max(0, math.floor(rem * 10) / 10), math.floor(dur * 10) / 10)
    elseif f == "Total" then
        return string.format("%.1f", math.floor(dur * 10) / 10)
    else
        return string.format("%.1f", math.max(0, math.floor(rem * 10) / 10))
    end
end

function AscensionCastBar:SetupCastBarShared(info)
    local cb = self.castBar
    local db = self.db.profile
    
    cb.currentStage = 1
    cb:SetScale(1.0)
    cb:SetAlpha(1.0)
    
    local name = info.name
    local texture = info.texture
    
    local displayName = name
    if db.truncateSpellName and string.len(displayName) > (db.truncateLength or 20) then
        displayName = string.sub(displayName, 1, db.truncateLength or 20) .. "..."
    end
    cb.spellName:SetText(db.showSpellText and displayName or "")
    
    if db.showIcon and texture then
        cb.icon:SetTexture(texture); cb.icon:Show()
    else
        cb.icon:Hide()
    end
    
    cb.shield:Hide()
    
    self:ApplyFont()
    self:UpdateBorder()
    self:UpdateBackground()
    self:UpdateIcon()
    self:UpdateSparkColors()
end

-- En AscensionCastBar/Logic.lua
function AscensionCastBar:HandleCastStart(event, unit, ...)
    local channel = (event == "UNIT_SPELLCAST_CHANNEL_START")
    local empowered = (event == "UNIT_SPELLCAST_EMPOWER_START" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE")
    if empowered then channel = true end

    if unit and unit ~= "player" then return end

    local db = self.db.profile
    local cb = self.castBar
    if not cb then return end

    local info = GetSafeCastInfo("player", channel)

    if not info or not info.name then 
        cb.casting = false
        cb.channeling = false
        cb.isEmpowered = false
        cb.lastSpellName = nil
        cb:Hide()
        return 
    end

    self:UpdateAnchor()
    
    if empowered then
        self:EmpowerStart(info)
    elseif channel then
        self:ChannelStart(info)
    else
        self:CastStart(info)
    end
end

-- AscensionCastBar/Logic.lua

function AscensionCastBar:HandleCastStop(event, unit)
    if unit and unit ~= "player" then return end

    local castData = GetSafeCastInfo("player", false)
    local channelData = GetSafeCastInfo("player", true)
    
    local cName = castData and castData.name
    local chName = channelData and channelData.name
    
    local currentSpell = self.castBar and self.castBar.lastSpellName

    local isEmpowerStop = (event == "UNIT_SPELLCAST_EMPOWER_STOP")

    if cName or chName then
        if (cName and cName == currentSpell) or (chName and chName == currentSpell) then
            if not isEmpowerStop then
                return 
            end
        else
            if chName then
                self:HandleCastStart("UNIT_SPELLCAST_CHANNEL_START", "player")
            else
                self:HandleCastStart("UNIT_SPELLCAST_START", "player")
            end
            return
        end
    end

    if self.castBar then
        self.castBar:SetScale(1.0)
        self.castBar.casting = false
        self.castBar.channeling = false
        self.castBar.isEmpowered = false
        self.castBar.lastSpellName = nil
        self.castBar:Hide()
        
        self:UpdateSpark(0, 0)
    end
end

function AscensionCastBar:StopCast()
    local cb = self.castBar
    if not cb then return end

    local channelInfo = GetSafeCastInfo("player", true)
    if channelInfo and channelInfo.name then
        self:HandleCastStart("UNIT_SPELLCAST_CHANNEL_START", "player")
        return
    end

    local castInfo = GetSafeCastInfo("player", false)
    if castInfo and castInfo.name then
        self:HandleCastStart("UNIT_SPELLCAST_START", "player")
        return
    end

    cb.casting = false
    cb.channeling = false
    cb.lastSpellName = nil
    cb.spellName:SetText("")
    cb.timer:SetText("")
    cb.icon:Hide()
    cb.shield:Hide()
    self:HideTicks()
    self:UpdateSpark(0, 0)

    if not self.db.profile.previewEnabled then
        cb:Hide()
    end
end

function AscensionCastBar:ToggleTestMode(val)
    local cb = self.castBar
    if not cb then return end

    local db = self.db.profile
    if val then
        local state = db.testModeState or "Cast"
        
        local info = {
            name = "Test " .. state,
            texture = "Interface\\Icons\\Spell_Nature_Lightning",
            startTime = GetTime() * 1000,
            endTime = (GetTime() + 10) * 1000,
            spellID = 234153, -- Example spell ID
            notInterruptible = false,
            numStages = state == "Empowered" and (IsPlayerSpell(408083) and 5 or 4) or 0
        }

        if state == "Empowered" then
            self:EmpowerStart(info)
        elseif state == "Channel" then
            self:ChannelStart(info)
        else
            self:CastStart(info)
        end
        
        cb.lastSpellName = "Test Spell" -- Flag for test mode
        self:UpdateAnchor()
    else
        cb.casting = false
        cb.channeling = false
        cb.isEmpowered = false
        cb.lastSpellName = nil

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

    if selfFrame.casting or selfFrame.channeling then
        local start = selfFrame.startTime or now
        local duration = selfFrame.duration or 1
        local endTime = selfFrame.endTime or (start + duration)

        if now > (endTime + 0.5) and selfFrame.lastSpellName ~= "Test Spell" then
            self:HandleCastStop(nil, "player")
            return
        end

        if db.previewEnabled and selfFrame.lastSpellName == "Test Spell" and now > endTime then
            selfFrame.startTime = now
            selfFrame.endTime = now + duration
            start = selfFrame.startTime
            endTime = selfFrame.endTime
        end

        if selfFrame.casting then
            self:CastUpdate(now, db)
        elseif selfFrame.isEmpowered then
            self:EmpowerUpdate(now, db)
        else
            self:ChannelUpdate(now, db)
        end
        return
    end

    if not db.previewEnabled and selfFrame:IsShown() then
        selfFrame:SetValue(0); selfFrame.spellName:SetText(""); selfFrame.timer:SetText("")
        selfFrame.icon:Hide(); selfFrame.shield:Hide()
        self:HideTicks()
        self:UpdateSpark(0, 0)
        selfFrame:Hide()
    end
end
