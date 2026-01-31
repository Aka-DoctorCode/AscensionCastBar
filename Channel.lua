-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- File: Channel.lua
-------------------------------------------------------------------------------
local ADDON_NAME = "Ascension Cast Bar"
local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

function AscensionCastBar:ChannelStart(info)
    local cb = self.castBar
    local db = self.db.profile
    
    cb.casting = false
    cb.channeling = true
    cb.isEmpowered = false
    cb.lastSpellName = info.name
    
    cb.startTime = info.startTime / 1000
    cb.duration = (info.endTime - info.startTime) / 1000
    cb.endTime = cb.startTime + cb.duration
    
    cb:Show()
    
    self:SetupCastBarShared(info)
    self:UpdateBarColor(info.notInterruptible)
    self:UpdateTicks(info.spellID, 0, cb.duration)
end

function AscensionCastBar:ChannelUpdate(now, db)
    local cb = self.castBar
    local start = cb.startTime
    local duration = cb.duration
    local endTime = cb.endTime
    
    local rem = endTime - now
    rem = math.max(0, rem)
    local elap = now - start

    cb.timer:SetText(db.hideTimerOnChannel and "" or self:GetFormattedTimer(rem, duration))

    cb:SetMinMaxValues(0, duration)
    
    if db.reverseChanneling then
        cb:SetValue(elap)
        local prog = 0
        if duration > 0 then prog = elap / duration end
        self:UpdateSpark(prog, prog)
    else
        cb:SetValue(rem)
        local prog = 0
        if duration > 0 then prog = rem / duration end
        self:UpdateSpark(prog, 1 - prog)
    end
    
    self:UpdateLatencyBar(cb)
end
