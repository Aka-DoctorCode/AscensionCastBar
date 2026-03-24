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
addonTable.tabs = {}

---Toggles the main configuration menu
function AscensionCastBar:ToggleConfigMenu()
    -- On the very first call, create and show immediately
    if not self.mainFrame then
        self:CreateMainFrame()
        self.mainFrame:Show()
        self:SelectTab(addonTable.activeTab or "general")
        return
    end

    local mf = self.mainFrame
    if mf:IsShown() then
        mf:Hide()
    else
        mf:Show()
        -- Ensure the current tab is rendered when showing
        self:SelectTab(addonTable.activeTab or "general")
    end
end

---Creates the main frame and sidebar container
function AscensionCastBar:CreateMainFrame()
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

    -- Sidebar background
    local sbWidth = menuStyle.sidebarWidth or 160
    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetSize(sbWidth, frameHeight - 50)
    sidebar:SetPoint("TOPLEFT", 0, -50)
    sidebar:SetBackdrop({
        bgFile = files.bgFile or [[Interface\Buttons\WHITE8X8]],
        insets = { left = 0, right = 1, top = 0, bottom = 0 }
    })
    sidebar:SetBackdropColor(unpack(colors.sidebarBg or {0,0,0,0.5}))

    -- Content Area
    local scrollFrame = CreateFrame("ScrollFrame", "AscensionCastBarConfigScroll", frame, "UIPanelScrollFrameTemplate")
    local contentPadding = menuStyle.contentPadding or 16
    scrollFrame:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", contentPadding, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 20)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(frameWidth - sbWidth - 50, 1)
    scrollFrame:SetScrollChild(content)

    -- Assign references
    self.mainFrame = frame
    self.sidebar = sidebar
    self.contentFrame = content
    self.navButtons = {}

    self:InitializeNavigation()
end

---Registers navigation buttons in the sidebar
function AscensionCastBar:InitializeNavigation()
    local navItems = {
        { id = "general",    label = "General" },
        { id = "castbar",    label = "Appearance" },
        { id = "text",       label = "Text & Fonts" },
        { id = "mechanics",  label = "Mechanics" },
        { id = "visualfx",   label = "Visual FX" },
        { id = "profiles",   label = "Profiles" },
    }

    local yOffset = -20
    local tabWidth = menuStyle.tabWidth or 144
    local tabHeight = menuStyle.tabHeight or 30
    local tabSpacing = menuStyle.tabSpacing or 6

    for _, item in ipairs(navItems) do
        local btn = CreateFrame("Button", nil, self.sidebar, "BackdropTemplate")
        btn:SetSize(tabWidth, tabHeight)
        btn:SetPoint("TOP", 0, yOffset)
        
        btn:SetBackdrop({ bgFile = files.bgFile or [[Interface\Buttons\WHITE8X8]] })
        btn:SetBackdropColor(0, 0, 0, 0)

        -- Active Accent (Vertical bar)
        local accent = btn:CreateTexture(nil, "OVERLAY")
        accent:SetWidth(menuStyle.sidebarAccentWidth or 3)
        accent:SetPoint("TOPLEFT", -8, 0)
        accent:SetPoint("BOTTOMLEFT", -8, 0)
        accent:SetColorTexture(unpack(colors.primary or {1,1,1,1}))
        accent:Hide()
        btn.accent = accent

        local text = btn:CreateFontString(nil, "OVERLAY", menuStyle.labelFont or "GameFontHighlight")
        text:SetText(item.label)
        text:SetPoint("LEFT", 12, 0)
        text:SetTextColor(unpack(colors.textDim or {0.7,0.7,0.7,1}))
        btn.text = text

        btn:SetScript("OnClick", function()
            self:SelectTab(item.id)
        end)

        btn:SetScript("OnEnter", function(s)
            if addonTable.activeTab ~= item.id then
                s:SetBackdropColor(unpack(colors.sidebarHover or {0.5,0.5,0.5,0.5}))
            end
        end)
        btn:SetScript("OnLeave", function(s)
            if addonTable.activeTab ~= item.id then
                s:SetBackdropColor(0, 0, 0, 0)
            end
        end)

        self.navButtons[item.id] = btn
        yOffset = yOffset - (tabHeight + tabSpacing)
    end
end

---Cleans the content frame and renders the selected module
---@param tabID string
function AscensionCastBar:SelectTab(tabID)
    if not addonTable.tabs[tabID] then return end

    -- Update Sidebar visual state
    for id, btn in pairs(self.navButtons) do
        if id == tabID then
            btn:SetBackdropColor(unpack(colors.sidebarActive or {0,1,0,0.5}))
            btn.accent:Show()
            btn.text:SetTextColor(unpack(colors.textLight or {1,1,1,1}))
        else
            btn:SetBackdropColor(0, 0, 0, 0)
            btn.accent:Hide()
            btn.text:SetTextColor(unpack(colors.textDim or {0.7,0.7,0.7,1}))
        end
    end

    -- Cleanup current content
    local contentArea = self.contentFrame
    if contentArea then
        local children = { contentArea:GetChildren() }
        for _, child in ipairs(children) do
            child:Hide()
            child:SetParent(nil)
        end
    end

    addonTable.activeTab = tabID

    -- Instantiate UIFactory via the Layout Model
    local layoutFactoryInstance = addonTable.layoutFactory
    if layoutFactoryInstance and layoutFactoryInstance.new then
        local layout = layoutFactoryInstance:new(self.contentFrame)
        -- Execute Render
        addonTable.tabs[tabID]:Render(layout, self.db.profile)
    end
end

-- Initialize the Slash Commands
SLASH_ASCENSION1 = "/ascension"
SlashCmdList["ASCENSION"] = function()
    AscensionCastBar:ToggleConfigMenu()
end