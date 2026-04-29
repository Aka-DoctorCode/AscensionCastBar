-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Ticks.lua
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

function AscensionCastBar:hideTicks()
    if not self.castBar or not self.castBar.ticks then return end
    for _, tick in pairs(self.castBar.ticks) do
        if tick then tick:Hide() end
    end
end

function AscensionCastBar:updateTicks(spellID, numStages, duration)
    if not self.castBar then return end
    self:hideTicks()

    spellID = spellID or self.castBar.lastSpellID
    numStages = numStages or self.castBar.numStages
    duration = duration or self.castBar.duration

    local db = self.db.profile
    if not db.showChannelTicks and not db.showEmpowerStages then return end

    if self.castBar.ticksFrame then
        self.castBar.ticksFrame:SetFrameLevel(self.castBar:GetFrameLevel() + 10)
        self.castBar.ticksFrame:Show()
    end

    local count = 0
    local isEmpowered = (numStages and numStages > 0)

    if isEmpowered then
        count = numStages
    elseif spellID and spellID > 0 then
        if spellID == 234153 then
            count = 5
        elseif self.channelTicks and self.channelTicks[spellID] then
            count = self.channelTicks[spellID]
        end
        
        if type(count) == "function" then
            count = count(duration)
        end
    end

    if not count or type(count) ~= "number" or count < 1 then return end

    local c = db.channelTicksColor
    local thickness = db.channelTicksThickness or 1
    local width = self.castBar:GetWidth()

    if width <= 10 then width = db.manualWidth or 270 end

    if isEmpowered then
        local numPips = (self.castBar.numStages and self.castBar.numStages - 1) or (count - 1)
        local maxMS = (self.castBar.duration and self.castBar.duration * 1000) or 1
        for i = 1, numPips do
            local cumulative = 0
            if self.castBar.stagePoints and self.castBar.stagePoints[i] then
                cumulative = self.castBar.stagePoints[i] / maxMS
            else
                cumulative = i / (numPips + 1)
            end
            local tick = self.castBar.ticks[i]
            if not tick then
                tick = self.castBar.ticksFrame:CreateTexture(nil, "OVERLAY")
                self.castBar.ticks[i] = tick
            end
            tick:ClearAllPoints()
            tick:SetPoint("CENTER", self.castBar, "LEFT", width * cumulative, 0)
            tick:SetSize(thickness, self.castBar:GetHeight())
            tick:SetColorTexture(c[1], c[2], c[3], c[4])
            tick:Show()
        end
    else
        local w = width / count
        for i = 1, count - 1 do
            local tick = self.castBar.ticks[i]
            if not tick then
                tick = self.castBar.ticksFrame:CreateTexture(nil, "OVERLAY")
                self.castBar.ticks[i] = tick
            end
            tick:ClearAllPoints()
            tick:SetSize(thickness, self.castBar:GetHeight())

            local pos = w * i
            if db.reverseChanneling then
                pos = width - pos
            end

            tick:SetPoint("CENTER", self.castBar, "LEFT", pos, 0)
            tick:SetColorTexture(c[1], c[2], c[3], c[4])
            tick:Show()
        end
    end
end
