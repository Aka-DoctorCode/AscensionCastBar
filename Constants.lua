local ADDON_NAME = "Ascension Cast Bar"
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

AscensionCastBar.BAR_DEFAULT_FONT_PATH = "Interface\\AddOns\\AscensionCastBar\\COLLEGIA.ttf"

-- ==========================================================
-- CONDITIONAL TICKS SYSTEM
-- ==========================================================

-- SpellID configuration table
AscensionCastBar.SPELL_TICK_CONFIG = {
    -- Arcane Missiles (has talent that modifies ticks)
    [153626] = {
        baseTicks = 5,
        conditions = {
            {
                type = "TALENT",
                id = 236628,
                modifier = 3,
                operator = "ADD"
            }
        }
    },
}

-- Tabla de respaldo para nombres de hechizos
AscensionCastBar.CHANNEL_TICKS_LEGACY = {
    ["Drain Life"] = 5,
    ["Mind Flay"] = 3,
    ["Ray of Frost"] = 5,
    ["Penance"] = 3,
    ["Hurricane"] = 10,
    ["Blizzard"] = 8,
    ["Rain of Fire"] = 8,
    ["Evocation"] = 4,
    ["Tranquility"] = 4,
    ["Divine hymn"] = 4,
    ["Disintegrate"] = 4,
    ["Fire Breath"] = 4,
    ["Eternity Surge"] = 4,
    ["Dream Breath"] = 4,
    ["Spiritbloom"] = 4,
    ["Upheaval"] = 4,
}

-- Keep the old table for compatibility.
AscensionCastBar.CHANNEL_TICKS = AscensionCastBar.CHANNEL_TICKS_LEGACY

-- ==========================================================
-- FUNCTIONS TO EVALUATE CONDITIONS
-- ==========================================================

-- Main function to calculate ticks with conditions
function AscensionCastBar:CalculateTicks(spellID)
    if not spellID then return 0 end
    
    local config = self.SPELL_TICK_CONFIG[spellID]
    
    -- If there is no configuration, returns 0 (do not show ticks)
    if not config then
        return 0
    end
    
    local tickCount = config.baseTicks
    
    -- Apply all conditions
    if config.conditions and #config.conditions > 0 then
        for _, condition in ipairs(config.conditions) do
            if self:CheckCondition(condition) then
                tickCount = self:ApplyModifier(tickCount, condition)
            end
        end
    end
    
    return tickCount
end

-- Function to verify an individual condition
function AscensionCastBar:CheckCondition(condition)
    if not condition then return false end
    
    if condition.type == "TALENT" then
        -- Verifies if the player has the talent
        return IsPlayerSpell and IsPlayerSpell(condition.id)
        
    elseif condition.type == "SPELL" then
        -- Verifies if the spell is learned
        return IsSpellKnown and IsSpellKnown(condition.id)
        
    elseif condition.type == "BUFF" then
        -- Verifies if the player has the buff
        local name = GetSpellInfo(condition.id)
        if name then
            return UnitAura("player", name) ~= nil
        end
        
    elseif condition.type == "CLASS" then
        -- Verifies the player's class
        local _, playerClass = UnitClass("player")
        return playerClass == condition.value
        
    elseif condition.type == "SPEC" then
        -- Verifies the player's specialization
        local spec = GetSpecialization()
        if spec then
            local specID = GetSpecializationInfo(spec)
            return specID == condition.value
        end
    end
    
    return false
end

-- Function to apply modifier to ticks
function AscensionCastBar:ApplyModifier(baseTicks, condition)
    if condition.operator == "ADD" then
        return baseTicks + (condition.modifier or 0)
        
    elseif condition.operator == "MULTIPLY" then
        return baseTicks * (condition.modifier or 1)
        
    elseif condition.operator == "SET" then
        return condition.modifier or baseTicks
        
    elseif condition.operator == "MAX" then
        return math.max(baseTicks, condition.modifier or 0)
        
    elseif condition.operator == "MIN" then
        return math.min(baseTicks, condition.modifier or 0)
    end
    
    return baseTicks
end

-- Function to debug ticks
function AscensionCastBar:DebugTicks(spellID)
    if not spellID then 
        print("Usage: /acbticks <spellID>")
        return 
    end
    
    local config = self.SPELL_TICK_CONFIG[spellID]
    if not config then
        print(string.format("Spell ID %d: No config found", spellID))
        return
    end
    
    local calculated = self:CalculateTicks(spellID)
    local _, spellName = GetSpellInfo(spellID)
    
    print(string.format("=== ACB TICKS DEBUG: %s (ID: %d) ===", spellName or "Unknown", spellID))
    print(string.format("Base ticks: %d", config.baseTicks))
    
    if config.conditions and #config.conditions > 0 then
        print("Active conditions:")
        for _, cond in ipairs(config.conditions) do
            local hasCondition = self:CheckCondition(cond)
            print(string.format("  - %s ID %d: %s", 
                cond.type, cond.id, hasCondition and "YES" or "NO"))
        end
    else
        print("No conditions")
    end
    
    print(string.format("Final ticks: %d", calculated))
    print("=====================================")
end

-- ==========================================================
-- ANIMATION PARAMETERS (MAINTAIN EXISTING)
-- ==========================================================

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
        tails = 0,
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
        tailCount = 0,
    }
}