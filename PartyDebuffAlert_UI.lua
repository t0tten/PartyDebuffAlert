-- PartyDebuffAlert_UI.lua
-- Language: Lua
-- Alert popup with draggable position and pop/hold/fade animation.

local PDA = PartyDebuffAlert

local colorKey = {
    Magic   = "colorMagic",
    Curse   = "colorCurse",
    Poison  = "colorPoison",
    Disease = "colorDisease",
}

local function GetTypeColor(debuffType)
    local db  = PartyDebuffAlertDB or PDA.defaults
    local key = colorKey[debuffType]
    local c   = key and db[key]
    if not c or not c.useColor then return 1, 1, 1 end
    return c.r or 1, c.g or 1, c.b or 1
end

local ANIM_POP  = 0.25
local ANIM_FADE = 0.40
local BASE_W    = 380
local BASE_H    = 90

local function EaseOut(t) return 1 - (1 - t)^3 end
local function EaseIn(t)  return t * t end

-- ── Alert frame ───────────────────────────────────────────────────────────────

local alertFrame = CreateFrame("Frame", "PDA_AlertFrame", UIParent)
alertFrame:SetSize(BASE_W, BASE_H)
alertFrame:SetFrameStrata("HIGH")
alertFrame:SetFrameLevel(100)
alertFrame:SetAlpha(0)
alertFrame:Hide()

local bgTex = alertFrame:CreateTexture(nil, "BACKGROUND")
bgTex:SetAllPoints(alertFrame)
bgTex:SetColorTexture(0.05, 0.05, 0.10, 0.90)

local topBorder = alertFrame:CreateTexture(nil, "BORDER")
topBorder:SetPoint("TOPLEFT",  alertFrame, "TOPLEFT",  0, 0)
topBorder:SetPoint("TOPRIGHT", alertFrame, "TOPRIGHT", 0, 0)
topBorder:SetHeight(2)
topBorder:SetColorTexture(1, 1, 1, 1)

local typeLabel = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
typeLabel:SetPoint("TOP", alertFrame, "TOP", 0, -10)
typeLabel:SetText("")

local mainLine = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
mainLine:SetPoint("TOP", typeLabel, "BOTTOM", 0, -4)
mainLine:SetText("")

local spellLine = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
spellLine:SetPoint("TOP", mainLine, "BOTTOM", 0, -4)
spellLine:SetText("")

-- ── Position helpers ──────────────────────────────────────────────────────────

local function ApplyAlertPosition()
    local db = PartyDebuffAlertDB or PDA.defaults
    local x = db.alertX or 0
    local y = db.alertY or 80
    alertFrame:ClearAllPoints()
    alertFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

local function SaveAlertPosition()
    if not alertFrame:GetCenter() or not UIParent:GetCenter() then return end
    local db = PartyDebuffAlertDB or PDA.defaults
    local x, y = alertFrame:GetCenter()
    local cx, cy = UIParent:GetCenter()
    db.alertX = math.floor(x - cx + 0.5)
    db.alertY = math.floor(y - cy + 0.5)
end

function PDA_ApplyAlertPosition()
    ApplyAlertPosition()
end

-- ── Drag-to-move mode ─────────────────────────────────────────────────────────

local moveMode = false

local moveOverlay = alertFrame:CreateTexture(nil, "HIGHLIGHT")
moveOverlay:SetAllPoints(alertFrame)
moveOverlay:SetColorTexture(1, 1, 1, 0.08)
moveOverlay:Hide()

local moveLabel = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
moveLabel:SetPoint("CENTER", alertFrame, "CENTER", 0, 0)
moveLabel:SetText("|cffffffffDrag to reposition|r")
moveLabel:Hide()

function PDA_EnterMoveMode()
    moveMode = true
    alertFrame:SetMovable(true)
    alertFrame:EnableMouse(true)
    alertFrame:RegisterForDrag("LeftButton")
    alertFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    alertFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveAlertPosition()
    end)
    alertFrame:SetSize(BASE_W, BASE_H)
    typeLabel:SetText("ALERT POSITION")
    typeLabel:SetTextColor(1, 0.82, 0)
    mainLine:SetText("Drag this box to reposition")
    mainLine:SetTextColor(1, 1, 1)
    spellLine:SetText("Click 'Save Positions' when finished")
    spellLine:SetTextColor(0.7, 0.7, 0.7)
    topBorder:SetColorTexture(1, 0.82, 0, 1)
    alertFrame:SetAlpha(0.75)
    alertFrame:Show()
    moveOverlay:Show()
    moveLabel:Hide()
