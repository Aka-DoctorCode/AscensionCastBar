local AscensionCastBar = LibStub("AceAddon-3.0"):GetAddon("Ascension Cast Bar")
local LSM = LibStub("LibSharedMedia-3.0")

-- ==========================================================
-- ANIMATION UTILITIES
-- ==========================================================

local function ClampAlpha(v)
    v = tonumber(v) or 0
    if v < 0 then v = 0 elseif v > 1 then v = 1 end
    return v
end

-- ==========================================================
-- ANIMATION STYLES DISPATCH
-- ==========================================================

AscensionCastBar.AnimationStyles = {}

function AscensionCastBar.AnimationStyles.Orb(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkGlow:Show()
    local rotSpeed = time * 8
    local radius = db.height * 0.4 
    local function SpinOrb(tex, angleOffset, intense)
        tex:ClearAllPoints()
        local x = math.cos(rotSpeed + angleOffset) * radius
        local y = math.sin(rotSpeed + angleOffset) * radius
        tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", x, y)
        tex:SetAlpha(self:ClampAlpha(intense) * 1.0)
        tex:Show()
    end
    if db.enableTails then
        SpinOrb(castBar.sparkTail, 0, db.tail1Intensity)
        SpinOrb(castBar.sparkTail2, math.pi/2, db.tail2Intensity)
        SpinOrb(castBar.sparkTail3, math.pi, db.tail3Intensity)
        SpinOrb(castBar.sparkTail4, -math.pi/2, db.tail4Intensity)
    end
    local pulse = 0.5 + 0.5 * math.sin(time * 8)
    castBar.sparkGlow:SetAlpha(self:ClampAlpha(db.glowIntensity) * (0.6 + 0.4*pulse))
end

function AscensionCastBar.AnimationStyles.Vortex(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkGlow:Show()
    local radius = db.height * 0.9
    local speed = 8
    local function Orbit(tex, idx, intense)
        tex:ClearAllPoints()
        local angle = (time * speed) + (offset * 0.05) - (idx * 0.8)
        local r = radius * (1 - (idx * 0.2))
        local x = math.cos(angle) * r
        local y = math.sin(angle) * r
        tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", x, y)
        tex:SetSize(db.height * 0.7, db.height * 0.7)
        tex:SetAlpha(self:ClampAlpha(intense) * tailProgress)
        tex:Show()
    end
    if db.enableTails then
        Orbit(castBar.sparkTail, 0, db.tail1Intensity)
        Orbit(castBar.sparkTail2, 1, db.tail2Intensity)
        Orbit(castBar.sparkTail3, 2, db.tail3Intensity)
        Orbit(castBar.sparkTail4, 3, db.tail4Intensity)
    end
end

function AscensionCastBar.AnimationStyles.Pulse(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkGlow:Show()
    local maxScale = 2.5
    local function Ripple(tex, offsetTime, intense)
        tex:ClearAllPoints()
        tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", 0, 0)
        local cycle = (time + offsetTime) % 1
        local size = db.height * 2 * (0.2 + cycle * maxScale) 
        tex:SetSize(size, size)
        local fade = 1 - (cycle * cycle)
        tex:SetAlpha(self:ClampAlpha(intense) * fade)
        tex:Show()
    end
    if db.enableTails then
        Ripple(castBar.sparkTail, 0.0, db.tail1Intensity)
        Ripple(castBar.sparkTail2, 0.3, db.tail2Intensity)
        Ripple(castBar.sparkTail3, 0.6, db.tail3Intensity)
        Ripple(castBar.sparkTail4, 0.9, db.tail4Intensity)
    end
end

function AscensionCastBar.AnimationStyles.Starfall(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkGlow:Hide()
    local h = db.height
    local function Fall(tex, driftBase, speed, intense)
        tex:ClearAllPoints()
        local fallY = -((time * speed * 15) % (h*2.5)) + h
        local sway = math.sin(time * 3 + driftBase) * 8 
        tex:SetPoint("CENTER", castBar.sparkHead, "CENTER", driftBase + sway, fallY)
        tex:SetAlpha(self:ClampAlpha(intense) * (1 - math.abs(fallY)/(h*1.5)))
        tex:Show()
    end
    if db.enableTails then
        Fall(castBar.sparkTail, -10, 2.5, db.tail1Intensity)
        Fall(castBar.sparkTail2, 10, 3.8, db.tail2Intensity)
        Fall(castBar.sparkTail3, -20, 1.5, db.tail3Intensity)
        Fall(castBar.sparkTail4, 20, 3.0, db.tail4Intensity)
    end
end

function AscensionCastBar.AnimationStyles.Flux(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkGlow:Hide() 
    local dm = w * 0.05
    local jitterY = 3.5
    local jitterX = 2.5
    local function Flux(tex, baseOff, drift, intense)
        tex:ClearAllPoints()
        local rY = (math.random() * jitterY * 2) - jitterY
        local rX = (math.random() * jitterX * 2) - jitterX
        local x = math.max(b, math.min(w-b, offset - baseOff + drift + rX))
        tex:SetPoint("CENTER", castBar.tailMask, "LEFT", x, rY)
        tex:SetAlpha(self:ClampAlpha(intense) * tailProgress)
        tex:Show()
    end
    if db.enableTails then
        Flux(castBar.sparkTail, 20, -dm*tailProgress, db.tail1Intensity)
        Flux(castBar.sparkTail2, 35, dm*tailProgress, db.tail2Intensity)
        Flux(castBar.sparkTail3, 20, -dm*tailProgress, db.tail3Intensity)
        Flux(castBar.sparkTail4, 35, dm*tailProgress, db.tail4Intensity)
    end
end

function AscensionCastBar.AnimationStyles.Helix(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkGlow:Show()
    local dm = w * 0.1
    local amp = db.height * 0.4
    local waveSpeed = 8
    local sv = math.sin(time * waveSpeed + (offset * 0.05)) * amp
    local cv = math.cos(time * waveSpeed + (offset * 0.05)) * amp
    local function Helix(tex, baseOff, drift, yOff, intense)
        tex:ClearAllPoints()
        local x = math.max(b, math.min(w-b, offset - baseOff + drift))
        tex:SetPoint("CENTER", castBar.tailMask, "LEFT", x, yOff)
        tex:SetAlpha(self:ClampAlpha(intense) * tailProgress)
        tex:Show()
    end
    if db.enableTails then
        Helix(castBar.sparkTail, 20, -dm*tailProgress, sv, db.tail1Intensity)
        Helix(castBar.sparkTail2, 35, dm*tailProgress, -sv, db.tail2Intensity)
        Helix(castBar.sparkTail3, 25, -dm*tailProgress, cv, db.tail3Intensity)
        Helix(castBar.sparkTail4, 30, dm*tailProgress, -cv, db.tail4Intensity)
    end
end

function AscensionCastBar.AnimationStyles.Wave(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkGlow:Hide()
    castBar.sparkHead:Hide() 
    if not castBar.waveOverlay then
        castBar.waveOverlay = castBar:CreateTexture(nil, "ARTWORK")
        castBar.waveOverlay:SetBlendMode("ADD")
        castBar.waveOverlay:SetAllPoints()
        castBar.waveOverlay:SetGradient("HORIZONTAL", CreateColor(1,1,1,0), CreateColor(1,1,1,0.5), CreateColor(1,1,1,0))
    end
    local wOff = (time * 2.0) % 1
    castBar.waveOverlay:SetTexCoord(wOff, wOff + 1, 0, 1)
    local wH = 5 * math.sin(time * 2) 
    castBar.waveOverlay:ClearAllPoints()
    castBar.waveOverlay:SetPoint("TOPLEFT", castBar, "TOPLEFT", 0, wH)
    castBar.waveOverlay:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 0, wH)
    local wc = db.tail2Color
    castBar.waveOverlay:SetVertexColor(wc[1], wc[2], wc[3], 0.3 * (0.5 + progress * 0.5))
    castBar.waveOverlay:Show()
end

function AscensionCastBar.AnimationStyles.Particles(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkGlow:Show()
    if not castBar.particles then castBar.particles = {} end
    if not castBar.lastParticleTime then castBar.lastParticleTime = 0 end
    if (time - castBar.lastParticleTime) > 0.05 then
        local p = nil
        for _, v in ipairs(castBar.particles) do if not v:IsShown() then p=v; break end end
        if not p then 
        p = castBar.tailMask:CreateTexture(nil, "OVERLAY")
        p:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        p:SetBlendMode("ADD")
        table.insert(castBar.particles, p)
        end
        p.life = 1.0
        p.sx = offset
        p.sy = 0
        p.vx = (math.random()-0.5)*10
        p.vy = 20 + math.random()*30
        p:SetSize(8,8)
        p:Show()
        castBar.lastParticleTime = time
    end
    for _, p in ipairs(castBar.particles) do
        if p:IsShown() then
            p.life = p.life - 0.05
            if p.life <= 0 then 
            p:Hide() 
            else
                p.sx = p.sx + p.vx * 0.05
                p.sy = p.sy + p.vy * 0.05
                p:ClearAllPoints()
                p:SetPoint("CENTER", castBar.tailMask, "LEFT", p.sx, p.sy)
                local pc = db.sparkColor
                p:SetVertexColor(pc[1], pc[2], pc[3], p.life)
            end
        end
    end
end

function AscensionCastBar.AnimationStyles.Scanline(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkHead:Hide()
    castBar.sparkGlow:Hide()
    if not castBar.scanLine then
        castBar.scanLine = castBar:CreateTexture(nil, "OVERLAY")
        castBar.scanLine:SetColorTexture(1, 1, 1, 1)
        castBar.scanLine:SetBlendMode("ADD")
        castBar.scanLine:SetSize(4, db.height)
    end
    local slP = (time % 1.5) / 1.5
    if slP > 0.5 then slP = 1 - slP end
    local slX = w * ((math.sin(time * 3) + 1) / 2)
    castBar.scanLine:ClearAllPoints()
    castBar.scanLine:SetPoint("CENTER", castBar, "LEFT", slX, 0)
    local sc = db.tail1Color
    castBar.scanLine:SetVertexColor(sc[1], sc[2], sc[3], 0.8)
    castBar.scanLine:Show()
end

function AscensionCastBar.AnimationStyles.Glitch(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkHead:Hide()
    if not castBar.glitchLayers then
        castBar.glitchLayers = {}
        for i=1,3 do 
        local g = castBar:CreateTexture(nil,"OVERLAY")
        g:SetColorTexture(1,1,1,0.2)
        g:SetBlendMode("ADD")
        table.insert(castBar.glitchLayers, g) 
    end
    end
    for i, g in ipairs(castBar.glitchLayers) do
        if math.random() < 0.1 then
            local r = math.random()>0.5 and 1 or 0
            local gr = math.random()>0.5 and 1 or 0
            local bl = math.random()>0.5 and 1 or 0
            g:SetVertexColor(r,gr,bl, 0.3)
            g:ClearAllPoints()
            local ox = math.random(-5,5)
            local oy = math.random(-2,2)
            g:SetPoint("TOPLEFT", castBar, "TOPLEFT", ox, oy)
            g:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", ox, oy)
            g:Show()
        else 
        g:Hide() 
    end
    end
end

function AscensionCastBar.AnimationStyles.Lightning(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkGlow:Show()
    if not castBar.lightningSegments then castBar.lightningSegments = {} end
    for i=1, 3 do
        local l = castBar.lightningSegments[i]
        if not l then 
        l = castBar:CreateTexture(nil, "OVERLAY")
        l:SetColorTexture(1,1,1,1)
        l:SetBlendMode("ADD")
        castBar.lightningSegments[i] = l 
        end
        if math.random() < 0.3 then
            local tx = math.random(0, w)
            local ty = math.random(0, db.height)
            local dx = tx - offset
            local dy = ty - (db.height/2)
            local len = math.sqrt(dx*dx + dy*dy)
            local ang = math.atan2(dy, dx)
            l:SetSize(len, 2)
            l:ClearAllPoints()
            l:SetPoint("CENTER", castBar, "LEFT", offset, 0)
            l:SetRotation(ang)
            local lc = db.tail3Color
            l:SetVertexColor(lc[1], lc[2], lc[3], 0.6)
            l:Show()
        else 
        l:Hide() 
    end
    end
end

function AscensionCastBar.AnimationStyles.Rainbow(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkHead:Hide()
    castBar.sparkGlow:Hide()
    if not castBar.rainbowOverlay then
        castBar.rainbowOverlay = castBar:CreateTexture(nil, "ARTWORK")
        castBar.rainbowOverlay:SetBlendMode("ADD")
        castBar.rainbowOverlay:SetAllPoints()
        castBar.rainbowOverlay:SetGradient("HORIZONTAL", CreateColor(1,0,0,1), CreateColor(1,1,0,1), CreateColor(0,1,0,1), CreateColor(0,1,1,1), CreateColor(0,0,1,1), CreateColor(1,0,1,1))
    end
    local ro = (time * 0.5) % 1
    castBar.rainbowOverlay:SetTexCoord(ro, ro+1, 0, 1)
    castBar.rainbowOverlay:SetAlpha(0.3 + progress * 0.7)
    castBar.rainbowOverlay:Show()
end

function AscensionCastBar.AnimationStyles.Comet(self, castBar, db, progress, tailProgress, time, offset, w, b)
    castBar.sparkGlow:Show()
    local function Comet(tex, rel_pos, int)
        tex:ClearAllPoints()
        local trailX = offset - (rel_pos * w) 
        tex:SetPoint("CENTER", castBar.tailMask, "LEFT", math.max(b, math.min(w-b, trailX)), 0)
        tex:SetAlpha(self:ClampAlpha(int)*tailProgress)
        tex:Show()
    end
    if db.enableTails then
        Comet(castBar.sparkTail, 0.05, db.tail1Intensity)
        Comet(castBar.sparkTail2, 0.10, db.tail2Intensity)
        Comet(castBar.sparkTail3, 0.15, db.tail3Intensity)
        Comet(castBar.sparkTail4, 0.20, db.tail4Intensity)
    end
end


-- ==========================================================
-- MAIN ANIMATION FUNCTIONS
-- ==========================================================

function AscensionCastBar:UpdateSparkColors()
    local db = self.db.profile
    local s, g = db.sparkColor, db.glowColor
    self.castBar.sparkHead:SetVertexColor(s[1], s[2], s[3], s[4])
    self.castBar.sparkGlow:SetVertexColor(g[1], g[2], g[3], g[4])
    
    local t1, t2, t3, t4 = db.tail1Color, db.tail2Color, db.tail3Color, db.tail4Color
    self.castBar.sparkTail:SetVertexColor(t1[1],t1[2],t1[3],t1[4])
    self.castBar.sparkTail2:SetVertexColor(t2[1],t2[2],t2[3],t2[4])
    self.castBar.sparkTail3:SetVertexColor(t3[1],t3[2],t3[3],t3[4])
    self.castBar.sparkTail4:SetVertexColor(t4[1],t4[2],t4[3],t4[4])
end

function AscensionCastBar:UpdateSparkSize()
    local db = self.db.profile
    local sc, h = db.sparkScale, db.height
    local cb = self.castBar
    
    cb.sparkHead:SetSize(32*sc, h*2*sc)
    cb.sparkGlow:SetSize(190*sc, h*2.4)
    cb.sparkTail:SetSize(db.tail1Length*sc, h*1.4)
    cb.sparkTail2:SetSize(db.tail2Length*sc, h*1.1)
    cb.sparkTail3:SetSize(db.tail3Length*sc, h*1.4)
    cb.sparkTail4:SetSize(db.tail4Length*sc, h*1.1)
    
    if cb.tailMask then cb.tailMask:SetWidth(cb:GetWidth()) end
end

function AscensionCastBar:ResetParticles()
    if self.castBar.particles then 
        for _, p in ipairs(self.castBar.particles) do p:Hide() end 
    end
    self.castBar.lastParticleTime = 0
end

function AscensionCastBar:UpdateSpark(progress, tailProgress)
    local db = self.db.profile
    local castBar = self.castBar
    
    -- Cleanup overlays
    if castBar.waveOverlay then castBar.waveOverlay:Hide() end
    if castBar.scanLine then castBar.scanLine:Hide() end
    if castBar.rainbowOverlay then castBar.rainbowOverlay:Hide() end
    if castBar.glitchLayers then for _, g in ipairs(castBar.glitchLayers) do g:Hide() end end
    if castBar.lightningSegments then for _, l in ipairs(castBar.lightningSegments) do l:Hide() end end
    if db.animStyle ~= "Particles" and castBar.particles then for _, p in ipairs(castBar.particles) do p:Hide() end end

    if not db.enableSpark or not progress or progress<=0 or progress>=1 then 
        castBar.sparkHead:Hide(); castBar.sparkGlow:Hide()
        castBar.sparkTail:Hide(); castBar.sparkTail2:Hide()
        castBar.sparkTail3:Hide(); castBar.sparkTail4:Hide()
        return 
    end

    local w = castBar:GetWidth()
    local style = db.animStyle
    local offset = w * progress
    local b = db.borderEnabled and db.borderThickness or 0
    local tP = tailProgress or 0
    local time = GetTime()
    
    local effOffset = (db.headLengthOffset) * (w / (270)) 
    castBar.sparkHead:ClearAllPoints()
    castBar.sparkHead:SetPoint("CENTER", castBar, "LEFT", offset + db.sparkOffset + effOffset, 0)
    castBar.sparkHead:SetAlpha(self:ClampAlpha(db.sparkIntensity))
    castBar.sparkHead:Show()
    castBar.sparkGlow:ClearAllPoints()
    castBar.sparkGlow:SetPoint("CENTER", castBar.sparkHead, "CENTER", 0, 0)

    if castBar.tailMask then
        local aw = offset - (b>0 and b or 0)
        if aw < 0 then aw = 0 end
        if aw > w then aw = w end
        castBar.tailMask:SetWidth(aw)
    end

    if not db.enableTails or (style == "Wave" or style == "Scanline" or style == "Rainbow" or style == "Glitch") then
         castBar.sparkTail:Hide(); castBar.sparkTail2:Hide(); castBar.sparkTail3:Hide(); castBar.sparkTail4:Hide()
    end
    
    -- Use Strategy Pattern to call appropriate animation function
    local animFunc = self.AnimationStyles[style]
    if animFunc then
        animFunc(self, castBar, db, progress, tP, time, offset, w, b)
    else
        -- Fallback to Comet if style not found
        self.AnimationStyles.Comet(self, castBar, db, progress, tP, time, offset, w, b)
    end
end
