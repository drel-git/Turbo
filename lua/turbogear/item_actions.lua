-- TurboGear/item_actions.lua
-- Shared right-click actions for item and augment names.

local ImGui = require('ImGui')
local mq = require('mq')
local theme = require('theme')
local Theme, col_text = theme.Theme, theme.col_text

local okShell, ShellOpen = pcall(require, 'Turbo.shell_open')
if not okShell then ShellOpen = nil end
local okIntegrations, integrations = pcall(require, 'item_integrations')
if not okIntegrations then integrations = nil end

local M = { status_msg = "" }
local PREVIEW_POPUP = "TurboGear Action Preview##tg_action_preview"
local last_inspect_at = 0
local last_link_at = 0
local last_link_name = ""
local INSPECT_DEBOUNCE_S = 0.35
local context_body_suffix = nil
-- Bank Give To in flight: show Stop Nav until timeout / explicit stop.
local IN_FLIGHT_TTL_S = 95

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

local function clean_name(name)
    return trim(name):lower()
end

local function link_arg(name)
    name = trim(name)
    if name == "" then return "" end
    return name:gsub("%s+", "_")
end

local function is_local_owner(owner)
    local me = mq.TLO.Me.CleanName and mq.TLO.Me.CleanName()
    if not me or trim(me) == "" then return false end
    return clean_name(owner) == clean_name(me)
end

local function opts_qty_from(row_or_item)
    local q = tonumber(row_or_item.qty or row_or_item.stack or row_or_item.count)
    if not q then return nil end
    q = math.floor(q)
    if q < 1 then q = 1 end
    return q
end

function M.pickup_opts_from_row(row)
    if type(row) ~= "table" then return nil end
    local opts = {
        owner = row.owner,
        locationGroup = row.locationGroup,
        where = row.where,
        slotid = row.slotid,
        slotname = row.slotname,
        nodrop = row.nodrop,
        attuned = row.attuned,
        attunable = row.attunable,
    }
    local qty = opts_qty_from(row)
    if qty then opts.qty = qty end
    if row.stack ~= nil then opts.stack = row.stack end
    return opts
end

function M.pickup_opts_from_item(item, owner)
    if type(item) ~= "table" then return nil end
    local loc = tostring(item.location or "")
    local group = nil
    if loc == "Bank" then group = "bank"
    elseif loc == "Bags" then group = "bags" end
    local opts = {
        owner = owner,
        locationGroup = group,
        where = item.where,
        slotid = item.slotid,
        slotname = item.slotname,
        nodrop = item.nodrop,
        attuned = item.attuned,
        attunable = item.attunable,
    }
    local qty = opts_qty_from(item)
    if qty then opts.qty = qty end
    if item.stack ~= nil then opts.stack = item.stack end
    return opts
end

function M.context_opts(base, row_or_item, owner)
    local opts = {}
    if type(base) == "table" then
        for k, v in pairs(base) do opts[k] = v end
    end
    local pickup = nil
    if type(row_or_item) == "table" then
        if row_or_item.owner then
            pickup = M.pickup_opts_from_row(row_or_item)
        else
            pickup = M.pickup_opts_from_item(row_or_item, owner)
        end
    end
    if pickup then
        for k, v in pairs(pickup) do opts[k] = v end
    end
    return opts
end

function M.can_pickup(opts)
    opts = opts or {}
    if not is_local_owner(opts.owner) then
        return false, "Pickup only works on this character's bags and bank."
    end

    local group = tostring(opts.locationGroup or "")
    local where = tostring(opts.where or "")
    if group == "installed_aug" or where == "installed_aug" or group == "equipped" or where == "equipped" then
        return false, nil
    end
    if group ~= "bags" and group ~= "bank" then
        return false, nil
    end

    local slotid = tonumber(opts.slotid)
    local slotname = opts.slotname
    local inner = tonumber(slotname)

    if group == "bags" then
        if not slotid or slotid < 23 or slotid > 34 then return false, nil end
        if tostring(slotname) == "Bag" then return false, nil end
        if inner and inner >= 1 then
            return true, string.format("Pick up from pack %d slot %d.", slotid - 22, inner)
        end
        if trim(opts.name or "") ~= "" then
            return true, "Pick up to cursor (inventory)."
        end
        return false, nil
    end

    if group == "bank" then
        if not slotid or slotid < 1 or slotid > 24 then return false, nil end
        if inner and inner > 0 then
            return true, string.format("Pick up from bank %d (bag slot %d). Banker must be nearby.", slotid, inner)
        end
        return true, string.format("Pick up from bank slot %d. Banker must be nearby.", slotid)
    end

    return false, nil
end

function M.pickup_item(name, opts)
    name = trim(name)
    opts = opts or {}
    opts.name = name
    local can, tip = M.can_pickup(opts)
    if not can then
        M.status_msg = tip or "Cannot pick up this item."
        return false
    end

    local group = tostring(opts.locationGroup or "")
    local slotid = tonumber(opts.slotid)
    local inner = tonumber(opts.slotname)

    if group == "bags" then
        local pack = (slotid or 0) - 22
        if inner and inner >= 1 and pack >= 1 and pack <= 12 then
            mq.cmdf("/shift /itemnotify in pack%d %d leftmouseup", pack, inner)
            M.status_msg = string.format("Picking up %s (pack %d #%d).", name ~= "" and name or "item", pack, inner)
            return true
        end
        if name ~= "" then
            mq.cmdf('/shift /itemnotify "%s" leftmouseup', name)
            M.status_msg = "Picking up " .. name .. "."
            return true
        end
    elseif group == "bank" and slotid and slotid >= 1 and slotid <= 24 then
        if inner and inner > 0 then
            mq.cmdf("/shift /itemnotify in bank%d %d leftmouseup", slotid, inner)
        else
            mq.cmdf("/shift /itemnotify bank%d leftmouseup", slotid)
        end
        M.status_msg = string.format("Picking up %s from bank.", name ~= "" and name or "item")
        return true
    end

    M.status_msg = "Pickup failed — missing slot data."
    return false
