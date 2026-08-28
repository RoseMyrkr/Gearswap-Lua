---@diagnostic disable: lowercase-global, undefined-global
include("Modes.lua")

----------------------------------------------------------------
-- NOTES
----------------------------------------------------------------

--[[
Potential enhancements:
- Save certain toggles and sets between reloads
- Potentially make an override to force the PDT idle set regardless of whether I have a bubble out.
- Steal Aquaveil stuff from SCH
- Doomed set
- Notification in chat when I'm slept or doomed
- Potentially build a straight up DT/meva set. Probably have Normal as a hybrid, a DT/meva set, and a refresh set.
- Something that checks the direction of the player in relation to the enemy to tell them what buff they'd have against it
- Might be worth having a Gishdubar check on Refresh as it can give bonus refresh on self

- Update this to work with WHM stuff + set up GEO WHM macros
    - Update healing etc sets; they are not complete

- Consider a separate Aspir burst set

- Update barspell logic to care about the fact that elemental and status barspells have different resistance calculations
    - i.e. status ones have a base potency, so I could just cast in conserve or idle
    - Steal from WHM
]]

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------

-- Modes
nuking_mode = M{"Free Nuke", "Burst"}
idle_mode = M{"Normal", "Refresh"}
weapon_mode = M{"Wizard's Rod", "Daybreak", "Idris", "Maxentius"}

toggle_speed = "Off"
toggle_tp = "Off" -- This will disable weapon swapping as well

-- Midcast helpers
match_list  = S{"Cure", "Curaga", "Aspir", "Drain", "Regen"}
ignored_spell_types = S{"Samba", "Waltz", "Jig", "Step", "Flourish1", "Flourish2", "Scholar"}

-- Bindings
send_command("bind f1 gs c nukemode freenuke")
send_command("bind f2 gs c nukemode burst")

send_command("bind f5 gs c weaponmode")
send_command("bind f6 gs c idlemode")
send_command("bind f7 gs c toggletp")

send_command("bind f9 gs c togglespeed")
send_command("bind f12 gs c toggletextbox")

-- Help Text
add_to_chat(123, "F1-F2: Switch nuking mode")
add_to_chat(123, "F5: Switch weapon set, F6: Cycle idle mode")
add_to_chat(123, "F7: Toggle TP lock")
add_to_chat(123, "F9: Toggle speed gear")
add_to_chat(123, "F12: Hide information text box")

----------------------------------------------------------------
-- INFORMATION BOX
----------------------------------------------------------------

default_settings = {
  bg = { alpha = 0 },
  pos = { x = -32, y = -2 },
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
        "[F1-2] Nuking Mode: %s [F5] Wep: %s [F6] Idle: %s [F7] TP Lock: %s [F9] Speed: %s",
        nuking_mode.current,
        weapon_mode.current,
        idle_mode.current,
        format_toggle(toggle_tp),
        format_toggle(toggle_speed)
    )

    text_box:text(output)
end

build_info_box()

----------------------------------------------------------------
-- MISC INIT/COMMANDS
----------------------------------------------------------------

-- Lockstyle
function update_lockstyle()
    send_command("wait 5;input /lockstyleset 5") -- Geomancer Relic
end

function update_macro_book()
    -- GEO/RDM macro book
    send_command("input /macro book 2;input /macro set 1")
end

update_lockstyle()
update_macro_book()

