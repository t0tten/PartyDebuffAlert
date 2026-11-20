-- PartyDebuffAlert_MinimapButton.lua
-- Language: Lua
-- Minimap button that exactly mirrors how LibDBIcon-1.0 (used by Atlas) builds its buttons.

local PDA = PartyDebuffAlert

local DEFAULT_ANGLE = 225

-- ── Position (copied verbatim from LibDBIcon updatePosition) ──────────────────

local minimapShapes = {
    ["ROUND"]                 = {true,  true,  true,  true },
    ["SQUARE"]                = {false, false, false, false},
    ["CORNER-TOPLEFT"]        = {false, false, false, true },
    ["CORNER-TOPRIGHT"]       = {false, false, true,  false},
    ["CORNER-BOTTOMLEFT"]     = {false, true,  false, false},
    ["CORNER-BOTTOMRIGHT"]    = {true,  false, false, false},
    ["SIDE-LEFT"]             = {false, true,  false, true },
    ["SIDE-RIGHT"]            = {true,  false, true,  false},
    ["SIDE-TOP"]              = {false, false, true,  true },
    ["SIDE-BOTTOM"]           = {true,  true,  false, false},
    ["TRICORNER-TOPLEFT"]     = {false, true,  true,  true },
    ["TRICORNER-TOPRIGHT"]    = {true,  false, true,  true },
    ["TRICORNER-BOTTOMLEFT"]  = {true,  true,  false, true },
    ["TRICORNER-BOTTOMRIGHT"] = {true,  true,  true,  false},
}

local RADIUS = 5  -- same lib.radius default as LibDBIcon

local function updatePosition(button, position)
    local angle = math.rad(position or DEFAULT_ANGLE)
    local x, y  = math.cos(angle), math.sin(angle)
    local q     = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    local minimapShape = (GetMinimapShape and GetMinimapShape()) or "ROUND"
    local quadTable    = minimapShapes[minimapShape]
    local w = (Minimap:GetWidth()  / 2) + RADIUS
    local h = (Minimap:GetHeight() / 2) + RADIUS
    if quadTable[q] then
        x, y = x * w, y * h
    else
        local diagW = math.sqrt(2 * w ^ 2) - 10
        local diagH = math.sqrt(2 * h ^ 2) - 10
        x = math.max(-w, math.min(x * diagW, w))
        y = math.max(-h, math.min(y * diagH, h))
    end
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function SaveAngle(angle)
    if PartyDebuffAlertDB then
        PartyDebuffAlertDB.minimapAngle = angle
    end
end

local function LoadAngle()
    if PartyDebuffAlertDB and PartyDebuffAlertDB.minimapAngle then
        return PartyDebuffAlertDB.minimapAngle
    end
    return DEFAULT_ANGLE
end

-- ── Button (parented to Minimap, exactly like LibDBIcon) ──────────────────────

local btn = CreateFrame("Button", "PDA_MinimapButton", Minimap)
btn:SetSize(31, 31)
btn:SetFrameStrata("MEDIUM")
btn:SetFrameLevel(8)
btn:RegisterForClicks("anyUp")
btn:RegisterForDrag("LeftButton")
btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Background: 20x20, offset TOPLEFT 7,-5  (LibDBIcon ResetButtonBackground)
local bg = btn:CreateTexture(nil, "BACKGROUND")
bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
bg:SetSize(20, 20)
bg:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -5)

-- Icon: 17x17, offset TOPLEFT 7,-6  (LibDBIcon ResetButtonIcon)
local icon = btn:CreateTexture(nil, "ARTWORK")
icon:SetTexture("Interface\\Icons\\Spell_Nature_RemoveCurse")
icon:SetSize(17, 17)
icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -6)
-- 5% inset on each side, same as LibDBIcon updateCoord default
icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

-- Border: 53x53, offset TOPLEFT 0,0  (LibDBIcon ResetButtonBorder)
local border = btn:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(53, 53)
border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

-- ── Tooltip ───────────────────────────────────────────────────────────────────

btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("PartyDebuffAlert", 1, 0.82, 0)
    GameTooltip:AddLine("Click to open settings", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag to reposition", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end)

btn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- ── Click ─────────────────────────────────────────────────────────────────────

btn:SetScript("OnClick", function(self, mouseButton)
    if mouseButton == "LeftButton" then
        if PDA_ConfigFrame:IsShown() then
            PDA_ConfigFrame:Hide()
        else
            PDA_ConfigFrame:Show()
        end
    end
end)

-- ── Drag ──────────────────────────────────────────────────────────────────────

btn:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", function(b)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale  = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local pos = math.deg(math.atan2(py - my, px - mx)) % 360
        updatePosition(b, pos)
        SaveAngle(pos)
    end)
end)

btn:SetScript("OnDragStop", function(self)
    self:UnlockHighlight()
    self:SetScript("OnUpdate", nil)
end)

-- ── Init (wait for PLAYER_LOGIN like LibDBIcon does) ─────────────────────────

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self:SetScript("OnEvent", nil)
    updatePosition(btn, LoadAngle())
    btn:Show()
end)
