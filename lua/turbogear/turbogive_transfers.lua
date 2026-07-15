-- TurboGear/turbogive_transfers.lua
-- Recent explicit TurboGive [GiveList] writes. This is a lightweight audit and
-- navigation surface; it does not run TurboGive or start trades.

local mq = require('mq')
local cfg = require('config')

local M = {}

local TransferFile = string.format("%s/%s_turbogive_transfers.lua", mq.configDir, cfg.CFG.script_name)
local loaded = false
local entries = {}

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

local function normalize(entry)
    if type(entry) ~= "table" then return nil end
    local item = trim(entry.item or entry.name)
    local to = trim(entry.to or entry.recipient)
    if item == "" or to == "" then return nil end
    return {
        item = item,
        id = tonumber(entry.id) or 0,
        from = trim(entry.from or entry.owner),
        to = to,
        qty = math.max(0, math.floor(tonumber(entry.qty) or 0)),
        location = trim(entry.location),
        ini = trim(entry.ini),
        value = trim(entry.value),
        at = tonumber(entry.at) or os.time(),
        status = trim(entry.status) ~= "" and trim(entry.status) or "rule",
    }
end

function M.load(force)
    if loaded and not force then return entries end
    loaded = true
    entries = {}
    local ok, data = pcall(dofile, TransferFile)
    if ok and type(data) == "table" then
        for _, rec in ipairs(data) do
            local entry = normalize(rec)
            if entry then entries[#entries + 1] = entry end
        end
    end
    table.sort(entries, function(a, b) return (a.at or 0) > (b.at or 0) end)
    return entries
end

function M.save()
    M.load()
    local ok, err = pcall(function() mq.pickle(TransferFile, entries) end)
    if not ok then return false, tostring(err or "Could not save TurboGive transfers.") end
    return true
end

function M.entries()
    return M.load()
end

function M.record(entry)
    M.load()
    entry = normalize(entry)
    if not entry then return false, "Missing item or recipient." end
    table.insert(entries, 1, entry)
    while #entries > 100 do table.remove(entries) end
    local ok, err = M.save()
    if not ok then return false, err end
    return true, entry
end

function M.remove(index)
    M.load()
    index = tonumber(index)
    if not index or not entries[index] then return false, "No transfer row selected." end
    local item = entries[index].item
    table.remove(entries, index)
    local ok, err = M.save()
    if not ok then return false, err end
    return true, "Removed " .. tostring(item) .. "."
end

function M.clear()
    entries = {}
    loaded = true
    return M.save()
end

return M
