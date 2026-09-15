-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Visual.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

local addonName, addonTable = ...
local ADDON_NAME = "Ascension Cast Bar"
---@class AscensionCastBar
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
if not AscensionCastBar then return end
local LSM = LibStub("LibSharedMedia-3.0")

function AscensionCastBar:updateBackground()
    if not self.castBar or not self.db then return end
    local c = self.db.profile.bgColor or {0,0,0,0.5}
    self.castBar.bg:SetColorTexture(c[1], c[2], c[3], c[4])
end

function AscensionCastBar:updateBorder()
    if not self.castBar or not self.db then return end
    local db = self.db.profile
    if not db then return end
    local t, c = db.borderThickness or 1, db.borderColor or {0,0,0,1}
    for _, tx in pairs(self.castBar.border) do
        tx:SetShown(db.borderEnabled)
        tx:SetColorTexture(c[1], c[2], c[3], c[4])
    end
    self.castBar.border.top:SetHeight(t); self.castBar.border.bottom:SetHeight(t)
    self.castBar.border.left:SetWidth(t); self.castBar.border.right:SetWidth(t)
end

function AscensionCastBar:updateBarOrientation()
    local cb = self.castBar
    if not cb or not self.db then return end
    local db = self.db.profile
    local isVertical = (db.orientation == "VERTICAL")
    local isInverted = db.invertFill or (isVertical and db.invertVerticalFill) or false

    if isVertical then
        cb:SetOrientation("VERTICAL")
        if cb.SetRotatesTexture then cb:SetRotatesTexture(true) end
        cb:SetReverseFill(isInverted)
    else
        cb:SetOrientation("HORIZONTAL")
        if cb.SetRotatesTexture then cb:SetRotatesTexture(false) end
        cb:SetReverseFill(isInverted)
    end
end

function AscensionCastBar:updateBarColor()
    local db = self.db.profile
    local cb = self.castBar
    if not cb or not cb.glowFrame then return end

    self:updateBarOrientation()

    cb.glowFrame:Hide()

    local isVertical = (db.orientation == "VERTICAL")

    if cb.isEmpowered and cb.currentStage then
        local s = cb.currentStage
        cb:SetScale(1.0)

        if isVertical then
            local baseHeight = cb.baseHeight or db.manualHeight or 200
            local heightMultiplier = db.empowerWidthScale and (1 + ((s - 1) * 0.05)) or 1
            local newHeight = baseHeight * heightMultiplier
            cb:SetHeight(newHeight)
        else
            local baseWidth = cb.baseWidth or db.manualWidth or 270
            local widthMultiplier = db.empowerWidthScale and (1 + ((s - 1) * 0.05)) or 1
            local newWidth = baseWidth * widthMultiplier
            cb:SetWidth(newWidth)
        end
        self:updateEmpowerGeometry()

        local c = db.empowerStage1Color or { 0, 1, 0, 1 }
        if s >= 5 then
            c = db.empowerStage5Color or { 0.8, 0.3, 1, 1 }
        elseif s == 4 then
            c = db.empowerStage4Color or { 1, 0, 0, 1 }
        elseif s == 3 then
            c = db.empowerStage3Color or { 1, 0.5, 0, 1 }
        elseif s == 2 then
            c = db.empowerStage2Color or { 1, 1, 0, 1 }
        end

        cb:SetStatusBarColor(c[1], c[2], c[3], c[4])

        if s >= (cb.numStages or 4) then
            cb.glowFrame:SetBackdropBorderColor(c[1], c[2], c[3], 1)
            cb.glowFrame:Show()
        end
        return
    else
        cb:SetScale(1.0)
        if isVertical then
            cb:SetHeight(cb.baseHeight or db.manualHeight or 200)
            cb:SetWidth(cb.baseWidth or db.manualWidth or 24)
        else
            cb:SetWidth(cb.baseWidth or db.manualWidth or 270)
            cb:SetHeight(cb.baseHeight or db.manualHeight or db.height or 24)
        end
    end

    if cb.channeling and db.useChannelColor then
        local c = db.channelColor
        cb:SetStatusBarColor(c[1], c[2], c[3], c[4])
    elseif db.useClassColor then
        local _, playerClass = UnitClass("player")
        local classColor = C_ClassColor.GetClassColor(playerClass) or { r = 1, g = 1, b = 1 }
        cb:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
    else
        local c = db.barColor
        cb:SetStatusBarColor(c[1], c[2], c[3], c[4])
    end

    local tex = LSM:Fetch("statusbar", db.barLSMName) or "Interface\\TARGETINGFRAME\\UI-StatusBar"
    cb:SetStatusBarTexture(tex)
end

function AscensionCastBar:updateIcon()
    local db = self.db.profile
    local cb = self.castBar
    if not cb or not cb.icon then return end

    if db.showIcon then
        cb.icon:Show()
        local isVertical = (db.orientation == "VERTICAL")
        local defaultSize = isVertical and (cb:GetWidth() > 0 and cb:GetWidth() or 24) or (db.height or 24)

        if db.detachIcon then
            cb.icon:SetSize(db.iconSize, db.iconSize)
            cb.icon:ClearAllPoints()
            if db.iconAnchor == "Top" then
                cb.icon:SetPoint("BOTTOM", cb, "TOP", db.iconX, db.iconY)
            elseif db.iconAnchor == "Bottom" then
                cb.icon:SetPoint("TOP", cb, "BOTTOM", db.iconX, db.iconY)
            elseif db.iconAnchor == "Right" then
                cb.icon:SetPoint("LEFT", cb, "RIGHT", db.iconX, db.iconY)
            else
                cb.icon:SetPoint("RIGHT", cb, "LEFT", db.iconX, db.iconY)
            end
        else
            cb.icon:SetSize(defaultSize, defaultSize)
            cb.icon:ClearAllPoints()
            if db.iconAnchor == "Top" then
                cb.icon:SetPoint("TOP", cb, "TOP", 0, 0)
            elseif db.iconAnchor == "Bottom" then
                cb.icon:SetPoint("BOTTOM", cb, "BOTTOM", 0, 0)
            elseif db.iconAnchor == "Right" then
                cb.icon:SetPoint("RIGHT", cb, "RIGHT", 0, 0)
            else
                cb.icon:SetPoint("LEFT", cb, "LEFT", 0, 0)
            end
        end
    else
        cb.icon:Hide()
    end
    if not db.detachText then self:updateTextLayout() end
end
