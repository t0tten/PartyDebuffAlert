-- PartyDebuffAlert_EditMode.lua
-- Language: Lua
-- Shared Edit Mode: lets the player drag the alert popup and the party arrow
-- preview to their desired positions relative to party frames.

local PDA = PartyDebuffAlert

local editActive  = false
local PULSE_SPEED = 7.5
local BASE_ARROW  = 64
local SCALE_MIN   = 0.85
local SCALE_MAX   = 1.35
local ALPHA_MIN   = 0.35
local ALPHA_MAX   = 1.00
local ARROW_ANGLE = math.rad(90) -- points left toward the frame on the left

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
arrowPreview:SetSize(166, 86)
arrowPreview:SetFrameStrata("DIALOG")
arrowPreview:SetFrameLevel(10)
arrowPreview.animTime = 0
arrowPreview:Hide()

local apBg = arrowPreview:CreateTexture(nil, "BACKGROUND")
apBg:SetAllPoints(arrowPreview)
apBg:SetColorTexture(0.05, 0.05, 0.10, 0.88)

local function ApplyPreviewOrientation(tex)
    if not tex then return end
    if tex.SetRotation then
        tex:SetRotation(ARROW_ANGLE)
    elseif tex.SetTexCoord then
        tex:SetTexCoord(0, 1, 1, 0)
    end
end

local apTex = arrowPreview:CreateTexture(nil, "ARTWORK")
apTex:SetPoint("LEFT", arrowPreview, "LEFT", 10, 0)
apTex:SetSize(BASE_ARROW, BASE_ARROW)
apTex:SetTexture("Interface\\Minimap\\ROTATING-MINIMAPARROW")
ApplyPreviewOrientation(apTex)
apTex:SetVertexColor(0.20, 0.60, 1.0)

local apLabel = arrowPreview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
apLabel:SetPoint("LEFT", apTex, "RIGHT", 10, 0)
apLabel:SetText("Drag arrow")

local apBorderTop = arrowPreview:CreateTexture(nil, "BORDER")
apBorderTop:SetColorTexture(1, 0.82, 0, 0.8)
apBorderTop:SetHeight(1)
apBorderTop:SetPoint("TOPLEFT",  arrowPreview, "TOPLEFT",  0, 0)
apBorderTop:SetPoint("TOPRIGHT", arrowPreview, "TOPRIGHT", 0, 0)

local apBorderBot = arrowPreview:CreateTexture(nil, "BORDER")
apBorderBot:SetColorTexture(1, 0.82, 0, 0.8)
apBorderBot:SetHeight(1)
apBorderBot:SetPoint("BOTTOMLEFT",  arrowPreview, "BOTTOMLEFT",  0, 0)
apBorderBot:SetPoint("BOTTOMRIGHT", arrowPreview, "BOTTOMRIGHT", 0, 0)

local function ApplyPreviewPulse(elapsed)
    local wave  = 0.5 + 0.5 * math.sin(elapsed * PULSE_SPEED)
    local scale = SCALE_MIN + (SCALE_MAX - SCALE_MIN) * wave
    local alpha = ALPHA_MIN + (ALPHA_MAX - ALPHA_MIN) * wave
    apTex:SetSize(BASE_ARROW * scale, BASE_ARROW * scale)
    apTex:SetAlpha(alpha)
    ApplyPreviewOrientation(apTex)
end

arrowPreview:SetScript("OnUpdate", function(self, dt)
    if not self:IsShown() then return end
    self.animTime = (self.animTime or 0) + (dt or 0)
    ApplyPreviewPulse(self.animTime)
end)

arrowPreview:SetScript("OnShow", function(self)
    self.animTime = 0
    ApplyPreviewOrientation(apTex)
    ApplyPreviewPulse(0)
end)

local function GetReferencePartyFrame()
    if PartyMemberFrame1 and PartyMemberFrame1:IsShown() then
        return PartyMemberFrame1
    end
    return PlayerFrame or UIParent
end

local function SaveArrowPos()
    local ref = GetReferencePartyFrame()
    local left = arrowPreview:GetLeft()
    local _, centerY = arrowPreview:GetCenter()
    local refRight = ref:GetRight()
    local _, refCenterY = ref:GetCenter()
    if not left or not centerY or not refRight or not refCenterY then return end

    local db = PartyDebuffAlertDB or PDA.defaults
    db.arrowOffsetX = math.floor(left - refRight + 0.5)
    db.arrowOffsetY = math.floor(centerY - refCenterY + 0.5)

    if PDA_RefreshAllPartyArrows then
        PDA_RefreshAllPartyArrows()
    end
end

local function ApplyArrowPreviewPos()
    local db = PartyDebuffAlertDB or PDA.defaults
    local ox = db.arrowOffsetX or 4
    local oy = db.arrowOffsetY or 0
    local ref = GetReferencePartyFrame()
    arrowPreview:ClearAllPoints()
    arrowPreview:SetPoint("LEFT", ref, "RIGHT", ox, oy)
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
    arrowPreview:SetFrameLevel(15)
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