-- TurboGear/keep_qty.lua
-- Persistent cached stock targets for potions, components, clickies, and other
-- items worth keeping across the roster. Counts are evaluated by callers from
-- cached inventory rows only.

local mq = require('mq')
local cfg = require('config')

local M = {}

local RulesFile = string.format("%s/%s_keepqty.lua", mq.configDir, cfg.CFG.script_name)
local loaded = false
local rules = {}

local VALID_SCOPES = {
    single = true,
    online = true,
    group = true,
    e3 = true,
    all = true,
}

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

local function norm(s)
    return trim(s):lower()
end

local function clean_qty(qty)
    qty = math.floor(tonumber(qty) or 1)
    if qty < 1 then qty = 1 end
    if qty > 9999 then qty = 9999 end
    return qty
end

local function clean_scope(scope)
    scope = tostring(scope or "all"):lower()
    return VALID_SCOPES[scope] and scope or "all"
end

local function normalize_rule(rule)
    if type(rule) ~= "table" then return nil end
    local name = trim(rule.name or rule.item or rule.item_name)
    local id = tonumber(rule.id or rule.item_id) or 0
    if name == "" and id <= 0 then return nil end
    return {
        name = name,
        id = id > 0 and math.floor(id) or 0,
        qty = clean_qty(rule.qty or rule.want or rule.keep),
        scope = clean_scope(rule.scope),
        updated = tonumber(rule.updated) or os.time(),
    }
end

local function rule_key(rule)
    rule = normalize_rule(rule)
    if not rule then return "" end
    if rule.id > 0 then return "id:" .. tostring(rule.id) end
    return "name:" .. norm(rule.name)
end

function M.load(force)
    if loaded and not force then return rules end
    loaded = true
    rules = {}
    local ok, data = pcall(dofile, RulesFile)
    if ok and type(data) == "table" then
        for _, rec in ipairs(data) do
            local rule = normalize_rule(rec)
            if rule then rules[#rules + 1] = rule end
        end
    end
    table.sort(rules, function(a, b)
        return norm(a.name ~= "" and a.name or tostring(a.id)) < norm(b.name ~= "" and b.name or tostring(b.id))
    end)
    return rules
end

function M.save()
    M.load()
    local ok, err = pcall(function() mq.pickle(RulesFile, rules) end)
    if not ok then return false, tostring(err or "Could not save Keep Qty rules.") end
    return true
end

function M.rules()
    return M.load()
end

function M.add_or_update(item_name, item_id, qty, scope)
    item_name = trim(item_name)
    item_id = tonumber(item_id) or 0
    if item_name == "" and item_id <= 0 then return false, "No item selected." end

    M.load()
    local next_rule = normalize_rule({
        name = item_name,
        id = item_id,
        qty = qty,
        scope = scope,
        updated = os.time(),
    })
    if not next_rule then return false, "Could not create Keep Qty rule." end

    local key = rule_key(next_rule)
    for i, rule in ipairs(rules) do
        if rule_key(rule) == key then
            rules[i] = next_rule
            local ok, err = M.save()
            if not ok then return false, err end
            return true, string.format("Keep Qty: %s x%d.", next_rule.name ~= "" and next_rule.name or ("item " .. next_rule.id), next_rule.qty)
        end
    end

    rules[#rules + 1] = next_rule
    table.sort(rules, function(a, b)
        return norm(a.name ~= "" and a.name or tostring(a.id)) < norm(b.name ~= "" and b.name or tostring(b.id))
    end)
    local ok, err = M.save()
    if not ok then return false, err end
    return true, string.format("Keep Qty: %s x%d.", next_rule.name ~= "" and next_rule.name or ("item " .. next_rule.id), next_rule.qty)
end

function M.remove(index)
    M.load()
    index = tonumber(index)
    if not index or not rules[index] then return false, "No Keep Qty rule selected." end
    local name = rules[index].name
    table.remove(rules, index)
    local ok, err = M.save()
    if not ok then return false, err end
    return true, "Removed " .. tostring(name ~= "" and name or "Keep Qty rule") .. "."
end

function M.set_qty(index, qty)
    M.load()
    index = tonumber(index)
    if not index or not rules[index] then return false, "No Keep Qty rule selected." end
    rules[index].qty = clean_qty(qty)
    rules[index].updated = os.time()
    return M.save()
end

function M.set_scope(index, scope)
    M.load()
    index = tonumber(index)
    if not index or not rules[index] then return false, "No Keep Qty rule selected." end
    rules[index].scope = clean_scope(scope)
    rules[index].updated = os.time()
    return M.save()
end

function M.matches(rule, row)
    if type(row) ~= "table" then return false end
    rule = normalize_rule(rule)
    if not rule then return false end
    if rule.id > 0 and tonumber(row.id) == rule.id then return true end
    return rule.name ~= "" and norm(row.name) == norm(rule.name)
end

function M.evaluate(rule, rows)
    rule = normalize_rule(rule)
    if not rule then return nil end
    local total = 0
    local owner_order, owners = {}, {}
    for _, row in ipairs(rows or {}) do
        if M.matches(rule, row) then
            local qty = clean_qty(row.qty or 1)
            total = total + qty
            local owner = trim(row.owner)
            if owner == "" then owner = "Unknown" end
            local rec = owners[owner]
            if not rec then
                rec = { owner = owner, qty = 0, locations = {} }
                owners[owner] = rec
                owner_order[#owner_order + 1] = owner
            end
            rec.qty = rec.qty + qty
            local loc = trim(row.location)
            if loc ~= "" and #rec.locations < 3 then rec.locations[#rec.locations + 1] = loc end
        end
    end
    local list = {}
    for _, owner in ipairs(owner_order) do list[#list + 1] = owners[owner] end
    table.sort(list, function(a, b)
        if a.qty ~= b.qty then return a.qty > b.qty end
        return norm(a.owner) < norm(b.owner)
    end)
    return {
        rule = rule,
        total = total,
        need = math.max(0, rule.qty - total),
        surplus = math.max(0, total - rule.qty),
        owners = list,
    }
end

return M
