-- XP Rail: a flat experience / reputation bar in place of the game's own.
--
--  * Experience below max level, else the watched reputation (or pick one).
--  * Rested XP shows as a faint second fill ahead of the real one.
--  * Any length and thickness, horizontal or vertical, movable (unlock, drag).
--  * Gradient color sets like Cooldown Skin, class color, or the game's colors;
--    reputation can follow its standing color.
--  * Thin black edge on a dark track, so it sits with mUI and the default UI alike.
--  * Hover for the numbers; right-click for the options (/xprail).

local ADDON = ...

-- Locale ------------------------------------------------------------------

local L = {
    title = "XP Rail",
    sub = "Changes apply at once. Drag to move, Esc to close.",
    xp = "Experience", rep = "Reputation",
    level = "Level %d", rested = "Rested: %s (%s)", toLevel = "To next level: %s",
    questXP = "Completed quests: %s (%s)", perHour = "This session: %s XP/hour", ttl = "Level up in: %s",
    questShow = "Show XP from completed quests",
    noRep = "No reputation watched. Pick one in the Reputation window (\"Show as experience bar\").",
    hint = "Right-click: options",
    secLayout = "Layout", secColors = "Colors", secText = "Text", secBehave = "Behavior",
    orient = "Orientation", horizontal = "Horizontal", vertical = "Vertical",
    length = "Length", thick = "Thickness", border = "Border",
    locked = "Locked (uncheck to drag the bar)", center = "Center horizontally",
    colors = "Colors", bright = "Brightness", repStanding = "Reputation in its standing color",
    restedShow = "Show rested XP", spark = "Spark at the fill's end",
    text = "Text", textSize = "Text size",
    textAlways = "Always", textHover = "Hover", textOff = "Off",
    mode = "Shows", modeAuto = "Auto (XP, then rep)", modeXP = "Experience only", modeRep = "Reputation only",
    hideBlizz = "Hide the default bar", reset = "Reset to defaults",
    dragMe = "XP Rail - drag me",
    reloadNote = "Showing the default bar again needs /reload.",
    openBtn = "Open XP Rail", openNote = "The options open in their own window (also with /xprail).",
    cls = "Class color", default = "Game colors", borderStyle = "Border style", black = "Black", gold = "Gold",
    famGame = "Game", famClassic = "Classic", famQuality = "Quality",
    castBar = "Cast bar", rested2 = "Rested",
    modeAutoShort = "Auto", xpShort = "XP", repShort = "Rep",
}
if GetLocale() == "deDE" then
    L.sub = "Änderungen wirken sofort. Ziehen zum Verschieben, Esc zum Schließen."
    L.xp, L.rep = "Erfahrung", "Ruf"
    L.level, L.rested, L.toLevel = "Stufe %d", "Erholt: %s (%s)", "Bis zur nächsten Stufe: %s"
    L.questXP, L.perHour, L.ttl = "Fertige Quests: %s (%s)", "Diese Sitzung: %s EP/Stunde", "Stufenaufstieg in: %s"
    L.questShow = "EP aus fertigen Quests anzeigen"
    L.noRep = "Kein Ruf beobachtet. Wähle einen im Ruffenster (\"Als Erfahrungsleiste anzeigen\")."
    L.hint = "Rechtsklick: Optionen"
    L.secLayout, L.secColors, L.secText, L.secBehave = "Aufbau", "Farben", "Text", "Verhalten"
    L.orient, L.horizontal, L.vertical = "Ausrichtung", "Waagerecht", "Senkrecht"
    L.length, L.thick, L.border = "Länge", "Dicke", "Rahmen"
    L.borderStyle, L.black, L.gold = "Rahmenstil", "Schwarz", "Gold"
    L.locked, L.center = "Fixiert (Haken weg, um die Leiste zu ziehen)", "Waagerecht zentrieren"
    L.colors, L.bright, L.repStanding = "Farben", "Helligkeit", "Ruf in der Farbe seines Rangs"
    L.restedShow, L.spark = "Erholte EP anzeigen", "Funke am Ende der Füllung"
    L.text, L.textSize = "Text", "Textgröße"
    L.textAlways, L.textHover, L.textOff = "Immer", "Maus", "Aus"
    L.mode, L.modeAuto, L.modeXP, L.modeRep = "Zeigt", "Automatisch (EP, dann Ruf)", "Nur Erfahrung", "Nur Ruf"
    L.hideBlizz, L.reset = "Standardleiste ausblenden", "Auf Standard zurücksetzen"
    L.dragMe = "XP Rail - zieh mich"
    L.reloadNote = "Die Standardleiste kommt erst nach /reload zurück."
    L.openBtn, L.openNote = "XP Rail öffnen", "Die Optionen öffnen sich in einem eigenen Fenster (auch mit /xprail)."
    L.cls, L.default, L.famGame = "Klassenfarbe", "Spielfarben", "Spiel"
    L.famClassic, L.famQuality, L.castBar, L.rested2 = "Klassisch", "Qualität", "Zauberleiste", "Erholt"
    L.modeAutoShort, L.xpShort, L.repShort = "Auto", "EP", "Ruf"
end

-- Settings ----------------------------------------------------------------

local SQUARE = "Interface\\Buttons\\WHITE8X8"

local DEFAULTS = {
    mode = "auto",           -- "auto", "xp" or "rep"
    orient = "horizontal",   -- "horizontal" or "vertical"
    length = 520,            -- along the fill, in pixels
    thick = 10,              -- across it
    border = 1,              -- edge thickness, pixels (0 = none)
    borderStyle = "black",   -- "black" (mUI) or "gold" (like the default unit frames)
    point = { "BOTTOM", 0, 4 },
    locked = true,
    color = "default",       -- a PALETTES name, "class" or "default"
    bright = 0.85,
    repStanding = true,      -- rep uses its standing color whatever the set
    rested = true,
    quests = true,           -- overlay for XP waiting in completed quests
    spark = true,
    text = "hover",          -- "always", "hover" or "off"
    textSize = 10,
    hideBlizz = true,
}

