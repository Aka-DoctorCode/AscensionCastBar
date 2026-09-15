-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Latency.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

local addonName, addonTable = ...
local ADDON_NAME = "Ascension Cast Bar"
---@class AscensionCastBar
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
if not AscensionCastBar then return end

function AscensionCastBar:updateLatency()
    if self.castBar then
        self:updateLatencyBar(self.castBar)
    end
end

function AscensionCastBar:updateLatencyBar(castBar)
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

    if self.castBar.lastSpellName == "Test Spell" then
        ms = 100
    end

    if ms <= 0 then
        castBar.latency:Hide()
        return
    end

    local frac = (ms / 1000) / (castBar.duration or 1)
    if frac > db.latencyMaxPercent then frac = db.latencyMaxPercent end

    local isVertical = (db.orientation == "VERTICAL")
    local isInverted = db.invertFill or (isVertical and db.invertVerticalFill) or false
    local b = db.borderEnabled and db.borderThickness or 0

    castBar.latency:ClearAllPoints()

    local isFilling = false
    if castBar.isEmpowered or castBar.casting then
        isFilling = true
    elseif castBar.channeling and db.reverseChanneling then
        isFilling = true
    end

    if isVertical then
        local h = castBar:GetHeight() * frac
        local minH = 2
        if h < minH then h = minH end
        if h <= 0.5 then
            castBar.latency:Hide()
            return
        end

        local placeAtTop = isFilling
        if isInverted then
            placeAtTop = not placeAtTop
        end

        if placeAtTop then
            castBar.latency:SetPoint("TOPLEFT", castBar, "TOPLEFT", b, -b)
            castBar.latency:SetPoint("TOPRIGHT", castBar, "TOPRIGHT", -b, -b)
        else
            castBar.latency:SetPoint("BOTTOMLEFT", castBar, "BOTTOMLEFT", b, b)
            castBar.latency:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", -b, b)
        end
        castBar.latency:SetHeight(h)
    else
        local w = castBar:GetWidth() * frac
        local minW = 2
        if w < minW then w = minW end
        if w <= 0.5 then
            castBar.latency:Hide()
            return
        end

        local placeAtRight = isFilling
        if isInverted then
            placeAtRight = not placeAtRight
        end

        if placeAtRight then
            castBar.latency:SetPoint("TOPRIGHT", castBar, "TOPRIGHT", -b, -b)
            castBar.latency:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", -b, b)
        else
            castBar.latency:SetPoint("TOPLEFT", castBar, "TOPLEFT", b, -b)
            castBar.latency:SetPoint("BOTTOMLEFT", castBar, "BOTTOMLEFT", b, b)
        end
        castBar.latency:SetWidth(w)
    end

    local c = db.latencyColor
    castBar.latency:SetColorTexture(c[1], c[2], c[3], c[4])
    castBar.latency:Show()
end
