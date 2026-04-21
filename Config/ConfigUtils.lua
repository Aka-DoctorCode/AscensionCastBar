-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: ConfigUtils.lua
-- Version: @project-version@
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in
-- derivative works without express written permission.
-------------------------------------------------------------------------------

local addonName, addonTable = ...

-- Object-Oriented module for Config Utilities
addonTable.configUtils = {}
---@type AscensionCastBar
local AscensionCastBar = addonTable.main or LibStub("AceAddon-3.0"):GetAddon("Ascension Cast Bar")
local configUtils = addonTable.configUtils

-- Cleans up a panel by hiding all children and regions
function configUtils:cleanupContent(contentPanel)
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
function configUtils:setTooltip(frame, text)
    if not frame or not text then return end
    
    frame:SetScript("OnEnter", function(self)
        if _G.GameTooltip then
            _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            _G.GameTooltip:SetText(text, 1, 1, 1) -- #FFFFFF
            _G.GameTooltip:Show()
        end
    end)
    
    frame:SetScript("OnLeave", function()
        if _G.GameTooltip then
            _G.GameTooltip:Hide()
        end
    end)
end

-- Integrates the custom layout management into the centralized UI Context
function configUtils:init()
    local UIContext = addonTable.UIContext
    if not UIContext then return end

    -- Custom method to cleanup a frame and return its layout model
    UIContext.newLayout = function(context, contentFrame)
        self:cleanupContent(contentFrame)
        if context.layoutModel and context.layoutModel.reset then
            return context.layoutModel:reset(contentFrame)
        end
        -- Fallback to creating a new one if reset is not available
        return context.layoutModel
    end
end

-- Auto-initialize if the context is already available
if addonTable.UIContext then
    configUtils:init()
end