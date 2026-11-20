-- PartyDebuffAlert_EditMode.lua
-- Language: Lua
-- Shared Edit Mode: lets the player drag the alert popup and the arrow
-- preview to their desired positions. All other UI is hidden while active.

local PDA = PartyDebuffAlert

local editActive = false

-- ── Dim overlay ───────────────────────────────────────────────────────────────

local dimFrame = CreateFrame("Frame", "PDA_DimFrame", UIParent)
dimFrame:SetAllPoints(UIParent)
dimFrame:SetFrameStrata("DIALOG")
dimFrame:SetFrameLevel(1)
dimFrame:Hide()

local dimTex = dimFrame:CreateTexture(nil, "BACKGROUND")
dimTex:SetAllPoints(dimFrame)
dimTex:SetColorTexture(0, 0, 0, 0.55)

-- ── Helper: make any frame draggable, saving position on stop ─────────────────

local function MakeDraggable(frame, onStop)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop",  function(self)
        self:StopMovingOrSizing()
        if onStop then onStop() end
    end)
end

local function StopDraggable(frame)
    frame:SetMovable(false)
    frame:EnableMouse(false)
    frame:SetScript("OnDragStart", nil)
    frame:SetScript("OnDragStop",  nil)
end

-- ── Alert preview frame ───────────────────────────────────────────────────────

local function SaveAlertPos()
    if not PDA_AlertFrame or not PDA_AlertFrame:GetCenter() or not UIParent:GetCenter() then return end
    local db = PartyDebuffAlertDB or PDA.defaults
    local x, y = PDA_AlertFrame:GetCenter()
    local cx, cy = UIParent:GetCenter()
    db.alertX = math.floor(x - cx + 0.5)
    db.alertY = math.floor(y - cy + 0.5)
end

-- ── Arrow preview frame ───────────────────────────────────────────────────────

local arrowPreview = CreateFrame("Frame", "PDA_ArrowPreview", UIParent)
arrowPreview:SetSize(80, 50)
arrowPreview:SetFrameStrata("DIALOG")
arrowPreview:SetFrameLevel(10)
arrowPreview:Hide()

local apBg = arrowPreview:CreateTexture(nil, "BACKGROUND")
apBg:SetAllPoints(arrowPreview)
apBg:SetColorTexture(0.05, 0.05, 0.10, 0.85)

local apTex = arrowPreview:CreateTexture(nil, "ARTWORK")
apTex:SetSize(16, 24)
apTex:SetPoint("LEFT", arrowPreview, "LEFT", 8, 0)
apTex:SetTexture("Interface\\Minimap\\ROTATING-MINIMAPARROW")
if apTex.SetRotation then
    apTex:SetRotation(math.rad(-90))
end
apTex:SetVertexColor(0.20, 0.60, 1.0)

local apLabel = arrowPreview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
apLabel:SetPoint("LEFT", apTex, "RIGHT", 6, 0)
apLabel:SetText("|cffffffffArrow|r")

local apHint = arrowPreview:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
apHint:SetPoint("BOTTOM", arrowPreview, "BOTTOM", 0, 2)
apHint:SetText("Drag me")

local apBorderTop = arrowPreview:CreateTexture(nil, "BORDER")
apBorderTop:SetColorTexture(0.6, 0.6, 0.6, 0.6)
apBorderTop:SetHeight(1)
apBorderTop:SetPoint("TOPLEFT",  arrowPreview, "TOPLEFT",  0, 0)
apBorderTop:SetPoint("TOPRIGHT", arrowPreview, "TOPRIGHT", 0, 0)

local apBorderBot = arrowPreview:CreateTexture(nil, "BORDER")
apBorderBot:SetColorTexture(0.6, 0.6, 0.6, 0.6)
apBorderBot:SetHeight(1)
apBorderBot:SetPoint("BOTTOMLEFT",  arrowPreview, "BOTTOMLEFT",  0, 0)
apBorderBot:SetPoint("BOTTOMRIGHT", arrowPreview, "BOTTOMRIGHT", 0, 0)

