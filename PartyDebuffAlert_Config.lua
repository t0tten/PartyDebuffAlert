-- PartyDebuffAlert_Config.lua
-- Language: Lua
-- Configuration panel. Compatible with WoW Forever (1.6x).
-- No CopyTable, no InsetFrame assumptions.

local PDA = PartyDebuffAlert

local function SafeCreateFrame(frameType, name, parent, template)
    if template then
        local ok, frame = pcall(CreateFrame, frameType, name, parent, template)
        if ok and frame then
            return frame
        end
    end
    return CreateFrame(frameType, name, parent)
end

local function SafeSetFont(fontString, preferredFont, fallbackFont)
    if not fontString or not fontString.SetFontObject then return end
    if preferredFont and _G[preferredFont] then
        fontString:SetFontObject(preferredFont)
    elseif fallbackFont and _G[fallbackFont] then
        fontString:SetFontObject(fallbackFont)
    end
end

-- ── Main frame ────────────────────────────────────────────────────────────────

local cfg = SafeCreateFrame("Frame", "PDA_ConfigFrame", UIParent, "BasicFrameTemplateWithInset")
cfg:SetSize(360, 440)
cfg:SetPoint("CENTER")
cfg:SetMovable(true)
cfg:EnableMouse(true)
cfg:RegisterForDrag("LeftButton")
cfg:SetScript("OnDragStart", cfg.StartMoving)
cfg:SetScript("OnDragStop",  cfg.StopMovingOrSizing)
cfg:SetFrameStrata("DIALOG")
cfg:Hide()

-- Säkerställ enkel bakgrund även om template saknar en
local cfgBg = cfg:CreateTexture(nil, "BACKGROUND")
cfgBg:SetAllPoints(cfg)
cfgBg:SetColorTexture(0.06, 0.06, 0.10, 0.92)

local titleObj = cfg.TitleText or cfg:CreateFontString(nil, "OVERLAY")
if not cfg.TitleText then
    titleObj:SetPoint("TOP", cfg, "TOP", 0, -10)
end
SafeSetFont(titleObj, "GameFontNormal", "GameFontHighlight")
titleObj:SetText("PartyDebuffAlert - Configuration")

