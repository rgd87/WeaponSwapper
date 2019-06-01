local addonName, ns = ...

-- local WeaponSwapper = CreateFrame("Button","WeaponSwapper", UIParent, "SecureActionButtonTemplate")
local WeaponSwapper = CreateFrame("Frame","WeaponSwapper", UIParent)
local WeaponSwapperDB
-- WeaponSwapper:SetAttribute("type1", "macro")

-- local macroBtn = CreateFrame("Button", "myMacroButton", UIParent, "SecureActionButtonTemplate")
-- macroBtn:SetAttribute("type1", "macro") -- left click causes macro
-- macroBtn:SetAttribute("macrotext1", "/raid zomg a left click!")

WeaponSwapper:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, event, ...)
end)

WeaponSwapper:RegisterEvent("PLAYER_LOGIN")
WeaponSwapper:RegisterEvent("PLAYER_LOGOUT")

-- BINDING_HEADER_WEAPONSWAPPER = "WeaponSwapper"
-- setglobal("BINDING_NAME_CLICK WeaponSwapper:LeftButton", "Swap weapons")


local function SetupDefaults(t, defaults)
    for k,v in pairs(defaults) do
        if type(v) == "table" then
            if t[k] == nil then
                t[k] = CopyTable(v)
            else
                SetupDefaults(t[k], v)
            end
        else
            if t[k] == nil then t[k] = v end
        end
    end
end
local function RemoveDefaults(t, defaults)
    for k, v in pairs(defaults) do
        if type(t[k]) == 'table' and type(v) == 'table' then
            RemoveDefaults(t[k], v)
            if next(t[k]) == nil then
                t[k] = nil
            end
        elseif t[k] == v then
            t[k] = nil
        end
    end
    return t
end

local defaults = {
    sets = {
        {},
        {},
    },
}

function WeaponSwapper:PLAYER_LOGIN(event)
    _G.WeaponSwapperDB = _G.WeaponSwapperDB or {}
    WeaponSwapperDB = _G.WeaponSwapperDB
    SetupDefaults(WeaponSwapperDB, defaults)

    self:CreateCharacterPanelButtons()

    SLASH_WEAPONSWAPPER1= "/wswap"
    SlashCmdList["WEAPONSWAPPER"] = ns.SlashHandler
end
function WeaponSwapper:PLAYER_LOGOUT(event)
    RemoveDefaults(WeaponSwapperDB, defaults)
end

-- local translateEquipLoc = function(equipLoc)
--     if equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_OFFHAND" then
--         return "oh"
--     elseif equipLoc == "INVTYPE_MAINHANDWEAPON" then
--         return "mh"
--     elseif equipLoc == "INVTYPE_WEAPON" then
--         return "1h"
--     elseif equipLoc == "INVTYPE_2HWEAPON" then
--         return "2h"
--     end
-- end

local MakeMacroLine = function(slot, conditionalWeaponType, conditionalPositive, link)
    local conditionalFormat = conditionalPositive and "[equipped:%s]" or "[noequipped:%s]"
    local conditional = string.format(conditionalFormat, conditionalWeaponType)
    local _, _, localWeaponType, itemEquipLoc = GetItemInfoInstant(link)
    local name = GetItemInfo(link)
    return string.format("/equipslot %s %d %s", conditional, slot, name)
end

local DecideConditional = function(mhl, ohl)
    if ohl then
        local _, _, localWeaponType, itemEquipLoc = GetItemInfoInstant(ohl)
        return localWeaponType
    elseif mhl then
        local _, _, localWeaponType, itemEquipLoc = GetItemInfoInstant(mhl)
        return localWeaponType
    end
end

function WeaponSwapper:PLAYER_REGEN_ENABLED()
    self:UpdateMacro()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

function WeaponSwapper:UpdateMacro()
    if InCombatLockdown() then
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end


    local sets = WeaponSwapperDB.sets
    local mhl1, ohl1 = unpack(sets[1])
    local mhl2, ohl2 = unpack(sets[2])
    if mhl1 == mhl2 then
        mhl1 = nil
        mhl2 = nil
    end
    if ohl1 == ohl2 then
        ohl1 = nil
        ohl2 = nil
    end

    local haveSet2 = mhl2 or ohl2
    local haveSet1 = mhl1 or ohl1

    if not (haveSet1 and haveSet2) then return end

    local conditionalWeaponType = DecideConditional(mhl2, ohl2)

    local t = {}

    if ohl2 then
        table.insert(t, MakeMacroLine(17, conditionalWeaponType, false, ohl2))
    end
    if mhl2 then
        table.insert(t, MakeMacroLine(16, conditionalWeaponType, false, mhl2))
    end
    if ohl1 then
        table.insert(t, MakeMacroLine(17, conditionalWeaponType, true, ohl1))
    end
    if mhl1 then
        table.insert(t, MakeMacroLine(16, conditionalWeaponType, true, mhl1))
    end
    local body = table.concat(t, '\n')

    local macroname = "WeaponSwap"
    local index = GetMacroIndexByName(macroname)
    if index == 0 then
        local perCharacter = true
        index = CreateMacro(macroname, 135882, body, perCharacter)
        if not index or index == 0 then return end
    end

    print("NEW MACRO")
    print("============")
    for _, line in ipairs(t) do
        print(line)
    end

    EditMacro(index, nil, nil, body)
end

function WeaponSwapper:SaveSet(setID)
    local mhLink = GetInventoryItemLink("player", INVSLOT_MAINHAND)
    local ohLink = GetInventoryItemLink("player", INVSLOT_OFFHAND)
    WeaponSwapperDB.sets[setID] = { mhLink, ohLink }
end

function ns.SlashHandler(args)
    if args == "" then return UpdateMacro() end
    local setNum = tonumber(args)
    if not setNum then return end

    WeaponSwapper:SaveSet(setNum)
    WeaponSwapper:UpdateMacro()
end

function WeaponSwapper:CreateCharacterPanelButtons()
    local button1 = CreateFrame("Button", nil, PaperDollFrame, "UIPanelButtonTemplate")
    button1:SetText("1")
    button1:SetSize(25, 25)
    button1.swappingSlot = 1
    button1:SetScript("OnClick", function()
        WeaponSwapper:SaveSet(1)
        WeaponSwapper:UpdateMacro()
    end)
    button1:SetPoint("BOTTOMLEFT", PaperDollFrame, "BOTTOMLEFT", 63, 85)

    local button2 = CreateFrame("Button", nil, PaperDollFrame, "UIPanelButtonTemplate")
    button2:SetText("2")
    button2:SetSize(25, 25)
    button2.swappingSlot = 2
    button2:SetScript("OnClick", function()
        WeaponSwapper:SaveSet(2)
        WeaponSwapper:UpdateMacro()
    end)
    button2:SetPoint("BOTTOMLEFT", button1, "BOTTOMRIGHT", 0, 0)

    local TooltipShow = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText(string.format("Save currently equipped weapons as WeasponSwapper Set %d", self.swappingSlot), nil, nil, nil, nil, 1);
        GameTooltip:Show();
    end
    local TooltipHide = function(self)
        GameTooltip:Hide();
    end
    button1:SetScript("OnEnter", TooltipShow)
    button1:SetScript("OnLeave", TooltipHide)
    button2:SetScript("OnEnter", TooltipShow)
    button2:SetScript("OnLeave", TooltipHide)
end