local function SaveArrowPos()
    if not arrowPreview:GetCenter() or not UIParent:GetCenter() then return end
    local db = PartyDebuffAlertDB or PDA.defaults
    local x, y = arrowPreview:GetCenter()
    local cx, cy = UIParent:GetCenter()
    db.arrowPreviewX = math.floor(x - cx + 0.5)
    db.arrowPreviewY = math.floor(y - cy + 0.5)
    db.arrowOffsetX = db.arrowPreviewX
    db.arrowOffsetY = db.arrowPreviewY
end

local function ApplyArrowPreviewPos()
    local db = PartyDebuffAlertDB or PDA.defaults
    local x = db.arrowPreviewX or db.arrowOffsetX or 4
    local y = db.arrowPreviewY or db.arrowOffsetY or 0
    arrowPreview:ClearAllPoints()
    arrowPreview:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

-- ── Exit button (always on top during edit mode) ──────────────────────────────

local exitBtn = CreateFrame("Button", "PDA_EditModeExitBtn", UIParent, "UIPanelButtonTemplate")
exitBtn:SetSize(180, 32)
exitBtn:SetPoint("TOP", UIParent, "TOP", 0, -60)
exitBtn:SetFrameStrata("TOOLTIP")
exitBtn:SetFrameLevel(20)
exitBtn:SetText("Exit Edit Mode")
exitBtn:Hide()

-- ── Public API ────────────────────────────────────────────────────────────────

function PDA_IsEditModeActive()
    return editActive
end

function PDA_EnterEditMode()
    if editActive then return end
    editActive = true

    local db = PartyDebuffAlertDB or PDA.defaults
    local colorKeys = { "colorMagic", "colorCurse", "colorPoison", "colorDisease" }
    for _, ck in ipairs(colorKeys) do
        local c = db[ck]
        if c and c.useColor then
            apTex:SetVertexColor(c.r or 1, c.g or 1, c.b or 1)
            break
        end
    end

    dimFrame:SetFrameStrata("DIALOG")
    dimFrame:SetFrameLevel(1)
    dimFrame:Show()

    if PDA_EnterMoveMode then PDA_EnterMoveMode() end
    if PDA_AlertFrame then
        PDA_AlertFrame:SetFrameStrata("DIALOG")
        PDA_AlertFrame:SetFrameLevel(5)
        MakeDraggable(PDA_AlertFrame, SaveAlertPos)
    end

    ApplyArrowPreviewPos()
    arrowPreview:SetFrameStrata("DIALOG")
    arrowPreview:SetFrameLevel(5)
    arrowPreview:Show()
    MakeDraggable(arrowPreview, SaveArrowPos)

    exitBtn:Show()
    exitBtn:SetFrameStrata("TOOLTIP")
end

function PDA_ExitEditMode(keepConfig)
    if not editActive then return end
    editActive = false

    SaveAlertPos()
    SaveArrowPos()

    if PDA_AlertFrame then
        PDA_AlertFrame:SetFrameStrata("HIGH")
        PDA_AlertFrame:SetFrameLevel(100)
        StopDraggable(PDA_AlertFrame)
    end
    if PDA_ExitMoveMode then PDA_ExitMoveMode() end

    StopDraggable(arrowPreview)
    arrowPreview:Hide()

    dimFrame:Hide()
    exitBtn:Hide()

    if keepConfig and PDA_ConfigFrame then
        PDA_ConfigFrame:Show()
    end
end

exitBtn:SetScript("OnClick", function()
    PDA_ExitEditMode(false)
end)

function PDA_GetArrowOffset()
    local db = PartyDebuffAlertDB or PDA.defaults
    return db.arrowOffsetX or 4, db.arrowOffsetY or 0
end