-- Gradient pairs, start to end of the fill (same sets as Cooldown Skin).
local PALETTES = {
    -- Neon.
    neon   = { { 0.00, 1.00, 1.00 }, { 1.00, 0.00, 1.00 } },   -- cyan to magenta
    toxic  = { { 0.60, 1.00, 0.00 }, { 0.00, 1.00, 0.60 } },   -- lime to mint
    sunset = { { 1.00, 0.45, 0.00 }, { 1.00, 0.00, 0.55 } },   -- orange to hot pink
    void   = { { 0.65, 0.00, 1.00 }, { 0.00, 0.55, 1.00 } },   -- violet to electric blue
    fel    = { { 0.15, 1.00, 0.10 }, { 0.85, 1.00, 0.00 } },   -- fel green to yellow
    ice    = { { 0.70, 0.95, 1.00 }, { 0.15, 0.40, 1.00 } },   -- frost to deep blue
    -- Catppuccin Mocha pastels.
    ctp_mauve = { { 0.80, 0.65, 0.97 }, { 0.96, 0.76, 0.91 } },
    ctp_peach = { { 0.98, 0.70, 0.53 }, { 0.95, 0.55, 0.66 } },
    ctp_teal  = { { 0.58, 0.89, 0.84 }, { 0.54, 0.86, 0.92 } },
    ctp_blue  = { { 0.54, 0.71, 0.98 }, { 0.71, 0.75, 1.00 } },
    ctp_green = { { 0.65, 0.89, 0.63 }, { 0.98, 0.89, 0.69 } },
    ctp_rose  = { { 0.95, 0.80, 0.80 }, { 0.92, 0.63, 0.67 } },
    -- Cyberpunk neons.
    cyber_yellow = { { 0.99, 0.93, 0.04 }, { 0.02, 0.85, 0.91 } },
    cyber_pink   = { { 1.00, 0.16, 0.43 }, { 0.48, 0.02, 0.92 } },
    cyber_cyan   = { { 0.02, 0.85, 0.91 }, { 0.18, 0.42, 1.00 } },
    cyber_red    = { { 1.00, 0.00, 0.24 }, { 1.00, 0.00, 0.63 } },
    cyber_acid   = { { 0.22, 1.00, 0.08 }, { 0.00, 0.94, 1.00 } },
    cyber_purple = { { 0.69, 0.15, 1.00 }, { 1.00, 0.16, 0.43 } },
    -- Dracula theme.
    drac_purple = { { 0.74, 0.58, 0.98 }, { 1.00, 0.47, 0.78 } },
    drac_cyan   = { { 0.55, 0.91, 0.99 }, { 0.74, 0.58, 0.98 } },
    drac_green  = { { 0.31, 0.98, 0.48 }, { 0.55, 0.91, 0.99 } },
    drac_orange = { { 1.00, 0.72, 0.42 }, { 1.00, 0.33, 0.33 } },
    drac_pink   = { { 1.00, 0.47, 0.78 }, { 1.00, 0.33, 0.33 } },
    drac_yellow = { { 0.95, 0.98, 0.55 }, { 0.31, 0.98, 0.48 } },
    -- Classic: the default UI's own bar colors, a little darker at the start.
    cl_health  = { { 0.00, 0.60, 0.00 }, { 0.00, 1.00, 0.00 } },
    cl_mana    = { { 0.00, 0.18, 0.70 }, { 0.10, 0.40, 1.00 } },
    cl_rage    = { { 0.60, 0.00, 0.00 }, { 1.00, 0.00, 0.00 } },
    cl_energy  = { { 0.75, 0.65, 0.00 }, { 1.00, 1.00, 0.00 } },
    cl_cast    = { { 0.80, 0.55, 0.00 }, { 1.00, 0.70, 0.00 } },
    cl_rested  = { { 0.00, 0.25, 0.60 }, { 0.00, 0.39, 0.88 } },
    -- Item quality colors.
    q_uncommon  = { { 0.08, 0.65, 0.00 }, { 0.12, 1.00, 0.00 } },
    q_rare      = { { 0.00, 0.29, 0.58 }, { 0.00, 0.44, 0.87 } },
    q_epic      = { { 0.42, 0.14, 0.62 }, { 0.64, 0.21, 0.93 } },
    q_legendary = { { 0.70, 0.33, 0.00 }, { 1.00, 0.50, 0.00 } },
}
-- The swatch rows in the settings window, one family per row.
local PALETTE_ROWS = {
    { name = L.famGame,    list = { "default", "class" } },
    { name = L.famClassic, list = { "cl_health", "cl_mana", "cl_rage", "cl_energy", "cl_cast", "cl_rested" } },
    { name = L.famQuality, list = { "q_uncommon", "q_rare", "q_epic", "q_legendary" } },
    { name = "Neon",       list = { "neon", "toxic", "sunset", "void", "fel", "ice" } },
    { name = "Catppuccin", list = { "ctp_mauve", "ctp_peach", "ctp_teal", "ctp_blue", "ctp_green", "ctp_rose" } },
    { name = "Cyberpunk",  list = { "cyber_yellow", "cyber_pink", "cyber_cyan", "cyber_red", "cyber_acid", "cyber_purple" } },
    { name = "Dracula",    list = { "drac_purple", "drac_cyan", "drac_green", "drac_orange", "drac_pink", "drac_yellow" } },
}
local COLOR_NAMES = { default = L.default, class = L.cls,
    neon = "Neon", toxic = "Toxic", sunset = "Sunset", void = "Void", fel = "Fel", ice = "Ice",
    ctp_mauve = "Catppuccin Mauve", ctp_peach = "Catppuccin Peach", ctp_teal = "Catppuccin Teal",
    ctp_blue = "Catppuccin Blue", ctp_green = "Catppuccin Green", ctp_rose = "Catppuccin Rose",
    cyber_yellow = "Cyberpunk Yellow", cyber_pink = "Cyberpunk Pink", cyber_cyan = "Cyberpunk Cyan",
    cyber_red = "Cyberpunk Red", cyber_acid = "Cyberpunk Acid", cyber_purple = "Cyberpunk Purple",
    drac_purple = "Dracula Purple", drac_cyan = "Dracula Cyan", drac_green = "Dracula Green",
    drac_orange = "Dracula Orange", drac_pink = "Dracula Pink", drac_yellow = "Dracula Yellow",
    -- The game's own words, so they read right in every language.
    cl_health = HEALTH or "Health", cl_mana = MANA or "Mana", cl_rage = RAGE or "Rage",
    cl_energy = ENERGY or "Energy", cl_cast = L.castBar, cl_rested = L.rested2,
    q_uncommon = ITEM_QUALITY2_DESC or "Uncommon", q_rare = ITEM_QUALITY3_DESC or "Rare",
    q_epic = ITEM_QUALITY4_DESC or "Epic", q_legendary = ITEM_QUALITY5_DESC or "Legendary" }

