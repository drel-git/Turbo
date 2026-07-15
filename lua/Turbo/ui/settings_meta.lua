--[[
  TurboLoot settings metadata.

  Keep this table outside init.lua so the Settings UI can stay data-driven
  without adding lots of locals to the main Turbo UI chunk.
]]

local M = {}

local SETTINGS_META = {
    lootDistance = {
        label = 'Loot distance', default = 80, options = 'Number',
        tooltip = 'Maximum corpse search distance in feet.',
        description = 'Maximum corpse search distance in feet.',
        group = 'Looting', type = 'int', min = 10, max = 300,
    },
    lootHighValueMinPP = {
        label = 'High value pp', default = 50, options = 'Number; 0 disables',
        tooltip = 'Loot non-stackable items worth at least this many platinum. 0 disables this rule.',
        description = 'Loot non-stackable items worth at least this many platinum. 0 disables this rule.',
        group = 'Looting', type = 'int', min = 0, max = 1000000,
    },
    lootStackableMinPP = {
        label = 'Stackable pp', default = 50, options = 'Number; 0 disables',
        tooltip = 'Loot stackable items worth at least this many platinum. 0 disables this rule.',
        description = 'Loot stackable items worth at least this many platinum. 0 disables this rule.',
        group = 'Looting', type = 'int', min = 0, max = 1000000,
    },
    inventoryWarnSlots = {
        label = 'Warn slots', default = 5, options = 'Number',
        tooltip = 'Warn when free inventory slots fall to this number or lower.',
        description = 'Warn when free inventory slots fall to this number or lower.',
        group = 'Looting', type = 'int', min = 0, max = 40,
    },
    finalSweep = {
        label = 'Final sweep', default = 'ON', options = 'ON, OFF',
        tooltip = 'Do one final retry pass after the main loot run.',
        description = 'Do one final retry pass after the main loot run.',
        group = 'Looting', type = 'bool', advanced = true,
    },
    finalSweepRadiusFeet = {
        label = 'Final sweep radius', default = 0, options = 'Number; 0 uses lootDistance',
        tooltip = 'Corpse radius for the final sweep. 0 reuses lootDistance.',
        description = 'Corpse radius for the final sweep. 0 reuses lootDistance.',
        group = 'Looting', type = 'int', min = 0, max = 300, advanced = true,
    },
    reclaimDiamondCoinsAfterLoot = {
        label = 'Reclaim Diamond Coins', default = 'OFF', options = 'ON, OFF',
        tooltip = 'After normal /mac turboloot finishes, reclaim inventory Diamond Coin stacks to alt-currency. No effect on sell/bank/tribute/unload modes.',
        description = 'After normal /mac turboloot finishes, reclaim inventory Diamond Coin stacks to alt-currency.',
        group = 'Looting', type = 'bool',
    },
    midRunRefreshCorpses = {
        label = 'Mid-run refresh corpses', default = 5, options = 'Number; 0 disables',
        tooltip = 'Refresh the corpse list every N processed corpses.',
        description = 'Refresh the corpse list every N processed corpses.',
        group = 'Looting', type = 'int', min = 0, max = 200, advanced = true,
    },
    UseNavForCorpses = {
        label = 'Use nav for corpses', default = 'OFF', options = 'ON, OFF',
        tooltip = 'Use navigation movement when approaching corpses.',
        description = 'Use navigation movement when approaching corpses.',
        group = 'Looting', type = 'bool', advanced = true,
    },
    RightClickLoot = {
        label = 'Right-click loot', default = 'ON', options = 'ON, OFF',
        tooltip = 'Use the safer right-click looting interaction. OFF is ignored unless Allow legacy left-click is also ON.',
        description = 'Use the safer right-click looting interaction. OFF is ignored unless Allow legacy left-click is also ON.',
        group = 'Looting', type = 'bool', advanced = true,
    },
    AllowLeftClickLoot = {
        label = 'Allow legacy left-click', default = 'OFF', options = 'ON, OFF',
        tooltip = 'Permit RightClickLoot=OFF. Leave OFF unless testing a left-click-specific issue.',
        description = 'Permit RightClickLoot=OFF. Leave OFF unless testing a left-click-specific issue.',
        group = 'Looting', type = 'bool', advanced = true,
    },

    SellUnlistedStackable = {
        label = 'Sell unlisted stackable', default = 'OFF', options = 'ON, OFF',
        tooltip = 'Sell stackable vendor-value items without explicit item rules.',
        description = 'Sell stackable vendor-value items without explicit item rules.',
        group = 'Selling', type = 'bool',
    },
    sellUnlistedItems = {
        label = 'Sell unlisted items', default = 'OFF', options = 'ON, OFF',
        tooltip = 'Sell any unlisted vendor-value item. Use carefully.',
        description = 'Sell any unlisted vendor-value item. Use carefully.',
        group = 'Selling', type = 'bool',
    },
    sellWildcards = {
        label = 'Sell wildcards', default = 'OFF', options = 'ON, OFF',
        tooltip = 'Allow wildcard matches to be sold automatically.',
        description = 'Allow wildcard matches to be sold automatically.',
        group = 'Selling', type = 'bool', advanced = true,
    },
    bankWildcards = {
        label = 'Bank wildcards', default = 'ON', options = 'ON, OFF',
        tooltip = 'Allow wildcard matches to be banked automatically.',
        description = 'Allow wildcard matches to be banked automatically.',
        group = 'Selling', type = 'bool',
    },
    convertCoinOnBank = {
        label = 'Convert coin on bank', default = 'ON', options = 'ON, OFF',
        tooltip = 'Convert coin denominations during bank mode.',
        description = 'Convert coin denominations during bank mode.',
        group = 'Selling', type = 'bool',
    },

    announceDefaultTo = {
        label = 'Default to', default = 'e3bc', options = 'echo, e3bc, say, gsay, rsay, tell Name',
        tooltip = 'Default channel used for TurboLoot messages.',
        description = 'Default channel used for TurboLoot messages.',
        group = 'Announcements', type = 'text',
    },
    announceDoneLootingTo = {
        label = 'Done looting to', default = 'e3bc', options = 'echo, e3bc, say, gsay, rsay, tell Name',
        tooltip = 'Channel used for the final done-looting message.',
        description = 'Channel used for the final done-looting message.',
        group = 'Announcements', type = 'text',
    },
    announceSkipTo = {
        label = 'Skip to', default = 'gsay', options = 'echo, e3bc, say, gsay, rsay, tell Name, OFF',
        tooltip = 'Channel used for skipped item messages. OFF disables skip announcements.',
        description = 'Channel used for skipped item messages. OFF disables skip announcements.',
        group = 'Announcements', type = 'text',
    },
    announceBankSellPerItem = {
        label = 'Bank/sell per item', default = 'ON', options = 'ON, OFF',
        tooltip = 'Announce each banked, sold, or tributed item individually.',
        description = 'Announce each banked, sold, or tributed item individually.',
        group = 'Announcements', type = 'bool',
    },
    announceLoot = {
        label = 'Announce loot', default = 'ON', options = 'ON, OFF',
        tooltip = 'Announce items as they are looted.',
        description = 'Announce items as they are looted.',
        group = 'Announcements', type = 'bool',
    },
    announceDestroy = {
        label = 'Announce destroy', default = 'OFF', options = 'ON, OFF',
        tooltip = 'Announce items that are destroyed.',
        description = 'Announce items that are destroyed.',
        group = 'Announcements', type = 'bool',
    },
    announceRunSummary = {
        label = 'Run summary', default = 'OFF', options = 'ON, OFF, or channel-style value',
        tooltip = 'Show Looted/Destroyed/Skipped/Duration when a loot run finishes. OFF by default for quieter runs.',
        description = 'Show Looted/Destroyed/Skipped/Duration when a loot run finishes. OFF by default for quieter runs.',
        group = 'Announcements', type = 'text',
    },
    AutoRsayInRaid = {
        label = 'Raid announce auto-rsay', default = 'OFF', options = 'ON, OFF',
        tooltip = 'Automatically switch announcements to rsay while in a raid.',
        description = 'Automatically switch announcements to rsay while in a raid.',
        group = 'Announcements', type = 'bool',
    },
    lootAnnounceMethod = {
        label = 'Loot channel', default = '', options = 'echo, e3bc, say, gsay, rsay, tell Name',
        tooltip = 'Optional explicit channel for loot announcements.',
        description = 'Optional explicit channel for loot announcements.',
        group = 'Announcements', type = 'text', advanced = true,
    },
    loreAnnounceMethod = {
        label = 'Lore channel', default = '', options = 'echo, e3bc, say, gsay, rsay, tell Name, OFF',
        tooltip = 'Optional explicit channel for lore item messages.',
        description = 'Optional explicit channel for lore item messages.',
        group = 'Announcements', type = 'text', advanced = true,
    },
    bankSellTributeAnnounceMethod = {
        label = 'Bank/sell/tribute channel', default = 'echo', options = 'echo, e3bc, say, gsay, rsay, tell Name',
        tooltip = 'Channel used for bank, sell, and tribute messages.',
        description = 'Channel used for bank, sell, and tribute messages.',
        group = 'Announcements', type = 'text', advanced = true,
    },

    corpseHideMode = {
        label = 'Corpse hide', default = 'LOOTED', options = 'ALL, GROUP, SELF, LOOTED, OFF',
        tooltip = 'Choose which corpses TurboLoot hides while running.',
        description = 'Choose which corpses TurboLoot hides while running.',
        group = 'Behavior', type = 'enum', values = { 'LOOTED', 'ALL', 'GROUP', 'SELF', 'OFF' },
    },
    lootNoDropPrompt = {
        label = 'No-drop prompt', default = 'never', options = 'always, never, once',
        tooltip = 'Controls no-drop prompt handling during looting.',
        description = 'Controls no-drop prompt handling during looting.',
        group = 'Behavior', type = 'enum', values = { 'never', 'always', 'once' },
    },
    lootNoDropPromptReset = {
        label = 'No-drop reset', default = 'always', options = 'always, never',
        tooltip = 'Restores no-drop prompt behavior when TurboLoot exits.',
        description = 'Restores no-drop prompt behavior when TurboLoot exits.',
        group = 'Behavior', type = 'enum', values = { 'always', 'never' },
    },
    dropLevBeforeNav = {
        label = 'Drop lev before nav', default = 'OFF', options = 'ON, OFF',
        tooltip = 'Drop levitation before movement when needed.',
        description = 'Drop levitation before movement when needed.',
        group = 'Behavior', type = 'bool', advanced = true,
    },
    returnToLeader = {
        label = 'Return to leader', default = 'ON', options = 'ON, OFF',
        tooltip = 'Return to the group leader after sell, bank, tribute, or unload.',
        description = 'Return to the group leader after sell, bank, tribute, or unload.',
        group = 'Behavior', type = 'bool',
    },
    StopLootWhenAttacked = {
        label = 'Stop when attacked', default = 'OFF', options = 'ON, OFF',
        tooltip = 'Stop looting if aggressive mobs are detected nearby.',
        description = 'Stop looting if aggressive mobs are detected nearby.',
        group = 'Behavior', type = 'bool',
    },
    followRestoreMode = {
        label = 'Follow restore mode', default = 'NONE', options = 'NONE',
        tooltip = 'Controls how follow state is restored after TurboLoot finishes.',
        description = 'Controls how follow state is restored after TurboLoot finishes.',
        group = 'Behavior', type = 'text', advanced = true,
    },
    followRestoreDriver = {
        label = 'Follow restore driver', default = 'AUTO', options = 'AUTO',
        tooltip = 'Controls which follow restore driver TurboLoot uses.',
        description = 'Controls which follow restore driver TurboLoot uses.',
        group = 'Behavior', type = 'text', advanced = true,
    },

    debug = {
        label = 'Debug', default = 'OFF', options = 'ON, OFF',
        tooltip = 'Enable extra debug output for troubleshooting.',
        description = 'Enable extra debug output for troubleshooting.',
        group = 'Debug / Logs', type = 'bool', advanced = true,
    },
    logToFile = {
        label = 'Log to file', default = 'OFF', options = 'ON, OFF',
        tooltip = 'Write TurboLoot log output to a file.',
        description = 'Write TurboLoot log output to a file.',
        group = 'Debug / Logs', type = 'bool', advanced = true,
    },
    logLevel = {
        label = 'Log level', default = 'INFO', options = 'DEBUG, INFO, WARN, ERROR',
        tooltip = 'Controls how verbose TurboLoot file logging is.',
        description = 'Controls how verbose TurboLoot file logging is.',
        group = 'Debug / Logs', type = 'enum', values = { 'INFO', 'DEBUG', 'WARN', 'ERROR' }, advanced = true,
    },
    logSkipListForIni = {
        label = 'Log skip list for ini', default = 'ON', options = 'ON, OFF',
        tooltip = 'Queue skipped item rows for the Turbo Review UI (chat hints only when debug=ON).',
        description = 'Queue skipped item rows for the Turbo Review UI (chat hints only when debug=ON).',
        group = 'Debug / Logs', type = 'bool', advanced = true,
    },
}

