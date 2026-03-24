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
    layout:createHeader({ text = "Spark Settings" })
    layout:beginSection()
        
        layout:createToggle({
            text = "Enable Spark",
            get = function() return profile.sparkEnabled end,
            set = function(val)
                profile.sparkEnabled = val
                AscensionCastBar:UpdateSparkSize()
            end
        })

        layout:createSlider({
            text = "Spark Width",
            min = 1, max = 50, step = 1,
            disabled = function() return not profile.sparkEnabled end,
            get = function() return profile.sparkSize end,
            set = function(val)
                profile.sparkSize = val
                AscensionCastBar:UpdateSparkSize()
            end
        })

        layout:createColorPicker({
            text = "Spark Color",
            disabled = function() return not profile.sparkEnabled end,
            get = function() return unpack(profile.sparkColor) end,
            set = function(r, g, b, a)
                profile.sparkColor = { r, g, b, a }
                AscensionCastBar:UpdateSparkColors()
            end,
            onReset = function()
                profile.sparkColor = { unpack(defaults.sparkColor) }
                AscensionCastBar:UpdateSparkColors()
            end
        })
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIÓN: MOTION TAILS (Estelas de brillo)
    -- -------------------------------------------------------------------------------
    layout:createHeader({ text = "Motion Tails" })
    layout:beginSection()
        
        layout:createToggle({
            text = "Enable Tails",
            get = function() return profile.tailEnabled end,
            set = function(val)
                profile.tailEnabled = val
                AscensionCastBar:UpdateTails() -- Asumiendo que esta función refresca el estado
                AscensionCastBar:SelectTab("visualfx")
            end
        })

        if profile.tailEnabled then
            layout:createSlider({
                text = "Global Offset",
                min = -20, max = 20, step = 1,
                get = function() return profile.tailOffset end,
                set = function(val)
                    profile.tailOffset = val
                    AscensionCastBar:UpdateTails()
                end
            })
        end
    layout:endSection()

    -- -------------------------------------------------------------------------------
    -- SECCIONES DINÁMICAS: Configuración de cada Capa (1 a 4)
    -- -------------------------------------------------------------------------------
    if profile.tailEnabled then
        for i = 1, 4 do
            layout:createHeader({ text = "Tail Layer " .. i })
            layout:beginSection()

                -- Color de la capa
                layout:createColorPicker({
                    text = "Color",
                    get = function() return unpack(profile["tail" .. i .. "Color"]) end,
                    set = function(r, g, b, a)
                        profile["tail" .. i .. "Color"] = { r, g, b, a }
                        AscensionCastBar:UpdateSparkColors() -- Usualmente maneja todos los colores de glow
                    end,
                    onReset = function()
                        profile["tail" .. i .. "Color"] = { unpack(defaults["tail" .. i .. "Color"]) }
                        AscensionCastBar:UpdateSparkColors()
                    end
                })

                -- Longitud de la estela
                layout:createSlider({
                    text = "Length",
                    min = 10, max = 500, step = 5,
                    get = function() return profile["tail" .. i .. "Length"] end,
                    set = function(val)
                        profile["tail" .. i .. "Length"] = { val, 1 } -- Manteniendo estructura de tabla si es necesario
                        AscensionCastBar:UpdateSparkSize()
                    end
                })

                -- Intensidad/Opacidad
                layout:createSlider({
                    text = "Intensity",
                    min = 0, max = 1, step = 0.05,
                    get = function() return profile["tail" .. i .. "Intensity"] end,
                    set = function(val)
                        profile["tail" .. i .. "Intensity"] = val
                        AscensionCastBar:UpdateSparkColors()
                    end
                })

            layout:endSection()
        end
    end
end

-- Registrar la pestaña
addonTable.tabs["visualfx"] = VisualFXTab