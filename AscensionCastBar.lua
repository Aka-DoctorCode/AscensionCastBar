-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: AscensionCastBar.lua
-- Version: V55
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in
-- derivative works without express written permission.
-------------------------------------------------------------------------------

---@class AceAddon
---@field OnInitialize function
---@field OnEnable function
---@field OnDisable function
---@class AceEvent
---@field RegisterEvent function
---@field UnregisterEvent function
---@field UnregisterAllEvents function
---@class AceConsole
---@field RegisterChatCommand function
---@field UnregisterChatCommand function
---@class AceHook
---@field Hook function
---@field SecureHook function
---@field Unhook function
---@class AceDB
---@field profile table
---@field RegisterCallback function
---@class AscensionCastBar : AceAddon, AceEvent, AceConsole, AceHook
---@field db any
---@field defaults table
---@field optionsFrame table
---@field castBar any
---@field anchorFrame any
---@field barDefaultFontPath string
---@field channelTicks table
---@field animationStyleParams table
---@field AnimationStyles table
---@field testAttachedFrame any
---@field actionBarProxy any
---@field editModeEventsRegistered boolean
---@field lastHookedFrame any
---@field cdmFinderTimer any
---@field registeredElements table|nil
---@field activeTab number|nil
---@field colors table|nil
---@field files table|nil
---@field menuStyle table|nil
---@field OnInitialize function
---@field OnEnable function
---@field OnDisable function
---@field setupOptions function
---@field toggleTestMode function
---@field updateDefaultCastBarVisibility function
---@field updateAnchor function
---@field updateSparkSize function
---@field updateIcon function
---@field initCDMHooks function
---@field UpdateBarTexture function
---@field updateBarColor function
---@field updateBackground function
---@field updateBorder function
---@field applyFont function
---@field updateTextVisibility function
---@field updateTextLayout function
---@field updateLatencyBar function
---@field updateTicks function
---@field updateSparkColors function
---@field createBar function
---@field addEmpowerStages function
---@field updateEmpowerStageHighlight function
---@field clearEmpowerStages function
---@field handleCastStart function
---@field handleCastStop function
---@field stopCast function
---@field onFrameUpdate function
---@field getFormattedTimer function
---@field setupCastBarShared function
---@field empowerStart function
---@field empowerUpdate function
---@field channelStart function
---@field channelUpdate function
---@field castStart function
---@field castUpdate function
---@field hideTicks function
---@field updateSpark function
---@field resetParticles function
---@field hideAllSparkElements function
---@field refreshConfig function
---@field getBlizzardCastBars function
---@field NAME_PLATE_UNIT_ADDED function
---@field NAME_PLATE_UNIT_REMOVED function
---@field resetAnimationParams function
---@field validateAnimationParams function
---@field toggleConfigMenu function
---@field openConfig function
---@field OpenConfig function
---@field updateStrata function
---@field updateLatency function

local addonName, addonTable = ...
local ADDON_NAME = "Ascension Cast Bar"
---@type AscensionCastBar
local AscensionCastBar = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")
addonTable.main = AscensionCastBar -- Set this immediately!
local LSM = LibStub("LibSharedMedia-3.0")

-- Inicialización explícita del namespace compartido
addonTable.tabs = addonTable.tabs or {}
addonTable.configUtils = nil
addonTable.UIContext = nil

-- -------------------------------------------------------------------------------
-- INITIALIZATION
-- -------------------------------------------------------------------------------



function AscensionCastBar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AscensionCastBarDB", self.defaults, "Default")

    local LibDualSpec = LibStub("LibDualSpec-1.0", true)
    if LibDualSpec then
        LibDualSpec:EnhanceDatabase(self.db, "Ascension Cast Bar")
    end

    self.db.RegisterCallback(self, "OnProfileChanged", "refreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "refreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "refreshConfig")

    self:setupOptions()

    if not self.db.profile.animationParams then
        self.db.profile.animationParams = {}
    end
    for style, params in pairs(self.animationStyleParams) do
        if not self.db.profile.animationParams[style] then
            self.db.profile.animationParams[style] = CopyTable(params)
        end
    end
    
    -- Initialize the Centralized UI Library context
    local UIFactory = LibStub("AscensionSuit-UI", true)
    if UIFactory then
        addonTable.UIContext = UIFactory:CreateContext({
            colors = self.colors,
            files = self.files,
            menuStyle = self.menuStyle
        })
    end

    self:createBar()
end

