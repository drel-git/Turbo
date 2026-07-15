--[[
  Turbo/handins.lua - PoT/GoD symbol turn-ins.
  @version lua/Turbo/handins.lua 1.0.2
  Usage: /lua run Turbo/handins
  Turbo hub: Actions tab -> PoT + GoD

  Tabs:
    PoT         - PoK Planar/TIME turn-ins
    GoD         - PoK Taelosian (Texvu+Tacvi) turn-ins
    Exclusions  - per-character ignore list, applied to both tabs above

  Binds: /giveplanar (PoK Planar line) | /givediscord /givetexvu (PoK Taelosian = Texvu+Tacvi)

  Exclusions: stored per-character in <MQConfig>/Turbo_handins_exclusions_<CharName>.lua
  as a Lua table file. An excluded item is removed from the inventory scan, so it
  never appears in the turn-in lists and chat binds (Select All) skip it cleanly.
]]

local mq = require('mq')
local ImGui = require('ImGui')
local Theme = require('Turbo.theme')
local Ui = require('Turbo.ui.components')
local Data = require('Turbo/handins_data')

--- Alt currency can be absent or return non-number; matches Turbo/init.lua readAltCurrencyAmount.
local function readAltCurrencyAmount(name)
  local ok, v = pcall(function()
    local t = mq.TLO.Me.AltCurrency(name)
    if not t then return 0 end
    local n = t()
    if n == nil then return 0 end
    return tonumber(n) or 0
  end)
  return ok and type(v) == 'number' and v or 0
end

local GUARD_KEY = '__TurboHandinsActive'
if _G[GUARD_KEY] then
  printf('\ar[Handins]\ax Another copy is already running. Close that window first.')
  return
end
_G[GUARD_KEY] = true

local TAG = '\at[Handins]\ax'

--==========================================================================--
-- Exclusions: per-character ignore list, lives at:
--   <MQConfig>/Turbo_handins_exclusions_<CharName>.lua
--
-- File format: a Lua return statement of a flat table of bool keys, e.g.
--   return { ["Songblade of the Eternal"] = true, ["Withered Rose"] = true }
-- Read via loadfile + setfenv (5.1) / load with empty env (5.4 fallback).
-- Written via plain io.open + a tiny serializer (no pcall, no schema) since
-- the file is owned by this script and never edited externally during runtime.
--==========================================================================--

local exclusions = {}  --- canonical excluded set: { [itemName] = true }
local exclusionsFile = nil

