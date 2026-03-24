-------------------------------------------------------------------------------
-- Project: AscensionCastBar
-- Author: Aka-DoctorCode
-- File: Config/UIFactory.lua
-- Version: @project-version@
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in
-- derivative works without express written permission.
-------------------------------------------------------------------------------


local addonName, addonTable = ...
---@type AscensionCastBar
local AscensionCastBar = addonTable.main or LibStub("AceAddon-3.0"):GetAddon("Ascension Cast Bar")
---@cast AscensionCastBar AscensionCastBar

local colors = AscensionCastBar.colors or {}
local files = AscensionCastBar.files or {}
local menuStyle = AscensionCastBar.menuStyle or {}

-- Internal table for raw UI creation functions
local elements = {}

-- Helper function to fetch specific element overrides
local function getStyle(elementID)
    if not AscensionCastBar.db or not AscensionCastBar.db.profile then return {} end
    return AscensionCastBar.db.profile.elementStyles and AscensionCastBar.db.profile.elementStyles[elementID] or {}
end

function elements:createHeader(args)
    local elementID, parent, text, yOffset = args.elementID, args.parent, args.text, args.yOffset
        AscensionCastBar.registeredElements = AscensionCastBar.registeredElements or {}
    AscensionCastBar.registeredElements[elementID] = "Header"
    local style = getStyle(elementID)
    local headerColor = style.uiHeaderColor or menuStyle.uiHeaderColor or colors.gold or {1, 0.8, 0.2, 1}
    local leftPadding = style.contentPadding or menuStyle.contentPadding or 16
    local header = parent:CreateFontString(nil, "OVERLAY", menuStyle.headerFont or "GameFontNormal")
        header.elementID = elementID
        header:SetPoint("TOPLEFT", leftPadding, yOffset)
        header:SetText(text)
        header:SetTextColor(unpack(headerColor))
    local headerHeight = header:GetStringHeight()
    local spacingAfter = 8
    local nextY = yOffset - headerHeight - spacingAfter

    return header, nextY
end

function elements:createLabel(args)
    local elementID, parent, text, yOffset, xOffset = args.elementID, args.parent, args.text, args.yOffset, args.xOffset
    local anchorFrame = args.anchorFrame
    local color = args.color -- Fetch the custom color
    AscensionCastBar.registeredElements = AscensionCastBar.registeredElements or {}
    AscensionCastBar.registeredElements[elementID] = "Label"
    
    local style = getStyle(elementID)
    local textColor = color or style.textLight or colors.textLight or {0.886, 0.909, 0.941, 1} -- Apply custom color or fallback #E2E8F0
    local labelSpacing = style.labelSpacing or menuStyle.labelSpacing or 16
    local actualX = xOffset or style.contentPadding or menuStyle.contentPadding or 16

    local label = parent:CreateFontString(nil, "OVERLAY", menuStyle.labelFont or "GameFontNormal")
    label.elementID = elementID
    label:SetPoint("TOPLEFT", anchorFrame or parent, "TOPLEFT", actualX, yOffset)
    label:SetText(text)
    label:SetTextColor(unpack(textColor or {0.886, 0.909, 0.941, 1}))

    return label, yOffset - labelSpacing
end