end

local function safe_http_url(url)
    if ShellOpen then return ShellOpen.isSafeHttpUrl(url) end
    url = trim(url)
    if url == "" then return false end
    local lower = url:lower()
    if not (lower:match("^https://") or lower:match("^http://")) then return false end
    if url:find("[%c%s\"'`&|<>^]") then return false end
    return true
end

local function open_url_silent(url)
    url = trim(url)
    if not safe_http_url(url) then return false end
    if ShellOpen then return ShellOpen.shellOpenUrl(url) end
    return false
end

local function looks_like_item_link(text)
    return tostring(text or ""):find("\x12") ~= nil
end

function M.resolve_item_link(name)
    name = trim(name)
    if name == "" then return "" end
    local linkDB = mq.TLO.LinkDB
    if linkDB then
        local ok, link = pcall(function() return linkDB("=" .. name)() end)
        if ok and looks_like_item_link(link) then return link end
    end
    local fi = mq.TLO.FindItem and mq.TLO.FindItem("=" .. name)
    if fi and fi() then
        local ok, link = pcall(function() return fi.ItemLink("CLICKABLE")() end)
        if ok and looks_like_item_link(link) then return link end
    end
    return ""
end

function M.looks_like_item_link(text)
    return looks_like_item_link(text)
end

-- Observed-link cache: raw links seen in chat/actor traffic this session,
-- keyed by item id and normalized name (LRU-capped). Makes announce links
-- independent of whether the ANNOUNCING character happens to possess the item
-- or run MQ2LinkDB - if any box linked it recently, we can re-link it.
local observed_links = { by_id = {}, by_name = {}, order = {} }
local OBSERVED_LINK_MAX = 200

local function norm_link_name(name)
    return trim(name):lower():gsub("%s+", " ")
end

