-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Text.lua
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
local LSM = LibStub("LibSharedMedia-3.0")

function AscensionCastBar:updateTextLayout()
    local db = self.db.profile
    local cb = self.castBar
    if not cb or not cb.textCtx then return end

    if db.detachText then
        cb.textCtx:ClearAllPoints()
        cb.textCtx:SetPoint("CENTER", UIParent, "CENTER", db.textX, db.textY)
        cb.textCtx:SetSize(db.textWidth, db.spellNameFontSize + 10)

        local c = db.textBackdropColor
        if db.textBackdropEnabled then
            cb.textCtx.bg:SetColorTexture(c[1], c[2], c[3], c[4])
        else
            cb.textCtx.bg:SetColorTexture(0, 0, 0, 0)
        end

        cb.spellName:ClearAllPoints()
        cb.spellName:SetPoint("LEFT", cb.textCtx, "LEFT", 5, 0)
        cb.spellName:SetPoint("RIGHT", cb.timer, "LEFT", -5, 0)

        cb.timer:ClearAllPoints()
        cb.timer:SetPoint("RIGHT", cb.textCtx, "RIGHT", -5, 0)
    else
        cb.textCtx:ClearAllPoints()
        cb.textCtx:SetAllPoints(cb)
        cb.textCtx.bg:SetColorTexture(0, 0, 0, 0)

        cb.spellName:ClearAllPoints()
        cb.timer:ClearAllPoints()

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

function AscensionCastBar:applyFont()
    local db = self.db.profile
    local cb = self.castBar
    local outline = db.outline or "OUTLINE"

    local r, g, b, a = unpack(db.fontColor or {1,1,1,1})
    local sP = LSM:Fetch("font", db.spellNameFontLSM) or self.barDefaultFontPath
    cb.spellName:SetFont(sP, db.spellNameFontSize, outline)
    cb.spellName:SetTextColor(r, g, b, a)

    if not db.useSharedColor and db.timerColor then
        r, g, b, a = unpack(db.timerColor or {1,1,1,1})
    end

    local tP = LSM:Fetch("font", db.timerFontLSM) or self.barDefaultFontPath
    cb.timer:SetFont(tP, db.timerFontSize, outline)
    cb.timer:SetTextColor(r, g, b, a)
end

function AscensionCastBar:updateTextVisibility()
    local cb = self.castBar
    if not cb then return end

    local db = self.db.profile
    if db.showSpellText then
        local displayName = cb.lastSpellName or ""
        if db.truncateSpellName and string.len(displayName) > (db.truncateLength or 20) then
            displayName = string.sub(displayName, 1, db.truncateLength or 20) .. "..."
        end
        cb.spellName:SetText(displayName)
    else
        cb.spellName:SetText("")
    end
end