local XP_COLOR = { 0.58, 0.00, 0.55 }      -- the game's own XP purple
local RESTED_COLOR = { 0.00, 0.39, 0.88 }  -- and its rested blue
local QUEST_COLOR = { 1.00, 0.59, 0.00 }   -- XP waiting in completed quests

local db

local function say(msg) print("|cff8ce6c0XP Rail:|r " .. msg) end

-- Data --------------------------------------------------------------------
-- Returns what the bar shows now: { kind, cur, max, rested, label, reaction } or nil.

local function atMaxLevel()
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or MAX_PLAYER_LEVEL or 60
    return UnitLevel("player") >= maxLevel or (IsXPUserDisabled and IsXPUserDisabled())
end

-- XP from quests in the log that are ready to turn in. Asked by quest ID only;
-- the log's selected quest is never changed (that is Blizzard's UI state).
local questXPCache = 0
local function scanQuests()
    local n = (C_QuestLog and C_QuestLog.GetNumQuestLogEntries or GetNumQuestLogEntries)()
    local sum = 0
    for i = 1, n or 0 do
        local id
        if C_QuestLog and C_QuestLog.GetQuestIDForLogIndex then
            id = C_QuestLog.GetQuestIDForLogIndex(i)
        elseif GetQuestLogTitle then
            id = select(8, GetQuestLogTitle(i))
        end
        if id and id > 0 then
            local done = (C_QuestLog and C_QuestLog.IsComplete and C_QuestLog.IsComplete(id))
                or (C_QuestLog and C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(id))
            if done and GetQuestLogRewardXP then
                local ok, xp = pcall(GetQuestLogRewardXP, id)
                if ok and type(xp) == "number" then sum = sum + xp end
            end
        end
    end
    questXPCache = sum
end

-- XP gained since login, for XP/hour. Level-ups add the rest of the old level.
local session = { start = GetTime(), gained = 0 }
local function trackXP()
    local cur, max = UnitXP("player"), UnitXPMax("player")
    if session.cur then
        if cur >= session.cur and max == session.max then
            session.gained = session.gained + (cur - session.cur)
        elseif max ~= session.max then
            session.gained = session.gained + (session.max - session.cur) + cur
        end
    end
    session.cur, session.max = cur, max
end

local function xpData()
    if atMaxLevel() then return nil end
    local cur, max = UnitXP("player"), UnitXPMax("player")
    if not max or max <= 0 then return nil end
    return { kind = "xp", cur = cur, max = max, rested = GetXPExhaustion() or 0, quest = questXPCache,
        label = string.format(L.level, UnitLevel("player")) }
end

local function repData()
    local name, reaction, lo, hi, value
    if C_Reputation and C_Reputation.GetWatchedFactionData then
        local d = C_Reputation.GetWatchedFactionData()
        if d and d.name then
            name, reaction, lo, hi, value = d.name, d.reaction, d.currentReactionThreshold, d.nextReactionThreshold, d.currentStanding
        end
    elseif GetWatchedFactionInfo then
        name, reaction, lo, hi, value = GetWatchedFactionInfo()
    end
    if not name then return nil end
    local cur, max = value - lo, hi - lo
    if max <= 0 then cur, max = 1, 1 end     -- top standing: a full bar
    local standing = GetText and GetText("FACTION_STANDING_LABEL" .. reaction, UnitSex("player")) or ""
    return { kind = "rep", cur = cur, max = max, rested = 0, label = name, standing = standing, reaction = reaction }
end

local function currentData()
    if db.mode == "xp" then return xpData() end
    if db.mode == "rep" then return repData() end
    return xpData() or repData()
end

-- Colors ------------------------------------------------------------------

local function colorsFor(d)
    local a, b
    if d and d.kind == "rep" and (db.repStanding or db.color == "default") then
        local c = FACTION_BAR_COLORS and FACTION_BAR_COLORS[d.reaction]
        if c then a = { c.r * 0.75, c.g * 0.75, c.b * 0.75 }; b = { c.r, c.g, c.b } end
    end
    if not a then
        local p = PALETTES[db.color]
        if p then
            a, b = p[1], p[2]
        else
            local r, g, bl
            if db.color == "class" then
                local _, class = UnitClass("player")
                local cc = class and ((C_ClassColor and C_ClassColor.GetClassColor(class)) or RAID_CLASS_COLORS[class])
                if cc then r, g, bl = cc.r, cc.g, cc.b end
            end
            r, g, bl = r or XP_COLOR[1], g or XP_COLOR[2], bl or XP_COLOR[3]
            a = { r * 0.6, g * 0.6, bl * 0.6 }
            b = { math.min(1, r * 1.2), math.min(1, g * 1.2), math.min(1, bl * 1.2) }
        end
    end
    local k = db.bright or 1
    return { a[1] * k, a[2] * k, a[3] * k }, { b[1] * k, b[2] * k, b[3] * k }
end

