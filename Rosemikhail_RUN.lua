---@diagnostic disable: lowercase-global, undefined-global
include("Modes.lua")

----------------------------------------------------------------
-- NOTES
----------------------------------------------------------------

--[[
TO DO:
- FC set with Vallation/Valiance up (Inspiration). With 4 merits, I get 40% FC.
    - Buff check in precast
- Add priorities to everything
- Pick up /BLU and get a fuck ton of spells. See Dumo guide.
- Protect/Shell cast with Brachyura Earring or Sheltered Ring if self-cast
- SIRD set + force toggle? or just a toggle for enmity - may default to SIRD if nothing is defined for that spell?
- Parrying set when I have access to SU3

STRETCH
- Enmity mode (enmity vs safe enmity)
- Regen idle when it comes to it (Sortie...)
- SOME BLU magic IS subject to weather effects
- Swipe/Lunch JA magic burst damage
    - If I have double weather OR single weather + matching day, Hachirin-no-Obi is better than Osash
- Consider resist death things

ALL JOBS
- Sleep cry

-- When I have a bunch more gear, re-sim TP and WS sets

]]

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------

-- Modes and toggles
weapon_mode = M{"Aettir", "Naegling", "Kaja Chopper", "Kaja Axe"} -- Update these
engaged_mode = M{"Physical", "Magical", "TP"}
idle_mode = M{"Normal", "Buffs", "Phalanx"}

toggle_speed = "Off"
weapon_lock = "Off"

-- Midcast helpers
match_list = S{"Cure", "Regen"}
enmity_spells = S{"Foil", "Flash", "Sheep Song", "Stinking Gas", "Jettatura", "Geist Wall", "Blank Gaze", "Chaotic Eye", "Soporific", "Cold Wave", "Frightful Roar", "Bomb Toss", "Cursed Sphere"}

-- Bindings
send_command("bind f1 gs c idlemode normal")
send_command("bind f2 gs c idlemode buffs")
send_command("bind f3 gs c idlemode phalanx")

send_command("bind f5 gs c weaponmode")
send_command("bind f6 gs c engagedmode")

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
        "[F1-F3] Idle: %s [F5] Weapon: %s [F6] Engaged: %s [F8] Weapon Lock: %s [F9] Speed: %s",
        idle_mode.current,
        weapon_mode.current,
        engaged_mode.current,
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
    send_command("wait 5;input /lockstyleset 22") -- Ebur
end

function update_macro_book()
    send_command("input /macro book 10;input /macro set 1")
end

update_lockstyle()
update_macro_book()

