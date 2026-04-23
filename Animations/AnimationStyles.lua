-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: AnimationStyles.lua
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

local math_sin         = math.sin
local math_cos         = math.cos
local math_abs         = math.abs
local math_max         = math.max
local math_min         = math.min
local math_pi          = math.pi
local math_random      = math.random
local empty_table      = {}

AscensionCastBar.AnimationStyles = {}

AscensionCastBar.AnimationStyles.withoutTails = {
    Wave = true,
    Glitch = true,
    Lightning = true,
}

AscensionCastBar.AnimationStyles.validStyles = {
    Orb = true,
    Pulse = true,
    Starfall = true,
    Flux = true,
    Helix = true,
    Wave = true,
    Glitch = true,
    Lightning = true,
    Comet = true,
}

function AscensionCastBar.AnimationStyles.Orb(self, castBar, db, progress, tailProgress, time, offset, w)
    castBar.sparkGlow:Show()
    local params = db.animationParams.Orb or empty_table
    local rotSpeed = time * self:safeValue(params.rotationSpeed, 8)
    local radius = db.height * self:safeValue(params.radiusMultiplier, 0.4)

    local function SpinOrb(tex, angleOffset, intense)
        if not tex then return end
        tex:ClearAllPoints()
        local x = math_cos(rotSpeed + angleOffset) * radius
        local y = math_sin(rotSpeed + angleOffset) * radius
        tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", x, y)
        tex:SetAlpha(self:clampAlpha(intense) * 1.0)
        tex:Show()
    end

    if db.enableTails then
        SpinOrb(castBar.sparkTail, 0, db.tail1Intensity)
        SpinOrb(castBar.sparkTail2, math_pi / 2, db.tail2Intensity)
        SpinOrb(castBar.sparkTail3, math_pi, db.tail3Intensity)
        SpinOrb(castBar.sparkTail4, -math_pi / 2, db.tail4Intensity)
    end

    local pulse = 0.5 + 0.5 * math_sin(time * self:safeValue(params.glowPulse, 1) * 8)
    local glowAlpha = self:clampAlpha(db.glowIntensity) * (0.6 + 0.4 * pulse)
    castBar.sparkGlow:SetAlpha(glowAlpha)
end

function AscensionCastBar.AnimationStyles.Pulse(self, castBar, db, progress, tailProgress, time, offset, w)
    castBar.sparkGlow:Show()
    local params = db.animationParams.Pulse or empty_table
    local maxScale = self:safeValue(params.maxScale, 2.5)
    local rippleCycle = self:safeValue(params.rippleCycle, 1.0)
    local fadeSpeed = self:safeValue(params.fadeSpeed, 1.0)

    rippleCycle = math_max(0.1, rippleCycle)
    fadeSpeed = math_max(0.1, fadeSpeed)

    local function Ripple(tex, offsetTime, intense)
        if not tex then return end

        tex:ClearAllPoints()
        tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", 0, 0)

        local totalTime = time + self:safeValue(offsetTime, 0)
        local rawCycle = (totalTime % math_max(rippleCycle, 0.1)) / math_max(rippleCycle, 0.1)
        local cycle = math_max(0, math_min(1, rawCycle))
        local baseSize = db.height * 2
        local scaleFactor = 0.2 + cycle * maxScale
        local size = baseSize * math_max(0.1, scaleFactor)
        tex:SetSize(size, size)

        local fade = 1 - (cycle * cycle * fadeSpeed)
        fade = math_max(0, math_min(1, fade))

        local alpha = self:clampAlpha(intense) * fade
        tex:SetAlpha(alpha)
        tex:Show()
    end

    if db.enableTails then
        Ripple(castBar.sparkTail, 0.0, self:safeValue(db.tail1Intensity, 1))
        Ripple(castBar.sparkTail2, 0.3, self:safeValue(db.tail2Intensity, 1))
        Ripple(castBar.sparkTail3, 0.6, self:safeValue(db.tail3Intensity, 1))
        Ripple(castBar.sparkTail4, 0.9, self:safeValue(db.tail4Intensity, 1))
    end
end

function AscensionCastBar.AnimationStyles.Starfall(self, castBar, db, progress, tailProgress, time, offset, w)
    castBar.sparkGlow:Hide()
    local params = db.animationParams.Starfall or empty_table
    local h = db.height

    local function Fall(tex, driftBase, speed, intense)
        if not tex then return end

        tex:ClearAllPoints()
        local fallSpeed = self:safeValue(params.fallSpeed, 2.5)
        local swayAmount = self:safeValue(params.swayAmount, 8)
        local particleSpeed = self:safeValue(params.particleSpeed, 3.8)

        local fallY = -((time * speed * fallSpeed) % (h * 2.5)) + h
        local sway = math_sin(time * particleSpeed + driftBase) * swayAmount

        tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", driftBase + sway, fallY)

        local alphaIntensity = self:clampAlpha(intense)
        local distanceFactor = 1 - math_abs(fallY) / (h * 1.5)
        distanceFactor = math_max(0, distanceFactor)

        tex:SetAlpha(alphaIntensity * distanceFactor)
        tex:Show()
    end

    if db.enableTails then
        Fall(castBar.sparkTail, -10, 2.5, db.tail1Intensity)
        Fall(castBar.sparkTail2, 10, 3.8, db.tail2Intensity)
        Fall(castBar.sparkTail3, -20, 1.5, db.tail3Intensity)
        Fall(castBar.sparkTail4, 20, 3.0, db.tail4Intensity)
    end