function M.remember_item_link(name, item_id, link)
    link = tostring(link or "")
    if not looks_like_item_link(link) then return false end
    item_id = tonumber(item_id) or 0
    local nkey = norm_link_name(name)
    if item_id <= 0 and nkey == "" then return false end
    if item_id > 0 then
        if observed_links.by_id[item_id] == nil then
            observed_links.order[#observed_links.order + 1] = { kind = "id", key = item_id }
        end
        observed_links.by_id[item_id] = link
    end
    if nkey ~= "" then
        if observed_links.by_name[nkey] == nil then
            observed_links.order[#observed_links.order + 1] = { kind = "name", key = nkey }
        end
        observed_links.by_name[nkey] = link
    end
    while #observed_links.order > OBSERVED_LINK_MAX do
        local old = table.remove(observed_links.order, 1)
        if old.kind == "id" then
            observed_links.by_id[old.key] = nil
        else
            observed_links.by_name[old.key] = nil
        end
    end
    return true
end

function M.observed_link_for(name, item_id)
    item_id = tonumber(item_id) or 0
    local nkey = norm_link_name(name)
    if nkey ~= "" and observed_links.by_name[nkey] then
        return observed_links.by_name[nkey]
    end
    if item_id > 0 and observed_links.by_id[item_id] then
        return observed_links.by_id[item_id]
    end
    return ""
end

function M.observed_link_count()
    return #observed_links.order
end

function M.resolve_announce_link(name, link, item_id)
    link = tostring(link or "")
    if looks_like_item_link(link) then return link end
    item_id = tonumber(item_id) or 0
    -- A link any box put in chat recently beats possession-dependent lookups.
    local seen = M.observed_link_for(name, item_id)
    if seen ~= "" then return seen end
    local named = M.resolve_item_link(name)
    if named ~= "" then return named end
    if item_id > 0 then
        local ok, fi = pcall(function() return mq.TLO.FindItem and mq.TLO.FindItem(item_id) end)
        if ok and fi and fi() then
            local ok2, got = pcall(function() return fi.ItemLink("CLICKABLE")() end)
            if ok2 and looks_like_item_link(got) then return got end
        end
    end
    return ""
end

local function close_item_inspect_windows()
    local names = { "ItemDisplayWindow", "ITEMDISPLAYWINDOW" }
    for _, name in ipairs(names) do
        pcall(function()
            local w = mq.TLO.Window(name)
            if w and w() and w.Open and w.Open() and w.Close then w.Close() end
        end)
    end
    pcall(function()
        local w = mq.TLO.DisplayItem and mq.TLO.DisplayItem.Window
        if w and w() and w.Open and w.Open() and w.Close then w.Close() end
    end)
end

function M.inspect_item(name, id)
    name = trim(name)
    id = tonumber(id) or 0
    local now = os.clock()
    if (now - last_inspect_at) < INSPECT_DEBOUNCE_S then
        M.status_msg = "Inspect cooldown - wait a moment."
        return false
    end
    local link = M.resolve_announce_link(name, nil, id)
    if link ~= "" then
        close_item_inspect_windows()
        mq.cmd("/executelink " .. link)
        last_inspect_at = now
        M.status_msg = "Inspecting " .. (name ~= "" and name or ("id " .. tostring(id)))
        return true
    end
    M.status_msg = "No item link available for " .. (name ~= "" and name or "?")
    return false
end

function M.open_alla_item(id)
    id = tonumber(id)
    if not id or id <= 0 then
        M.status_msg = "No item id available for Alla."
        return false
    end

    local url = M.alla_url(id)
    if not safe_http_url(url) then
        M.status_msg = "Invalid Alla URL."
        return false
    end

    local ok = open_url_silent(url)
    M.status_msg = ok and ("Opening Alla item " .. tostring(math.floor(id))) or "Alla open failed."
    return ok and true or false
end

function M.alla_url(id)
    id = tonumber(id)
    if not id or id <= 0 then return "" end
    return "https://lazaruseq.com/alla/items/" .. tostring(math.floor(id))
end

function M.alla_spell_url(id)
    id = tonumber(id)
    if not id or id <= 0 then return "" end
    return "https://lazaruseq.com/alla/spells/" .. tostring(math.floor(id))
end

function M.resolve_spell_id(name)
    name = trim(name):gsub("^Spell:%s*", ""):gsub("^Tome of%s+", "")
    if name == "" or not mq.TLO.Spell then return 0 end
    local ok, id = pcall(function()
        local spell = mq.TLO.Spell(name)
        if spell and spell() and spell.ID then return tonumber(spell.ID()) or 0 end
        return 0
    end)
    return ok and (tonumber(id) or 0) or 0
end

function M.open_alla_spell(name_or_id)
    local id = tonumber(name_or_id)
    if not id or id <= 0 then id = M.resolve_spell_id(name_or_id) end
    if not id or id <= 0 then
        M.status_msg = "No spell id available for Alla."
        return false
    end

    local url = M.alla_spell_url(id)
    if not safe_http_url(url) then
        M.status_msg = "Invalid Alla spell URL."
        return false
    end

    local ok = open_url_silent(url)
    M.status_msg = ok and ("Opening Alla spell " .. tostring(math.floor(id))) or "Alla spell open failed."
    return ok and true or false
end

function M.copy_name(name)
    name = trim(name)
    if name == "" then return false end
    if ImGui.SetClipboardText then pcall(ImGui.SetClipboardText, name) end
    M.status_msg = "Copied " .. name
    return true
end

function M.copy_text(label, text)
    text = trim(text)
    if text == "" then return false end
    if ImGui.SetClipboardText then pcall(ImGui.SetClipboardText, text) end
    M.status_msg = "Copied " .. trim(label or "text")
    return true
end

local function set_status(ok, detail)
    M.status_msg = tostring(detail or (ok and "Done." or "Action failed."))
    return ok
end

local function popup_suffix(suffix)
    return tostring(suffix or ""):gsub("##", "_")
end

function M.reset_popup_frame()
    context_body_suffix = nil
end

function M.context_needed(suffix)
    suffix = popup_suffix(suffix)
    if M.active_context_suffix == suffix then return true end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() then return true end
    return false
end

-- confirm_label + run: single-button (legacy). Optional 5th arg:
--   actions = { { label=, run=, primary= }, ... }
--   qty_edit = { min=, max=, value= }  (InputInt when max > 1)
--   sync_preview = function(pending)  (refresh lines after qty change)
--   modal = true  (BeginPopupModal — bank Give To)
local function queue_preview(title, lines, confirm_label, run, extra)
    extra = type(extra) == "table" and extra or {}
    M.pending_action = {
        title = trim(title),
        lines = type(lines) == "table" and lines or {},
        confirm_label = trim(confirm_label) ~= "" and trim(confirm_label) or "Confirm",
        run = run,
        actions = type(extra.actions) == "table" and extra.actions or nil,
        qty_edit = type(extra.qty_edit) == "table" and extra.qty_edit or nil,
        sync_preview = type(extra.sync_preview) == "function" and extra.sync_preview or nil,
        modal = extra.modal == true,
    }
    M.pending_open = true
    M.status_msg = "Pending: " .. (M.pending_action.title ~= "" and M.pending_action.title or "action")
    if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
end

local function run_pending_fn(run)
    if type(run) ~= "function" then
        M.status_msg = "No action queued."
        return
    end
    local ran, ok, detail = pcall(run)
    if ran then
        set_status(ok, detail)
    else
        M.status_msg = "Action failed: " .. tostring(ok)
    end
end

local function preview_or_status(ok, preview)
    if ok then return preview end
    M.status_msg = tostring(preview or "Could not build preview.")
    return nil
end

local function preview_line_text_color(line)
    if type(line) == "table" then
        return tostring(line.text or line[1] or ""), line.color or Theme.dim
    end
    local text = tostring(line or "")
    local lower = text:lower()
    if lower:find("^blocked:") or lower:find("^guard:") then return text, Theme.amber or Theme.gold end
    if lower:find("^warning:") or lower:find("^navigat") or lower:find("^will navigate") then
        return text, Theme.amber or Theme.gold
    end
    if lower:find("^item:") then return text, Theme.item end
    if lower:find("^from:") then return text, Theme.online or Theme.green end
    if lower:find("^to:") then return text, Theme.sync or Theme.blue end
    if lower:find("^zone:") then return text, Theme.value or Theme.cyan end
    if lower:find("^location:") or lower:find("^slot:") or lower:find("^result:") then return text, Theme.value or Theme.green end
    if lower:find("^qty available:") or lower:find("^give qty:") then return text, Theme.value or Theme.cyan end
    if lower:find("^transport:") or lower:find("^requires:") then return text, Theme.section or Theme.header end
    if lower:find("^command:") then return text, Theme.dim end
    if lower:find("no ini rule") or lower:find("^mode:") then return text, Theme.dim end
    return text, Theme.dim
end

local function mark_bank_give_inflight(source, recipient, item_name, item_id)
    M.in_flight_give = {
        kind = "bank",
        source = trim(source),
        recipient = trim(recipient),
        item = trim(item_name),
        id = math.floor(tonumber(item_id) or 0),
        at = os.clock(),
        until_at = os.clock() + IN_FLIGHT_TTL_S,
    }
end

function M.stop_in_flight_give()
    local flight = M.in_flight_give
    if not flight then
        M.status_msg = "No bank give in progress."
        return false
    end
    local source = flight.source
    M.in_flight_give = nil
    if not integrations or not integrations.stop_source_nav then
        M.status_msg = "Stop unavailable."
        return false
    end
    local ok, detail = integrations.stop_source_nav(source)
    set_status(ok, detail)
    return ok
end

function M.draw_in_flight()
    local flight = M.in_flight_give
    if not flight then return end
    if os.clock() > (tonumber(flight.until_at) or 0) then
        M.in_flight_give = nil
        return
    end
    local who = flight.source ~= "" and flight.source or "source"
    local item = flight.item ~= "" and flight.item or ("id " .. tostring(flight.id))
    col_text(Theme.amber or Theme.gold, string.format("Bank give: %s navigating / pulling for %s…", who, item))
    ImGui.SameLine()
    if ImGui.Button("Stop Nav##tg_stop_bank_give") then
        M.stop_in_flight_give()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("/nav stop + /endmacro on the source character.")
    end
end

local function preview_lines_for_ini(preview, action_label)
    return {
        tostring(action_label or "Write rule"),
        "File: " .. tostring(preview.file or preview.path or "?"),
        "Section: [" .. tostring(preview.section or "?") .. "]",
        "Key: " .. tostring(preview.key or "?"),
        "Current: " .. (tostring(preview.existing or "") ~= "" and tostring(preview.existing) or "(none)"),
        "New: " .. tostring(preview.value or ""),
    }
end

function M.draw_pending_modal()
    local pending = M.pending_action
    if not pending then return end
    if M.pending_open and ImGui.OpenPopup then
        ImGui.OpenPopup(PREVIEW_POPUP)
        M.pending_open = false
    end
    local opened = false
    if pending.modal and ImGui.BeginPopupModal then
        local flags = (ImGuiWindowFlags and ImGuiWindowFlags.AlwaysAutoResize) or 0
        opened = not not ImGui.BeginPopupModal(PREVIEW_POPUP, nil, flags)
    elseif ImGui.BeginPopup then
        opened = not not ImGui.BeginPopup(PREVIEW_POPUP)
    end
    if not opened then return end

    col_text(Theme.item, pending.title ~= "" and pending.title or "Confirm Action")
    ImGui.Separator()
    for _, line in ipairs(pending.lines or {}) do
        local text, color = preview_line_text_color(line)
        col_text(color, text)
    end

    local qty_edit = pending.qty_edit
    if qty_edit and (tonumber(qty_edit.max) or 1) > 1 and ImGui.InputInt then
        ImGui.Separator()
        local max_q = math.max(1, math.floor(tonumber(qty_edit.max) or 1))
        local min_q = math.max(1, math.floor(tonumber(qty_edit.min) or 1))
        local cur = math.floor(tonumber(qty_edit.value) or max_q)
        if cur < min_q then cur = min_q end
        if cur > max_q then cur = max_q end
        qty_edit.value = cur
        ImGui.Text("Give qty")
        ImGui.SameLine()
        local next_v, changed = ImGui.InputInt("##tg_preview_give_qty", cur, 1, 5)
        if changed then
            next_v = math.floor(tonumber(next_v) or cur)
            if next_v < min_q then next_v = min_q end
            if next_v > max_q then next_v = max_q end
            qty_edit.value = next_v
            if pending.sync_preview then
                pcall(pending.sync_preview, pending)
            end
        end
    end

    ImGui.Separator()
    local actions = pending.actions
    if type(actions) == "table" and #actions > 0 then
        for i, action in ipairs(actions) do
            if i > 1 then ImGui.SameLine() end
            local label = trim(action.label)
            if label == "" then label = "Confirm" end
            if ImGui.Button(label .. "##tg_preview_act_" .. tostring(i)) then
                local run = action.run
                M.pending_action = nil
                M.pending_open = false
                run_pending_fn(run)
                if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
            end
        end
    else
        if ImGui.Button((pending.confirm_label or "Confirm") .. "##tg_preview_confirm") then
            local run = pending.run
            M.pending_action = nil
            M.pending_open = false
            run_pending_fn(run)
            if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
        end
    end
    ImGui.SameLine()
    if ImGui.Button("Cancel##tg_preview_cancel") then
        M.pending_action = nil
        M.pending_open = false
        M.status_msg = "Action cancelled."
        if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
    end
    ImGui.EndPopup()
end

function M.queue_turbogive_rule(name, recipient, qty, opts, extra_lines, title, confirm_label)
    name = trim(name)
    recipient = trim(recipient)
    opts = opts or {}
    if not integrations then
        M.status_msg = "TurboGive integration is not available."
        return false
    end

    local preview = preview_or_status(integrations.preview_turbogive_rule(name, recipient, qty or 0, opts))
    if not preview then return false end

    local lines = preview_lines_for_ini(preview, "Write TurboGive rule")
    lines[#lines + 1] = "Recipient: " .. tostring(preview.recipient or recipient)
    lines[#lines + 1] = "Qty: " .. ((tonumber(preview.qty) or 0) > 0 and tostring(preview.qty) or "all copies")
    if tostring(preview.owner or "") ~= "" then lines[#lines + 1] = "Owner: " .. tostring(preview.owner) end
    if tostring(preview.sourceLocation or "") ~= "" then lines[#lines + 1] = "Source: " .. tostring(preview.sourceLocation) end
    for _, line in ipairs(extra_lines or {}) do
        if trim(line) ~= "" then lines[#lines + 1] = tostring(line) end
    end

    queue_preview(title or "TurboGive Rule", lines, confirm_label or "Write", function()
        return integrations.set_turbogive_rule(name, recipient, qty or 0, opts)
    end)
    return true
end

-- True when the configured transport can build a live "Give now" command for
-- this source->recipient pair (false e.g. on DanNet Alt with no target template).
function M.give_now_available(item_id, source, recipient, opts)
    if not integrations or not integrations.preview_give_now then return false end
    local ok, preview = pcall(integrations.preview_give_now, "", item_id, source, recipient, opts or {})
    return ok and preview == true
end

function M.bank_give_now_available(item_id, source, recipient, opts)
    if not integrations or not integrations.preview_bank_give_now then return false end
    local ok, preview = pcall(integrations.preview_bank_give_now, "", item_id, source, recipient, opts or {})
    return ok and preview == true
end

local function give_avail_qty(opts)
    local q = math.floor(tonumber(opts and opts.qty) or 1)
    if q < 1 then q = 1 end
    return q
end

local function replace_preview_prefix(lines, prefix, text)
    prefix = tostring(prefix or ""):lower()
    for i, line in ipairs(lines or {}) do
        local raw = type(line) == "table" and tostring(line.text or line[1] or "") or tostring(line or "")
        if raw:lower():sub(1, #prefix) == prefix then
            lines[i] = text
            return
        end
    end
    lines[#lines + 1] = text
end

-- Shared Give 1 / All / Qty confirm for bags (send_stack) and bank (_banksendstack).
local function queue_give_qty_confirm(kind, item_name, item_id, source, recipient, opts, extra_lines, preview)
    local avail = give_avail_qty(opts)
    local is_bank = kind == "bank"
    local title = is_bank and "Give To - Pull from Bank" or "Give Gear Now"
    local one_label = is_bank and "Pull & Give 1" or "Give 1"

    local function one_command()
        if is_bank then
            return integrations.bank_give_now_command(item_id, source, recipient)
        end
        return integrations.give_now_command(item_id, source, recipient)
    end

    local function stack_command(qty)
        if is_bank then
            return integrations.bank_send_stack_command(item_id, qty, source, recipient)
        end
        return integrations.send_stack_command(item_id, item_name, qty, source, recipient)
    end

    local function run_one()
        if is_bank then
            local ok, detail = integrations.bank_give_now(item_name, item_id, source, recipient, opts)
            if ok then mark_bank_give_inflight(source, recipient, item_name, item_id) end
            return ok, detail
        end
        return integrations.give_now(item_name, item_id, source, recipient, opts)
    end

    local function run_stack(qty)
        qty = math.max(1, math.min(avail, math.floor(tonumber(qty) or 1)))
        if is_bank then
            local ok, detail = integrations.bank_send_stack(item_name, item_id, qty, source, recipient, opts)
            if ok then mark_bank_give_inflight(source, recipient, item_name, item_id) end
            return ok, detail
        end
        return integrations.send_stack(item_name, item_id, qty, source, recipient, opts)
    end

    local lines
    if is_bank then
        lines = {
            "Pull from bank, then live trade - no INI rule written.",
            "Warning: if the bank is closed, the source will navigate to a banker.",
            "Cancel here = no movement. After start: use Stop Nav in TurboGear.",
            "Item: " .. (item_name ~= "" and item_name or ("id " .. tostring(preview.id))),
            "From: " .. tostring(preview.source or source),
            "To: " .. tostring(preview.recipient or recipient),
            "Zone: " .. tostring(preview.zone or "?") .. (preview.zoneSource and preview.zoneSource ~= "" and (" (" .. tostring(preview.zoneSource) .. ")") or ""),
            "Requires: source can reach/open a banker, recipient is in same zone.",
            "Macro verifies exact item ID in bank before moving it.",
            "Transport: " .. tostring(preview.transport or "?"),
            "Qty available: " .. tostring(avail),
        }
    else
        lines = {
            "Live trade now - no INI rule written.",
            "Item: " .. (item_name ~= "" and item_name or ("id " .. tostring(preview.id))),
            "From: " .. tostring(preview.source or source),
            "To: " .. tostring(preview.recipient or recipient),
            "Zone: " .. tostring(preview.zone or "?") .. (preview.zoneSource and preview.zoneSource ~= "" and (" (" .. tostring(preview.zoneSource) .. ")") or ""),
            "Transport: " .. tostring(preview.transport or "?"),
            "Qty available: " .. tostring(avail),
        }
    end

    local cmd0 = avail > 1 and stack_command(avail) or one_command()
    if avail > 1 then
        lines[#lines + 1] = "Give qty: " .. tostring(avail)
    end
    lines[#lines + 1] = "Command: " .. tostring((cmd0 ~= "" and cmd0) or preview.command or "")
    for _, line in ipairs(extra_lines or {}) do
        if trim(line) ~= "" then lines[#lines + 1] = tostring(line) end
    end

    local modal_extra = is_bank and { modal = true } or nil
    if avail <= 1 then
        queue_preview(title, lines, one_label, run_one, modal_extra)
        return true
    end

    local qty_state = { min = 1, max = avail, value = avail }
    local function sync_preview(pending)
        local q = math.max(1, math.min(avail, math.floor(tonumber(pending.qty_edit and pending.qty_edit.value) or avail)))
        pending.qty_edit.value = q
        replace_preview_prefix(pending.lines, "give qty:", "Give qty: " .. tostring(q))
        local cmd = stack_command(q)
        replace_preview_prefix(pending.lines, "command:", "Command: " .. tostring(cmd ~= "" and cmd or "?"))
    end

    queue_preview(title, lines, one_label, run_one, {
        modal = is_bank,
        qty_edit = qty_state,
        sync_preview = sync_preview,
        actions = {
            {
                label = is_bank and string.format("Pull & Give All (%d)", avail) or string.format("Give All (%d)", avail),
                primary = true,
                run = function()
                    return run_stack(avail)
                end,
            },
            {
                label = one_label,
                run = run_one,
            },
            {
                label = is_bank and "Pull & Give Qty" or "Give Qty",
                run = function()
                    return run_stack(qty_state.value)
                end,
            },
        },
    })
    return true
end

-- Live cross-box hand-off (no INI rule). Shows a confirm modal first because the
-- trade is immediate and irreversible. Stack rows offer Give 1 / All / Qty.
function M.give_now_action(item_name, item_id, source, recipient, opts, extra_lines)
    item_name = trim(item_name)
    recipient = trim(recipient)
    source = trim(source)
    opts = opts or {}
    if not integrations then
        M.status_msg = "TurboGive integration is not available."
        return false
    end
    local ok, preview_or_err = integrations.preview_give_now(item_name, item_id, source, recipient, opts)
    local preview = preview_or_status(ok, preview_or_err)
    if not preview then
        queue_preview("Give Now Blocked", {
            "Live trade now - no INI rule written.",
            "Item: " .. (item_name ~= "" and item_name or ("id " .. tostring(item_id))),
            "From: " .. tostring(source),
            "To: " .. tostring(recipient),
            "Blocked: " .. tostring(preview_or_err or "Could not build preview."),
        }, "OK", function()
            return true, "Give Now blocked."
        end)
        return false
    end
    return queue_give_qty_confirm("bags", item_name, item_id, source, recipient, opts, extra_lines, preview)
end

-- Live bank withdrawal plus cross-box hand-off. Pulls qty from bank (QuantityWnd),
-- then SendMyItem / SendMyStack. No TurboGive INI rule is written.
function M.bank_give_now_action(item_name, item_id, source, recipient, opts, extra_lines)
    item_name = trim(item_name)
    recipient = trim(recipient)
    source = trim(source)
    opts = opts or {}
    if not integrations then
        M.status_msg = "TurboGive integration is not available."
        return false
    end
    local ok, preview_or_err = integrations.preview_bank_give_now(item_name, item_id, source, recipient, opts)
    local preview = preview_or_status(ok, preview_or_err)
    if not preview then
        queue_preview("Give To Blocked", {
            "Pull from bank, then live trade - no INI rule written.",
            "Item: " .. (item_name ~= "" and item_name or ("id " .. tostring(item_id))),
            "From: " .. tostring(source),
            "To: " .. tostring(recipient),
            "Blocked: " .. tostring(preview_or_err or "Could not build preview."),
        }, "OK", function()
            return true, "Give To blocked."
        end)
        return false
    end
    return queue_give_qty_confirm("bank", item_name, item_id, source, recipient, opts, extra_lines, preview)
end

function M.show_action_notice(title, lines)
    queue_preview(title or "TurboGear Action", lines or {}, "OK", function()
        return true, "No action written."
    end)
    return true
end

local function push_menu_text_color(color)
    if not color or not ImGuiCol or not ImGuiCol.Text or not ImGui.PushStyleColor then return false end
    return pcall(ImGui.PushStyleColor, ImGuiCol.Text, color[1], color[2], color[3], color[4] or 1) == true
end

local function begin_menu_colored(label, color)
    local pushed = push_menu_text_color(color)
    local open = ImGui.BeginMenu and ImGui.BeginMenu(label)
    if pushed then ImGui.PopStyleColor(1) end
    return open
end

local function selectable_colored(label, color)
    local pushed = push_menu_text_color(color)
    local clicked = ImGui.Selectable(label)
    if pushed then ImGui.PopStyleColor(1) end
    return clicked
end

local function draw_integrations(name, id, suffix, opts)
    if not integrations then return end
    ImGui.Separator()
    if ImGui.Selectable("Search Inventory/Lists##tgctx_search_all_" .. suffix) then
        set_status(integrations.search_inventory_and_lists(name))
    end

    local slot_id = nil
    local ok_items, items = pcall(require, 'items')
    if opts.slotname and ok_items and items and items.slot_id_for_label then
        slot_id = items.slot_id_for_label(opts.slotname)
    end
    if not slot_id then
        local numeric_slot = tonumber(opts.slotid)
        if numeric_slot and numeric_slot >= 0 and numeric_slot <= 22 then slot_id = numeric_slot end
    end
    if slot_id then
        if ImGui.Selectable("Open Suggest For Slot##tgctx_suggest_slot_" .. suffix) then
            set_status(integrations.open_suggest_for_slot(opts.targetKey or "__self__", slot_id))
        end
    end

    if begin_menu_colored("Add to List...##tgctx_bis_menu_" .. suffix, Theme.item or Theme.cyan) then
        local slot_name = opts.slotname or opts.sourceLocation or ""
        local add_opts = {}
        if trim(opts.installedIn or "") ~= "" then
            add_opts.isAug = true
            add_opts.group = "Aug"
            add_opts.hostSlot = opts.hostSlotname or slot_name
            add_opts.socket = tonumber(opts.augIndex or opts.socket)
        end
        local lists = integrations.bis_list_options()
        if #lists == 0 then
            ImGui.TextDisabled("No user lists yet")
        end
        for _, rec in ipairs(lists) do
            local label = tostring(rec.name or rec.id)
            if rec.selected then label = label .. " (selected)" end
            if ImGui.Selectable(label .. "##tgctx_bis_list_" .. tostring(rec.id) .. "_" .. suffix) then
                local preview = preview_or_status(integrations.preview_bis_add(rec.id, name, id, slot_name, add_opts))
                if preview then
                    queue_preview("Add To List", {
                        "List: " .. tostring(preview.list or "?"),
                        "Item: " .. tostring(preview.item ~= "" and preview.item or ("item " .. tostring(preview.id or ""))),
                        "ID: " .. tostring(preview.id and preview.id > 0 and preview.id or "-"),
                        "Slot: " .. tostring(preview.slot ~= "" and preview.slot or "-"),
                        "Group: " .. tostring(preview.group ~= "" and preview.group or "-"),
                        "Socket: " .. tostring(preview.socket and preview.socket or "-"),
                    }, "Add", function()
                        return integrations.add_to_bis_list(rec.id, name, id, slot_name, add_opts)
                    end)
                end
            end
        end
        ImGui.Separator()
        if ImGui.Selectable("Create new list...##tgctx_bis_new_" .. suffix) then
            queue_preview("Create List + Add", {
                "List: new user list",
                "Item: " .. tostring(name ~= "" and name or ("item " .. tostring(id or ""))),
                "ID: " .. tostring(tonumber(id) and tonumber(id) > 0 and math.floor(tonumber(id)) or "-"),
                "Slot: " .. tostring(slot_name ~= "" and slot_name or "-"),
            }, "Create", function()
                return integrations.create_list_and_add(name, id, slot_name, add_opts)
            end)
        end
        ImGui.EndMenu()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Add this item to any TurboBiS user list, or create a new list.")
    end

    if opts.loadoutListId and opts.loadoutEntryIndex and ImGui.BeginMenu and ImGui.BeginMenu("Move to Socket##tgctx_loadout_aug_" .. suffix) then
        for socket = 1, 6 do
            if ImGui.Selectable("Socket " .. tostring(socket) .. "##tgctx_loadout_sock_" .. tostring(socket) .. "_" .. suffix) then
                set_status(integrations.move_loadout_aug(opts.loadoutListId, opts.loadoutEntryIndex, socket))
            end
        end
        ImGui.EndMenu()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip and opts.loadoutListId then
        ImGui.SetTooltip("Reassign this planned aug to another socket on the loadout list.")
    end

    if begin_menu_colored("Keep Qty##tgctx_stock_" .. suffix, Theme.amber or Theme.gold) then
        for _, count in ipairs(integrations.stock_count_options()) do
            if ImGui.Selectable(tostring(count) .. " across cache##tgctx_stock_" .. tostring(count) .. "_" .. suffix) then
                local qty = count
                queue_preview("Keep Qty Rule", {
                    "Item: " .. tostring(name),
                    "ID: " .. tostring(tonumber(id) and tonumber(id) > 0 and math.floor(tonumber(id)) or "-"),
                    "Target: " .. tostring(qty),
                    "Scope: all cached inventory",
                    "Storage: TurboGear Keep Qty cache",
                }, "Save", function()
                    return integrations.add_keep_qty(name, id, qty, "all")
                end)
            end
        end
        ImGui.Separator()
        if ImGui.Selectable("Open Stock View##tgctx_stock_open_" .. suffix) then
            set_status(integrations.open_stock_view())
        end
        ImGui.EndMenu()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Tracks desired stock from cached inventory only.")
    end

    local bank_ctx = tostring(opts.locationGroup or ""):lower() == "bank" or tostring(opts.where or ""):lower() == "bank"
    local give_color = Theme.online or Theme.green
    if not bank_ctx and begin_menu_colored("Give Now##tgctx_live_give_" .. suffix, give_color) then
        local targets = integrations.give_target_options(opts.owner)
        if #targets == 0 then
            ImGui.TextDisabled("No cached targets")
        end
        for _, target in ipairs(targets) do
            if ImGui.Selectable(tostring(target.label or target.name) .. "##tgctx_live_give_target_" .. suffix .. "_" .. target.name) then
                M.give_now_action(name, id, opts.owner, target.name, opts, {
                    "Source: " .. tostring(opts.sourceLocation or "-"),
                })
            end
        end
        ImGui.Separator()
        ImGui.TextDisabled("Live, same-zone handoff only.")
        ImGui.EndMenu()
    end
    if not bank_ctx and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Runs a one-time TurboGive _senditem command. No INI rule is written.")
    end

    if bank_ctx and begin_menu_colored("Give To##tgctx_bank_give_" .. suffix, give_color) then
        local targets = integrations.give_target_options(opts.owner)
        if #targets == 0 then
            ImGui.TextDisabled("No cached targets")
        end
        for _, target in ipairs(targets) do
            if ImGui.Selectable(tostring(target.label or target.name) .. "##tgctx_bank_give_target_" .. suffix .. "_" .. target.name) then
                M.bank_give_now_action(name, id, opts.owner, target.name, opts, {
                    "Source: " .. tostring(opts.sourceLocation or "-"),
                })
            end
        end
        ImGui.Separator()
        ImGui.TextDisabled("Confirms before navigating to a banker.")
        ImGui.EndMenu()
    end
    if bank_ctx and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Confirm first, then pull from bank and give. Opens Stop Nav if navigation starts. No INI rule.")
    end

    if begin_menu_colored("Advanced##tgctx_advanced_" .. suffix, Theme.dim or Theme.muted) then
        if ImGui.BeginMenu and ImGui.BeginMenu("Queue Give Rule##tgctx_give_" .. suffix) then
            local targets = integrations.give_target_options(opts.owner)
            if #targets == 0 then
                ImGui.TextDisabled("No cached targets")
            end
            for _, target in ipairs(targets) do
                if ImGui.BeginMenu(tostring(target.label or target.name) .. "##tgctx_give_target_" .. suffix .. "_" .. target.name) then
                    if ImGui.Selectable("All copies##tgctx_give_all_" .. suffix .. "_" .. target.name) then
                        local write_opts = {
                            id = id,
                            owner = opts.owner,
                            sourceLocation = opts.sourceLocation,
                        }
                        local preview = preview_or_status(integrations.preview_turbogive_rule(name, target.name, 0, write_opts))
                        if preview then
                            local lines = preview_lines_for_ini(preview, "Write TurboGive rule")
                            lines[#lines + 1] = "Recipient: " .. tostring(preview.recipient or target.name)
                            lines[#lines + 1] = "Qty: all copies"
                            if tostring(preview.owner or "") ~= "" then lines[#lines + 1] = "Owner: " .. tostring(preview.owner) end
                            if tostring(preview.sourceLocation or "") ~= "" then lines[#lines + 1] = "Source: " .. tostring(preview.sourceLocation) end
                            queue_preview("TurboGive Rule", lines, "Write", function()
                                return integrations.set_turbogive_rule(name, target.name, 0, write_opts)
                            end)
                        end
                    end
                    for _, count in ipairs(integrations.count_options()) do
                        if ImGui.Selectable(tostring(count) .. " max##tgctx_give_" .. tostring(count) .. "_" .. suffix .. "_" .. target.name) then
                            local qty = count
                            local write_opts = {
                                id = id,
                                owner = opts.owner,
                                sourceLocation = opts.sourceLocation,
                            }
                            local preview = preview_or_status(integrations.preview_turbogive_rule(name, target.name, qty, write_opts))
                            if preview then
                                local lines = preview_lines_for_ini(preview, "Write TurboGive rule")
                                lines[#lines + 1] = "Recipient: " .. tostring(preview.recipient or target.name)
                                lines[#lines + 1] = "Qty: " .. tostring(qty) .. " max"
                                if tostring(preview.owner or "") ~= "" then lines[#lines + 1] = "Owner: " .. tostring(preview.owner) end
                                if tostring(preview.sourceLocation or "") ~= "" then lines[#lines + 1] = "Source: " .. tostring(preview.sourceLocation) end
                                queue_preview("TurboGive Rule", lines, "Write", function()
                                    return integrations.set_turbogive_rule(name, target.name, qty, write_opts)
                                end)
                            end
                        end
                    end
                    ImGui.EndMenu()
                end
            end
            ImGui.EndMenu()
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Writes a [GiveList] rule for later TurboGive distribution.")
        end
        if ImGui.Selectable("Open Transfers View##tgctx_give_open_" .. suffix) then
            set_status(integrations.open_transfers_view())
        end
        ImGui.EndMenu()
    end

    if begin_menu_colored("Set TurboLoot Rule##tgctx_tl_rule_" .. suffix, Theme.purple or Theme.bank) then
        for _, rec in ipairs(integrations.rule_options()) do
            if ImGui.Selectable(tostring(rec.label) .. "##tgctx_rule_" .. tostring(rec.value) .. "_" .. suffix) then
                local rule = rec.value
                local preview = preview_or_status(integrations.preview_turboloot_rule(name, rule))
                if preview then
                    queue_preview("TurboLoot Rule", preview_lines_for_ini(preview, "Write TurboLoot rule"), "Write", function()
                        return integrations.set_turboloot_rule(name, rule)
                    end)
                end
            end
        end
        if ImGui.BeginMenu("Keep Count##tgctx_rule_count_" .. suffix) then
            for _, count in ipairs(integrations.count_options()) do
                if ImGui.Selectable(tostring(count) .. "##tgctx_rule_count_" .. tostring(count) .. "_" .. suffix) then
                    local rule = tostring(count)
                    local preview = preview_or_status(integrations.preview_turboloot_rule(name, rule))
                    if preview then
                        queue_preview("TurboLoot Keep Count", preview_lines_for_ini(preview, "Write TurboLoot keep count"), "Write", function()
                            return integrations.set_turboloot_rule(name, rule)
                        end)
                    end
                end
            end
            ImGui.EndMenu()
        end
        ImGui.EndMenu()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Writes this item to [ItemLimits] in the active TurboLoot INI.")
    end
end

function M.draw_context(name, id, suffix, opts)
    name = trim(name)
    if name == "" or not ImGui.BeginPopupContextItem then return end
    if M.item_left_clicked and M.item_left_clicked() then
        M.link_item(name)
    end
    opts = opts or {}
    suffix = popup_suffix(suffix or name)
    if not M.context_needed(suffix) then return end
    if context_body_suffix == suffix then return end
    if not ImGui.BeginPopupContextItem("##tg_item_ctx_" .. suffix) then
        if M.active_context_suffix == suffix and (not ImGui.IsMouseDown or not ImGui.IsMouseDown(1)) then
            M.active_context_suffix = nil
            if context_body_suffix == suffix then context_body_suffix = nil end
        end
        return
    end
    context_body_suffix = suffix
    M.active_context_suffix = suffix
    col_text(Theme.item, name)
    if tonumber(id) and tonumber(id) > 0 then col_text(Theme.dim, "ID: " .. tostring(math.floor(tonumber(id)))) end
    ImGui.Separator()
    if tonumber(id) and tonumber(id) > 0 then
        if ImGui.Selectable("View on Alla##tgctx_alla_" .. suffix) then M.open_alla_item(id) end
        if ImGui.Selectable("Copy Alla URL##tgctx_alla_url_" .. suffix) then M.copy_text("Alla URL", M.alla_url(id)) end
    else
        ImGui.TextDisabled("View on Alla")
    end
    if ImGui.Selectable("Inspect in-game##tgctx_inspect_" .. suffix) then M.inspect_item(name, id) end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Opens EQ item window (closes any prior inspect first). For a stable view, use View on Alla.")
    end
    local can_pickup, pickup_tip = M.can_pickup(opts)
    if can_pickup then
        if selectable_colored("Pickup##tgctx_pickup_" .. suffix, Theme.online or Theme.green) then
            M.pickup_item(name, opts)
        end
        if pickup_tip and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip(pickup_tip)
        end
    end
    if ImGui.Selectable("Copy Name##tgctx_copy_" .. suffix) then M.copy_name(name) end
    draw_integrations(name, id, suffix, opts)
    ImGui.EndPopup()
end

function M.link_item(name)
    name = trim(name)
    if name == "" or name == "-" then return false end
    local now = os.clock()
    if name == last_link_name and (now - last_link_at) < 0.25 then return true end
    last_link_name = name
    last_link_at = now
    local arg = link_arg(name)
    if arg == "" then return false end
    mq.cmdf('/link %s', arg)
    M.status_msg = "Linking " .. name
    return true
end

function M.item_left_clicked()
    if ImGui.IsItemClicked and ImGui.IsItemClicked(0) then return true end
    if ImGui.IsItemHovered and ImGui.IsMouseClicked and ImGui.IsItemHovered() and ImGui.IsMouseClicked(0) then return true end
    return false
end

function M.draw_name(name, color, suffix, id, opts)
    name = tostring(name or "?")
    theme.colored_text(name, color or Theme.item)
    M.draw_context(name, id, suffix, opts)
end

-- Transient action feedback. status_msg is set from many call sites and is not
-- cleared by them; without a TTL the last message lingers forever and (when drawn
-- inline) permanently shifts the layout. Stamp an expiry the first time a given
-- message is seen and return "" once it lapses, so callers get self-clearing text.
M.STATUS_TTL = 4.0

--- Set status with an explicit TTL (seconds). Use for Dry Even / Dry Collect so
--- the header band keeps the summary longer than the default 4s blink.
function M.set_status(msg, ttl)
    M.status_msg = tostring(msg or "")
    M._status_seen = M.status_msg
    local life = tonumber(ttl)
    if not life or life <= 0 then life = tonumber(M.STATUS_TTL) or 4.0 end
    M._status_until = os.clock() + life
end

function M.status()
    local msg = M.status_msg or ""
    if msg == "" then return "" end
    if msg ~= M._status_seen then
        M._status_seen = msg
        M._status_until = os.clock() + (tonumber(M.STATUS_TTL) or 4.0)
    end
    if os.clock() >= (M._status_until or 0) then
        return ""
    end
    return msg
end

return M