local function gradient(tex, dir, a, b, alpha)
    alpha = alpha or 1
    if CreateColor and tex.SetGradient then
        local ok = pcall(tex.SetGradient, tex, dir, CreateColor(a[1], a[2], a[3], alpha), CreateColor(b[1], b[2], b[3], alpha))
        if ok then return end
    end
    tex:SetVertexColor((a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2, alpha)
end

-- Text --------------------------------------------------------------------

local function abbrev(n)
    if n >= 1e6 then return string.format("%.1fm", n / 1e6) end
    if n >= 1e4 then return string.format("%.1fk", n / 1e3) end
    return BreakUpLargeNumbers and BreakUpLargeNumbers(n) or tostring(n)
end

local function percent(cur, max) return string.format("%.1f%%", max > 0 and cur / max * 100 or 0) end

-- The line printed on the bar. d = currentData() (see its fields above);
-- short = true on a vertical bar, where there is little room across it.
-- Just the percent; the tooltip has the full numbers.
local function formatText(d, short)
    return percent(d.cur, d.max)
end

-- The bar -----------------------------------------------------------------

local holder = CreateFrame("Frame", "XPRailFrame", UIParent)
holder:SetFrameStrata("LOW")
holder:SetClampedToScreen(true)
holder:SetMovable(true)
holder:EnableMouse(true)
holder:RegisterForDrag("LeftButton")

local track = holder:CreateTexture(nil, "BACKGROUND", nil, 1)
track:SetAllPoints()
track:SetColorTexture(0.06, 0.06, 0.07, 0.85)

-- Two rings of edge: the inner one (black, or gold like the default unit frames)
-- and, for gold, a 1 px black line outside it.
local function makeRing(sub)
    local r = {}
    for i = 1, 4 do r[i] = holder:CreateTexture(nil, "BACKGROUND", nil, sub) end
    return r
end
local edges = makeRing(0)
local outline = makeRing(-1)
for _, t in ipairs(outline) do t:SetColorTexture(0, 0, 0, 1) end

-- Places a ring `size` thick, starting `gap` pixels outside the bar.
local function placeRing(ring, gap, size)
    local o = gap + size
    for _, t in ipairs(ring) do t:ClearAllPoints(); t:SetShown(size > 0) end
    if size <= 0 then return end
    ring[1]:SetPoint("BOTTOMLEFT", holder, "TOPLEFT", -o, gap); ring[1]:SetPoint("BOTTOMRIGHT", holder, "TOPRIGHT", o, gap); ring[1]:SetHeight(size)
    ring[2]:SetPoint("TOPLEFT", holder, "BOTTOMLEFT", -o, -gap); ring[2]:SetPoint("TOPRIGHT", holder, "BOTTOMRIGHT", o, -gap); ring[2]:SetHeight(size)
    ring[3]:SetPoint("TOPRIGHT", holder, "TOPLEFT", -gap, gap); ring[3]:SetPoint("BOTTOMRIGHT", holder, "BOTTOMLEFT", -gap, -gap); ring[3]:SetWidth(size)
    ring[4]:SetPoint("TOPLEFT", holder, "TOPRIGHT", gap, gap); ring[4]:SetPoint("BOTTOMLEFT", holder, "BOTTOMRIGHT", gap, -gap); ring[4]:SetWidth(size)
end

local GOLD_LIGHT = { 0.95, 0.80, 0.40 }
local GOLD_DARK  = { 0.55, 0.40, 0.12 }

local restedBar = CreateFrame("StatusBar", nil, holder)
restedBar:SetAllPoints()
restedBar:SetStatusBarTexture(SQUARE)

local questBar = CreateFrame("StatusBar", nil, holder)
questBar:SetAllPoints()
questBar:SetStatusBarTexture(SQUARE)
questBar:SetFrameLevel(restedBar:GetFrameLevel() + 1)

local bar = CreateFrame("StatusBar", nil, holder)
bar:SetAllPoints()
bar:SetStatusBarTexture(SQUARE)
bar:SetFrameLevel(questBar:GetFrameLevel() + 1)

local spark = bar:CreateTexture(nil, "OVERLAY")
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
spark:SetBlendMode("ADD")

-- Thin ticks every 10%, like the game's bar.
local ticks = {}
for i = 1, 9 do
    local t = bar:CreateTexture(nil, "OVERLAY", nil, -1)
    t:SetColorTexture(0, 0, 0, 0.35)
    ticks[i] = t
end

local textFrame = CreateFrame("Frame", nil, holder)
textFrame:SetAllPoints()
textFrame:SetFrameLevel(bar:GetFrameLevel() + 2)
local text = textFrame:CreateFontString(nil, "OVERLAY")
text:SetPoint("CENTER")

local mover = CreateFrame("Frame", nil, holder)
mover:SetAllPoints()
mover:SetFrameLevel(textFrame:GetFrameLevel() + 1)
local moverTex = mover:CreateTexture(nil, "OVERLAY")
moverTex:SetAllPoints()
moverTex:SetColorTexture(0.55, 0.90, 0.75, 0.35)
local moverText = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
moverText:SetPoint("CENTER")
moverText:SetText(L.dragMe)
mover:Hide()

local hovered = false
local data

local function updateText()
    local show = data and (db.text == "always" or (db.text == "hover" and hovered))
    text:SetShown(show and true or false)
    if show then text:SetText(formatText(data, db.orient == "vertical")) end
end

local function update()
    if not db then return end
    data = currentData()
    holder:SetShown(data ~= nil or not db.locked)
    if not data then return end

    local vert = db.orient == "vertical"
    local dir = vert and "VERTICAL" or "HORIZONTAL"
    local a, b = colorsFor(data)

    bar:SetMinMaxValues(0, data.max)
    bar:SetValue(data.cur)
    gradient(bar:GetStatusBarTexture(), dir, a, b)

    local showRested = db.rested and data.kind == "xp" and data.rested > 0
    restedBar:SetShown(showRested)
    if showRested then
        restedBar:SetMinMaxValues(0, data.max)
        restedBar:SetValue(math.min(data.max, data.cur + data.rested))
        local r = db.color == "default" and RESTED_COLOR or b
        restedBar:GetStatusBarTexture():SetVertexColor(r[1], r[2], r[3], 0.35)
    end

    -- Rested and quest XP both start at the fill's end; the shorter one goes on top
    -- so neither hides the other.
    local base = holder:GetFrameLevel()
    local restedOnTop = (data.rested or 0) < (data.quest or 0)
    restedBar:SetFrameLevel(base + (restedOnTop and 2 or 1))
    questBar:SetFrameLevel(base + (restedOnTop and 1 or 2))
    bar:SetFrameLevel(base + 3)
    textFrame:SetFrameLevel(base + 5)
    mover:SetFrameLevel(base + 6)

    local showQuest = db.quests and data.kind == "xp" and (data.quest or 0) > 0
    questBar:SetShown(showQuest)
    if showQuest then
        questBar:SetMinMaxValues(0, data.max)
        questBar:SetValue(math.min(data.max, data.cur + data.quest))
        questBar:GetStatusBarTexture():SetVertexColor(QUEST_COLOR[1], QUEST_COLOR[2], QUEST_COLOR[3], 0.55)
    end

    local frac = data.max > 0 and data.cur / data.max or 0
    spark:SetShown(db.spark and frac > 0 and frac < 1)
    if spark:IsShown() then
        spark:ClearAllPoints()
        if vert then
            spark:SetSize(db.thick * 2.2, db.thick * 0.9)
            spark:SetPoint("CENTER", bar, "BOTTOM", 0, frac * db.length)
            spark:SetRotation(math.pi / 2)
        else
            spark:SetSize(db.thick * 0.9, db.thick * 2.2)
            spark:SetPoint("CENTER", bar, "LEFT", frac * db.length, 0)
            spark:SetRotation(0)
        end
    end
    updateText()
end

local function layout()
    if not db then return end
    local vert = db.orient == "vertical"
    holder:SetSize(vert and db.thick or db.length, vert and db.length or db.thick)
    holder:ClearAllPoints()
    holder:SetPoint(db.point[1], UIParent, db.point[1], db.point[2], db.point[3])

    local o = vert and "VERTICAL" or "HORIZONTAL"
    bar:SetOrientation(o)
    restedBar:SetOrientation(o)
    questBar:SetOrientation(o)

    local e = db.border
    local gold = db.borderStyle == "gold"
    placeRing(edges, 0, e)
    placeRing(outline, e, (gold and e > 0) and 1 or 0)
    for i, t in ipairs(edges) do
        if gold then
            -- Lit from above, like the unit frames' gold rim.
            t:SetColorTexture(1, 1, 1, 1)
            local top = (i == 1) and GOLD_LIGHT or GOLD_DARK
            if i >= 3 then
                gradient(t, "VERTICAL", GOLD_DARK, GOLD_LIGHT)
            else
                t:SetVertexColor(top[1], top[2], top[3], 1)
            end
        else
            t:SetColorTexture(0, 0, 0, 1)
            t:SetVertexColor(1, 1, 1, 1)
        end
    end

    for i, t in ipairs(ticks) do
        t:ClearAllPoints()
        if vert then
            t:SetHeight(1); t:SetPoint("LEFT", bar, "BOTTOMLEFT", 0, db.length * i / 10); t:SetPoint("RIGHT", bar, "BOTTOMRIGHT", 0, db.length * i / 10)
        else
            t:SetWidth(1); t:SetPoint("TOP", bar, "TOPLEFT", db.length * i / 10, 0); t:SetPoint("BOTTOM", bar, "BOTTOMLEFT", db.length * i / 10, 0)
        end
    end

    text:SetFont(STANDARD_TEXT_FONT, db.textSize, "OUTLINE")
    mover:SetShown(not db.locked)
    update()
end

-- Dragging ----------------------------------------------------------------

holder:SetScript("OnDragStart", function(self)
    if not db.locked then self:StartMoving() end
end)
holder:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Saved against the nearest screen side, so it stays put when the UI scale changes.
    local cx, cy = self:GetCenter()
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    local s = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
    cx, cy = cx * s, cy * s
    local w, h = self:GetWidth() * s, self:GetHeight() * s
    local v = cy < sh / 3 and "BOTTOM" or (cy > sh * 2 / 3 and "TOP" or "")
    local hz = cx < sw / 3 and "LEFT" or (cx > sw * 2 / 3 and "RIGHT" or "")
    local p = (v .. hz ~= "") and (v .. hz) or "CENTER"
    local x = hz == "LEFT" and (cx - w / 2) or (hz == "RIGHT" and (cx + w / 2 - sw) or (cx - sw / 2))
    local y = v == "BOTTOM" and (cy - h / 2) or (v == "TOP" and (cy + h / 2 - sh) or (cy - sh / 2))
    db.point = { p, math.floor(x + 0.5), math.floor(y + 0.5) }
    layout()
end)

