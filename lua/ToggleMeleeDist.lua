--[[============================================================================
   ████████╗ ██████╗  ██████╗  ██████╗ ██╗     ███████╗
   ╚══██╔══╝██╔═══██╗██╔════╝ ██╔════╝ ██║     ██╔════╝
      ██║   ██║   ██║██║  ███╗██║  ███╗██║     █████╗
      ██║   ██║   ██║██║   ██║██║   ██║██║     ██╔══╝
      ██║   ╚██████╔╝╚██████╔╝╚██████╔╝███████╗███████╗
      ╚═╝    ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
   ███╗   ███╗███████╗██╗     ███████╗███████╗
   ████╗ ████║██╔════╝██║     ██╔════╝██╔════╝
   ██╔████╔██║█████╗  ██║     █████╗  █████╗
   ██║╚██╔╝██║██╔══╝  ██║     ██╔══╝  ██╔══╝
   ██║ ╚═╝ ██║███████╗███████╗███████╗███████╗
   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝
   ██████╗ ██╗███████╗████████╗   ██╗      ██╗   ██╗ █████╗
   ██╔══██╗██║██╔════╝╚══██╔══╝   ██║      ██║   ██║██╔══██╗
   ██║  ██║██║███████╗   ██║      ██║      ██║   ██║███████║
   ██║  ██║██║╚════██║   ██║      ██║      ██║   ██║██╔══██║
   ██████╔╝██║███████║   ██║      ███████╗ ╚██████╔╝██║  ██║
   ╚═════╝ ╚═╝╚══════╝   ╚═╝      ╚══════╝  ╚═════╝ ╚═╝  ╚═╝


   ToggleMeleeDist.lua
-----------------------------------------------------------------------------
Dynamic melee distance controller for E3Next
- Varset toggle between fixed distance (10) and adaptive distance (MaxMelee)
- `toggle` reads INI, flips 10 <-> MaxMelee, syncs MeleeDistFar, ensures [Startup Commands] TurboMelee_* lines, one /g line
- Status reporting (melee-only to group chat) to confirm INI "Melee Distance=" value
- Melee-only safety gates
- Buttonmaster friendly

   Made by Drel
============================================================================]]

local mq = require('mq')

local function file_exists(path)
  local fh = io.open(path, 'r')
  if fh then fh:close(); return true end
  return false
end

--- Match Turbo's findE3Ini probing (lua/Turbo/init.lua): Config + Macros bases, server name variants,
--- Lazarus legacy suffix, bare character name — not only `%s_Lazarus.ini`.
local function resolve_e3_bot_ini_path()
  local mqPath = mq.TLO.MacroQuest.Path() or ''
  local charName = mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or ''
  local serverRaw = mq.TLO.EverQuest.Server() or ''
  local bases = {}
  if mqPath ~= '' then
    table.insert(bases, mqPath .. '\\Config\\e3 Bot Inis')
    table.insert(bases, mqPath .. '\\Macros\\e3 Bot Inis')
  end

  local serverStripped = serverRaw:gsub('^Project ', '')
  local serverUnder = serverRaw:gsub(' ', '_')
  local variants = {}
  if serverRaw ~= '' then table.insert(variants, charName .. '_' .. serverRaw) end
  if serverStripped ~= serverRaw then table.insert(variants, charName .. '_' .. serverStripped) end
  if serverUnder ~= serverRaw then table.insert(variants, charName .. '_' .. serverUnder) end
  --- Legacy Lazarus-named INIs often used `%s_Lazarus` regardless of EQ.Server() wording.
  table.insert(variants, charName .. '_Lazarus')
  table.insert(variants, charName)

  for _, base in ipairs(bases) do
    for _, v in ipairs(variants) do
      local p = base .. '\\' .. v .. '.ini'
      if file_exists(p) then return p end
    end
  end

  if #bases > 0 and #variants > 0 then
    return bases[1] .. '\\' .. variants[1] .. '.ini'
  end
  return nil
end

local function normalize_max_token(s)
  if not s or s == '' then return nil end
  local u = (s or ''):gsub('%s', ''):upper()
  if u == 'MAXMELEE' or u == 'MAX' then return true end
  if u:find('MAX', 1, true) then return true end
  return false
end

--- Binary flip for Field Tools-style workflow: MaxMelee vs 10. Any numeric distance -> MaxMelee; missing/other -> MaxMelee.
local function flip_target_from_ini_value(rawOpt)
  if normalize_max_token(rawOpt) then
    return '10'
  end
  return 'MaxMelee'
end

local function apply_melee_dist_far(target)
  if target == 'MaxMelee' then
    mq.cmd('/e3varset MeleeDistFar true')
  else
    mq.cmd('/e3varset MeleeDistFar false')
  end
end

