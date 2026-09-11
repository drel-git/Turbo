-- TurboGear/references/don_lockouts.lua
-- Canonical Dragons of Norrath replay lockout rows for the dedicated DoN tab.

local M = {}

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function add_aliases(row, aliases)
    row.aliases = row.aliases or {}
    local seen = {}
    local function add(v)
        v = trim(v)
        if v ~= "" and not seen[v] then
            seen[v] = true
            row.aliases[#row.aliases + 1] = v
        end
    end
    add(row.name)
    add(row.name .. " [Solo]")
    add(row.name .. " [Duo]")
    add("T1: " .. row.name)
    add("T2: " .. row.name)
    add("T3: " .. row.name)
    for _, v in ipairs(aliases or {}) do add(v) end
end

local function row(name, replay_group, solo, duo, aliases)
    local out = {
        name = name,
        replay_group = tonumber(replay_group),
        task_ids = {},
    }
    if tonumber(solo) then out.task_ids[#out.task_ids + 1] = tonumber(solo) end
    if tonumber(duo) and tonumber(duo) ~= tonumber(solo) then out.task_ids[#out.task_ids + 1] = tonumber(duo) end
    if out.replay_group then
        local found = false
        for _, id in ipairs(out.task_ids) do
            if id == out.replay_group then found = true; break end
        end
        if not found then out.task_ids[#out.task_ids + 1] = out.replay_group end
    end
    add_aliases(out, aliases)
    return out
end

M.sections = {
    {
        id = "raid",
        title = "Raid Events",
        description = "Kindly + Tier 2 complete - 5d 12h",
        color_family = "raid",
        default_collapsed = false,
        replay_seconds = 475200,
        rows = {
            row("Calling Emoush", 5580, 5580, nil, { "Calling Emoush [Raid Event]" }),
            row("Circle of Drakes", 5587, 5587, nil, { "Circle of Drakes [Raid Event]" }),
            row("Fanning the Flames", 5500, 5501, nil, { "Fanning the Flames [Raid Event]" }),
            row("Rampaging Monolith", 5586, 5586, nil, { "Rampaging Monolith [Raid Event]" }),
            row("Trial of Perseverance", 5053, 5053, nil, { "Trial of Perseverance [Raid Event]" }),
            row("Volkara's Bite", 5582, 5582, nil, { "Volkara's Bite [Raid Event]", "Volkara", "Volkara [Raid Event]" }),
        },
    },
    {
        id = "t1_missions",
        title = "Tier 1 Missions",
        description = "Apprehensive - 4h",
        color_family = "mission",
        default_collapsed = true,
        replay_seconds = 14400,
        rows = {
            row("Best Laid Plans", 4809, 74, 4811),
            row("Diseased Pumas", 5538, 75, 5540),
            row("Lair Unguarded", 4777, 4777, 5040),
            row("Lavaspinner's Locals", 5024, 76, 5027, { "Lavaspinners Locals" }),
            row("Scrap Metal", 4883, 77, 4883),
            row("Signal Fires", 5074, 78, 5076),
            row("Sudden Tremors", 4929, 79, 4931),
            row("Tea for Thy Master", 4821, 80, 4823),
        },
    },
    {
        id = "t1_progression",
        title = "Tier 1 Progression",
        description = "12h",
        color_family = "progression",
        default_collapsed = true,
        replay_seconds = 43200,
        rows = {
            row("Children of Gimblax", 401, 401, nil, { "Children of Gimblax [2 Group Progression]" }),
        },
    },
    {
        id = "t2_missions",
        title = "Tier 2 Missions",
        description = "Amiable + Tier 1 complete - 4h",
        color_family = "mission",
        default_collapsed = true,
        replay_seconds = 14400,
        rows = {
            row("Animated Statue Plans", 5526, 82, 5528),
            row("Clues", 4865, 81, 4865),
            row("Forbin's Elixir", 5000, 89, 5003),
            row("Grounding the Drakes", 1119, 83, 1122),
            row("Infested", 1130, 84, 1133),
            row("Lavaspinner Hunting", 301, 85, 5512),
            row("Scales of Justice", 4815, 87, 4817),
            row("Splitting the Storm", 4801, 86, 4972),
            row("Storm Dragon Scales", 5532, 5533, 5536),
            row("The Drake Menace", 5016, 88, 5019),
        },
    },
    {
        id = "t2_progression",
        title = "Tier 2 Progression",
        description = "12h",
        color_family = "progression",
        default_collapsed = true,
        replay_seconds = 43200,
        rows = {
            row("Sickness of the Spirit", 4785, 4785, nil, { "Sickness of the Spirit [2 Group Progression]" }),
        },
    },
    {
        id = "t3_missions",
        title = "Tier 3 Missions",
        description = "Kindly + Tier 2 complete - 4h",
        color_family = "mission",
        default_collapsed = true,
        replay_seconds = 14400,
        rows = {
            row("A Halfling's Greed", 5600, 90, 5603),
            row("Death Comes Swiftly", 4845, 91, 4847),
            row("Diving For Lavarocks", 5565, 5565, 5573),
            row("Dragon's Egg", 4889, 92, 4889),
            row("Flight of the Black Wing Drakes", 4980, 95, 4990),
            row("Holy Hour", 4774, 93, 4774),
            row("House of the Autumn Rose", 5068, 94, 5070),
            row("Lost Comrades", 4981, 96, 4992),
            row("Spider's Eye", 4895, 97, 4895),
            row("The Creator", 4795, 98, 4966),
        },
    },
}

local all_rows_cache = nil

function M.all_rows()
    if all_rows_cache then return all_rows_cache end
    local out = {}
    for _, section in ipairs(M.sections) do
        for _, r in ipairs(section.rows or {}) do
            r.section_id = section.id
            r.section_title = section.title
            out[#out + 1] = r
        end
    end
    all_rows_cache = out
    return out
end

function M.row_count()
    return #M.all_rows()
end

function M.lookup_keys(row)
    local out, seen = {}, {}
    local function add(v)
        v = trim(v)
        if v ~= "" and not seen[v] then
            seen[v] = true
            out[#out + 1] = v
        end
    end
    if row.replay_group then add(tostring(row.replay_group)) end
    for _, id in ipairs(row.task_ids or {}) do add(tostring(id)) end
    for _, alias in ipairs(row.aliases or {}) do add(alias) end
    return out
end

local function normalize_title(s)
    s = trim(s):lower()
    s = s:gsub("^t[123]:%s*", "")
    s = s:gsub("%s*%[solo%]%s*", " ")
    s = s:gsub("%s*%[duo%]%s*", " ")
    s = s:gsub("%s*%[raid event%]%s*", " ")
    s = s:gsub("%s*%[2 group progression%]%s*", " ")
    s = s:gsub("[`'’]", "")
    s = s:gsub("[^%w]+", " ")
    s = s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    return s
end

M.normalize_title = normalize_title

local alias_index = nil

local function ensure_alias_index()
    if alias_index then return alias_index end
    alias_index = {}
    for _, r in ipairs(M.all_rows()) do
        if r.replay_group then alias_index[tostring(r.replay_group)] = r end
        for _, id in ipairs(r.task_ids or {}) do alias_index[tostring(id)] = r end
        alias_index[normalize_title(r.name)] = r
        for _, alias in ipairs(r.aliases or {}) do
            alias_index[normalize_title(alias)] = r
        end
    end
    return alias_index
end

function M.lookup(value)
    value = trim(value)
    if value == "" then return nil end
    local idx = ensure_alias_index()
    return idx[value] or idx[normalize_title(value)]
end

return M
