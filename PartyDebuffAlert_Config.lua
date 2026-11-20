-- PartyDebuffAlert_Config.lua
-- Language: Lua
-- Configuration panel. Compatible with WoW Forever (1.6x).
-- No CopyTable, no InsetFrame assumptions.

local PDA = PartyDebuffAlert

-- ── Main frame ────────────────────────────────────────────────────────────────

local cfg = CreateFrame("Frame", "PDA_ConfigFrame", UIParent, "BasicFrameTemplateWithInset")
cfg:SetSize(360, 440)
cfg:SetPoint("CENTER")
cfg:SetMovable(true)
cfg:EnableMouse(true)
cfg:RegisterForDrag("LeftButton")
cfg:SetScript("OnDragStart", cfg.StartMoving)
cfg:SetScript("OnDragStop",  cfg.StopMovingOrSizing)
cfg:SetFrameStrata("DIALOG")
cfg:Hide()
cfg.TitleText:SetText("PartyDebuffAlert - Configuration")

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function MakeCheckbox(parent, label, x, y, getVal, setVal)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(24, 24)
    cb.text:SetText(label)
    cb.text:SetFontObject("GameFontHighlight")
    cb:SetChecked(getVal())
    cb:SetScript("OnClick", function(self) setVal(self:GetChecked()) end)
    return cb
end

