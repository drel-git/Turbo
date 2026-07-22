--[[
   *  *  *  *  *  *  *  *  *  [  T u r b o T h e m e  ]  *  *  *  *  *  *  *  *  *
             Centralized design tokens for TurboSuite ImGui rendering.
             require('Turbo.theme') from any Turbo Lua file.
             @version lua/Turbo/theme.lua 1.5.2
--]]

local M = {}

M.space = {
    xs = 4,
    sm = 6,
    md = 10,
    lg = 14,
}

-- =========================================================
-- Layout constants
-- =========================================================
M.layout = {
    -- Top bar / tab bar
    topBarH      = 32,
    tabBarH      = 28,
    rowH         = 22,

    -- Window sizing
    windowMinW   = 480,
    windowMaxW   = 620,
    fullTargetW  = 480,
    slimTargetW  = 280,
    -- +24px clears the hairline outer scrollbar on Actions/Review/Setup/More
    -- (shell height is applied every frame via SetWindowSize).
    fullTargetH  = 704,
    slimTargetH  = 700,
    actionsFullW = 480,
    setupFullW   = 480,
    reviewFullW  = 480,
    -- v1.2.1: unified Big View width. state.lua's windowWidthForTab uses
    -- this for ALL non-slim tabs so the window doesn't resize when switching
    -- Actions / Setup / Review. Set to the widest of the three per-tab
    -- widths above so nothing gets clipped.
    bigViewW     = 480,
    -- Unified full-view height. Actions / Review / Setup / More share one
    -- shell so tab switches do not resize the window.
    bigViewH     = 704,
    actionsFullH = 640,
    toolsFullH   = 620,
    gainsFullH   = 720,
    actionsSlimH = 700,
    setupSharedFullH = 704,
    setupAdvancedFullH = 860,
    setupFullH   = 820,
    reviewFullH  = 820,
    lootManagerFullH = 820,
    lootManagerSlimH = 700,

    -- Skip list
    skipRowH          = 22,
    skipListMaxFull   = 180,
    skipListMaxSlim   = 220,
    reviewSkipListMaxFull = 248,
    reviewActionPanelH    = 196,
    skipClearMinCount = 2,    -- "Clear all skips" appears when pending >= this (v1.2.1: was 10, tester wants 2)

    -- Button sizing
    actionBtnH       = 0,    -- 0 = ImGui auto height
    ruleBtnW         = 92,
    slimRuleBtnH     = 36,
    layoutModeBtnW   = 58,
    layoutModeBtnH   = 28,
    slimLayoutBtnW   = 50,
    slimLayoutBtnH   = 24,
    helpChipW        = 40,
    helpChipH        = 28,
    slimHelpH        = 22,
    footerWalletW    = 28,
    footerReserveH   = 54,

    -- Skip badge (top bar)
    skipBadgeW   = 28,
    skipBadgeH   = 22,

    -- Status message auto-clear (ms) — was Slim-only, will become universal
    statusMsgTtlMs = 14000,
}

