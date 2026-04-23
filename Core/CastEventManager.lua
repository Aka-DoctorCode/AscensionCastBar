-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: CastEventManager.lua
-- Version: @project-version@
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in
-- derivative works without express written permission.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local ADDON_NAME = "Ascension Cast Bar"
---@class AscensionCastBar
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
if not AscensionCastBar then return end

local reusableCastInfo = {}

---@param unit string
---@param channel boolean
---@return table|nil
local function GetSafeCastInfo(unit, channel)
    if not unit then return nil end

    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID

    if channel then
        name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
    else
        name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
    end

    if type(name) == "table" then
        local castData = name
        if not castData.name then return nil end

        reusableCastInfo.name = castData.name
        reusableCastInfo.text = castData.text or ""
        reusableCastInfo.texture = castData.icon or castData.texture or 0
        reusableCastInfo.startTime = castData.startTime or 0
        reusableCastInfo.endTime = castData.endTime or 0
        reusableCastInfo.isTradeSkill = castData.isTradeSkill or false
        reusableCastInfo.castID = castData.castID
        reusableCastInfo.notInterruptible = (castData.isInterruptible == false) or (castData.notInterruptible == true)
        reusableCastInfo.spellID = castData.spellID or 0
        reusableCastInfo.numStages = castData.numStages or 0

        return reusableCastInfo
    end

    if not name then return nil end
    reusableCastInfo.name = name
    reusableCastInfo.text = text or ""
    reusableCastInfo.texture = texture or 0
    reusableCastInfo.startTime = startTime or 0
    reusableCastInfo.endTime = endTime or 0
    reusableCastInfo.isTradeSkill = isTradeSkill or false
    reusableCastInfo.spellID = spellID or 0
    reusableCastInfo.notInterruptible = notInterruptible or false
    reusableCastInfo.castID = castID
    reusableCastInfo.numStages = 0

    return reusableCastInfo
end

-------------------------------------------------------------------------------
-- CAST START LOGIC
-------------------------------------------------------------------------------

function AscensionCastBar:handleCastStart(event, unit, ...)
    local channel = (event == "UNIT_SPELLCAST_CHANNEL_START")
    local empowered = (event == "UNIT_SPELLCAST_EMPOWER_START" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE")

    if unit and unit ~= "player" then return end

    local db = self.db.profile
    local cb = self.castBar
    if not cb then return end

    local info = GetSafeCastInfo("player", channel)
    if empowered and (not info or not info.name) then
        info = GetSafeCastInfo("player", true)
    end

    if not info or not info.name then
        cb.casting = false
        cb.channeling = false
        cb.isEmpowered = false
        cb.lastSpellName = nil
        cb:Hide()
        return
    end

    self:updateAnchor()

    if empowered then
        self:empowerStart(info)
    elseif channel then
        self:channelStart(info)
    else
        self:castStart(info)
    end
end

-------------------------------------------------------------------------------
-- STOP LOGIC
-------------------------------------------------------------------------------

function AscensionCastBar:handleCastStop(event, unit)
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
                self:handleCastStart("UNIT_SPELLCAST_CHANNEL_START", "player")
            else
                self:handleCastStart("UNIT_SPELLCAST_START", "player")
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
        if self.castBar.textCtx then self.castBar.textCtx:Hide() end
        self.castBar.spellName:SetText("")
        self.castBar.timer:SetText("")
        self.castBar.icon:Hide()
        self.castBar.shield:Hide()
        self:hideTicks()
        self:clearEmpowerStages()

        self:updateSpark(0, 0)
    end
end

function AscensionCastBar:stopCast()
    local cb = self.castBar
    if not cb then return end

    local channelInfo = GetSafeCastInfo("player", true)
    if channelInfo and channelInfo.name then
        self:handleCastStart("UNIT_SPELLCAST_CHANNEL_START", "player")
        return
    end

    local castInfo = GetSafeCastInfo("player", false)
    if castInfo and castInfo.name then
        self:handleCastStart("UNIT_SPELLCAST_START", "player")
        return
    end

    cb.casting = false
    cb.channeling = false
    cb.lastSpellName = nil
    cb.spellName:SetText("")
    cb.timer:SetText("")
    cb.icon:Hide()
    cb.shield:Hide()
    self:hideTicks()
    self:clearEmpowerStages()
    self:updateSpark(0, 0)

    if not self.db.profile.previewEnabled then
        cb:Hide()
    end
end

function AscensionCastBar:toggleTestMode(val)
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
            spellID = 234153,
            notInterruptible = false,
            numStages = state == "Empowered" and (IsPlayerSpell(408083) and 5 or 4) or 0
        }

        cb.lastSpellID = info.spellID
        cb.numStages = info.numStages or 0
        cb.duration = info.duration or 10

        if state == "Empowered" then
            self:empowerStart(info)
        elseif state == "Channel" then
            self:channelStart(info)
            self:updateTicks(234153, 0, 10)
        else
            self:castStart(info)
            self:hideTicks()
        end

        cb.lastSpellName = "Test Spell"

        self:updateAnchor()
        self:updateTextLayout()
        self:updateIcon()
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
            if cb.textCtx then cb.textCtx:Hide() end
        end
    end
end

-------------------------------------------------------------------------------
-- ON UPDATE (ANIMATION LOOP)
-------------------------------------------------------------------------------

function AscensionCastBar:onFrameUpdate(selfFrame, elapsed)
    local now = GetTime()
    local db = self.db.profile

    if selfFrame.casting or selfFrame.channeling then
        local start = selfFrame.startTime or now
        local duration = selfFrame.duration or 1
        local endTime = selfFrame.endTime or (start + duration)

        if now > (endTime + 0.5) and selfFrame.lastSpellName ~= "Test Spell" then
            self:handleCastStop(nil, "player")
            return
        end

        if db.previewEnabled and selfFrame.lastSpellName == "Test Spell" and now > endTime then
            selfFrame.startTime = now
            selfFrame.endTime = now + duration
            start = selfFrame.startTime
            endTime = selfFrame.endTime
        end

        if selfFrame.casting then
            self:castUpdate(now, db)
        elseif selfFrame.isEmpowered then
            self:empowerUpdate(now, db)
        else
            self:channelUpdate(now, db)
        end
        return
    end

    if not db.previewEnabled and selfFrame:IsShown() then
        selfFrame:SetValue(0)
        selfFrame.spellName:SetText("")
        selfFrame.timer:SetText("")
        selfFrame.icon:Hide()
        selfFrame.shield:Hide()
        if selfFrame.textCtx then selfFrame.textCtx:Hide() end
        self:hideTicks()
        self:clearEmpowerStages()
        self:updateSpark(0, 0)
        selfFrame:Hide()
    end
end