local GROUP_ORDER = {
    'Looting',
    'Selling',
    'Announcements',
    'Behavior',
    'Debug / Logs',
}

local SCHEMA_ORDER = {
    'lootDistance', 'lootHighValueMinPP', 'lootStackableMinPP', 'inventoryWarnSlots',
    'finalSweep', 'finalSweepRadiusFeet', 'reclaimDiamondCoinsAfterLoot', 'midRunRefreshCorpses', 'UseNavForCorpses', 'RightClickLoot', 'AllowLeftClickLoot',
    'SellUnlistedStackable', 'sellUnlistedItems', 'sellWildcards', 'bankWildcards', 'convertCoinOnBank',
    'announceDefaultTo', 'announceDoneLootingTo', 'announceSkipTo', 'announceBankSellPerItem',
    'announceLoot', 'announceDestroy', 'announceRunSummary', 'AutoRsayInRaid',
    'lootAnnounceMethod', 'loreAnnounceMethod', 'bankSellTributeAnnounceMethod',
    'corpseHideMode', 'lootNoDropPrompt', 'lootNoDropPromptReset', 'dropLevBeforeNav',
    'returnToLeader', 'StopLootWhenAttacked', 'followRestoreMode', 'followRestoreDriver',
    'debug', 'logToFile', 'logLevel', 'logSkipListForIni',
}