--- Reads [Assist Settings] Melee Distance= trimmed value or nil / '(missing)'
local function read_melee_distance_in_assist(lines)
  local inAssist = false
  for _, line in ipairs(lines) do
    local section = line:match('^%[(.-)%]$')
    if section then
      inAssist = (section:gsub('%s+$', '') == 'Assist Settings')
    elseif inAssist then
      local v = line:match('^Melee Distance=(.*)')
      if v then
        local trimmed = (v or ''):match('^%s*(.-)%s*$')
        if trimmed ~= '' then return trimmed end
        return ''
      end
    end
  end
  return nil
end

--- Writes Melee Distance= under [Assist Settings].
--- Returns dirty=true if the disk file must be rewritten (edited or inserted row).
local function write_melee_distance_lines(lines, target)
  local inAssist = false
  local foundKey = false
  local dirty = false
  local insertBeforeNextSectionIdx = nil

  for i, line in ipairs(lines) do
    local section = line:match('^%[(.-)%]$')
    if section then
      if inAssist and not foundKey and insertBeforeNextSectionIdx == nil then
        insertBeforeNextSectionIdx = i
      end
      inAssist = (section:gsub('%s+$', '') == 'Assist Settings')
    elseif inAssist then
      local cur = line:match('^Melee Distance=(.*)')
      if cur then
        foundKey = true
        local current = (cur or ''):match('^%s*(.-)%s*$')
        if current ~= target then
          lines[i] = 'Melee Distance=' .. target
          dirty = true
        end
      end
    end
  end

  if foundKey then return dirty end

  if insertBeforeNextSectionIdx then
    table.insert(lines, insertBeforeNextSectionIdx, 'Melee Distance=' .. target)
    return true
  end
  if inAssist then
    table.insert(lines, 'Melee Distance=' .. target)
    return true
  end

  table.insert(lines, '')
  table.insert(lines, '[Assist Settings]')
  table.insert(lines, 'Melee Distance=' .. target)
  return true
end

local STARTUP_SECTION = 'Startup Commands'
--- Stable keys so we can overwrite on each toggle (avoid duplicate ambiguous Command= rows).
local KEY_STARTUP_MONO = 'TurboMelee_E3Mono'
local KEY_STARTUP_ASSIST = 'TurboMelee_AssistApply'

local function strip_section_name(s)
  return (s or ''):gsub('%s+$', '')
end

