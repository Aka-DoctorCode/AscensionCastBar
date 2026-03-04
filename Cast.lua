-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Cast.lua
-- Version: @project-version@
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in
-- derivative works without express written permission.
-------------------------------------------------------------------------------
local ADDON_NAME = "Ascension Cast Bar"
---@class AscensionCastBar
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

function AscensionCastBar:CastStart(info)
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

    self:SetupCastBarShared(info)
    self:UpdateBarColor(info.notInterruptible)
    self:UpdateTicks(info.spellID, 0, cb.duration)
end

function AscensionCastBar:CastUpdate(now, db)
    local cb = self.castBar
    local start = cb.startTime
    local duration = cb.duration
    local endTime = cb.endTime

    local elap = now - start
    elap = math.max(0, math.min(elap, duration))

    cb.timer:SetText(self:GetFormattedTimer(endTime - now, duration))

    cb:SetMinMaxValues(0, duration)
    cb:SetValue(elap)

    local prog = 0
    if duration > 0 then prog = elap / duration end
    self:UpdateSpark(prog, prog)

    self:UpdateLatencyBar(cb)
end
