-- PartyDebuffAlert_PartyArrows.lua
-- Language: Lua
-- Shows a coloured arrow to the right of the party frame for members with
-- a dispellable debuff. One arrow per unit, re-coloured per debuff type.

local PDA = PartyDebuffAlert

-- Maps party unit token -> the arrow frame for that slot
local arrows = {}

-- Arrow size
local ARROW_W = 16
local ARROW_H = 24

-- The party frame names used by the default Blizzard UI
local unitFrameNames = {
    player   = "PlayerFrame",
    party1   = "PartyMemberFrame1",
    party2   = "PartyMemberFrame2",
    party3   = "PartyMemberFrame3",
    party4   = "PartyMemberFrame4",
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
    return c.r, c.g, c.b
end

-- Build a right-pointing arrow texture from two triangles using Line primitives.
-- We draw it as a simple ► shape using a plain texture rotated, since WoW
-- does not have a built-in arrow. We use a TextureCoord trick on WHITE8X8
-- to get a solid block, then mask it into a triangle shape by overlaying
-- a rotated texture. For maximum compat we simply use the game's own
-- directional arrow texture.
local function CreateArrow(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(ARROW_W, ARROW_H)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(10)

    -- Use the raid target / UI arrow texture that exists in all clients
    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(f)
    -- Interface\Minimap\ROTATING-MINIMAPARROW is a directional arrow present
    -- in every WoW client. We rotate it 90° to point right.
    tex:SetTexture("Interface\\Minimap\\ROTATING-MINIMAPARROW")
    tex:SetRotation(math.rad(-90))  -- default points up; rotate to point right

    f.tex = tex
    f:Hide()
    return f
end

local function GetOrCreateArrow(unit)
    if arrows[unit] then return arrows[unit] end

    local frameName = unitFrameNames[unit]
    local parent    = frameName and _G[frameName]
    if not parent then
        -- Frame doesn't exist yet; use UIParent and position manually later
        parent = UIParent
    end

    local arrow = CreateArrow(parent)
    arrows[unit] = arrow
    return arrow
end

local function PositionArrow(arrow, unit)
    local frameName = unitFrameNames[unit]
    local anchor    = frameName and _G[frameName]
    if not anchor then
        arrow:Hide()
        return
    end
    local ox, oy = PDA_GetArrowOffset()
    arrow:ClearAllPoints()
    arrow:SetPoint("LEFT", anchor, "RIGHT", ox, oy)
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Called from core when a debuff is detected or cleared on a unit.
-- debuffType is the type string (or nil when clearing), show is true/false.
function PDA_UpdatePartyArrow(unit, debuffType, show)
    local db = PartyDebuffAlertDB or PDA.defaults
    if not db.showPartyArrows then
        -- Setting off – ensure arrow is hidden and bail
        local existing = arrows[unit]
        if existing then existing:Hide() end
        return
    end

    local arrow = GetOrCreateArrow(unit)

    if not show or not debuffType then
        arrow:Hide()
        return
    end

    PositionArrow(arrow, unit)

    local r, g, b = GetTypeColor(debuffType)
    arrow.tex:SetVertexColor(r, g, b)
    arrow:Show()
end

-- Reposition all visible arrows (called after UI reload / party roster change)
local function RefreshAllArrows()
    for unit, arrow in pairs(arrows) do
        if arrow:IsShown() then
            PositionArrow(arrow, unit)
        end
    end
end

-- Hide all arrows (e.g. when debuffs are wiped on group change)
function PDA_HideAllPartyArrows()
    for _, arrow in pairs(arrows) do
        arrow:Hide()
    end
end

-- Hook GROUP_ROSTER_UPDATE to reposition arrows when frames move
local arrowFrame = CreateFrame("Frame")
arrowFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
arrowFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
arrowFrame:SetScript("OnEvent", function()
    PDA_HideAllPartyArrows()
end)
