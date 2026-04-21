# 🧩 Elementos faltantes en la nueva interfaz de configuración (AscensionCastBar)

Este documento detalla las diferencias entre el menú de opciones original (basado en `AceConfig`) y la nueva interfaz modular (`General.lua`, `Appearance.lua`, `Text.lua`, `Mechanics.lua`, `VisualFX.lua`, `Profiles.lua`).

---

## 📁 General & Layout

| Elemento original | Estado en nueva versión | Observaciones |
|-------------------|-------------------------|---------------|
| `manualWidth` stepper con paso `1` | **Modificado** | Ahora tiene paso `5`. No es una pérdida grave, pero cambia la precisión. |

---

## 🎨 Appearance (Style & Colors)

| Elemento original | Estado en nueva versión |
|-------------------|-------------------------|
| Botón **Reset** para `barColor` | ❌ **Ausente** |
| Botón **Reset** para `bgColor` | ❌ **Ausente** |
| Botón **Reset** para `borderColor` | ❌ **Ausente** |

---

## 🔤 Text & Fonts

| Elemento original | Estado en nueva versión |
|-------------------|-------------------------|
| Botón **Reset** para `fontColor` (Spell Name) | ❌ **Ausente** |
| Botón **Reset** para `timerColor` | ❌ **Ausente** |
| Botón **Reset** para `textBackdropColor` | ❌ **Ausente** |

---

## ⚙️ Mechanics

| Elemento original | Estado en nueva versión | Impacto |
|-------------------|-------------------------|---------|
| **Slider `latencyMaxPercent`** | ❌ **Ausente** | 🔴 **Crítico** – Impide limitar el ancho máximo del indicador de latencia. |
| Botón **Reset** para `latencyColor` | ❌ **Ausente** | |
| Botón **Reset** para `channelTicksColor` | ❌ **Ausente** | |
| Botón **Reset** para `channelColor` | ❌ **Ausente** | |
| Botón **Reset** para `empowerStage1Color` | ❌ **Ausente** | |
| Botón **Reset** para `empowerStage2Color` | ❌ **Ausente** | |
| Botón **Reset** para `empowerStage3Color` | ❌ **Ausente** | |
| Botón **Reset** para `empowerStage4Color` | ❌ **Ausente** | |
| Botón **Reset** para `empowerStage5Color` | ❌ **Ausente** | |

> **Nota:** Se han añadido nuevas opciones (`flashInterrupted`, `interruptedColor`, `failedColor`, `successColor`, `showEmpowerStages`) que no existían en el original.

---

## ✨ Visual FX (Animation)

| Elemento original | Estado en nueva versión | Observaciones |
|-------------------|-------------------------|---------------|
| Botón **Reset** para `glowColor` | ❌ **Ausente** | |
| Botón **Reset** para `sparkColor` | ❌ **Ausente** | |
| Botón **Reset** para `tail1Color` | ❌ **Ausente** | |
| Botón **Reset** para `tail2Color` | ❌ **Ausente** | |
| Botón **Reset** para `tail3Color` | ❌ **Ausente** | |
| Botón **Reset** para `tail4Color` | ❌ **Ausente** | |
| Checkbox `enableSpark` | ⚠️ **Renombrado** | Ahora se llama `sparkEnabled`. Puede causar desincronización si el código principal no usa ambos nombres. |
| Slider `Tail Offset (Global)` en sección "Motion Tails" | ⚠️ **Duplicado** | Aparece también dentro de "Global Glow & Offsets". Funcionalidad redundante. |

---

## 👤 Profiles

| Elemento original | Estado en nueva versión |
|-------------------|-------------------------|
| Panel completo de `AceDBOptions-3.0` (copiar, renombrar, borrar, importar/exportar perfiles) | ❌ **Reemplazado por versión básica** |

> **Aclaración:** La nueva pestaña incluye un botón **"Open Advanced Ace3 Profiles"** que abre el panel original de Ace3, por lo que **no hay pérdida real de funcionalidad**, solo un acceso en dos pasos.

---

## 📊 Resumen numérico

| Categoría | Elementos ausentes |
|-----------|-------------------|
| Appearance | 3 botones Reset |
| Text & Fonts | 3 botones Reset |
| Mechanics | 1 slider crítico + 9 botones Reset |
| Visual FX | 6 botones Reset + 1 posible desincronización de variable |
| **Total** | **1 slider crítico + 21 botones Reset** |

---

## 🛠️ Recomendaciones

1. **Añadir el slider `latencyMaxPercent`** en la sección "Latency & Lag" de `Mechanics.lua`.
2. **Implementar botones de Reset individuales** para todos los selectores de color listados.
3. **Unificar el nombre de la variable** `enableSpark` / `sparkEnabled` para evitar conflictos.
4. **Eliminar el slider redundante** "Global Tail Offset" dentro de "Motion Tails".