-- Tooltip -----------------------------------------------------------------

holder:SetScript("OnEnter", function(self)
    hovered = true
    updateText()
    if not data then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    local nums = string.format("%s / %s  (%s)", abbrev(data.cur), abbrev(data.max), percent(data.cur, data.max))
    if data.kind == "xp" then
        GameTooltip:AddLine(L.xp)
        GameTooltip:AddDoubleLine(data.label, nums, 1, 1, 1, 1, 1, 1)
        GameTooltip:AddLine(string.format(L.toLevel, abbrev(data.max - data.cur)), 0.8, 0.8, 0.8)
        if data.rested > 0 then
            GameTooltip:AddLine(string.format(L.rested, abbrev(data.rested), percent(data.rested, data.max)),
                RESTED_COLOR[1] + 0.3, RESTED_COLOR[2] + 0.3, RESTED_COLOR[3])
        end
        if (data.quest or 0) > 0 then
            GameTooltip:AddLine(string.format(L.questXP, abbrev(data.quest), percent(data.quest, data.max)),
                QUEST_COLOR[1], QUEST_COLOR[2], QUEST_COLOR[3])
        end
        local elapsed = GetTime() - session.start
        if session.gained > 0 and elapsed > 60 then
            local perHour = session.gained / elapsed * 3600
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format(L.perHour, abbrev(math.floor(perHour))), 0.8, 0.8, 0.8)
            local secs = (data.max - data.cur) / perHour * 3600
            local t = SecondsToTime and SecondsToTime(secs, true) or string.format("%d min", secs / 60)
            GameTooltip:AddLine(string.format(L.ttl, t), 0.8, 0.8, 0.8)
        end
    else
        GameTooltip:AddLine(data.label)
        local c = FACTION_BAR_COLORS and FACTION_BAR_COLORS[data.reaction] or { r = 1, g = 1, b = 1 }
        GameTooltip:AddDoubleLine(data.standing, nums, c.r, c.g, c.b, 1, 1, 1)
    end
    if db.mode == "auto" and data.kind == "xp" then
        local r = repData()
        if r then
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(r.label .. " (" .. r.standing .. ")", percent(r.cur, r.max), 0.8, 0.8, 0.8, 0.8, 0.8, 0.8)
        end
    end
    GameTooltip:AddLine(L.hint, 0.5, 0.5, 0.5)
    GameTooltip:Show()
