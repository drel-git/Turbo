-- TurboGear/peer_discovery.lua
-- Lightweight online-client discovery. Discovery is separate from command
-- transport: providers answer "who is online?", config transport decides how
-- to start TurboGear on those clients.

local mq = require('mq')
local cfg = require('config')
local Store = require('store').Store

local M = {}

local state = {
    last_poll = 0,
    last_sig = "",
    last_set = {},
    request_at = 0,
    last_status = "idle",
}

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function clean_name(name)
    name = trim(name)
    name = name:match("^[%w_]+") or name
    return name
end

local function self_name()
    local ok, name = pcall(function() return mq.TLO.Me.CleanName() end)
    return ok and tostring(name or ""):lower() or ""
end

local function e3_connected_names()
    local names, seen = {}, {}
    local ok, peers = pcall(function()
        if mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query then
            return mq.TLO.MQ2Mono.Query("e3,E3Bots.ConnectedClients")()
        end
        return nil
    end)
    if not ok or type(peers) ~= "string" then return names end
    local mine = self_name()
    for peer in peers:gmatch("([^,]+)") do
        local name = clean_name(peer)
        local key = name:lower()
        if name ~= "" and key ~= mine and not seen[key] then
            seen[key] = true
            names[#names + 1] = name
        end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

local PROVIDERS = {
    e3 = {
        label = "E3 ConnectedClients",
        names = e3_connected_names,
    },
}

local function provider_key()
    local key = tostring(cfg.Settings.peerDiscoveryProvider or "auto"):lower()
    if key == "off" then return nil end
    if key == "auto" then
        return "e3"
    end
    return PROVIDERS[key] and key or nil
end

local function names_signature(names)
    return table.concat(names or {}, "|"):lower()
end

local function names_set(names)
    local set = {}
    for _, name in ipairs(names or {}) do set[name:lower()] = name end
    return set
end

local function send_starts(new_names)
    if not new_names or #new_names == 0 then return 0 end
    local sent = 0
    if cfg.transport_template("target") ~= "" then
        for _, name in ipairs(new_names) do
            local cmd = cfg.soft_start_bg_command_for(name)
            if cmd ~= "" then
                mq.cmd(cmd)
                sent = sent + 1
            end
        end
        return sent
    end
    if cfg.launch_all_online_peers and cfg.launch_all_online_peers() then
        return #new_names
    end
    return 0
end

function M.tick(Engine)
    if cfg.Settings.peerDiscoveryEnabled == false or cfg.Settings.autoAddOnlinePeers == false then return end
    local providerName = provider_key()
    local provider = providerName and PROVIDERS[providerName] or nil
    if not provider then return end

    local now = os.clock()
    if state.request_at > 0 and now >= state.request_at then
        state.request_at = 0
        if Engine and Engine.ok and Engine.request_all then
            Engine.request_all(true)
        else
            -- Viewer UI never owns the mailbox; the local bg responder does.
            pcall(function() mq.cmd('/squelch /tgearbg sync') end)
        end
    end

    local interval = tonumber(cfg.Settings.peerDiscoveryIntervalSeconds) or 10
    if (now - state.last_poll) < interval then return end
    state.last_poll = now

    local names = provider.names()
    local sig = names_signature(names)
    local current = names_set(names)
    local new_names = {}
    for _, name in ipairs(names) do
        Store.discover_peer(name, providerName)
        if not state.last_set[name:lower()] then
            new_names[#new_names + 1] = name
        end
    end
    if sig ~= state.last_sig and #new_names > 0 then
        local sent = send_starts(new_names)
        state.request_at = now + (tonumber(cfg.CFG.peer_soft_sync_delay_s) or 3.0)
        state.last_status = string.format("%s: %d online, %d new, %d start command(s)", provider.label, #names, #new_names, sent)
    elseif sig ~= state.last_sig then
        state.last_status = string.format("%s: %d online", provider.label, #names)
    end
    state.last_sig = sig
    state.last_set = current
end

function M.status()
    return state.last_status
end

return M
