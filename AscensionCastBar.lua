local ADDON_NAME = "AscensionBars"
local AB = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0", "AceConsole-3.0")

-- ==========================================================
-- 1. VALORES POR DEFECTO (AceDB)
-- ==========================================================
local defaults = {
    profile = {
        barHeightXP = 5,
        barHeightRep = 6,
        textHeight = 15,
        textSize = 12,
        yOffset = -2,
        paragonTextSize = 14,
        paragonTextYOffset = -100,
        paragonOnTop = true,
        splitParagonText = false,
        paragonTextGap = 5,
        showOnMouseover = false,
        hideInCombat = false,
        paragonScanThrottle = 60,
        paragonPendingColor = {r=0, g=1, b=0, a=1.0},
        useClassColorXP = false,
        xpBarColor = {r=0.0, g=0.4, b=0.9, a=1.0},
        useReactionColorRep = true,
        repBarColor = {r=0.0, g=1.0, b=0.0, a=1.0},
        textColor = {r=1.0, g=1.0, b=1.0, a=1.0},
        showRestedBar = true,
        restedBarColor = {r=0.6, g=0.4, b=0.8, a=1.0},
        repColors = {
            [1] = {r=0.8, g=0.133, b=0.133, a=0.70},
            [2] = {r=1.0, g=0.0, b=0.0, a=0.70},
            [3] = {r=0.933, g=0.4, b=0.133, a=0.70},
            [4] = {r=1.0, g=1.0, b=0.0, a=0.70},
            [5] = {r=0.0, g=1.0, b=0.0, a=0.70},
            [6] = {r=0.0, g=1.0, b=0.533, a=0.70},
            [7] = {r=0.0, g=1.0, b=0.8, a=0.70},
            [8] = {r=0.0, g=1.0, b=1.0, a=0.70},
            [9] = {r=0.858, g=0.733, b=0.008, a=0.70},
            [10] = {r=0.639, g=0.208, b=0.933, a=0.70},
            [11] = {r=0.255, g=0.412, b=0.882, a=0.70},
        }
    }
}

-- ==========================================================
-- 2. TABLA DE OPCIONES (AceConfig)
-- ==========================================================
local function GetOptions()
    local options = {
        name = "Ascension Bars",
        type = "group",
        args = {
            configMode = {
                name = "Modo Configuración",
                desc = "Muestra todos los elementos para realizar ajustes",
                type = "toggle",
                set = function(_, val) AB.state.isConfigMode = val; AB:UpdateDisplay() end,
                get = function() return AB.state.isConfigMode end,
                order = 1,
            },
            general = {
                name = "Ajustes Globales",
                type = "group",
                inline = true,
                order = 10,
                args = {
                    yOffset = {
                        name = "Posición Vertical (Y)",
                        type = "range", min = -1080, max = 0, step = 1,
                        set = function(_, val) AB.db.profile.yOffset = val; AB:UpdateDisplay() end,
                        get = function() return AB.db.profile.yOffset end,
                    },
                    textSize = {
                        name = "Tamaño de Fuente",
                        type = "range", min = 8, max = 30, step = 1,
                        set = function(_, val) AB.db.profile.textSize = val; AB:UpdateDisplay() end,
                        get = function() return AB.db.profile.textSize end,
                    },
                    textColor = {
                        name = "Color del Texto",
                        type = "color", hasAlpha = true,
                        set = function(_, r, g, b, a) 
                            local t = AB.db.profile.textColor
                            t.r, t.g, t.b, t.a = r, g, b, a
                            AB:UpdateDisplay()
                        end,
                        get = function() 
                            local t = AB.db.profile.textColor
                            return t.r, t.g, t.b, t.a
                        end,
                    },
                }
            },
            xpBar = {
                name = "Barra de Experiencia",
                type = "group",
                inline = true,
                order = 20,
                args = {
                    height = {
                        name = "Altura de Barra XP",
                        type = "range", min = 1, max = 50, step = 1,
                        set = function(_, val) AB.db.profile.barHeightXP = val; AB:UpdateDisplay() end,
                        get = function() return AB.db.profile.barHeightXP end,
                    },
                    useClassColor = {
                        name = "Usar Color de Clase",
                        type = "toggle",
                        set = function(_, val) AB.db.profile.useClassColorXP = val; AB:UpdateDisplay() end,
                        get = function() return AB.db.profile.useClassColorXP end,
                    },
                    color = {
                        name = "Color Personalizado",
                        type = "color", hasAlpha = true,
                        set = function(_, r, g, b, a) 
                            local t = AB.db.profile.xpBarColor
                            t.r, t.g, t.b, t.a = r, g, b, a
                            AB:UpdateDisplay()
                        end,
                        get = function() 
                            local t = AB.db.profile.xpBarColor
                            return t.r, t.g, t.b, t.a
                        end,
                        disabled = function() return AB.db.profile.useClassColorXP end,
                    },
                }
            },
            -- Aquí puedes seguir añadiendo el resto de opciones (Reputación, Paragon, etc.)
        }
    }
    return options
end

-- ==========================================================
-- 3. MÉTODOS DEL ADDON
-- ==========================================================
function AB:OnInitialize()
    -- Base de datos
    self.db = LibStub("AceDB-3.0"):New("AscensionBarsDB", defaults, true)
    
    -- Configuración AceConfig
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, GetOptions())
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, "Ascension Bars")
    
    -- Estado interno
    self.state = {
        lastParagonScanTime = 0,
        cachedPendingParagons = {},
        playerClassColor = RAID_CLASS_COLORS[select(2, UnitClass("player"))],
        isConfigMode = false,
        inCombat = false,
        isHovering = false 
    }
    
    -- Constantes y Fuente
    self.standardFontPath = GameFontNormal:GetFont() or "Fonts\\FRIZQT__.TTF"
    self.coloredPipe = string.format("|cff%02x%02x%02x | |r",
        self.state.playerClassColor.r * 255, self.state.playerClassColor.g * 255, self.state.playerClassColor.b * 255)

    self:CreateFrames()
end

function AB:OnEnable()
    self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateDisplay")
    self:RegisterEvent("UPDATE_EXHAUSTION", "UpdateDisplay")
    self:RegisterEvent("PLAYER_LEVEL_UP", "UpdateDisplay")
    self:RegisterEvent("UPDATE_FACTION", "HandleFactionUpdate")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "HandleCombatStart")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "HandleCombatEnd")
    self:RegisterEvent("QUEST_TURNED_IN", "HandleQuestTurnIn")
    
    self:HideBlizzardFrames()
    self:UpdateDisplay()
end

-- ==========================================================
-- 4. LÓGICA DE ACTUALIZACIÓN (MANTENIENDO TU ESTRUCTURA)
-- ==========================================================

function AB:UpdateDisplay()
    local profile = self.db.profile
    local isMax = UnitLevel("player") >= GetMaxPlayerLevel()
    
    self:UpdateLayout(isMax)
    self:UpdateVisibility()
    
    -- Lógica de renderizado XP y Reputación...
    -- (Aquí integrarías el resto de tu función UpdateDisplay adaptando 'db' a 'self.db.profile')
end

-- Comandos de chat
function AB:ChatCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(self, "ab", ADDON_NAME, input)
    end
end