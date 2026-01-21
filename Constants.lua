-- Constants.lua
local ADDON_NAME = "Ascension Cast Bar"
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

AscensionCastBar.BAR_DEFAULT_FONT_PATH = "Interface\\AddOns\\AscensionCastBar\\COLLEGIA.ttf"

AscensionCastBar.CHANNEL_TICKS = {
    -- Basic Spells
    ["Drain Life"] = 5,
    ["Drenar vida"] = 5,
    ["Mind Flay"] = 3,
    ["Tortura mental"] = 3,
    ["Penance"] = 3,
    ["Penitencia"] = 3,
    ["Arcane Missiles"] = 5,
    ["Misiles arcanos"] = 5,
    ["Hurricane"] = 10,
    ["Huracán"] = 10,
    ["Blizzard"] = 8,
    ["Ventisca"] = 8,
    ["Rain of Fire"] = 8,
    ["Lluvia de fuego"] = 8,
    ["Evocation"] = 4,
    ["Evocación"] = 4,
    ["Tranquility"] = 4,
    ["Tranquilidad"] = 4,
    ["Divine hymn"] = 4,
    ["Himno divino"] = 4,
    ["Disintegrate"] = 4,
    ["Desintegrar"] = 4,
    -- Dracthyr / Empowered (Usually have stages)
    ["Fire Breath"] = 4,
    ["Aliento de fuego"] = 4,
    ["Eternity Surge"] = 4,
    ["Oleada de eternidad"] = 4,
    ["Dream Breath"] = 4,
    ["Aliento onírico"] = 4,
    ["Spiritbloom"] = 4,
    ["Flor de espíritu"] = 4,
    ["Upheaval"] = 4,
    ["Agitación"] = 4,
    ["Void Torrent"] = 4,
    ["Torrente del vacío"] = 4,
}

AscensionCastBar.ANIMATION_STYLE_PARAMS = {
    Comet = {
        tailOffset = -14.68,
        headLengthOffset = -23,
        tailLength = 200,
        tails = 4,
    },
    Orb = {
        rotationSpeed = 8,
        radiusMultiplier = 0.4,
        glowPulse = 1.0,
        tails = 4,
    },
    Pulse = {
        maxScale = 2.5,
        rippleCycle = 1,
        fadeSpeed = 1.0,
        tails = 4,
    },
    Starfall = {
        fallSpeed = 2.5,
        swayAmount = 8,
        particleSpeed = 3.8,
        tails = 4,
    },
    Flux = {
        jitterY = 3.5,
        jitterX = 2.5,
        driftMultiplier = 0.05,
        tails = 4,
    },
    Helix = {
        driftMultiplier = 0.1,
        amplitude = 0.4,
        waveSpeed = 8,
        tails = 4,
    },
    Wave = {
        waveCount = 3,
        waveSpeed = 0.4,
        amplitude = 0.05,
        waveWidth = 0.25,
        tails = 0, -- Wave no usa tails tradicionales
    },
    Glitch = {
        glitchChance = 0.1,
        maxOffset = 5,
        colorIntensity = 0.3,
        tails = 0,
    },
    Lightning = {
        lightningChance = 0.3,
        segmentCount = 3,
        tailCount = 0, -- Usa segments en lugar de tails
    }
}
