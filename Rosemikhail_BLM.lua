---@diagnostic disable: lowercase-global, undefined-global
include("Modes.lua")

----------------------------------------------------------------
-- NOTES
----------------------------------------------------------------

--[[
Todo: Become a citizen of Windurst for Sibyl Scarf

Potential enhancements:
- Add stun set loaded with recast/macc/DT
- Allow dispelga and impact during mana wall and death
- Toggle for Mana Wall set
- Doomed set
- Notification in chat when I'm slept or doomed

- Potentially build a straight up DT/meva set. Probably have Normal as a hybrid, a DT/meva set, and a refresh set.

- Casting overrides

- Probably want to rework the death functionality to allow for occult acumen casting - it'll murder my mp, but the point is to get as much TP as possible to regain mp

- Barspell stuff maybe?

- Consider a separate Aspir burst set

- Update enfeebling set

- Consider midcast enmity toggle instead of tying it only to Mana Wall Stun

- potentially add /whm capability i.e. curaga

- finish upgrading AF+4 for accuracy purposes

- Bursting set specifically for Triboulex

-- Add agwu feel to aquaveil whenever it's maxed
]]

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------

-- Modes and toggles
nuking_mode = M{"Free Nuke", "Burst", "Occult Acumen"}
weapon_mode = M{"Laevateinn", "Wizard's Rod", "Maxentius", "Daybreak", "Opashoro", "Khatvanga"} --"Marin Staff",
engaged_mode = M{}
idle_mode = M{"Normal", "Refresh"}

eat_tp = "Off"
toggle_speed = "Off"
toggle_af_body = "Off"
toggle_death = "Off"
weapon_lock = "Off"

-- Midcast helpers
match_list = S{"Cure", "Aspir", "Drain", "Regen"}
elemental_debuffs = S{'Burn','Frost','Choke','Rasp','Shock','Drown'}
cumulative_spells = S{'Stoneja','Waterja','Aeroja','Firaja','Blizzaja','Thundaja', 'Comet'}
helix_spells = S{"Geohelix", "Hydrohelix", "Anemohelix", "Pyrohelix", "Cryohelix", "Ionohelix", "Noctohelix", "Luminohelix"}
ignored_spell_types = S{"Samba", "Waltz", "Jig", "Step", "Flourish1", "Flourish2", "Scholar"}

-- Bindings
send_command("bind f1 gs c nukemode freenuke")
send_command("bind f2 gs c nukemode burst")
send_command("bind f3 gs c nukemode occultacumen")
send_command("bind f4 gs c toggleeattp")

send_command("bind f5 gs c weaponmode")
send_command("bind f6 gs c engagedmode")
send_command("bind f7 gs c idlemode")
send_command("bind f8 gs c lockweapon")

send_command("bind f9 gs c togglespeed")
send_command("bind f10 gs c toggleafbody")
send_command("bind f11 gs c toggledeath")
send_command("bind f12 gs c toggletextbox")

-- Help Text
add_to_chat(123, "F1-F3: Cycle nuking mode", "F4: Eat TP")
add_to_chat(123, "F5: Cycle weapon mode, F6: Cycle engaged mode")
add_to_chat(123, "F7: Cycle idle mode, F8: Lock weapon")
add_to_chat(123, "F9: Toggle speed gear, F10: Toggle AF body")
add_to_chat(123, "F11: Toggle Death, F12: Hide information text box")

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
        "[F1-F3] Nuking Mode: %s [F4] Eat TP: %s [F5] Weapon: %s [F6] Engaged: %s [F7] Idle: %s [F8] Weapon Lock: %s [F9] Speed: %s [F10] AF Body: %s [F11] Death: %s",
        nuking_mode.current,
        format_toggle(eat_tp),
        weapon_mode.current,
        engaged_mode.current,
        idle_mode.current,
        format_toggle(weapon_lock),
        format_toggle(toggle_speed),
        format_toggle(toggle_af_body),
        format_toggle(toggle_death)
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
    send_command("wait 5;input /lockstyleset 21") -- Furia
end

function update_macro_book()
    if player.sub_job == "SCH" then
        send_command("input /macro book 1;input /macro set 1")
    elseif player.sub_job == "DNC" then
        send_command("input /macro book 7;input /macro set 1")
    elseif player.sub_job == "SAM" then
        send_command("input /macro book 9;input /macro set 1")
    end
end

update_lockstyle()
update_macro_book()