end

function AscensionCastBar.AnimationStyles.Flux(self, castBar, db, progress, tailProgress, time, offset, w)
    castBar.sparkGlow:Hide()
    local params = db.animationParams.Flux or empty_table

    local dm = w * self:safeValue(params.driftMultiplier, 0.05)
    local jitterY = self:safeValue(params.jitterY, 3.5)
    local jitterX = self:safeValue(params.jitterX, 2.5)

    local function Flux(tex, baseOff, drift, intense)
        if not tex then return end

        tex:ClearAllPoints()
        local rY = (math_random() * jitterY * 2) - jitterY
        local rX = (math_random() * jitterX * 2) - jitterX

        local xPos = -baseOff + drift + rX + (db.tailOffset or 0)

        tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", xPos, rY)
        tex:SetAlpha(self:clampAlpha(intense) * tailProgress)
        tex:Show()
    end

    if db.enableTails then
        Flux(castBar.sparkTail, 20, -dm * tailProgress, db.tail1Intensity)
        Flux(castBar.sparkTail2, 35, dm * tailProgress, db.tail2Intensity)
        Flux(castBar.sparkTail3, 20, -dm * tailProgress, db.tail3Intensity)
        Flux(castBar.sparkTail4, 35, dm * tailProgress, db.tail4Intensity)
    end
end

function AscensionCastBar.AnimationStyles.Helix(self, castBar, db, progress, tailProgress, time, offset, w)
    castBar.sparkGlow:Show()
    local params = db.animationParams.Helix or empty_table

    local dm = w * self:safeValue(params.driftMultiplier, 0.1)
    local amp = db.height * self:safeValue(params.amplitude, 0.4)
    local waveSpeed = self:safeValue(params.waveSpeed, 8)

    local sv = math_sin(time * waveSpeed + (offset * 0.05)) * amp
    local cv = math_cos(time * waveSpeed + (offset * 0.05)) * amp

    local function Helix(tex, baseOff, drift, yOff, intense)
        if not tex then return end

        tex:ClearAllPoints()
        local xPos = -baseOff + drift + (db.tailOffset or 0)

        tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", xPos, yOff)
        tex:SetAlpha(self:clampAlpha(intense) * tailProgress)
        tex:Show()
    end

    if db.enableTails then
        Helix(castBar.sparkTail, 20, -dm * tailProgress, sv, db.tail1Intensity)
        Helix(castBar.sparkTail2, 35, dm * tailProgress, -sv, db.tail2Intensity)
        Helix(castBar.sparkTail3, 25, -dm * tailProgress, cv, db.tail3Intensity)
        Helix(castBar.sparkTail4, 30, dm * tailProgress, -cv, db.tail4Intensity)
    end
end

function AscensionCastBar.AnimationStyles.Wave(self, castBar, db, progress, tailProgress, time, offset, w)
    castBar.sparkGlow:Hide()
    castBar.sparkHead:Hide()

    local params = db.animationParams.Wave or empty_table
    local waveCount = math_max(1, math_min(10, self:safeValue(params.waveCount, 3)))
    local waveSpeed = self:safeValue(params.waveSpeed, 0.4)
    local amplitude = self:safeValue(params.amplitude, 0.05)
    local waveWidth = self:safeValue(params.waveWidth, 0.25)

    if not castBar.tailMask then
        castBar.tailMask = CreateFrame("Frame", nil, castBar)
        castBar.tailMask:SetPoint("LEFT", castBar, "LEFT")
        castBar.tailMask:SetPoint("TOP", castBar, "TOP")
        castBar.tailMask:SetPoint("BOTTOM", castBar, "BOTTOM")
        castBar.tailMask:SetWidth(w)
    end

    if not castBar.waveLines then
        castBar.waveLines = {}
    end
    while #castBar.waveLines < waveCount do
        local wave = castBar.tailMask:CreateTexture(nil, "ARTWORK")
        wave:SetBlendMode("ADD")
        wave:SetHeight(db.height * 0.25)
        wave:SetColorTexture(1, 1, 1, 1)
        table.insert(castBar.waveLines, wave)
    end

    for i = waveCount + 1, #castBar.waveLines do
        castBar.waveLines[i]:Hide()
    end

    local wc = db.tail2Color
    local baseAlpha = 0.4 * (0.5 + progress * 0.5)
    baseAlpha = math_max(0, math_min(1, baseAlpha))

    for i = 1, waveCount do
        local wave = castBar.waveLines[i]
        if wave then
            local waveTime = time + (i * 0.5)
            local waveProgress = (waveTime * waveSpeed) % 1
            local waveX = waveProgress * castBar.tailMask:GetWidth()

            local waveY = math_sin(waveTime * 3 + i) * (db.height * amplitude)
            local waveW = castBar.tailMask:GetWidth() * waveWidth

            wave:SetWidth(waveW)
            wave:ClearAllPoints()
            wave:SetPoint("CENTER", castBar.tailMask, "LEFT", waveX, waveY)

            local edgeFade = 1.0
            local distanceFromCenter = math_abs(waveProgress - 0.5) * 2
            edgeFade = 1.0 - distanceFromCenter * 0.5

            local waveAlpha = baseAlpha * (0.6 + 0.4 * math_sin(waveTime * 2)) * edgeFade
            waveAlpha = math_max(0, math_min(1, waveAlpha))

            wave:SetVertexColor(wc[1], wc[2], wc[3], waveAlpha)
            wave:Show()
        end
    end
