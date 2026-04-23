-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Creation.lua
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

function AscensionCastBar:createBar()
    -- Create an invisible anchor frame
    if not self.anchorFrame then
        self.anchorFrame = CreateFrame("Frame", nil, UIParent)
    end
    self.anchorFrame:SetSize(1, 1) -- Minimal size, just for positioning

    local castBar = CreateFrame("StatusBar", "AscensionCastBarFrame", self.anchorFrame)
    castBar:SetClipsChildren(false)

    local width = self.db.profile.manualWidth or 270
    local height = self.db.profile.manualHeight or 24
    castBar:SetSize(width, height)

    castBar:ClearAllPoints()
    castBar:SetPoint("CENTER", self.anchorFrame, "CENTER", 0, 0)

    local strata = self.db.profile.frameStrata or "MEDIUM"
    castBar:SetFrameStrata(strata); castBar:SetFrameLevel(10); castBar:Hide()
    self.castBar = castBar

    -- Bar Texture
    castBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")

    -- Background
    castBar.bg = castBar:CreateTexture(nil, "BACKGROUND")
    castBar.bg:SetAllPoints()

    -- Glow Frame
    castBar.glowFrame = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
    castBar.glowFrame:SetFrameLevel(9)
    castBar.glowFrame:SetPoint("TOPLEFT", -6, 6)
    castBar.glowFrame:SetPoint("BOTTOMRIGHT", 6, -6)
    castBar.glowFrame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Glow",
        edgeSize = 16,
    })
    castBar.glowFrame:Hide()

    -- Ticks
    castBar.ticksFrame = CreateFrame("Frame", nil, castBar)
    castBar.ticksFrame:SetAllPoints()
    castBar.ticksFrame:SetFrameLevel(15)
    castBar.ticks = {}

    -- Icon & Shield & Latency
    castBar.icon = castBar:CreateTexture(nil, "OVERLAY")
    castBar.shield = castBar:CreateTexture(nil, "OVERLAY", nil, 5)
    castBar.shield:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
    castBar.shield:SetSize(16, 16); castBar.shield:Hide()
    castBar.latency = castBar:CreateTexture(nil, "OVERLAY", nil, 2)
    castBar.latency:Hide()

    -- Spark Components
    castBar.tailMask = CreateFrame("Frame", nil, castBar)
    castBar.tailMask:SetPoint("TOPLEFT", 0, 0); castBar.tailMask:SetPoint("BOTTOMLEFT", 0, 0)
    castBar.tailMask:SetClipsChildren(true)

    castBar.sparkHead = castBar:CreateTexture(nil, "OVERLAY", nil, 7)
    if castBar.sparkHead.SetRotation then castBar.sparkHead:SetRotation(math.rad(90)) end

    -- Tails
    castBar.sparkTail = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail:SetAtlas(
        "AftLevelup-SoftCloud", true); castBar.sparkTail:SetBlendMode("ADD")
    castBar.sparkTail2 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail2:SetAtlas(
        "AftLevelup-SoftCloud", true); castBar.sparkTail2:SetTexCoord(0, 1, 1, 0); castBar.sparkTail2:SetBlendMode("ADD")
    castBar.sparkTail3 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail3:SetAtlas(
        "AftLevelup-SoftCloud", true); castBar.sparkTail3:SetBlendMode("ADD")
    castBar.sparkTail4 = castBar.tailMask:CreateTexture(nil, "OVERLAY", nil, 4); castBar.sparkTail4:SetAtlas(
        "AftLevelup-SoftCloud", true); castBar.sparkTail4:SetTexCoord(0, 1, 1, 0); castBar.sparkTail4:SetBlendMode("ADD")

    castBar.sparkGlow = castBar:CreateTexture(nil, "OVERLAY", nil, 6)

    -- Text Context
    castBar.textCtx = CreateFrame("Frame", "AscensionCastBarTextFrame", UIParent)
    castBar.textCtx:SetFrameStrata("MEDIUM")
    castBar.textCtx:SetFrameLevel(25)
    castBar.textCtx.bg = castBar.textCtx:CreateTexture(nil, "BACKGROUND")
    castBar.textCtx.bg:SetAllPoints()

    castBar.spellName = castBar.textCtx:CreateFontString(nil, "OVERLAY");
    castBar.spellName:SetDrawLayer("OVERLAY", 7);
    castBar.spellName:SetJustifyH("LEFT")

    castBar.timer = castBar.textCtx:CreateFontString(nil, "OVERLAY");
    castBar.timer:SetDrawLayer("OVERLAY", 7);
    castBar.timer:SetJustifyH("RIGHT")

    -- Borders
    castBar.border = {
        top = castBar:CreateTexture(nil, "OVERLAY"),
        bottom = castBar:CreateTexture(nil, "OVERLAY"),
        left =
            castBar:CreateTexture(nil, "OVERLAY"),
        right = castBar:CreateTexture(nil, "OVERLAY")
    }
    castBar.border.top:SetPoint("TOPLEFT", 0, 0); castBar.border.top:SetPoint("TOPRIGHT", 0, 0);
    castBar.border.bottom:SetPoint("BOTTOMLEFT", 0, 0); castBar.border.bottom:SetPoint("BOTTOMRIGHT", 0, 0)
    castBar.border.left:SetPoint("TOPLEFT", 0, 0); castBar.border.left:SetPoint("BOTTOMLEFT", 0, 0);
    castBar.border.right:SetPoint("TOPRIGHT", 0, 0); castBar.border.right:SetPoint("BOTTOMRIGHT", 0, 0)

    -- OnUpdate Loop
    castBar:SetScript("OnUpdate", function(f, elapsed) self:onFrameUpdate(f, elapsed) end)

    -- Empower visuals (FCC-style)
    castBar.empowerStageFrame = CreateFrame("Frame", nil, castBar)
    castBar.empowerStageFrame:SetAllPoints(castBar)
    castBar.empowerStageFrame:SetFrameLevel(castBar:GetFrameLevel() + 5)
    castBar.stagePips = {}
    castBar.stageTiers = {}

    -- Initialize text layout
    self:updateTextLayout()
end

function AscensionCastBar:initializeTailMask()
    local cb = self.castBar
    if not cb.tailMask then
        cb.tailMask = CreateFrame("Frame", nil, cb)
        cb.tailMask:SetPoint("LEFT", cb, "LEFT")
        cb.tailMask:SetPoint("TOP", cb, "TOP")
        cb.tailMask:SetPoint("BOTTOM", cb, "BOTTOM")
        cb.tailMask:SetWidth(cb:GetWidth())
    end
end
