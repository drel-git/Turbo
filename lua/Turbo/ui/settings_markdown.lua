local settingsMeta = require('Turbo.ui.settings_meta')

local M = {}

local function cell(value)
    local text = tostring(value == nil and '' or value)
    text = text:gsub('[\r\n]+', ' '):gsub('%s+', ' '):gsub('|', '\\|')
    return text
end

local function tableFor(keys, includeOptions)
    local lines = {}
    if includeOptions then
        lines[#lines + 1] = '| Setting | INI Key | Default | Options | Description |'
        lines[#lines + 1] = '|---|---|---:|---|---|'
    else
        lines[#lines + 1] = '| Setting | INI Key | Default | Description |'
        lines[#lines + 1] = '|---|---|---:|---|'
    end
    for _, key in ipairs(keys or {}) do
        local e = settingsMeta.get(key)
        if e then
            if includeOptions then
                lines[#lines + 1] = string.format('| %s | `%s` | `%s` | %s | %s |',
                    cell(e.label), cell(key), cell(e.default), cell(e.options), cell(e.description))
            else
                lines[#lines + 1] = string.format('| %s | `%s` | `%s` | %s |',
                    cell(e.label), cell(key), cell(e.default), cell(e.description))
            end
        end
    end
    return table.concat(lines, '\n')
end

local function appendTurboKeySection(lines)
    lines[#lines + 1] = '## TurboKey'
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'TurboKey tags the item on your cursor into `turboloot.ini` under `[ItemLimits]`. The Turbo UI uses the same rule values when you click rule buttons.'
    lines[#lines + 1] = ''
    lines[#lines + 1] = '| Rule | Category | Description |'
    lines[#lines + 1] = '|---|---|---|'
    for _, rule in ipairs(settingsMeta.getItemLimitRules()) do
        lines[#lines + 1] = string.format('| `%s` | %s | %s |',
            cell(rule.value), cell(rule.category), cell(rule.description))
    end
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'Examples:'
    lines[#lines + 1] = ''
    lines[#lines + 1] = '- `/mac turbokey KEEP` with an item on cursor writes `Item Name=KEEP`.'
    lines[#lines + 1] = '- `/mac turbokey ANNOUNCE` leaves future copies on the corpse and announces them.'
    lines[#lines + 1] = '- `/mac turbokey 5` writes a numeric max-count rule.'
    lines[#lines + 1] = ''
end

local function appendTurboGiveSection(lines)
    lines[#lines + 1] = '## TurboGive'
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'TurboGive uses the same `turboloot.ini` and reads `[GiveList]`, `[GiveExclude]`, and shared `[Wildcards]` rows.'
    lines[#lines + 1] = ''
    lines[#lines + 1] = '| Pattern | INI shape | Example | Description |'
    lines[#lines + 1] = '|---|---|---|---|'
    for _, row in ipairs(settingsMeta.getTurboGiveDocs()) do
        lines[#lines + 1] = string.format('| %s | `%s` | `%s` | %s |',
            cell(row.title), cell(row.ini), cell(row.example), cell(row.description))
    end
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'Common commands:'
    lines[#lines + 1] = ''
    lines[#lines + 1] = '- `/mac turbogive add` with a PC targeted and an item on cursor adds that item to the receiver.'
    lines[#lines + 1] = '- `/mac turbogive` distributes assigned items through the group.'
    lines[#lines + 1] = '- `/mac turbogive collect` asks the group to send assigned items to you.'
    lines[#lines + 1] = '- `/mac turbogive hand 1` gives one cursor item to each in-zone groupmate.'
    lines[#lines + 1] = ''
end

function M.renderReadme()
    local lines = {
        '## TurboLoot Settings',
        '',
        'Start with the basic settings. Advanced settings are available for movement, channels, and troubleshooting.',
        '',
        '### Basic Settings',
        '',
    }
    for _, group in ipairs(settingsMeta.getGroups()) do
        local keys = settingsMeta.getKeysByGroup(group, false)
        if #keys > 0 then
            lines[#lines + 1] = '#### ' .. group
            lines[#lines + 1] = ''
            lines[#lines + 1] = tableFor(keys, false)
            lines[#lines + 1] = ''
        end
    end
    lines[#lines + 1] = '### Advanced Settings'
    lines[#lines + 1] = ''
    for _, group in ipairs(settingsMeta.getGroups()) do
        local all = settingsMeta.getKeysByGroup(group, true)
        local keys = {}
        for _, key in ipairs(all) do
            if settingsMeta.isAdvanced(key) then keys[#keys + 1] = key end
        end
        if #keys > 0 then
            lines[#lines + 1] = '#### ' .. group
            lines[#lines + 1] = ''
            lines[#lines + 1] = tableFor(keys, true)
            lines[#lines + 1] = ''
        end
    end
    appendTurboKeySection(lines)
    appendTurboGiveSection(lines)
    return table.concat(lines, '\n')
end

function M.renderTurboKeyRules()
    local lines = {
        '## TurboKey Rules',
        '',
        '| Rule | Category | Description |',
        '|---|---|---|',
    }
    for _, rule in ipairs(settingsMeta.getItemLimitRules()) do
        lines[#lines + 1] = string.format('| `%s` | %s | %s |',
            cell(rule.value), cell(rule.category), cell(rule.description))
    end
    return table.concat(lines, '\n')
end

function M.renderTurboGiveDocs()
    local lines = {
        '## TurboGive INI Patterns',
        '',
        '| Pattern | INI shape | Example | Description |',
        '|---|---|---|---|',
    }
    for _, row in ipairs(settingsMeta.getTurboGiveDocs()) do
        lines[#lines + 1] = string.format('| %s | `%s` | `%s` | %s |',
            cell(row.title), cell(row.ini), cell(row.example), cell(row.description))
    end
    return table.concat(lines, '\n')
end

function M.renderTooltipTable()
    local lines = { '## TurboLoot UI Tooltips', '', '| UI Label | Tooltip |', '|---|---|' }
    for _, key in ipairs(settingsMeta.getAllKeys(true)) do
        local e = settingsMeta.get(key)
        lines[#lines + 1] = string.format('| %s | %s |', cell(e.label), cell(e.tooltip))
    end
    return table.concat(lines, '\n')
end

return M