-- Individual spells should be added in the following way: sets.precast["Impact"]. This goes for precast and midcast.
function get_sets()
    ----------------------------------------------------------------
    -- GEAR PLACEHOLDERS
    ----------------------------------------------------------------
    jse = {}                       -- Leave this empty
    jse.AF = {}                    -- Leave this empty
    jse.relic = {}                 -- Leave this empty
    jse.empyrean = {}              -- Leave this empty
    jse.capes = {}                 -- Leave this empty

    jse.AF = {
        head= "Geo. Galero +1",
        body= "Geomancy Tunic +3",
        hands= "Geo. Mitaines +4",
        legs= "Geo. Pants +1",
        feet= "Geo. Sandals +3",
    }

    jse.relic = {
        head="Bagua Galero",
        body="Bagua Tunic",
        hands="Bagua Mitaines",
        legs="Bagua Pants +2",
        feet="Bagua Sandals +4",
    }

    jse.empyrean = {
        head= "Azimuth Hood +3",
        body= "Azimuth Coat +3",
        hands= "Azimuth Gloves +3",
        legs= "Azimuth Tights +3",
        feet= "Azimuth Gaiters +3",
    }

    jse.capes={
        luopan={ name="Nantosuelta's Cape", augments={'VIT+20','Eva.+20 /Mag. Eva.+20','Evasion+10','Pet: "Regen"+10','Pet: "Regen"+5',}},
        idle={ name="Nantosuelta's Cape", augments={'VIT+20','Eva.+20 /Mag. Eva.+20','Evasion+10','Pet: "Regen"+10','Phys. dmg. taken-10%',}},
        nuking={ name="Nantosuelta's Cape", augments={'INT+20','Mag. Acc+20 /Mag. Dmg.+20','INT+10','"Mag.Atk.Bns."+10','Phys. dmg. taken-10%',}},
        enfeebling_healing_fc={ name="Nantosuelta's Cape", augments={'MND+20','Mag. Acc+20 /Mag. Dmg.+20','MND+10','"Fast Cast"+10','Phys. dmg. taken-10%',}},
        --tp="",
    }

    ----------------------------------------------------------------
    -- WEAPON SETS
    ----------------------------------------------------------------
    
    weapon_sets = {
        ["Wizard's Rod"] = {
            main="Wizard's Rod",
            sub="Ammurapi Shield",
        },
        ["Daybreak"] = {
            main="Daybreak",
            sub="Ammurapi Shield",
        },
        ["Idris"] = {
            main="Idris",
            sub="Ammurapi Shield",
            --range=empty,
        },
        ["Maxentius"] = {
            main="Maxentius",
            sub="Ammurapi Shield",
        },
    }

    ----------------------------------------------------------------
    -- SETS
    ----------------------------------------------------------------

    sets = {}
    sets.precast = {}               -- Leave this empty
    sets.midcast = {}               -- Leave this empty
    sets.idle = {}                  -- Leave this empty
    sets.ja = {}                    -- Leave this empty
    sets.ws = {}                    -- Leave this empty
    sets.melee = {}                 -- Leave this empty
    sets.buff = {}                  -- Leave this empty

    ----------------------------------------------------------------
    -- IDLE SETS
    ----------------------------------------------------------------

    sets.idle["Normal"] = {                                                                                                                -- -62% DT, -10% PDT, -0% MDT (-72% DT+PDT, -62% DT+MDT), +6-7 Refresh
        --main={ name="Solstice", augments={'Mag. Acc.+20','Pet: Damage taken -4%','"Fast Cast"+5',}},                                    -- -0%
        --sub="Genmei Shield",                                                                                                            -- -10% PDT
        range=empty,
        ammo="Staunch Tathlum",                                                                                                         -- -2% DT
        head=jse.empyrean.head,                                                                                                         -- -11% DT
        body=jse.empyrean.body,                                                                                                         -- +4 Refresh -- Replace with Shamash when possible for DT
        hands=jse.empyrean.hands,                                                                                                       -- -11% DT
        legs="Assid. Pants +1",                                                                                                         -- +1-2 Refresh
        feet=jse.empyrean.feet,                                                                                                         -- -10% DT
        neck="Warder's Charm +1",
        waist="Fucho-no-Obi",                                                                                                           -- +1 Refresh -- Maybe replace with Shinjutsu-no-Obi someday according to guide
        left_ear="Alabaster Earring",                                                                                                   -- -5% DT
        right_ear={ name="Odnowa Earring +1", augments={'Path: A',}},                                                                   -- -3% DT
        left_ring="Murky Ring",                                                                                                         -- -10% DT
        right_ring="Defending Ring",                                                                                                    -- -10% DT
        back=jse.capes.idle,                                                                                                            -- -10% PDT
    }

    sets.idle["Refresh"] = set_combine(sets.idle["Normal"], {                                                                                              -- OVERALL -33% DT, -20% PDT, -0% MDT (-53% DT+PDT, -43% DT+MDT), +9-10 refresh
        --main={ name="Solstice", augments={'Mag. Acc.+20','Pet: Damage taken -4%','"Fast Cast"+5',}},                                                    -- -0%
        --sub="Genmei Shield",                                                                                                                            -- -10% PDT
        range=empty,
        ammo="Staunch Tathlum",                                                                                                                         -- -2% DT
        head={ name="Merlinic Hood", augments={'DEX+11','Pet: "Store TP"+6','"Refresh"+2','Accuracy+16 Attack+16','Mag. Acc.+4 "Mag.Atk.Bns."+4',}},    -- +2 Refresh
        body=jse.empyrean.body,                                                                                                                         -- +4 Refresh -- Replace with Shamash when possible for DT
        hands="Serpentes Cuffs",                                                                                                                        -- -0%      +0.5 Refresh with Serpentes Sabots
        legs="Assid. Pants +1",                                                                                                                         --          1-2 Refresh (realistically 1)
        feet="Serpentes Sabots",                                                                                                                        -- -0%      +0.5 Refresh with Serpentes Cuffs
        neck="Loricate Torque +1",                                                                                                                      -- -6% DT
        waist="Fucho-no-Obi",                                                                                                                           -- -0%      +1 Refresh -- Maybe replace with Shinjutsu-no-Obi someday according to guide
        left_ear="Alabaster Earring",                                                                                                                   -- -5% DT
        right_ear="Nehalennia Earring",
        left_ring="Murky Ring",                                                                                                                         -- -10% DT
        right_ring="Defending Ring",                                                                                                                    -- -10% DT
        back=jse.capes.idle,                                                                                                                            -- -10% PDT
    })

    sets.idle.luopan = {                                                                                                                -- -50% Pet DT (Capped at -37.5%), +29 Regen (need 24+), -42% DT, -10% PDT, -0% MDT (-52% DT+PDT, -42% DT+MDT), +4 Refresh
        main="Idris",                                                                                                                   -- -25% Pet DT
        sub="Genmei Shield",                                                                                                            -- -10% PDT
        range={ name="Dunna", augments={'MP+20','Mag. Acc.+10','"Fast Cast"+3',}},                                                      -- -5% Pet DT
        ammo=empty,
        head=jse.empyrean.head,                                                                                                         -- +5 Regen, -11% DT
        body=jse.empyrean.body,                                                                                                         -- +4 Refresh -- Replace with Shamash when possible for DT
        hands=jse.AF.hands,                                                                                                             -- -3% DT, -13% Pet DT
        legs={ name="Telchine Braconi", augments={'Pet: "Regen"+3','Pet: Damage taken -4%',}},                                          -- -4% Pet DT, +3 Regen Apparently replace with Agwu's slops for DT and stuff
        feet=jse.relic.feet,                                                                                                            -- +5 Regen
        neck={ name="Bagua Charm +1", augments={'Path: A',}},
        left_ring="Murky Ring",                                                                                                         -- -10% DT
        right_ring="Defending Ring",                                                                                                    -- -10% DT
        waist="Isa Belt",                                                                                                               -- -3% Pet DT, +1 Regen
        left_ear="Alabaster Earring",                                                                                                   -- -5% DT ETIOLATION EARRING WHEN DT ACHEIVED
        right_ear={ name="Odnowa Earring +1", augments={'Path: A',}},                                                                   -- -3% DT actually probably this one
        back=jse.capes.luopan,                                                                                                          -- +15 regen
    }

    ----------------------------------------------------------------
    -- MELEE "IDLE"
    ----------------------------------------------------------------
    
    -- This set is trying its best for accuracy but is suffering; it is a work in progress
    -- Nyame RP will help a lot, as will stuff like Chirich
    sets.melee.TP = {
        range=empty,
        ammo="Amar Cluster",
        head="Null Masque",
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet, -- Could instead be Battlecast Gaiters
        neck="Null Loop",
        waist="Null Belt", -- Could instead be Grunfeld
        left_ear="Cessance Earring",
        right_ear="Crep. Earring",
        left_ring="Petrov Ring",
        right_ring="Lehko's Ring",
        back="Null Shawl",
    }

    ----------------------------------------------------------------
    -- PRECAST
    ----------------------------------------------------------------

    -- Could drop the Prolix Ring and replace it with the Lebeche Ring
    sets.precast.fast_cast = {                                                                                                          -- OVERALL 83% FC, 2% Occ
        range=empty,
        ammo="Impatiens",                                                                                                               -- 2% Occ
        head={ name="Merlinic Hood", augments={'"Fast Cast"+6','"Mag.Atk.Bns."+8',}},                                                   -- 14% FC
        body={ name="Merlinic Jubbah", augments={'Mag. Acc.+2','"Fast Cast"+7','INT+9','"Mag.Atk.Bns."+7',}},                           -- 13% FC
        hands={ name="Merlinic Dastanas", augments={'Mag. Acc.+8 "Mag.Atk.Bns."+8','"Fast Cast"+7','MND+5','Mag. Acc.+11',}},           -- 7% FC
        legs="Agwu's Slops",                                                                                                            -- 7% FC
        feet={ name="Merlinic Crackows", augments={'"Fast Cast"+6','CHR+2','Mag. Acc.+8','"Mag.Atk.Bns."+11',}},                        -- 11% FC
        neck="Voltsurge Torque",                                                                                                        -- 4% FC
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                                     -- 5% FC
        left_ear="Malignance Earring",                                                                                                  -- 4% FC
        right_ear="Loquacious Earring",                                                                                                 -- 2% FC
        left_ring="Kishar Ring",                                                                                                        -- 4% FC
        right_ring="Prolix Ring",                                                                                                       -- 2% FC
        back=jse.capes.enfeebling_healing_fc,                                                                                           -- 10% FC
    }

    sets.precast["Impact"] = set_combine(sets.precast.fast_cast, {
        head=empty,
        body="Crepuscular Cloak",
    })

    sets.precast["Dispelga"] = set_combine(sets.precast.fast_cast, {
        main="Daybreak",
        sub="Genmei Shield",
    })

    ----------------------------------------------------------------
    -- NUKE MIDCAST MODES
    ----------------------------------------------------------------

    -- SIM what these actually should be, but it looks like Empyrean +3 beats all

    sets.midcast["Free Nuke"] = {
        range=empty,
        ammo={ name="Ghastly Tathlum +1", augments={'Path: A',}},
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Saevus Pendant +1",
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Freke Ring",
        right_ring={ name="Metamor. Ring +1", augments={'Path: A',}},
        back=jse.capes.nuking,
    }

    sets.midcast["Burst"] = {                                                                           -- 37% MB, 17% MB II
        range=empty,
        ammo={ name="Ghastly Tathlum +1", augments={'Path: A',}},
        head="Ea Hat +1",                                                                               -- 7% MB 7% MB II
        body=jse.empyrean.body,                                                                         -- 5% MB II
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,                                                                         -- 14% MB
        feet=jse.empyrean.feet,
        neck="Mizu. Kubikazari",                                                                        -- 10% MB
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Locus Ring",                                                                         -- 5% MB Eventually replace this ring with Freke when I'm at 40%+ mb cap and other gear puts by over by 5%
        right_ring="Mujin Band",                                                                        -- 5% MB II
        back=jse.capes.nuking
    }

    ----------------------------------------------------------------
    -- COLURE MIDCAST
    ----------------------------------------------------------------
    
    -- TODO: Can probably pull some of the skill gear out and replace with idle or conserve mp gear

    -- GEO SET CONSERVE MP: 43(GEO)+6+4+15+2 = 70%
    -- INDI SET CONSERVE MP: 43(GEO)+15+2 = 60%
    -- back="Fi Follet Cape +1", potentially conserve for geocoloure
    
    sets.midcast.geocolure = {                                                                                                  -- 981 total at present
        --main={ name="Solstice", augments={'Mag. Acc.+20','Pet: Damage taken -4%','"Fast Cast"+5',}},                          -- Skill, 6% Conserve MP
        main="Idris",
        sub="Genmei Shield",
        range={ name="Dunna", augments={'MP+20','Mag. Acc.+10','"Fast Cast"+3',}},                                              -- Skill
        ammo=empty,
        head=jse.empyrean.head,                                                                                                 -- Skill, Set: MP occasionally not depleted when using geomancy spells.
        body=jse.relic.body,                                                                                                    -- Skill (10) Consider replacing with Amalric Doublet +1 for +7 Conserve MP
        hands=jse.AF.hands,                                                                                                     -- Skill, DT
        legs={ name="Vanya Slops", augments={'Healing magic skill +20','"Cure" spellcasting time -7%','Magic dmg. taken -3',}}, -- 6% Conserve MP
        feet={ name="Merlinic Crackows", augments={'"Fast Cast"+6','CHR+2','Mag. Acc.+8','"Mag.Atk.Bns."+11',}},                -- 4% Conserve MP
        neck={ name="Bagua Charm +1", augments={'Path: A',}},                                                                   -- Geomancy boost - Replace with Incanter's Torque when I have Idris + sufficient pet DT and regen for the MP effect.
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                             -- 15% Conserve MP
        left_ear="Mendi. Earring",                                                                                              -- 2% Conserve MP
        right_ear={ name="Azimuth Earring +1", augments={'System: 1 ID: 1676 Val: 0','Mag. Acc.+11','Damage taken-3%',}},       -- Skill Consider replacing with Gwati Earring for Conserve
        left_ring="Stikini Ring",                                                                                               -- Skill
        right_ring="Stikini Ring",                                                                                              -- Skill
        back={ name="Lifestream Cape", augments={'Geomancy Skill +9','Indi. eff. dur. +20','Pet: Damage taken -2%',}},          -- Skill
    }

    sets.midcast.indicolure = {                                                                                                  -- 981 total at present
        --main={ name="Gada", augments={'Indi. eff. dur. +10','Mag. Acc.+13','"Mag.Atk.Bns."+13','DMG:+10',}},                   -- Indi duration +10%
        main="Idris",
        sub="Genmei Shield",
        range={ name="Dunna", augments={'MP+20','Mag. Acc.+10','"Fast Cast"+3',}},                                              -- Skill
        ammo=empty,
        head=jse.empyrean.head,                                                                                                 -- Skill, Set: MP occasionally not depleted when using geomancy spells.
        body=jse.relic.body,                                                                                                    -- Skill (10) Consider replacing with Amalric Doublet +1 for +7 Conserve MP
        hands=jse.AF.hands,                                                                                                     -- Skill, DT
        legs=jse.relic.legs,                                                                                                    -- Indi duration +12
        feet=jse.empyrean.feet,                                                                                                 -- Indi duration +15, Set: MP occasionally not depleted when using geomancy spells.
        neck={ name="Bagua Charm +1", augments={'Path: A',}},                                                                   -- Geomancy boost - Replace with Incanter's Torque when I have Idris + sufficient pet DT and regen for the MP effect.
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                             -- 15% Conserve MP
        left_ear="Mendi. Earring",                                                                                              -- 2% Conserve MP
        right_ear={ name="Azimuth Earring +1", augments={'System: 1 ID: 1676 Val: 0','Mag. Acc.+11','Damage taken-3%',}},       -- Skill Consider replacing with Gwati Earring for Conserve
        left_ring="Stikini Ring",                                                                                               -- Skill
        right_ring="Stikini Ring",                                                                                              -- Skill
        back={ name="Lifestream Cape", augments={'Geomancy Skill +9','Indi. eff. dur. +20','Pet: Damage taken -2%',}},          -- Skill
    }

    -- Entrust doesn't work with Idris Geomancy bonus
    sets.midcast.entrust = set_combine(sets.midcast.indicolure, {
        main={ name="Gada", augments={'Indi. eff. dur. +10','Mag. Acc.+13','"Mag.Atk.Bns."+13','DMG:+10',}},                    -- Indi duration +10%
    })

    ----------------------------------------------------------------
    -- ENFEEBLING MIDCAST
    ----------------------------------------------------------------

    -- Geomancy Attire will be really good for this at +2 and +3
    sets.midcast["Enfeebling Magic"] = {
        range=empty,
        ammo="Pemphredo Tathlum",
        head=empty,  -- This wants to be AF head when upgraded
        body={ name="Cohort Cloak +1", augments={'Path: A',}}, -- This wants to be AF body when head is upgraded
        hands=jse.AF.hands,
        legs="Jhakri Slops +2", -- This wants to be AF legs when upgraded
        feet=jse.AF.feet,
        neck={ name="Bagua Charm +1", augments={'Path: A',}},
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Kishar Ring",
        right_ring="Stikini Ring",
        back={ name="Aurist's Cape +1", augments={'Path: A',}},
    }

    sets.midcast["Dispelga"] = set_combine(sets.midcast["Enfeebling Magic"], {
        main="Daybreak",
        sub="Genmei Shield",
    })

    sets.midcast["Impact"] = {
        range=empty,
        ammo="Pemphredo Tathlum",
        body="Crepuscular Cloak",
        hands={ name="Amalric Gages +1", augments={'INT+12','Mag. Acc.+20','"Mag.Atk.Bns."+20',}},
        legs="Azimuth Tights +2",
        feet="Azimuth Gaiters +2",
        neck="Incanter's Torque",
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Ilmr Earring",
        right_ear="Regal Earring",
        left_ring="Stikini Ring",
        right_ring="Stikini Ring",
        back={ name="Aurist's Cape +1", augments={'Path: A',}},
    }

    ----------------------------------------------------------------
    -- ENHANCING MIDCAST
    ----------------------------------------------------------------

    sets.midcast["Enhancing Magic"] = set_combine(sets.midcast["Free Nuke"], {                                                      -- +75% duration
        main={ name="Gada", augments={'Enh. Mag. eff. dur. +6',}},                                                                  -- +6% duration
        sub="Ammurapi Shield",                                                                                                      -- +10% duration
        range=empty,
        ammo="Pemphredo Tathlum",
        head={ name="Telchine Cap", augments={'Enh. Mag. eff. dur. +10',}},                                                         -- +10% duration
        body={ name="Telchine Chas.", augments={'Pet: "Regen"+3','Enh. Mag. eff. dur. +10',}},                                      -- +10% duration
        hands={ name="Telchine Gloves", augments={'Pet: "Regen"+3','Enh. Mag. eff. dur. +10',}},                                    -- +10% duratiom.
        legs={ name="Telchine Braconi", augments={'Enh. Mag. eff. dur. +9',}},                                                      -- +9% duration
        feet={ name="Telchine Pigaches", augments={'Enh. Mag. eff. dur. +10',}},                                                    -- +10% duration
        neck="Incanter's Torque",
        waist="Embla Sash",                                                                                                         -- +10% duration
        left_ear="Mendi. Earring",
        right_ear="Gwati Earring",
        left_ring="Stikini Ring",
        right_ring="Stikini Ring",
        back={ name="Aurist's Cape +1", augments={'Path: A',}},
    })

    sets.midcast["Regen"] = set_combine(sets.midcast["Enhancing Magic"], {
        main="Bolelabunga",                                                                                                         -- 10% potency
    })

    sets.midcast["Stoneskin"] = set_combine(sets.midcast["Enhancing Magic"], {
        legs="Shedir Seraweels",                                                                                                    -- +35 Stoneskin
        neck="Nodens Gorget",                                                                                                       -- +30 Stoneskin
    })

    sets.midcast["Aquaveil"] = set_combine(sets.midcast["Enhancing Magic"], {                                                       -- +1 Aquaveil, 91% SIRD
        ammo="Staunch Tathlum",                                                                                                     -- 10% SIRD
        head="Agwu's Cap",                                                                                                          -- 10% SIRD
        body="Ros. Jaseran +1",                                                                                                     -- 25% SIRD
        hands={ name="Amalric Gages +1", augments={'INT+12','Mag. Acc.+20','"Mag.Atk.Bns."+20',}},                                  -- 11% SIRD
        legs="Shedir Seraweels",                                                                                                    -- +1 Aquaveil
        neck="Loricate Torque +1",                                                                                                  -- 5% SIRD
        waist="Rumination Sash",                                                                                                    -- 10% SIRD
        left_ring="Freke Ring",                                                                                                     -- 10% SIRD
        right_ring="Evanescence Ring",                                                                                              -- 5% SIRD
        back="Fi Follet Cape +1",                                                                                                   -- 5% SIRD
    })

    sets.midcast.barspell = set_combine(sets.midcast["Enhancing Magic"], {
        legs="Shedir Seraweels",
    })

    ----------------------------------------------------------------
    -- HEALING MIDCAST
    ----------------------------------------------------------------

    sets.midcast["Cure"] = {                                                                                                        -- Overall +50%
        main="Daybreak",                                                                                                            -- 30%
        sub="Genmei Shield",
        range=empty,
        ammo="Kalboron Stone",
        head={ name="Vanya Hood", augments={'MP+50','"Cure" potency +7%','Enmity-6',}},                                             -- +10%
        body={ name="Vanya Robe", augments={'Healing magic skill +20','"Cure" spellcasting time -7%','Magic dmg. taken -3',}},
        hands={ name="Vanya Cuffs", augments={'Healing magic skill +20','"Cure" spellcasting time -7%','Magic dmg. taken -3',}},
        legs={ name="Vanya Slops", augments={'Healing magic skill +20','"Cure" spellcasting time -7%','Magic dmg. taken -3',}},
        feet={ name="Vanya Clogs", augments={'MP+50','"Cure" potency +7%','Enmity-6',}},                                            -- +5%
        neck="Incanter's Torque",
        waist="Rumination Sash",
        left_ear="Mendi. Earring",                                                                                                  -- +5%
        right_ear="Meili Earring",
        left_ring="Stikini Ring",
        right_ring="Stikini Ring",
        back=jse.capes.enfeebling_healing_fc,
    }

    sets.midcast["Curaga"] = sets.midcast["Cure"]

    -- This will apply to any non-cure healing magic, like debuff cleanses, unless they have their own set
    -- TODO: REVIEW THIS SET AS ITS JUST THERE FOR SCH/WHM SUB
    sets.midcast["Healing Magic"] = set_combine(sets.idle["Normal"], { -- -59% DT, +34% Conserve MP, 33% SIRD, Haste +6%, FC +8%
        main="Daybreak",                                                                                                            -- Filler
        sub="Culminus",                                                                                                             -- 10% SIRD 
        ammo="Staunch Tathlum",                                                                                                     -- -2% DT, 10% SIRD 
        --head=jse.empyrean.head,                                                                                                     -- -10% DT, Haste +6%
        --body=jse.empyrean.body,                                                                                                     -- -13% DT, -28 Enmity
        hands="Nyame Gauntlets",                                                                                                    -- 7% DT
        --legs=jse.empyrean.legs,                                                                                                     -- 11% DT
        --feet=jse.empyrean.feet,                                                                                                     -- MEVA I guess
        neck="Loricate Torque +1",                                                                                                  -- -6% DT, 5% SIRD 
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                                 -- +15% Conserve MP
        left_ear="Mendi. Earring",                                                                                                  -- +2% Conserve MP, +5% Cure Potency
        right_ear="Etiolation Earring",                                                                                             -- Resist silence
        left_ring="Murky Ring",                                                                                                     -- -10% DT, 3% SIRD
        right_ring="Mephitas's Ring +1",                                                                                            -- -3-7 Enmity TODO: Needs augment for conserve MP
        back="Fi Follet Cape +1",                                                                                                   -- +5% Conserve MP, 5% SIRD
    })

    -- Technically this is "enhancing magic", for some godforsaken reason, so we'll just copy Healing Magic for Erase
    sets.midcast["Erase"] = sets.midcast["Healing Magic"]

    -- TODO: More healing skill - can get more Vanya
    -- TODO: REVIEW THIS SET AS ITS JUST THERE FOR SCH/WHM SUB
    sets.midcast["Cursna"] = set_combine(sets.idle["Normal"], {
        main={ name="Gada", augments={'Indi. eff. dur. +10','Mag. Acc.+13','"Mag.Atk.Bns."+13','DMG:+10',}},                        -- Healing skill
        sub="Genmei Shield",
        --ammo=,
        head={ name="Vanya Hood", augments={'MP+50','"Cure" potency +7%','Enmity-6',}}, -- Replace with healing skill
        --body=jse.relic.body,
        --hands=,
        --legs=jse.AF.legs,                                                                                                           -- Healing skill
        feet={ name="Vanya Clogs", augments={'MP+50','"Cure" potency +7%','Enmity-6',}}, -- Replace with healing skill              -- Cursna +5%
        neck="Debilis Medallion",                                                                                                   -- Cursna +15%
        --waist="Gishdubar Sash",                                                                                                     -- Cursna Received +10%
        waist="Bishop's Sash",                                                                                                      -- Healing skill
        --left_ear=,
        right_ear="Meili Earring",
        left_ring="Stikini Ring",
        right_ring="Haoma's Ring",                                                                                                  -- Cursna +15%
        back="Oretan. Cape +1",                                                                                                     -- Cursna +5%
    })

    ----------------------------------------------------------------
    -- OTHER MIDCAST
    ----------------------------------------------------------------

    sets.midcast["Aspir"] = set_combine(sets.midcast["Free Nuke"], {
        main={ name="Rubicundity", augments={'Mag. Acc.+9','"Mag.Atk.Bns."+8','Dark magic skill +9','"Conserve MP"+5',}},
        sub="Ammurapi Shield",
        ammo="Pemphredo Tathlum",
        head=jse.relic.head,
        body=jse.AF.body,
        --hands="",
        legs=jse.empyrean.legs,
        feet="Agwu's Pigaches",
        neck="Erra Pendant",
        waist="Fucho-no-Obi",
        left_ear="Barkaro. Earring",
        right_ear={ name="Azimuth Earring +1", augments={'System: 1 ID: 1676 Val: 0','Mag. Acc.+11','Damage taken-3%',}},
        left_ring="Archon Ring",
        right_ring="Evanescence Ring",
        back={ name="Aurist's Cape +1", augments={'Path: A',}},
    })

    sets.midcast["Drain"] = sets.midcast["Aspir"]

    ----------------------------------------------------------------
    -- JOB ABILITIES
    ----------------------------------------------------------------

    sets.ja["Bolster"] = {
        body=jse.relic.body,
    }

    -- It's implied that I will already be in the Nantosuelta's Cape
    sets.ja["Life Cycle"] = {
        body=jse.AF.body,
    }

    sets.ja["Mending Halation"] = {
        legs=jse.relic.legs,
    }

    sets.ja["Radial Arcana"] = {
        feet=jse.relic.feet,
    }

    sets.ja["Full Circle"] = {
        head=jse.empyrean.head,
    }


    ----------------------------------------------------------------
    -- WEAPONSKILLS
    ----------------------------------------------------------------

    -- Would it just be better to use Nyame anyway for much of these sets for the sake of the higher magic evasion? I do have decent DT in all of them anyway.

    sets.ws.default = { -- Hybrid DT, generic for physical weaponskills (idk what else to put here)
        range=empty,
        ammo="Amar Cluster",
        head="Null Masque",
        body="Jhakri Robe +2",
        hands=jse.empyrean.hands,
        legs="Jhakri Slops +2",
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Malignance Earring",
        right_ear="Odnowa Earring +1",
        left_ring="Murky Ring",
        right_ring="Rufescent Ring",
        back="Null Shawl",
    }

    sets.ws["Realmrazer"] = {
        range=empty,
        ammo="Amar Cluster",
        head="Null Masque",
        body="Jhakri Robe +2",
        hands=jse.empyrean.hands,
        legs="Jhakri Slops +2",
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Malignance Earring",
        right_ear="Odnowa Earring +1",
        left_ring="Murky Ring",
        right_ring="Rufescent Ring",
        back="Null Shawl",
    }

    sets.ws["Exudation"] = {
        range=empty,
        ammo="Ghastly Tathlum +1",
        head=jse.empyrean.head,
        body="Nyame Mail",
        hands="Jhakri Cuffs +2",
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Malignance Earring",
        right_ear="Odnowa Earring +1",
        left_ring="Murky Ring",
        right_ring="Metamor. Ring +1",
        back="Alabaster Mantle",
    }

    sets.ws["Aeolian Edge"] = {
        range=empty,
        ammo="Ghastly Tathlum +1",
        head=jse.empyrean.head,
        body="Nyame Mail",
        hands="Jhakri Cuffs +2",
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Malignance Earring",
        right_ear="Odnowa Earring +1",
        left_ring="Murky Ring",
        right_ring="Metamor. Ring +1",
        back="Alabaster Mantle", -- WSD + PDT Ambu cape will be better.
    }

    sets.ws["Black Halo"] = {
        range=empty,
        ammo="Amar Cluster",
        head="Null Masque",
        body="Jhakri Robe +2",
        hands="Jhakri Cuffs +2",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Grunfeld Rope",
        left_ear="Malignance Earring",
        right_ear="Odnowa Earring +1",
        left_ring="Murky Ring",
        right_ring="Rufescent Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Judgment"] = sets.ws["Black Halo"]

    sets.ws["Seraph Strike"] = { -- 1000+ Prefer Daybreak for this
        range=empty,
        ammo="Sroda Tathlum",
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands="Jhakri Cuffs +2",
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Saevus Pendant +1",
        waist="Eschan Stone",
        left_ear="Malignance Earring",
        right_ear="Friomisi Earring",
        left_ring="Murky Ring",
        right_ring="Defending Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Flash Nova"] = sets.ws["Seraph Strike"] -- 1000
