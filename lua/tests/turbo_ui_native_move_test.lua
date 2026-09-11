-- Run from repo root: luajit lua/tests/turbo_ui_native_move_test.lua
-- Native-move contract: no Lua drag loops, 0 settings writes while held,
-- 1 debounced write after settle.

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then
        pass = pass + 1
    else
        fail = fail + 1
        print('FAIL: ' .. tostring(msg))
    end
end

local function read_file(path)
    local f, err = io.open(path, 'r')
    if not f then error('cannot read ' .. path .. ': ' .. tostring(err)) end
    local src = f:read('*a')
    f:close()
    return src
end

local files = {
    'lua/Turbo/init.lua',
    'lua/Turbo/fleet_wallet.lua',
    'lua/Turbo/gains_view.lua',
    'lua/Turbo/ui/views/mini.lua',
    'lua/Turbo/theme.lua',
    'lua/turbogear/ui.lua',
    'lua/turbogear/tabs/worn.lua',
    'lua/TurboMobs.lua',
    'lua/TurboRolls.lua',
}

local forbidden = {
    'turboChromeDrag',
    'chromeDrag',
    'dragCurrentWindow',
    'ui_drag',
    'ResetMouseDragDelta',
    'ClearActiveID',
    '##watch_header_drag',
    '##full_header_drag',
    '##tr_header_drag',
}

for _, path in ipairs(files) do
    local src = read_file(path)
    for _, needle in ipairs(forbidden) do
        check(not src:find(needle, 1, true), path .. ' must not contain ' .. needle)
    end
    check(not src:find('ImGui%.SetWindowPos'), path .. ' must not call SetWindowPos')
end

do
    local f = io.open('lua/Turbo/ui_window.lua', 'r')
    check(f == nil, 'ui_window.lua must not exist')
    if f then f:close() end
end

local worn = read_file('lua/turbogear/tabs/worn.lua')
check(not worn:find('request_all', 1, true), 'worn.lua must not call Engine.request_all')

local ui = read_file('lua/turbogear/ui.lua')
local draw_ui = ui:match('function M%.draw_ui%(%)%s*.*end%s*$')
if not draw_ui then
    local s = ui:find('function M.draw_ui()', 1, true)
    check(s ~= nil, 'ui.lua has draw_ui')
    if s then
        draw_ui = ui:sub(s)
    end
end
check(draw_ui and not draw_ui:find('reload_cache_if_changed', 1, true),
    'draw_ui must not poll Store.reload_cache_if_changed')
check(draw_ui and not draw_ui:find('request_all', 1, true),
    'draw_ui must not call Engine.request_all')
check(ui:find('if pointer_held() then return end', 1, true) ~= nil,
    'persist_window_geom returns while pointer is held')
check(ui:find('ImGuiCond.Appearing', 1, true) ~= nil,
    'TurboGear restores geometry with Appearing')

-- Repeat-draw / unchanged geometry: persist must not dirty when pos is stable.
do
    local start_at = ui:find('local function vec2_xy(', 1, true)
        local persist_at = ui:find('local function persist_window_geom(', 1, true)
        local persist_end = persist_at and ui:find('\nlocal function content_avail_x', persist_at, true)
        check(start_at and persist_at and persist_end, 'can extract persist_window_geom')
        if start_at and persist_end then
            local block = ui:sub(start_at, persist_end)
        local held = false
        local wx, wy, ww, wh = 40, 80, 480, 700
        local dirty = 0
        local env = {
            tonumber = tonumber,
            math = math,
            type = type,
            tostring = tostring,
            Settings = { mainWindowPos = { x = 40, y = 80 }, mainWindowSize = { w = 480, h = 700 } },
            ImGui = {
                IsMouseDown = function() return held end,
                GetWindowPos = function() return wx, wy end,
                GetWindowSize = function() return ww, wh end,
            },
            cfg = { MarkSettingsDirty = function() dirty = dirty + 1 end },
            SaveSettings = function() error('SaveSettings must not run from persist') end,
        }
        local loader = loadstring or load
        local chunk, err = loader(block .. '\nreturn persist_window_geom\n')
        check(chunk ~= nil, 'persist chunk loads: ' .. tostring(err))
        if chunk then
            if setfenv then setfenv(chunk, env) else
                chunk, err = loader(block .. '\nreturn persist_window_geom\n', 'persist', 't', env)
            end
            local persist = chunk()
            persist('mainWindowPos', 'mainWindowSize')
            persist('mainWindowPos', 'mainWindowSize')
            persist('mainWindowPos', 'mainWindowSize')
            check(dirty == 0, 'repeat draw with unchanged geom -> 0 dirty, got ' .. tostring(dirty))

            held = true
            wx, wy = 120, 160
            persist('mainWindowPos', 'mainWindowSize')
            persist('mainWindowPos', 'mainWindowSize')
            check(dirty == 0, '0 dirty while pointer held during move, got ' .. tostring(dirty))
            check(env.Settings.mainWindowPos.x == 40, 'Settings pos stays stale while held')

            held = false
            persist('mainWindowPos', 'mainWindowSize')
            check(dirty == 1, '1 dirty after movement settles, got ' .. tostring(dirty))
            check(env.Settings.mainWindowPos.x == 120, 'Settings pos updates after release')
        end
    end
