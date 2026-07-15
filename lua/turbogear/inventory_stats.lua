-- TurboGear/inventory_stats.lua
-- Reads the Inventory window's named Stats-tab labels. This avoids broad UI
-- body scraping; only stable controls from EQUI_Inventory.xml are touched.

local mq = require('mq')

local M = {}

local LABELS = {
    currentHp = { "IWS_CurrentHP", "IW_CurrentHP" },
    hp = { "IWS_MaxHP", "IW_MaxHP" },
    currentMana = { "IWS_CurrentMana", "IW_CurrentMANA" },
    mana = { "IWS_MaxMana", "IW_MaxMANA" },
    currentEndurance = { "IWS_CurrentEndurance", "IW_CurrentENDR" },
    endurance = { "IWS_MaxEndurance", "IW_MaxENDR" },
    ac = { "IWS_CurrentArmorClass", "IW_ACNumber" },
    attack = { "IWS_CurrentAttack", "IW_ATKNumber" },
    haste = { "IWS_CurrentHaste" },

    str = { "IWS_CurrentStrength", "IW_STRNumber" },
    sta = { "IWS_CurrentStamina", "IW_STANumber" },
    agi = { "IWS_CurrentAgility", "IW_AGINumber" },
    dex = { "IWS_CurrentDexterity", "IW_DEXNumber" },
    wis = { "IWS_CurrentWisdom", "IW_WISNumber" },
    int = { "IWS_CurrentIntelligence", "IW_INTNumber" },
    cha = { "IWS_CurrentCharisma", "IW_CHANumber" },

    heroicStr = { "IWS_HeroicStrength" },
    heroicSta = { "IWS_HeroicStamina" },
    heroicAgi = { "IWS_HeroicAgility" },
    heroicDex = { "IWS_HeroicDexterity" },
    heroicWis = { "IWS_HeroicWisdom" },
    heroicInt = { "IWS_HeroicIntelligence" },
    heroicCha = { "IWS_HeroicCharisma" },

    combatEffects = { "IWS_CurrentCombatEffects" },
    shielding = { "IWS_CurrentShielding" },
    spellShield = { "IWS_CurrentSpellShield" },
    dotShielding = { "IWS_CurrentDoTShielding" },
    dsMitigation = { "IWS_CurrentDamageShieldMitigation" },
    avoidance = { "IWS_CurrentAvoidance" },
    accuracy = { "IWS_CurrentAccuracy" },
    stunResist = { "IWS_CurrentStunResist" },
    strikethrough = { "IWS_CurrentStrikeThrough" },
    healAmount = { "IWS_CurrentHealAmount" },
    spellDamage = { "IWS_CurrentSpellDamage" },

    svMagic = { "IWS_CurrentMagic" },
    svFire = { "IWS_CurrentFire" },
    svCold = { "IWS_CurrentCold" },
    svDisease = { "IWS_CurrentDisease" },
    svPoison = { "IWS_CurrentPoison" },
    svCorruption = { "IWS_CurrentCorruption" },
}

local PRINT_ORDER = {
    "hp", "currentHp", "mana", "currentMana", "endurance", "currentEndurance",
    "ac", "attack", "haste",
    "str", "sta", "agi", "dex", "wis", "int", "cha",
    "heroicStr", "heroicSta", "heroicAgi", "heroicDex", "heroicWis", "heroicInt", "heroicCha",
    "shielding", "avoidance", "spellShield", "dotShielding", "dsMitigation",
    "accuracy", "combatEffects", "stunResist", "strikethrough", "healAmount", "spellDamage",
    "svMagic", "svFire", "svCold", "svDisease", "svPoison", "svCorruption",
}

local function clean_text(value)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" or value == "NULL" then return nil end
    value = value:gsub("\r", " "):gsub("\n", " ")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value ~= "" and value or nil
end

local function safe_call(fn)
    local ok, value = pcall(fn)
    if not ok then return nil end
    return clean_text(value)
end

local function window_open()
    return safe_call(function() return mq.TLO.Window("InventoryWindow").Open() end) == "true"
end

local function label_text(control)
    control = tostring(control or "")
    if control == "" then return nil end
    local value = safe_call(function() return mq.TLO.Window("InventoryWindow/" .. control).Text() end)
    if value then return value end
    return safe_call(function()
        local wnd = mq.TLO.Window("InventoryWindow")
        local child = wnd and wnd.Child(control)
        if child then return child.Text() end
        return nil
    end)
end

local function to_number(text)
    text = clean_text(text)
    if not text then return nil end
    text = text:gsub(",", ""):gsub("%%", "")
    local token = text:match("[-+]?%d+")
    return token and tonumber(token) or nil
end

function M.open_stats_page()
    pcall(function()
        local wnd = mq.TLO.Window("InventoryWindow")
        if wnd and wnd.Open and not wnd.Open() then wnd.DoOpen() end
    end)
    pcall(function() mq.delay(120) end)
    -- The Stats page is page 2 in the Project Lazarus inventory XML.
    pcall(function() mq.cmd("/nomodkey /notify InventoryWindow IW_Subwindows tabselect 2") end)
end

function M.capture(opts)
    opts = type(opts) == "table" and opts or {}
    if opts.open == true then M.open_stats_page() end
    local is_open = window_open()
    if not is_open then return nil, {} end

    local stats, raw, count = {}, {}, 0
    for key, controls in pairs(LABELS) do
        for _, control in ipairs(controls) do
            local text = label_text(control)
            local value = to_number(text)
            if value ~= nil then
                stats[key] = value
                raw[key] = { control = control, text = text }
                count = count + 1
                break
            end
        end
    end
    if stats.attack ~= nil then stats.atk = stats.attack end
    if count == 0 then return nil, raw end
    stats.updated = os.time()
    stats.source = "inventory"
    stats.inventoryStats = true
    stats.inventoryWindowOpen = is_open
    return stats, raw
end

function M.merge_into(stats, opts)
    stats = type(stats) == "table" and stats or {}
    local inv = M.capture(opts)
    if not inv then return stats, 0 end
    local merged = 0
    for key, value in pairs(inv) do
        if key ~= "updated" and key ~= "source" and key ~= "inventoryStats" and key ~= "inventoryWindowOpen" then
            if tonumber(value) ~= nil then
                stats[key] = value
                merged = merged + 1
            end
        end
    end
    if stats.attack ~= nil then stats.atk = stats.attack end
    stats.inventoryStatsUpdated = inv.updated
    stats.inventoryStatsMerged = merged
    stats.inventoryStatsWindowOpen = inv.inventoryWindowOpen
    return stats, merged
end

function M.probe(opts)
    opts = type(opts) == "table" and opts or {}
    local stats, raw = M.capture({ open = opts.open == true })
    if not stats then
        print("[TurboGear Inventory Stats Probe] No named Inventory Stats labels returned values.")
        print("[TurboGear Inventory Stats Probe] Open Inventory > Stats and run /tgear invstats again.")
        return false
    end
    print("[TurboGear Inventory Stats Probe] Named Inventory Stats labels:")
    for _, key in ipairs(PRINT_ORDER) do
        if stats[key] ~= nil then
            local src = raw and raw[key] and raw[key].control or "?"
            print(string.format("[TurboGear Inventory Stats Probe] %s=%s via %s", key, tostring(stats[key]), src))
        end
    end
    return true
end

return M