local function getExclusionsFilePath()
  local mqPath = mq.TLO.MacroQuest.Path() or ''
  local cfg = mqPath .. '\\config'
  local charName = mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or 'Unknown'
  --- Strip any path-hostile chars from the character name (paranoia; EQ names
  --- are alpha-only by rule but a corrupted TLO read shouldn't blow up file IO).
  charName = charName:gsub('[^%w_%-]', '')
  if charName == '' then charName = 'Unknown' end
  return cfg .. '\\Turbo_handins_exclusions_' .. charName .. '.lua'
end

local function loadExclusions()
  exclusions = {}
  exclusionsFile = exclusionsFile or getExclusionsFilePath()
  local f = io.open(exclusionsFile, 'r')
  if not f then return end
  local body = f:read('*a') or ''
  f:close()
  if body == '' then return end
  --- Sandbox: load body with no globals exposed. Lua 5.1 (LuaJIT) uses
  --- setfenv on a chunk; 5.3+ uses load(...,'t',env). MQ Next ships LuaJIT 2.1
  --- so the setfenv path is the live one; the load(...) fallback is harmless.
  local chunk
  if loadstring then
    chunk = loadstring(body, 'handins_exclusions')
    if chunk and setfenv then setfenv(chunk, {}) end
  else
    chunk = load(body, 'handins_exclusions', 't', {})
  end
  if not chunk then return end
  local ok, t = pcall(chunk)
  if not ok or type(t) ~= 'table' then return end
  for k, v in pairs(t) do
    if type(k) == 'string' and v == true then
      exclusions[k] = true
    end
  end
end

local function saveExclusions()
  exclusionsFile = exclusionsFile or getExclusionsFilePath()
  --- Serialize to a stable alphabetical order so file diffs are clean.
  local keys = {}
  for k in pairs(exclusions) do keys[#keys + 1] = k end
  table.sort(keys)
  local out = { 'return {' }
  for _, k in ipairs(keys) do
    --- %q escapes embedded quotes and backslashes safely for Lua.
    out[#out + 1] = string.format('  [%q] = true,', k)
  end
  out[#out + 1] = '}'
  out[#out + 1] = ''
  local f, err = io.open(exclusionsFile, 'w')
  if not f then
    printf('%s Could not write exclusions file (%s): %s', TAG, exclusionsFile, tostring(err))
    return false
  end
  f:write(table.concat(out, '\n'))
  f:close()
  return true
end

local function isExcluded(itemName)
  return exclusions[itemName] == true
end

local function setExcluded(itemName, value)
  if value then
    exclusions[itemName] = true
  else
    exclusions[itemName] = nil
  end
  saveExclusions()
end

--- Stable alphabetical sort by .Name field. Used to render every list (PoT,
--- Taelosian) in alphabetical order regardless of how
--- handins_data declares them. Stable so future changes to the data file
--- never reshuffle the UI in a confusing way.
local function sortByName(rows)
  table.sort(rows, function(a, b) return a.Name < b.Name end)
end

local CURSOR_WAIT_MS  = 5000
local GIVE_CLEAR_MS   = 10000
local NAV_STOP_DIST   = 10
local NAV_TIMEOUT_MS  = 20000

local symZone      = Data.symbolZoneShort:lower()
local symbolNpc    = Data.symbolNpcByZone

--- UI lists: Planar = TIME loot; Taelosian = TEXVU + TACVI (rows carry .Line for NPC).
local SYMBOL_PLANAR    = 'PLANAR'
local SYMBOL_TAELOSIAN = 'TAELOSIAN'

local running      = true
local open         = true
local show         = true
local doTurnIns    = false
local activeTab    = 'pot' --- 'pot' | 'god' | 'exclusions'
local tabInitDone  = false

local symbolSelectable = { PLANAR = {}, TAELOSIAN = {} }
local navToNpcIfFar = true
local statusMsg = ''

local function zoneShortLower()
  local z = mq.TLO.Zone
  if not z or not z.ShortName then return '' end
  local s = z.ShortName() or ''
  return type(s) == 'string' and s:lower() or ''
end

local function setTabFromZoneOnce()
  if tabInitDone then return end
  tabInitDone = true
  local zs = zoneShortLower()
  if zs == symZone then
    activeTab = 'pot'
  else
    activeTab = 'pot'
  end
end

local function currentSymbolListKey()
  return activeTab == 'god' and SYMBOL_TAELOSIAN or SYMBOL_PLANAR
end

local function findSymbolItems()
  local items = Data.symbolTurnInItems
  symbolSelectable.PLANAR = {}
  symbolSelectable.TAELOSIAN = {}
  for _, item in ipairs(items.TIME) do
    if not isExcluded(item) then
      local itemRef = mq.TLO.FindItem('=' .. item)
      if itemRef() and not itemRef.NoTrade()
          and itemRef.ItemSlot() > 22 and itemRef.ItemSlot() < 33 then
        table.insert(symbolSelectable.PLANAR, {
          Name = item,
          ItemSlot = itemRef.ItemSlot(),
          ItemSlot2 = itemRef.ItemSlot2(),
          Selected = false,
          Line = 'TIME',
        })
      end
    end
  end
  local seen = {}
  for _, item in ipairs(items.TEXVU) do
    if not isExcluded(item) then
      local itemRef = mq.TLO.FindItem('=' .. item)
      if itemRef() and not itemRef.NoTrade()
          and itemRef.ItemSlot() > 22 and itemRef.ItemSlot() < 33 then
        seen[item] = true
        table.insert(symbolSelectable.TAELOSIAN, {
          Name = item,
          ItemSlot = itemRef.ItemSlot(),
          ItemSlot2 = itemRef.ItemSlot2(),
          Selected = false,
          Line = 'TEXVU',
        })
      end
    end
  end
  for _, item in ipairs(items.TACVI) do
    if not seen[item] and not isExcluded(item) then
      local itemRef = mq.TLO.FindItem('=' .. item)
      if itemRef() and not itemRef.NoTrade()
          and itemRef.ItemSlot() > 22 and itemRef.ItemSlot() < 33 then
        table.insert(symbolSelectable.TAELOSIAN, {
          Name = item,
          ItemSlot = itemRef.ItemSlot(),
          ItemSlot2 = itemRef.ItemSlot2(),
          Selected = false,
          Line = 'TACVI',
        })
      end
    end
  end
  --- 1.0.1: alphabetical sort applied here so the UI never depends on
  --- handins_data ordering. Both lists sorted independently.
  sortByName(symbolSelectable.PLANAR)
  sortByName(symbolSelectable.TAELOSIAN)
end

local function refreshLists()
  findSymbolItems()
end

local function selectAllSymbols(zkey)
  for _, row in ipairs(symbolSelectable[zkey]) do
    row.Selected = true
  end
end

local function navigationPathExists(id)
  local nav = mq.TLO.Navigation
  if not nav or not nav.PathExists then return false end
  local query = string.format('id %s', tostring(id))
  local ok, res = pcall(function()
    local pe = nav.PathExists(query)
    return pe and pe()
  end)
  return ok and res
end

local function navigationActive()
  local nav = mq.TLO.Navigation
  if not nav or not nav.Active then return false end
  local ok, res = pcall(function() return nav.Active() end)
  return ok and res
end

local function approachTarget(maxDist)
  if not navToNpcIfFar then return end
  maxDist = maxDist or NAV_STOP_DIST
  local nav = mq.TLO.Navigation
  if not nav then
    printf('%s MQ2Nav not available (Navigation TLO missing). Load MQ2Nav.', TAG)
    return
  end
  local t = mq.TLO.Target
  if not t or not t() then return end
  local dist = t.Distance() or 999
  if dist <= maxDist then return end
  local tid = t.ID and t.ID() or nil
  if not tid then return end
  local hasPath = navigationPathExists(tid)
  if not hasPath then
    printf('%s No mesh/path reported for this target - trying /nav anyway (see MQ2Nav mesh).', TAG)
  else
    local nm = t.CleanName and t.CleanName() or 'NPC'
    printf('%s Navigating to %s (id %s)...', TAG, nm, tostring(tid))
  end
  mq.cmdf('/squelch /nav id %s distance=%s', tid, maxDist)
  local deadline = mq.gettime() + NAV_TIMEOUT_MS
  while mq.gettime() < deadline do
    dist = (t.Distance and t.Distance()) or 999
    if dist <= maxDist + 1 then break end
    if not navigationActive() and dist > maxDist + 2 then
      mq.cmdf('/squelch /nav id %s distance=%s', tid, maxDist)
    end
    mq.delay(50)
  end
  if navigationActive() then
    mq.cmd('/squelch /nav stop')
  end
  dist = (t.Distance and t.Distance()) or 999
  if dist > maxDist + 3 then
    printf('%s Nav finished but still %.0f away - stand closer or check mesh.', TAG, dist)
  end
end

--- One give-window cycle for a single item name pick.
--- Uses Ctrl pickup so stackable turn-ins are drained one item at a time instead
--- of putting a whole stack on the cursor. This is slower but avoids risky
--- whole-stack cursor handoffs during NPC trade windows.
local function handinOnce(itemName)
  mq.cmdf('/ctrl /itemnotify "%s" leftmouseup', itemName)
  local startTime = mq.gettime()
  while not mq.TLO.Cursor() do
    if mq.gettime() - startTime > CURSOR_WAIT_MS then return false end
    mq.delay(10)
  end
  mq.delay(100)
  if not mq.TLO.Cursor() then return false end

  mq.cmd('/click left target')
  startTime = mq.gettime()
  while mq.TLO.Cursor() do
    if mq.gettime() - startTime > GIVE_CLEAR_MS then return false end
    mq.delay(10)
  end
  mq.delay(100)
  if mq.TLO.Cursor() then return false end

  mq.cmd('/notify GiveWnd GVW_Give_Button leftmouseup')
  startTime = mq.gettime()
  while not mq.TLO.Cursor() do
    if mq.gettime() - startTime > CURSOR_WAIT_MS then return false end
    mq.delay(10)
  end
  while mq.TLO.Cursor() do
    mq.cmd('/autoinv')
    mq.delay(10)
  end
  mq.delay(500, function() return not mq.TLO.Cursor() end)
  return true
end

local function handinSymbolRow(row)
  handinOnce(row.Name)
end

local function zoneOkForSymbols()
  return zoneShortLower() == symZone
end

local function runTurnIns()
  if activeTab == 'pot' or activeTab == 'god' then
    if not zoneOkForSymbols() then
      printf('%s Symbols require zone \ag%s\ax (Plane of Knowledge).', TAG, symZone)
      return
    end
    local listKey = currentSymbolListKey()
    if listKey == SYMBOL_PLANAR then
      local npc = symbolNpc.TIME
      if not npc or npc == '' then
        printf('%s No NPC configured for Planar - edit handins_data.symbolNpcByZone.TIME.', TAG)
        return
      end
      mq.cmdf('/mqt npc %s', npc)
      mq.delay(500)
      approachTarget(NAV_STOP_DIST)
      for _, row in ipairs(symbolSelectable.PLANAR) do
        if row.Selected then
          handinSymbolRow(row)
        end
      end
    else
      local groups = {}
      for _, row in ipairs(symbolSelectable.TAELOSIAN) do
        if row.Selected then
          local npc = symbolNpc[row.Line]
          if not npc or npc == '' then
            printf('%s No NPC for line \ay%s\ax - edit handins_data.', TAG, tostring(row.Line))
            refreshLists()
            return
          end
          groups[npc] = groups[npc] or {}
          table.insert(groups[npc], row)
        end
      end
      for npc, rows in pairs(groups) do
        mq.cmdf('/mqt npc %s', npc)
        mq.delay(500)
        approachTarget(NAV_STOP_DIST)
        for _, row in ipairs(rows) do
          handinSymbolRow(row)
        end
      end
    end
  else
    printf('%s Choose PoT or GoD before turning in.', TAG)
  end
  refreshLists()
end

--- MQ ImGui.TextColored needs r,g,b,a as separate numbers; multi-return col4() often breaks from Lua.
local function textColored(c, text)
  if not c then ImGui.Text(text) return end
  ImGui.TextColored(c[1], c[2], c[3], c[4] or 1.0, text)
end

local tabH = Theme.layout.slimLayoutBtnH or 24

--- Vertical-space helper: returns the height in pixels remaining between the
--- current cursor and the bottom of the content region. Used to size the
--- BeginChild scroll boxes so each list fills whatever the user resized the
--- window to (no more dead band below the inner list).
---
--- Why pcall + GetWindowContentRegionMax: this is the proven pattern from
--- init.lua's footer reservation logic. MQ Next's ImGui binding exposes
--- GetContentRegionAvail as a single (width) scalar, not the (x, y) ImVec2
--- the C++ API returns — so we can't use GetContentRegionAvail() here. The
--- WindowContentRegionMax / CursorPosY pair is the documented workaround.
---
--- reserveStatusLine: when true, leave room for one line of status text +
--- the Spacing() before it. Used on tabs that may render `statusMsg` below
--- the scroll area.
local function availListHeight(reserveStatusLine)
  local okMax, _, contentBottomY = pcall(ImGui.GetWindowContentRegionMax)
  local okCur, curY = pcall(ImGui.GetCursorPosY)
  if not (okMax and okCur and type(contentBottomY) == 'number' and type(curY) == 'number') then
    return 240
  end
  local h = contentBottomY - curY
  if reserveStatusLine then
    h = h - (ImGui.GetFontSize() + Theme.space.sm)
  end
  if h < 120 then return 120 end
  return h
end

local function draw()
  if not open then
    running = false
    return
  end
  setTabFromZoneOnce()
  local cond = (ImGuiCond and ImGuiCond.FirstUseEver) or 4
  ImGui.SetNextWindowSize(340, 520, cond)
  local wb = Theme.col.windowBg
  local titleBg = Theme.col.titleBg
  local titleBgAct = Theme.col.titleBgActive
  local pushedWindowBg = 0

  --- 1.0.2: Push the same rounding style vars the main Turbo window pushes
  --- (see init.lua 3.8.55 ~line 4232) so TurboHandins buttons match the
  --- rounded look of the rest of the suite. Five vars total; popped at
  --- end-of-draw via pushedStyleVars counter for symmetry with the existing
  --- pushedWindowBg pattern. Guarded on ImGuiStyleVar presence to keep this
  --- script working on older bindings (silently squared corners, no crash).
  local pushedStyleVars = 0
  if ImGuiStyleVar then
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 4)
    pushedStyleVars = pushedStyleVars + 1
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 8)
    pushedStyleVars = pushedStyleVars + 1
    ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 4)
    pushedStyleVars = pushedStyleVars + 1
    ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, 4)
    pushedStyleVars = pushedStyleVars + 1
    ImGui.PushStyleVar(ImGuiStyleVar.GrabRounding, 4)
    pushedStyleVars = pushedStyleVars + 1
  end

  if ImGuiCol and IM_COL32 then
    if wb then
      ImGui.PushStyleColor(ImGuiCol.WindowBg, IM_COL32(wb[1], wb[2], wb[3], wb[4]))
      pushedWindowBg = pushedWindowBg + 1
    end
    if titleBg then
      ImGui.PushStyleColor(ImGuiCol.TitleBg, IM_COL32(titleBg[1], titleBg[2], titleBg[3], titleBg[4]))
      pushedWindowBg = pushedWindowBg + 1
    end
    if titleBgAct then
      ImGui.PushStyleColor(ImGuiCol.TitleBgActive, IM_COL32(titleBgAct[1], titleBgAct[2], titleBgAct[3], titleBgAct[4]))
      pushedWindowBg = pushedWindowBg + 1
    end
  end
  open, show = ImGui.Begin('TurboHandins', open)
  if show == nil then show = open end
  if show then
    local zs = zoneShortLower()
    local zwarn = false
    if (activeTab == 'pot' or activeTab == 'god') and zs ~= symZone then zwarn = true end
    --- Exclusions tab: no zone gating — it edits a config file, not inventory.

    ImGui.Dummy(0, Theme.space.xs)

    --- Three tabs: PoT / GoD / Exclusions. PoT and GoD both run in PoK;
    --- Exclusions manages the per-character skip list applied to both scans.
    local tabGap = Theme.space.sm
    local topAvail = ImGui.GetContentRegionAvail()
    local tabW1 = math.max(1, math.floor((topAvail - tabGap * 2) / 3))
    local tabW2 = tabW1
    local tabW3 = math.max(1, topAvail - tabW1 - tabW2 - tabGap * 2)

    if Ui.tabButton('PoT##htab', activeTab == 'pot', false, tabW1, tabH) then
      activeTab = 'pot'
      refreshLists()
    end
    ImGui.SameLine(0, tabGap)
    if Ui.tabButton('GoD##htab', activeTab == 'god', false, tabW2, tabH) then
      activeTab = 'god'
      refreshLists()
    end
    ImGui.SameLine(0, tabGap)
    if Ui.tabButton('Exclusions##htab', activeTab == 'exclusions', false, tabW3, tabH) then
      activeTab = 'exclusions'
      --- No refreshLists on the Exclusions tab — its content is the static
      --- handins_data lists, not inventory. refreshLists fires when the user
      --- comes back to PoT/GoD so the filter takes effect.
    end

    if zwarn then
      textColored(Theme.col.errorCol, 'Wrong zone - use PoT/GoD turn-ins in Plane of Knowledge.')
    elseif activeTab == 'pot' then
      textColored(Theme.col.turboloot.label,
        'PoK Planar/TIME symbols: /t the NPC, then turn in below.')
    elseif activeTab == 'god' then
      textColored(Theme.col.turboloot.label,
        'PoK Taelosian/GoD symbols: Texvu + Tacvi turn-ins.')
    else
      --- Exclusions tab: tell the user what the list does and how it ties back
      --- to the inventory scans. Kept brief so the context strip stays one line.
      textColored(Theme.col.turbogive.label,
        'Excluded items are skipped on every turn-in (UI + chat binds).')
    end
    ImGui.Spacing()
    navToNpcIfFar = ImGui.Checkbox('Navigate to NPC if out of range (MQ2Nav)', navToNpcIfFar)
    if ImGui.IsItemHovered() then
      Ui.tooltip(
        'E3BC - run TurboHandins on another character:\n/e3bct botname /lua run Turbo/handins\n\nReplace botname with that toon name. They need Turbo installed with this script and should be in Plane of Knowledge.',
        36)
    end

    ImGui.Spacing()
    do
      local gp = mq.TLO.FindItemCount('Planar Symbol')() or 0
      local gt = mq.TLO.FindItemCount('Taelosian Symbol')() or 0
      local rp = readAltCurrencyAmount('Planar Symbols')
      local rt = readAltCurrencyAmount('Taelosian Symbols')
      local nPlanarBags = #symbolSelectable.PLANAR
      local nTaelBags = #symbolSelectable.TAELOSIAN

      local balance = { gp + rp, gt + rt }
      local listed = { nPlanarBags, nTaelBags }
      local colNames = { 'Planar', 'Taelosian' }
      --- Per-column accents: headers vs totals vs list counts read as different roles.
      local hdrAccent = {
        Theme.col.currency.label,
        Theme.col.turboloot.label,
      }
      local totalAccent = {
        Theme.col.plat,
        Theme.col.aa,
      }
      local itemsAccent = {
        Theme.col.skipReason.default,
        Theme.col.profile.label,
      }

      if ImGui.BeginTable and ImGuiTableFlags and ImGuiTableColumnFlags then
        local tf = ImGuiTableFlags.SizingStretchSame
        if ImGui.BeginTable('##handins_totals', 3, tf) then
          ImGui.TableSetupColumn('##corner', ImGuiTableColumnFlags.WidthFixed, 44)
          ImGui.TableSetupColumn('##p', ImGuiTableColumnFlags.WidthStretch, 1)
          ImGui.TableSetupColumn('##t', ImGuiTableColumnFlags.WidthStretch, 1)

          ImGui.TableNextRow()
          for i = 1, 2 do
            ImGui.TableSetColumnIndex(i)
            textColored(hdrAccent[i], colNames[i])
          end

          ImGui.TableNextRow()
          ImGui.TableSetColumnIndex(0)
          textColored(Theme.col.statusMsg, 'Total')
          for i = 1, 2 do
            ImGui.TableSetColumnIndex(i)
            textColored(totalAccent[i], string.format('%s', balance[i]))
          end

          ImGui.TableNextRow()
          ImGui.TableSetColumnIndex(0)
          textColored(Theme.col.turbogive.label, 'Items')
          for i = 1, 2 do
            ImGui.TableSetColumnIndex(i)
            textColored(itemsAccent[i], string.format('%s', listed[i]))
          end

          ImGui.EndTable()
        end
      else
        ImGui.TextWrapped(string.format('Total: Planar %s · Taelosian %s',
          balance[1], balance[2]))
        ImGui.TextWrapped(string.format('Items: Planar %s · Taelosian %s',
          listed[1], listed[2]))
      end
    end

    ImGui.Dummy(0, Theme.space.sm)
    if activeTab == 'pot' or activeTab == 'god' then
      local listKey = currentSymbolListKey()
      Ui.sectionHeader(Theme.col.currency, listKey == SYMBOL_PLANAR and 'Planar (PoT)' or 'Taelosian (GoD)')

      ImGui.BeginDisabled(doTurnIns)
      local btnW = (ImGui.GetContentRegionAvail() - Theme.space.sm) * 0.5
      if Ui.buttonVariant('Select all##symall', 'secondaryButton', btnW, 0) then
        selectAllSymbols(listKey)
      end
      ImGui.SameLine()
      if Ui.buttonVariant('Turn in selected##symgo', 'successButton', btnW, 0) then
        doTurnIns = true
      end
      for _, row in ipairs(symbolSelectable[listKey]) do
        row.Selected = ImGui.Checkbox(row.Name, row.Selected)
      end
      ImGui.EndDisabled()
    else
      --- Exclusions tab: two sections (Planar / Taelosian),
      --- each listing the curated candidates from handins_data.exclusionCandidates.
      --- Checked = excluded (skipped on every turn-in). Toggling persists
      --- immediately via setExcluded() → file write, then refreshLists() so
      --- the PoT/GoD tabs reflect the change as soon as the user
      --- switches back. Sections sorted alphabetically per session start.
      local count = 0
      for _ in pairs(exclusions) do count = count + 1 end
      textColored(Theme.col.errorCol,
        'Checked = EXCLUDE (item will NOT turn in). Saved per-character.')
      ImGui.SameLine()
      textColored(Theme.col.statusMsg, string.format('  %d excluded.', count))

      ImGui.Spacing()
      if Ui.buttonVariant('Clear all exclusions##exclr', 'secondaryButton',
          ImGui.GetContentRegionAvail(), 0) then
        --- Wipe the in-memory set, write the (now-empty) file, and reload
        --- inventory so anything that was hidden becomes visible again.
        exclusions = {}
        saveExclusions()
        refreshLists()
      end

      --- Build alphabetically-sorted local copies once per draw. Cheap (small
      --- lists, ~10 items total) and avoids mutating Data.* tables in place.
      local plList   = {}
      local taeList  = {}
      for _, item in ipairs(Data.exclusionCandidates.PLANAR) do plList[#plList + 1] = item end
      for _, item in ipairs(Data.exclusionCandidates.TAELOSIAN) do taeList[#taeList + 1] = item end
      table.sort(plList)
      table.sort(taeList)

      --- Planar (PoT/TIME) section
      Ui.sectionHeader(Theme.col.currency, 'Planar (PoT)')
      for _, item in ipairs(plList) do
        local was = isExcluded(item)
        local now = ImGui.Checkbox(item .. '##excl_p', was)
        if now ~= was then
          setExcluded(item, now)
          refreshLists()
        end
      end

      --- Taelosian (GoD: Texvu + Tacvi) section
      Ui.sectionHeader(Theme.col.turboloot, 'Taelosian (GoD)')
      for _, item in ipairs(taeList) do
        local was = isExcluded(item)
        local now = ImGui.Checkbox(item .. '##excl_t', was)
        if now ~= was then
          setExcluded(item, now)
          refreshLists()
        end
      end

    end

    if statusMsg ~= '' then
      ImGui.Spacing()
      textColored(Theme.col.statusMsg, statusMsg)
    end
  end
  ImGui.End()
  if pushedWindowBg > 0 then
    ImGui.PopStyleColor(pushedWindowBg)
  end
  if pushedStyleVars > 0 then
    ImGui.PopStyleVar(pushedStyleVars)
  end
end

mq.imgui.init('turbo_handins_ui', draw)

local function givePlanar()
  if doTurnIns then printf('%s Wait for current turn-in to finish.', TAG) return end
  activeTab = 'pot'
  selectAllSymbols(SYMBOL_PLANAR)
  doTurnIns = true
end

--- PoK Taelosian (Texvu + Tacvi items).
local function giveDiscordSymbols()
  if doTurnIns then printf('%s Wait for current turn-in to finish.', TAG) return end
  activeTab = 'god'
  selectAllSymbols(SYMBOL_TAELOSIAN)
  doTurnIns = true
end

local function giveTexvu()
  if doTurnIns then printf('%s Wait for current turn-in to finish.', TAG) return end
  activeTab = 'god'
  selectAllSymbols(SYMBOL_TAELOSIAN)
  doTurnIns = true
end

mq.bind('/giveplanar', givePlanar)
mq.bind('/givediscord', giveDiscordSymbols)
mq.bind('/givetexvu', giveTexvu)

--- Load exclusions BEFORE the first refreshLists() so the initial inventory
--- scan honors the per-character ignore list. If the file is missing or
--- corrupt, loadExclusions() leaves `exclusions` as an empty table — no items
--- excluded, same behavior as a fresh install.
loadExclusions()
refreshLists()
while running do
  if doTurnIns then
    runTurnIns()
    doTurnIns = false
  end
  mq.delay(100)
end

_G[GUARD_KEY] = nil