-- =========================================================
-- Colors
-- All values are {r,g,b,a} for IM_COL32 or {r,g,b,a} normalized
-- for ImGui.TextColored. Convention per key:
--   .sep   = {r,g,b,a}   IM_COL32 args (0-255)
--   .label = {r,g,b,a}   normalized (0.0-1.0)
--   .btn   = {r,g,b}     IM_COL32 base (alpha always 255)
-- =========================================================
M.col = {

    -- ---- Section separators + labels ----
    --- 1.4.0: each section gets a `dot` field. Rendered by sectionHeader as a
    --- small filled circle before the label so the eye finds section breaks
    --- faster. Dot color is brighter than `sep` so it reads as a marker rather
    --- than a continuation of the separator line.
    --- 1.5.0: Conversions and Corpses got their own palettes. Both were
    --- previously reusing `currency` (gold), which meant three adjacent
    --- section bands on the Actions tab all read as gold — the eye couldn't
    --- find the section breaks. New hue map across the Actions tab:
    ---   TurboLoot   blue        (210°)
    ---   TurboGive   green       (140°)
    ---   Currency    gold        ( 45°)
    ---   Conversions teal        (185°) — "exchange" semantic, distinct hue
    ---   Corpses     muted violet(285°) — distinct again, ghosty/inert feel
    --- TurboKey stays cyan (175°); only appears in slim/cursor-hand contexts
    --- so the slight teal/cyan adjacency to Conversions never appears in
    --- the same screen.
    turboloot   = { sep={55,80,130,90},   label={0.55,0.68,0.85,0.9}, dot={70,110,180,255}    },
    turbogive   = { sep={50,110,65,90},   label={0.45,0.72,0.52,0.9}, dot={75,150,95,255}     },
    turbokey    = { sep={55,130,150,90},  label={0.50,0.78,0.85,0.9}, dot={75,170,195,255}    },
    currency    = { sep={140,115,45,90},  label={0.82,0.75,0.42,0.9}, dot={210,165,65,255}    },
    conversions = { sep={45,115,125,90},  label={0.45,0.78,0.82,0.9}, dot={65,175,190,255}    },
    corpses     = { sep={95,75,120,90},   label={0.62,0.55,0.74,0.9}, dot={140,110,175,255}   },
    utility     = { sep={75,95,115,90},   label={0.58,0.70,0.82,0.9}, dot={100,135,165,255}   },
    skipreview  = { sep={130,95,45,90},   label={0.80,0.65,0.42,0.9}, dot={185,140,70,255}    },
    profile     = { sep={100,85,140,90},  label={0.65,0.58,0.78,0.9} },

    -- ---- Neutrals ----
    neutral    = {55,58,65},
    neutralLit = {75,78,85},
    warn       = {145,60,55},
    warnLit    = {165,80,75},

    -- ---- Status / feedback ----
    statusOn   = {0.45,0.9,0.55,1.0},
    statusOff  = {0.85,0.42,0.42,1.0},
    statusMsg  = {0.78,0.78,0.55,1.0},
    plat       = {0.85,0.78,0.38,1.0},
    aa         = {0.55,0.72,0.9,1.0},
    errorCol   = {0.9,0.35,0.35,1.0},

    -- ---- Member / looter row tints (IM_COL32) ----
    memberHi   = {50,85,130,50},
    memberAll  = {50,110,130,40},
    memberSel  = {105,85,150,70},
    lootCell   = {42,120,72,105},

    -- ---- Row states ----
    rowSelected = {105,85,150,80},
    rowLoot     = {42,120,72,105},
    rowAll      = {50,110,130,40},
    rowSingle   = {50,85,130,50},

    -- ---- Rule buttons ----
    ruleKeep    = {60,120,80},
    ruleTrade   = {70,100,150},
    ruleTribute = {90,82,130},
    ruleDestroy = {145,60,55},
    ruleSkip    = {55,58,65},

    -- ---- TurboKey rule buttons (alias table keeps old TurboKeyRGB API) ----
    -- Used by ruleButton() and Skip Review srBtn helpers.
    --- 1.4.0: aligned to chat color codes used in TurboLoot.mac help output
    --- (\ag SELL, \ap BANK, \ay TRIBUTE, \ar DESTROY) so a user's mental model
    --- carries from chat into the GUI button bar. KEEP became blue (was green)
    --- to resolve the green-on-green collision with SELL — chat uses green for
    --- both KEEP and SELL but disambiguates via word context, which buttons
    --- can't replicate. `trade` kept as an alias of `bank` for any external
    --- consumer that still references the pre-1.4.0 name; remove once the
    --- audit is clean.
    turboKeyRGB = {
        keep    = {70,100,150},   -- BLUE (new) — was {60,120,80} green; greens collide on adjacent buttons
        sell    = {60,120,80},    -- GREEN — matches \ag in chat; took KEEP's old shade
        bank    = {90,82,130},    -- PURPLE — matches \ap in chat; took the old `tribute` slot
        tribute = {130,95,35},    -- GOLD/AMBER — matches \ay in chat; new value, was {90,82,130} purple
        destroy = {145,60,55},    -- RED — matches \ar in chat (unchanged)
        skip    = {55,58,65},     -- GRAY — IGNORE / neutral (unchanged)
        --- 1.4.1: ANNOUNCE — TEAL/CYAN — "leave it, broadcast it." Skip-class
        --- rule (item stays on corpse) with a forced announce so another
        --- character can grab it. Distinct from KEEP's blue (loot-class) and
        --- IGNORE's muted gray (silent skip). Cyan in chat (\at) is the EQ
        --- convention for "important info, look here," matching the semantic.
        announce = {55,130,140},
        --- Back-compat alias: any caller still reading `trade` gets the same
        --- color BANK now uses. New code should reference `sell` or `bank`
        --- directly so the action-color mapping stays explicit.
        trade   = {90,82,130},    -- alias of bank
    },

    -- ---- Skip reason text (normalized, keyed by reason code) ----
    skipReason = {
        unlisted                          = {0.72,0.72,0.72,1},
        below_threshold                   = {0.62,0.72,0.82,1},
        stackable_below_pp_threshold      = {0.62,0.72,0.82,1},
        lore_already_have                 = {0.82,0.65,0.35,1},
        lore_already_owned                = {0.82,0.65,0.35,1},
        lore_denied_cache                 = {0.82,0.65,0.35,1},
        lore_have_copy_cannot_destroy     = {0.82,0.65,0.35,1},
        numeric_limit_reached             = {0.65,0.82,0.65,1},
        wildcard_excluded                 = {0.55,0.55,0.72,1},
        bag_full                          = {0.90,0.45,0.45,1},
        inventory_full                    = {0.90,0.45,0.45,1},
        default                           = {0.58,0.58,0.62,1},
    },

    -- ---- Window chrome ----
    windowBg     = {12,15,22,246},
    titleBg      = {14,17,24,255},
    titleBgActive= {20,24,34,255},
    frameBg      = {25,29,39,255},
    frameBgHov   = {38,44,58,255},
    header       = {32,54,82,255},
    headerHov    = {46,70,104,255},
    tableRowBg   = {16,18,25,255},
    tableRowBgAlt= {21,23,31,255},
    tableBorderS = {58,58,48,255},
    tableBorderL = {42,44,40,255},

    -- ---- Top bar ----
    topBar       = {14,17,24,245},
    topBarBorder = {185,140,70,220},

    -- ---- Skip badge (top bar + Mini) ----
    skipBadge    = {120,85,30,255},
    skipBadgeHov = {145,110,55,255},
    skipBadgeDim = {55,58,68,255},
    skipBadgeDimHov = {72,76,88,255},

    -- ---- Mini bar ----
    miniBorder      = {185,140,70,235},
    miniBg          = {12,15,22,248},
    miniLabel       = {255,188,72,230},   -- gold Turbo brand
    miniLabelHov    = {255,188,72,35},
    miniTurboOn     = {50,130,72,255},
    miniTurboOnHov  = {72,152,94,255},
    miniTurboOff    = {115,48,42,255},
    miniTurboOffHov = {137,70,64,255},
    miniLooter      = {52,82,132,55},     -- hover tint
    miniLooterSet   = {210,158,55,255},   -- amber when unset
    miniLooterActive= {188,198,220,220},  -- blue-white when set
    miniLoot        = {55,95,155,255},
    miniLootHov     = {80,125,190,255},
    miniLootText    = {210,228,255,255},
    miniSkipActive  = {145,95,22,255},
    miniSkipActHov  = {175,122,45,255},
    miniSkipActText = {255,222,130,255},
    miniSkipDim     = {38,42,55,180},
    miniSkipDimHov  = {55,60,75,200},
    miniSkipDimText = {90,95,112,200},
    miniWallet      = {105,82,18,255},
    miniWalletHov   = {148,118,35,255},
    miniWalletText  = {245,210,80,255},
    miniTools       = {42,46,60,255},
    miniToolsHov    = {62,68,88,255},
    miniToolsText   = {155,162,185,220},
    miniExpand      = {45,50,68,255},
    miniExpandHov   = {68,75,100,255},
    miniExpandText  = {140,150,175,220},
    miniDivider     = {0.35,0.38,0.48,0.7},
    miniZoneDivider = {0.28,0.32,0.42,0.6},

    -- ---- Tab bar ----
    tabActive    = {44,78,122,255},
    tabActiveHov = {62,98,146,255},
    tabInactive  = {27,31,42,255},
    tabInactiveHov = {42,48,62,255},
    tabMini      = {130,72,42,255},
    tabMiniHov   = {155,92,58,255},
    lootBtn      = {70,100,150,255},
    lootBtnHov   = {95,125,175,255},

    -- ---- Section button variants ----
    turbolootBtn    = {70,100,150},
    turbolootBtnAlt = {85,110,155},
    turbogiveBtn    = {60,120,80},
    turbogiveBtnAlt = {75,125,90},
    turbokeyBtn     = {55,125,145},
    currencyBtn     = {160,130,50},
    currencyBtnAlt  = {145,120,55},
}

