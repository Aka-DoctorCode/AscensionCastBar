-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Config/VisualFX.lua
-- Version: @project-version@
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in
-- derivative works without express written permission.
-------------------------------------------------------------------------------


local addonName, addonTable = ...
local AscensionCastBar = addonTable.main or LibStub("AceAddon-3.0"):GetAddon("Ascension Cast Bar")

-- Registry for the Visual FX tab
addonTable.tabs = addonTable.tabs or {}
local VisualFXTab = {}

---Rendering function for the Visual FX tab
---@param layout table layoutModel object
---@param profile table Reference to self.db.profile
function VisualFXTab:Render(layout, profile)
    local defaults = AscensionCastBar.defaults.profile

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: SPARK (La chispa que guía el progreso)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Spark Settings")
    layout:beginSection()
        
        layout:checkbox(nil, "Enable Spark", nil,
            function() return profile.sparkEnabled end,
            function(val)
                profile.sparkEnabled = val
                AscensionCastBar:UpdateSparkSize()
                AscensionCastBar:SelectTab("visualfx")
            end
        )

        if profile.sparkEnabled then
            layout:slider(nil, "Spark Width", 1, 50, 1,
                function() return profile.sparkSize end,
                function(val)
                    profile.sparkSize = val
                    AscensionCastBar:UpdateSparkSize()
                end
            )

            layout:colorPicker(nil, "Spark Color",
                function() return unpack(profile.sparkColor) end,
                function(r, g, b, a)
                    profile.sparkColor = { r, g, b, a }
                    AscensionCastBar:UpdateSparkColors()
                end, nil, true
            )
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: MOTION TAILS (Estelas de brillo)
    -- -------------------------------------------------------------------------------
    layout:header(nil, "Motion Tails")
    layout:beginSection()
        
        layout:checkbox(nil, "Enable Tails", nil,
            function() return profile.tailEnabled end,
            function(val)
                profile.tailEnabled = val
                AscensionCastBar:UpdateTails()
                AscensionCastBar:SelectTab("visualfx")
            end
        )

        if profile.tailEnabled then
            layout:slider(nil, "Global Offset", -20, 20, 1,
                function() return profile.tailOffset end,
                function(val)
                    profile.tailOffset = val
                    AscensionCastBar:UpdateTails()
                end
            )
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIONES DINÁMICAS: Configuración de cada Capa (1 a 4)
    -- -------------------------------------------------------------------------------
    if profile.tailEnabled then
        for i = 1, 4 do
            layout:header(nil, "Tail Layer " .. i)
            layout:beginSection()

                -- Color de la capa
                layout:colorPicker("TailColor_" .. i, "Color",
                    function() return unpack(profile["tail" .. i .. "Color"]) end,
                    function(r, g, b, a)
                        profile["tail" .. i .. "Color"] = { r, g, b, a }
                        AscensionCastBar:UpdateSparkColors()
                    end, nil, true
                )

                -- Longitud de la estela
                layout:slider("TailLength_" .. i, "Length", 10, 500, 5,
                    function() return profile["tail" .. i .. "Length"] end,
                    function(val)
                        profile["tail" .. i .. "Length"] = val
                        AscensionCastBar:UpdateSparkSize()
                    end
                )

                -- Intensidad/Opacidad
                layout:slider("TailIntensity_" .. i, "Intensity", 0, 1, 0.05,
                    function() return profile["tail" .. i .. "Intensity"] end,
                    function(val)
                        profile["tail" .. i .. "Intensity"] = val
                        AscensionCastBar:UpdateSparkColors()
                    end
                )

            layout:endSection()
        end
    end
end

-- Registrar la pestaña
addonTable.tabs["visualfx"] = VisualFXTab