-- PartyDebuffAlert.lua
-- Language: Lua

PartyDebuffAlert = {}
local PDA = PartyDebuffAlert

local function DeepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = (type(v) == "table") and DeepCopy(v) or v
    end
    return copy
end
PDA.DeepCopy = DeepCopy

PDA.defaults = {
    enabled         = true,
    trackMagic      = true,
    trackCurse      = true,
    trackPoison     = true,
    trackDisease    = true,
    displayDuration = 4,
    minimapAngle    = 225,
    -- Alert popup anchor (offsets from UIParent CENTER)
    alertX          = 0,
    alertY          = 80,
    showPartyArrows = true,
    arrowOffsetX    = 4,
    arrowOffsetY    = 0,
    colorMagic      = { useColor = true, r = 0.20, g = 0.60, b = 1.00 },
    colorCurse      = { useColor = true, r = 0.70, g = 0.00, b = 1.00 },
    colorPoison     = { useColor = true, r = 0.00, g = 0.80, b = 0.20 },
    colorDisease    = { useColor = true, r = 0.60, g = 0.40, b = 0.00 },
}

PDA.classDispels = {
    PRIEST  = { Magic = true, Disease = true },
    PALADIN = { Magic = true, Poison = true, Disease = true },
    DRUID   = { Curse = true, Poison = true },
    MAGE    = { Curse = true },
    SHAMAN  = { Curse = true, Poison = true },
    MONK    = { Magic = true, Poison = true, Disease = true },
    EVOKER  = { Magic = true, Curse = true },
}

PDA.activeAlerts = {}
local wasInGroup = false

local function PrintClassMessage()
    local _, playerClass = UnitClass("player")
    if not playerClass then return end
    local dispelTypes = PDA.classDispels[playerClass]
    local className = playerClass:sub(1,1):upper() .. playerClass:sub(2):lower()
    if dispelTypes then
        local list = {}
        for dtype in pairs(dispelTypes) do
            table.insert(list, dtype)
        end
        table.sort(list)
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ccff[PartyDebuffAlert]|r " .. className ..
            " detected - Alerting for: |cffffd700" .. table.concat(list, ", ") .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ccff[PartyDebuffAlert]|r " .. className ..
            " has no dispel abilities - alerts disabled.")
    end
end

local function GetDB()
    return PartyDebuffAlertDB or PDA.defaults
end

local function GetPlayerDispelTypes()
    local _, playerClass = UnitClass("player")
    return PDA.classDispels[playerClass]
end

local function IsTrackedType(debuffType)
    local db = GetDB()
    if debuffType == "Magic"   then return db.trackMagic   end
    if debuffType == "Curse"   then return db.trackCurse   end
    if debuffType == "Poison"  then return db.trackPoison  end
    if debuffType == "Disease" then return db.trackDisease end
    return false
end

local function ScanUnit(unit)
    if not UnitExists(unit) or UnitIsDead(unit) then return end
    local dispelTypes = GetPlayerDispelTypes()
    if not dispelTypes then return end
    local db = GetDB()
    if not db.enabled then return end
    local unitName = UnitName(unit) or unit

    for i = 1, 40 do
        local name, _, _, debuffType, _, _, _, _, _, spellId = UnitDebuff(unit, i)
        if not name then break end
        if debuffType and debuffType ~= "" then
            local dtype = debuffType:sub(1,1):upper() .. debuffType:sub(2):lower()
            if dispelTypes[dtype] and IsTrackedType(dtype) then
                local alertKey = unit .. "_" .. (spellId or name)
                if not PDA.activeAlerts[alertKey] then
                    PDA.activeAlerts[alertKey] = true
                    PDA_ShowAlert(unitName, dtype, name)
                    PDA_UpdatePartyArrow(unit, dtype, true)
                end
            end
        end
    end
end

local function ClearExpiredAlerts(unit)
    local stillPresent = {}
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellId = UnitDebuff(unit, i)
        if not name then break end
        stillPresent[unit .. "_" .. (spellId or name)] = true
    end
    local anyCleared = false
    for key in pairs(PDA.activeAlerts) do
        if key:find("^" .. unit .. "_") and not stillPresent[key] then
            PDA.activeAlerts[key] = nil
            anyCleared = true
        end
    end
    if anyCleared then
        PDA_UpdatePartyArrow(unit, nil, false)
    end
end

local function ScanAll()
    ScanUnit("player")
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            ScanUnit(unit)
            ClearExpiredAlerts(unit)
        end
    end
    ClearExpiredAlerts("player")
end

-- ── Event frame ───────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame", "PDA_EventFrame", UIParent)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)

    if event == "ADDON_LOADED" then
        if arg1 ~= "PartyDebuffAlert" then return end
        if not PartyDebuffAlertDB then
            PartyDebuffAlertDB = DeepCopy(PDA.defaults)
        else
            for k, v in pairs(PDA.defaults) do
                if PartyDebuffAlertDB[k] == nil then
                    PartyDebuffAlertDB[k] = (type(v) == "table") and DeepCopy(v) or v
                end
            end
        end
        PDA_BuildConfigUI()

    elseif event == "UNIT_AURA" then
        if arg1 == "player" or (arg1 and arg1:find("^party%d$")) then
            ScanAll()
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        wipe(PDA.activeAlerts)
        ScanAll()
        local inGroup = IsInGroup()
        if inGroup and not wasInGroup then
            PrintClassMessage()
        end
        wasInGroup = inGroup

    elseif event == "PLAYER_ENTERING_WORLD" then
        wipe(PDA.activeAlerts)
        ScanAll()

    elseif event == "PLAYER_LOGIN" then
        PrintClassMessage()

end)

SLASH_PARTYDEBUFFALERT1 = "/pdebuff"
SLASH_PARTYDEBUFFALERT2 = "/partydebuff"
SlashCmdList["PARTYDEBUFFALERT"] = function()
    if PDA_ConfigFrame:IsShown() then
        PDA_ConfigFrame:Hide()
    else
        PDA_ConfigFrame:Show()
    end
end