end

function AscensionCastBar.AnimationStyles.Glitch(self, castBar, db, progress, tailProgress, time, offset, w)
    castBar.sparkHead:Hide()
    local params = db.animationParams.Glitch or {}

    local glitchChance = self:safeValue(params.glitchChance, 0.1)
    local maxOffset = self:safeValue(params.maxOffset, 5)
    local colorIntensity = self:safeValue(params.colorIntensity, 0.3)

    if not castBar.glitchLayers then
        castBar.glitchLayers = {}
        for i = 1, 3 do
            local g = castBar:CreateTexture(nil, "OVERLAY")
            g:SetColorTexture(1, 1, 1, 1)
            g:SetBlendMode("ADD")
            table.insert(castBar.glitchLayers, g)
        end
    end

    for i, g in ipairs(castBar.glitchLayers) do
        if math_random() < glitchChance then
            local r = math_random() > 0.5 and 1 or 0
            local gr = math_random() > 0.5 and 1 or 0
            local bl = math_random() > 0.5 and 1 or 0
            g:SetVertexColor(r, gr, bl, colorIntensity)
            g:ClearAllPoints()
            local ox = math_random(-maxOffset, maxOffset)
            local oy = math_random(-2, 2)
            g:SetPoint("TOPLEFT", castBar, "TOPLEFT", ox, oy)
            g:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", ox, oy)
            g:Show()
        else
            g:Hide()
        end
    end
end

function AscensionCastBar.AnimationStyles.Lightning(self, castBar, db, progress, tailProgress, time, offset, w)
    castBar.sparkGlow:Show()
    local params = db.animationParams.Lightning or {}

    local lightningChance = self:safeValue(params.lightningChance, 0.3)
    local segmentCount = math_max(1, math_min(10, self:safeValue(params.segmentCount, 3)))

    if not castBar.lightningSegments then castBar.lightningSegments = {} end

    while #castBar.lightningSegments < segmentCount do
        local l = castBar:CreateTexture(nil, "OVERLAY")
        l:SetColorTexture(1, 1, 1, 1)
        l:SetBlendMode("ADD")
        table.insert(castBar.lightningSegments, l)
    end

    for i = segmentCount + 1, #castBar.lightningSegments do
        castBar.lightningSegments[i]:Hide()
    end

    for i = 1, segmentCount do
        local l = castBar.lightningSegments[i]
        if math_random() < lightningChance then
            local tx = math_random(0, w)
            local ty = math_random(0, db.height)
            local dx = tx - offset
            local dy = ty - (db.height / 2)
            local len = math.sqrt(dx * dx + dy * dy)
            local ang = math.atan2(dy, dx)
            l:SetSize(len, 2)
            l:ClearAllPoints()
            l:SetPoint("CENTER", castBar.sparkHead, "CENTER", 0, 0)
            l:SetRotation(ang)
            local lc = db.tail3Color
            l:SetVertexColor(lc[1], lc[2], lc[3], 0.6)
            l:Show()
        else
            l:Hide()
        end
    end
end

function AscensionCastBar.AnimationStyles.Comet(self, castBar, db, progress, tailProgress, time, offset, w)
    castBar.sparkGlow:Show()
    castBar.sparkGlow:SetAlpha(self:clampAlpha(db.glowIntensity))
    local params = db.animationParams.Comet or {}

    local function Comet(tex, rel_pos, int)
        if not tex then return end

        tex:ClearAllPoints()
        local trailX = -(rel_pos * w) + (db.tailOffset or 0)

        tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", trailX, 0)
        tex:SetAlpha(self:clampAlpha(int) * tailProgress)
        tex:Show()
    end

    if db.enableTails then
        Comet(castBar.sparkTail, 0.05, db.tail1Intensity)
        Comet(castBar.sparkTail2, 0.10, db.tail2Intensity)
        Comet(castBar.sparkTail3, 0.15, db.tail3Intensity)
        Comet(castBar.sparkTail4, 0.20, db.tail4Intensity)
    end
end
