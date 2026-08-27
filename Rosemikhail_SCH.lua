---@diagnostic disable: lowercase-global, undefined-global
include("Modes.lua")

----------------------------------------------------------------
-- NOTES
----------------------------------------------------------------

--[[
Kinda just do this as and when:
- Notification in chat when I'm slept or doomed
- Update barspell logic to care about the fact that elemental and status barspells have different resistance calculations
    - i.e. status ones have a base potency, so I could just cast in conserve or idle
    - Steal from WHM

Potential enhancements:
- Save certain toggles and sets between reloads
- Cure DT vs conserve toggle
    - Kinda less less important but can make a conserve focused set, potentially with Cure II stat
- When Agwu's is upgraded, I may want a separate magic burst set for Ebullience. Check SCH guide later. This will require adjustment to a check in midcast.
- I don't know how much I care about the Grimoire thing. Right now, it seems to cast faster? But I'm not using the logic as I don't trust it.

- Consider switching to Stormsurge (can Gearswap check merits?)
    - Would need a check, as there's a bit of gear that can boost this

- Consider a separate Aspir burst set
- Consider having two Aquaveil sets, one for myself that uses SIRD, another that maximises duration for AOE casting (check if accession is on)

From Reddit:
-"If a related day or/and weather is active, Helices will receive the day/weather damage bonus or penalty 100% of the time even without an Elemental Obi. "
- Your lua probably already accounts for this, but if you made it yourself, make sure you use O.Sash or Skrymir or w/e instead of an Obi for these. 
]]

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------

-- Modes and toggles
nuking_mode = M{"Free Nuke", "Burst", "Occult Acumen", "Vagary Burst"}
idle_mode = M{"Normal", "Refresh"}
weapon_mode = M{"Marin Staff", "Wizard's Rod", "Maxentius", "Malevolence", "Opashoro"}
regen_mode = M{"Balanced", "Potency", "Duration"}

toggle_speed = "Off"
toggle_tp = "Off" -- This will disable weapon swapping as well

-- Midcast helpers
match_list = S{"Cure", "Curaga", "Aspir", "Drain"}
helix_spells = S{"Geohelix", "Hydrohelix", "Anemohelix", "Pyrohelix", "Cryohelix", "Ionohelix", "Noctohelix", "Luminohelix", "Geohelix II", "Hydrohelix II", "Anemohelix II", "Pyrohelix II", "Cryohelix II", "Ionohelix II", "Noctohelix II", "Luminohelix II",}
ignored_spell_types = S{"Samba", "Waltz", "Jig", "Step", "Flourish1", "Flourish2", "Scholar"}

-- Bindings
send_command("bind f1 gs c nukemode freenuke")
send_command("bind f2 gs c nukemode burst")
send_command("bind f3 gs c nukemode occultacumen")
send_command("bind f4 gs c nukemode vagaryburst")

send_command("bind f5 gs c weaponmode")
send_command("bind f6 gs c idlemode")
send_command("bind f7 gs c toggletp")
send_command("bind f8 gs c regenmode")

send_command("bind f9 gs c togglespeed")
send_command("bind f12 gs c toggletextbox")

-- Help Text
add_to_chat(123, "F1-F4: Switch nuking mode")
add_to_chat(123, "F5: Switch weapon set, F6: Cycle idle mode")
add_to_chat(123, "F7: Toggle TP lock, F8: Switch regen mode")
add_to_chat(123, "F9: Toggle speed gear")
add_to_chat(123, "F12: Hide information text box")

----------------------------------------------------------------
-- INFORMATION BOX
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
        "[F1-F4] Nuking Mode: %s [F5] Wep: %s [F6] Idle: %s [F7] TP Lock: %s [F8] Regen Mode: %s [F9] Speed: %s",
        nuking_mode.current,
        weapon_mode.current,
        idle_mode.current,
        format_toggle(toggle_tp),
        regen_mode.current,
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
    send_command("wait 5;input /lockstyleset 22") -- Ebur
end

