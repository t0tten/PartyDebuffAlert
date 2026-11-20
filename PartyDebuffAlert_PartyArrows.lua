-- PartyDebuffAlert_PartyArrows.lua
-- Language: Lua
-- Shows a large, coloured, pulsing and gently blinking left-pointing arrow
-- next to each unit frame (player + party1..4) that has a tracked debuff.
-- Stays visible until the tracked debuff expires or is dispelled.

local PDA = PartyDebuffAlert

-- One arrow frame per unit token ("player", "party1", "party2", "party3", "party4")
local arrows = {}

-- Extra-large base size so it stands out immediately in combat
local BASE_W = 64
local BASE_H = 64

-- Noticeable size pulse + clear blink, pointing left toward the unit portrait
local PULSE_SPEED = 7.5
local SCALE_MIN   = 0.85
local SCALE_MAX   = 1.35
local ALPHA_MIN   = 0.35
local ALPHA_MAX   = 1.00
local ARROW_ANGLE = math.rad(90) -- points left toward the frame on the left

-- Standard Blizzard unit frames
local unitFrameNames = {
    player = "PlayerFrame",
    party1 = "PartyMemberFrame1",
    party2 = "PartyMemberFrame2",
    party3 = "PartyMemberFrame3",
    party4 = "PartyMemberFrame4",
}

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

local function ApplyArrowOrientation(tex)
    if not tex then return end
    if tex.SetRotation then
        tex:SetRotation(ARROW_ANGLE)
    elseif tex.SetTexCoord then
        tex:SetTexCoord(0, 1, 1, 0)
    end
end

local function ApplyPulseState(frame, elapsed)
    local wave  = 0.5 + 0.5 * math.sin(elapsed * PULSE_SPEED)
    local scale = SCALE_MIN + (SCALE_MAX - SCALE_MIN) * wave
    local alpha = ALPHA_MIN + (ALPHA_MAX - ALPHA_MIN) * wave

    if frame.tex then
        frame.tex:SetSize(BASE_W * scale, BASE_H * scale)
        frame.tex:SetAlpha(alpha)
        ApplyArrowOrientation(frame.tex)
    end
end

local function CreateArrow(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(BASE_W, BASE_H)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(20)
    f.animTime = 0

    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("CENTER", f, "CENTER", 0, 0)
    tex:SetSize(BASE_W, BASE_H)
    tex:SetTexture("Interface\\Minimap\\ROTATING-MINIMAPARROW")
    ApplyArrowOrientation(tex)

    f.tex = tex

    f:SetScript("OnUpdate", function(self, dt)
        if not self:IsShown() then return end
        self.animTime = (self.animTime or 0) + (dt or 0)
        ApplyPulseState(self, self.animTime)
    end)

    f:SetScript("OnShow", function(self)
        self.animTime = 0
        ApplyPulseState(self, 0)
    end)

    f:Hide()
    return f
end

local function GetAnchorFrame(unit)
    local frameName = unitFrameNames[unit]
    if frameName and _G[frameName] then
        return _G[frameName]
    end
    return nil
end

local function GetOrCreateArrow(unit)
    if arrows[unit] then return arrows[unit] end
    local anchor = GetAnchorFrame(unit)
    local arrow = CreateArrow(anchor or UIParent)
    arrows[unit] = arrow
    return arrow
end

local function PositionArrow(arrow, unit)
    local anchor = GetAnchorFrame(unit)
    if not anchor then
        arrow:Hide()
        return false
    end
    local ox, oy = 4, 0
    if PDA_GetArrowOffset then
        ox, oy = PDA_GetArrowOffset()
    end
    arrow:SetParent(anchor)
    arrow:ClearAllPoints()
    arrow:SetPoint("LEFT", anchor, "RIGHT", ox, oy)
    return true
end

-- ── Public API ────────────────────────────────────────────────────────────────

function PDA_UpdatePartyArrow(unit, debuffType, show)
    if not unit then return end
    local db = PartyDebuffAlertDB or PDA.defaults
    if not db.showPartyArrows then
        local existing = arrows[unit]
        if existing then existing:Hide() end
        return
    end

    local arrow = GetOrCreateArrow(unit)

    if not show or not debuffType then
        arrow:Hide()
        return
    end

    if not PositionArrow(arrow, unit) then
        return
    end

    local r, g, b = GetTypeColor(debuffType)
    arrow.tex:SetVertexColor(r, g, b)
    ApplyArrowOrientation(arrow.tex)
    arrow:Show()
end

function PDA_RefreshAllPartyArrows()
    for unit, arrow in pairs(arrows) do
        if arrow:IsShown() then
            PositionArrow(arrow, unit)
        end
    end
end

function PDA_HideAllPartyArrows()
    for _, arrow in pairs(arrows) do
        arrow:Hide()
    end
end

function PDA_TestPartyArrow(debuffType)
    PDA_UpdatePartyArrow("player", debuffType, true)
end