-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Config.lua
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
---@class AscensionCastBar: AceAddon
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
if not AscensionCastBar then return end

local colors = AscensionCastBar.colors or {}
local files = AscensionCastBar.files or {}
local menuStyle = AscensionCastBar.menuStyle or {}

-- Cleans up a panel by hiding all children and regions
local function cleanupContent(contentPanel)
    if not contentPanel then return end
    for _, child in ipairs({ contentPanel:GetChildren() }) do
        child:Hide()
        child:ClearAllPoints()
    end
    for _, region in ipairs({ contentPanel:GetRegions() }) do
        if region.Hide then region:Hide() end
    end
end

-- Sets a standard GameTooltip for a given UI frame
local function setTooltip(frame, text)
    if not frame or not text then return end
    frame:SetScript("OnEnter", function(self)
        if _G.GameTooltip then
            _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            _G.GameTooltip:SetText(text, 1, 1, 1)
            _G.GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function()
        if _G.GameTooltip then _G.GameTooltip:Hide() end
    end)
end

-- Integrates the custom layout management into the centralized UI Context
local function initUIContext()
    local UIContext = addonTable.UIContext
    if not UIContext then return end
    UIContext.newLayout = function(context, contentFrame)
        cleanupContent(contentFrame)
        if context.layoutModel and context.layoutModel.reset then
            return context.layoutModel:reset(contentFrame)
        end
        return context.layoutModel
    end
end

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
    initUIContext()

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

    -- Close Button (Premium Aesthetic)
    local close = CreateFrame("Button", nil, frame)
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", -12, -12)
    
    local closeTex = close:CreateTexture(nil, "OVERLAY")
    closeTex:SetAllPoints()
    closeTex:SetTexture(files.close or [[Interface\Buttons\UI-Panel-MinimizeButton-Up]])
    
    close:SetScript("OnEnter", function() 
        closeTex:SetVertexColor(unpack(colors.primary or {1,1,1,1})) 
    end)
    close:SetScript("OnLeave", function() 
        closeTex:SetVertexColor(1, 1, 1, 1) 
    end)
    close:SetScript("OnClick", function() frame:Hide() end)

    -- Resize Handle (Premium Aesthetic)
    frame:SetResizable(true)
    frame:SetResizeBounds(600, 400, 1200, 900)

    local resize = CreateFrame("Button", nil, frame)
    resize:SetSize(20, 20)
    resize:SetPoint("BOTTOMRIGHT", -4, 4)
    
    local resizeTex = resize:CreateTexture(nil, "OVERLAY")
    resizeTex:SetSize(16, 16)
    resizeTex:SetPoint("CENTER")
    resizeTex:SetTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]])
    resizeTex:SetVertexColor(unpack(colors.gold or {1,1,1,1}))

    resize:SetScript("OnEnter", function() 
        resizeTex:SetVertexColor(unpack(colors.primary or {1,1,1,1})) 
    end)
    resize:SetScript("OnLeave", function() 
        resizeTex:SetVertexColor(unpack(colors.gold or {1,1,1,1})) 
    end)
    resize:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    resize:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

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
        local tabID = item.id -- Fix closure capturing
        table.insert(tabNames, item.label)
        table.insert(tabBuildFuncs, function(contentFrame)
            -- Ensure we use the scroll content frame if available from the factory
            local targetFrame = contentFrame.content or contentFrame
            local layout = UIContext:newLayout(targetFrame)
            
            if addonTable.tabs[tabID] then
                addonTable.tabs[tabID]:render(layout, self.db.profile)
                -- Auto-resize the content frame to fit the last Y position
                targetFrame:SetHeight(math.abs(layout.y) + 50)
            end
        end)
    end

    -- Create and initialize the tabbed interface via UIContext
    local menu = UIContext:createTabbedInterface(frame, tabNames, tabBuildFuncs, 1)
    
    -- Expose selectTab for external use
    self.selectTab = function(_, tabID)
        for i, item in ipairs(tabData) do
            if item.id == tabID then
                menu.selectTab(i)
                break
            end
        end
    end

    self.mainFrame = frame
end