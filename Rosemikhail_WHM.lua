---@diagnostic disable: lowercase-global, undefined-global
include("Modes.lua")

----------------------------------------------------------------
-- NOTES
----------------------------------------------------------------

-- TODO:
-- fast cast
-- macros

-- LONG TERM STUFF
-- Think about Enfeebling when I have the AF set sorted.
-- Apparently whm can also use impact, consider someday.
-- Divine Magic skill - then Repose/Flash/Holy/Banish.
-- Figure out melee stuff.
-- Consider splitting raise/cleanse spells into separate sets for purposes of recast, etc...
    -- Could easily do this via debuff_cleansers and match_list

-- Consider setting stuff up for Afflatus Misery like Cura, macros, etc...

-- No, I don't really care about helixes or elemental buttons
-- Maybe I can set up some nuking sets for stuff like Banish and Holy? Lmao?

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------

-- Modes and toggles
weapon_mode = M{"Daybreak"}
engaged_mode = M{}
idle_mode = M{"Normal"}

toggle_speed = "Off"
weapon_lock = "Off"

-- Midcast helpers
match_list = S{"Cure", "Curaga", "Regen"} -- Maybe add Aspir and Drain here if I use BLM sub. Maybe also add Cura and whatever other spells, but for now, yolo
debuff_cleansers = S{"Stona", "Poisona", "Silena", "Viruna", "Paralyna", "Blindna", "Cursna", "Erase", "Esuna", "Sacrifice"}
elemental_barspells = S{"Barfire", "Barblizzard", "Baraero", "Barstone", "Barthunder", "Barwater", "Barfira", "Barblizzara", "Baraera", "Barstonra", "Barthundra", "Barwatera",}
status_barspells = S{"Baramnesia","Barvirus", "Barparalyze", "Barsilence", "Barpetrify", "Barpoison", "Barblind", "Barsleep", "Baramnesra","Barvira", "Barparalyzra", "Barsilencera", "Barpetra", "Barpoisonra", "Barblindra", "Barsleepra"}
ignored_spell_types = S{"Samba", "Waltz", "Jig", "Step", "Flourish1", "Flourish2", "Scholar"}

-- Bindings
send_command("bind f5 gs c weaponmode")
send_command("bind f6 gs c engagedmode")
send_command("bind f7 gs c idlemode")
send_command("bind f8 gs c lockweapon")

send_command("bind f9 gs c togglespeed")
send_command("bind f12 gs c toggletextbox")

-- Help Text
add_to_chat(123, "F5: Cycle weapon mode, F6: Cycle engaged mode")
add_to_chat(123, "F7: Cycle idle mode, F8: Lock weapon")
add_to_chat(123, "F9: Toggle speed gear")
add_to_chat(123, "F12: Hide information text box")

----------------------------------------------------------------
-- INFORMATION BOX & OTHER FUNCTIONS
----------------------------------------------------------------

default_settings = {
  bg = { alpha = 0 },
  pos = { x = -35, y = -2 },
  flags = { draggable = false, right = true },
  text = { font = "Arial", size = 11, stroke = { width = 1}},
}

text_box = texts.new(default_settings)
text_box:visible(true)

function build_info_box()
    local function format_toggle(toggle)
        return toggle == "On" and "\\cs(0,255,0)On\\cr" or "\\cs(255,0,0)Off\\cr"
    end

    local output = string.format(
        "[F5] Weapon: %s [F6] Engaged: %s [F7] Idle: %s [F8] Weapon Lock: %s [F9] Speed: %s",
        weapon_mode.current,
        engaged_mode.current,
        idle_mode.current,
        format_toggle(weapon_lock),
        format_toggle(toggle_speed)
    )

    text_box:text(output)
end

-- We wait until inside get_sets() to build the info box initially, as that is where some weapon set logic is being handled.

