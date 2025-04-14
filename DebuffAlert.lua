local frame = CreateFrame("Frame")
local alertText = nil
local lastDebuffState = false
local flashFrame = nil

local function LoadVariables()
    DebuffAlert_Store = DebuffAlert_Store or {}
    DebuffAlert_Store.AlertPosition = DebuffAlert_Store.AlertPosition or { point = "CENTER", x = 0, y = 200 }
    DebuffAlert_Store.DebuffTexturesToWatch = DebuffAlert_Store.DebuffTexturesToWatch or
        {
            ["Spell_BrokenHeart"] = { enabled = true },
            ["Spell_Shadow_AntiShadow"] = { enabled = true },
            ["Inv_Misc_ShadowEgg"] = { enabled = true },
            -- Add more here
        }  
end

function AddDebuffToWatch(texturePath)
    DebuffAlert_Store.DebuffTexturesToWatch[texturePath] = { enabled = true }
end

function RemoveDebuffFromWatch(texturePath)
    DebuffAlert_Store.DebuffTexturesToWatch[texturePath] = nil
end

function SetDebuffEnabled(texturePath, enabled)
    if DebuffAlert_Store.DebuffTexturesToWatch[texturePath] then
        DebuffAlert_Store.DebuffTexturesToWatch[texturePath].enabled = enabled
    end
end

-- Create the screen flash frame
local function CreateFlashFrame()
    if flashFrame then
        flashFrame:Hide()
        flashFrame = nil
    end
    
    flashFrame = CreateFrame("Frame", nil, UIParent)
    flashFrame:SetAllPoints(UIParent)
    flashFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    flashFrame:SetAlpha(0)
    
    local texture = flashFrame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(flashFrame)
    texture:SetTexture("Interface\\FullScreenTextures\\LowHealth")
    texture:SetVertexColor(1, 0, 0, 0.5) -- Red color with 50% opacity
end

-- Create the floating alert text
local function CreateAlertText()
    local pos = DebuffAlert_Store.AlertPosition
    alertText = UIParent:CreateFontString(nil, "OVERLAY")
    alertText:SetFont("Fonts\\FRIZQT__.TTF", 160, "OUTLINE")
    alertText:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    alertText:SetTextColor(1, 0, 0, 1)
    alertText:SetText("Debuff Alert - Move!")
    alertText:SetShadowColor(0, 0, 0, 1)
    alertText:SetShadowOffset(4, -4)
    alertText:SetSpacing(4)
    alertText:Hide()

    -- Update the position of the alert text if position data changes
    local function UpdateAlertTextPosition()
        local pos = DebuffAlert_Store.AlertPosition
        if pos then
            alertText:ClearAllPoints()
            alertText:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
        end
    end

    -- Call this function whenever the position changes
    DebuffAlert_DraggableAlert:SetScript("OnDragStop", function()
        DebuffAlert_DraggableAlert:StopMovingOrSizing()  -- Stop moving the frame
        local point, _, _, x, y = DebuffAlert_DraggableAlert:GetPoint()  -- Get the new position
        DebuffAlert_Store.AlertPosition = { point = point, x = x, y = y }  -- Save the new position
        UpdateAlertTextPosition()  -- Update the alert text position immediately
    end)

    -- Initially set the position of the alert text
    UpdateAlertTextPosition()
end

-- Flash animation
local function FlashScreen()
    if not flashFrame then return end
    UIFrameFadeIn(flashFrame, 0.2, 0, 0.5)
end