-- Individual spells should be added in the following way: sets.precast["Impact"]. This goes for precast and midcast.
function get_sets()
    ----------------------------------------------------------------
    -- WEAPON SETS
    ----------------------------------------------------------------
    
    weapon_sets = {
        -- ["Marin Staff"] = {
        --     gear = {
        --         main={ name="Marin Staff +1", augments={'Path: A',}},
        --         sub="Enki Strap",
        --     },
        --     engaged_sets = {}, -- Use the default
        --     overrides = {},
        -- },
        ["Laevateinn"] = {
            gear = {
                main={ name="Laevateinn", augments={'Path: A',}},
                sub="Enki Strap",
            },
            engaged_sets = {"Idle", "TP", "Low Acc TP"},
            overrides = {},
        },
        ["Wizard's Rod"] = {
            gear = {
                main="Wizard's Rod",
                sub="Ammurapi Shield",
            },
            engaged_sets = {"Idle", "TP", "/DNC TP"},
            overrides = {
                ["/DNC TP"] = {
                    main="Wizard's Rod",
                    sub="Maxentius",
                },
            },
        },
        ["Maxentius"] = {
            gear = {
                main="Maxentius",
                sub="Ammurapi Shield",
            },
            engaged_sets = {"Idle", "TP", "/DNC TP"},
            overrides = {
                ["/DNC TP"] = {
                    main="Maxentius",
                    sub="Wizard's Rod",
                },
            },
        },
        ["Daybreak"] = {
            gear = {
                 main="Daybreak",
                sub="Ammurapi Shield",
            },
            engaged_sets = {}, -- Use the default
            overrides = {},
        },
        ["Opashoro"] = {
            gear = {
                main="Opashoro",
                sub="Enki Strap",
            },
            engaged_sets = {}, -- Use the default
            overrides = {},
        },
        ["Khatvanga"] = { -- Apparently good for Earth Crusher and Cataclysm because of the TP bonus, also for Death strats
            gear = {
                main="Khatvanga",
                sub="Enki Strap",
            },
            engaged_sets = {}, -- Use the default
            overrides = {},
        },
        
    }

    -- Soon Malevolence and Ammurapi Shield
    -- Consider Malignance pole for later. Though, I don't know how much I care about that when Mythic AM3 + /SAM exists.

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
        head="Spae. Petasos +1",
        body="Spae. Coat +4",
        hands="Spae. Gloves +4",
        legs="Spae. Tonban +4",
        feet="Spae. Sabots +2", -- Upgrade these for accuracy reasons
    }

    jse.relic = {
        head="Arch. Petasos +1",
        body="Arch. Coat +2",
        hands="Arch. Gloves +1",
        legs="Arch. Tonban +4",
        feet="Arch. Sabots +4",
    }

    jse.empyrean = {
        head="Wicce Petasos +3",
        body="Wicce Coat +3",
        hands="Wicce Gloves +3",
        legs="Wicce Chausses +3",
        feet="Wicce Sabots +3",
    }

    jse.capes = {
        nuking={ name="Taranus's Cape", augments={'INT+20','Mag. Acc+20 /Mag. Dmg.+20','INT+10','"Mag.Atk.Bns."+10',}},
        idle_fc={ name="Taranus's Cape", augments={'MP+60','Mag. Acc+20 /Mag. Dmg.+20','MP+20','"Fast Cast"+10','Phys. dmg. taken-10%',}},
        occult_acumen={ name="Taranus's Cape", augments={'INT+20','Mag. Acc+20 /Mag. Dmg.+20','INT+10','"Store TP"+10',}},
        death ={ name="Taranus's Cape", augments={'MP+60','Mag. Acc+20 /Mag. Dmg.+20','MP+20','"Mag.Atk.Bns."+10','Phys. dmg. taken-10%',}},
        wsd={ name="Taranus's Cape", augments={'INT+20','Mag. Acc+20 /Mag. Dmg.+20','INT+10','Weapon skill damage +10%','Phys. dmg. taken-10%',}},
        tp={ name="Taranus's Cape", augments={'DEX+20','Accuracy+20 Attack+20','Accuracy+10','"Store TP"+10','Phys. dmg. taken-10%',}}, -- Null shawl exists
        enmity ={ name="Taranus's Cape", augments={'Mag. Acc+20 /Mag. Dmg.+20','Mag. Acc.+10','Enmity+10',}},
        -- meva cape to swap into idles MP 60 (thread), meva 10 (dye), eva/meva 20 (dust), meva 15 (resin)
    }

    ----------------------------------------------------------------
    -- GEAR SETS
    ----------------------------------------------------------------
    
    sets = {}
    sets.precast = {}               -- Leave this empty
    sets.midcast = {}               -- Leave this empty
    sets.idle = {}                  -- Leave this empty
    sets.ja = {}                    -- Leave this empty
    sets.ws = {}                    -- Leave this empty
    sets.engaged = {}               -- Leave this empty
    sets.buff = {}                  -- Leave this empty

    ----------------------------------------------------------------
    -- IDLE MODES
    ----------------------------------------------------------------

    sets.idle["Normal"] = {                                                                                                                             -- OVERALL -44% DT, -10% PDT, -3% MDT (-54% DT+PDT, -47% DT+MDT), +8-9 Refresh
        ammo="Staunch Tathlum",                                                                                                                         -- -2% DT
        head={ name="Merlinic Hood", augments={'DEX+11','Pet: "Store TP"+6','"Refresh"+2','Accuracy+16 Attack+16','Mag. Acc.+4 "Mag.Atk.Bns."+4',}},    -- +2 Refresh
        body=jse.empyrean.body,                                                                                                                         -- +4 Refresh
        hands=jse.empyrean.hands,                                                                                                                       -- -12% DT
        legs="Assid. Pants +1",                                                                                                                         -- +1-2 Refresh
        feet=jse.empyrean.feet,                                                                                                                         -- -10% DT
        neck="Warder's Charm +1",
        waist="Fucho-no-Obi",                                                                                                                           -- +1 Refresh
        left_ear="Nehalennia Earring",
        right_ear="Etiolation Earring",                                                                                                                 -- -3% MDT
        left_ring="Murky Ring",                                                                                                                         -- -10% DT
        right_ring="Defending Ring",                                                                                                                    -- -10% DT
        back=jse.capes.idle_fc,                                                                                                                         -- -10% PDT
    }

    sets.idle["Refresh"] = set_combine(sets.idle["Normal"], {                                                                                           -- OVERALL -33% DT, -10% PDT, -0% MDT (-43% DT+PDT, -33% DT+MDT), +9-10 refresh
        ammo="Staunch Tathlum",                                                                                                                         -- -2% DT
        head={ name="Merlinic Hood", augments={'DEX+11','Pet: "Store TP"+6','"Refresh"+2','Accuracy+16 Attack+16','Mag. Acc.+4 "Mag.Atk.Bns."+4',}},    -- +2 Refresh
        body=jse.empyrean.body,                                                                                                                         -- -0%      +4 Refresh
        hands="Serpentes Cuffs",                                                                                                                        -- -0%      +0.5 Refresh with Serpentes Sabots
        legs="Assid. Pants +1",                                                                                                                         --          1-2 Refresh (realistically 1)
        feet="Serpentes Sabots",                                                                                                                        -- -0%      +0.5 Refresh with Serpentes Cuffs
        neck="Loricate Torque +1",                                                                                                                      -- -6% DT
        waist="Fucho-no-Obi",                                                                                                                           -- -0%      +1 Refresh -- Maybe replace with Shinjutsu-no-Obi someday according to guide
        left_ear="Nehalennia Earring",
        right_ear="Alabaster Earring",                                                                                                                  -- -5% DT
        left_ring="Murky Ring",                                                                                                                         -- -10% DT
        right_ring="Defending Ring",                                                                                                                    -- -10% DT
        back=jse.capes.idle_fc,                                                                                                                         -- -10% PDT
    })

    sets.idle["Death"] = {
        ammo={ name="Ghastly Tathlum +1", augments={'Path: A',}},
        head={ name="Kaabnax Hat", augments={'HP+30','MP+30','MP+30',}},
        body="Ros. Jaseran +1",
        hands=jse.AF.hands,
        legs=jse.AF.legs,
        feet={ name="Psycloth Boots", augments={'MP+50','INT+7','"Conserve MP"+6',}},
        neck="Dualism Collar +1",
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},
        left_ear="Nehalennia Earring",
        right_ear="Etiolation Earring",
        left_ring="Mephitas's Ring",
        right_ring="Mephitas's Ring +1",
        back=jse.capes.death,
    }

    ----------------------------------------------------------------
    -- MELEE "IDLE"
    ----------------------------------------------------------------
    
    -- Takes advantage of the AF body bonuses (with Marin Staff +1)
    -- Re-sim these sets after Laev/Gazu Bracelets/Telos Earring

    sets.engaged.TP = { -- ~100 per WS
        ammo="Amar Cluster",
        head="Null Masque",
        body=jse.AF.body,
        hands=jse.empyrean.hands,
        legs=jse.AF.legs,
        feet=jse.empyrean.feet, -- Replace with +4 AF feet (maybe, I'll lose DT)
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Crep. Earring",
        right_ear="Regal Earring", -- Replace with Telos Earring
        left_ring="Lehko's Ring",
        right_ring="Defending Ring",
        back="Null Shawl",
    }

    sets.engaged["Low Acc TP"] = { -- ~67 per WS
        ammo="Amar Cluster",
        head="Ischkur Turban",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Jhakri Slops +2",
        feet="Battlecast Gaiters",
        neck="Loricate Torque +1",
        waist="Olseni Belt",
        left_ear="Cessance Earring",
        right_ear="Alabaster Earring",
        left_ring="Lehko's Ring",
        right_ring="Petrov Ring",
        back=jse.capes.tp,
    }

    -- Sub Dancer Wiz Rod + Maxentius TP (as a treat)
    sets.engaged["/DNC TP"] = { -- ~73 per WS
        ammo="Amar Cluster",
        head="Null Masque",
        body=jse.AF.body,
        hands=jse.empyrean.hands,
        legs="Jhakri Slops +2",
        feet=jse.empyrean.feet, -- Replace with +4 AF feet
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Crep. Earring",
        right_ear="Regal Earring", -- Replace with Telos Earring
        left_ring="Lehko's Ring",
        right_ring="Defending Ring",
        back="Null Shawl",
    }
    
    -- Aims are Nyame 20B on the legs + gazu bracelets + crep earring + telos earring + laev
    -- Resimulate this when I get any one of the above items
    -- The power of AF set bonus!

    ----------------------------------------------------------------
    -- PRECAST
    ----------------------------------------------------------------

    -- Could drop the Prolix Ring and replace it with the Lebeche Ring
    sets.precast.fast_cast = {                                                                                                          -- OVERALL 83% FC, 2% Occ
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
        back=jse.capes.idle_fc,                                                                                                         -- 10% FC
    }

    sets.precast["Impact"] = set_combine(sets.precast.fast_cast, {
        head=empty,
        body="Crepuscular Cloak",
    })

    sets.precast["Death"] = set_combine(sets.precast.fast_cast, {
        hands="Agwu's Gages",
        body="Ros. Jaseran +1",
        legs={ name="Psycloth Lappas", augments={'MP+80','Mag. Acc.+15','"Fast Cast"+7',}},
        left_ring="Mephitas's Ring",
        right_ring="Mephitas's Ring +1",
        back=jse.capes.death,
    })

    sets.precast["Dispelga"] = set_combine(sets.precast.fast_cast, {
        main="Daybreak",
        sub="Genmei Shield",
    })

    ----------------------------------------------------------------
    -- NUKE MIDCAST MODES
    ----------------------------------------------------------------

    -- Assumptions are in general that I will have SCH weather + COR rolls. For bursting, I assume I have GEO bubbles.

    -- I could technically do more damage per individual nuke using some r25 Agwu's, but then I lose out on the Conserve MP + its associated damage boost from the Empyrean gear.
    -- I could use Empyrean body too, but I value infinite MP more.
    sets.midcast["Free Nuke"] = {
        ammo={ name="Ghastly Tathlum +1", augments={'Path: A',}},
        head=jse.empyrean.head,
        body=jse.AF.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck={ name="Src. Stole +2", augments={'Path: A',}},
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Freke Ring",
        right_ring={ name="Metamor. Ring +1", augments={'Path: A',}},
        back=jse.capes.nuking
    }

    -- I can come up with a set that uses Awgu's hands and feet for almost identical damage at R15. It's not really worth until R20/R25.

    -- sets.midcast["Burst"] = {                                                                                           -- 37% MB, 12% MB II
    --     ammo={ name="Ghastly Tathlum +1", augments={'Path: A',}},
    --     head="Ea Hat +1",                                                                                               -- 7% MB 7% MB II
    --     body=jse.empyrean.body,                                                                                         -- 5% MB II
    --     hands=jse.empyrean.hands,                                                                                       -- Replace with r25 Agwu's
    --     legs=jse.empyrean.legs,                                                                                         -- 15% MB
    --     feet=jse.empyrean.feet,                                                                                         -- Replace with r25 Agwu's, might even be replaceable at r23 now
    --     neck={ name="Src. Stole +2", augments={'Path: A',}},
    --     waist={ name="Acuity Belt +1", augments={'Path: A',}},
    --     left_ear="Malignance Earring",
    --     right_ear="Regal Earring",
    --     left_ring="Freke Ring",
    --     right_ring={ name="Metamor. Ring +1", augments={'Path: A',}},                                                   -- Replace with Mujin Band
    --     back=jse.capes.nuking                                                                                           -- 5% MB
    -- }

    sets.midcast["Burst"] = {                                                                                           -- 51% MB (40% cap), 22% MB II
        ammo={ name="Ghastly Tathlum +1", augments={'Path: A',}},
        head="Ea Hat +1",                                                                                               -- 7% MB, 7% MB II
        body=jse.empyrean.body,                                                                                         -- 5% MB II
        hands="Agwu's Gages",                                                                                           -- 8% MB, 5% MB II (R25)
        legs=jse.empyrean.legs,                                                                                         -- 15% MB
        feet="Agwu's Pigaches",                                                                                         -- 6% MB
        neck={ name="Src. Stole +2", augments={'Path: A',}},
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Freke Ring",
        right_ring="Mujin Band",                                                                                        -- 5% MB II
        back=jse.capes.nuking                                                                                           -- 5% MB
    }

    sets.midcast["Occult Acumen"] = set_combine(sets.midcast["Free Nuke"], {
        ammo="Seraphic Ampulla",
        head="Mallquis Chapeau +2",
        body={ name="Merlinic Jubbah", augments={'"Occult Acumen"+11','INT+7','Mag. Acc.+15','"Mag.Atk.Bns."+15',}},
        hands={ name="Merlinic Dastanas", augments={'Mag. Acc.+19','"Occult Acumen"+11','MND+5',}},
        legs= "Perdition Slops",
        feet="Battlecast Gaiters",
        neck={ name="Src. Stole +2", augments={'Path: A',}},
        waist="Oneiros Rope",
        left_ear="Cessance Earring",
        right_ear="Crep. Earring",
        left_ring="Petrov Ring",
        right_ring="Lehko's Ring",
        back=jse.capes.occult_acumen,
    })

    sets.midcast.death_burst = set_combine(sets.midcast["Burst"], {
        ammo={ name="Ghastly Tathlum +1", augments={'Path: A',}},
        head="Pixie Hairpin +1",
        hands="Agwu's Gages",
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},
        left_ear="Barkaro. Earring",
        left_ring="Archon Ring",
        right_ring="Mephitas's Ring +1",
        back=jse.capes.death,
    })

    sets.midcast.death_free_nuke = set_combine(sets.midcast["Free Nuke"], {
        ammo={ name="Ghastly Tathlum +1", augments={'Path: A',}},
        head="Pixie Hairpin +1",
        hands={ name="Amalric Gages +1", augments={'INT+12','Mag. Acc.+20','"Mag.Atk.Bns."+20',}},
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},
        left_ear="Barkaro. Earring",
        left_ring="Archon Ring",
        right_ring="Mephitas's Ring +1",
        back=jse.capes.death,
    })
    
    ----------------------------------------------------------------
    -- DAMAGE MIDCAST
    ----------------------------------------------------------------

    sets.midcast["Meteor"] = set_combine(sets.midcast["Free Nuke"], {
        ammo={ name="Ghastly Tathlum +1", augments={'Path: A',}},
        body=jse.relic.body,
        hands=jse.AF.hands,                                            -- Replace with +3 Archmage hands if and when I get them...
        feet=jse.relic.feet,
        left_ear="Ilmr Earring",
    })

    sets.midcast["Comet"] = set_combine(sets.midcast["Free Nuke"], {
        head="Pixie Hairpin +1",
        left_ring="Archon Ring",
    })

    ----------------------------------------------------------------
    -- ENFEEBLING MIDCAST
    ----------------------------------------------------------------

    -- Eventually when I have more Wicce upgraded, they may end up beating out the Spaekona macc bonuses.
    sets.midcast["Enfeebling Magic"] = {
        ammo="Pemphredo Tathlum",
        head=empty,
        body={ name="Cohort Cloak +1", augments={'Path: A',}},
        hands=jse.AF.hands,
        legs=jse.AF.legs,
        feet=jse.AF.feet,
        neck={ name="Src. Stole +2", augments={'Path: A',}},
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Malignance Earring",
        right_ear={ name="Wicce Earring +1", augments={'System: 1 ID: 1676 Val: 0','Mag. Acc.+13','Enmity-3',}},
        left_ring="Kishar Ring",
        right_ring="Stikini Ring",
        back={ name="Aurist's Cape +1", augments={'Path: A',}},
    }

    -- Eventually this prefers Wicce+3 head and Spae body for the slightly higher elemental magic skill + accuracy, it seems...
    sets.midcast.elemental_debuff = {
        ammo="Pemphredo Tathlum",
        head=empty,
        body={ name="Cohort Cloak +1", augments={'Path: A',}},
        hands=jse.AF.hands,
        legs=jse.relic.legs,
        feet=jse.relic.feet,
        neck={ name="Src. Stole +2", augments={'Path: A',}},
        waist={ name="Acuity Belt +1", augments={'Path: A',}},
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Stikini Ring",
        right_ring="Stikini Ring",
        back={ name="Aurist's Cape +1", augments={'Path: A',}},
    }

    sets.midcast["Dispelga"] = set_combine(sets.midcast["Enfeebling Magic"], {
        main="Daybreak",
        sub="Ammurapi Shield",
    })
    
    -- Impact likes more elemental magic skill
    sets.midcast["Impact"] = {
        ammo="Pemphredo Tathlum",
        head=empty,
        body="Crepuscular Cloak",
        hands=jse.AF.hands,
        legs=jse.AF.legs,
        feet=jse.relic.feet,
        neck={ name="Src. Stole +2", augments={'Path: A',}},
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
    
    -- Could add Gada and Ammurapi if I felt special and cool and didn't mind losing TP
    sets.midcast["Enhancing Magic"] = set_combine(sets.midcast["Free Nuke"], {                                                      -- +59% duration
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

    -- Not sure whether to go for duration or potency, but probably the latter
    sets.midcast["Regen"] = set_combine(sets.midcast["Enhancing Magic"], {
        main="Bolelabunga",                                                                                                         -- 10% potency
    })

    sets.midcast["Stoneskin"] = set_combine(sets.midcast["Enhancing Magic"], {
        legs="Shedir Seraweels",                                                                                                    -- +35 Stoneskin
        neck="Nodens Gorget",                                                                                                       -- +30 Stoneskin
    })

    sets.midcast["Aquaveil"] = set_combine(sets.midcast["Enhancing Magic"], {                                                       -- +1 Aquaveil, 96% SIRD
        ammo="Staunch Tathlum",                                                                                                     -- 10% SIRD
        head="Agwu's Cap",                                                                                                          -- 10% SIRD
        body="Ros. Jaseran +1",                                                                                                     -- 25% SIRD
        hands={ name="Amalric Gages +1", augments={'INT+12','Mag. Acc.+20','"Mag.Atk.Bns."+20',}},                                  -- 11% SIRD
        legs="Shedir Seraweels",                                                                                                    -- +1 Aquaveil
        feet="Agwu's Pigaches",                                                                                                     -- 5% SIRD
        neck="Loricate Torque +1",                                                                                                  -- 5% SIRD
        waist="Rumination Sash",                                                                                                    -- 10% SIRD
        left_ring="Freke Ring",                                                                                                     -- 10% SIRD
        right_ring="Evanescence Ring",                                                                                              -- 5% SIRD
        back="Fi Follet Cape +1",                                                                                                   -- 5% SIRD
    })

    ----------------------------------------------------------------
    -- HEALING MIDCAST
    ----------------------------------------------------------------

    -- TODO: Check out the BLM guide for a set that doesn't require a weapon swap for curing.
    sets.midcast["Cure"] = {                                                                 -- Overall +50%
        main="Daybreak",                                                                                                            -- 30%
        sub="Genmei Shield",
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
        back={ name="Aurist's Cape +1", augments={'Path: A',}},
    }

    -- TODO: Steal whatever SCH has but otherwise idle is enough for now
    -- This will apply to any non-cure healing magic, like debuff cleanses, unless they have their own set
    sets.midcast["Healing Magic"] = sets.idle["Normal"]

    -- Technically this is "enhancing magic", for some godforsaken reason
    sets.midcast["Erase"] = sets.midcast["Healing Magic"]

    -- TODO: More healing skill - can get more Vanya
    sets.midcast["Cursna"] = set_combine(sets.idle["Normal"], {
        main={ name="Gada", augments={'Indi. eff. dur. +10','Mag. Acc.+13','"Mag.Atk.Bns."+13','DMG:+10',}},                        -- Healing skill
        sub="Genmei Shield",
        --ammo=,
        head={ name="Vanya Hood", augments={'MP+50','"Cure" potency +7%','Enmity-6',}}, -- Replace with healing skill
        --body=,
        --hands=,
        --legs=,                                                                                                                    -- Healing skill
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
        ammo="Pemphredo Tathlum",
        head="Pixie Hairpin +1",
        body="Shango Robe",
        hands=jse.relic.hands,
        legs=jse.AF.legs,
        feet="Agwu's Pigaches",
        neck="Erra Pendant",
        waist="Fucho-no-Obi",
        left_ear="Barkaro. Earring",
        --right_ear="Barkaro. Earring",
        left_ring="Archon Ring",
        right_ring="Evanescence Ring",
        back={ name="Aurist's Cape +1", augments={'Path: A',}},
    })

    sets.midcast["Drain"] = sets.midcast["Aspir"]

    ----------------------------------------------------------------
    -- JOB ABILITIES 
    ----------------------------------------------------------------

    sets.ja["Manafont"] = {
        body=jse.relic.body,
    }

    sets.ja["Mana Wall"] = {                                                                                            -- OVERALL -57% DT, -10% PDT
        ammo="Staunch Tathlum",                                                                                         -- -2% DT
        head=jse.empyrean.head,                                                                                         -- -10% DT
        body=jse.AF.body,
        hands=jse.empyrean.hands,                                                                                       -- -12% DT
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,                                                                                         -- -10% DT
        neck="Unmoving Collar +1",
        waist="Plat. Mog. Belt",                                                                                        -- -3% DT
        left_ear="Malignance Earring",                                                                                  -- Soon replaced but I won't say no to more damage during mana wall
        right_ear="Ethereal Earring",                                                                                   -- Damage to MP
        left_ring="Murky Ring",                                                                                         -- -10% DT
        right_ring="Defending Ring",                                                                                    -- -10% DT
        back=jse.capes.idle_fc,                                                                                         -- -10% PDT
    }

    sets.midcast.stun_enmity = set_combine(sets.ja["Mana Wall"], {                                                      -- OVERALL +35 enmity, 27% Haste (cap 25%), 24 FC (12% recast)
        ammo="Staunch Tathlum",                                                                                         -- -2% DT
        head="Null Masque",                                                                                             -- -10% DT, 10% Haste
        --body=jse.empyrean.body,                                                                                       -- 3% Haste (More macc than Agwu's Robe)
        body="Agwu's Robe",                                                                                             -- 3% Haste, 8 FC
        hands=jse.empyrean.hands,                                                                                       -- -12% DT, 3% Haste
        legs=jse.empyrean.legs,                                                                                         -- 5% Haste
        --feet=jse.empyrean.feet,                                                                                       -- -10% DT, -16 enmity, 3% Haste
        feet={ name="Merlinic Crackows", augments={'"Fast Cast"+6','CHR+2','Mag. Acc.+8','"Mag.Atk.Bns."+11',}},        -- 3% Haste, 11% FC
        neck="Unmoving Collar +1",                                                                                      -- +10 enmity
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},                                                     -- 5% FC
        left_ear="Cryptic Earring",                                                                                     -- +4 enmity 
        right_ear="Friomisi Earring",                                                                                   -- +2 enmity
        left_ring="Eihwaz Ring",                                                                                        -- +5 enmity
        right_ring="Petrov Ring",                                                                                       -- +4 enmity TODO: Replace with Supershear
        back=jse.capes.enmity                                                                                           -- +10 enmity
    })

    -- sets.midcast.stun_enmity = set_combine(sets.ja["Mana Wall"], {  -- OVERALL +35 enmity -35 enmity = 0, 17% Haste (cap 25%)
    --     ammo="Staunch Tathlum",                                     -- -2% DT
    --     head=jse.empyrean.head,                                     -- -10 enmity, 6% Haste
    --     body=jse.AF.body,                                           -- -9 enmity, 3% Haste
    --     hands=jse.empyrean.hands,                                   -- -12% DT, 3% Haste
    --     legs=jse.empyrean.legs,                                     -- 5% Haste, 3% Haste
    --     feet=jse.empyrean.feet,                                     -- -10% DT, -16 enmity
    --     neck="Unmoving Collar +1",                                  -- +10 enmity
    --     waist="Plat. Mog. Belt",                                    -- -3% DT
    --     left_ear="Cryptic Earring",                                 -- +4 enmity 
    --     right_ear="Friomisi Earring",                               -- +2 enmity
    --     left_ring="Eihwaz Ring",                                    -- +5 enmity
    --     right_ring="Petrov Ring",                                   -- +4 enmity TODO: Replace with Supershear
    --     back=jse.capes.enmity                                       -- +10 enmity
    -- })

    -- Worth noting that the BLM guide for some reason uses Wicce pieces in the enmity set, but that has huge enmity decreases
    -- I guess it's for Mana Wall but that seems silly!!!!!! May replace with other high accuracy haste pieces

    ----------------------------------------------------------------
    -- WEAPONSKILLS - STAFF
    ----------------------------------------------------------------

    sets.ws.default = { -- Generic physical
        ammo="Amar Cluster",
        head=jse.empyrean.head,
        body=jse.AF.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Moonshade Earring",
        right_ear="Cessance Earring",
        left_ring="Murky Ring",
        right_ring="Rufescent Ring",
        back="Null Shawl",
    }

    sets.ws["Rock Crusher"] = {
        ammo="Oshasha's Treatise",
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Saevus Pendant +1",
        waist="Eschan Stone", -- Maybe Orpheus's Sash?
        left_ear="Moonshade Earring",
        right_ear="Malignance Earring",
        left_ring="Murky Ring",
        right_ring="Freke Ring",
        back=jse.capes.wsd, -- Want STR +MACC/MDMG -10PDT WSD cape
    }

    sets.ws["Starburst"] = sets.ws["Rock Crusher"]

    sets.ws["Vidohunir"] = { -- Potentially resim now that I have agwus
        ammo="Ghastly Tathlum +1",
        head="Pixie Hairpin +1",
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck={ name="Src. Stole +2", augments={'Path: A',}},
        waist="Orpheus's Sash",
        left_ear="Malignance Earring",
        right_ear="Regal Earring",
        left_ring="Murky Ring",
        right_ring="Archon Ring",
        back=jse.capes.wsd,
    }

    sets.ws["Retribution"] = {
        ammo="Oshasha's Treatise",
        head=jse.empyrean.head,
        body=jse.AF.body,
        hands=jse.AF.hands,
        legs=jse.AF.legs,
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Odnowa Earring +1",
        right_ear="Regal Earring",
        left_ring="Murky Ring",
        right_ring="Rufescent Ring",
        back=jse.capes.wsd,
    }

    sets.ws["Myrkr"] = { -- No DT
        ammo="Strobilus",
        head={ name="Kaabnax Hat", augments={'HP+30','MP+30','MP+30',}},                                                                -- Want to replace with Amalric Coif +1 augmented
        body={ name="Amalric Doublet +1", augments={'MP+80','Mag. Acc.+20','"Mag.Atk.Bns."+20',}},
        hands="Otomi Gloves",
        legs=jse.AF.legs,                                                                                                               -- Want to replace with Amalric Slops +1 augmented
        feet={ name="Psycloth Boots", augments={'MP+50','INT+7','"Conserve MP"+6',}},
        neck="Dualism Collar +1",
        waist={ name="Shinjutsu-no-Obi +1", augments={'Path: A',}},
        left_ear="Moonshade Earring",
        right_ear="Nehalennia Earring",
        left_ring="Mephitas's Ring",
        right_ring="Mephitas's Ring +1",
        back=jse.capes.idle_fc,
    }

    ----------------------------------------------------------------
    -- WEAPONSKILLS - CLUB
    ----------------------------------------------------------------

    sets.ws["Shining Strike"] = {  -- Use Daybreak
        ammo="Oshasha's Treatise",
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Saevus Pendant +1",
        waist="Eschan Stone", -- Maybe Orpheus's Sash?
        left_ear="Moonshade Earring",
        right_ear="Malignance Earring",
        left_ring="Murky Ring",
        right_ring="Freke Ring",
        back=jse.capes.wsd,
    }
    
    sets.ws["Black Halo"] = {  -- Use Maxentius
        ammo="Oshasha's Treatise",
        head="Null Masque",
        body=jse.AF.body,
        hands=jse.AF.hands,
        legs=jse.AF.legs,
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Moonshade Earring",
        right_ear="Regal Earring",
        left_ring="Murky Ring",
        right_ring="Defending Ring",
        back="Null Shawl",
    }

    sets.ws["Realmrazer"] = {  -- Use Maxentius
        ammo="Amar Cluster",
        head=jse.empyrean.head,
        body=jse.AF.body,
        hands=jse.AF.hands,
        legs=jse.AF.legs,
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Moonshade Earring",
        right_ear="Regal Earring",
        left_ring="Murky Ring",
        right_ring="Defending Ring",
        back="Null Shawl",
    }
    ----------------------------------------------------------------
    -- WEAPONSKILLS - OTHER
    ----------------------------------------------------------------

    sets.ws["Aeolian Edge"] = { -- Use Malevolence
        ammo="Oshasha's Treatise",
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Saevus Pendant +1",
        waist="Eschan Stone",
        left_ear="Moonshade Earring",
        right_ear="Malignance Earring",
        left_ring="Murky Ring",
        right_ring="Freke Ring",
        back=jse.capes.wsd,
    }

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

-- Sublimation won't apply the overlay if we're currently TPing.
function idle()
    if buffactive["Mana Wall"] then
        equip_set_and_weapon(sets.ja["Mana Wall"])
        return
    end

    if toggle_death == "On" then
        equip_set_and_weapon(sets.idle["Death"])
        return
    end

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

        -- Speed overlay
        if toggle_speed == "On" then
            equip({right_ring="Shneddick Ring",})
        end
    end

    -- Eat TP so that we can use AM2
    if eat_tp == "On" then 
        equip({neck="Chrysopoeia Torque",})
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

    local function equip_if_ja_match(spell_name)
        if sets.ja[spell_name] then
            equip_set_and_weapon(sets.ja[spell_name])
            return true
        end
        return false
    end

    -- Death
    if toggle_death == "On" and spell.name ~= "Myrkr" then -- I want to allow Myrkr, as that has more MP than my precast
        if spell.type == "JobAbility" then
            if equip_if_ja_match(spell.name) then
                -- Stay in Death idle
                return
            end
        end

        if spell.action_type == "Magic" then
            equip_set_and_weapon(sets.precast["Death"])
        end

        -- Do nothing with weapon skills
        return
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

-- spell.action_type == "Magic" ensures that job ability gear survives into midcast, as otherwise they won't work.
function midcast(spell)
    if spell.action_type == "Magic" then
        -- Mana Wall
        if buffactive["Mana Wall"] then
            if spell.name == "Stun" then
                equip_set_and_weapon(sets.midcast.stun_enmity)
            else
                equip_set_and_weapon(sets.ja["Mana Wall"])
            end
            return
        end

        -- Early return Death to avoid overlays
        if toggle_death == "On" then
            if nuking_mode.current == "Burst" then
                equip_set_and_weapon(sets.midcast.death_burst)
            else
                equip_set_and_weapon(sets.midcast.death_free_nuke)
            end
            return
        end

        local matched = false

        -- If the spell matches one of the match_list spells.
        -- If I ever have to break up these spells into separate sets, it would be worth breaking this up.
        for match in match_list:it() do
            if spell.name:match(match) then
                equip_set_and_weapon(sets.midcast[match])
                matched = true
                break
            end
        end

        -- If we're casting Death even if we're not in the Death mode (why tho)
        if not matched and spell.name == "Death" then
            if nuking_mode.current == "Burst" then
                equip_set_and_weapon(sets.midcast.death_burst)
            else
                equip_set_and_weapon(sets.midcast.death_free_nuke)
            end

            matched = true
        end

        -- If the spell name EXACTLY matches.
        if not matched and sets.midcast[spell.name] then
            equip_set_and_weapon(sets.midcast[spell.name])
            matched = true
        end

        -- If the spell name is contained within elemental debuffs
        if not matched and elemental_debuffs:contains(spell.name) then
            equip_set_and_weapon(sets.midcast.elemental_debuff)
            matched = true
        end

        -- If the spell skill is Elemental Magic
        if not matched and spell.skill == "Elemental Magic" then
            equip_set_and_weapon(sets.midcast[nuking_mode.current])
            matched = true

            -- Empyrean leg overlay
            if cumulative_spells:contains(spell.name) then
                equip({legs=jse.empyrean.legs})
            end

            -- AF body overlay
            if toggle_af_body == "On" and spell.skill == "Elemental Magic" then
                equip({body=jse.AF.body})
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

        if (valid_obi_skill or is_cure) and element_matches_day_or_weather and spell.element ~= "None" and nuking_mode.current ~= "Occult Acumen" then
            -- Helixes get weather bonuses 100% of the time.
            if not helix_spells:contains(spell.name) then
                equip({waist="Hachirin-no-Obi"})
            end
        end

        if is_cure and element_matches_weather then
            equip({main="Chatoyant Staff", sub="Khonsu",})
        end
    end
end

function aftercast(spell)
    -- Gearswap will not immediately register Mana Wall's activation, so we skip this and wait for buff_change to handle the swap.
    if spell.name == "Mana Wall" then
        return
    end

    idle()
end

function buff_change(name, gain, buff_details)
    if not midaction() then
        -- We wait until here to select gear, as Gearswap doesn't immediately register Mana Wall in aftercast.
        if name == "Mana Wall" then
            idle()
        end

        if name == "Sublimation: Activated" then
            idle() 
        end
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

local last_weapon_mode = ""

function self_command(command)
    -- Lowercase and split
    local commandArgs = T(command:lower():split(" "))
    local main_command = commandArgs[1]
    local sub_command = commandArgs[2]

    -- Not the most ideal code especially with consideration towards occult acumen, probably
    if main_command == "nukemode" then
        if sub_command == "burst" then
            if nuking_mode.current == "Occult Acumen" then
                weapon_mode:set(last_weapon_mode)
            end
            nuking_mode:set("Burst")
            --idle()

        elseif sub_command == "freenuke" then
            if nuking_mode.current == "Occult Acumen" then
                weapon_mode:set(last_weapon_mode)
            end
            nuking_mode:set("Free Nuke")
            --idle()

        elseif sub_command == "occultacumen" then
            if nuking_mode.current ~= "Occult Acumen" then
                last_weapon_mode = weapon_mode.current
            end
            weapon_mode:set("Khatvanga")
            nuking_mode:set("Occult Acumen")
            --idle()
        else
            nuking_mode:cycle()
            --idle()
        end

        idle()

        add_to_chat(123, string.format("Nuking mode set to %s", nuking_mode.current))

    elseif main_command == "toggleeattp" then
        eat_tp = handle_toggle(eat_tp, "Eat TP")
        idle()

    elseif main_command == "weaponmode" then
        weapon_mode:cycle()
        last_weapon_mode = weapon_mode.current -- So Occult Acumen doesn't swap us back to an old mode if we switch during it for some reason
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

    elseif main_command == "toggleafbody" then
        toggle_af_body = handle_toggle(toggle_af_body, "AF Body")
        -- Midcast so no need to idle()

    elseif main_command == "toggledeath" then
        toggle_death = handle_toggle(toggle_death, "Death")
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
    send_command("unbind f10")
    send_command("unbind f11")
    send_command("unbind f12")
end