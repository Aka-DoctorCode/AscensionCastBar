-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: AnimationCore.lua
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

local math_max = math.max
local math_min = math.min

function AscensionCastBar:updateSparkColors()
    local cb = self.castBar
    if not cb or not self.db then return end

    local db = self.db.profile
    if not db then return end

    local t1, t2, t3, t4 = db.tail1Color or {1,1,1,1}, db.tail2Color or {1,1,1,1}, db.tail3Color or {1,1,1,1}, db.tail4Color or {1,1,1,1}
    local s, g = db.sparkColor or {1,1,1,1}, db.glowColor or {1,1,1,1}

    if cb.sparkHead then
        cb.sparkHead:SetVertexColor(s[1], s[2], s[3], s[4])
    end
    if cb.sparkGlow then
        cb.sparkGlow:SetVertexColor(g[1], g[2], g[3], g[4])
    end

    if cb.sparkTail then
        cb.sparkTail:SetVertexColor(t1[1], t1[2], t1[3], t1[4])
    end
    if cb.sparkTail2 then
        cb.sparkTail2:SetVertexColor(t2[1], t2[2], t2[3], t2[4])
    end
    if cb.sparkTail3 then
        cb.sparkTail3:SetVertexColor(t3[1], t3[2], t3[3], t3[4])
    end
    if cb.sparkTail4 then
        cb.sparkTail4:SetVertexColor(t4[1], t4[2], t4[3], t4[4])
    end
end

function AscensionCastBar:updateSparkSize()
    local cb = self.castBar
    if not cb or not self.db then return end

    local db = self.db.profile
    if not db then return end
    local sc, h = db.sparkScale or 1, db.height or 24

    if cb.sparkHead then
        cb.sparkHead:SetSize(32 * sc, h * 2 * sc)
    end
    if cb.sparkGlow then
        cb.sparkGlow:SetSize(190 * sc, h * 2.4)
    end
    if cb.sparkTail then
        cb.sparkTail:SetSize(db.tail1Length * sc, h * 1.4)
    end
    if cb.sparkTail2 then
        cb.sparkTail2:SetSize(db.tail2Length * sc, h * 1.1)
    end
    if cb.sparkTail3 then
        cb.sparkTail3:SetSize(db.tail3Length * sc, h * 1.4)
    end
    if cb.sparkTail4 then
        cb.sparkTail4:SetSize(db.tail4Length * sc, h * 1.1)
    end

    if cb.tailMask then
        cb.tailMask:SetWidth(cb:GetWidth())
    end
end

function AscensionCastBar:resetParticles()
    local cb = self.castBar
    if not cb then return end

    if cb.particles then
        for _, p in ipairs(cb.particles) do
            if p then p:Hide() end
        end
    end
    cb.lastParticleTime = 0

    if cb.lightningSegments then
        for _, l in ipairs(cb.lightningSegments) do
            if l then l:Hide() end
        end
    end
    if cb.glitchLayers then
        for _, g in ipairs(cb.glitchLayers) do
            if g then g:Hide() end
        end
    end
    if cb.waveOverlay then
        cb.waveOverlay:Hide()
    end
end

function AscensionCastBar:hideAllSparkElements()
    local cb = self.castBar
    if not cb then return end

    if cb.sparkHead then cb.sparkHead:Hide() end
    if cb.sparkGlow then cb.sparkGlow:Hide() end
    if cb.sparkTail then cb.sparkTail:Hide() end
    if cb.sparkTail2 then cb.sparkTail2:Hide() end
    if cb.sparkTail3 then cb.sparkTail3:Hide() end
    if cb.sparkTail4 then cb.sparkTail4:Hide() end

    if cb.waveOverlay then cb.waveOverlay:Hide() end
    if cb.waveTexture then cb.waveTexture:Hide() end
    if cb.waveSegments then
        for _, seg in ipairs(cb.waveSegments) do
            if seg then seg:Hide() end
        end
    end
    if cb.waveLines then
        for _, wave in ipairs(cb.waveLines) do
            if wave then wave:Hide() end
        end
    end
    if cb.glitchLayers then
        for _, g in ipairs(cb.glitchLayers) do
            if g then g:Hide() end
        end
    end
    if cb.lightningSegments then
        for _, l in ipairs(cb.lightningSegments) do
            if l then l:Hide() end
        end
    end
    if cb.particles then
        for _, p in ipairs(cb.particles) do
            if p then p:Hide() end
        end
    end