local sliderSeq = 0
local function NewSlider(parent, label, minVal, maxVal, x, y, width, getVal, setVal, fmtFn)
    sliderSeq = sliderSeq + 1
    local s = CreateFrame("Slider", "PDA_S"..sliderSeq, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    s:SetWidth(width)
    s:SetMinMaxValues(minVal, maxVal)
    s:SetValueStep(1)
    s:SetObeyStepOnDrag(true)
    s:SetValue(getVal())
    _G["PDA_S"..sliderSeq.."Text"]:SetText(label)
    _G["PDA_S"..sliderSeq.."Low"]:SetText(tostring(minVal))
    _G["PDA_S"..sliderSeq.."High"]:SetText(tostring(maxVal))
    local vt = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    vt:SetPoint("TOP", s, "BOTTOM", 0, 2)
    local function fmt(v) return fmtFn and fmtFn(v) or tostring(v) end
    vt:SetText(fmt(getVal()))
    s:SetScript("OnValueChanged", function(self, val)
        local v = math.floor(val + 0.5)
        setVal(v)
        vt:SetText(fmt(v))
    end)
    return s
end

local function MakeRGBSlider(parent, label, x, y, width, getVal, setVal)
    return NewSlider(parent, label, 0, 255, x, y, width,
        function() return math.floor(getVal() * 255 + 0.5) end,
        function(v) setVal(v / 255) end)
end

local function Header(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

-- ── Tab system ────────────────────────────────────────────────────────────────

local pages = {}
local function ShowPage(name)
    for k, p in pairs(pages) do
        if k == name then p:Show() else p:Hide() end
    end
end

-- ── Build UI ──────────────────────────────────────────────────────────────────

function PDA_BuildConfigUI()
    local db = PartyDebuffAlertDB

    -- Tab buttons sit just below the title bar
    local tabDefs = {
        { label = "General", name = "general", x = 10  },
        { label = "Colors",  name = "colors",  x = 112 },
        { label = "Preview", name = "preview", x = 214 },
    }
    for _, t in ipairs(tabDefs) do
        local b = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
        b:SetSize(98, 24)
        b:SetPoint("TOPLEFT", cfg, "TOPLEFT", t.x, -28)
        b:SetText(t.label)
        local n = t.name
        b:SetScript("OnClick", function() ShowPage(n) end)
    end

    -- Content pages all share the same region below the tabs
    local function MakePage()
        local p = CreateFrame("Frame", nil, cfg)
        p:SetPoint("TOPLEFT",     cfg, "TOPLEFT",     8,   -58)
        p:SetPoint("BOTTOMRIGHT", cfg, "BOTTOMRIGHT", -8,   40)
        return p
    end

    -- ════════════════════════════════════════════════════════════════════════
    -- GENERAL
    -- ════════════════════════════════════════════════════════════════════════
    local gen = MakePage()
    pages["general"] = gen

    MakeCheckbox(gen, "Enable PartyDebuffAlert", 8, -8,
        function() return db.enabled end,
        function(v) db.enabled = v end)

    Header(gen, "Track debuff types:", 8, -44)

    MakeCheckbox(gen, "Magic",   8, -64,
        function() return db.trackMagic end,
        function(v) db.trackMagic = v end)
    MakeCheckbox(gen, "Curse",   8, -90,
        function() return db.trackCurse end,
        function(v) db.trackCurse = v end)
    MakeCheckbox(gen, "Poison",  8, -116,
        function() return db.trackPoison end,
        function(v) db.trackPoison = v end)
    MakeCheckbox(gen, "Disease", 8, -142,
        function() return db.trackDisease end,
        function(v) db.trackDisease = v end)

    MakeCheckbox(gen, "Show party frame arrows", 8, -172,
        function() return db.showPartyArrows end,
        function(v)
            db.showPartyArrows = v
            if not v then PDA_HideAllPartyArrows() end
        end)

    NewSlider(gen, "Alert display duration", 1, 10, 8, -210, 300,
        function() return db.displayDuration end,
        function(v) db.displayDuration = v end,
        function(v) return v .. " sec" end)

    -- Edit Mode button + Done button (both visible in the panel, not requiring config to close)
    local editBtn = CreateFrame("Button", nil, gen, "UIPanelButtonTemplate")
    editBtn:SetSize(160, 28)
    editBtn:SetPoint("TOPLEFT", gen, "TOPLEFT", 8, -262)
    editBtn:SetText("⚙  Edit Mode")

    local doneEditBtn = CreateFrame("Button", nil, gen, "UIPanelButtonTemplate")
    doneEditBtn:SetSize(160, 28)
    doneEditBtn:SetPoint("TOPLEFT", gen, "TOPLEFT", 8, -262)
    doneEditBtn:SetText("✓  Save Positions")
    doneEditBtn:Hide()

    editBtn:SetScript("OnClick", function()
        editBtn:Hide()
        doneEditBtn:Show()
        PDA_EnterEditMode()
    end)
    doneEditBtn:SetScript("OnClick", function()
        doneEditBtn:Hide()
        editBtn:Show()
        PDA_ExitEditMode(true) -- true = keep config open
    end)

    local edithint = gen:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    edithint:SetPoint("TOPLEFT", gen, "TOPLEFT", 8, -295)
    edithint:SetText("Move the alert and arrow to any screen position")

    -- ════════════════════════════════════════════════════════════════════════
    -- COLORS
    -- ════════════════════════════════════════════════════════════════════════
    local col = MakePage()
    pages["colors"] = col

    local typeList = {
        { label = "Magic",   key = "colorMagic"   },
        { label = "Curse",   key = "colorCurse"   },
        { label = "Poison",  key = "colorPoison"  },
        { label = "Disease", key = "colorDisease" },
    }

    for i, entry in ipairs(typeList) do
        local y   = -8 - (i - 1) * 82
        local cdb = db[entry.key]

        local hdr = col:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
        hdr:SetPoint("TOPLEFT", col, "TOPLEFT", 8, y)
        hdr:SetText(entry.label)

        local swatch = col:CreateTexture(nil, "OVERLAY")
        swatch:SetSize(14, 14)
        swatch:SetPoint("LEFT", hdr, "RIGHT", 6, 0)

        swatch:SetTexture("Interface\\Buttons\\WHITE8X8")

        local function RefreshSwatch()
            swatch:SetVertexColor(cdb.r, cdb.g, cdb.b)
            swatch:SetAlpha(cdb.useColor and 1 or 0.25)
        end
        RefreshSwatch()

        MakeCheckbox(col, "Use colour", 8, y - 18,
            function() return cdb.useColor end,
            function(v) cdb.useColor = v; RefreshSwatch() end)

        MakeRGBSlider(col, "R", 8,   y - 48, 90,
            function() return cdb.r end, function(v) cdb.r=v; RefreshSwatch() end)
        MakeRGBSlider(col, "G", 108, y - 48, 90,
            function() return cdb.g end, function(v) cdb.g=v; RefreshSwatch() end)
        MakeRGBSlider(col, "B", 208, y - 48, 90,
            function() return cdb.b end, function(v) cdb.b=v; RefreshSwatch() end)
    end

    -- ════════════════════════════════════════════════════════════════════════
    -- PREVIEW
    -- ════════════════════════════════════════════════════════════════════════
    local prev = MakePage()
    pages["preview"] = prev

    local desc = prev:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", prev, "TOPLEFT", 8, -8)
    desc:SetWidth(320)
    desc:SetJustifyH("LEFT")
    desc:SetText("Click a button below to preview the alert animation\nfor that debuff type.")

    local previewTypes = { "Magic", "Curse", "Poison", "Disease" }
    for i, dtype in ipairs(previewTypes) do
        local col_i = (i - 1) % 2
        local row_i = math.floor((i - 1) / 2)
        local pb = CreateFrame("Button", nil, prev, "UIPanelButtonTemplate")
        pb:SetSize(152, 36)
        pb:SetPoint("TOPLEFT", prev, "TOPLEFT", 8 + col_i * 162, -60 - row_i * 48)
        pb:SetText(dtype)
        local dt = dtype
        pb:SetScript("OnClick", function() PDA_TestAlert(dt) end)
        pb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Preview " .. dt .. " alert", 1, 1, 1)
            GameTooltip:Show()
        end)
        pb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- ── Bottom bar ────────────────────────────────────────────────────────────
    local resetBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    resetBtn:SetSize(130, 24)
    resetBtn:SetPoint("BOTTOMLEFT", cfg, "BOTTOMLEFT", 10, 10)
    resetBtn:SetText("Reset to defaults")
    resetBtn:SetScript("OnClick", function()
        for k, v in pairs(PDA.defaults) do
            PartyDebuffAlertDB[k] = type(v) == "table" and PDA.DeepCopy(v) or v
        end
        PDA_BuildConfigUI = function() end
        ReloadUI()
    end)

    local hint = cfg:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMRIGHT", cfg, "BOTTOMRIGHT", -10, 14)
    hint:SetText("/pdebuff to toggle")

    ShowPage("general")
    PDA_ApplyAlertPosition()
end