local ITEM_LIMIT_RULES = {
    KEEP = {
        label = 'KEEP',
        value = 'KEEP',
        category = 'Loot',
        tooltip = 'Always loot this item and keep it in inventory.',
        description = 'Always loot this item and keep it in inventory.',
    },
    SELL = {
        label = 'SELL',
        value = 'SELL',
        category = 'Unload',
        tooltip = 'Loot this item, then sell it during TurboLoot sell or unload.',
        description = 'Loot this item, then sell it during TurboLoot sell or unload.',
    },
    BANK = {
        label = 'BANK',
        value = 'BANK',
        category = 'Unload',
        tooltip = 'Loot this item, then bank it during TurboLoot bank or unload.',
        description = 'Loot this item, then bank it during TurboLoot bank or unload.',
    },
    TRIBUTE = {
        label = 'TRIBUTE',
        value = 'TRIBUTE',
        category = 'Unload',
        tooltip = 'Loot this item, then tribute it during TurboLoot tribute or unload.',
        description = 'Loot this item, then tribute it during TurboLoot tribute or unload.',
    },
    DESTROY = {
        label = 'DESTROY',
        value = 'DESTROY',
        category = 'Skip / Act',
        tooltip = 'Loot and destroy this item.',
        description = 'Loot and destroy this item.',
    },
    IGNORE = {
        label = 'IGNORE',
        value = 'IGNORE',
        category = 'Skip',
        tooltip = 'Leave this item on the corpse and do not announce it.',
        description = 'Leave this item on the corpse and do not announce it.',
    },
    SKIP = {
        label = 'SKIP',
        value = 'SKIP',
        category = 'Skip',
        tooltip = 'Alias for IGNORE.',
        description = 'Alias for IGNORE.',
    },
    ANNOUNCE = {
        label = 'ANNOUNCE',
        value = 'ANNOUNCE',
        category = 'Skip',
        tooltip = 'Leave this item on the corpse and announce it so another character can loot it.',
        description = 'Leave this item on the corpse and announce it so another character can loot it.',
    },
    NUMBER = {
        label = 'Number',
        value = '#',
        category = 'Loot',
        tooltip = 'Loot up to this many copies or stack units.',
        description = 'Loot up to this many copies or stack units, for example Bone Chips=50.',
    },
}

