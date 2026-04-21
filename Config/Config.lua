-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Config/Config.lua
-- Version: @project-version@
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in
-- derivative works without express written permission.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
---@class AscensionCastBar: AceAddon
local AscensionCastBar = addonTable.main or LibStub("AceAddon-3.0"):GetAddon("Ascension Cast Bar")
local colors = AscensionCastBar.colors or {}
local files = AscensionCastBar.files or {}
local menuStyle = AscensionCastBar.menuStyle or {}

-- Initialize tab registry in the shared namespace
addonTable.tabs = addonTable.tabs or {}

---Toggles the main configuration menu
function AscensionCastBar:toggleConfigMenu()
    -- On the very first call, create and show immediately
    if not self.mainFrame then
        self:CreateMainFrame()
        self.mainFrame:Show()
        return
    end

    local mf = self.mainFrame
    if mf:IsShown() then
        mf:Hide()
    else
        mf:Show()
    end
end

---Creates the main frame and sidebar container
function AscensionCastBar:CreateMainFrame()
    local UIContext = addonTable.UIContext
    if not UIContext then return end

    local frame = CreateFrame("Frame", "AscensionCastBarConfigFrame", UIParent, "BackdropTemplate")
    local frameWidth = 800
    local frameHeight = 560
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetBackdrop({
        bgFile = files.bgFile or [[Interface\Buttons\WHITE8X8]],
        edgeFile = files.edgeFile or [[Interface\Buttons\WHITE8X8]],
        edgeSize = menuStyle.backdropEdgeSize or 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(unpack(colors.backgroundDark or {0,0,0,1}))
    frame:SetBackdropBorderColor(unpack(colors.surfaceHighlight or {1,1,1,1}))

    -- Add to UISpecialFrames so ESC closes it
    tinsert(UISpecialFrames, "AscensionCastBarConfigFrame")

    -- Header / Title
    local title = frame:CreateFontString(nil, "OVERLAY", menuStyle.headerFont or "GameFontNormal")
    title:SetPoint("TOPLEFT", menuStyle.titleLeft or 16, menuStyle.titleTop or -16)
    title:SetText("Ascension Cast Bar")
    title:SetTextColor(unpack(colors.gold or {1,1,0,1}))

    -- Close Button
    local close = CreateFrame("Button", nil, frame)
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", -12, -12)
    close:SetNormalTexture(files.close or [[Interface\Buttons\UI-Panel-MinimizeButton-Up]])
    close:SetScript("OnClick", function() frame:Hide() end)

    -- Tab Configuration for the library
    local tabData = {
        { id = "general",    label = "General" },
        { id = "castbar",    label = "Appearance" },
        { id = "text",       label = "Text & Fonts" },
        { id = "mechanics",  label = "Mechanics" },
        { id = "visualfx",   label = "Visual FX" },
        { id = "profiles",   label = "Profiles" },
    }

    local tabNames = {}
    local tabBuildFuncs = {}

    for _, item in ipairs(tabData) do
        table.insert(tabNames, item.label)
        table.insert(tabBuildFuncs, function(contentFrame)
            local layout = UIContext:newLayout(contentFrame)
            if addonTable.tabs[item.id] then
                addonTable.tabs[item.id]:Render(layout, self.db.profile)
            end
        end)
    end

    -- Create and initialize the tabbed interface via UIContext
    local menu = UIContext:createTabbedInterface(frame, tabNames, tabBuildFuncs, 1)
    
    -- Expose SelectTab for external use
    self.SelectTab = function(_, tabID)
        for i, item in ipairs(tabData) do
            if item.id == tabID then
                menu.selectTab(i)
                break
            end
        end
    end

    self.mainFrame = frame
end