end)
holder:SetScript("OnLeave", function()
    hovered = false
    updateText()
    GameTooltip:Hide()
end)

local togglePanel   -- below
holder:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" then togglePanel() end
end)

-- The game's bar ----------------------------------------------------------
-- Hidden the same way mUI does it: hide it, and hide it again whenever the game
-- shows it. Turning this off takes a /reload (the hook can't be removed).

local hooked = false
local function hideBlizzard()
    if not db.hideBlizz then return end
    for _, name in ipairs({ "StatusTrackingBarManager", "MainStatusTrackingBarContainer", "SecondaryStatusTrackingBarContainer" }) do
        local f = _G[name]
        if f and f.Hide then
            f:Hide()
            if not hooked then
                hooksecurefunc(f, "Show", function(self) if db.hideBlizz then self:Hide() end end)
            end
        end
    end
    hooked = true
end

-- Options -----------------------------------------------------------------
-- A dark, movable panel in the same look as Cooldown Skin's.

local UI_FILL = { 0.05, 0.05, 0.06 }
local UI_EDGE = { 0.30, 0.30, 0.33 }
local UI_ACCENT = { 0.55, 0.90, 0.75 }
local UI_W, UI_PAD = 340, 16
local UI_INNER = UI_W - 2 * UI_PAD

local function uiEdges(f, fill, alpha)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(fill[1], fill[2], fill[3], alpha or 1)
    for _, e in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" },
                         { "TOPLEFT", "BOTTOMLEFT", true }, { "TOPRIGHT", "BOTTOMRIGHT", true } }) do
        local t = f:CreateTexture(nil, "BORDER")
        t:SetPoint(e[1]); t:SetPoint(e[2])
        if e[3] then t:SetWidth(1) else t:SetHeight(1) end
        t:SetColorTexture(UI_EDGE[1], UI_EDGE[2], UI_EDGE[3], 1)
    end
end

local function uiButton(parent, label, w)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w or UI_INNER, 22)
    uiEdges(b, { 0.12, 0.12, 0.13 })
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(UI_ACCENT[1], UI_ACCENT[2], UI_ACCENT[3], 0.15)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.label:SetPoint("LEFT", 6, 0)
    b.label:SetPoint("RIGHT", -6, 0)
    b.label:SetWordWrap(false)
    b.label:SetJustifyH("CENTER")
    b.label:SetText(label)
    return b
end

