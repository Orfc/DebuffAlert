local debuffTextureToWatch = "Interface\\Icons\\Spell_Holy_AshesToAshes" -- "Weakened Soul"
local frame = CreateFrame("Frame")
local alertText = nil
local lastDebuffState = false

-- Create the floating alert text
local function CreateAlertText()
    alertText = UIParent:CreateFontString(nil, "OVERLAY")
    alertText:SetFont("Fonts\\FRIZQT__.TTF", 48, "OUTLINE")
    alertText:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    alertText:SetTextColor(1, 0, 0, 1)
    alertText:SetText("Weakened Soul!")
    alertText:Hide()
end

-- Check for the specific debuff
local function CheckDebuff()
    if not alertText then return end

    local hasDebuff = false
    
    -- Check all debuffs
    for i = 1, 40 do
        local texture = UnitDebuff("player", i)
        if texture == debuffTextureToWatch then
            hasDebuff = true
            break
        end
    end

    -- Update alert visibility based on debuff state
    if hasDebuff and not lastDebuffState then
        alertText:Show()
        lastDebuffState = true
    elseif not hasDebuff and lastDebuffState then
        alertText:Hide()
        lastDebuffState = false
    end
end

-- Event handler
frame:SetScript("OnEvent", function()
    local event = event
    if not event then return end
    
    if event == "ADDON_LOADED" then
        CreateAlertText()
        CheckDebuff()
    elseif event == "PLAYER_ENTERING_WORLD" then
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
        CreateAlertText()
        CheckDebuff()
        self:SetScript("OnUpdate", nil)
    end
end)
