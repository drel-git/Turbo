--[[
  TurboGear/export_spells.lua - missing-spell export for friends

  Run:
    /tgear exportspells [copies]
    /lua run turbogear export_spells.lua
    /lua run turbogear export_spells.lua ui

  Writes: MacroQuest/Config/ResearchLearn_want_<Character>.txt
]]

local mq = require('mq')
local ImGui = require('ImGui')

local okCatalog, Catalog = pcall(require, 'research_catalog')
if not okCatalog or not Catalog then
    local root = (mq.TLO.MacroQuest.Path() or '') .. '\\lua\\turbogear\\research_catalog.lua'
    local chunk = loadfile(root)
    if chunk then Catalog = chunk() end
end

local scriptName = 'TurboGearExportSpells'
local state = {
    windowOpen = false,
    copies = 1,
    statusMsg = '',
    lastPath = '',
    lastCount = 0,
    preview = {},
}

local function trim(s)
    return (tostring(s or ''):gsub('^%s*(.-)%s*$', '%1'))
end

local function to_win_path(path)
    path = trim(path)
    if path == '' then return '' end
    return path:gsub('/', '\\')
end

local function reveal_export_file(path)
    path = to_win_path(path)
    if path == '' then return end
    pcall(function()
        local fh = io.open(path, 'r')
        if not fh then
            printf('\ay[TurboGear]\ax Could not find export file for Explorer: %s', path)
            return
        end
        fh:close()

        if package.config:sub(1, 1) ~= '\\' then
            local dir = path:match('^(.*[/\\])') or path
            os.execute(string.format('xdg-open "%s"', dir:gsub('"', '')))
            return
        end

        local safe = path:gsub('"', '')
        local params = '/select,"' .. safe .. '"'

        local okFfi, ffi = pcall(require, 'ffi')
        if okFfi and ffi then
            if not _G.TurboGearExportShellExecuteCdef then
                pcall(ffi.cdef, [[
                    void* ShellExecuteA(void* hwnd, const char* lpOperation, const char* lpFile, const char* lpParameters, const char* lpDirectory, int nShowCmd);
                ]])
                _G.TurboGearExportShellExecuteCdef = true
            end
            local ok = pcall(function()
                if not _G.TurboGearExportShell32 then
                    _G.TurboGearExportShell32 = ffi.load('shell32')
                end
                _G.TurboGearExportShell32.ShellExecuteA(nil, 'open', 'explorer.exe', params, nil, 1)
            end)
            if ok then return end
        end

        local okShell, ShellOpen = pcall(require, 'Turbo.shell_open')
        if okShell and ShellOpen and ShellOpen.shellOpenFolder then
            local dir = path:match('^(.*)[/\\]') or path
            ShellOpen.shellOpenFolder(dir)
        end
    end)
end

local function write_export(copies)
    if not Catalog then
        return nil, 'TurboGear research_catalog.lua not found.'
    end
    copies = math.max(1, math.floor(tonumber(copies) or 1))
    local path, count, planOrErr = Catalog.export_missing({
        copies = copies,
        source = 'TurboGear',
    })
    if not path then
        return nil, tostring(planOrErr or 'Export failed.')
    end
    local rows, _plan = Catalog.missing_export_rows({ copies = copies })
    state.lastPath = path
    state.lastCount = count or 0
    state.preview = {}
    for _, row in ipairs(rows or {}) do
        state.preview[#state.preview + 1] = { level = row.level, name = row.name }
    end
    return path, count
end

local function do_export(copies)
    local path, countOrErr = write_export(copies)
    if not path then
        state.statusMsg = countOrErr or 'Export failed.'
        printf('\ar[TurboGear]\ax %s', state.statusMsg)
        return false
    end
    state.statusMsg = string.format('Exported %d spells -> %s', countOrErr, path)
    printf('\ag[TurboGear]\ax %s', state.statusMsg)
    reveal_export_file(path)
    printf('\ayExplorer opened with your file selected - send it to your researcher.\ax')
    return true
end

local function render_window()
    if not state.windowOpen then return end
    local open = ImGui.Begin('TurboGear Spell Export###tg_export_spells', state.windowOpen)
    state.windowOpen = open
    if open then
        ImGui.Text(string.format('Character: %s  (%s)', mq.TLO.Me.CleanName() or '?', mq.TLO.Me.Class.ShortName() or '?'))
        ImGui.TextDisabled('Uses bundled turbogear/data + turbogear/references.')
        ImGui.Separator()
        local copiesBuf = tostring(state.copies)
        copiesBuf = ImGui.InputText('Copies each##tg_sp_copies', copiesBuf, 4)
        local cn = tonumber(trim(copiesBuf))
        if cn and cn >= 1 then state.copies = math.floor(cn) end
        if ImGui.Button('Export missing list', 160, 28) then do_export(state.copies) end
        ImGui.SameLine()
        if state.lastPath ~= '' and ImGui.Button('Show file##tg_sp_show', 80, 28) then
            reveal_export_file(state.lastPath)
        end
        if state.lastCount > 0 then
            ImGui.Spacing()
            ImGui.Text(string.format('Last export: %d spells', state.lastCount))
            ImGui.TextWrapped(state.lastPath)
        end
        if state.statusMsg ~= '' then
            ImGui.Spacing()
            ImGui.TextWrapped(state.statusMsg)
        end
    end
    ImGui.End()
end

local M = {}

local function run_cli(arg)
    arg = trim(arg or ''):lower()
    local copiesArg = tonumber(arg)
    if arg == 'ui' or arg == 'show' then
        state.windowOpen = true
        mq.imgui.init(scriptName, render_window)
        while state.windowOpen do mq.delay(100) end
        mq.imgui.destroy(scriptName)
        return
    end
    do_export(copiesArg or 1)
end

M.run = run_cli
M.export = do_export

local cli = trim(({ ... })[1] or '')
if cli ~= '' or select('#', ...) > 0 then
    run_cli(cli)
end

return M
