local debuffTextureToWatch = "Interface\\Icons\\Spell_Shadow_AntiShadow"
local frame = CreateFrame("Frame")
local alertText = nil
local lastDebuffState = false
local flashFrame = nil

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
    alertText:SetText("Mark of the Highlord!")
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
        if texture and debuffTextureToWatch and string.lower(texture) == string.lower(debuffTextureToWatch) then
            hasDebuff = true
            break
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

-- Event handler
frame:SetScript("OnEvent", function()
    local event = event
    if not event then return end
    
    if event == "ADDON_LOADED" then
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