end

----------------------------------------------------------------
-- HELPER FUNCTIONS 
----------------------------------------------------------------

function equip_set_and_weapon(set)
    equip(set)

    -- This will only add the current weapon set to sets that have neither a main weapon or a sub (like a shield)
    if not set.main and not set.sub then
        equip(weapon_sets[weapon_mode.current])
        return
    end
end

function idle()
    if toggle_tp == "On" and player.status == "Engaged" then
        equip_set_and_weapon(sets.melee.TP)
    else
        if pet.isvalid then
            equip_set_and_weapon(sets.idle.luopan)
        else
            equip_set_and_weapon(sets.idle[idle_mode.current])

            -- Speed overlay
            if toggle_speed == "On" then
                equip({feet=jse.AF.feet})
            end
        end
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

    -- There are many kinds of abilities, so let's check Weapon Skills first, as they count as an "Ability"
    if spell.type == "WeaponSkill" then
        -- If the weapon skill name matches.
        if sets.ws[spell.name] then
            equip_set_and_weapon(sets.ws[spell.name])
        else
             -- Unhandled Weapon Skills
            equip_set_and_weapon(sets.ws.default)
        end

        -- Hachirin-no-Obi overlay.
        if S{world.weather_element, world.day_element}:contains(spell.element) and spell.element ~= "None" and spell.name ~= "Myrkr" then
            equip({waist="Hachirin-no-Obi"})
        end

        return
    end

    -- Check every other kind of ability
    if spell.action_type == "Ability" then
        if sets.ja[spell.name] then
            equip_set_and_weapon(sets.ja[spell.name])
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
end