end

function PDA_ExitMoveMode()
    moveMode = false
    alertFrame:SetMovable(false)
    alertFrame:EnableMouse(false)
    alertFrame:SetScript("OnDragStart", nil)
    alertFrame:SetScript("OnDragStop", nil)
    alertFrame:Hide()
    alertFrame:SetAlpha(0)
    moveOverlay:Hide()
    SaveAlertPosition()
end

-- ── State ─────────────────────────────────────────────────────────────────────

local animState   = "idle"
local animElapsed = 0
local holdFor     = 4
local alertQueue  = {}
local isShowing   = false
local isTestArrow = false

local function ApplyColors(r, g, b)
    typeLabel:SetTextColor(r, g, b)
    mainLine:SetTextColor(r, g, b)
    spellLine:SetTextColor(math.min(r+0.15,1), math.min(g+0.15,1), math.min(b+0.15,1))
    topBorder:SetColorTexture(r, g, b, 1)
end

local function ShowNextAlert()
    if moveMode then return end
    if #alertQueue == 0 then
        isShowing = false
        animState = "idle"
        alertFrame:Hide()
        if isTestArrow and PDA_UpdatePartyArrow then
            isTestArrow = false
            PDA_UpdatePartyArrow("player", nil, false)
        end
        return
    end

    isShowing = true
    local entry = table.remove(alertQueue, 1)
    local r, g, b = GetTypeColor(entry.debuffType)

    typeLabel:SetText(entry.debuffType:upper())
    mainLine:SetText(entry.unitName .. " has a " .. entry.debuffType .. "!")
    spellLine:SetText('"' .. entry.spellName .. '"')
    ApplyColors(r, g, b)

    local db = PartyDebuffAlertDB or PDA.defaults
    holdFor = (db.displayDuration and db.displayDuration > 0) and db.displayDuration or 4

    ApplyAlertPosition()
    alertFrame:SetSize(BASE_W * 0.6, BASE_H * 0.6)
    alertFrame:SetAlpha(0)
    alertFrame:Show()
    animState   = "popin"
    animElapsed = 0
end

alertFrame:SetScript("OnUpdate", function(self, dt)
    if moveMode then return end
    if animState == "popin" then
        animElapsed = animElapsed + dt
        local t = math.min(animElapsed / ANIM_POP, 1)
        local e = EaseOut(t)
        alertFrame:SetSize(BASE_W * (0.6 + e * 0.4), BASE_H * (0.6 + e * 0.4))
        self:SetAlpha(e)
        if t >= 1 then
            alertFrame:SetSize(BASE_W, BASE_H)
            self:SetAlpha(1)
            animState   = "hold"
            animElapsed = 0
        end

    elseif animState == "hold" then
        animElapsed = animElapsed + dt
        if animElapsed >= holdFor then
            animState   = "fadeout"
            animElapsed = 0
        end

    elseif animState == "fadeout" then
        animElapsed = animElapsed + dt
        local t = math.min(animElapsed / ANIM_FADE, 1)
        local e = EaseIn(t)
        alertFrame:SetSize(BASE_W * (1 + e * 0.1), BASE_H * (1 + e * 0.1))
        self:SetAlpha(1 - e)
        if t >= 1 then
            self:Hide()
            alertFrame:SetSize(BASE_W, BASE_H)
            self:SetAlpha(0)
            animState = "idle"
            ShowNextAlert()
        end
    end
end)

-- ── Public API ────────────────────────────────────────────────────────────────

function PDA_ShowAlert(unitName, debuffType, spellName)
    if moveMode then return end
    table.insert(alertQueue, {
        unitName   = unitName,
        debuffType = debuffType,
        spellName  = spellName,
    })
    if not isShowing then
        ShowNextAlert()
    end
end

function PDA_TestAlert(debuffType)
    if moveMode then return end
    isShowing = false
    animState = "idle"
    alertFrame:Hide()
    alertFrame:SetSize(BASE_W, BASE_H)
    alertFrame:SetAlpha(0)
    while #alertQueue > 0 do table.remove(alertQueue) end

    if PDA_TestPartyArrow then
        isTestArrow = true
        PDA_TestPartyArrow(debuffType)
    end

    PDA_ShowAlert("Testplayer", debuffType, "Test - " .. debuffType .. " Debuff")
end