-- Create the draggable alert (default to hidden)
local DebuffAlert_DraggableAlert = CreateFrame("Frame", "DebuffAlert_DraggableAlert", UIParent)
DebuffAlert_DraggableAlert:SetWidth(200)  -- Set width instead of SetSize
DebuffAlert_DraggableAlert:SetHeight(30)  -- Set height instead of SetSize
DebuffAlert_DraggableAlert:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
DebuffAlert_DraggableAlert:SetBackdropColor(0, 0, 0, 0.8)
DebuffAlert_DraggableAlert.text = DebuffAlert_DraggableAlert:CreateFontString(nil, "OVERLAY", "GameFontNormal")
DebuffAlert_DraggableAlert.text:SetPoint("CENTER", DebuffAlert_DraggableAlert, "CENTER")
DebuffAlert_DraggableAlert.text:SetText("Debuff Alert Position")
DebuffAlert_DraggableAlert:EnableMouse(true)
DebuffAlert_DraggableAlert:RegisterForDrag("LeftButton")
DebuffAlert_DraggableAlert:SetMovable(true)
DebuffAlert_DraggableAlert:SetClampedToScreen(true)
DebuffAlert_DraggableAlert:Hide()  -- Keep it hidden by default

-- OnDragStart and OnDragStop should directly use DebuffAlert_DraggableAlert in their functions
DebuffAlert_DraggableAlert:SetScript("OnDragStart", function()
    DebuffAlert_DraggableAlert:StartMoving()  -- Start moving the frame
end)

DebuffAlert_DraggableAlert:SetScript("OnDragStop", function()
    DebuffAlert_DraggableAlert:StopMovingOrSizing()  -- Stop moving the frame
    local point, _, _, x, y = DebuffAlert_DraggableAlert:GetPoint()  -- Get the new position
    DebuffAlert_Store.AlertPosition = { point = point, x = x, y = y }  -- Save the new position
    
    -- Update the position of the actual alert (text) immediately
    if DebuffAlert_Store.AlertPosition then
        DebuffAlert_DraggableAlert:SetPoint(DebuffAlert_Store.AlertPosition.point, UIParent, DebuffAlert_Store.AlertPosition.point, DebuffAlert_Store.AlertPosition.x, DebuffAlert_Store.AlertPosition.y)
    end
end)

-- Check for the specific debuff
local function CheckDebuff()
    if not alertText then return end

    local hasDebuff = false
    
    -- Check all debuffs
    for i = 1, 40 do
        local texture = UnitDebuff("player", i)
        if texture then
            local entry
            local normalizedTexture = string.lower(texture)

            for storedTexture, data in pairs(DebuffAlert_Store.DebuffTexturesToWatch or {}) do
                if "interface\\icons\\" .. string.lower(storedTexture) == normalizedTexture then
                    entry = data
                    break
                end
            end

            if entry and entry.enabled then
                hasDebuff = true
                break
            end
        end        
    end    

    -- Update alert visibility based on debuff state
    if hasDebuff and not lastDebuffState then
        alertText:Show()
        PlaySoundFile("Sound\\Interface\\RaidWarning.wav", "Master")
        FlashScreen() -- Add screen flash effect
        lastDebuffState = true
    elseif not hasDebuff and lastDebuffState then
        alertText:Hide()
        if flashFrame then
            flashFrame:Hide()
        end
        lastDebuffState = false
    end
end

function DebuffAlert_OnDebuffToggle()
    local texture = this.texture
    if texture and DebuffAlert_Store.DebuffTexturesToWatch[texture] then
        DebuffAlert_Store.DebuffTexturesToWatch[texture].enabled = this:GetChecked()
    end
end