-- Individual spells should be added in the following way: sets.precast["Impact"]. This goes for precast and midcast.
function get_sets()
    ----------------------------------------------------------------
    -- WEAPON SETS
    ----------------------------------------------------------------

    weapon_sets = {
        ["Aettir"] = {
            gear = {
                main="Aettir",
                sub="Khonsu", -- Potentially refined grip later
            },
            engaged_sets = {"Physical", "Magical", "TP"},
            overrides = {
                ["Magical"] = {
                    main="Aettir",
                    sub="Irenic Strap +1",
                },
                -- ["TP"] = {
                --     main="Aettir",
                --     sub="Utu Grip",
                -- },
            },
        },
        ["Naegling"] = {
            gear = {
                main="Naegling",
                sub=empty,
            },
            engaged_sets = {"Physical", "TP"},
            overrides = {},
        },
        ["Kaja Chopper"] = {
            gear = {
                main="Kaja Chopper",
                sub="Khonsu",
            },
            engaged_sets = {"Physical", "TP"},
            overrides = {},
        },
        ["Kaja Axe"] = {
            gear = {
                main="Kaja Axe",
                sub=empty,
            },
            engaged_sets = {"Physical", "TP"},
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
        head="Runeist Bandeau +3",          -- FC, Regen
        body="Runeist Coat +3",             -- Valliance/Vallation, "FC"?, Refresh swap? -- Not as good as Nyame for MEVA
        hands="Runeist Mitons +3",          -- Gambit, Enhancing Magic Skill
        legs="Runeist Trousers +3",         -- Vaguely useful in niche circumstances, yolo
        feet="Runeist Bottes +3",           -- I have these for lockstyle more than anything, thank you AF+3 voucher
    }

    jse.relic = {
        head="Futhark Bandeau +4",          -- Phalanx!!!, PDT
        body="Futhark Coat +1",             -- Elemental Sforzo, Liement
        hands="Futhark Mitons +1",          -- Maybe not as important, but used for Sleight of Sword
        legs="Futhark Trousers +1",         -- Enhancing duration, Enhancing FC, additionally 50% FC when used with Vallation/Alliance via Inspiration merit trait
        feet="Futhark Boots +1",            -- Rayke, maybe not useful for much else
    }

    jse.empyrean = {
        --head="",                          -- SIRD, Vivacious Pulse, Refresh, Enhancing duration
        --body="",                          -- Potentially good for early gear if I have the DT, enmity retention, otherwise Nyame
        --hands="",                         -- GS skill :), DT, Resistance to status ailments - use when +3
        legs="Erilaz Leg Guards +3",        -- Passive parry bonus, DT, Enmity
        --feet="",                          -- Enmity, eva/meva, resistances, 
    }

    jse.capes = {
        enmity={ name="Ogma's Cape", augments={'HP+60','Eva.+20 /Mag. Eva.+20','HP+20','Enmity+10','Damage taken-5%',}},
        parry={ name="Ogma's Cape", augments={'HP+60','Eva.+20 /Mag. Eva.+20','HP+20','Enmity+10','Parrying rate+5%',}},
        fast_cast={ name="Ogma's Cape", augments={'HP+60','Eva.+20 /Mag. Eva.+20','HP+20','"Fast Cast"+10','Phys. dmg. taken-10%',}},
        SIRD={ name="Ogma's Cape", augments={'HP+60','Eva.+20 /Mag. Eva.+20','HP+20','Enmity+10','Spell interruption rate down-10%',}},
        --VIT+30, DEF+50 supertank
        -- dimidiation
        -- savage blade
        -- resolution
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

    sets.idle["Normal"] = {                 -- 71% DT, 2% MDT, 7% PDT
        range=empty,
        ammo="Staunch Tathlum",             -- 2% DT
        head="Null Masque",                 -- 10% DT Regen +3 Refresh +1 Regain +2
        body="Adamantite Armor",            -- 20% DT
        hands="Nyame Gauntlets",            -- 7% DT
        legs="Nyame Flanchard",             -- 8% DT
        feet="Nyame Sollerets",             -- 7% DT
        neck="Loricate Torque +1",          -- 6% DT
        waist="Plat. Mog. Belt",            -- 3% DT +10% HP, Replace with Engraved Belt
        left_ear="Odnowa Earring +1",       -- 3% DT, 2% MDT
        right_ear="Tuisto Earring",
        left_ring="Gelatinous Ring +1",     -- 7% PDT
        right_ring="Moonbeam Ring",         -- 4% DT, Replace with Moonlight Ring eventually
        back="Null Shawl",
    }

    sets.idle["Buffs"] = {                  -- 68 DT, 7% PDT
        range=empty,
        ammo="Staunch Tathlum",             -- 2% DT
        head="Null Masque",                 -- 10% DT Regen +3 Refresh +1 Regain +2
        body="Adamantite Armor",            -- 20% DT
        hands="Nyame Gauntlets",            -- 7% DT
        legs="Nyame Flanchard",             -- 8% DT
        feet="Nyame Sollerets",             -- 7% DT
        neck="Loricate Torque +1",          -- 6% DT
        waist="Gishdubar Sash",
        left_ear="Brachyura Earring",
        right_ear={ name="Erilaz Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+12','Mag. Acc.+12','Damage taken-4%',}},
        left_ring="Gelatinous Ring +1",     -- 7% PDT
        right_ring="Moonbeam Ring",         -- 4% DT, Replace with Moonlight Ring eventually
        back=jse.capes.parry,
    }

    sets.idle["Phalanx"] = {
        ammo="Staunch Tathlum",
        head=jse.relic.head,
        body={ name="Herculean Vest", augments={'INT+11','Mag. Acc.+15 "Mag.Atk.Bns."+15','Phalanx +5','Accuracy+20 Attack+20',}},
        hands={ name="Herculean Gloves", augments={'CHR+8','Accuracy+26','Phalanx +5','Mag. Acc.+16 "Mag.Atk.Bns."+16',}},
        legs={ name="Herculean Trousers", augments={'Weapon skill damage +1%','Pet: Attack+13 Pet: Rng.Atk.+13','Phalanx +4','Accuracy+20 Attack+20',}},
        feet={ name="Herculean Boots", augments={'"Rapid Shot"+4','"Fast Cast"+3','Phalanx +5','Accuracy+1 Attack+1',}},
        neck="Loricate Torque +1",
        waist="Plat. Mog. Belt",
        left_ear="Odnowa Earring +1",
        right_ear="Alabaster Earring",
        left_ring="Gelatinous Ring +1",
        right_ring="Moonbeam Ring",
        back="Moonbeam Cape",
    }

    ----------------------------------------------------------------
    -- ENGAGED
    ----------------------------------------------------------------

    -- Set for if I can't force the enemies into a cone
    -- Default set for now until I get SU3
    sets.engaged["Physical"] = {            -- 76% DT, 2% MDT, 7% PDT
        range=empty,
        ammo="Staunch Tathlum",             -- 2% DT
        head="Null Masque",                 -- 10% DT Regen +3 Refresh +1 Regain +2, Replace with Empyrean +3
        body="Adamantite Armor",            -- 20% DT, Replace with Empyrean +3
        hands="Nyame Gauntlets",            -- 7% DT, Replace with Empyrean +3
        legs=jse.empyrean.legs,             -- 13% DT
        feet="Nyame Sollerets",             -- 7% DT, Replace with Empyrean +3
        neck="Loricate Torque +1",          -- 6% DT
        waist="Plat. Mog. Belt",            -- 3% DT +10% HP, Replace with Engraved Belt
        left_ear="Odnowa Earring +1",      -- 3% DT, 2% MDT
        right_ear="Tuisto Earring",
        left_ring="Gelatinous Ring +1",     -- 7% PDT
        right_ring="Moonbeam Ring",         -- 4% DT, Replace with Moonlight Ring eventually
        back=jse.capes.parry,
    }

    -- If DT needs are met, Warders Charm +1. If not, JSE neck +1/2.
    sets.engaged["Magical"] = {            -- 56% DT, 2% MDT, 7% PDT
        range=empty,
        ammo="Staunch Tathlum",             -- 2% DT
        head="Nyame Helm",                  -- 7% DT, Replace with Empyrean +3
        body="Nyame Mail",                  -- 9% DT, Replace with Empyrean +3, Consider swapping in Adamantite Armor
        hands="Nyame Gauntlets",            -- 7% DT, Replace with Empyrean +3
        legs=jse.empyrean.legs,             -- 13% DT
        feet="Nyame Sollerets",             -- 7% DT, Replace with Empyrean +3
        neck="Warder's Charm +1",
        waist="Plat. Mog. Belt",            -- 3% DT +10% HP, Replace with Engraved Belt
        left_ear="Odnowa Earring +1",       -- 3% DT, 2% MDT
        right_ear={ name="Erilaz Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+12','Mag. Acc.+12','Damage taken-4%',}}, -- 4% DT
        left_ring="Gelatinous Ring +1",     -- 7% PDT, Replace with Shadow Ring
        right_ring="Moonbeam Ring",         -- 4% DT, Replace with Moonlight Ring eventually
        back=jse.capes.parry,
    }

    -- I don't expect that I'll be using this much
    -- This probably needs work.
    sets.engaged["TP"] = {
        range=empty,
        ammo="Coiste Bodhar", -- No RP at the moment...
        head="Null Masque",
        body="Ayanmo Corazza +2",
        hands="Nyame Gauntlets",
        legs=jse.empyrean.legs,
        feet="Carmine Greaves +1",
        neck="Null Loop",
        waist="Kentarch Belt +1",
        left_ear="Cessance Earring",
        right_ear="Sherida Earring",
        left_ring="Moonbeam Ring",
        right_ring="Moonbeam Ring",
        back="Null Shawl",
    }

    -- Not sure if I'll bother having a separate max TP set. Hybrid seems cozier.

    ----------------------------------------------------------------
    -- PRECAST
    ----------------------------------------------------------------
    
    -- I am at 40% FC under Inspiration from 4/5 Merits
    -- Relic legs give +2% for every merit. Extra 8%.
    -- Potentially switch to 5/5 ?

    -- Platinum moogle belt is apparently good but needs to be a priority swap to come on first
    sets.precast.fast_cast = set_combine(sets.idle["Normal"], {
        range=empty,
        ammo="Sapience Orb",                                                                        -- 2% FC
        head=jse.AF.head,                                                                           -- 14% FC
        body="Adamantite Armor", -- Empyrean Body
        hands="Nyame Gauntlets", -- Leyline Gloves
        legs="Agwu's Slops",                                                                        -- 7% FC
        feet={ name="Carmine Greaves +1", augments={'HP+80','MP+80','Phys. dmg. taken -4',}},       -- 8% FC
        neck="Voltsurge Torque",                                                                    -- 4% FC
        waist="Plat. Mog. Belt",
        left_ear="Odnowa Earring +1",
        right_ear="Loquacious Earring",                                                             -- 2% FC
        left_ring="Gelatinous Ring +1",                                                        
        right_ring="Kishar Ring",                                                                   -- 4% FC
        back=jse.capes.fast_cast,                                                                   -- 10% FC
    })

    sets.precast.fast_cast_inspiration = set_combine(sets.idle["Normal"], {
    })

    ----------------------------------------------------------------
    -- ENMITY
    ----------------------------------------------------------------

     -- All of the JA enmity actions inherit from this set
    sets.midcast.enmity = {             -- 85 Enmity, 25% PDT
        range=empty,
        ammo="Aqreqaq Bomblet",         -- 2 Enmity
        head="Halitus Helm",            -- 8 Enmity
        body="Emet Harness +1",         -- 10 Enmity, 6% PDT
        hands="Kurys Gloves",           -- 9 Enmity, 2% DT
        legs=jse.empyrean.legs,         -- 13 Enmity, 12% DT
        feet="",                        -- Empyrean (8 Enmity, 11% DT)
        neck="Unmoving Collar +1",      -- 10 Enmity, Replace with Moonlight Necklace when I'm rich
        waist="Kasiri Belt",            -- 3 Enmity
        left_ear="Trux Earring",        -- 5 Enmity
        right_ear="Cryptic Earring",    -- 5 Enmity
        left_ring="Eihwaz Ring",        -- 5 Enmity
        right_ring="Supershear Ring",   -- 5 Enmity
        back=jse.capes.enmity,          -- 10 Enmity, 5% DT
    }

    sets.midcast["Foil"] = set_combine(sets.midcast.enmity, {
        legs=jse.relic.legs,
    })

    ----------------------------------------------------------------
    -- MAGIC
    ----------------------------------------------------------------
    
    -- Fill with duration. I guess just fill with idle/defensive pieces otherwise?
    sets.midcast["Enhancing Magic"] = { -- I assume I can just make this an enhancing duration set, which will be necessary for things like Protect, Shell and spikes
        ammo="",
        head="",
        body="",
        hands="",
        legs="",
        feet="",
        neck="",
        waist="",
        left_ear="",
        right_ear="",
        left_ring="",
        right_ring="",
        back="",
    }

    -- This is not the most elegant solution but we need barspell to be checked separately in midcast
    -- Aims are 501 skill + fill with duration
    sets.midcast.barspell = { -- Enhancing skill
        ammo="",
        head="",
        body="",
        hands="",
        legs="",
        feet="",
        neck="",
        waist="",
        left_ear="",
        right_ear="",
        left_ring="",
        right_ring="",
        back="",
    }

    sets.midcast["Aquaveil"] = sets.midcast.barspell
    sets.midcast["Temper"] = sets.midcast.barspell

    sets.midcast["Phalanx"] = {  -- This is for self-casting
        ammo="Staunch Tathlum",
        head=jse.relic.head,
        body={ name="Herculean Vest", augments={'INT+11','Mag. Acc.+15 "Mag.Atk.Bns."+15','Phalanx +5','Accuracy+20 Attack+20',}},
        hands={ name="Herculean Gloves", augments={'CHR+8','Accuracy+26','Phalanx +5','Mag. Acc.+16 "Mag.Atk.Bns."+16',}},
        legs={ name="Herculean Trousers", augments={'Weapon skill damage +1%','Pet: Attack+13 Pet: Rng.Atk.+13','Phalanx +4','Accuracy+20 Attack+20',}},
        feet={ name="Herculean Boots", augments={'"Rapid Shot"+4','"Fast Cast"+3','Phalanx +5','Accuracy+1 Attack+1',}},
        neck="Incanter's Torque",
        waist="Olympus Sash",
        left_ear="Andoaa Earring",
        right_ear="Mimir Earring",
        left_ring="Stikini Ring",
        right_ring="Stikini Ring",
        back="Moonbeam Cape", -- Replace with Merciful Cape
    }

    sets.midcast["Regen"] = {
        ammo="",
        head="",
        body="",
        hands="",
        legs="",
        feet="",
        neck="",
        waist="",
        left_ear="",
        right_ear="",
        left_ring="",
        right_ring="",
        back="",
    }

    sets.midcast["Refresh"] = {
        ammo="",
        head="",
        body="",
        hands="",
        legs="",
        feet="",
        neck="",
        waist="",
        left_ear="",
        right_ear="",
        left_ring="",
        right_ring="",
        back="",
    }

    sets.midcast["Stoneskin"] = { -- Not sure how close we can get to 500 but there are specific pieces I want here.
        ammo="",
        head="",
        body="",
        hands="",
        legs="",
        feet="",
        neck="",
        waist="",
        left_ear="",
        right_ear="",
        left_ring="",
        right_ring="",
        back="",
    }

    sets.midcast["Cure"] = {
        ammo="",
        head="",
        body="",
        hands="",
        legs="",
        feet="",
        neck="",
        waist="",
        left_ear="",
        right_ear="",
        left_ring="",
        right_ring="",
        back="",
    }

    sets.midcast.SIRD = set_combine(sets.idle["Normal"], { -- This needs to become something proper
        -- ammo="",
        -- head="",
        -- body="",
        -- hands="",
        -- legs="",
        -- feet="",
        -- neck="",
        -- waist="",
        left_ear="Halasz Earring", -- 5% SIRD
        -- right_ear="",
        -- left_ring="",
        -- right_ring="",
        -- back="",
    })

    sets.midcast["Enfeebling Magic"] = {
        ammo="",
        head="",
        body="",
        hands="",
        legs="",
        feet="",
        neck="",
        waist="",
        left_ear="",
        right_ear="",
        left_ring="",
        right_ring="",
        back="",
    }

    ----------------------------------------------------------------
    -- JOB ABILITIES 
    ----------------------------------------------------------------

    sets.ja["Valiance"] = set_combine(sets.midcast.enmity, {
        body=jse.AF.body,
        -- Needs ambuscade cape
    })

    sets.ja["Vallation"] = sets.ja["Valiance"]

    sets.ja["Liement"] = set_combine(sets.midcast.enmity, {
        body=jse.relic.body,
    })

    sets.ja["Battuta"] = set_combine(sets.midcast.enmity, {
        head=jse.relic.head,
    })

    sets.ja["Rayke"] = set_combine(sets.midcast.enmity, {
        feet=jse.relic.feet,
    })

    sets.ja["Gambit"] = set_combine(sets.midcast.enmity, {
        hands=jse.AF.hands,
    })

    sets.ja["Swordplay"] = set_combine(sets.midcast.enmity, {
        hands=jse.relic.hands,
    })

    sets.ja["One for All"] = sets.midcast.enmity -- Affected by max HP

    sets.ja["Elemental Sforzo"] = set_combine(sets.midcast.enmity, {
        body=jse.relic.body,
    })

    sets.ja["Odyllic Subterfuge"] = sets.midcast.enmity

    sets.ja["Pflug"] = sets.midcast.enmity

    -- Shove so much skill up my ass
    sets.ja["Vivacious Pulse"] = set_combine(sets.midcast.enmity, {
        -- I unno
    })

    -- TODO LATER
    -- sets.ja["Swipe"] = set_combine(sets.midcast.enmity, {
    --     -- I unno
    -- })

    -- sets.ja["Lunge"] = sets.ja["Swipe"]

    ----------------------------------------------------------------
    -- WEAPONSKILLS 
    ----------------------------------------------------------------

    -- None of these have DT yet but I can figure that out later
    sets.ws.default = {
        ranged=empty,
        ammo="Knobkierrie",
        head="Nyame Helm",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Kentarch Belt +1",
        left_ear="Odnowa Earring +1",
        right_ear="Sherida Earring",
        left_ring="Rufescent Ring",
        right_ring="Petrov Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Resolution"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head=jse.relic.head,
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs=jse.empyrean.legs,
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Sailfi Belt +1",
        left_ear="Moonshade Earring",
        right_ear="Sherida Earring",
        left_ring="Rufescent Ring",
        right_ring="Petrov Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Hard Slash"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head=jse.relic.head,
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs=jse.empyrean.legs,
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Sailfi Belt +1",
        left_ear="Moonshade Earring",
        right_ear="Sherida Earring",
        left_ring="Rufescent Ring",
        right_ring="Petrov Ring",
        back="Null Shawl",
    }

    sets.ws["Shockwave"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head="Nyame Helm",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs=jse.empyrean.legs,
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Sailfi Belt +1",
        left_ear="Cessance Earring",
        right_ear="Sherida Earring",
        left_ring="Rufescent Ring",
        right_ring="Petrov Ring",
        back="Null Shawl",
    }

    sets.ws["Herculean Slash"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head="Nyame Helm",
        body="Nyame Mail",
        hands="Agwu's Gages",
        legs="Nyame Flanchard",
        feet="Agwu's Pigaches",
        neck="Sibyl Scarf",
        waist="Orpheus's Sash",
        left_ear="Friomisi Earring",
        right_ear="Ishvara Earring",
        left_ring="Gelatinous Ring +1",
        right_ring="Petrov Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Dimidiation"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head="Nyame Helm",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Kentarch Belt +1",
        left_ear="Moonshade Earring",
        right_ear="Sherida Earring",
        left_ring="Rufescent Ring",
        right_ring="Petrov Ring",
        back="Alabaster Mantle",
    }

    -- Can't sim sword WS at the moment due to an issue with the Kastra sim
    sets.ws["Savage Blade"] = set_combine(sets.ws.default, {
        -- ammo="",
        -- head="",
        -- body="",
        -- hands="",
        -- legs="",
        -- feet="",
        -- neck="",
        -- waist="",
        -- left_ear="",
        -- right_ear="",
        -- left_ring="",
        -- right_ring="",
        -- back="",
    })

    -- Spitballing. I don't know because I can't use the sim :)
    sets.ws["Requiescat"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head="Nyame Helm",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Rumination Sash",
        left_ear="Moonshade Earring",
        right_ear="Sherida Earring",
        left_ring="Metamor. Ring +1",
        right_ring="Rufescent Ring",
        back="Alabaster Mantle",
    }

    ----------------------------------------------------------------
    -- BUFF 
    ----------------------------------------------------------------

    sets.buff.embolden = {
        back={ name="Evasionist's Cape", augments={'Enmity+4','"Embolden"+15','"Dbl.Atk."+1',}},
    }

    -- Consider separating into Holy Water on self vs Cursna received sets because if I cast Cursna on myself I may want to use Menelaus's Ring
    sets.buff.doom = {
        neck="Nicander's Necklace", -- 20% Cursna, 30% Holy Water
        waist="Gishdubar Sash", -- 10% Cursna
        --left_ring="Purity Ring", -- 7% Cursna, 7% Holy Water
        --right_ring="Blenmot's Ring +1", -- 10% Holy Water
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
    -- I don't *think* I need to care about Sublimation on Runefencer?
    -- Choose between engaged set and regular idle
    if player.status == "Engaged" then
        if engaged_mode.current == "Idle" then
            equip_set_and_weapon(sets.idle[idle_mode.current])
        else
            equip_set_and_weapon(sets.engaged[engaged_mode.current])
        end
    else
        equip_set_and_weapon(sets.idle[idle_mode.current])

        -- Speed overlay
        if toggle_speed == "On" then
            equip({right_ring="Shneddick Ring",})
        end
    end

    -- Embolden overlay
    if buffactive["Embolden"] then
        equip(sets.buff.embolden)
        return;
    end

    if buffactive["doom"] then
        equip(sets.buff.doom)
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

    --[[
    if toggle_speed == "On" then
        add_to_chat(123, "Consider disabling the speed toggle!")
    end
    ]]

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

        -- If the spell matches one of the match_list spells.
        for match in match_list:it() do
            if spell.name:match(match) then
                equip_set_and_weapon(sets.midcast[match])
                matched = true
                break
            end
        end

        -- If the spell name EXACTLY matches.
        if not matched and sets.midcast[spell.name] then
            equip_set_and_weapon(sets.midcast[spell.name])
            matched = true
        end

        if not matched and spell.name:match("^Bar") then
            equip_set_and_weapon(sets.midcast.barspell)
            matched = true
        end

        -- Enmity, maybe reorder this if I need to
        if not matched and enmity_spells:contains(spell.name) then
            equip_set_and_weapon(sets.midcast.enmity)
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

        -- Embolden overlay (for self-casting)
        if buffactive["Embolden"] and spell.skill == "Enhancing Magic" then
            equip_set_and_weapon(sets.buff.embolden)
            return;
        end
    end

    if buffactive["doom"] then
        equip(sets.buff.doom)
    end
end

function aftercast(spell)
    idle()
end

function buff_change(name, gain, buff_details)
    if not midaction() then
        if name == "Embolden" then
            idle()
        end
    end

    -- I don't care if we're midaction. Doom needs immediate action.
    if name == "doom" then
        if gain == true then
            send_command("input /p Doom.")
        elseif gain == false and player.status ~= "Dead" and player.status ~= "Engaged Dead" then
            send_command("input /p Doom is removed.")
        end

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

-- If I want to stop enabling when I don't need to, I could do a "last_mode" variable

function self_command(command)
    -- Lowercase and split
    local commandArgs = T(command:lower():split(" "))
    local main_command = commandArgs[1]
    local sub_command = commandArgs[2]

    if main_command == "idlemode" then
        if sub_command == "normal" then
            idle_mode:set("Normal")
        elseif sub_command == "buffs" then
            idle_mode:set("Buffs")
        elseif sub_command == "phalanx" then
            idle_mode:set("Phalanx")
        else
            idle_mode:cycle()
        end

        idle()

        add_to_chat(123, string.format("Idle mode set to %s", idle_mode.current))

    elseif main_command == "weaponmode" then
        weapon_mode:cycle()
        add_to_chat(123, string.format("Weapon mode set to %s", weapon_mode.current))
        update_engaged_modes(weapon_sets)
        idle()
    
    elseif main_command == "engagedmode" then
        engaged_mode:cycle()
        add_to_chat(123, string.format("Engaged mode set to %s", engaged_mode.current))
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

    send_command("unbind f8")

    send_command("unbind f9")

    send_command("unbind f12")
end