end

function AscensionCastBar:cleanupOverlays()
    local cb = self.castBar
    if not cb or not self.db then return end
    local db = self.db.profile
    if not db then return end
    local style = db.animStyle
    if not style or not (self.AnimationStyles and self.AnimationStyles.validStyles[style]) then
        style = "Comet"
    end

    if style ~= "Wave" then
        if cb.waveOverlay then cb.waveOverlay:Hide() end
        if cb.waveTexture then cb.waveTexture:Hide() end
        if cb.waveSegments then
            for _, seg in ipairs(cb.waveSegments) do
                if seg then seg:Hide() end
            end
        end
        if cb.waveLines then
            for _, wave in ipairs(cb.waveLines) do
                if wave then wave:Hide() end
            end
        end
    end

    if style ~= "Glitch" and cb.glitchLayers then
        for _, g in ipairs(cb.glitchLayers) do
            if g then g:Hide() end
        end
    end

    if style ~= "Lightning" and cb.lightningSegments then
        for _, l in ipairs(cb.lightningSegments) do
            if l then l:Hide() end
        end
    end
end

function AscensionCastBar:updateSpark(passedProgress, tailProgress)
    if not self.db then return end
    local db = self.db.profile
    local castBar = self.castBar
    if not db or not castBar then return end

    local minVal, maxVal = castBar:GetMinMaxValues()
    local currentVal = castBar:GetValue()
    local visualProgress = 0

    if maxVal and minVal and maxVal > minVal then
        visualProgress = (currentVal - minVal) / (maxVal - minVal)
    end

    visualProgress = math_max(0, math_min(1, visualProgress))

    if not db.enableSpark or visualProgress <= 0.001 or visualProgress >= 0.999 then
        self:hideAllSparkElements()
        return
    end

    self:initializeTailMask()

    local style = db.animStyle
    if not style or not (self.AnimationStyles and self.AnimationStyles.validStyles[style]) then
        style = "Comet"
    end

    self:cleanupOverlays()
    local tP = self:clampAlpha(tailProgress or visualProgress)

    local w = castBar:GetWidth()
    if w <= 0 then return end

    local offset = w * visualProgress
    local time = GetTime()

    local baseWidth = db.manualWidth or 270
    local effOffset = (db.headLengthOffset or 0) * (w / math_max(baseWidth, 1))
    local customOffsetX = (db.sparkOffset or 0) + effOffset

    if castBar.sparkHead then
        castBar.sparkHead:ClearAllPoints()
        castBar.sparkHead:SetPoint("CENTER", castBar, "LEFT", offset + customOffsetX, 0)
        castBar.sparkHead:SetAlpha(self:clampAlpha(db.sparkIntensity))
        castBar.sparkHead:Show()
    end

    if castBar.sparkGlow then
        castBar.sparkGlow:ClearAllPoints()
        castBar.sparkGlow:SetPoint("CENTER", castBar.sparkHead, "CENTER", 0, 0)
    end

    if castBar.tailMask then
        castBar.tailMask:SetWidth(math_max(0.001, offset))
    end

    if not db.enableTails or (self.AnimationStyles and self.AnimationStyles.withoutTails[style]) then
        if castBar.sparkTail then castBar.sparkTail:Hide() end
        if castBar.sparkTail2 then castBar.sparkTail2:Hide() end
        if castBar.sparkTail3 then castBar.sparkTail3:Hide() end
        if castBar.sparkTail4 then castBar.sparkTail4:Hide() end
    end

    local animFunc = self.AnimationStyles and self.AnimationStyles[style]
    if animFunc and type(animFunc) == "function" then
        local success, err = pcall(animFunc, self, castBar, db, visualProgress, tP, time, offset, w)
        if not success then
            if self.AnimationStyles and self.AnimationStyles.Comet then
                self.AnimationStyles.Comet(self, castBar, db, visualProgress, tP, time, offset, w)
            end
        end
    else
        if self.AnimationStyles and self.AnimationStyles.Comet then
            self.AnimationStyles.Comet(self, castBar, db, visualProgress, tP, time, offset, w)
        end
    end
end