function update_macro_book()
    if player.sub_job == "RDM" then
        send_command("input /macro book 3;input /macro set 1")
    elseif player.sub_job == "WHM" then
        send_command("input /macro book 4;input /macro set 1")
    end
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
        head="Acad. Mortar. +3",
        body="Acad. Gown +3",
        hands="Acad. Bracers +3",
        legs="Acad. Pants +3",
        feet="Acad. Loafers +3",
    }

    jse.relic = {
        head="Peda. M.Board +3", 
        body="Peda. Gown +3",       -- Didn't make a check for the bonus to skill because I've barely invested into it Merit-wise (though it works on the JA, so I could just do it whenever)
        hands="Peda. Bracers +3",   -- Didn't merit Tranquility or Equanimity, so didn't bother checking for that
        legs="Peda. Pants +4",
        feet="Peda. Loafers +3",    -- Added a check into precast for the bonus, but I don't want it to affect my midcasts for the recast reduction. Maybe if I ever end up using Stun on this job.
    }

    jse.empyrean = {
        head="Arbatel Bonnet +3",
        body="Arbatel Gown +3",
        hands="Arbatel Bracers +3",
        legs="Arbatel Pants +3",    -- Suppose I could have a Penury/Parsimony check, but eh.
        feet="Arbatel Loafers +3",  -- If for some reason my feet ever AREN'T these for nuking, then maybe add a check for the Klima feature. Though I should always have that.
    }

    jse.capes = {
        nuking_idle={ name="Lugh's Cape", augments={'INT+20','Mag. Acc+20 /Mag. Dmg.+20','INT+10','"Mag.Atk.Bns."+10','Phys. dmg. taken-10%',}},
        occult_acumen={ name="Lugh's Cape", augments={'INT+20','Mag. Acc+20 /Mag. Dmg.+20','INT+10','"Store TP"+10',}},
        helix_duration={ name="Bookworm's Cape", augments={'INT+2','MND+4','Helix eff. dur. +20',}},
        regen_potency={ name="Bookworm's Cape", augments={'INT+3','MND+1','Helix eff. dur. +18','"Regen" potency+10',}},
        --tp="", Melee TP: DEX +20, Acc +30, Atk +20, Store TP +10 ... er another 10 dex i think
        --wsd="", WS: INT +30, Macc/Mdmg +20, Weapon Skill Damage +10%
        --curing="" MND+20, Mag. Evasion +10, Eva.+20/Mag.Eva+20, Enmity -10, Damage taken -5% (or PDT)
    }

    ----------------------------------------------------------------
    -- WEAPON SETS
    ----------------------------------------------------------------
    
    weapon_sets = {
        ["Marin Staff"] = {
            main={ name="Marin Staff +1", augments={'Path: A',}},
            sub="Enki Strap",
        },
        ["Wizard's Rod"] = {
            main="Wizard's Rod",
            sub="Ammurapi Shield",
        },
        ["Maxentius"] = {
            main="Maxentius",
            sub="Ammurapi Shield",
        },
        ["Malevolence"] = {
            main="Malevolence",
            sub="Ammurapi Shield",
        },
        ["Opashoro"] = {
            main="Opashoro",
             sub="Enki Strap",
        },
    }

    -- Consider Malignance pole for later.

    ----------------------------------------------------------------
    -- GEAR SETS
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
    -- IDLE MODES
    ----------------------------------------------------------------

    sets.idle["Normal"] = {                                                                                                                             -- OVERALL -51% DT, -10% PDT, -3% MDT (-61% DT+PDT, -54% DT+MDT), +7 refresh
        ammo="Homiliary",                                                                                                                               -- +1 Refresh
        head={ name="Merlinic Hood", augments={'DEX+11','Pet: "Store TP"+6','"Refresh"+2','Accuracy+16 Attack+16','Mag. Acc.+4 "Mag.Atk.Bns."+4',}},    -- +2 Refresh
        body=jse.empyrean.body,                                                                                                                         -- +3 Refresh, 13% DT
        hands="Nyame Gauntlets",                                                                                                                        -- 7% DT
        legs=jse.empyrean.legs,                                                                                                                         -- 11% DT
        feet=jse.empyrean.feet,                                                                                                                         -- We're capped on DT so, shrug, some meva
        neck="Warder's Charm +1",
        waist="Fucho-no-Obi",                                                                                                                           -- +1 Refresh
        left_ear="Nehalennia Earring",
        right_ear="Etiolation Earring",                                                                                                                 -- -3% MDT
        left_ring="Murky Ring",                                                                                                                         -- -10% DT
        right_ring="Defending Ring",                                                                                                                    -- -10% DT
        back=jse.capes.nuking_idle                                                                                                                      -- -10% PDT
    }

    sets.idle["Refresh"] = set_combine(sets.idle["Normal"], {                                                                                              -- OVERALL -43% DT, -10% PDT, -0% MDT (-53% DT+PDT, -43% DT+MDT), +9-10 refresh
       ammo="Homiliary",                                                                                                                                -- +1 Refresh
        head={ name="Merlinic Hood", augments={'DEX+11','Pet: "Store TP"+6','"Refresh"+2','Accuracy+16 Attack+16','Mag. Acc.+4 "Mag.Atk.Bns."+4',}},    -- +2 Refresh
        body=jse.empyrean.body,                                                                                                                         -- +3 Refresh, 12% DT
        hands="Serpentes Cuffs",                                                                                                                        -- +1 Refresh (with Serpentes Sabots)
        legs="Assid. Pants +1",                                                                                                                         -- 1-2 Refresh
        feet="Serpentes Sabots",                                                                                                                        -- Refresh
        neck="Loricate Torque +1",                                                                                                                      -- -6% DT
        waist="Fucho-no-Obi",                                                                                                                           -- +1 Refresh -- Maybe replace with Shinjutsu-no-Obi someday according to guide
        left_ear="Nehalennia Earring",
        right_ear="Alabaster Earring",                                                                                                                  -- -5% DT
        left_ring="Murky Ring",                                                                                                                         -- -10% DT
        right_ring="Defending Ring",                                                                                                                    -- -10% DT
        back=jse.capes.nuking_idle                                                                                                                      -- -10% PDT
    })

    ----------------------------------------------------------------
    -- MELEE "IDLE"
    ----------------------------------------------------------------
    
    sets.melee.TP = { -- ~53 per WS
        ammo="Amar Cluster",
        head="Null Masque",
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Cessance Earring",
        right_ear="Crep. Earring",
        left_ring="Lehko's Ring",
        right_ring="Defending Ring",
        back="Null Shawl",
    }

    ----------------------------------------------------------------
    -- PRECAST
    ----------------------------------------------------------------

    -- When I can overcap FC considerably more, consider looking into setting up grimoire casting.
    sets.precast.fast_cast = {                                                                                                          -- OVERALL 85% FC, 2% Occ
        ammo="Impatiens",                                                                                                               -- 2% Occ
        head={ name="Merlinic Hood", augments={'"Fast Cast"+6','"Mag.Atk.Bns."+8',}},                                                   -- 14% FC
        body={ name="Merlinic Jubbah", augments={'Mag. Acc.+2','"Fast Cast"+7','INT+9','"Mag.Atk.Bns."+7',}},                           -- 13% FC
        hands=jse.AF.hands,                                                                                                             -- 9% FC
        legs="Agwu's Slops",                                                                                                            -- 7% FC
        feet={ name="Merlinic Crackows", augments={'"Fast Cast"+6','CHR+2','Mag. Acc.+8','"Mag.Atk.Bns."+11',}},                        -- 11% FC
        neck="Voltsurge Torque",                                                                                                        -- 4% FC
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                                     -- 5% FC
        left_ear="Malignance Earring",                                                                                                  -- 4% FC
        right_ear="Loquacious Earring",                                                                                                 -- 2% FC
        left_ring="Kishar Ring",                                                                                                        -- 4% FC
        right_ring="Prolix Ring",                                                                                                       -- 2% FC
        back="Fi Follet Cape +1",                                                                                                       -- 10% FC
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

    sets.midcast["Free Nuke"] = {
        ammo={ name="Ghastly Tathlum +1", augments={'Path: A',}},
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck={ name="Argute Stole +1", augments={'Path: A',}},
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Freke Ring",
        right_ring={ name="Metamor. Ring +1", augments={'Path: A',}},
        back=jse.capes.nuking_idle
    }

    -- reevaluate the actual magic burst stat here
    sets.midcast["Burst"] = {                                                                                           -- 31% MB, 16% MB II
        ammo={ name="Ghastly Tathlum +1", augments={'Path: A',}},
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,                                                                                       -- 15% MB
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,                                                                                         -- 5% MB II
        neck="Mizukage-no-Kubikazari",                                                                                  -- 10% MB
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Freke Ring",
        right_ring="Mujin Band",                                                                                        -- 5% MB II
        back=jse.capes.nuking_idle,
    }

    sets.midcast["Occult Acumen"] = set_combine(sets.midcast["Free Nuke"], {
        ammo="Seraphic Ampulla",
        head="Mallquis Chapeau +2",
        --body=
        --hands=
        legs= "Perdition Slops",
        feet="Battlecast Gaiters",
        --neck=
        waist="Oneiros Rope",
        left_ear="Cessance Earring",
        right_ear="Crep. Earring",
        left_ring="Petrov Ring",
        right_ring="Lehko's Ring",
        back=jse.capes.occult_acumen,
    })

    -- Tweak as necessary.
    sets.midcast["Vagary Burst"] = set_combine(sets.midcast["Free Nuke"], {
        --main=empty,
        --sub=empty,
        --ammo=empty,
        head=empty,
        body=empty,
        --hands=empty,
        --legs=empty,
        --feet=empty,
        --neck=empty,
        --waist=empty,
        --left_ear=empty,
        --right_ear=empty,
        --left_ring=empty,
        --right_ring=empty,
        --back=empty,
    })

    sets.midcast.helix = {} -- Leave this empty.

    -- Helix duration cape might be helpful maybe... but I do less damage with it.

    sets.midcast.helix["Free Nuke"] = {
        main="Wizard's Rod",
        sub="Culminus",
        range=empty,
        ammo="Ghastly Tathlum +1",
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck={ name="Argute Stole +1", augments={'Path: A',}},
        waist="Eschan Stone",
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Freke Ring",
        right_ring="Mallquis Ring",
        back={ name="Lugh's Cape", augments={'INT+20','Mag. Acc+20 /Mag. Dmg.+20','INT+10','"Mag.Atk.Bns."+10','Phys. dmg. taken-10%',}},
    }

    sets.midcast.helix["Burst"] = {
        main="Wizard's Rod",
        sub="Culminus",
        range=empty,
        ammo="Ghastly Tathlum +1",
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Mizu. Kubikazari",
        waist="Eschan Stone",
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Mujin Band",
        right_ring="Mallquis Ring",
        back={ name="Lugh's Cape", augments={'INT+20','Mag. Acc+20 /Mag. Dmg.+20','INT+10','"Mag.Atk.Bns."+10','Phys. dmg. taken-10%',}},
    }

    sets.midcast["Kaustra"] = {
        main="Wizard's Rod",
        sub="Ammurapi Shield",
        range=empty,
        ammo="Ghastly Tathlum +1",
        head="Pixie Hairpin +1",
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Mizu. Kubikazari",
        waist="Acuity Belt +1",
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Archon Ring",
        right_ring="Freke Ring",
        back={ name="Lugh's Cape", augments={'INT+20','Mag. Acc+20 /Mag. Dmg.+20','INT+10','"Mag.Atk.Bns."+10','Phys. dmg. taken-10%',}},
    }

    ----------------------------------------------------------------
    -- ENFEEBLING MIDCAST
    ----------------------------------------------------------------
 
    sets.midcast.enfeebling_dark = {
        ammo="Pemphredo Tathlum",
        head=jse.AF.head,
        body=jse.AF.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Incanter's Torque",
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Kishar Ring",
        right_ring="Stikini Ring",
        back={ name="Aurist's Cape +1", augments={'Path: A',}},
    }

    sets.midcast.enfeebling_light = {
        ammo="Pemphredo Tathlum",
        head=empty,
        body={ name="Cohort Cloak +1", augments={'Path: A',}},
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Incanter's Torque",
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Kishar Ring",
        right_ring="Stikini Ring",
        back={ name="Aurist's Cape +1", augments={'Path: A',}},
    }
    
    -- Impact likes more elemental magic skill
    sets.midcast["Impact"] = {
        ammo="Pemphredo Tathlum",
        head=empty,
        body="Crepuscular Cloak",
        hands=jse.AF.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
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

    -- TODO: Improve Telchine to 10% if possible
    -- TOOD: Musa someday for 20% BUT LMAO

    -- TODO: Swap out skill for conserve MP perhaps

    -- TODO: When I'm mastered, reevaluate the pieces here.
    -- Consider DT pieces instead of skill
    sets.midcast["Enhancing Magic"] = {                                                                                             -- +77% duration, -- 532 Enhancing Skill +13 with gift
        main={ name="Gada", augments={'Enh. Mag. eff. dur. +6',}},                                                                  -- +6% duration
        sub="Ammurapi Shield",                                                                                                      -- +10% duration
        range=empty,
        ammo="Pemphredo Tathlum",
        head={ name="Telchine Cap", augments={'Enh. Mag. eff. dur. +10',}},                                                         -- +10% duration
        body=jse.relic.body                                                                  ,                                      -- +12% duration
        hands={ name="Telchine Gloves", augments={'Pet: "Regen"+3','Enh. Mag. eff. dur. +10',}},                                    -- +10% duration. This should be replaced by empy hands during Perpetuance
        legs={ name="Telchine Braconi", augments={'Enh. Mag. eff. dur. +9',}},                                                      -- +9% duration
        feet={ name="Telchine Pigaches", augments={'Enh. Mag. eff. dur. +10',}},                                                    -- +10% duration
        neck="Incanter's Torque",                                                                                                   -- Skill
        waist="Embla Sash",                                                                                                         -- +10% duration
        left_ear="Mendi. Earring",                                                                                                  -- Conserve MP
        right_ear="Mimir Earring",                                                                                                  -- Skill
        left_ring="Stikini Ring",                                                                                                   -- Skill
        right_ring="Stikini Ring",                                                                                                  -- Skill
        back="Fi Follet Cape +1",                                                                                                   -- Skill
    }

    sets.midcast.regen = {} -- Leave this empty.

    sets.midcast.regen["Balanced"] = set_combine(sets.midcast["Enhancing Magic"], {
        main={ name="Pedagogy Staff", augments={'Path: C',}},                                                                       -- +20 regen, +15% duration
        sub="Khonsu",
        head=jse.empyrean.head,                                                                                                     -- +25% potency
        body={ name="Telchine Chas.", augments={'Pet: "Regen"+3','Enh. Mag. eff. dur. +10',}},                                      -- +10% duration AND +12 Regen effect duration
        back=jse.capes.nuking_idle,                                                                                                 -- +15 duration
    })

    sets.midcast.regen["Potency"] = set_combine(sets.midcast["Enhancing Magic"], {
        main={ name="Pedagogy Staff", augments={'Path: C',}},                                                                       -- +20 regen, +15% duration
        sub="Khonsu",
        head=jse.empyrean.head,                                                                                                     -- +25% potency
        body={ name="Telchine Chas.", augments={'Pet: "Regen"+3','Enh. Mag. eff. dur. +10',}},                                      -- +10% duration AND +12 Regen effect duration
        back=jse.capes.regen_potency,                                                                                               -- +10 base value
    })

    sets.midcast.regen["Duration"] = set_combine(sets.midcast["Enhancing Magic"], {
        main={ name="Pedagogy Staff", augments={'Path: C',}},                                                                       -- +20 regen, +15% duration
        sub="Khonsu",
        body={ name="Telchine Chas.", augments={'Pet: "Regen"+3','Enh. Mag. eff. dur. +10',}},                                      -- +10% duration AND +12 Regen effect duration
        back=jse.capes.nuking_idle,                                                                                                 -- +15 duration
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
    
    -- TODO: Full potency/conserve/cure II/etc. set

    -- Attempt at a Cure DT set.
    sets.midcast["Cure"] = { -- -49% DT, 59% Cure Potency (50% cap), +34% Conserve MP, -54-58 Enmity, 23% SIRD 
        main="Chatoyant Staff",                                                                                                     -- 10% Cure Potency
        sub="Khonsu",                                                                                                               -- -6% DT, -5 Enmity
        ammo="Staunch Tathlum",                                                                                                     -- -2% DT, 10% SIRD 
        head={ name="Vanya Hood", augments={'MP+50','"Cure" potency +7%','Enmity-6',}},                                             -- +17% Cure Potency, +6% Conserve MP, -6 Enmity
        body=jse.empyrean.body,                                                                                                     -- -13% DT, -28 Enmity
        hands="Nyame Gauntlets",                                                                                                    -- 7% DT
        legs=jse.AF.legs,                                                                                                           -- 15% Cure Potency, -6 Enmity
        feet={ name="Vanya Clogs", augments={'MP+50','"Cure" potency +7%','Enmity-6',}},                                            -- +12% Cure Potency, +6% Conserve MP, -6 Enmity
        neck="Loricate Torque +1",                                                                                                  -- -6% DT, 5% SIRD 
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                                 -- +15% Conserve MP
        left_ear="Mendi. Earring",                                                                                                  -- +2% Conserve MP, +5% Cure Potency
        right_ear="Alabaster Earring",                                                                                              -- -5% DT
        left_ring="Murky Ring",                                                                                                     -- -10% DT, 3% SIRD
        right_ring="Mephitas's Ring +1",                                                                                            -- -3-7 Enmity TODO: Needs augment for conserve MP
        back="Fi Follet Cape +1",                                                                                                   -- +5% Conserve MP, 5% SIRD
    }

    sets.midcast["Curaga"] = sets.midcast["Cure"]

    -- This will apply to any non-cure healing magic, like debuff cleanses, unless they have their own set
    sets.midcast["Healing Magic"] = { -- -59% DT, +34% Conserve MP, 33% SIRD, Haste +6%, FC +8%
        main="Daybreak",                                                                                                            -- Filler
        sub="Culminus",                                                                                                             -- 10% SIRD 
        ammo="Staunch Tathlum",                                                                                                     -- -2% DT, 10% SIRD 
        head=jse.empyrean.head,                                                                                                     -- -10% DT, Haste +6%
        body=jse.empyrean.body,                                                                                                     -- -13% DT, -28 Enmity
        hands="Nyame Gauntlets",                                                                                                    -- 7% DT
        legs=jse.empyrean.legs,                                                                                                     -- 11% DT
        feet=jse.empyrean.feet,                                                                                                     -- MEVA I guess
        neck="Loricate Torque +1",                                                                                                  -- -6% DT, 5% SIRD 
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                                 -- +15% Conserve MP
        left_ear="Mendi. Earring",                                                                                                  -- +2% Conserve MP, +5% Cure Potency
        right_ear="Etiolation Earring",                                                                                             -- Resist silence
        left_ring="Murky Ring",                                                                                                     -- -10% DT, 3% SIRD
        right_ring="Mephitas's Ring +1",                                                                                            -- -3-7 Enmity TODO: Needs augment for conserve MP
        back="Fi Follet Cape +1",                                                                                                   -- +5% Conserve MP, 5% SIRD
    }

    -- Technically this is "enhancing magic", for some godforsaken reason, so we'll just copy Healing Magic for Erase
    sets.midcast["Erase"] = sets.midcast["Healing Magic"]

    -- TODO: More healing skill - can get more Vanya
    sets.midcast["Cursna"] = set_combine(sets.idle["Normal"], {
        main={ name="Gada", augments={'Indi. eff. dur. +10','Mag. Acc.+13','"Mag.Atk.Bns."+13','DMG:+10',}},                        -- Healing skill
        sub="Genmei Shield",
        --ammo=,
        head={ name="Vanya Hood", augments={'MP+50','"Cure" potency +7%','Enmity-6',}}, -- Replace with healing skill
        body=jse.relic.body,
        --hands=,
        legs=jse.AF.legs,                                                                                                           -- Healing skill
        feet={ name="Vanya Clogs", augments={'MP+50','"Cure" potency +7%','Enmity-6',}}, -- Replace with healing skill              -- Cursna +5%
        neck="Debilis Medallion",                                                                                                   -- Cursna +15%
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
        head="Pixie Hairpin +1",
        body=jse.AF.body, 
        --hands=
        legs=jse.relic.legs,
        feet="Agwu's Pigaches",
        neck="Erra Pendant",
        waist="Fucho-no-Obi",
        left_ear="Barkaro. Earring",
        --right_ear=
        left_ring="Archon Ring",
        right_ring="Evanescence Ring",
        back={ name="Aurist's Cape +1", augments={'Path: A',}}, -- TODO: Use bookworm's cape instead
    })

    sets.midcast["Drain"] = sets.midcast["Aspir"]

    --TODO: Subtle Blow and WSD variants
    -- sets.midcast.immanence = { -- 10% PDT, 37% DT (47% PDT, 37% MDT), 36% Haste (26 Cap), 40 FC (20% FC haste)
    --     main=empty,
    --     sub="Genmei Shield",            -- 10% PDT
    --     range=empty,
    --     ammo="Staunch Tathlum",         -- 2% DT
    --     head="Null Masque",             -- 10% DT, 10% Haste
    --     body="Shango Robe",             -- 3% FC, 3% Haste
    --     hands=jse.AF.hands,             -- 9% FC, 3% Haste
    --     legs=jse.AF.legs,               -- 5% Haste
    --     feet=jse.AF.feet,               -- 12% Grimoire FC
    --     neck="Voltsurge Torque",        -- 4% FC
    --     waist="Cornelia's Belt",        -- 10% Haste
    --     left_ear="Alabaster Earring",   -- 5% DT, 5% Haste
    --     right_ear="Loquac. Earring",    -- 2% FC
    --     left_ring="Murky Ring",         -- 10% DT
    --     right_ring="Defending Ring",    -- 10% DT
    --     back="Fi Follet Cape +1",       -- 10% FC
    -- }

    sets.midcast.immanence = {          -- 53% DT (53% PDT, 53% MDT), 30% Haste (25 Cap), 56 FC (28% FC haste)
        main="Malignance Pole",                                                             -- 20% DT
        sub="Khonsu",                                                                       -- 6% DT, 4% Haste
        range=empty,
        ammo="Staunch Tathlum",                                                             -- 2% DT
        head="Null Masque",                                                                 -- 10% DT, 10% Haste
        body="Shango Robe",                                                                 -- 3% FC, 3% Haste
        hands=jse.AF.hands,                                                                 -- 9% FC, 3% Haste
        legs={ name="Psycloth Lappas", augments={'MP+80','Mag. Acc.+15','"Fast Cast"+7',}}, -- 5% Haste, 7% FC
        feet=jse.AF.feet,                                                                   -- 12% Grimoire FC
        neck="Voltsurge Torque",                                                            -- 4% FC
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                         -- 5% FC
        left_ear="Alabaster Earring",                                                       -- 5% DT, 5% Haste
        right_ear="Loquac. Earring",                                                        -- 2% FC
        left_ring="Murky Ring",                                                             -- 10% DT
        right_ring="Kishar Ring",                                                           -- 4% FC
        back="Fi Follet Cape +1",                                                           -- 10% FC
    }

    -----------------------------------------------------------
    -- JOB ABILITIES 
    ----------------------------------------------------------------

    sets.ja["Tabula Rasa"] = {
        legs=jse.relic.legs,
    }

    ----------------------------------------------------------------
    -- WEAPONSKILLS 
    ----------------------------------------------------------------
    
    -- SIM THESE
    
    sets.ws.default = {
        ammo="Amar Cluster",
        head="Jhakri Coronal +2",
        body="Nyame Mail",
        hands="Jhakri Cuffs +2",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Grunfeld Rope",
        left_ear="Moonshade Earring",
        right_ear="Odnowa Earring +1",
        left_ring="Murky Ring",
        right_ring="Defending Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Aeolian Edge"] = {
        ammo="Sroda Tathlum",
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Saevus Pendant +1",
        waist="Eschan Stone",
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Murky Ring",
        right_ring="Defending Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Black Halo"] = {
        ammo="Amar Cluster",
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Moonshade Earring",
        right_ear={ name="Arbatel Earring +1", augments={'System: 1 ID: 1676 Val: 0','Mag. Acc.+14','Enmity-4',}},
        left_ring="Murky Ring",
        right_ring="Rufescent Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Realmrazer"] = {
        ammo="Amar Cluster",
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Moonshade Earring",
        right_ear="Odnowa Earring +1",
        left_ring="Metamor. Ring +1",
        right_ring="Rufescent Ring",
        back="Null Shawl",
    }

    sets.ws["Myrkr"] = { -- No DT
        ammo="Strobilus",
        head={ name="Kaabnax Hat", augments={'HP+30','MP+30','MP+30',}},                                                                -- Want to replace with Amalric Coif +1 augmented
        body=jse.AF.body,
        hands="Otomi Gloves",
        legs=jse.empyrean.legs,                                                                                                         -- Want to replace with Amalric Slops +1 augmented
        feet={ name="Psycloth Boots", augments={'MP+50','INT+7','"Conserve MP"+6',}},
        neck="Dualism Collar +1",
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},
        left_ear="Nehalennia Earring",
        right_ear="Moonshade Earring",
        left_ring="Mephitas's Ring",
        right_ring="Mephitas's Ring +1",
        back={ name="Aurist's Cape +1", augments={'Path: A',}},
    }

    ----------------------------------------------------------------
    -- BUFF 
    ----------------------------------------------------------------

    sets.buff.sublimation = {
        head=jse.AF.head,                                                                                                               -- Sublimation +4
        body=jse.relic.body,                                                                                                            -- Sublimation +5
        waist="Embla Sash",                                                                                                             -- Sublimation +3
    }
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
    -- Choose between TP set and regular idle
    if toggle_tp == "On" and player.status == "Engaged" then
        equip_set_and_weapon(sets.melee.TP)
    else
        equip_set_and_weapon(sets.idle[idle_mode.current])

        if buffactive["Sublimation: Activated"] then
            equip(sets.buff.sublimation)
        end

        -- Speed overlay
        if toggle_speed == "On" then
            equip({right_ring="Shneddick Ring",})
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

    -- To avoid any delay in knowing that Immanence is up (I am going to STRANGLE FFXI - it won't immediately register that the buff is active, so I can't check that)
    if spell.name == "Immanence" then
        immanence = true
        add_to_chat(200, "Casting Immanence.")
        return
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

        -- Celerity/Alacrity overlay
        if (buffactive["Celerity"] or buffactive["Alacrity"]) and world.weather_element == spell.element then
            equip({feet=jse.relic.feet})
        end

        return
    end

    -- Unhandled Job Abilities
    if spell.type == "JobAbility" or ignored_spell_types:contains(spell.type) then
        -- Stay in idle.
        return
    end

    -- Unhandled Weapon Skills
    if spell.action_type == "Ability" then
        equip_set_and_weapon(sets.ws.default)
        return
    end
end

local immanence = false

-- spell.action_type == "Magic" ensures that job ability gear survives into midcast, as otherwise they won't work.
function midcast(spell)
    if spell.action_type == "Magic" then
        local matched = false

        -- To avoid any delay in knowing that Immanence is up (I am going to STRANGLE FFXI - it won't immediately register that the buff is active, so I can't check that)
        -- Redunancy check just in case
        if spell.name == "Immanence" then
            immanence = true
            return
        end

        -- If Immanence is up and the spell is either a helix or elemental magic
        -- No need to use "matched", as I don't want to overlay this at all
        if immanence and spell.skill == "Elemental Magic" then
            equip_set_and_weapon(sets.midcast.immanence)
            return
        end

        -- If the spell matches one of the match_list spells.
        for match in match_list:it() do
            if spell.name:match(match) then
                equip_set_and_weapon(sets.midcast[match])
                matched = true
                break
            end
        end

        -- If the spell is any Regen spell (not including it in the above due to it being reliant on mode)
        if not matched and spell.name:match("Regen") then
            equip_set_and_weapon(sets.midcast.regen[regen_mode.current])
            matched = true
        end

        -- If the spell name EXACTLY matches
        if not matched and sets.midcast[spell.name] then
            equip_set_and_weapon(sets.midcast[spell.name])
            matched = true
        end

        -- If the spell is a barspell
        if not matched and spell.name:match("^Bar") then
            equip_set_and_weapon(sets.midcast.barspell)
            matched = true
        end

        -- If the spell is a helix
        if not matched and helix_spells:contains(spell.name) then

            --if nuking_mode.current == "Free Nuke" or nuking_mode.current == "Burst" then
            if sets.midcast.helix[nuking_mode.current] then
                equip_set_and_weapon(sets.midcast.helix[nuking_mode.current])
            else
                -- Fallback in case we don't have a set for a helix in the given mode
                equip_set_and_weapon(sets.midcast.helix["Free Nuke"])
            end

            if spell.name:match("Noctohelix") then
                equip({head="Pixie Hairpin +1", left_ring="Archon Ring",})
            end

            if spell.name:match("Anemohelix") then
                equip({main={ name="Marin Staff +1", augments={'Path: A',}}, sub="Enki Strap",})
            end

            if spell.name:match("Luminohelix") then
                equip({main="Daybreak", sub="Ammurapi Shield",})
            end

            -- If I happen to get the item.
            -- Argute Stole +2 may be better.
            --if spell.name:match("Geohelix") then
            --    equip({neck="Quanpur Necklace"})
            --end

            matched = true
        end

        -- If the spell skill is Elemental Magic
        if not matched and spell.skill == "Elemental Magic" then
            equip_set_and_weapon(sets.midcast[nuking_mode.current])
            matched = true
        end

        if not matched and spell.skill == "Enfeebling Magic" then
            if buffactive["Dark Arts"] or buffactive["Addendum: Black"] then
                equip(sets.midcast.enfeebling_dark)
                -- Specifically because AF body gives a buff if you're in Dark Arts
                matched = true
            else
                equip(sets.midcast.enfeebling_light)
                -- Also covering the instance that you're not in any art at all for some reason
                matched = true
            end

            if spell.name == "Dispelga" then
                equip({main="Daybreak", sub="Ammurapi Shield",})
            end
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
            -- Helixes get weather bonuses 100% of the time.
            if not helix_spells:contains(spell.name) then
                equip({waist="Hachirin-no-Obi"})
            end
        end

        if is_cure and element_matches_weather then
            equip({main="Chatoyant Staff", sub="Khonsu",})
        end

        -- Ebullience/Rapture overlay. Probably somewhat redundant for Dark atm.
        if (buffactive["Ebullience"] or buffactive["Rapture"]) and (spell.type == "BlackMagic" or spell.type == "WhiteMagic") then
            equip({head=jse.empyrean.head})
        end

        -- Perpetuance overlay
        if buffactive["Perpetuance"] and spell.type == "WhiteMagic" and spell.skill == "Enhancing Magic" then
            equip({hands=jse.empyrean.hands})
        end

        -- Focalization/Altruism overlay
        if buffactive["Focalization"] or buffactive["Altruism"] then
            equip({head=jse.relic.head, waist="Null Belt"})
        end
    end
end

function aftercast(spell)
    -- If Immanence ever fails to activate somehow, the buff_change check to turn the variable off will never occur because the buff will never be gained in the first place.
    -- Thus, we check here if it was interrupted and immediately toggle the Immanence variable off again (as long as we don't already have Immanence active!).
    if spell.interrupted and spell.name == "Immanence" and not buffactive["Immanence"] then
        immanence = false
        add_to_chat(200, "Immanence failed to apply. Disabling Immanence swap.")
    end

    idle()
end

function buff_change(name, gain, buff_details)
    if not midaction() and name == "Sublimation: Activated" then
        idle()
    end

    -- Part of the "why is ping like this" solution for minimal delays in checking for Immanence
    -- I'm happy to leave this in buff_change, as Immanence wearing is less time sensitive than it being gained + this accounts for any interrupted nukes/helixes
    if name == "Immanence" and gain == true then
        add_to_chat(200, "Immanence buff is active.")
    end
    
    if name == "Immanence" and gain == false then
        immanence = false
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

    if main_command == "nukemode" then
        if sub_command == "burst" then
            nuking_mode:set("Burst")
        elseif sub_command == "freenuke" then
            nuking_mode:set("Free Nuke")
        elseif sub_command == "occultacumen" then
            nuking_mode:set("Occult Acumen")
        elseif sub_command == "vagaryburst" then
            nuking_mode:set("Vagary Burst")
        else
            nuking_mode:cycle()
        end
        add_to_chat(123, string.format("Nuking mode set to %s", nuking_mode.current))

    elseif main_command == "regenmode" then
        regen_mode:cycle()
        add_to_chat(123, string.format("Regen mode set to %s", regen_mode.current))

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
    send_command("unbind f3")
    send_command("unbind f4")
    
    send_command("unbind f5")
    send_command("unbind f6")
    send_command("unbind f7")
    send_command("unbind f8")

    send_command("unbind f9")

    send_command("unbind f12")
end