end

-- Turbo hub observe/tick: 0 writes while held, 1 after debounce.
-- After pointer-up, keep observing the same final x/y every frame (~16ms)
-- so continued rendering cannot postpone the settle write.
do
    local src = read_file('lua/Turbo/init.lua')
    local start_at = src:find('TG.UI_GEOM_DEBOUNCE_S = 0.8', 1, true)
    local end_at = src:find('\nif TG.stampUiGeomWritten then TG.stampUiGeomWritten() end', start_at, true)
    check(start_at ~= nil and end_at ~= nil, 'can extract Turbo geom helpers')
    if start_at and end_at then
        local block = src:sub(start_at, end_at + #'\nif TG.stampUiGeomWritten then TG.stampUiGeomWritten() end' - 1)
        local held = false
        local clock = 10
        local saves = 0
        local TG = {}
        TG.saveSettings = function()
            saves = saves + 1
            -- Production saveSettings stamps written geom after the pickle.
            if TG.stampUiGeomWritten then TG.stampUiGeomWritten() end
        end
        local env = {
            TG = TG,
            ImGui = { IsMouseDown = function() return held end },
            os = { clock = function() return clock end },
            tonumber = tonumber,
            math = math,
            type = type,
        }
        local loader = loadstring or load
        local chunk, err = loader(block)
        check(chunk ~= nil, 'geom helpers load: ' .. tostring(err))
        if chunk then
            if setfenv then setfenv(chunk, env) end
            chunk()
            TG.miniWindowPos = { x = 100, y = 100 }
            TG.stampUiGeomWritten()
            held = true
            local drag_x, drag_y = 100, 100
            for i = 1, 20 do
                drag_x, drag_y = 100 + i * 20, 100 + i * 20
                TG.observeWindowPos('miniWindowPos', drag_x, drag_y)
                TG.tickUiGeomSave()
                clock = clock + 0.016
            end
            check(saves == 0, '0 settings writes while actively moving, got ' .. tostring(saves))
            check(TG.miniWindowPos.x == drag_x, 'live pos updates in memory while dragging')

            held = false
            local final_x, final_y = drag_x, drag_y
            local wrote_at = nil
            -- ~1.28s of continued rendering at the settled position.
            for i = 1, 80 do
                TG.observeWindowPos('miniWindowPos', final_x, final_y)
                TG.tickUiGeomSave()
                if saves == 1 and not wrote_at then wrote_at = clock end
                if i == 1 then
                    check(saves == 0, 'no immediate write on pointer-up')
                end
                clock = clock + 0.016
            end
            check(saves == 1, 'exactly 1 write after final geometry settled, got ' .. tostring(saves))
            check(wrote_at ~= nil and wrote_at >= 10 + 20 * 0.016 + 0.8 - 0.001,
                'write waits for debounce, wrote_at=' .. tostring(wrote_at))
            check(wrote_at ~= nil and wrote_at < 10 + 20 * 0.016 + 0.8 + 0.05,
                'continued rendering does not postpone the save, wrote_at=' .. tostring(wrote_at))

            for _ = 1, 40 do
                TG.observeWindowPos('miniWindowPos', final_x, final_y)
                TG.tickUiGeomSave()
                clock = clock + 0.016
            end
            check(saves == 1, 'no repeated writes afterward, got ' .. tostring(saves))
        end
    end
end

print(string.format('turbo_ui_native_move_test: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