function DebuffAlert_UpdateList()
    local scrollFrame = DebuffAlert_ScrollFrame
    local textures = {}

    -- Build a numerically indexed list of debuffs
    for texture, data in pairs(DebuffAlert_Store.DebuffTexturesToWatch or {}) do
        table.insert(textures, { texture = texture, enabled = data.enabled })
    end

    local total = table.getn(textures)
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    local numToShow = 10

    for i = 1, numToShow do
        local index = offset + i
        local row = getglobal("DebuffAlert_Row"..i)

        if not row then
            row = CreateFrame("CheckButton", "DebuffAlert_Row"..i, DebuffAlert_Frame, "OptionsCheckButtonTemplate")
            row:SetPoint("TOPLEFT", DebuffAlert_ScrollFrame, "TOPLEFT", 32, -((i - 1) * 36))
            row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            row.text:SetPoint("LEFT", row, "RIGHT", 5, 0)

            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetWidth(32)
            row.icon:SetHeight(32)
            row.icon:SetPoint("LEFT", row, "LEFT", -32, 0)

            -- Delete button
            row.deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.deleteButton:SetWidth(18)
            row.deleteButton:SetHeight(18)
            row.deleteButton:SetText("X")
            row.deleteButton:SetPoint("LEFT", row.text, "RIGHT", 10, 0)
        end

        local entry = textures[index]
        if entry then
            row:Show()
            row:SetChecked(entry.enabled)
            row.text:SetText(entry.texture)
            row.icon:SetTexture("Interface\\Icons\\" .. entry.texture)

            row.texture = entry.texture
            row:SetScript("OnClick", DebuffAlert_OnDebuffToggle)

            row.deleteButton:SetScript("OnClick", function()
                DebuffAlert_Store.DebuffTexturesToWatch[entry.texture] = nil
                DebuffAlert_UpdateList()
            end)

            row.deleteButton:Show()
        else
            row:Hide()
            if row.deleteButton then row.deleteButton:Hide() end
        end
    end

    FauxScrollFrame_Update(scrollFrame, total, numToShow, 20)
end

function DebuffAlert_SetPropValue(propName, propValue)
    if not DebuffAlert_Store then DebuffAlert_Store = {} end
    if not DebuffAlert_Store.DebuffTexturesToWatch then
        DebuffAlert_Store.DebuffTexturesToWatch = {}
    end

    if not DebuffAlert_Store.DebuffTexturesToWatch[propName] then
        DebuffAlert_Store.DebuffTexturesToWatch[propName] = {}
        DEFAULT_CHAT_FRAME:AddMessage("INFO: Added new debuff: " .. propName)
    end

    DebuffAlert_Store.DebuffTexturesToWatch[propName].enabled = propValue
    DEFAULT_CHAT_FRAME:AddMessage("INFO: Saved debuff: " .. propName .. " = " .. tostring(propValue))
end

-- Debuff Alert Slash Commands
local function DebuffAlertCommands(msg, editbox)
    if DebuffAlertOptions:IsShown() then
        DebuffAlertOptions:Hide()
    else
        DebuffAlertOptions:Show()
        DebuffAlert_UpdateList()
    end
end

-- Event handler
frame:SetScript("OnEvent", function()
    local event = event
    if not event then return end
    
    if event == "ADDON_LOADED" and arg1 == "DebuffAlert" then
        DebuffAlertOptions = DebuffAlert_Frame
        LoadVariables()
        DebuffAlert_UpdateList()

        -- If there's a stored position, set it
        if DebuffAlert_Store.AlertPosition then
            DebuffAlert_DraggableAlert:SetPoint(DebuffAlert_Store.AlertPosition.point, UIParent, DebuffAlert_Store.AlertPosition.point, DebuffAlert_Store.AlertPosition.x, DebuffAlert_Store.AlertPosition.y)
        end

        local function DebuffAlertCommands(msg, editbox)
            if DebuffAlertOptions and DebuffAlertOptions:IsShown() then
                DebuffAlertOptions:Hide()
            elseif DebuffAlertOptions then
                DebuffAlertOptions:Show()
            end
        end

        SLASH_DEBUFFALERT1 = "/da"
        SlashCmdList["DEBUFFALERT"] = DebuffAlertCommands

        CreateFlashFrame()
        CreateAlertText()
        CheckDebuff()
    elseif event == "PLAYER_ENTERING_WORLD" then
        CreateFlashFrame()
        CreateAlertText()
        CheckDebuff()
    elseif event == "UNIT_AURA" then
        CheckDebuff()
    end
end)

-- Register events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_AURA")

-- Force an initial check after a short delay
local timeSinceLastCheck = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    if not elapsed then return end
    timeSinceLastCheck = timeSinceLastCheck + elapsed
    if timeSinceLastCheck >= 1 then
        CreateFlashFrame()
        CreateAlertText()
        CheckDebuff()
        self:SetScript("OnUpdate", nil)
    end
end)
