local frame = CreateFrame("Frame")
local alertText = nil
local lastDebuffState = false
local flashFrame = nil

local function LoadVariables()
    DebuffAlert_Store = DebuffAlert_Store or {}
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
    alertText = UIParent:CreateFontString(nil, "OVERLAY")
    alertText:SetFont("Fonts\\FRIZQT__.TTF", 160, "OUTLINE")
    alertText:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    alertText:SetTextColor(1, 0, 0, 1)
    alertText:SetText("Debuff Alert - Move!")
    alertText:SetShadowColor(0, 0, 0, 1)
    alertText:SetShadowOffset(4, -4)
    alertText:SetSpacing(4)
    alertText:Hide()
end

-- Flash animation
local function FlashScreen()
    if not flashFrame then return end
    UIFrameFadeIn(flashFrame, 0.2, 0, 0.5)
end

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