local ITEM_LIMIT_RULE_ORDER = {
    'KEEP',
    'SELL',
    'BANK',
    'TRIBUTE',
    'DESTROY',
    'IGNORE',
    'SKIP',
    'ANNOUNCE',
    'NUMBER',
}

local TURBOGIVE_DOCS = {
    {
        title = 'Exact item',
        ini = 'Item Name=Receiver',
        example = 'Example Token=Tankname',
        description = 'Give every copy or stack of the exact item to one receiver.',
    },
    {
        title = 'Exact item with cap',
        ini = 'Item Name=Receiver 5',
        example = 'Example Potion=Clericname 5',
        description = 'Give up to the listed total count to one receiver.',
    },
    {
        title = 'Multiple receivers',
        ini = 'Item Name=Receiver 1|Other 1',
        example = 'Quest Token=Tankname 1|Clericname 1',
        description = 'Give capped amounts to multiple receivers from one exact item row.',
    },
    {
        title = 'Prefix pattern',
        ini = '_prefix1=Receiver:Spell:*',
        example = '_prefix1=Wizardname:Spell:*',
        description = 'Match item names by pattern and give matches to the receiver.',
    },
    {
        title = 'Shared wildcards',
        ini = '_wildcards=Receiver|Other',
        example = '_wildcards=Wizardname|Clericname',
        description = 'Use the shared [Wildcards] prefixes for these receivers.',
    },
    {
        title = 'Give exclusions',
        ini = '[GiveExclude] _list=Name,Other Name',
        example = '_list=Tome of Nife\'s Mercy',
        description = 'Block prefix and wildcard GiveList matches. Exact GiveList item rows still apply.',
    },
}

