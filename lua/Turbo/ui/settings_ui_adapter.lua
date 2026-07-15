local settingsMeta = require('Turbo.ui.settings_meta')

local M = {}

M.labelToKey = {}
for _, key in ipairs(settingsMeta.getSchemaOrder()) do
    M.labelToKey[settingsMeta.getLabel(key)] = key
end

function M.keyFromLabel(label) return M.labelToKey[label] end
function M.metaFromLabel(label)
    local key = M.keyFromLabel(label)
    return key and settingsMeta.get(key) or nil
end
function M.tooltipFromLabel(label)
    local meta = M.metaFromLabel(label)
    return meta and meta.tooltip or ''
end
function M.labelForKey(key) return settingsMeta.getLabel(key) end
function M.tooltipForKey(key) return settingsMeta.getTooltip(key) end
function M.defaultForKey(key) return settingsMeta.getDefault(key) end
function M.optionsForKey(key) return settingsMeta.getOptions(key) end
function M.isAdvancedLabel(label)
    local key = M.keyFromLabel(label)
    return key and settingsMeta.isAdvanced(key) or false
end
function M.getItemLimitRules() return settingsMeta.getItemLimitRules() end
function M.itemLimitRule(rule) return settingsMeta.getItemLimitRule(rule) end
function M.itemLimitTooltip(rule)
    local meta = settingsMeta.getItemLimitRule(rule)
    return meta and meta.tooltip or ''
end
function M.getTurboGiveDocs() return settingsMeta.getTurboGiveDocs() end

return M
