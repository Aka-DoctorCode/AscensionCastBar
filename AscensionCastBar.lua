-- ==========================================================
-- AscensionCastBar - Version 4.4.0
-- ==========================================================
local ADDON_NAME = "Ascension Cast Bar"
local AscensionCastBar = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")

-- ==========================================================
-- INITIALIZATION
-- ==========================================================

function AscensionCastBar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AscensionCastBarDB", self.defaults, "Default")

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    self:SetupOptions()
    self:CreateBar()
end

function AscensionCastBar:OnEnable()
    self:ValidateAnimationParams()
    self:UpdateDefaultCastBarVisibility()
    self:InitCDMHooks()

    -- Register Events
    self:RegisterEvent("UNIT_SPELLCAST_START", "HandleCastStart")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "HandleCastStart")
    self:RegisterEvent("UNIT_SPELLCAST_STOP", "HandleCastStop")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "HandleCastStop")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "HandleCastStop")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED", "HandleCastStop")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateDefaultCastBarVisibility")

    -- Empowered Events (Retail 11.0+)
    pcall(function()
        self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START", "HandleCastStart")
        self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP", "HandleCastStop")
        self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "HandleCastStart")
    end)

    -- Chat Commands
    self:RegisterChatCommand("acb", "OpenConfig")
    self:RegisterChatCommand("ascensioncastbar", "OpenConfig")

    self:RefreshConfig()
end

function AscensionCastBar:RefreshConfig()
    self:ValidateAnimationParams() -- Añadir esta línea
    self:UpdateAnchor()
    self:UpdateSparkSize()
    self:UpdateIcon()
    self:ApplyFont()
    self:UpdateBarColor()
    self:UpdateBackground()
    self:UpdateBorder()
    self:UpdateTextLayout()
    self:UpdateSparkColors()
    self:UpdateDefaultCastBarVisibility()
end

-- ==========================================================
-- CORE FUNCTIONS
-- ==========================================================

function AscensionCastBar:ClampAlpha(v)
    v = tonumber(v) or 0
    -- Validar valores especiales
    if v ~= v then return 0 end                   -- NaN
    if math.abs(v) == math.huge then return 1 end -- Infinito
    if v < 0 then v = 0 elseif v > 1 then v = 1 end
    return v
end

function AscensionCastBar:GetBlizzardCastBars()
    local frames = {}
    if _G["CastingBarFrame"] then table.insert(frames, _G["CastingBarFrame"]) end
    if _G["PlayerCastingBarFrame"] then table.insert(frames, _G["PlayerCastingBarFrame"]) end
    return frames
end

function AscensionCastBar:UpdateDefaultCastBarVisibility()
    local hide = self.db.profile.hideDefaultCastbar
    local frames = self:GetBlizzardCastBars()

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

-- ==========================================================
-- CHAT COMMANDS
-- ==========================================================

function AscensionCastBar:OpenConfig()
    LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)
end

-- ==========================================================
-- ANIMATION PARAMETERS MANAGEMENT
-- ==========================================================

function AscensionCastBar:ResetAnimationParams(style)
    if style and self.ANIMATION_STYLE_PARAMS[style] then
        self.db.profile.animationParams[style] = CopyTable(self.ANIMATION_STYLE_PARAMS[style])
    else
        -- Reset all styles
        for styleName, defaults in pairs(self.ANIMATION_STYLE_PARAMS) do
            self.db.profile.animationParams[styleName] = CopyTable(defaults)
        end
    end
    self:RefreshConfig()
end

-- Función auxiliar CopyTable (añadir si no existe)
if not CopyTable then
    function CopyTable(orig)
        local copy = {}
        for key, value in pairs(orig) do
            if type(value) == "table" then
                copy[key] = CopyTable(value)
            else
                copy[key] = value
            end
        end
        return copy
    end
end

-- ==========================================================
-- VALIDATION FUNCTIONS
-- ==========================================================

function AscensionCastBar:ValidateAnimationParams()
    local db = self.db.profile

    -- Asegurarse de que animationParams exista
    if not db.animationParams then
        db.animationParams = {}
    end

    -- Inicializar cada estilo si no existe
    for styleName, defaults in pairs(self.ANIMATION_STYLE_PARAMS or {}) do
        if not db.animationParams[styleName] then
            db.animationParams[styleName] = {}
            for key, value in pairs(defaults) do
                db.animationParams[styleName][key] = value
            end
        else
            -- Asegurar que todos los parámetros existan
            for key, value in pairs(defaults) do
                if db.animationParams[styleName][key] == nil then
                    db.animationParams[styleName][key] = value
                end
            end
        end
    end

    -- Validar valores específicos
    local style = db.animStyle
    if style and db.animationParams[style] then
        local params = db.animationParams[style]

        -- Para Pulse, asegurar que rippleCycle no sea 0
        if style == "Pulse" then
            if not params.rippleCycle or params.rippleCycle <= 0 then
                params.rippleCycle = 1.0
            end
        end

        -- Para cualquier parámetro numérico, asegurar que sea válido
        for key, value in pairs(params) do
            if type(value) == "number" then
                -- Reemplazar valores NaN o infinitos
                if value ~= value or math.abs(value) == math.huge then
                    params[key] = self.ANIMATION_STYLE_PARAMS[style][key] or 1.0
                end
            end
        end
    end
end