local function copyArray(values)
    local out = {}
    for i = 1, #(values or {}) do out[i] = values[i] end
    return out
end

function M.get(key) return SETTINGS_META[key] end
function M.getTooltip(key) return SETTINGS_META[key] and SETTINGS_META[key].tooltip or '' end
function M.getLabel(key) return SETTINGS_META[key] and SETTINGS_META[key].label or key end
function M.getDefault(key) return SETTINGS_META[key] and SETTINGS_META[key].default or nil end
function M.getOptions(key) return SETTINGS_META[key] and SETTINGS_META[key].options or '' end
function M.getGroup(key) return SETTINGS_META[key] and SETTINGS_META[key].group or '' end
function M.isAdvanced(key) return SETTINGS_META[key] and SETTINGS_META[key].advanced == true or false end
function M.getGroups() return copyArray(GROUP_ORDER) end
function M.getSchemaOrder() return copyArray(SCHEMA_ORDER) end
function M.getItemLimitRuleOrder() return copyArray(ITEM_LIMIT_RULE_ORDER) end
function M.getItemLimitRule(rule) return ITEM_LIMIT_RULES[tostring(rule or ''):upper()] end
function M.getItemLimitRules()
    local out = {}
    for _, rule in ipairs(ITEM_LIMIT_RULE_ORDER) do
        local e = ITEM_LIMIT_RULES[rule]
        if e then
            out[#out + 1] = {
                key = rule,
                label = e.label,
                value = e.value,
                category = e.category,
                tooltip = e.tooltip,
                description = e.description,
            }
        end
    end
    return out
end
function M.getTurboGiveDocs() return copyArray(TURBOGIVE_DOCS) end

function M.buildSchema()
    local rows = {}
    for _, key in ipairs(SCHEMA_ORDER) do
        local e = SETTINGS_META[key]
        if e then
            rows[#rows + 1] = {
                key = key, label = e.label, group = e.group,
                type = e.type or 'text', min = e.min, max = e.max,
                values = e.values, advanced = e.advanced == true,
                tooltip = e.tooltip, description = e.description,
                default = e.default, options = e.options,
            }
        end
    end
    return rows
end

function M.getKeysByGroup(groupName, includeAdvanced)
    local out = {}
    for _, key in ipairs(SCHEMA_ORDER) do
        local e = SETTINGS_META[key]
        if e and e.group == groupName and (includeAdvanced or e.advanced ~= true) then
            out[#out + 1] = key
        end
    end
    return out
end

function M.getAllKeys(includeAdvanced)
    local out = {}
    for _, key in ipairs(SCHEMA_ORDER) do
        local e = SETTINGS_META[key]
        if e and (includeAdvanced or e.advanced ~= true) then out[#out + 1] = key end
    end
    return out
end

M.entries = SETTINGS_META
M.groupOrder = GROUP_ORDER
M.schemaOrder = SCHEMA_ORDER
M.itemLimitRules = ITEM_LIMIT_RULES
M.itemLimitRuleOrder = ITEM_LIMIT_RULE_ORDER

return M