-- spell.action_type == "Magic" ensures that job ability gear survives into midcast, as otherwise they won't work.
function midcast(spell)
    if spell.action_type == "Magic" then
        local matched = false

        -- If the spell is a Geocolure or Indicolure spell
        if spell.name:match("^Geo") then
            equip_set_and_weapon(sets.midcast.geocolure)
            matched = true
        elseif spell.name:match("^Indi") then
            if buffactive["Entrust"] then
                equip_set_and_weapon(sets.midcast.entrust)
            else
                equip_set_and_weapon(sets.midcast.indicolure)
            end
            
            matched = true
        end

        -- If the spell matches one of the match_list spells.
        -- Note: This HAS to be after the Geo/Indi spells otherwise it'll match those too
        -- If I ever have to break up these spells into separate sets, it would be worth breaking this up.
        if not matched then
            for match in match_list:it() do
                if spell.name:match(match) then
                    equip_set_and_weapon(sets.midcast[match])
                    matched = true
                    break
                end
            end
        end
        
        -- If the spell name EXACTLY matches.
        if not matched and sets.midcast[spell.name] then
            equip_set_and_weapon(sets.midcast[spell.name])
            matched = true
        end

        -- If the spell skill is Elemental Magic
        if not matched and spell.skill == "Elemental Magic" then
            equip_set_and_weapon(sets.midcast[nuking_mode.current])
            matched = true
        end

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
    end
