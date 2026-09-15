-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Text.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

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

    local isVertical = (db.orientation == "VERTICAL")

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
        cb.spellName:SetJustifyH("LEFT")
        cb.spellName:SetPoint("LEFT", cb.textCtx, "LEFT", 5, 0)
        cb.spellName:SetPoint("RIGHT", cb.timer, "LEFT", -5, 0)

        cb.timer:ClearAllPoints()
        cb.timer:SetJustifyH("RIGHT")
        cb.timer:SetPoint("RIGHT", cb.textCtx, "RIGHT", -5, 0)
    elseif isVertical then
        cb.textCtx:ClearAllPoints()
        cb.textCtx.bg:SetColorTexture(0, 0, 0, 0)
        cb.spellName:ClearAllPoints()
        cb.timer:ClearAllPoints()

        local iconH = 0
        if db.showIcon and not db.detachIcon then
            iconH = cb:GetWidth() > 0 and cb:GetWidth() or 24
        end

        local layoutMode = db.verticalTextLayout or "StackedInside"

        if layoutMode == "OutsideTop" then
            cb.textCtx:SetPoint("BOTTOM", cb, "TOP", 0, 4)
            cb.textCtx:SetSize(db.textWidth or 200, (db.spellNameFontSize or 14) + 10)
            cb.spellName:SetJustifyH("LEFT")
            cb.spellName:SetPoint("LEFT", cb.textCtx, "LEFT", 0, 0)
            cb.spellName:SetPoint("RIGHT", cb.timer, "LEFT", -4, 0)
            cb.timer:SetJustifyH("RIGHT")
            cb.timer:SetPoint("RIGHT", cb.textCtx, "RIGHT", 0, 0)
        elseif layoutMode == "OutsideBottom" then
            cb.textCtx:SetPoint("TOP", cb, "BOTTOM", 0, -4)
            cb.textCtx:SetSize(db.textWidth or 200, (db.spellNameFontSize or 14) + 10)
            cb.spellName:SetJustifyH("LEFT")
            cb.spellName:SetPoint("LEFT", cb.textCtx, "LEFT", 0, 0)
            cb.spellName:SetPoint("RIGHT", cb.timer, "LEFT", -4, 0)
            cb.timer:SetJustifyH("RIGHT")
            cb.timer:SetPoint("RIGHT", cb.textCtx, "RIGHT", 0, 0)
        elseif layoutMode == "OutsideRight" then
            cb.textCtx:SetPoint("LEFT", cb, "RIGHT", 8, 0)
            cb.textCtx:SetSize(db.textWidth or 200, cb:GetHeight())
            cb.spellName:SetJustifyH("LEFT")
            cb.spellName:SetPoint("TOPLEFT", cb.textCtx, "TOPLEFT", 0, -4)
            cb.timer:SetJustifyH("LEFT")
            cb.timer:SetPoint("BOTTOMLEFT", cb.textCtx, "BOTTOMLEFT", 0, 4)
        elseif layoutMode == "OutsideLeft" then
            cb.textCtx:SetPoint("RIGHT", cb, "LEFT", -8, 0)
            cb.textCtx:SetSize(db.textWidth or 200, cb:GetHeight())
            cb.spellName:SetJustifyH("RIGHT")
            cb.spellName:SetPoint("TOPRIGHT", cb.textCtx, "TOPRIGHT", 0, -4)
            cb.timer:SetJustifyH("RIGHT")
            cb.timer:SetPoint("BOTTOMRIGHT", cb.textCtx, "BOTTOMRIGHT", 0, 4)
        elseif layoutMode == "Default" then
            cb.textCtx:SetAllPoints(cb)
            cb.spellName:SetJustifyH("LEFT")
            cb.timer:SetJustifyH("RIGHT")
            cb.spellName:SetPoint("LEFT", cb.textCtx, "LEFT", 5, 0)
            cb.timer:SetPoint("RIGHT", cb.textCtx, "RIGHT", -5, 0)
        else
            -- "StackedInside"
            cb.textCtx:SetAllPoints(cb)
            local topPad = (db.iconAnchor == "Top" and iconH > 0) and (iconH + 4) or 4
            local btmPad = (db.iconAnchor == "Bottom" and iconH > 0) and (iconH + 4) or 4

            cb.spellName:SetJustifyH("CENTER")
            cb.spellName:SetPoint("TOP", cb.textCtx, "TOP", 0, -topPad)
            cb.spellName:SetPoint("LEFT", cb.textCtx, "LEFT", 2, 0)
            cb.spellName:SetPoint("RIGHT", cb.textCtx, "RIGHT", -2, 0)

            cb.timer:SetJustifyH("CENTER")
            cb.timer:SetPoint("BOTTOM", cb.textCtx, "BOTTOM", 0, btmPad)
            cb.timer:SetPoint("LEFT", cb.textCtx, "LEFT", 2, 0)
            cb.timer:SetPoint("RIGHT", cb.textCtx, "RIGHT", -2, 0)
        end
    else
        cb.textCtx:ClearAllPoints()
        cb.textCtx:SetAllPoints(cb)
        cb.textCtx.bg:SetColorTexture(0, 0, 0, 0)

        cb.spellName:ClearAllPoints()
        cb.spellName:SetJustifyH("LEFT")
        cb.timer:ClearAllPoints()
        cb.timer:SetJustifyH("RIGHT")

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
    if not cb or not cb.spellName or not cb.timer then return end

    local outlineMode = db.outline or "OUTLINE"
    local fontOutlineFlag = ""
    if outlineMode == "OUTLINE" or outlineMode == "OUTLINESHADOW" then
        fontOutlineFlag = "OUTLINE"
    elseif outlineMode == "THICKOUTLINE" then
        fontOutlineFlag = "THICKOUTLINE"
    elseif outlineMode == "MONOCHROME" then
        fontOutlineFlag = "MONOCHROME"
    end

    local r, g, b, a = unpack(db.fontColor or {1,1,1,1})
    local sP = LSM:Fetch("font", db.spellNameFontLSM) or self.barDefaultFontPath
    cb.spellName:SetFont(sP, db.spellNameFontSize, fontOutlineFlag)
    cb.spellName:SetTextColor(r, g, b, a)

    if not db.useSharedColor and db.timerColor then
        r, g, b, a = unpack(db.timerColor or {1,1,1,1})
    end

    local tP = LSM:Fetch("font", db.timerFontLSM) or self.barDefaultFontPath
    cb.timer:SetFont(tP, db.timerFontSize, fontOutlineFlag)
    cb.timer:SetTextColor(r, g, b, a)

    if outlineMode == "SHADOW" or outlineMode == "OUTLINESHADOW" then
        local thickness = db.shadowThickness or 1
        local shadowX = (db.shadowOffsetX or 1) * thickness
        local shadowY = (db.shadowOffsetY or -1) * thickness
        local sr, sg, sb, sa = unpack(db.shadowColor or { 0, 0, 0, 1 })
        cb.spellName:SetShadowOffset(shadowX, shadowY)
        cb.spellName:SetShadowColor(sr, sg, sb, sa)
        cb.timer:SetShadowOffset(shadowX, shadowY)
        cb.timer:SetShadowColor(sr, sg, sb, sa)
    else
        cb.spellName:SetShadowOffset(0, 0)
        cb.spellName:SetShadowColor(0, 0, 0, 0)
        cb.timer:SetShadowOffset(0, 0)
        cb.timer:SetShadowColor(0, 0, 0, 0)
    end
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