function update_engaged_modes(weapon_sets)
    -- Get the sets (i.e. Idle, TP, etc.) from the currently active weapon mode
    local weapon = weapon_sets[weapon_mode.current]
    local weapon_engaged_sets = {}
    
    -- If the weapon has engaged sets associated with it, then use those.
    -- Otherwise, insert our own and assume that we want a non-engaged and a default TP toggle.
    if #weapon.engaged_sets > 0 then
        weapon_engaged_sets = weapon.engaged_sets
    else
        weapon_engaged_sets = {"Idle", "TP"}
    end

    add_to_chat(123, string.format("The current weapon has %s engaged sets associated with it.", #weapon.engaged_sets))
    engaged_mode = M{table.unpack(weapon_engaged_sets)}
end

----------------------------------------------------------------
-- MISC INIT/COMMANDS
----------------------------------------------------------------

-- Lockstyle
function update_lockstyle()
    send_command("wait 5;input /lockstyleset 12") -- WHM Empy
end

function update_macro_book()
    -- WHM macro book
    send_command("input /macro book 6;input /macro set 1")
end

update_lockstyle()
update_macro_book()

-- Individual spells should be added in the following way: sets.precast["Impact"]. This goes for precast and midcast.
function get_sets()
    ----------------------------------------------------------------
    -- WEAPON SETS
    ----------------------------------------------------------------

    weapon_sets = {
        ["Daybreak"] = {
            gear = {
                main="Daybreak",
                sub="Genmei Shield",
            },
            engaged_sets = {}, -- Use the default
            overrides = {},
        },
    }

    update_engaged_modes(weapon_sets)
    build_info_box()

    ----------------------------------------------------------------
    -- GEAR PLACEHOLDERS
    ----------------------------------------------------------------
    
    jse = {}                       -- Leave this empty
    jse.AF = {}                    -- Leave this empty
    jse.relic = {}                 -- Leave this empty
    jse.empyrean = {}              -- Leave this empty
    jse.capes = {}                 -- Leave this empty

    jse.AF = {
        head="",
        body="",
        hands="",
        legs="Theophany Pantaloons +3", -- Regen duration, Cursna
        feet="",
    }

    jse.relic = {
        head="Piety Cap",               -- Devotion
        body="Piety Bliaut",            -- Benediction, Regen
        hands="Piety Mitts",            -- whatever check later
        legs="Piety Pantaloons",        -- Elemental resistance spells
        feet="Piety Duckbills",         -- whatever check later
    }

    -- Set bonus is elemental resistance spells
    jse.empyrean = {
        head="Ebers Cap +2",
        body="Ebers Bliaut +2",
        hands="Ebers Mitts +2",
        legs="Ebers Pantaloons +2",
        feet="Ebers Duckbills +2",      -- Auspice
    }

    jse.capes = {
        casting_idle = { name="Alaunus's Cape", augments={'MND+20','Mag. Acc+20 /Mag. Dmg.+20','MND+10','Enmity-10','Damage taken-5%',}},
    }

    ----------------------------------------------------------------
    -- GEAR SETS
    ----------------------------------------------------------------
    
    sets = {}
    sets.idle = {}                  -- Leave this empty
    sets.precast = {}               -- Leave this empty
    sets.midcast = {}               -- Leave this empty
    sets.ja = {}                    -- Leave this empty
    sets.ws = {}                    -- Leave this empty
    sets.engaged = {}               -- Leave this empty
    sets.buff = {}                  -- Leave this empty

    ----------------------------------------------------------------
    -- IDLE MODES
    ----------------------------------------------------------------

    -- Consider changing this when I get stikini rings for refresh.
    -- I can use Malignance pole for an easy -20% DT
    -- Re-evaluate when I have +3 empyrean
    -- Probably want a max evasion and a max refresh set too

    sets.idle["Normal"] = {                         -- OVERALL -54% DT, -0% PDT, -3% MDT (-54% DT+PDT, -57% DT+MDT), 7 Refresh, 4 Regen
        ammo="Homiliary",                           -- 1 Refresh
        head="Nyame Helm",                          -- -7% DT
        body=jse.empyrean.body,                     -- 4 Regen, 3 Refresh
        hands=jse.empyrean.hands,                   -- -10% DT
        legs="Assid. Pants +1",                     -- 2 Refresh
        feet="Nyame Sollerets",                     -- -7% DT
        neck="Warder's Charm +1",
        waist="Fucho-no-Obi",                       -- 1 Refresh
        left_ear="Alabaster Earring",               -- -5% DT
        right_ear="Etiolation Earring",             -- -3% MDT
        left_ring="Murky Ring",                     -- -10% DT
        right_ring="Defending Ring",                -- -10% DT
        back=jse.capes.casting_idle,                -- -5% DT
    }

    ----------------------------------------------------------------
    -- ENGAGED
    ----------------------------------------------------------------
    
    sets.engaged["TP"] = {
        ammo="Amar Cluster",
        head="Null Masque",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Cessance Earring",
        right_ear="Odnowa Earring +1",
        left_ring="Petrov Ring",
        right_ring="Lehko's Ring",
        back="Null Shawl",
    }

    ----------------------------------------------------------------
    -- PRECAST
    ----------------------------------------------------------------

    sets.precast.fast_cast = {                                                                                                          -- OVERALL 65% FC, 7 Cure FC, 14 Healing FC, 2% Occ (Effectively capped for healing/cures)
        main="C. Palug Hammer",                                                                                                         -- 7 FC
        sub="Chanter's Shield",                                                                                                         -- 3 FC
        ammo="Impatiens",                                                                                                               -- 2% Occ
        head=jse.empyrean.head,                                                                                                         -- 10 FC
        body="Inyanga Jubbah +2",                                                                                                       -- 14 FC
        hands={ name="Vanya Cuffs", augments={'Healing magic skill +20','"Cure" spellcasting time -7%','Magic dmg. taken -3',}},        -- 7 Cure FC
        legs=jse.empyrean.legs,                                                                                                         -- 14 Healing FC, -na FC, -na enmity
        feet="Nyame Sollerets",                                                                                                         -- Yolo gear
        neck="Voltsurge Torque",                                                                                                        -- 4% FC
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                                     -- 5% FC
        left_ear="Malignance Earring",                                                                                                  -- 4% FC
        right_ear="Loquacious Earring",                                                                                                 -- 2% FC
        left_ring="Kishar Ring",                                                                                                        -- 4% FC
        right_ring="Prolix Ring",                                                                                                       -- 2% FC
        back="Fi Follet Cape +1",                                                                                                       -- 10% FC
    }

    sets.precast["Dispelga"] = set_combine(sets.precast.fast_cast, {
        main="Daybreak",
        sub="Genmei Shield",
    })

    ----------------------------------------------------------------
    -- ENFEEBLING MIDCAST
    ----------------------------------------------------------------
    
    sets.midcast["Dispelga"] = set_combine(sets.idle["Normal"], {
        main="Daybreak",
        sub="Ammurapi Shield",
    })

    ----------------------------------------------------------------
    -- ENHANCING MIDCAST
    ----------------------------------------------------------------
    
    -- TODO: When I'm mastered, reevaluate the pieces here.
    -- Consider DT pieces instead of skill
    sets.midcast["Enhancing Magic"] = {                                                                                             -- +75% duration, -- CHECK ENHANCING SKILL
        main={ name="Gada", augments={'Enh. Mag. eff. dur. +6',}},                                                                  -- +6% duration
        sub="Ammurapi Shield",                                                                                                      -- +10% duration
        range=empty,
        ammo="Pemphredo Tathlum",
        head={ name="Telchine Cap", augments={'Enh. Mag. eff. dur. +10',}},                                                         -- +10% duration
        body={ name="Telchine Chas.", augments={'Pet: "Regen"+3','Enh. Mag. eff. dur. +10',}},                                      -- +10% duration
        hands={ name="Telchine Gloves", augments={'Pet: "Regen"+3','Enh. Mag. eff. dur. +10',}},                                    -- +10% duration.
        legs={ name="Telchine Braconi", augments={'Enh. Mag. eff. dur. +9',}},                                                      -- +9% duration
        feet={ name="Telchine Pigaches", augments={'Enh. Mag. eff. dur. +10',}},                                                    -- +10% duration
        neck="Incanter's Torque",                                                                                                   -- Skill
        waist="Embla Sash",                                                                                                         -- +10% duration
        left_ear="Andoaa Earring",
        right_ear="Mimir Earring",                                                                                                  -- Skill
        left_ring="Stikini Ring",                                                                                                   -- Skill
        right_ring="Stikini Ring",                                                                                                  -- Skill
        back="Fi Follet Cape +1",                                                                                                   -- Skill
    }

    sets.midcast.elemental_barspell = set_combine(sets.midcast["Enhancing Magic"], {
        main="Beneficus",
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.relic.legs,
        feet=jse.empyrean.feet,
        left_ear="Andoaa Earring",
    })

    sets.midcast.status_barspell = set_combine(sets.idle["Normal"], {
        -- I guess at some point I could use the Sroda Necklace, wait wtf, its cheap! but there's none on the market!
        -- TODO: I could switch this over to a bunch of conserve gear
    })

    -- Not sure whether to go for duration or potency, but probably the latter
    sets.midcast["Regen"] = set_combine(sets.midcast["Enhancing Magic"], {
        main="Bolelabunga",                                                                                                         -- 10% potency
        head="Inyanga Tiara +2",                                                                                                    -- 14% potency
        body=jse.relic.body,                                                                                                        -- 28% potency
        hands=jse.empyrean.hands,                                                                                                   -- +24 duration
        legs=jse.AF.legs,                                                                                                           -- +24 duration
    })

    sets.midcast["Stoneskin"] = set_combine(sets.midcast["Enhancing Magic"], {
        legs="Shedir Seraweels",                                                                                                    -- +35 Stoneskin
        neck="Nodens Gorget",                                                                                                       -- +30 Stoneskin
    })

    sets.midcast["Aquaveil"] = set_combine(sets.midcast["Enhancing Magic"], {
        legs="Shedir Seraweels",                                                                                                    -- +1 Aquaveil
    })


    sets.midcast["Auspice"] = set_combine(sets.midcast["Enhancing Magic"], {
        feet=jse.empyrean.feet,
    })

    ----------------------------------------------------------------
    -- HEALING MIDCAST
    ----------------------------------------------------------------
    
    -- re-math all of the DT and stuff here because I lost the plot
    -- consider the use of conserve pieces like fi follet 

    -- Consider a max cure/curaga set for when I feel safe enough to use one.
    -- Is Naji's loop really worth a loss of enmity reduction and conserve MP offered by Mephitas?

    -- Additional attempt at a cure DT set
    sets.midcast["Cure"] = { -- -40% DT, -10% PDT (-50% PDT, -40% MDT), 60% Cure Potency (50% cap), 1% Cure Potency II, +27% Conserve MP, -41 Enmity, 18% SIRD
        main="Daybreak",                                                                                                                -- 30% Cure Potency
        sub="Genmei Shield",                                                                                                            -- -10% PDT
        ammo="Staunch Tathlum",                                                                                                         -- -2% DT, 10% SIRD 
        head={ name="Vanya Hood", augments={'MP+50','"Cure" potency +7%','Enmity-6',}},                                                 -- +17% Cure Potency, +6% Conserve MP, -6 Enmity
        body=jse.empyrean.body,                                                                                                         -- Solace cureskin
        hands=jse.empyrean.hands,                                                                                                       -- -10% DT, -11 Enmity
        legs=jse.empyrean.legs,                                                                                                         -- MP return
        feet={ name="Vanya Clogs", augments={'MP+50','"Cure" potency +7%','Enmity-6',}},                                                -- +12% Cure Potency, +6% Conserve MP, -6 Enmity
        neck="Loricate Torque +1",                                                                                                      -- -6% DT, 5% SIRD 
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                                     -- +15% Conserve MP
        left_ear="Alabaster Earring",                                                                                                   -- -5% DT
        right_ear= { name="Ebers Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+11','Mag. Acc.+11','Damage taken-3%',}},  -- -3% DT, -8 Enmity
        left_ring="Murky Ring",                                                                                                         -- -10% DT, 3% SIRD
        right_ring="Naji's Loop",                                                                                                       -- +1% Cure Potency II
        back=jse.capes.casting_idle,                                                                                                    -- -5% DT, -10 enmity, Solace cureskin
    }

    -- Additional attempt at a curaga DT set
    sets.midcast["Curaga"] = { -- -49% DT, -10% PDT (-59% PDT, -49% MDT), 60% Cure Potency (50% cap), 1% Cure Potency II, +27% Conserve MP, -41 Enmity, 18% SIRD
        main="Daybreak",                                                                                                                -- 30% Cure Potency
        sub="Genmei Shield",                                                                                                            -- -10% PDT
        ammo="Staunch Tathlum",                                                                                                         -- -2% DT, 10% SIRD 
        head={ name="Vanya Hood", augments={'MP+50','"Cure" potency +7%','Enmity-6',}},                                                 -- +17% Cure Potency, +6% Conserve MP, -6 Enmity
        body="Nyame Mail",                                                                                                              -- -9% DT
        hands=jse.empyrean.hands,                                                                                                       -- -10% DT, -11 Enmity
        legs=jse.empyrean.legs,                                                                                                         -- MP return
        feet={ name="Vanya Clogs", augments={'MP+50','"Cure" potency +7%','Enmity-6',}},                                                -- +12% Cure Potency, +6% Conserve MP, -6 Enmity
        neck="Loricate Torque +1",                                                                                                      -- -6% DT, 5% SIRD 
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                                     -- +15% Conserve MP
        left_ear="Alabaster Earring",                                                                                                   -- -5% DT
        right_ear= { name="Ebers Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+11','Mag. Acc.+11','Damage taken-3%',}},  -- -3% DT, -8 Enmity
        left_ring="Murky Ring",                                                                                                         -- -10% DT, 3% SIRD
        right_ring="Naji's Loop",                                                                                                       -- +1% Cure Potency II
        back=jse.capes.casting_idle,                                                                                                    -- -5% DT, -10 enmity
    }

    -- This will apply to any non-cure healing magic, like debuff cleanses, unless they have their own set
    sets.midcast["Healing Magic"] = { -- -50% DT, +32% Conserve MP, 33% SIRD, FC +18%
        main="Daybreak",                                                                                                            -- Filler
        sub="Culminus",                                                                                                             -- 10% SIRD 
        ammo="Staunch Tathlum",                                                                                                     -- -2% DT, 10% SIRD 
        head=jse.empyrean.head,                                                                                                     -- Chance to AOE debuff cleanse (Divine Veil)
        body="Nyame Mail",                                                                                                          -- -9% DT
        hands={ name="Vanya Cuffs", augments={'Healing magic skill +20','"Cure" spellcasting time -7%','Magic dmg. taken -3',}},    -- 7 Cure FC
        legs=jse.empyrean.legs,                                                                                                     -- -12% DT, -na fc, -na enmity
        feet="Nyame Sollerets",                                                                                                     -- -7% DT
        neck="Loricate Torque +1",                                                                                                  -- -6% DT, 5% SIRD 
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                                 -- +15% Conserve MP
        left_ear="Alabaster Earring",                                                                                               -- -5% DT
        right_ear="Etiolation Earring",                                                                                             -- Resist silence
        left_ring="Murky Ring",                                                                                                     -- -10% DT, 3% SIRD
        right_ring="Mephitas's Ring +1",                                                                                            -- -3-7 Enmity TODO: Needs augment for conserve MP
        back="Fi Follet Cape +1",                                                                                                   -- +5% Conserve MP, 5% SIRD, 10 FC
    }

    -- Technically this is "enhancing magic", for some godforsaken reason, so we'll just copy Healing Magic for Erase
    sets.midcast["Erase"] = sets.midcast["Healing Magic"]

     -- TODO: More healing skill - can get more Vanya
    sets.midcast["Cursna"] = set_combine(sets.idle["Normal"], {
        main={ name="Gada", augments={'Indi. eff. dur. +10','Mag. Acc.+13','"Mag.Atk.Bns."+13','DMG:+10',}},                            -- Healing skill
        sub="Genmei Shield",
        --ammo=,
        head={ name="Vanya Hood", augments={'MP+50','"Cure" potency +7%','Enmity-6',}}, -- Replace with healing skill
        body=jse.empyrean.body,                                                                                                         -- Healing skill
        --hands=,
        legs=jse.AF.legs,                                                                                                               -- Cursna +21%
        feet={ name="Vanya Clogs", augments={'MP+50','"Cure" potency +7%','Enmity-6',}},                                                -- Cursna +5%
        neck="Debilis Medallion",                                                                                                       -- Cursna +15%
        waist="Bishop's Sash",                                                                                                          -- Healing skill
        left_ear="Meili Earring",
        right_ear={ name="Ebers Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+11','Mag. Acc.+11','Damage taken-3%',}},   -- Healing skill
        left_ring="Stikini Ring",
        right_ring="Haoma's Ring",                                                                                                      -- Cursna +15%
        back=jse.capes.casting_idle,                                                                                                    -- Cursna +25%
    })

    ----------------------------------------------------------------
    -- OTHER MIDCAST
    ----------------------------------------------------------------
    
    -- Someday

    ----------------------------------------------------------------
    -- JOB ABILITIES 
    ----------------------------------------------------------------
    
    sets.ja["Devotion"] = {
        head=jse.relic.head,
    }

    sets.ja["Benediction"] = {
        body=jse.relic.body,
    }

    sets.ja["Martyr"] = {
        hands=jse.relic.hands,
    }

    ----------------------------------------------------------------
    -- WEAPONSKILLS 
    ----------------------------------------------------------------
    
    sets.ws.default = {
        ammo="Amar Cluster",
        head="Nyame Helm",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Grunfeld Rope",
        left_ear="Odnowa Earring +1",
        right_ear="Moonshade Earring",
        left_ring="Murky Ring",
        right_ring="Defending Ring",
        back="Alabaster Mantle",
    }

    -- Probably want sets for Flash Nova and Seraph Strike, maybe Realmrazer
    -- Maybe Black Halo? Cataclysm?

    ----------------------------------------------------------------
    -- BUFF 
    ----------------------------------------------------------------
    
    sets.buff.sublimation = {
        waist="Embla Sash",                                                                                                             -- Sublimation +3
    }

end
----------------------------------------------------------------
-- HELPER FUNCTIONS 
----------------------------------------------------------------

function equip_current_weapon()
    local current_weapon = weapon_sets[weapon_mode.current]
    local engaged_override = current_weapon.overrides[engaged_mode.current]

    -- First check if the weapon has any engaged_mode specific permutation
    -- Otherwise, we'll just use the default gear
    if engaged_override then
        equip(engaged_override)
    else
        equip(current_weapon.gear)
    end
end

function equip_set_and_weapon(set)
    equip(set)

    -- This will only add the current weapon set to sets that have neither a main weapon or a sub (like a shield)
    if not set.main and not set.sub then
        equip_current_weapon()
    end
end

function idle()
    -- Choose between engaged set and regular idle
    if player.status == "Engaged" then
        if engaged_mode.current == "Idle" then
            equip_set_and_weapon(sets.idle[idle_mode.current])

            if buffactive["Sublimation: Activated"] then
                equip(sets.buff.sublimation)
            end
        else
            equip_set_and_weapon(sets.engaged[engaged_mode.current])
        end
    else
        equip_set_and_weapon(sets.idle[idle_mode.current])

        if buffactive["Sublimation: Activated"] then
            equip(sets.buff.sublimation)
        end
    end

    -- Speed overlay
    if toggle_speed == "On" then
        equip({right_ring="Shneddick Ring",})
    end
end

function handle_toggle(toggle, label)
    local result = (toggle == "On") and "Off" or "On"
    add_to_chat(123, string.format("%s toggle: %s", label, result))
    return result
end

----------------------------------------------------------------
-- GEARSWAP FUNCTIONS
----------------------------------------------------------------

function precast(spell)
    if toggle_speed == "On" then
        add_to_chat(123, "Consider disabling the speed toggle!")
    end

    -- Somewhat redundant, but leftover from BLM's other paths
    local function equip_if_ja_match(spell_name)
        if sets.ja[spell_name] then
            equip_set_and_weapon(sets.ja[spell_name])
            return true
        end
        return false
    end

    -- If the job ability name matches.
    if equip_if_ja_match(spell.name) then
        return
    end

    -- If the weapon skill name matches.
    if sets.ws[spell.name] then
        equip_set_and_weapon(sets.ws[spell.name])

        -- Hachirin-no-Obi overlay. Do not apply this to Myrkr.
        if S{world.weather_element, world.day_element}:contains(spell.element) and spell.element ~= "None" and spell.name ~= "Myrkr" then
            equip({waist="Hachirin-no-Obi"})
        end

        return
    end

    -- Handling for both matched and unmatched magic spells
    if spell.action_type == "Magic" then
        if sets.precast[spell.name] then
            -- If the spell name matches.
            equip_set_and_weapon(sets.precast[spell.name])
        else
            -- General purpose
            equip_set_and_weapon(sets.precast.fast_cast)
        end

        return
    end

    -- Unhandled Job Abilities
    if spell.type == "JobAbility" or spell.type == "Scholar" then
        -- Stay in idle.
        return
    end

    -- Unhandled Weapon Skills
    if spell.action_type == "Ability" then
        equip_set_and_weapon(sets.ws.default)
        return
    end
end

-- spell.action_type == "Magic" ensures that job ability gear survives into midcast, as otherwise they won't work.
function midcast(spell)
    if spell.action_type == "Magic" then
        local matched = false

        -- If the spell matches one of the match_list spells.
        for match in match_list:it() do
            if spell.name:match(match) then
                equip_set_and_weapon(sets.midcast[match])
                matched = true
                break
            end
        end

        -- If the spell name EXACTLY matches
        if not matched and sets.midcast[spell.name] then
            equip_set_and_weapon(sets.midcast[spell.name])
            matched = true
        end

        -- If the spell is a barspell
        if not matched and spell.name:match("^Bar") then
            if elemental_barspells:contains(spell.name) then
                equip_set_and_weapon(sets.midcast.elemental_barspell)
            elseif status_barspells:contains(spell.name) then
                equip_set_and_weapon(sets.midcast.status_barspell)
            end
            matched = true
        end

        -- Missing logic for nuking, but this can be added later. i.e. Holy and Banish

        -- Missing logic for Enfeebling, but this can be added later.

        -- If the spell skill has a relevant set
        if not matched and sets.midcast[spell.skill] then
            equip_set_and_weapon(sets.midcast[spell.skill])
            matched = true
        end

        -- Any other spell (trusts?)
        if not matched then
            idle()
        end

        -- Weather and day overlays
        -- Technically I could also do Divine for Banish but also lmao
        local valid_obi_skill = S{"Elemental Magic", "Dark Magic"}:contains(spell.skill)
        local is_cure = spell.name:match("Cure") or spell.name:match("Curaga")
        local element_matches_day_or_weather = S{world.weather_element, world.day_element}:contains(spell.element)
        local element_matches_weather = world.weather_element == spell.element

        if (valid_obi_skill or is_cure) and element_matches_day_or_weather and spell.element ~= "None" then
            equip({waist="Hachirin-no-Obi"})
        end

        if is_cure and element_matches_weather then
            equip({main="Chatoyant Staff", sub="Khonsu",})
        end

        local valid_divine_caress_debuff = spell.name ~= "Esuna" and spell.name ~= "Erase" and spell.name ~= "Sacrifice"
        if buffactive["Divine Caress"] and debuff_cleansers:contains(spell.name) and valid_divine_caress_debuff then
            equip({hands=jse.empyrean.hands, back="Mending Cape"})
        end
    end
end

function aftercast(spell)
    idle()
end

function buff_change(name, gain, buff_details)
    if not midaction() and name == "Sublimation: Activated" then
        idle()
    end

    if name == "Sublimation: Complete" and gain == true then
        add_to_chat(200, "Sublimation complete.")

        if not midaction() then
            idle()
        end
    end
end

function status_change(new, old)
    idle()
end

function sub_job_change(new,old)
    update_lockstyle()
    update_macro_book()
end

function self_command(command)
    -- Lowercase and split
    local commandArgs = T(command:lower():split(" "))
    local main_command = commandArgs[1]
    local sub_command = commandArgs[2]

    if main_command == "weaponmode" then
        weapon_mode:cycle()
        add_to_chat(123, string.format("Weapon mode set to %s", weapon_mode.current))
        update_engaged_modes(weapon_sets)
        idle()
    
    elseif main_command == "engagedmode" then
        engaged_mode:cycle()
        add_to_chat(123, string.format("Engaged mode set to %s", engaged_mode.current))
        idle()

    elseif main_command == "idlemode" then
        idle_mode:cycle()
        add_to_chat(123, string.format("Idle mode set to %s", idle_mode.current))
        idle()

    elseif main_command == "lockweapon" then
        weapon_lock = handle_toggle(weapon_lock, "Weapon Lock")

        idle()

        if weapon_lock == "On" then
            equip_current_weapon()
            send_command("gs disable main;gs disable sub;gs disable range")
        else
            send_command("gs enable main;gs enable sub;gs enable range")
        end

    elseif main_command == "togglespeed" then
        toggle_speed = handle_toggle(toggle_speed, "Speed")
        idle()

    elseif main_command == "toggletextbox" then
        text_box:visible(not text_box:visible())

    else
        add_to_chat(123, "Command not recognised.")
    end

    build_info_box()
end

function file_unload(file_name)
    send_command("unbind f5")
    send_command("unbind f6")
    send_command("unbind f7")
    send_command("unbind f8")

    send_command("unbind f9")
    send_command("unbind f12")
end