local function px(v) return string.format("%d px", v) end
local function pct(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end

local function resetAll()
    XPRailDB = CopyTable(DEFAULTS)
    db = XPRailDB
    hideBlizzard()
    layout()
end

local panel
-- Two columns: layout, text and behavior on the left; colors on the right.
local function buildPanel()
    local f = CreateFrame("Frame", "XPRailOptions", UIParent)
    f:SetSize(UI_W * 2, 400)
    f:SetPoint("CENTER", 0, 60)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    uiEdges(f, UI_FILL, 0.95)

    local close = CreateFrame("Button", nil, f)
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", -8, -8)
    local x = close:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    x:SetPoint("CENTER")
    x:SetText("\195\151")
    x:SetTextColor(UI_ACCENT[1], UI_ACCENT[2], UI_ACCENT[3])
    close:SetScript("OnEnter", function() x:SetTextColor(1, 1, 1) end)
    close:SetScript("OnLeave", function() x:SetTextColor(UI_ACCENT[1], UI_ACCENT[2], UI_ACCENT[3]) end)
    close:SetScript("OnClick", function() f:Hide() end)

    local logo = f:CreateTexture(nil, "ARTWORK")
    logo:SetSize(32, 32)
    logo:SetPoint("TOPLEFT", UI_PAD, -UI_PAD)
    logo:SetTexture("Interface\\Icons\\INV_Misc_Book_11")
    logo:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, -1)
    title:SetText(L.title)
    title:SetTextColor(UI_ACCENT[1], UI_ACCENT[2], UI_ACCENT[3])
    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    sub:SetText(L.sub)

    local widgets = {}
    local function refreshWidgets() for _, w in ipairs(widgets) do w() end end
    f.Refresh = refreshWidgets

    local TOP = -(UI_PAD + 32 + 10)
    local cols = { { x = UI_PAD, y = TOP }, { x = UI_W + UI_PAD, y = TOP } }
    local col = cols[1]

    -- Thin divider between the columns.
    local div = f:CreateTexture(nil, "BORDER")
    div:SetWidth(1)
    div:SetColorTexture(UI_EDGE[1], UI_EDGE[2], UI_EDGE[3], 0.5)
    div:SetPoint("TOP", f, "TOPLEFT", UI_W, TOP - 4)
    div:SetPoint("BOTTOM", f, "BOTTOMLEFT", UI_W, UI_PAD + 30)

    local function head(label)
        col.y = col.y - 6
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", col.x, col.y)
        fs:SetText(label)
        local rule = f:CreateTexture(nil, "BORDER")
        rule:SetHeight(1)
        rule:SetColorTexture(UI_EDGE[1], UI_EDGE[2], UI_EDGE[3], 0.8)
        rule:SetPoint("LEFT", fs, "RIGHT", 8, 0)
        rule:SetPoint("RIGHT", f, "LEFT", col.x + UI_INNER, 0)
        col.y = col.y - 22
    end
    local function row(h)
        local r = CreateFrame("Frame", nil, f)
        r:SetSize(UI_INNER, h or 24)
        r:SetPoint("TOPLEFT", col.x, col.y)
        col.y = col.y - (h or 24) - 4
        return r
    end
    local function label(r, s)
        local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("LEFT")
        fs:SetText(s)
    end

    local function check(s, key, after)
        local r = row()
        local c = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
        c:SetSize(24, 24)
        c:SetPoint("LEFT", -3, 0)
        local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("LEFT", c, "RIGHT", 4, 0)
        fs:SetPoint("RIGHT")
        fs:SetJustifyH("LEFT")
        fs:SetText(s)
        c:SetScript("OnClick", function(self)
            db[key] = self:GetChecked() and true or false
            if after then after() end
            layout(); refreshWidgets()
        end)
        widgets[#widgets + 1] = function() c:SetChecked(db[key] and true or false) end
    end

    -- label ......... [-] value [+]   (shift-click: 5 steps)
    local function stepper(s, key, step, lo, hi, fmt)
        local r = row()
        label(r, s)
        local plus = uiButton(r, "+", 24)
        plus:SetPoint("RIGHT")
        local value = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        value:SetWidth(60)
        value:SetJustifyH("CENTER")
        value:SetPoint("RIGHT", plus, "LEFT", -4, 0)
        local minus = uiButton(r, "-", 24)
        minus:SetPoint("RIGHT", value, "LEFT", -4, 0)
        local function bump(d)
            if IsShiftKeyDown() then d = d * 5 end
            local v = math.floor((db[key] + d) / step + 0.5) * step
            db[key] = tonumber(string.format("%.2f", math.max(lo, math.min(hi, v))))
            layout(); refreshWidgets()
        end
        minus:SetScript("OnClick", function() bump(-step) end)
        plus:SetScript("OnClick", function() bump(step) end)
        widgets[#widgets + 1] = function() value:SetText(fmt(db[key])) end
    end

    -- label ......... [ a | b | c ]  (segmented choice, the chosen one lit)
    local function choice(s, key, list, names)
        local r = row()
        label(r, s)
        -- Buttons fill the row after a fixed label column, so they never cover the label.
        local LABEL_COL = 100
        local w = math.floor((UI_INNER - LABEL_COL - 2 * (#list - 1)) / #list)
        local btns = {}
        for i = #list, 1, -1 do
            local b = uiButton(r, names[list[i]], w)
            if i == #list then b:SetPoint("RIGHT") else b:SetPoint("RIGHT", btns[i + 1], "LEFT", -2, 0) end
            b:SetScript("OnClick", function() db[key] = list[i]; layout(); refreshWidgets() end)
            btns[i] = b
        end
        widgets[#widgets + 1] = function()
            for i, b in ipairs(btns) do
                if db[key] == list[i] then
                    b.label:SetTextColor(UI_ACCENT[1], UI_ACCENT[2], UI_ACCENT[3])
                else
                    b.label:SetTextColor(0.6, 0.6, 0.6)
                end
            end
        end
    end

    local function button(s, onClick)
        local b = uiButton(f, s)
        b:SetPoint("TOPLEFT", col.x, col.y)
        b:SetScript("OnClick", onClick)
        col.y = col.y - 30
    end

    -- Left column ----------------------------------------------------------
    head(L.secLayout)
    choice(L.orient, "orient", { "horizontal", "vertical" }, { horizontal = L.horizontal, vertical = L.vertical })
    stepper(L.length, "length", 20, 40, 2000, px)
    stepper(L.thick, "thick", 1, 2, 60, px)
    choice(L.borderStyle, "borderStyle", { "black", "gold" }, { black = L.black, gold = L.gold })
    stepper(L.border, "border", 1, 0, 4, px)
    check(L.locked, "locked")
    button(L.center, function() db.point = { db.point[1]:find("TOP") and "TOP" or "BOTTOM", 0, db.point[3] }; layout() end)

    head(L.secText)
    choice(L.text, "text", { "hover", "always", "off" }, { always = L.textAlways, hover = L.textHover, off = L.textOff })
    stepper(L.textSize, "textSize", 1, 6, 24, px)

    head(L.secBehave)
    choice(L.mode, "mode", { "auto", "xp", "rep" }, { auto = L.modeAutoShort, xp = L.xpShort, rep = L.repShort })
    check(L.hideBlizz, "hideBlizz", function()
        if db.hideBlizz then hideBlizzard() else say(L.reloadNote) end
    end)

    -- Right column ---------------------------------------------------------
    col = cols[2]
    head(L.secColors)

    -- Preview: the chosen colors as a little XP bar, with rested and quest XP.
    local pv = row(14)
    local pvBg = pv:CreateTexture(nil, "BACKGROUND")
    pvBg:SetAllPoints()
    pvBg:SetColorTexture(0.06, 0.06, 0.07, 1)
    local pvQuest = pv:CreateTexture(nil, "ARTWORK", nil, 1)
    pvQuest:SetPoint("TOPLEFT", pv, "TOPLEFT", UI_INNER * 0.62, 0)
    pvQuest:SetSize(UI_INNER * 0.14, 14)
    pvQuest:SetColorTexture(QUEST_COLOR[1], QUEST_COLOR[2], QUEST_COLOR[3], 0.55)
    local pvRested = pv:CreateTexture(nil, "ARTWORK", nil, 2)
    pvRested:SetPoint("TOPLEFT", pv, "TOPLEFT", UI_INNER * 0.62, 0)
    pvRested:SetSize(UI_INNER * 0.08, 14)
    pvRested:SetTexture(SQUARE)
    local pvFill = pv:CreateTexture(nil, "ARTWORK", nil, 3)
    pvFill:SetPoint("TOPLEFT")
    pvFill:SetSize(UI_INNER * 0.62, 14)
    pvFill:SetTexture(SQUARE)
    local pvName = pv:CreateFontString(nil, "OVERLAY")
    pvName:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    pvName:SetPoint("CENTER")
    widgets[#widgets + 1] = function()
        local a, b = colorsFor({ kind = "xp" })
        gradient(pvFill, "HORIZONTAL", a, b)
        local r = db.color == "default" and RESTED_COLOR or b
        pvRested:SetVertexColor(r[1], r[2], r[3], 0.35)
        pvRested:SetShown(db.rested)
        pvQuest:SetShown(db.quests)
        pvName:SetText(COLOR_NAMES[db.color] or db.color)
    end
    col.y = col.y - 4

    -- Swatches: one row per family; click to pick, hover for the name.
    local SW_W, SW_H, SW_GAP = 34, 16, 4
    local LABEL_W = UI_INNER - 6 * (SW_W + SW_GAP) + SW_GAP
    local swatches = {}
    for _, fam in ipairs(PALETTE_ROWS) do
        local r = row(SW_H + 2)
        local fl = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fl:SetPoint("LEFT")
        fl:SetWidth(LABEL_W - 4)
        fl:SetJustifyH("LEFT")
        fl:SetWordWrap(false)
        fl:SetText(fam.name)
        for i, key in ipairs(fam.list) do
            local s = CreateFrame("Button", nil, r)
            s:SetSize(SW_W, SW_H)
            s:SetPoint("LEFT", LABEL_W + (i - 1) * (SW_W + SW_GAP), 0)
            local ring = s:CreateTexture(nil, "BACKGROUND")
            ring:SetPoint("TOPLEFT", -2, 2)
            ring:SetPoint("BOTTOMRIGHT", 2, -2)
            ring:SetColorTexture(1, 1, 1, 1)
            local edge = s:CreateTexture(nil, "BORDER")
            edge:SetAllPoints()
            edge:SetColorTexture(0, 0, 0, 1)
            local fill = s:CreateTexture(nil, "ARTWORK")
            fill:SetPoint("TOPLEFT", 1, -1)
            fill:SetPoint("BOTTOMRIGHT", -1, 1)
            fill:SetTexture(SQUARE)
            s:SetScript("OnClick", function() db.color = key; layout(); refreshWidgets() end)
            s:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(COLOR_NAMES[key] or key)
                GameTooltip:Show()
            end)
            s:SetScript("OnLeave", function() GameTooltip:Hide() end)
            swatches[#swatches + 1] = { key = key, ring = ring, fill = fill }
        end
    end
    widgets[#widgets + 1] = function()
        local keep = db.color
        for _, sw in ipairs(swatches) do
            db.color = sw.key                     -- colorsFor reads db.color
            local a, b = colorsFor({ kind = "xp" })
            gradient(sw.fill, "HORIZONTAL", a, b)
            sw.ring:SetShown(sw.key == keep)
        end
        db.color = keep
    end
    col.y = col.y - 4

    stepper(L.bright, "bright", 0.05, 0.3, 1, pct)
    check(L.repStanding, "repStanding")
    check(L.restedShow, "rested")
    check(L.questShow, "quests")
    check(L.spark, "spark")

    -- Bottom: reset, under the taller column.
    local y = math.min(cols[1].y, cols[2].y) - 6
    local reset = uiButton(f, L.reset, 200)
    reset:SetPoint("TOPLEFT", UI_PAD, y)
    reset:SetScript("OnClick", function() resetAll(); refreshWidgets() end)
    y = y - 22

    f:SetHeight(-y + UI_PAD)
    f:SetScript("OnShow", refreshWidgets)
    if UISpecialFrames then table.insert(UISpecialFrames, f:GetName()) end
    f:Hide()
    return f
end

togglePanel = function()
    panel = panel or buildPanel()
    panel:SetShown(not panel:IsShown())
end

function XPRail_OnCompartmentClick() togglePanel() end

local function registerSettings()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
    local c = CreateFrame("Frame")
    local t = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 16, -16)
    t:SetText(L.title)
    local s = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    s:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
    s:SetText(L.openNote)
    local b = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
    b:SetSize(200, 24)
    b:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, -12)
    b:SetText(L.openBtn)
    b:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then HideUIPanel(SettingsPanel) end
        panel = panel or buildPanel()
        panel:Show()
    end)
    pcall(function() Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(c, L.title)) end)
end

SLASH_XPRAIL1 = "/xprail"
SLASH_XPRAIL2 = "/xpr"
SlashCmdList.XPRAIL = function(msg)
    local cmd = strtrim(msg or ""):lower()
    if cmd == "unlock" or cmd == "lock" then
        db.locked = (cmd == "lock")
        layout()
    elseif cmd == "reset" then
        resetAll()
        say(L.reset)
    else
        togglePanel()
    end
    if panel and panel:IsShown() then panel.Refresh() end
end

-- Startup -----------------------------------------------------------------

local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP",
                     "UPDATE_EXHAUSTION", "UPDATE_FACTION", "QUEST_LOG_UPDATE", "ENABLE_XP_GAIN", "DISABLE_XP_GAIN", "UI_SCALE_CHANGED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, arg)
    if event == "ADDON_LOADED" then
        if arg ~= ADDON then return end
        XPRailDB = XPRailDB or {}
        db = XPRailDB
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then db[k] = type(v) == "table" and CopyTable(v) or v end
        end
        registerSettings()
        layout()
    elseif not db then
        return
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UI_SCALE_CHANGED" then
        hideBlizzard()
        trackXP()
        scanQuests()
        layout()
    elseif event == "QUEST_LOG_UPDATE" then
        scanQuests()
        update()
    else
        if event == "PLAYER_XP_UPDATE" then trackXP() end
        -- PLAYER_LEVEL_UP fires before UnitXPMax changes; look again a moment later.
        if event == "PLAYER_LEVEL_UP" then C_Timer.After(0.5, update) end
        update()
    end
end)
