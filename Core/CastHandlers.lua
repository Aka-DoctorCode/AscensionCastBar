-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: CastHandlers.lua
-- Version: V55
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

-------------------------------------------------------------------------------
-- CAST HANDLERS (from Cast.lua)
-------------------------------------------------------------------------------

function AscensionCastBar:castStart(info)
    local cb = self.castBar
    if not info.startTime or not info.endTime then return end

    cb.casting = true
    cb.channeling = false
    cb.isEmpowered = false
    cb.lastSpellName = info.name
    cb.startTime = info.startTime / 1000
    cb.duration = (info.endTime - info.startTime) / 1000
    cb.endTime = cb.startTime + cb.duration

    cb:Show()

    self:setupCastBarShared(info)
    self:updateBarColor(info.notInterruptible)
    self:updateTicks(info.spellID, 0, cb.duration)
end

function AscensionCastBar:castUpdate(now, db)
    local cb = self.castBar
    local start = cb.startTime
    local duration = cb.duration
    local endTime = cb.endTime

    local elap = now - start
    elap = math.max(0, math.min(elap, duration))

    cb.timer:SetText(self:getFormattedTimer(endTime - now, duration))

    cb:SetMinMaxValues(0, duration)
    cb:SetValue(elap)

    local prog = 0
    if duration > 0 then prog = elap / duration end
    self:updateSpark(prog, prog)

    self:updateLatencyBar(cb)
end

-------------------------------------------------------------------------------
-- CHANNEL HANDLERS (from Channel.lua)
-------------------------------------------------------------------------------

function AscensionCastBar:channelStart(info)
    local cb = self.castBar
    local db = self.db.profile

    cb.casting = false
    cb.channeling = true
    cb.isEmpowered = false
    cb.lastSpellName = info.name

    cb.startTime = info.startTime / 1000
    cb.endTime = info.endTime / 1000
    cb.duration = cb.endTime - cb.startTime
    cb.maxValue = cb.duration

    cb.duration = (info.endTime - info.startTime) / 1000
    cb.endTime = cb.startTime + cb.duration
    local ticks = 0
    if info.spellID == 234153 then
        ticks = 5
    elseif info.spellID and self.channelTicks then
        local tData = self.channelTicks[info.spellID]
        if type(tData) == "function" then
            ticks = tData(cb.duration)
        else
            ticks = tData or 0
        end
    end
    cb.totalTicks = (ticks > 0) and ticks or 1

    cb:Show()

    self:setupCastBarShared(info)
    self:updateBarColor(info.notInterruptible)
    self:updateTicks(info.spellID, 0, cb.duration)
end

function AscensionCastBar:channelUpdate(now, db)
    local cb = self.castBar
    local start = cb.startTime
    local duration = cb.duration
    local endTime = cb.endTime

    local rem = endTime - now
    rem = math.max(0, rem)
    local elap = now - start

    cb.timer:SetText(db.hideTimerOnChannel and "" or self:getFormattedTimer(rem, duration))

    cb:SetMinMaxValues(0, duration)

    if db.reverseChanneling then
        cb:SetValue(elap)
        local prog = 0
        if duration > 0 then prog = elap / duration end
        self:updateSpark(prog, prog)
    else
        cb:SetValue(rem)
        local prog = 0
        if duration > 0 then prog = rem / duration end
        self:updateSpark(prog, 1 - prog)
    end

    self:updateLatencyBar(cb)

    if cb.glowFrame then cb.glowFrame:Hide() end
end

-------------------------------------------------------------------------------
-- EMPOWER UTILS
-------------------------------------------------------------------------------


function AscensionCastBar:getStageTint(i)
    if self.stageTints and self.stageTints[i] then return unpack(self.stageTints[i]) end
    return 0.95, 0.85, 0.2, 0.4
end

function AscensionCastBar:getEmpoweredStageWeights(numStages)
    if numStages == 4 then
        return { 1.5, 1.0, 1.0, 1.5 }
    elseif numStages == 5 then
        return { 1.5, 1.0, 1.0, 1.0, 1.5 }
    end
    local w = {}
    if numStages and numStages > 0 then
        for i = 1, numStages do w[i] = 1 end
    end
    return w
end

