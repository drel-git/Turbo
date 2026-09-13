-- turbo_lib/transport.lua
-- Small targeted-command wrapper for Lua collectors.

local mq = require('mq')

local M = {}
local CACHE_TTL_S = 30.0
local resolver_cache = nil

local function trim(s)
    return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function clean_target(name)
    return trim(name):match('^[%w_]+$') and trim(name) or ''
end

local function normalize_cmd(cmd)
    cmd = trim(cmd)
    cmd = cmd:gsub('^/+', '')
    return trim(cmd)
end

local function load_config(force)
    local ok, cfg = pcall(require, 'turbogear.config')
    if not (ok and type(cfg) == 'table' and type(cfg.transport_command) == 'function') then
        return nil, 'config_unavailable'
    end
    if force ~= false and type(cfg.LoadSettings) == 'function' then pcall(cfg.LoadSettings) end
    return cfg, nil
end

local function profile_label(cfg)
    if not cfg then return 'E3' end
    local profile = nil
    if type(cfg.transport_profile) == 'function' then
        local ok, p = pcall(cfg.transport_profile)
        if ok and type(p) == 'table' then profile = p end
    end
    if profile and tostring(profile.label or '') ~= '' then return tostring(profile.label) end
    local key = tostring((cfg.Settings and cfg.Settings.transportProfile) or ''):lower()
    if key == 'eqbc' then return 'EQBC' end
    if key == 'dannet' then return 'DanNet' end
    if key == 'dannet_alt' then return 'DanNet Alt' end
    if key == 'custom' then return 'Custom' end
    return 'E3'
end

local function profile_key(cfg)
    local key = tostring((cfg and cfg.Settings and cfg.Settings.transportProfile) or ''):lower()
    if key == '' and type(cfg.transport_profile) == 'function' then
        local ok, p = pcall(cfg.transport_profile)
        if ok and type(p) == 'table' then key = tostring(p.key or ''):lower() end
    end
    return key ~= '' and key or 'e3'
end

local function target_template(cfg)
    if type(cfg.transport_template) ~= 'function' then return '' end
    local ok, template = pcall(cfg.transport_template, 'target')
    if not ok then return '' end
    return trim(template)
end

local function resolve_target(force)
    local now = os.clock()
    if force ~= true and type(resolver_cache) == 'table'
        and (now - (tonumber(resolver_cache.at) or 0)) < CACHE_TTL_S then
        return resolver_cache
    end

    local cfg, err = load_config(true)
    if not cfg then
        resolver_cache = {
            at = now,
            cfg = nil,
            key = 'e3',
            label = 'E3',
            template = '',
            route = 'e3_fallback',
            reason = err or 'config_unavailable',
        }
        return resolver_cache
    end

    local label = profile_label(cfg)
    local key = profile_key(cfg)
    local template = target_template(cfg)
    local route, reason
    if template == '' then
        route, reason = 'e3_fallback', 'target_template_empty'
    elseif not template:find('{name}', 1, true) then
        route, reason = 'e3_fallback', 'target_template_no_name'
    elseif key == 'e3' then
        route, reason = 'e3', 'configured'
    else
        route, reason = 'bridge', 'configured'
    end
    resolver_cache = {
        at = now,
        cfg = cfg,
        key = key,
        label = label,
        template = template,
        route = route,
        reason = reason,
    }
    return resolver_cache
end

local function configured_target_command(name, cmd, force)
    local resolved = resolve_target(force)
    local cfg = resolved.cfg
    if not cfg then return '', resolved.reason or 'config_unavailable', resolved.label or 'E3', resolved.route end
    if resolved.route == 'e3_fallback' then return '', resolved.reason, resolved.label, resolved.route end
    local rendered_ok, built = pcall(cfg.transport_command, 'target', cmd, name)
    if not rendered_ok then return '', 'render_failed', resolved.label, 'e3_fallback' end
    built = type(built) == 'string' and trim(built) or ''
    if built == '' then return '', 'render_empty', resolved.label, 'e3_fallback' end
    return built, nil, resolved.label, resolved.route
end

local function squelched(cmd)
    cmd = trim(cmd)
    if cmd == '' then return '' end
    if cmd:lower():match('^/squelch%s+') then return cmd end
    return '/squelch ' .. cmd
end

function M.target_command(name, cmd)
    name = clean_target(name)
    cmd = normalize_cmd(cmd)
    if name == '' then return nil, 'bad_target' end
    if cmd == '' then return nil, 'empty_command' end

    local built, reason, _, route = configured_target_command(name, cmd)
    if built ~= '' then return squelched(built), route or 'configured' end

    return string.format('/squelch /e3bct %s /%s', name, cmd), route or 'e3_fallback'
end

function M.send_target(name, cmd)
    local built, route = M.target_command(name, cmd)
    if not built or built == '' then return false, route or 'no_route' end
    mq.cmd(built)
    return true, built, route
end

function M._normalize_cmd_for_tests(cmd)
    return normalize_cmd(cmd)
end

function M.invalidate()
    resolver_cache = nil
end

function M.resolve(opts)
    opts = type(opts) == 'table' and opts or {}
    local resolved = resolve_target(opts.force == true)
    return {
        key = resolved.key,
        label = resolved.label,
        route = resolved.route,
        reason = resolved.reason,
        template = resolved.template,
        ttl_s = CACHE_TTL_S,
        age_s = os.clock() - (tonumber(resolved.at) or os.clock()),
    }
end

function M.route_hint(opts)
    local resolved = resolve_target(type(opts) == 'table' and opts.force == true)
    if resolved.route == 'e3' or resolved.route == 'e3_fallback' then
        return resolved.route
    end
    return 'bridge'
end

function M.route_hint_arg(opts)
    return ' route ' .. M.route_hint(opts)
end

function M.status()
    local resolved = resolve_target()
    if not resolved.cfg then
        return { label = 'E3 (fallback)', route = 'e3_fallback', reason = resolved.reason or 'config_unavailable' }
    end
    if resolved.route == 'e3_fallback' then
        return { label = resolved.label .. ' (target fallback: E3)', route = 'e3_fallback', reason = resolved.reason or 'fallback' }
    end
    return { label = resolved.label, route = resolved.route, reason = resolved.reason or 'configured' }
end

return M
