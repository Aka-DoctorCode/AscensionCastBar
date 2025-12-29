-- Constants.lua
local ADDON_NAME = "Ascension Cast Bar"
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

AscensionCastBar.BAR_DEFAULT_FONT_PATH = "Interface\\AddOns\\AscensionCastBar\\COLLEGIA.ttf"

AscensionCastBar.CHANNEL_TICKS = {
    -- Basic Spells
    ["Drain Life"] = 5, ["Drenar vida"] = 5,
    ["Mind Flay"] = 3, ["Tortura mental"] = 3,
    ["Penance"] = 3, ["Penitencia"] = 3,
    ["Arcane Missiles"] = 5, ["Misiles arcanos"] = 5,
    ["Hurricane"] = 10, ["Huracán"] = 10,
    ["Blizzard"] = 8, ["Ventisca"] = 8,
    ["Rain of Fire"] = 8, ["Lluvia de fuego"] = 8,
    ["Evocation"] = 4, ["Evocación"] = 4,
    ["Tranquility"] = 4, ["Tranquilidad"] = 4,
    ["Divine hymn"] = 4, ["Himno divino"] = 4,
    -- Dracthyr / Empowered (Usually have stages)
    ["Fire Breath"] = 4, ["Aliento de fuego"] = 4,
    ["Eternity Surge"] = 4, ["Oleada de eternidad"] = 4,
    ["Dream Breath"] = 4, ["Aliento onírico"] = 4,
    ["Spiritbloom"] = 4, ["Flor de espíritu"] = 4,
    ["Upheaval"] = 4, ["Agitación"] = 4,
}