function AscensionCastBar:clearEmpowerStages()
    local cb = self.castBar
    if not cb then return end

    if cb.stagePips then
        for _, pip in ipairs(cb.stagePips) do
            pip:Hide()
        end
    end

    if cb.stageTiers then
        for _, tier in ipairs(cb.stageTiers) do
            if tier.pulse then tier.pulse:Stop() end
            if tier.tint then tier.tint:Hide() end
        end
    end
end

function AscensionCastBar:addEmpowerStages(numStages)
    local cb = self.castBar
    if not cb or numStages < 2 then return end

    self:clearEmpowerStages()

    local db = self.db.profile
    local border = (db.borderEnabled and db.borderThickness) or 0
    local width = cb:GetWidth() or 270
    local usableW = math.max(1, width - (border * 2))

    local stageMaxMS = 0
    local durations = {}
    for i = 1, cb.numStages do
        local d = GetUnitEmpowerStageDuration("player", i - 1) or 0
        if i == cb.numStages then d = GetUnitEmpowerHoldAtMaxTime("player") or 0 end
        durations[i] = d
        stageMaxMS = stageMaxMS + d
    end

    if stageMaxMS <= 0 then return end

    local cumMS = 0
    for i = 1, cb.numStages do
        local d = durations[i]
        local leftPortion = cumMS / stageMaxMS
        cumMS = cumMS + d
        local rightPortion = cumMS / stageMaxMS

        local left = border + (usableW * leftPortion)
        local right = border + (usableW * rightPortion)

        -- Create/Get Tier
        local tier = cb.stageTiers[i]
        if not tier then
            tier = {}
            tier.tint = cb.empowerStageFrame:CreateTexture(nil, "ARTWORK", nil, 1)
            tier.tint:SetBlendMode("BLEND")

            -- Simple Pulse Animation
            tier.pulse = tier.tint:CreateAnimationGroup()
            local a = tier.pulse:CreateAnimation("Alpha")
            a:SetFromAlpha(0.8)
            a:SetToAlpha(0.4)
            a:SetDuration(0.3)
            a:SetSmoothing("OUT")

            cb.stageTiers[i] = tier
        end

        tier.tint:ClearAllPoints()
        tier.tint:SetPoint("TOPLEFT", cb, "TOPLEFT", left, -border)
        tier.tint:SetPoint("BOTTOMRIGHT", cb, "BOTTOMLEFT", right, border)

        local r, g, b, a = self:getStageTint(i)
        tier.tint:SetColorTexture(r, g, b, a)
        tier._baseAlpha = a
        tier.tint:Hide() -- Hidden by default to preserve the standard backdrop

        -- Create/Get Pip (except for the last hold stage which is the end of the bar)
        if i < cb.numStages then
            local pip = cb.stagePips[i]
            if not pip then
                pip = CreateFrame("Frame", nil, cb.empowerStageFrame, "CastingBarFrameStagePipTemplate")
                cb.stagePips[i] = pip
            end
            pip:ClearAllPoints()
            pip:SetPoint("TOP", cb, "TOPLEFT", right, -border)
            pip:SetPoint("BOTTOM", cb, "BOTTOMLEFT", right, border)
            pip:SetShown(db.showEmpowerStages)
        end
    end
end

function AscensionCastBar:updateEmpowerStageHighlight(currentStage)
    local cb = self.castBar
    if not cb or not cb.stageTiers then return end

    -- Ensure only the active tier is shown and pulsing, keeping the backdrop intact
    for i, tier in ipairs(cb.stageTiers) do
        if i == currentStage then
            tier.tint:Show()
            if tier.pulse then tier.pulse:Play() end
        else
            tier.tint:Hide()
            if tier.pulse then tier.pulse:Stop() end
        end
    end
end