M.component = {
    chip = {
        radius = 4,
        text = {210, 220, 235, 255},
    },
    badge = {
        active = {
            base = M.col.skipBadge,
            hover = M.col.skipBadgeHov,
            text = {255, 222, 130, 255},
        },
        inactive = {
            base = M.col.skipBadgeDim,
            hover = M.col.skipBadgeDimHov,
            text = {160, 168, 186, 220},
        },
    },
    panel = {
        bg = M.col.windowBg,
        border = M.col.topBarBorder,
    },
    sectionHeader = {
        text = {0.60, 0.66, 0.76, 0.92},
        muted = {0.46, 0.50, 0.58, 0.92},
        prefix = '%s',
    },
    primaryButton = {
        base = M.col.lootBtn,
        hover = M.col.lootBtnHov,
        text = M.col.miniLootText,
    },
    secondaryButton = {
        base = {46,49,58,255},
        hover = {66,69,78,255},
        text = {220,225,235,255},
    },
    menuButton = {
        base = {58,86,125,255},
        hover = {74,104,148,255},
        active = {48,74,110,255},
        text = {235,240,248,255},
    },
    successButton = {
        base = {60,120,80,255},
        hover = {80,140,100,255},
        text = {228,245,232,255},
    },
    amberButton = {
        base = {130,95,35,255},
        hover = {155,120,60,255},
        text = {255,226,145,255},
    },
    -- Fleet wallet `$` chrome: teal (Conversions / TurboKey family), not amber
    -- (amber is minimize `-` and Currency gold).
    walletButton = {
        base = {45,115,125,255},
        hover = {65,145,155,255},
        text = {210,245,250,255},
    },
    windowToggleButton = {
        base = {116,84,42,220},
        hover = {145,108,58,245},
        text = {235,205,150,245},
    },
    miniCountButton = {
        base = {58,62,72,255},
        hover = {78,84,98,255},
        text = {224,228,238,255},
    },
    windowButton = {
        base = {48,72,108,255},
        hover = {66,96,140,255},
        text = {220,232,252,255},
    },
    utilityButton = {
        base = {42,54,70,255},
        hover = {58,74,94,255},
        text = {218,228,238,255},
    },
    utilityAccentButton = {
        base = {58,62,72,255},
        hover = {78,84,98,255},
        text = {224,228,238,255},
    },
    valueButton = {
        base = {130,95,35,255},
        hover = {155,120,60,255},
        text = {255,226,145,255},
    },
    storageButton = {
        base = {90,82,130,255},
        hover = {112,102,155,255},
        text = {232,224,248,255},
    },
    infoButton = {
        base = {45,104,112,255},
        hover = {60,126,136,255},
        text = {220,244,246,255},
    },
    footerToolsButton = {
        base = {48,56,70,255},
        hover = {68,78,96,255},
        text = {220,226,238,255},
    },
    footerSetupButton = {
        base = {46,64,82,255},
        hover = {66,88,110,255},
        text = {220,230,240,255},
    },
    footerCommandsButton = {
        base = {58,52,72,255},
        hover = {78,70,98,255},
        text = {226,220,240,255},
    },
    subTabActive = {
        base = {44,64,94,255},
        hover = {58,82,118,255},
        text = {220,232,252,255},
    },
    subTabInactive = {
        base = {28,32,42,255},
        hover = {44,50,64,255},
        text = {190,198,214,255},
    },
    dangerButton = {
        base = {145,60,55,255},
        hover = {170,85,80,255},
        text = {255,228,228,255},
    },
    toggleOn = {
        track = {50,140,80,255},
        knob = {230,230,230,255},
    },
    toggleOff = {
        track = {65,68,78,255},
        knob = {230,230,230,255},
    },
    modeChip = {
        single = {0.72, 0.78, 0.65, 1.0},
        multi  = {0.68, 0.72, 0.92, 1.0},
        all    = {0.55, 0.78, 0.95, 1.0},
    },
}