_G["PDA_ConfigFrame"] = cfg
PDA.configFrame = cfg

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function GetCheckboxText(cb)
    if not cb then return nil end
    if cb.Text then return cb.Text end
    if cb.text then return cb.text end
    local name = cb:GetName()
    if name and _G[name .. "Text"] then
        return _G[name .. "Text"]
    end
    for _, region in ipairs({ cb:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "FontString" then
            return region
        end
    end
    return nil
end

local function MakeCheckbox(parent, label, x, y, getVal, setVal)
    local cb = SafeCreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(24, 24)

    local textObj = GetCheckboxText(cb)
    if textObj then
        textObj:SetText(label)
        SafeSetFont(textObj, "GameFontHighlight", "GameFontNormal")
    else
        local fallbackLabel = parent:CreateFontString(nil, "OVERLAY")
        fallbackLabel:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        SafeSetFont(fallbackLabel, "GameFontHighlight", "GameFontNormal")
        fallbackLabel:SetText(label)
    end

    local initial = getVal and getVal() or false
    cb:SetChecked(initial and true or false)
    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        if setVal then setVal(checked) end
    end)
    return cb
end

local sliderSeq = 0
local function NewSlider(parent, label, minVal, maxVal, x, y, width, getVal, setVal, fmtFn)
    sliderSeq = sliderSeq + 1
    local sName = "PDA_S" .. sliderSeq
    local s = SafeCreateFrame("Slider", sName, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    s:SetWidth(width)
    s:SetMinMaxValues(minVal, maxVal)
    if s.SetValueStep then s:SetValueStep(1) end
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end

    local initVal = (getVal and getVal()) or minVal
    s:SetValue(initVal)

    local topText = _G[sName .. "Text"]
    if not topText then
        topText = s:CreateFontString(nil, "OVERLAY")
        topText:SetPoint("BOTTOM", s, "TOP", 0, 2)
        SafeSetFont(topText, "GameFontNormalSmall", "GameFontNormal")
    end
    topText:SetText(label)

    local lowText = _G[sName .. "Low"]
    if not lowText then
        lowText = s:CreateFontString(nil, "ARTWORK")
        lowText:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, 0)
        SafeSetFont(lowText, "GameFontHighlightSmall", "GameFontNormal")
    end
    lowText:SetText(tostring(minVal))

    local highText = _G[sName .. "High"]
    if not highText then
        highText = s:CreateFontString(nil, "ARTWORK")
        highText:SetPoint("TOPRIGHT", s, "BOTTOMRIGHT", 0, 0)
        SafeSetFont(highText, "GameFontHighlightSmall", "GameFontNormal")
    end
    highText:SetText(tostring(maxVal))

    local vt = s:CreateFontString(nil, "OVERLAY")
    vt:SetPoint("TOP", s, "BOTTOM", 0, 2)
    SafeSetFont(vt, "GameFontHighlightSmall", "GameFontNormal")

    local function fmt(v) return fmtFn and fmtFn(v) or tostring(v) end
    vt:SetText(fmt(initVal))

    s:SetScript("OnValueChanged", function(self, val)
        local v = math.floor((val or minVal) + 0.5)
        if setVal then setVal(v) end
        vt:SetText(fmt(v))
    end)
    return s
end

local function MakeRGBSlider(parent, label, x, y, width, getVal, setVal)
    return NewSlider(parent, label, 0, 255, x, y, width,
        function() return math.floor((getVal() or 0) * 255 + 0.5) end,
        function(v) setVal(v / 255) end)
end

local function Header(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    SafeSetFont(fs, "GameFontNormalLarge", "GameFontNormal")
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

local uiBuilt = false

function PDA_BuildConfigUI()
    if uiBuilt then return end
    uiBuilt = true

    local db = PartyDebuffAlertDB or PDA.defaults

    -- Tab buttons sit just below the title bar
    local tabDefs = {
        { label = "General", name = "general", x = 10  },
        { label = "Colors",  name = "colors",  x = 112 },
        { label = "Preview", name = "preview", x = 214 },
    }
    for _, t in ipairs(tabDefs) do
        local b = SafeCreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
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
            if not v and PDA_HideAllPartyArrows then PDA_HideAllPartyArrows() end
        end)

    NewSlider(gen, "Alert display duration", 1, 10, 8, -210, 300,
        function() return db.displayDuration end,
        function(v) db.displayDuration = v end,
        function(v) return v .. " sec" end)

    -- Edit Mode button + Done button (both visible in the panel, not requiring config to close)
    local editBtn = SafeCreateFrame("Button", nil, gen, "UIPanelButtonTemplate")
    editBtn:SetSize(160, 28)
    editBtn:SetPoint("TOPLEFT", gen, "TOPLEFT", 8, -262)
    editBtn:SetText("Edit Mode")

    local doneEditBtn = SafeCreateFrame("Button", nil, gen, "UIPanelButtonTemplate")
    doneEditBtn:SetSize(160, 28)
    doneEditBtn:SetPoint("TOPLEFT", gen, "TOPLEFT", 8, -262)
    doneEditBtn:SetText("Save Positions")
    doneEditBtn:Hide()

    editBtn:SetScript("OnClick", function()
        editBtn:Hide()
        doneEditBtn:Show()
        if PDA_EnterEditMode then PDA_EnterEditMode() end
    end)
    doneEditBtn:SetScript("OnClick", function()
        doneEditBtn:Hide()
        editBtn:Show()
        if PDA_ExitEditMode then PDA_ExitEditMode(true) end
    end)

    local edithint = gen:CreateFontString(nil, "OVERLAY")
    edithint:SetPoint("TOPLEFT", gen, "TOPLEFT", 8, -295)
    SafeSetFont(edithint, "GameFontDisableSmall", "GameFontNormal")
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
        local cdb = db[entry.key] or { useColor = true, r = 1, g = 1, b = 1 }
        db[entry.key] = cdb

        local hdr = col:CreateFontString(nil, "OVERLAY")
        hdr:SetPoint("TOPLEFT", col, "TOPLEFT", 8, y)
        SafeSetFont(hdr, "GameFontNormalLarge", "GameFontNormal")
        hdr:SetText(entry.label)

        local swatch = col:CreateTexture(nil, "OVERLAY")
        swatch:SetSize(14, 14)
        swatch:SetPoint("LEFT", hdr, "RIGHT", 6, 0)
        swatch:SetTexture("Interface\\Buttons\\WHITE8X8")

        local function RefreshSwatch()
            swatch:SetVertexColor(cdb.r or 1, cdb.g or 1, cdb.b or 1)
            swatch:SetAlpha(cdb.useColor and 1 or 0.25)
        end
        RefreshSwatch()

        MakeCheckbox(col, "Use colour", 8, y - 18,
            function() return cdb.useColor end,
            function(v) cdb.useColor = v; RefreshSwatch() end)

        MakeRGBSlider(col, "R", 8,   y - 48, 90,
            function() return cdb.r end, function(v) cdb.r = v; RefreshSwatch() end)
        MakeRGBSlider(col, "G", 108, y - 48, 90,
            function() return cdb.g end, function(v) cdb.g = v; RefreshSwatch() end)
        MakeRGBSlider(col, "B", 208, y - 48, 90,
            function() return cdb.b end, function(v) cdb.b = v; RefreshSwatch() end)
    end

    -- ════════════════════════════════════════════════════════════════════════
    -- PREVIEW
    -- ════════════════════════════════════════════════════════════════════════
    local prev = MakePage()
    pages["preview"] = prev

    local desc = prev:CreateFontString(nil, "OVERLAY")
    desc:SetPoint("TOPLEFT", prev, "TOPLEFT", 8, -8)
    desc:SetWidth(320)
    desc:SetJustifyH("LEFT")
    SafeSetFont(desc, "GameFontHighlight", "GameFontNormal")
    desc:SetText("Click a button below to preview the alert animation\nfor that debuff type.")

    local previewTypes = { "Magic", "Curse", "Poison", "Disease" }
    for i, dtype in ipairs(previewTypes) do
        local col_i = (i - 1) % 2
        local row_i = math.floor((i - 1) / 2)
        local pb = SafeCreateFrame("Button", nil, prev, "UIPanelButtonTemplate")
        pb:SetSize(152, 36)
        pb:SetPoint("TOPLEFT", prev, "TOPLEFT", 8 + col_i * 162, -60 - row_i * 48)
        pb:SetText(dtype)
        local dt = dtype
        pb:SetScript("OnClick", function()
            if PDA_TestAlert then PDA_TestAlert(dt) end
        end)
        pb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Preview " .. dt .. " alert", 1, 1, 1)
            GameTooltip:Show()
        end)
        pb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- ── Bottom bar ────────────────────────────────────────────────────────────
    local resetBtn = SafeCreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    resetBtn:SetSize(130, 24)
    resetBtn:SetPoint("BOTTOMLEFT", cfg, "BOTTOMLEFT", 10, 10)
    resetBtn:SetText("Reset to defaults")
    resetBtn:SetScript("OnClick", function()
        PartyDebuffAlertDB = PDA.DeepCopy(PDA.defaults)
        ReloadUI()
    end)

    local hint = cfg:CreateFontString(nil, "OVERLAY")
    hint:SetPoint("BOTTOMRIGHT", cfg, "BOTTOMRIGHT", -10, 14)
    SafeSetFont(hint, "GameFontDisableSmall", "GameFontNormal")
    hint:SetText("/pdebuff to toggle")

    ShowPage("general")
    if PDA_ApplyAlertPosition then
        PDA_ApplyAlertPosition()
    end
end