function AscensionCastBar:updateEmpowerGeometry()
    local cb = self.castBar
    if not cb or not cb.stageTiers then return end

    local db = self.db.profile
    local border = (db.borderEnabled and db.borderThickness) or 0
    local width = cb:GetWidth() or 270
    local usableW = math.max(1, width - (border * 2))

    local stageMaxMS = 0
    if cb.stagePoints and #cb.stagePoints > 0 and cb.duration then
        stageMaxMS = cb.duration * 1000
    else
        return
    end

    for i = 1, cb.numStages do
        local leftPortion = (i == 1) and 0 or (cb.stagePoints[i - 1] / stageMaxMS)
        local rightPortion = (i == cb.numStages) and 1 or (cb.stagePoints[i] / stageMaxMS)

        local left = border + (usableW * leftPortion)
        local right = border + (usableW * rightPortion)

        if cb.stageTiers[i] and cb.stageTiers[i].tint then
            cb.stageTiers[i].tint:SetPoint("TOPLEFT", cb, "TOPLEFT", left, -border)
            cb.stageTiers[i].tint:SetPoint("BOTTOMRIGHT", cb, "BOTTOMLEFT", right, border)
        end
        if i < cb.numStages and cb.stagePips and cb.stagePips[i] then
            cb.stagePips[i]:SetPoint("TOP", cb, "TOPLEFT", right, -border)
            cb.stagePips[i]:SetPoint("BOTTOM", cb, "BOTTOMLEFT", right, border)
        end
    end

    if cb.ticks then
        local numPips = cb.numStages - 1
        for i = 1, numPips do
            local cumulative = 0
            if cb.stagePoints and cb.stagePoints[i] then
                cumulative = cb.stagePoints[i] / stageMaxMS
            end
            if cb.ticks[i] then
                cb.ticks[i]:SetPoint("CENTER", cb, "LEFT", width * cumulative, 0)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- EMPOWER HANDLERS (from Empower.lua)
-------------------------------------------------------------------------------

local function GetStageDurationMS(unit, stage, numStages)
    if stage == numStages then
        return GetUnitEmpowerHoldAtMaxTime(unit or "player") or 0
    end
    return GetUnitEmpowerStageDuration(unit or "player", stage - 1) or 0
end

function AscensionCastBar:empowerStart(info)
    local cb = self.castBar
    if not cb then return end

    cb.casting = false
    cb.channeling = true
    cb.isEmpowered = true
    cb.lastSpellName = info.name

    local numStages = info.numStages or 0
    if numStages == 0 then
        local _, _, _, _, _, _, _, _, _, apiNumStages = UnitChannelInfo("player")
        numStages = apiNumStages or 0
    end

    if numStages < 2 then
        self:castStart(info)
        return
    end

    cb.numStages = numStages + 1
    cb.startTime = info.startTime / 1000

    local stageMaxMS = 0
    cb.stagePoints = {}
    for i = 1, cb.numStages do
        local d = GetStageDurationMS("player", i, cb.numStages)
        if d and d > 0 then
            stageMaxMS = stageMaxMS + d
            if i < cb.numStages then
                cb.stagePoints[i] = stageMaxMS
            end
        end
    end

    if stageMaxMS <= 0 then
        self:castStart(info)
        return
    end

    cb.duration = stageMaxMS / 1000
    cb.endTime = cb.startTime + cb.duration
    cb.currentStage = 1

    cb:Show()

    self:setupCastBarShared(info)
    self:updateBarColor(info.notInterruptible)

    self:addEmpowerStages(numStages)
    self:updateTicks(info.spellID, numStages, cb.duration)
    
    if self.updateEmpowerStageHighlight then
        self:updateEmpowerStageHighlight(1)
    end
end

function AscensionCastBar:empowerUpdate(now, db)
    local cb = self.castBar
    if not cb or not cb.duration or cb.duration <= 0 then return end

    local start = cb.startTime
    local duration = cb.duration
    local endTime = cb.endTime

    local rem = endTime - now
    rem = math.max(0, rem)
    local elap = now - start

    local stageValueMS = (elap / duration) * (cb.duration * 1000)
    local maxStage = 0
    if cb.stagePoints then
        for i = 1, #cb.stagePoints do
            if stageValueMS > cb.stagePoints[i] then
                maxStage = i
            else
                break
            end
        end
    end

    local currentStage = math.max(1, math.min(cb.numStages or 1, maxStage + 1))

    if currentStage ~= cb.currentStage then
        cb.currentStage = currentStage
        self:updateBarColor()
        if self.updateEmpowerStageHighlight then
            self:updateEmpowerStageHighlight(currentStage)
        end
    end

    cb.timer:SetText(db.hideTimerOnChannel and "" or self:getFormattedTimer(rem, duration))

    cb:SetMinMaxValues(0, duration)
    cb:SetValue(elap)

    local prog = 0
    if duration > 0 then prog = elap / duration end
    self:updateSpark(prog, prog)

    self:updateLatencyBar(cb)
end