function elements:createCheckbox(args)
    local elementID, parent, text, tooltip = args.elementID, args.parent, args.text, args.tooltip
    local getter, setter, yOffset, xOffset = args.getter, args.setter, args.yOffset, args.xOffset
    
    AscensionCastBar.registeredElements = AscensionCastBar.registeredElements or {}
    AscensionCastBar.registeredElements[elementID] = "Checkbox"
    
    local style = getStyle(elementID)
    local actualParent = parent or menuStyle.contentPanel
    local checkboxSize = style.checkboxSize or menuStyle.checkboxSize or 24
    local checkboxSpacing = style.checkboxSpacing or menuStyle.checkboxSpacing or 24
    local labelColor = style.textColor or colors.textLight or {0.886, 0.909, 0.941, 1} -- #E2E8F0

    local checkbox = CreateFrame("CheckButton", nil, actualParent, "UICheckButtonTemplate")
    checkbox.elementID = elementID
    checkbox:SetSize(checkboxSize, checkboxSize)
    local actualX = xOffset or style.contentPadding or 16
    checkbox:SetPoint("TOPLEFT", actualParent, "TOPLEFT", actualX, yOffset or -16)

    local label = checkbox.Text
    -- Upgrade checkbox text font to match the UI style
    label:SetFontObject(menuStyle.labelFont or "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
    label:SetText(text or "")
    label:SetTextColor(unpack(labelColor or {0.886, 0.909, 0.941, 1}))

    if getter then checkbox:SetChecked(getter()) end

    checkbox:SetScript("OnClick", function(self)
        if setter then setter(self:GetChecked()) end
    end)

    if tooltip then
        checkbox:SetScript("OnEnter", function(self)
            local tooltipFrame = _G.GameTooltip
            tooltipFrame:SetOwner(self, "ANCHOR_RIGHT")
            tooltipFrame:SetText(text or "", 1, 1, 1) -- #FFFFFF
            tooltipFrame:AddLine(tooltip, 1, 0.82, 0, true) -- #FFD100
            tooltipFrame:Show()
        end)
        checkbox:SetScript("OnLeave", _G["GameTooltip_Hide"])
    end

    return checkbox, yOffset - checkboxSpacing
end

function elements:createSlider(args)
    local elementID, parent, text, minVal, maxVal = args.elementID, args.parent, args.text, args.minVal, args.maxVal
    local step, getter, setter = args.step or 1, args.getter, args.setter
    local width, yOffset, xOffset = args.width or menuStyle.sliderWidth or 160, args.yOffset, args.xOffset
    
    AscensionCastBar.registeredElements = AscensionCastBar.registeredElements or {}
    AscensionCastBar.registeredElements[elementID] = "Slider"
    
    local style = getStyle(elementID)
    local actualX = xOffset or style.contentPadding or menuStyle.contentPadding or 16

    local sliderName = "AscensionCastBarSlider_" .. tostring(math.random(1000000, 9999999))
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", actualX, yOffset - 16)
    slider:SetWidth(width)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local val = getter() or minVal

    slider.text = slider:CreateFontString(nil, "OVERLAY", menuStyle.labelFont or "GameFontNormal")
    slider.text:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)
    slider.text:SetText(text)
    slider.text:SetTextColor(unpack(colors.textDim or {0.6, 0.6, 0.6, 1}))

    -- Upgrade Low and High text fonts to match the UI style
    local lowText = _G[sliderName .. "Low"]
    if lowText then
        lowText:SetFontObject(menuStyle.labelFont or "GameFontNormal")
        lowText:SetText(minVal)
        lowText:SetTextColor(unpack(colors.textDim or {0.6, 0.6, 0.6, 1}))
    end

    local highText = _G[sliderName .. "High"]
    if highText then
        highText:SetFontObject(menuStyle.labelFont or "GameFontNormal")
        highText:SetText(maxVal)
        highText:SetTextColor(unpack(colors.textDim or {0.6, 0.6, 0.6, 1}))
    end

    slider:SetValue(val)

    -- Función auxiliar para actualizar valor desde los controles
    local function updateValue(inputValue)
        local numericValue = tonumber(inputValue)
        if numericValue then
            numericValue = math.max(minVal, math.min(maxVal, numericValue))
            slider:SetValue(numericValue)
            setter(numericValue)
        end
    end

    -- ============================================
    -- CONTROLES VERTICALES (debajo del slider)
    -- ============================================
    local btnSize = menuStyle.editBoxHeight or 28

    -- Frame contenedor para los controles
    local controlsFrame = CreateFrame("Frame", nil, parent)
    controlsFrame:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -8)  -- 8 píxeles debajo del slider
    controlsFrame:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -8)
    controlsFrame:SetHeight(btnSize + 10)

    -- Caja de edición (centrada en el contenedor)
    local editBox = CreateFrame("EditBox", nil, controlsFrame, "InputBoxTemplate")
    editBox:SetSize(btnSize + 20, btnSize + 20)
    editBox:SetPoint("CENTER", controlsFrame, "CENTER", 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetJustifyH("CENTER")
    editBox:SetFontObject(menuStyle.labelFont or "GameFontNormal")
    editBox:SetText(tostring(math.floor(val * 100) / 100))

    editBox:SetScript("OnEnterPressed", function(self)
        updateValue(self:GetText())
        self:ClearFocus()
    end)

    -- Botón "-" a la izquierda de la caja
    local btnMinus = CreateFrame("Button", nil, controlsFrame, "UIPanelButtonTemplate")
    btnMinus:SetSize(btnSize, btnSize)
    btnMinus:SetText("-")
    local minusFont = btnMinus:GetFontString()
    if minusFont then
        minusFont:SetFontObject(menuStyle.labelFont or "GameFontNormal")
    end
    btnMinus:SetPoint("RIGHT", editBox, "LEFT", -12, 0)
    btnMinus:SetScript("OnClick", function() updateValue(slider:GetValue() - step) end)

    -- Botón "+" a la derecha de la caja
    local btnPlus = CreateFrame("Button", nil, controlsFrame, "UIPanelButtonTemplate")
    btnPlus:SetSize(btnSize, btnSize)
    btnPlus:SetText("+")
    local plusFont = btnPlus:GetFontString()
    if plusFont then
        plusFont:SetFontObject(menuStyle.labelFont or "GameFontNormal")
    end
    btnPlus:SetPoint("LEFT", editBox, "RIGHT", 12, 0)
    btnPlus:SetScript("OnClick", function() updateValue(slider:GetValue() + step) end)

    -- Actualizar la caja cuando el slider cambie (por arrastre)
    slider:SetScript("OnValueChanged", function(_, value)
        editBox:SetText(tostring(math.floor(value * 100) / 100))
        setter(value)
    end)

    -- Calcular la coordenada Y para el siguiente elemento
    local sliderHeight = slider:GetHeight()  -- Altura real del slider
    local controlsHeight = controlsFrame:GetHeight()
    local gap = 4      -- Espacio entre slider y controles
    local margin = 36   -- Margen adicional debajo de los controles
    local totalDescent = sliderHeight + gap + controlsHeight + margin

    local nextY = yOffset - totalDescent

    return slider, nextY
end

function elements:createStepper(args)
    local elementID, parent, text, minVal, maxVal = args.elementID, args.parent, args.text, args.minVal, args.maxVal
    local step, getter, setter = args.step or 1, args.getter, args.setter
    local width, yOffset, xOffset = args.width or 120, args.yOffset, args.xOffset
    
    AscensionCastBar.registeredElements = AscensionCastBar.registeredElements or {}
    AscensionCastBar.registeredElements[elementID] = "Stepper"
    
    local style = getStyle(elementID)
    local actualX = xOffset or style.contentPadding or menuStyle.contentPadding or 16

    local val = getter() or minVal

    -- Label text
    local labelString = parent:CreateFontString(nil, "OVERLAY", menuStyle.labelFont or "GameFontNormal")
    labelString:SetPoint("TOPLEFT", actualX, yOffset)
    labelString:SetText(text)
    labelString:SetTextColor(unpack(colors.textDim or {0.6, 0.6, 0.6, 1}))

    -- Helper function to update value
    local function updateValue(editBox, inputValue)
        local numericValue = tonumber(inputValue)
        if numericValue then
            numericValue = math.max(minVal, math.min(maxVal, numericValue))
            editBox:SetText(tostring(math.floor(numericValue * 100) / 100))
            setter(numericValue)
        else
            -- revert to old value
            editBox:SetText(tostring(math.floor(getter() * 100) / 100))
        end
    end

    local btnSize = menuStyle.editBoxHeight or 28

    local controlsFrame = CreateFrame("Frame", nil, parent)
    -- Align frame directly below the label
    controlsFrame:SetPoint("TOPLEFT", labelString, "BOTTOMLEFT", 0, -8)
    controlsFrame:SetSize(width, btnSize)

    -- Edit Box (Centered in its space)
    local editBox = CreateFrame("EditBox", nil, controlsFrame, "InputBoxTemplate")
    editBox:SetSize(btnSize + 20, btnSize + 10)
    editBox:SetPoint("CENTER", controlsFrame, "CENTER", 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetJustifyH("CENTER")
    editBox:SetFontObject(menuStyle.labelFont or "GameFontNormal")
    editBox:SetText(tostring(math.floor(val * 100) / 100))

    editBox:SetScript("OnEnterPressed", function(self)
        updateValue(self, self:GetText())
        self:ClearFocus()
    end)

    -- Minus Button
    local btnMinus = CreateFrame("Button", nil, controlsFrame, "UIPanelButtonTemplate")
    btnMinus:SetSize(btnSize, btnSize)
    btnMinus:SetText("-")
    local minusFont = btnMinus:GetFontString()
    if minusFont then minusFont:SetFontObject(menuStyle.labelFont or "GameFontNormal") end
    btnMinus:SetPoint("RIGHT", editBox, "LEFT", -8, 0)
    btnMinus:SetScript("OnClick", function() updateValue(editBox, getter() - step) end)

    -- Plus Button
    local btnPlus = CreateFrame("Button", nil, controlsFrame, "UIPanelButtonTemplate")
    btnPlus:SetSize(btnSize, btnSize)
    btnPlus:SetText("+")
    local plusFont = btnPlus:GetFontString()
    if plusFont then plusFont:SetFontObject(menuStyle.labelFont or "GameFontNormal") end
    btnPlus:SetPoint("LEFT", editBox, "RIGHT", 8, 0)
    btnPlus:SetScript("OnClick", function() updateValue(editBox, getter() + step) end)

    local labelHeight = labelString:GetHeight() or 14
    local totalDescent = labelHeight + 8 + btnSize + 16

    return controlsFrame, yOffset - totalDescent
end

function elements:createColorPicker(args)
    local elementID, parent, text, getter = args.elementID, args.parent, args.text, args.getter
    local setter, yOffset, xOffset, hasAlpha = args.setter, args.yOffset, args.xOffset, args.hasAlpha
    
    AscensionCastBar.registeredElements = AscensionCastBar.registeredElements or {}
    AscensionCastBar.registeredElements[elementID] = "ColorPicker"
    
    local style = getStyle(elementID)
    -- Reduce the left padding by 4 pixels for better optical alignment
    local basePadding = xOffset or style.contentPadding or menuStyle.contentPadding or 16
    local actualX = basePadding - 4
    
    local pickerSize = style.colorPickerSize or menuStyle.colorPickerSize or 20
    local pickerSpacing = style.colorPickerSpacing or menuStyle.colorPickerSpacing or 24
    
    local button = CreateFrame("Button", nil, parent)
    button.elementID = elementID
    button:SetSize(pickerSize, pickerSize)
    button:SetPoint("TOPLEFT", actualX, yOffset)

    local texture = button:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    
    local r, g, b, a = getter()
    if type(r) == "table" then
        texture:SetColorTexture(unpack(r))
    else
        texture:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
    end

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", -1, 1)
    background:SetPoint("BOTTOMRIGHT", 1, -1)
    background:SetColorTexture(1, 1, 1, 1) -- #FFFFFF

    local label = button:CreateFontString(nil, "OVERLAY", menuStyle.labelFont or "GameFontNormal")
    label:SetPoint("LEFT", button, "RIGHT", 10, 0)
    label:SetText(text)

    -- Reset Button (Small 'half width' style mentioned in the plan)
    if args.onReset then
        local resetBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        resetBtn:SetSize(16, 16)
        resetBtn:SetPoint("LEFT", label, "RIGHT", 8, 0)
        resetBtn:SetText("R") -- 'R' for Reset
        local resetFont = resetBtn:GetFontString()
        if resetFont then 
            local fontName = type(menuStyle.labelFont) == "string" and menuStyle.labelFont or "GameFontNormal"
            local fontObj = _G[fontName]
            local fontPath = fontObj and fontObj:GetFont() or "Fonts\\FRIZQT__.TTF"
            resetFont:SetFont(fontPath, 10, "OUTLINE") 
        end
        
        resetBtn:SetScript("OnClick", function()
            args.onReset()
            local r, g, b, a = getter()
            if type(r) == "table" then
                texture:SetColorTexture(unpack(r))
            else
                texture:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
            end
        end)
        
        resetBtn:SetScript("OnEnter", function(self)
            local tooltipFrame = _G.GameTooltip
            tooltipFrame:SetOwner(self, "ANCHOR_RIGHT")
            tooltipFrame:SetText("Reset to Default", 1, 1, 1)
            tooltipFrame:Show()
        end)
        resetBtn:SetScript("OnLeave", _G["GameTooltip_Hide"])
    end

    local function colorCallback(restore)
        local colorPicker = _G["ColorPickerFrame"]
        local r, g, b, a
        if restore then
            r, g, b, a = unpack(restore)
        else
            if colorPicker.GetColorRGB then
                r, g, b = colorPicker:GetColorRGB()
            end
            a = (colorPicker.GetColorAlpha and colorPicker:GetColorAlpha()) or
                (colorPicker.GetColorOpacity and 1 - colorPicker:GetColorOpacity()) or 1
        end
        local finalAlpha = a or 1
        setter(r or 1, g or 1, b or 1, finalAlpha)
        button.tex:SetColorTexture(r or 1, g or 1, b or 1, finalAlpha)
    end

    button:SetScript("OnClick", function()
        local colorPicker = _G["ColorPickerFrame"]
        local r, g, b, a = getter()
        local currentAlpha = a or 1
        local info = {
            swatchFunc = function() colorCallback() end,
            opacityFunc = function() colorCallback() end,
            cancelFunc = function() colorCallback({ r or 1, g or 1, b or 1, currentAlpha }) end,
            hasOpacity = hasAlpha,
            opacity = currentAlpha,
            r = r or 1, g = g or 1, b = b or 1
        }

        if colorPicker.SetupColorPickerAndShow then
            colorPicker:SetupColorPickerAndShow(info)
        else
            colorPicker.func = info.swatchFunc
            colorPicker.opacityFunc = info.opacityFunc
            colorPicker.cancelFunc = info.cancelFunc
            colorPicker.hasOpacity = info.hasOpacity
            colorPicker.opacity = info.opacity
            if colorPicker.SetColorRGB then colorPicker:SetColorRGB(info.r, info.g, info.b) end
            colorPicker:Show()
        end
    end)
    return button, yOffset - pickerSpacing
end

function elements:createDropdown(args)
    local elementID, parent, text, options = args.elementID, args.parent, args.text, args.options
    local getter, setter, width, yOffset, xOffset = args.getter, args.setter, args.width, args.yOffset, args.xOffset
    
    AscensionCastBar.registeredElements = AscensionCastBar.registeredElements or {}
    AscensionCastBar.registeredElements[elementID] = "Dropdown"
    
    local style = getStyle(elementID)
    local actualX = xOffset or style.contentPadding or menuStyle.contentPadding or 16
    local dropWidth = width or style.dropdownWidth or menuStyle.dropdownWidth or 140
    local dropHeight = style.dropdownHeight or menuStyle.dropdownHeight or 44

    local frame = CreateFrame("Frame", nil, parent)
    frame.elementID = elementID
    frame:SetSize(dropWidth, dropHeight)
    frame:SetPoint("TOPLEFT", actualX, yOffset)

    local label = frame:CreateFontString(nil, "OVERLAY", menuStyle.labelFont or "GameFontNormal")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(text)
    label:SetTextColor(unpack(colors.textLight or {0.886, 0.909, 0.941, 1})) -- #E2E8F0

    local dropdown = CreateFrame("Button", nil, frame, "BackdropTemplate")
    dropdown:SetSize(dropWidth, 24)
    dropdown:SetPoint("BOTTOMLEFT", 0, 0)
    dropdown:SetBackdrop({
        bgFile = files.bgFile,
        edgeFile = files.edgeFile,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    dropdown:SetBackdropColor(unpack(colors.surfaceHighlight or {0.164, 0.141, 0.239, 1})) -- #2A243D
    dropdown:SetBackdropBorderColor(unpack(colors.blackDetail or {0, 0, 0, 1})) -- #000000

    local dropdownText = dropdown:CreateFontString(nil, "OVERLAY", menuStyle.labelFont or "GameFontNormal")
    dropdownText:SetPoint("LEFT", 10, 0)
    dropdownText:SetPoint("RIGHT", -20, 0)
    dropdownText:SetJustifyH("LEFT")

    -- Support both values (string array) and options (table array)
    local items = args.options or args.values or {}
    local function getItem(idx)
        local raw = items[idx]
        if type(raw) == "string" then
            return { label = raw, value = raw }
        else
            return raw
        end
    end

    local function getLabel(val)
        for i = 1, #items do
            local item = getItem(i)
            if item and item.value == val then return item.label end
        end
        return tostring(val)
    end
    dropdownText:SetText(getLabel(getter()))

    local arrow = dropdown:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(20, 20)
    arrow:SetPoint("RIGHT", -5, 0)
    arrow:SetTexture(files.arrow)
    arrow:SetDesaturated(true)

    local list = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    list:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    list:SetWidth(dropWidth)
    list:SetFrameStrata("TOOLTIP")
    list:Hide()
    list:SetBackdrop({
        bgFile = files.bgFile,
        edgeFile = files.edgeFile,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    list:SetBackdropColor(unpack(colors.surfaceDark or {0.047, 0.039, 0.082, 1})) -- #0C0A15
    list:SetBackdropBorderColor(unpack(colors.surfaceHighlight or {0.164, 0.141, 0.239, 1})) -- #2A243D

    dropdown:SetScript("OnClick", function()
        if list:IsShown() then list:Hide() else list:Show() end
    end)

    local itemCount = #items
    list:SetHeight(itemCount * 20 + 10)

    for i = 1, itemCount do
        local opt = getItem(i)
        if not opt then break end -- Ensure opt exists
        local btn = CreateFrame("Button", nil, list, "BackdropTemplate")
        btn:SetSize(dropWidth - 10, 20)
        btn:SetPoint("TOPLEFT", 5, -5 - ((i - 1) * 20))
        btn:SetBackdrop({ bgFile = files.bgFile })
        btn:SetBackdropColor(unpack(colors.surfaceDark or {0.047, 0.039, 0.082, 1})) -- #0C0A15

        local btnText = btn:CreateFontString(nil, "OVERLAY", menuStyle.labelFont or "GameFontNormal")
        btnText:SetPoint("LEFT", 5, 0)
        btnText:SetText(opt.label)

        btn:SetScript("OnEnter", function(self) self:SetBackdropColor(unpack(colors.surfaceHighlight or {0.164, 0.141, 0.239, 1})) end)
        btn:SetScript("OnLeave", function(self) self:SetBackdropColor(unpack(colors.surfaceDark or {0.047, 0.039, 0.082, 1})) end)
        btn:SetScript("OnClick", function()
            setter(opt.value)
            dropdownText:SetText(opt.label)
            list:Hide()
        end)
    end

    return frame, yOffset - ((menuStyle.dropdownHeight or 44) + 16)
end

function elements:createScrollPanel(args)
    local elementID, parent = args.elementID, args.parent
        AscensionCastBar.registeredElements = AscensionCastBar.registeredElements or {}
        AscensionCastBar.registeredElements[elementID] = "ScrollPanel"
    
    local scrollName = "AscensionCastBarScrollPanel_" .. tostring(math.random(1000000, 9999999))
    local scrollFrame = CreateFrame("ScrollFrame", scrollName, parent, "UIPanelScrollFrameTemplate")
    scrollFrame.elementID = elementID
    
    -- Anchor to all corners of the parent. 
    -- We leave a 25px margin on the right to accommodate the native vertical scrollbar.
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -15, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    
    -- Set an initial safe size. The height will be dynamically overridden by your build() functions.
    local initialWidth = scrollFrame:GetWidth()
    if initialWidth == 0 then initialWidth = 600 end
    content:SetSize(initialWidth, 1) 
    
    scrollFrame:SetScrollChild(content)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame.ScrollBar = _G[scrollName .. "ScrollBar"]

    -- Make the content canvas responsive to main frame resizing
    scrollFrame:SetScript("OnSizeChanged", function(self, width)
        if content and width and width > 0 then
            content:SetWidth(width)
        end
    end)

    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local bar = self.ScrollBar
        if not bar then return end
        local minVal, maxVal = bar:GetMinMaxValues()
        local currentVal = bar:GetValue()
        local newVal = currentVal - delta * 50
        if newVal < minVal then newVal = minVal end
        if newVal > maxVal then newVal = maxVal end
        bar:SetValue(newVal)
    end)
    
    local scrollBar = scrollFrame.ScrollBar
    if scrollBar then
        if scrollBar.ScrollUpButton then scrollBar.ScrollUpButton:SetAlpha(0.7) end
        if scrollBar.ScrollDownButton then scrollBar.ScrollDownButton:SetAlpha(0.7) end
        
        local thumb = scrollBar:GetThumbTexture()
        if thumb then
            local r, g, b = unpack(colors.surfaceHighlight or {0.164, 0.141, 0.239, 1})
            thumb:SetVertexColor(r, g, b, 0.8)
        end
        
        local regions = { scrollBar:GetRegions() }
        for _, region in ipairs(regions) do
            if region:IsObjectType("Texture") and region ~= thumb then
                region:SetAlpha(0)
            end
        end
    end

    return scrollFrame, content
end

function elements:createInput(args)
    local elementID, parent, text = args.elementID, args.parent, args.text
    local onEnterPressed, width, yOffset, xOffset = args.onEnterPressed, args.width, args.yOffset, args.xOffset
    
    AscensionCastBar.registeredElements = AscensionCastBar.registeredElements or {}
    AscensionCastBar.registeredElements[elementID] = "Input"
    
    local style = getStyle(elementID)
    local actualX = xOffset or style.contentPadding or menuStyle.contentPadding or 16
    local actualWidth = width or 200

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(actualWidth, 40)
    frame:SetPoint("TOPLEFT", actualX, yOffset)

    local label = frame:CreateFontString(nil, "OVERLAY", menuStyle.labelFont or "GameFontNormal")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(text)
    label:SetTextColor(unpack(colors.textLight or {0.886, 0.909, 0.941, 1}))

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editBox:SetSize(actualWidth, 20)
    editBox:SetPoint("BOTTOMLEFT", 6, 0)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(menuStyle.labelFont or "GameFontNormal")

    editBox:SetScript("OnEnterPressed", function(self)
        if onEnterPressed then onEnterPressed(self:GetText()) end
        self:ClearFocus()
    end)

    return frame, yOffset - 50
end

function elements:createButton(args)
    local elementID, parent, text, onClick = args.elementID, args.parent, args.text, args.onClick
    local width, height, yOffset, xOffset = args.width, args.height, args.yOffset, args.xOffset
    
    AscensionCastBar.registeredElements = AscensionCastBar.registeredElements or {}
    AscensionCastBar.registeredElements[elementID] = "Button"
    
    local style = getStyle(elementID)
    local actualX = xOffset or style.contentPadding or menuStyle.contentPadding or 16
    local actualWidth = width or 120
    local actualHeight = height or 28

    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(actualWidth, actualHeight)
    btn:SetPoint("TOPLEFT", actualX, yOffset)
    btn:SetText(text)

    local btnFont = btn:GetFontString()
    if btnFont then btnFont:SetFontObject(menuStyle.labelFont or "GameFontNormal") end

    btn:SetScript("OnClick", function()
        if onClick then onClick() end
    end)

    return btn, yOffset - (actualHeight + 10)
end

function elements:createTabbedInterface(parent, tabNames, buildFuncs, initialIndex)
    local tabs = {}
    local panels = {}
    local activeTab = initialIndex or 1

    local sidebarSeparator = parent:CreateTexture(nil, "ARTWORK")
    sidebarSeparator:SetWidth(1)
    sidebarSeparator:SetPoint("TOPLEFT", menuStyle.sidebarWidth or 200, -45)
    sidebarSeparator:SetPoint("BOTTOMLEFT", menuStyle.sidebarWidth or 200, 75)
    sidebarSeparator:SetColorTexture(unpack(colors.surfaceHighlight or {0.164, 0.141, 0.239, 1})) -- #2A243D

    local function selectTab(index)
        activeTab = index
        AscensionCastBar.activeTab = index
        for i, tab in ipairs(tabs) do
            if i == index then
                tab:SetBackdropColor(unpack(colors.sidebarActive or {0.047, 0.039, 0.082, 1}))
                tab.accent:Show()
            else
                tab:SetBackdropColor(0, 0, 0, 0)
                tab.accent:Hide()
            end
        end
        for i, panel in ipairs(panels) do
            if i == index then
                panel:Show()
                _G.C_Timer.After(0.01, function()
                    if panel.updateLayout then panel.updateLayout(panel) end
                end)
            else
                panel:Hide()
            end
        end
    end

    local function createTabButton(label, idx)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        local xOffset = ((menuStyle.sidebarWidth or 200) - (menuStyle.tabWidth or 180)) / 2
        local yOffset = -56 - ((idx - 1) * ((menuStyle.tabHeight or 32) + (menuStyle.tabSpacing or 4)))
        
        btn:SetSize(menuStyle.tabWidth or 180, menuStyle.tabHeight or 32)
        btn:SetPoint("TOPLEFT", xOffset, yOffset)
        
        local accent = btn:CreateTexture(nil, "OVERLAY")
        accent:SetWidth(menuStyle.sidebarAccentWidth or 4)
        accent:SetPoint("TOPLEFT", -xOffset, 0)
        accent:SetPoint("BOTTOMLEFT", -xOffset, 0)
        accent:SetColorTexture(unpack(colors.primary or {1, 0.82, 0, 1})) -- #FFD100
        accent:Hide()
        btn.accent = accent
        
        btn:SetBackdrop({
            bgFile = files.bgFile,
            edgeFile = files.edgeFile,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        btn:SetBackdropColor(0, 0, 0, 0)
        btn:SetBackdropBorderColor(0, 0, 0, 0)

        local text = btn:CreateFontString(nil, "OVERLAY", menuStyle.labelFont)
        text:SetPoint("LEFT", 15, 0)
        text:SetText(label)

        btn:SetScript("OnClick", function() selectTab(idx) end)
        btn:SetScript("OnEnter", function()
            if activeTab ~= idx then btn:SetBackdropColor(unpack(colors.sidebarHover)) end
        end)
        btn:SetScript("OnLeave", function()
            if activeTab ~= idx then btn:SetBackdropColor(0, 0, 0, 0) end
        end)

        table.insert(tabs, btn)
        return btn
    end

    for i, name in ipairs(tabNames) do
        createTabButton(name, i)
        local panel = CreateFrame("Frame", nil, parent)
        panel:SetPoint("TOPLEFT", sidebarSeparator, "TOPRIGHT", 0, 0)
        panel:SetPoint("BOTTOMRIGHT", -10, 15)
        panel:Hide()

        local scrollFrame, content = elements:createScrollPanel({ elementID = "TabScrollPanel_" .. i, parent = panel })
        panel.scrollFrame = scrollFrame
        panel.content = content
        panel.updateLayout = buildFuncs[i]

        table.insert(panels, panel)
    end

    selectTab(activeTab)

    return {
        panels = panels,
        selectTab = selectTab,
        getActiveTab = function() return activeTab end
    }
end

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FACTORY (OOP Wrapper & Table-based API)
-------------------------------------------------------------------------------
local Factory = {}

function Factory:new(parent, startY)
    local obj = { parent = parent, y = startY or -15 }
    setmetatable(obj, { __index = self })
    return obj
end

function Factory:header(elementID, text)
    local h, newY = elements:createHeader({ elementID = elementID, parent = self.parent, text = text, yOffset = self.y })
    self.y = newY
    return h
end

function Factory:label(elementID, text, xOffset, color)
    local targetParent = self.currentSection or self.parent
    local l, newY = elements:createLabel({ 
        elementID = elementID, 
        parent = targetParent, 
        anchorFrame = self.parent, 
        text = text, 
        yOffset = self.y, 
        xOffset = xOffset,
        color = color 
    })
    self.y = newY
    return l
end

function Factory:checkbox(elementID, text, tooltip, getter, setter, xOffset)
    local cb, newY = elements:createCheckbox({
        elementID = elementID, parent = self.parent, text = text, tooltip = tooltip,
        getter = getter, setter = setter, yOffset = self.y, xOffset = xOffset
    })
    self.y = newY
    return cb
end

function Factory:slider(elementID, text, minVal, maxVal, step, getter, setter, width, xOffset)
    local s, newY = elements:createSlider({
        elementID = elementID, parent = self.parent, text = text, minVal = minVal, maxVal = maxVal, step = step,
        getter = getter, setter = setter, width = width, yOffset = self.y, xOffset = xOffset
    })
    self.y = newY
    return s
end

function Factory:stepper(elementID, text, minVal, maxVal, step, getter, setter, width, xOffset)
    local s, newY = elements:createStepper({
        elementID = elementID, parent = self.parent, text = text, minVal = minVal, maxVal = maxVal, step = step,
        getter = getter, setter = setter, width = width, yOffset = self.y, xOffset = xOffset
    })
    self.y = newY
    return s
end

function Factory:colorPicker(elementID, text, getter, setter, xOffset, hasAlpha)
    local cp, newY = elements:createColorPicker({
        elementID = elementID, parent = self.parent, text = text, getter = getter, setter = setter,
        yOffset = self.y, xOffset = xOffset, hasAlpha = hasAlpha
    })
    self.y = newY
    return cp
end

function Factory:dropdown(elementID, text, items, getter, setter, width, xOffset)
    local itemsTable = items
    if type(items) == "table" and items.values then itemsTable = items.values end
    
    local d, newY = elements:createDropdown({
        elementID = elementID, parent = self.parent, text = text, options = itemsTable,
        getter = getter, setter = setter, width = width, yOffset = self.y, xOffset = xOffset
    })
    self.y = newY
    return d
end

function Factory:input(elementID, text, onEnterPressed, width, xOffset)
    local i, newY = elements:createInput({
        elementID = elementID, parent = self.parent, text = text, onEnterPressed = onEnterPressed,
        width = width, yOffset = self.y, xOffset = xOffset
    })
    self.y = newY
    return i
end

function Factory:button(elementID, text, width, height, xOffset, onClick)
    local btn, newY = elements:createButton({
        elementID = elementID, parent = self.parent, text = text,
        width = width, height = height, xOffset = xOffset, yOffset = self.y, onClick = onClick
    })
    self.y = newY
    return btn
end

function Factory:beginSection(xOffset, width)
    local section = CreateFrame("Frame", nil, self.parent, "BackdropTemplate")
    local actualX = xOffset or 8
    
    -- Reduced top padding from 8 to 4
    self.sectionStartY = self.y + 4
    section:SetPoint("TOPLEFT", self.parent, "TOPLEFT", actualX, self.sectionStartY)
    
    if width then
        section:SetWidth(width)
    else
        section:SetPoint("RIGHT", self.parent, "RIGHT", -8, 0)
    end

    section:SetBackdrop({
        bgFile = files.bgFile,
        edgeFile = files.edgeFile,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    section:SetBackdropColor(unpack(colors.surfaceDark or {0,0,0,1}))
    section:SetBackdropBorderColor(unpack(colors.surfaceHighlight or {1,1,1,1}))
    self.currentSection = section
    self.y = self.y - 4 -- Reduced top padding inside the card
end

function Factory:endSection()
    if self.currentSection then
        -- Reduce the inherent bottom gap left by the last UI element by moving Y up by 8 pixels
        self.y = self.y + 8 
        
        local totalHeight = self.sectionStartY - self.y
        self.currentSection:SetHeight(totalHeight)
        
        self.currentSection = nil
        self.y = self.y - 16
    end
end

-- --------------------------------------------------------------------------------
-- Aliases for Table-based API (Used by Tab files)
-- --------------------------------------------------------------------------------

function Factory:createHeader(args)
    return self:header(args.elementID or ("Header_" .. (args.text or "")), args.text)
end

function Factory:createToggle(args)
    return self:checkbox(args.elementID or ("Toggle_" .. (args.text or "")), args.text, args.tooltip, args.get, args.set, args.xOffset)
end

function Factory:createSlider(args)
    return self:slider(args.elementID or ("Slider_" .. (args.text or "")), args.text, args.min or 0, args.max or 100, args.step or 1, args.get, args.set, args.width, args.xOffset)
end

function Factory:createDropdown(args)
    return self:dropdown(args.elementID or ("Dropdown_" .. (args.text or "")), args.text, args.options or args.values or {}, args.get, args.set, args.width, args.xOffset)
end

function Factory:createColorPicker(args)
    local cp, newY = elements:createColorPicker({
        elementID = args.elementID or ("Color_" .. (args.text or "")),
        parent = self.parent,
        text = args.text,
        getter = args.get,
        setter = args.set,
        yOffset = self.y,
        xOffset = args.xOffset,
        hasAlpha = args.hasAlpha,
        onReset = args.onReset
    })
    self.y = newY
    return cp
end

function Factory:createButton(args)
    return self:button(args.elementID or ("Button_" .. (args.text or "")), args.text, args.width, args.height, args.xOffset, args.onClick)
end

-- Final Export: Ensure Config.lua can find 'new' in layoutFactory
addonTable.layoutFactory = Factory
addonTable.UIElements = elements