--- Ensures paired startup lines mirror current Assist target after toggle (MeleeDistFar + re-apply Assist Melee Distance=).
--- Writes Turbo-prefixed keys so we do not collide with unrelated Command=/macro lines.
local function merge_turbo_melee_startup_commands(lines, target)
  local monoFlag = (target == 'MaxMelee') and 'true' or 'false'
  local luaArg = (target == 'MaxMelee') and 'MaxMelee' or '10'
  local l1 = KEY_STARTUP_MONO .. '=/e3varset MeleeDistFar ' .. monoFlag
  local l2 = KEY_STARTUP_ASSIST .. '=/lua run ToggleMeleeDist ' .. luaArg

  local linePatMono = '^' .. KEY_STARTUP_MONO .. '='
  local linePatAssist = '^' .. KEY_STARTUP_ASSIST .. '='

  local h
  for i, line in ipairs(lines) do
    local bracket = line:match('^%[(.-)%]$')
    if bracket and strip_section_name(bracket) == STARTUP_SECTION then
      h = i
      break
    end
  end

  local function strip_old_turbo(slice)
    local out = {}
    for _, ln in ipairs(slice) do
      if not (ln:match(linePatMono) or ln:match(linePatAssist)) then
        out[#out + 1] = ln
      end
    end
    return out
  end

  if not h then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '[' .. STARTUP_SECTION .. ']'
    lines[#lines + 1] = l1
    lines[#lines + 1] = l2
    return true
  end

  local tail = {}
  local j = h + 1
  while j <= #lines and not lines[j]:match('^%[.-%]$') do
    tail[#tail + 1] = lines[j]
    j = j + 1
  end
  tail = strip_old_turbo(tail)

  local rebuilt = {}
  for i = 1, h - 1 do
    rebuilt[#rebuilt + 1] = lines[i]
  end
  rebuilt[#rebuilt + 1] = lines[h]
  rebuilt[#rebuilt + 1] = l1
  rebuilt[#rebuilt + 1] = l2
  for _, ln in ipairs(tail) do
    rebuilt[#rebuilt + 1] = ln
  end
  while j <= #lines do
    rebuilt[#rebuilt + 1] = lines[j]
    j = j + 1
  end

  local dirty = (#rebuilt ~= #lines)
  if not dirty then
    for i = 1, #lines do
      if rebuilt[i] ~= lines[i] then
        dirty = true
        break
      end
    end
  end
  if dirty then
    for i = 1, #rebuilt do
      lines[i] = rebuilt[i]
    end
    for i = #rebuilt + 1, #lines do
      lines[i] = nil
    end
  end
  return dirty
end

local function flush_ini(path, lines)
  local out = io.open(path, 'w')
  if not out then
    return false
  end
  for _, line in ipairs(lines) do
    out:write(line, '\n')
  end
  out:close()
  return true
end

local cls = (mq.TLO.Me.Class.ShortName() or ''):upper()
local me = mq.TLO.Me.Name()

local melee = {
  WAR = true, PAL = true, SHD = true, BRD = true, RNG = true,
  ROG = true, BER = true, MNK = true, BST = true,
}

local a1 = ...
local arg = tostring(a1 or '10'):match('^%s*(.-)%s*$') or ''

local ini = resolve_e3_bot_ini_path()
if not ini or ini == '' then
  mq.cmdf('/echo [ToggleMeleeDist] Could not resolve e3 Bot Inis path for %s', me)
  return
end

if arg:lower() == 'status' then
  if not melee[cls] then
    mq.cmdf('/echo [ToggleMeleeDist] %s (%s): status skipped (non-melee).', me, cls)
    return
  end

  local rf = io.open(ini, 'r')
  if not rf then
    mq.cmdf('/g [MeleeDist] %s (%s) -> could not open ini', me, cls)
    return
  end

  local lines = {}
  for line in rf:lines() do lines[#lines + 1] = line end
  rf:close()

  local val = read_melee_distance_in_assist(lines)
  if val == nil then val = '(missing)' end

  mq.cmdf('/g [MeleeDist] %s (%s) -> %s', me, cls, val)
  return
end

if not melee[cls] then
  mq.cmdf('/echo [ToggleMeleeDist] %s (%s) is not a melee class; script skipped.', me, cls)
  return
end

if arg:lower() == 'toggle' then
  local f = io.open(ini, 'r')
  if not f then
    mq.cmdf('/echo [ToggleMeleeDist] Could not open %s', ini)
    return
  end
  local lines = {}
  for line in f:lines() do lines[#lines + 1] = line end
  f:close()

  local raw = read_melee_distance_in_assist(lines)
  local target = flip_target_from_ini_value(raw)

  --- Always sync Mono var (can drift even when INI already matches intent).
  apply_melee_dist_far(target)

  local dirtyAssist = write_melee_distance_lines(lines, target)
  local dirtyStartup = merge_turbo_melee_startup_commands(lines, target)

  if dirtyAssist or dirtyStartup then
    if not flush_ini(ini, lines) then
      mq.cmdf('/echo [ToggleMeleeDist] Could not write %s', ini)
      return
    end
    if dirtyAssist then
      mq.cmdf('/echo [ToggleMeleeDist] %s -> Melee Distance=%s', ini, target)
    end
    if dirtyStartup then
      mq.cmdf('/echo [ToggleMeleeDist] %s -> [Startup Commands] %s + %s (needs /e3reload to apply at boot)',
        ini, KEY_STARTUP_MONO, KEY_STARTUP_ASSIST)
    end
  else
    mq.cmdf('/echo [ToggleMeleeDist] %s (already %s); synced MeleeDistFar', ini, target)
  end

  mq.cmdf('/g [MeleeDist] %s (%s) -> %s', me, cls, target)
  return
end

local target = arg
local tUpper = target:upper()
if target ~= '10' and tUpper ~= 'MAXMELEE' then
  mq.cmdf('/echo [ToggleMeleeDist] Invalid arg "%s", defaulting to 10', target)
  target = '10'
else
  if tUpper == 'MAXMELEE' then target = 'MaxMelee' end
end

apply_melee_dist_far(target)

local f = io.open(ini, 'r')
if not f then
  mq.cmdf('/echo [ToggleMeleeDist] Could not open %s', ini)
  return
end

local lines = {}
for line in f:lines() do lines[#lines + 1] = line end
f:close()

local dirtyAssist = write_melee_distance_lines(lines, target)
local dirtyStartup = merge_turbo_melee_startup_commands(lines, target)
if dirtyAssist or dirtyStartup then
  if not flush_ini(ini, lines) then
    mq.cmdf('/echo [ToggleMeleeDist] Could not write %s', ini)
    return
  end
  if dirtyAssist then
    mq.cmdf('/echo [ToggleMeleeDist] %s -> Melee Distance=%s', ini, target)
  end
  if dirtyStartup then
    mq.cmdf('/echo [ToggleMeleeDist] %s -> [Startup Commands] %s + %s (needs /e3reload to apply at boot)',
      ini, KEY_STARTUP_MONO, KEY_STARTUP_ASSIST)
  end
else
  mq.cmdf('/echo [ToggleMeleeDist] %s INI unchanged; synced MeleeDistFar at runtime', ini, target)
end