-- =========================================================
-- Helper: safely look up a skip-reason color, falling back
-- to default if the reason code is unknown.
-- Usage: local c = Theme.skipReasonColor(reasonCode)
--        ImGui.TextColored(c[1],c[2],c[3],c[4], text)
-- =========================================================
function M.skipReasonColor(reasonCode)
    if reasonCode and M.col.skipReason[reasonCode] then
        return M.col.skipReason[reasonCode]
    end
    return M.col.skipReason.default
end

-- =========================================================
-- Helper: lighten an {r,g,b} table by `amount` (0-255 clamp).
-- Usage: local hov = Theme.lighten(Theme.col.ruleKeep, 25)
-- =========================================================
function M.lighten(rgb, amount)
    amount = amount or 25
    return {
        math.min(rgb[1]+amount, 255),
        math.min(rgb[2]+amount, 255),
        math.min(rgb[3]+amount, 255),
    }
end

function M.tabVariant(isActive, hasAttention)
    if isActive then
        return {
            base = M.col.tabActive,
            hover = M.col.tabActiveHov,
            text = {220, 232, 252, 255},
        }
    end
    return {
        base = M.col.tabInactive,
        hover = M.col.tabInactiveHov,
        text = hasAttention and {238, 218, 170, 255} or {195, 202, 220, 255},
    }
end

return M
