-- TurboGear/global_search.lua
-- Cross-tab inventory search over the cached item_index (no live TLO scans).

local cfg = require('config')
local Settings = cfg.Settings
local item_index = require('item_index')
local store = require('store')
local Store = store.Store

local M = {}

local filtered_cache = { key = nil, rows = nil }
local bis_filtered_cache = { key = nil, rows = nil }

function M.invalidate()
    filtered_cache.key = nil
    filtered_cache.rows = nil
    bis_filtered_cache.key = nil
    bis_filtered_cache.rows = nil
end

local TAB_LABELS = {
    gear = "Gear",
    inspect = "Inspect",
    upgrade = "Upgrade",
    bis = "BiS + Lists",
    lockouts = "Lockouts",
    setup = "Setup",
}

function M.tab_for_row(row)
    if type(row) ~= "table" then return "gear", "inventory" end
    local where = tostring(row.where or "")
    local group = tostring(row.locationGroup or "")
    if where == "equipped" or group == "equipped" or group == "installed_aug" then
        if row.kind == "aug" then
            return "gear", group == "installed_aug" and "worn" or "stored"
        end
        return "gear", "worn"
    end
    if where == "loose_aug" or row.kind == "aug" then
        return "gear", "stored"
    end
    if group == "bags" or group == "bank" then
        return "gear", "inventory"
    end
    if type(row.stats) == "table" then
        for _, value in pairs(row.stats) do
            if (tonumber(value) or 0) > 0 then
                return "inspect", "stats"
            end
        end
    end
    if type(row.focusEffects) == "table" and #row.focusEffects > 0 then
        return "inspect", "focus"
    end
    if type(row.wornFocusEffects) == "table" and #row.wornFocusEffects > 0 then
        return "inspect", "focus"
    end
    return "gear", "inventory"
end

function M.tab_label(tab_key)
    return TAB_LABELS[tab_key] or tostring(tab_key or "?")
end

function M.row_hint(row)
    local tab, sub = M.tab_for_row(row)
    if tab == "inspect" then
        if sub == "focus" then return "Inspect · Focus" end
        return "Inspect · Stats"
    end
    if tab == "upgrade" then
        if sub == "compare" then return "Upgrade · Compare" end
        return "Upgrade · Suggest"
    end
    if tab == "gear" then
        if sub == "worn" then return "Gear · Worn" end
        if sub == "stored" then return "Gear · Stored" end
        if sub == "empty" then return "Gear · Empty" end
        return "Gear · Inventory"
    end
    return M.tab_label(tab)
end

function M.filter(needle, limit)
    needle = tostring(needle or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if needle == "" then
        filtered_cache.key = nil
        filtered_cache.rows = nil
        return {}
    end

    item_index.get(false)
    local version = Store.content_version or 0
    local cache_key = needle .. ":" .. tostring(version) .. ":" .. tostring(limit or 80)
    if filtered_cache.key == cache_key then
        return filtered_cache.rows or {}
    end

    limit = tonumber(limit) or 80
    local out = {}
    for _, row in ipairs(item_index.rows or {}) do
        if #out >= limit then break end
        local hay = table.concat({
            row.name or "",
            row.owner or "",
            row.location or "",
            row.where or "",
            row.installedIn or "",
        }, " "):lower()
        if hay:find(needle, 1, true) then
            out[#out + 1] = row
        end
    end

    filtered_cache.key = cache_key
    filtered_cache.rows = out
    return out
end

function M.filter_bis(needle, limit)
    needle = tostring(needle or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if needle == "" then
        bis_filtered_cache.key = nil
        bis_filtered_cache.rows = nil
        return {}
    end

    limit = tonumber(limit) or 30
    local cache_key = needle .. ":" .. tostring(limit)
    if bis_filtered_cache.key == cache_key then
        return bis_filtered_cache.rows or {}
    end

    local bis_catalog = require('bis_catalog')
    local out = bis_catalog.search_items(needle, limit)
    bis_filtered_cache.key = cache_key
    bis_filtered_cache.rows = out
    return out
end

function M.apply_bis_row(row)
    if type(row) ~= "table" then return end
    Settings.mainTab = "bis"
    Settings.bisListsTab = "catalog"
    Settings.bisListMode = "catalog"
    local bis_tab = require('tabs.bis')
    bis_tab.open_catalog_list(row.list_id, row.name)
    if cfg.SaveSettings then cfg.SaveSettings() end
end

function M.apply_row(row)
    if type(row) ~= "table" then return end
    local tab, sub = M.tab_for_row(row)
    Settings.mainTab = tab
    local name = tostring(row.name or "")
    if tab == "gear" then
        Settings.gearTab = sub or "inventory"
        Settings.augsSubTab = (sub == "stored" and "stored") or (sub == "empty" and "empty") or "equipped"
        if Settings.gearTab == "inventory" then
            Settings.inventoryViewMode = "table"
            Settings.inventorySearch = name
        end
    elseif tab == "inspect" then
        Settings.inspectTab = sub or "stats"
    elseif tab == "upgrade" then
        Settings.upgradeTab = sub or "suggestions"
    end
    if tab == "inspect" and (sub or "stats") == "stats" then
        require('tabs.stats').set_search(name)
    elseif tab == "inspect" and sub == "focus" then
        require('tabs.focus').set_search(name)
    elseif tab == "upgrade" and (sub or "suggestions") == "suggestions" then
        require('tabs.suggestions').set_search(name)
    end
    if cfg.SaveSettings then cfg.SaveSettings() end
end

return M
