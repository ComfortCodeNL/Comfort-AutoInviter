local ADDON_NAME = "Comfort-AutoInviter"

local defaults = {
    enabled = true,
    trigger = "123",
    minimapAngle = 225,
}

local inviteFunc = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit

-- Hoofdframe voor events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_GUILD")

-- ==========================================
-- Settings Venster
-- ==========================================
local settingsFrame = CreateFrame("Frame", "ComfortAutoInviterSettingsFrame", UIParent, "BackdropTemplate")
settingsFrame:SetSize(280, 175)
settingsFrame:SetPoint("CENTER")
settingsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
settingsFrame:SetMovable(true)
settingsFrame:EnableMouse(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
settingsFrame:SetFrameStrata("DIALOG")
settingsFrame:Hide()

local title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -14)
title:SetText("Comfort-AutoInviter")

local closeBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -5, -5)

-- Checkbox: Aan / Uit
local enableCheck = CreateFrame("CheckButton", "ComfortAutoInviterEnableCheck", settingsFrame, "UICheckButtonTemplate")
enableCheck:SetPoint("TOPLEFT", 20, -45)
local checkText = enableCheck.Text or _G[enableCheck:GetName() .. "Text"]
checkText:SetText("Auto Inviter inschakelen")

-- Label voor Trigger String
local triggerLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
triggerLabel:SetPoint("TOPLEFT", 24, -85)
triggerLabel:SetText("Trigger tekst (guildchat):")

-- Invoerveld voor Trigger String
local triggerBox = CreateFrame("EditBox", "ComfortAutoInviterTriggerBox", settingsFrame, "InputBoxTemplate")
triggerBox:SetSize(140, 24)
triggerBox:SetPoint("TOPLEFT", 28, -105)
triggerBox:SetAutoFocus(false)

-- Opslaan knop
local saveBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
saveBtn:SetSize(80, 24)
saveBtn:SetPoint("LEFT", triggerBox, "RIGHT", 10, 0)
saveBtn:SetText("Opslaan")

-- ==========================================
-- Minimap Icoon
-- ==========================================
local minimapBtn = CreateFrame("Button", "ComfortAutoInviterMinimapButton", Minimap)
minimapBtn:SetSize(31, 31)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local overlay = minimapBtn:CreateTexture(nil, "OVERLAY")
overlay:SetSize(53, 53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT")

local icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetTexture("Interface\\Icons\\INV_Letter_15")
icon:SetPoint("CENTER", 0, 1)

local function UpdateMinimapPosition()
    local angle = math.rad(ComfortAutoInviterDB.minimapAngle or defaults.minimapAngle)
    local radius = 80
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function UpdateVisualState()
    if ComfortAutoInviterDB.enabled then
        icon:SetDesaturated(false)
        icon:SetVertexColor(1, 1, 1)
    else
        icon:SetDesaturated(true)
        icon:SetVertexColor(0.6, 0.6, 0.6)
    end
end

minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        ComfortAutoInviterDB.minimapAngle = angle
        UpdateMinimapPosition()
    end)
end)

minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

minimapBtn:SetScript("OnClick", function(_, button)
    if button == "LeftButton" then
        if settingsFrame:IsShown() then
            settingsFrame:Hide()
        else
            enableCheck:SetChecked(ComfortAutoInviterDB.enabled)
            triggerBox:SetText(ComfortAutoInviterDB.trigger or defaults.trigger)
            settingsFrame:Show()
        end
    elseif button == "RightButton" then
        ComfortAutoInviterDB.enabled = not ComfortAutoInviterDB.enabled
        enableCheck:SetChecked(ComfortAutoInviterDB.enabled)
        UpdateVisualState()
        local status = ComfortAutoInviterDB.enabled and "|cff00ff00AAN|r" or "|cffff0000UIT|r"
        print("|cff33ff99Comfort-AutoInviter:|r Status gewijzigd naar " .. status)
    end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Comfort-AutoInviter")
    local status = ComfortAutoInviterDB.enabled and "|cff00ff00Ingeschakeld|r" or "|cffff0000Uitgeschakeld|r"
    GameTooltip:AddLine("Status: " .. status, 1, 1, 1)
    GameTooltip:AddLine("Trigger: |cffffff00" .. (ComfortAutoInviterDB.trigger or defaults.trigger) .. "|r", 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Linkerklik: Instellingen openen", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Rechterklik: Snel aan/uit zetten", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Slepen: Icoon verplaatsen", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- ==========================================
-- Acties voor Settings
-- ==========================================
enableCheck:SetScript("OnClick", function(self)
    ComfortAutoInviterDB.enabled = self:GetChecked()
    UpdateVisualState()
end)

local function SaveTrigger()
    local text = triggerBox:GetText():match("^%s*(.-)%s*$")
    if text ~= "" then
        ComfortAutoInviterDB.trigger = text
        print("|cff33ff99Comfort-AutoInviter:|r Nieuwe trigger opgeslagen: |cffffff00" .. text .. "|r")
    else
        triggerBox:SetText(ComfortAutoInviterDB.trigger)
    end
    triggerBox:ClearFocus()
end

saveBtn:SetScript("OnClick", SaveTrigger)
triggerBox:SetScript("OnEnterPressed", SaveTrigger)
triggerBox:SetScript("OnEscapePressed", function(self)
    self:SetText(ComfortAutoInviterDB.trigger)
    self:ClearFocus()
end)

-- ==========================================
-- Event Handling
-- ==========================================
eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        ComfortAutoInviterDB = ComfortAutoInviterDB or {}
        for k, v in pairs(defaults) do
            if ComfortAutoInviterDB[k] == nil then
                ComfortAutoInviterDB[k] = v
            end
        end
        UpdateMinimapPosition()
        UpdateVisualState()
        eventFrame:UnregisterEvent("ADDON_LOADED")

    elseif event == "CHAT_MSG_GUILD" then
        if not ComfortAutoInviterDB or not ComfortAutoInviterDB.enabled then return end

        local message, sender = arg1, arg2
        if not message or not sender then return end

        local trimmed = message:match("^%s*(.-)%s*$")
        if trimmed ~= ComfortAutoInviterDB.trigger then return end

        local playerName = UnitName("player")
        local senderShort = Ambiguate(sender, "short")
        if senderShort == playerName then return end

        if not IsInGroup() or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
            inviteFunc(sender)
        end
    end
end)

-- Slash command als extra optie
SLASH_COMFORTAUTOINVITER1 = "/cai"
SLASH_COMFORTAUTOINVITER2 = "/autoinviter"
SlashCmdList["COMFORTAUTOINVITER"] = function()
    if settingsFrame:IsShown() then
        settingsFrame:Hide()
    else
        enableCheck:SetChecked(ComfortAutoInviterDB.enabled)
        triggerBox:SetText(ComfortAutoInviterDB.trigger or defaults.trigger)
        settingsFrame:Show()
    end
end
