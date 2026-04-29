-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Helpers.lua
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
-- HELPERS (Common Utilities)
-------------------------------------------------------------------------------

---@param v any
---@return number
function AscensionCastBar:clampAlpha(v)
    v = tonumber(v) or 0
    if v ~= v then return 0 end
    if math.abs(v) == math.huge then return 1 end
    if v < 0 then v = 0 elseif v > 1 then v = 1 end
    return v
end

---@param val any
---@param default number
---@return number
function AscensionCastBar:safeValue(val, default)
    if type(val) ~= "number" or val ~= val or math.abs(val) == math.huge then
        return default or 1.0
    end
    return val
end

---@param rem number
---@param dur number
---@return string
function AscensionCastBar:getFormattedTimer(rem, dur)
    if not self.db then return "" end
    local db = self.db.profile
    if not db or not db.showTimerText then return "" end
    local f = db.timerFormat
    if f == "Duration" then
        return string.format("%.1f / %.1f", math.max(0, math.floor(rem * 10) / 10), math.floor(dur * 10) / 10)
    elseif f == "Total" then
        return string.format("%.1f", math.floor(dur * 10) / 10)
    else
        return string.format("%.1f", math.max(0, math.floor(rem * 10) / 10))
    end
end

---@param info table
function AscensionCastBar:setupCastBarShared(info)
    local cb = self.castBar
    if not cb or not self.db then return end
    local db = self.db.profile
    if not db then return end

    if cb.textCtx then cb.textCtx:Show() end

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

    self:applyFont()
    self:updateBorder()
    self:updateBackground()
    self:updateIcon()
    self:updateSparkColors()
end