end

function aftercast(spell)
    -- Gearswap will not immediately register the geocolure's summoning, so we skip this and wait for pet_change to handle the idle swap.
    if spell.name:match("^Geo") then
        return
    end

    idle()
end

function pet_change(pet,gain)
    -- We wait until here to select gear, as Gearswap doesn't immediately register the summoning in aftercast.
    if not midaction() then
        idle()
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

    if main_command == "nukemode" then
        if sub_command == "burst" then
            nuking_mode:set("Burst")
        elseif sub_command == "freenuke" then
            nuking_mode:set("Free Nuke")
        else
            nuking_mode:cycle()
        end
        add_to_chat(123, string.format("Nuking mode set to %s", nuking_mode.current))

    elseif main_command == "weaponmode" then
        weapon_mode:cycle()
        add_to_chat(123, string.format("Weapon mode set to %s", weapon_mode.current))
        idle()

    elseif main_command == "idlemode" then
        idle_mode:cycle()
        add_to_chat(123, string.format("Idle mode set to %s", idle_mode.current))
        idle()

    elseif main_command == "toggletp" then
        toggle_tp = handle_toggle(toggle_tp, "TP")

        idle()

        if toggle_tp == "On" then
            equip(weapon_sets[weapon_mode.current])
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
    send_command("unbind f1")
    send_command("unbind f2")
    
    send_command("unbind f5")
    send_command("unbind f6")
    send_command("unbind f7")

    send_command("unbind f9")

    send_command("unbind f12")
end