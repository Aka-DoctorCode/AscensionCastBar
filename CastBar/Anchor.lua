-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Anchor.lua
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

local barButtonConfig = {
    ["ActionBar1"] = { btStart = 1, btEnd = 12 },
    ["ActionBar2"] = { btStart = 61, btEnd = 72 },
    ["ActionBar3"] = { btStart = 49, btEnd = 60 },
    ["ActionBar4"] = { btStart = 25, btEnd = 36 },
    ["ActionBar5"] = { btStart = 37, btEnd = 48 },
    ["ActionBar6"] = { btStart = 145, btEnd = 156 },
    ["ActionBar7"] = { btStart = 157, btEnd = 168 },
    ["ActionBar8"] = { btStart = 169, btEnd = 181 },
    ["BT4Bonus"]   = { btStart = 13, btEnd = 24 },
    ["BT4Class1"]  = { btStart = 73, btEnd = 84 },
    ["BT4Class2"]  = { btStart = 85, btEnd = 96 },
    ["BT4Class3"]  = { btStart = 97, btEnd = 108 },
    ["BT4Class4"]  = { btStart = 109, btEnd = 120 },
}

function AscensionCastBar:updateStrata()
    if not self.castBar then return end
    local strata = self.db.profile.frameStrata or "MEDIUM"
    self.castBar:SetFrameStrata(strata)
end

function AscensionCastBar:getCDMTargetFrame()
    local target = self.db.profile.cdmTarget
    local isBT4 = C_AddOns.IsAddOnLoaded("Bartender4")

    if target == "Buffs" then
        return _G["BuffIconCooldownViewer"]
    elseif target == "Essential" then
        return _G["EssentialCooldownViewer"]
    elseif target == "Utility" then
        return _G["UtilityCooldownViewer"]
    elseif target == "PlayerFrame" then
        return _G["PlayerFrame"]
    elseif isBT4 and (barButtonConfig[target] or target:find("BT4")) then
    elseif target == "ActionBar1" then
        return _G["MainMenuBar"]
    elseif target == "ActionBar2" then
        return _G["MultiBarBottomLeft"]
    elseif target == "ActionBar3" then
        return _G["MultiBarBottomRight"]
    elseif target == "ActionBar4" then
        return _G["MultiBarRight"]
    elseif target == "ActionBar5" then
        return _G["MultiBarLeft"]
    elseif target == "ActionBar6" then
        return _G["MultiBar5"]
    elseif target == "ActionBar7" then
        return _G["MultiBar6"]
    elseif target == "ActionBar8" then
        return _G["MultiBar7"]
    elseif target == "PersonalResource" then
        return _G["PersonalResourceDisplayFrame"]
    end

    return nil
end

function AscensionCastBar:updateAnchor()
    if not self.castBar then return end

    local db = self.db.profile
    local testOverride = (self.db.profile.previewEnabled and not self.db.profile.testAttached)
    if not db.attachToCDM or testOverride then
        self.castBar:ClearAllPoints()
        self.castBar:SetPoint(db.point, UIParent, db.relativePoint, db.manualX, db.manualY)
        self.castBar.baseWidth = db.manualWidth or 270
        self:updateBarColor()
        return
    end

    local target = db.cdmTarget
    local isBT4 = C_AddOns.IsAddOnLoaded("Bartender4")
    local btConfig = barButtonConfig[target]

    local useProxy = false
    local startBtn, endBtn, btnPrefix

    if isBT4 and btConfig then
        useProxy = true
        startBtn = btConfig.btStart
        endBtn = btConfig.btEnd

        if _G["BT4Button" .. startBtn] then
            btnPrefix = "BT4Button"
        elseif _G["BTButton" .. startBtn] then
            btnPrefix = "BTButton"
        else
            btnPrefix = "BT4Button"
        end
    elseif target == "ActionBar1" and not isBT4 then
        useProxy = true
        startBtn = 1
        endBtn = 12
        btnPrefix = "ActionButton"
    end

    if useProxy then
        -- === PROXY MODE ===
        if not self.actionBarProxy then
            self.actionBarProxy = CreateFrame("Frame", nil, UIParent)
            self.actionBarProxy:SetSize(1, 1)
            self.actionBarProxy:SetScript("OnUpdate", function(f, elapsed)
                f.timer = (f.timer or 0) + elapsed
                if f.timer > 0.5 then
                    f.timer = 0
                    self:updateProxyFrame()
                end
            end)
        end

        self.actionBarProxy.btnConfig = { prefix = btnPrefix, startBtn = startBtn, endBtn = endBtn }
        self.actionBarProxy:Show()
        self:updateProxyFrame()
    else
        -- === STANDARD FRAME MODE ===
        if self.actionBarProxy then self.actionBarProxy:Hide() end

        local targetFrame = self:getCDMTargetFrame()

        if targetFrame then
            self.castBar:ClearAllPoints()
            self.castBar:SetPoint("BOTTOM", targetFrame, "TOP", 0, db.cdmYOffset or 0)
            local tWidth = targetFrame:GetWidth()
            if tWidth and tWidth > 10 and tWidth <= UIParent:GetWidth() then
                self.castBar.baseWidth = tWidth
            else
                self.castBar.baseWidth = db.manualWidth or 270
            end
            self:updateBarColor()
        else
            self.castBar:ClearAllPoints()
            self.castBar:SetPoint(db.point, UIParent, db.relativePoint, db.manualX, db.manualY)
            self.castBar.baseWidth = db.manualWidth or 270
            self:updateBarColor()
        end
    end