function AscensionCastBar:openConfig()
    if not addonTable.UIContext then
        local UIFactory = LibStub("AscensionSuit-UI", true)
        if UIFactory then
            addonTable.UIContext = UIFactory:CreateContext({
                colors = self.colors,
                files = self.files,
                menuStyle = self.menuStyle
            })
        end
    end
    
    if self.toggleConfigMenu then
        self:toggleConfigMenu()
    else
        print("|cff7F13ECAscension Cast Bar:|r Configuration system not loaded correctly.")
    end
end

function AscensionCastBar:OnEnable()
    self:validateAnimationParams()
    self:updateDefaultCastBarVisibility()
    self:initCDMHooks()
    self:RegisterEvent("ADDON_LOADED", "initCDMHooks")
    self:RegisterEvent("UNIT_SPELLCAST_START", "handleCastStart")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "handleCastStart")
    self:RegisterEvent("UNIT_SPELLCAST_STOP", "handleCastStop")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "handleCastStop")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "handleCastStop")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED", "handleCastStop")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "updateDefaultCastBarVisibility")
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    pcall(function()
        self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START", "handleCastStart")
        self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP", "handleCastStop")
        self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "handleCastStart")
    end)
    self:RegisterChatCommand("acb", "openConfig")
    self:RegisterChatCommand("ascensioncastbar", "openConfig")
    self:refreshConfig()
    if self.castBar then
        self.castBar:Hide()
        self:updateAnchor()
    end
end

function AscensionCastBar:refreshConfig()
    self:validateAnimationParams()
    self:updateAnchor()
    self:updateSparkSize()
    self:updateIcon()
    self:applyFont()
    self:updateBarColor()
    self:updateBackground()
    self:updateBorder()
    self:updateTextLayout()
    self:updateTextVisibility()
    self:updateSparkColors()
    self:updateTicks()
    self:updateLatency()
    self:updateStrata()
    self:updateDefaultCastBarVisibility()
end

-- -------------------------------------------------------------------------------
-- HELPER FUNCTIONS (Non-UI, Non-Logic)
-- -------------------------------------------------------------------------------


function AscensionCastBar:getBlizzardCastBars()
    local frames = {}
    if _G["CastingBarFrame"] then table.insert(frames, _G["CastingBarFrame"]) end
    if _G["PlayerCastingBarFrame"] then table.insert(frames, _G["PlayerCastingBarFrame"]) end
    return frames
end

function AscensionCastBar:updateDefaultCastBarVisibility()
    local hide = self.db.profile.hideDefaultCastbar
    local frames = self:getBlizzardCastBars()

    for _, frame in ipairs(frames) do
        if frame then
            if hide then
                frame:UnregisterAllEvents()
                frame:Hide()
            else
                frame:RegisterEvent("UNIT_SPELLCAST_START")
                frame:RegisterEvent("UNIT_SPELLCAST_STOP")
                frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
                frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
            end
        end
    end
end

function AscensionCastBar:NAME_PLATE_UNIT_ADDED(event, unit)
    if unit == "player" and self.db.profile.cdmTarget == "PersonalResource" then
        self:updateAnchor()
    end
end

function AscensionCastBar:NAME_PLATE_UNIT_REMOVED(event, unit)
    if unit == "player" and self.db.profile.cdmTarget == "PersonalResource" then
        self:updateAnchor()
    end
end


-- -------------------------------------------------------------------------------
-- ANIMATION PARAMETERS VALIDATION
-- -------------------------------------------------------------------------------

function AscensionCastBar:resetAnimationParams(style)
    if style and self.animationStyleParams[style] then
        self.db.profile.animationParams[style] = CopyTable(self.animationStyleParams[style])
    else
        for styleName, defaults in pairs(self.animationStyleParams) do
            self.db.profile.animationParams[styleName] = CopyTable(defaults)
        end
    end
    self:refreshConfig()
end

function AscensionCastBar:validateAnimationParams()
    if not self.db or not self.db.profile then return end
    local db = self.db.profile
    if not db.animationParams then db.animationParams = {} end
    if self.animationStyleParams then
        for styleName, defaults in pairs(self.animationStyleParams) do
            if styleName and defaults then
                if not db.animationParams[styleName] then
                    db.animationParams[styleName] = {}
                end
                for key, value in pairs(defaults) do
                    if key and value ~= nil and db.animationParams[styleName][key] == nil then
                        db.animationParams[styleName][key] = value
                    end
                end
            end
        end
    end
end