end

function AscensionCastBar:initCDMHooks()
    local db = self.db.profile
    if not db.attachToCDM then return end

    if not self.editModeEventsRegistered then
        if type(EventRegistry) == "table" and EventRegistry.RegisterCallback then
            EventRegistry:RegisterCallback("EditMode.Exit", self.updateAnchor, self)
        end
        self.editModeEventsRegistered = true
    end

    local isBT4 = C_AddOns.IsAddOnLoaded("Bartender4")
    local isProxy = (isBT4 and (barButtonConfig[db.cdmTarget] or db.cdmTarget:find("BT4"))) or
        (db.cdmTarget == "ActionBar1" and not isBT4)

    if isProxy then
        self:updateAnchor()
        return
    end

    local targetFrame = self:getCDMTargetFrame()

    if targetFrame then
        if self.lastHookedFrame ~= targetFrame then
            self.lastHookedFrame = targetFrame
            local updateFunc = function()
                if self.db.profile.attachToCDM then self:updateAnchor() end
            end
            pcall(function()
                hooksecurefunc(targetFrame, "SetPoint", updateFunc)
                hooksecurefunc(targetFrame, "Show", updateFunc)
                hooksecurefunc(targetFrame, "Hide", updateFunc)
                hooksecurefunc(targetFrame, "SetSize", updateFunc)
            end)
            self:updateAnchor()
        end
        if self.cdmFinderTimer then
            self.cdmFinderTimer:Cancel(); self.cdmFinderTimer = nil
        end
    else
        if not self.cdmFinderTimer then
            self.cdmFinderTimer = C_Timer.NewTicker(1, function()
                local tf = self:getCDMTargetFrame()
                if tf then self:initCDMHooks() end
            end, 60)
        end
    end
end

function AscensionCastBar:updateProxyFrame()
    if not self.actionBarProxy or not self.actionBarProxy.btnConfig then return end

    local cfg = self.actionBarProxy.btnConfig
    local minX, maxX, minY, maxY
    local found = false

    local uiScale = UIParent:GetEffectiveScale()
    if not uiScale or uiScale <= 0 then uiScale = 1 end

    for i = cfg.startBtn, cfg.endBtn do
        local btn = _G[cfg.prefix .. i]
        if btn and btn:IsShown() then
            local btnScale = btn:GetEffectiveScale() or 1
            local l, r, t, b = btn:GetLeft(), btn:GetRight(), btn:GetTop(), btn:GetBottom()

            if l and r and t and b then
                l, r, t, b = l * btnScale, r * btnScale, t * btnScale, b * btnScale

                if not minX or l < minX then minX = l end
                if not maxX or r > maxX then maxX = r end
                if not minY or b < minY then minY = b end
                if not maxY or t > maxY then maxY = t end
                found = true
            end
        end
    end

    if found then
        local width = (maxX - minX) / uiScale
        local height = (maxY - minY) / uiScale

        if width < 1 then width = 1 end
        if height < 1 then height = 1 end

        local screenCenterX = (minX + maxX) / 2
        local screenCenterY = (minY + maxY) / 2

        local anchorX = screenCenterX / uiScale
        local anchorY = screenCenterY / uiScale

        self.actionBarProxy:ClearAllPoints()
        self.actionBarProxy:SetPoint("CENTER", UIParent, "BOTTOMLEFT", anchorX, anchorY)
        self.actionBarProxy:SetSize(width, height)

        if self.castBar then
            self.castBar:ClearAllPoints()
            self.castBar:SetPoint("BOTTOM", self.actionBarProxy, "TOP", 0, self.db.profile.cdmYOffset or 0)

            if width > 10 then
                self.castBar.baseWidth = width
                self:updateBarColor()
                if self.castBar.isEmpowered then
                    self:addEmpowerStages(self.castBar.numStages - 1)
                end
            end
        end
    end
end
