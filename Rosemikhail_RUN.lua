---@diagnostic disable: lowercase-global, undefined-global
include("Modes.lua")

----------------------------------------------------------------
-- NOTES
----------------------------------------------------------------

--[[
TO DO:

-- How to approach SIRD... I could have a straight SIRD toggle for I MUST CAST THIS NOW, and then a separate line (perhaps default line) for spells that otherwise don't have a set to be casted in SIRD
-- Actually nah I don't want to "by default" cast in SIRD for anything. I'll just have it as a toggle for when I need it. Aquaveil got me :)
- Automatic mode maybe. If Aquaveil is NOT up, casting most is automatically SIRD mode. Turn this mode off when Aquaveil is up.

- FC set with Vallation/Valiance up (Inspiration).
    - Buff check in precast
- Pick up /BLU and get a fuck ton of spells. See Dumo guide.
- Protect/Shell cast with Brachyura Earring or Sheltered Ring if self-cast
- For enmity sird, foil may need to become an overlay in midcast, though maybe not for SIRD reasons
- Parrying set when I have access to SU3
- Potentially healing magic sets i.e. Cursna
- Needle the enmity cape to have PDT instead probably

STRETCH
- Enmity mode (enmity vs safe enmity)
- Regen idle when it comes to it (Sortie...)
- SOME BLU magic IS subject to weather effects
- Swipe/Lunch JA magic burst damage
    - If I have double weather OR single weather + matching day, Hachirin-no-Obi is better than Osash
    - Need a check for Tenebrae or Lux (I don't have the weatherspoon ring though)
    For melee range stuff like Lunge/Swipe or elemental weaponskills
        If weather = double, hachirin-no-obi
        Or if weather + day is matching, hachirin no obi
        Otherwise, osash
        world.weather_intensity 0-2
- Consider ACC sets - idk how this works for WS though!
- Potentially Flume Belt as a toggle for MP

- Consider resist death resist toggle
-- I don't *think* I need to care about Sublimation on Runefencer?

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
SIRD = "Off"

-- Midcast helpers
match_list = S{"Cure", "Regen"}
enmity_spells = S{
    "Foil",
    "Flash",
    "Sheep Song",
    "Stinking Gas",
    "Jettatura",
    "Geist Wall",
    "Blank Gaze",
    "Chaotic Eye",
    "Soporific",
    "Cold Wave",
    "Frightful Roar",
    "Bomb Toss",
    "Cursed Sphere",
    "Stun",
    "Poisonga"}

-- Bindings
send_command("bind f1 gs c idlemode normal")
send_command("bind f2 gs c idlemode buffs")
send_command("bind f3 gs c idlemode phalanx")

send_command("bind f5 gs c weaponmode")
send_command("bind f6 gs c engagedmode")

send_command("bind f8 gs c lockweapon")

send_command("bind f9 gs c togglespeed")
send_command("bind f10 gs c sird")
send_command("bind f12 gs c toggletextbox")

-- Help Text
add_to_chat(123, "F1-F3: Idle Modes")
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
        "[F1-F3] Idle: %s [F5] Weapon: %s [F6] Engaged: %s [F8] Weapon Lock: %s [F9] Speed: %s [F10] SIRD: %s",
        idle_mode.current,
        weapon_mode.current,
        engaged_mode.current,
        format_toggle(weapon_lock),
        format_toggle(toggle_speed),
        format_toggle(SIRD)
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
    if player.sub_job == "SCH" then
        send_command("input /macro book 10;input /macro set 1")
    elseif player.sub_job == "DRK" then
        send_command("input /macro book 11;input /macro set 1")
    elseif player.sub_job == "BLU" then
        send_command("input /macro book 12;input /macro set 1")
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
        ["Aettir"] = {
            gear = {
                main="Aettir",
                sub="Refined Grip +1",
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
            engaged_sets = {"Physical", "Magical", "TP"},
            overrides = {},
        },
        ["Kaja Chopper"] = {
            gear = {
                main="Kaja Chopper",
                sub="Refined Grip +1",
            },
            engaged_sets = {"Physical", "Magical", "TP"},
            overrides = {},
        },
        ["Kaja Axe"] = {
            gear = {
                main="Kaja Axe",
                sub=empty,
            },
            engaged_sets = {"Physical", "Magical", "TP"},
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
        head={name="Runeist Bandeau +3", priority=109},         -- FC, Regen
        body={name="Runeist Coat +3", priority=218},            -- Valliance/Vallation, "FC"?, Refresh swap? -- Not as good as Nyame for MEVA
        hands={name="Runeist Mitons +3", priority=85},          -- Gambit, Enhancing Magic Skill
        legs={name="Runeist Trousers +3", priority=80},         -- Vaguely useful in niche circumstances, yolo
        feet={name="Runeist Bottes +3", priority=74},           -- I have these for lockstyle more than anything, thank you AF+3 voucher
    }

    jse.relic = {
        head={name="Fu. Bandeau +4", priority=66},              -- Phalanx!!!, PDT
        body={name="Futhark Coat +1", priority=99},             -- Elemental Sforzo, Liement
        hands={name="Futhark Mitons +3", priority=45},          -- Maybe not as important, but used for Sleight of Sword
        legs={name="Futhark Trousers +2", priority=97},         -- Enhancing duration, Enhancing FC, additionally 50% FC when used with Vallation/Alliance via Inspiration merit trait
        feet={name="Futhark Boots +1", priority=13},            -- Rayke, maybe not useful for much else
    }

    jse.empyrean = {
        head={name="Erilaz Galea +3", priority=111},            -- SIRD, Vivacious Pulse, Refresh, Enhancing duration
        body={name="Erilaz Surcoat +3", priority=143},          -- Potentially good for early gear if I have the DT, enmity retention, otherwise Nyame
        hands={name="Erilaz Gauntlets +3", priority=59},        -- GS skill :), DT, Resistance to status ailments - use when +3
        legs={name="Erilaz Leg Guards +3", priority=100},       -- Passive parry bonus, DT, Enmity
        feet={name="Erilaz Greaves +3", priority=48},           -- Enmity, eva/meva, resistances, 
    }

    jse.capes = {
        enmity={ name="Ogma's Cape", augments={'HP+60','Eva.+20 /Mag. Eva.+20','HP+20','Enmity+10','Damage taken-5%',}, priority=80},
        parry={ name="Ogma's Cape", augments={'HP+60','Eva.+20 /Mag. Eva.+20','HP+20','Enmity+10','Parrying rate+5%',}, priority=80},
        fast_cast={ name="Ogma's Cape", augments={'HP+60','Eva.+20 /Mag. Eva.+20','HP+20','"Fast Cast"+10','Phys. dmg. taken-10%',}, priority=80},
        SIRD={ name="Ogma's Cape", augments={'HP+60','Eva.+20 /Mag. Eva.+20','HP+20','Enmity+10','Spell interruption rate down-10%',}, priority=80},
        -- SIRD enmity cape
        -- Potentially a supertank cape with DEF n stuff check guide
        -- MEVA cape INT+20, Eva/Meva, Meva+25, Enmity
        -- TP cape
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

    sets.idle["Normal"] = {                                         -- 72% DT, 2% MDT, 7% PDT
        range=empty,
        ammo="Staunch Tathlum",                                     -- 2% DT
        head={name="Null Masque", priority=100},                    -- 10% DT Regen +3 Refresh +1 Regain +2
        body={name="Adamantite Armor", priority=182},               -- 20% DT
        hands={name="Nyame Gauntlets", priority=91},                -- 7% DT
        legs={name="Nyame Flanchard", priority=114},                -- 8% DT
        --feet={name="Nyame Sollerets", priority=68},               -- 7% DT
        feet=jse.empyrean.feet,                                     -- 11% DT, +35 all resistances
        neck="Loricate Torque +1",                                  -- 6% DT
        --waist={name="Plat. Mog. Belt", priority=1000},             -- 3% DT +10% HP, Replace with Engraved Belt
        waist="Engraved Belt",
        left_ear={name="Odnowa Earring +1", priority=110},          -- 3% DT, 2% MDT
        right_ear={name="Tuisto Earring", priority=150},
        left_ring={name="Gelatinous Ring +1", priority=135},        -- 7% PDT
        right_ring={name="Moonbeam Ring", priority=100},            -- 4% DT, Replace with Moonlight Ring eventually
        back="Null Shawl",
    }

    sets.idle["Buffs"] = {                                          -- 68 DT, 7% PDT
        range=empty,
        ammo="Staunch Tathlum",                                     -- 2% DT
        head={name="Null Masque", priority=100},                    -- 10% DT Regen +3 Refresh +1 Regain +2
        body={name="Adamantite Armor", priority=182},               -- 20% DT
        hands={name="Nyame Gauntlets", priority=91},                -- 7% DT
        legs={name="Nyame Flanchard", priority=114},                -- 8% DT
        feet={name="Nyame Sollerets", priority=68},                 -- 7% DT
        neck="Loricate Torque +1",                                  -- 6% DT
        waist="Gishdubar Sash",
        left_ear="Brachyura Earring",
        right_ear={ name="Erilaz Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+12','Mag. Acc.+12','Damage taken-4%',}},
        left_ring={name="Gelatinous Ring +1", priority=135},        -- 7% PDT
        right_ring={name="Moonbeam Ring", priority=100},            -- 4% DT, Replace with Moonlight Ring eventually
        back=jse.capes.parry
    }

    sets.idle["Phalanx"] = {
        ammo="Staunch Tathlum",
        head=jse.relic.head,
        body={ name="Herculean Vest", augments={'INT+11','Mag. Acc.+15 "Mag.Atk.Bns."+15','Phalanx +5','Accuracy+20 Attack+20',}, priority=61},
        hands={ name="Herculean Gloves", augments={'CHR+8','Accuracy+26','Phalanx +5','Mag. Acc.+16 "Mag.Atk.Bns."+16',}, priority=20},
        legs={ name="Herculean Trousers", augments={'Weapon skill damage +1%','Pet: Attack+13 Pet: Rng.Atk.+13','Phalanx +4','Accuracy+20 Attack+20',}, priority=38},
        feet={ name="Herculean Boots", augments={'"Rapid Shot"+4','"Fast Cast"+3','Phalanx +5','Accuracy+1 Attack+1',}, priority=9},
        neck="Loricate Torque +1",
        waist={name="Plat. Mog. Belt", priority=1000},
        left_ear={name="Odnowa Earring +1", priority=110},
        right_ear={name="Alabaster Earring", priority=100},
        left_ring={name="Gelatinous Ring +1", priority=135},
        right_ring={name="Moonbeam Ring", priority=100},
        back={name="Moonbeam Cape", priority=250},
    }

    ----------------------------------------------------------------
    -- ENGAGED
    ----------------------------------------------------------------

    -- Set for if I can't force the enemies into a cone
    -- Default set for now until I get SU3
    sets.engaged["Physical"] = {                                    -- 51% DT, 2% MDT, 7% PDT
        range=empty,
        ammo="Staunch Tathlum",                                     -- 2% DT
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,                                   -- 11% DT
        legs=jse.empyrean.legs,                                     -- 13% DT
        feet=jse.empyrean.feet,                                     -- 11% DT, Consider swapping in Turms Leggings +1 for the parry stat (I should be able to make the DT requirements)
        neck="Loricate Torque +1",                                  -- 6% DT, Replace with JSE+1/+2 neck
        --waist={name="Plat. Mog. Belt", priority=1000},              -- 3% DT +10% HP, Replace with Engraved Belt
        waist="Engraved Belt",
        left_ear={name="Odnowa Earring +1", priority=110},          -- 3% DT, 2% MDT
        right_ear={name="Tuisto Earring", priority=150},
        left_ring={name="Gelatinous Ring +1", priority=135},        -- 7% PDT
        right_ring={name="Moonbeam Ring", priority=100},            -- 4% DT, Replace with Moonlight Ring eventually
        back=jse.capes.parry,
    }

    -- If DT needs are met, Warders Charm +1. If not, JSE neck +1/2.
    sets.engaged["Magical"] = {                                     -- 48% DT, 2% MDT, 7% PDT (technically capping both woo)
        range=empty,
        ammo="Staunch Tathlum",                                     -- 2% DT, Repalce with Yamarang
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,                                   -- 11% DT
        legs=jse.empyrean.legs,                                     -- 13% DT
        feet=jse.empyrean.feet,                                     -- 11% DT,
        neck="Warder's Charm +1",
        --waist={name="Plat. Mog. Belt", priority=1000},              -- 3% DT +10% HP, Replace with Engraved Belt
        waist="Engraved Belt",
        left_ear={name="Odnowa Earring +1", priority=110},          -- 3% DT, 2% MDT
        right_ear={ name="Erilaz Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+12','Mag. Acc.+12','Damage taken-4%',}}, -- 4% DT
        left_ring={name="Gelatinous Ring +1", priority=135},        -- 7% PDT, Replace with Shadow Ring
        right_ring={name="Moonbeam Ring", priority=100},            -- 4% DT, Replace with Moonlight Ring eventually
        back=jse.capes.parry, -- Replace with MEVA cape
    }

    -- I don't expect that I'll be using this much
    -- This probably needs work.
    sets.engaged["TP"] = {
        range=empty,
        ammo="Coiste Bodhar", -- No RP at the moment...
        head={name="Null Masque", priority=100},
        body={name="Ayanmo Corazza +2", priority=57},
        hands={name="Nyame Gauntlets", priority=91},
        legs=jse.empyrean.legs,
        feet={name="Carmine Greaves +1", priority=95},
        neck={name="Null Loop", priority=50},
        waist="Kentarch Belt +1",
        left_ear="Cessance Earring",
        right_ear="Sherida Earring",
        left_ring={name="Moonbeam Ring", priority=100, bag="wardrobe5"},
        right_ring={name="Moonbeam Ring", priority=100, bag="wardrobe6"},
        back="Null Shawl",
    }

    -- Not sure if I'll bother having a separate max TP set. Hybrid seems cozier.

    ----------------------------------------------------------------
    -- PRECAST
    ----------------------------------------------------------------
    
    -- I am at 50% FC under Inspiration from 5/5 Merits
    -- Relic legs give +2% for every merit. Extra 10%.

    sets.precast.fast_cast = {                                                                                                      -- 71% FC
        range=empty,
        ammo="Sapience Orb",                                                                                                        -- 2% FC
        head=jse.AF.head,                                                                                                           -- 14% FC
        --body={name="Adamantite Armor", priority=182}, -- Empyrean Body
        body=jse.empyrean.body,                                                                                                     -- 13% FC
        hands={ name="Leyline Gloves", augments={'Accuracy+12','Mag. Acc.+14','"Mag.Atk.Bns."+15','"Fast Cast"+2',}, priority=25},  -- 7% FC (Can do more SR to get slightly better)
        legs={name="Agwu's Slops", priority=50},                                                                                    -- 7% FC
        feet={ name="Carmine Greaves +1", augments={'HP+80','MP+80','Phys. dmg. taken -4',}, priority=95},                          -- 8% FC
        neck="Voltsurge Torque",                                                                                                    -- 4% FC
        waist={name="Plat. Mog. Belt", priority=1000},
        left_ear={name="Odnowa Earring +1", priority=110},
        right_ear="Loquacious Earring",                                                                                             -- 2% FC
        left_ring={name="Gelatinous Ring +1", priority=135},
        right_ring="Kishar Ring",                                                                                                   -- 4% FC
        back=jse.capes.fast_cast,                                                                                                   -- 10% FC
    }

    sets.precast.fast_cast_inspiration = set_combine(sets.idle["Normal"], {
    })

    ----------------------------------------------------------------
    -- ENMITY
    ----------------------------------------------------------------

     -- All of the JA enmity actions inherit from this set
    sets.midcast.enmity = {                                 -- 93 Enmity, 36% PDT
        range=empty,
        ammo={name="Aqreqaq Bomblet", priority=20},         -- 2 Enmity
        head={name="Halitus Helm", priority=88},            -- 8 Enmity
        body={name="Emet Harness +1", priority=61},         -- 10 Enmity, 6% PDT
        hands={name="Kurys Gloves", priority=25},           -- 9 Enmity, 2% DT
        legs=jse.empyrean.legs,                             -- 13 Enmity, 12% DT
        feet=jse.empyrean.feet,                             -- 8 Enmity, 11% DT
        neck={name="Unmoving Collar +1", priority=200},     -- 10 Enmity, Replace with Moonlight Necklace when I'm rich
        --neck="Moonlight Necklace",                        -- TODO: More enmity when I can balance this better with the main set
        waist={name="Kasiri Belt", priority=30},            -- 3 Enmity
        left_ear="Trux Earring",                            -- 5 Enmity
        right_ear={name="Cryptic Earring", priority=40},    -- 5 Enmity
        left_ring={name="Eihwaz Ring", priority=70},        -- 5 Enmity
        right_ring={name="Supershear Ring", priority=30},   -- 5 Enmity
        back=jse.capes.enmity,                              -- 10 Enmity, 5% DT
    }

    sets.midcast["Foil"] = set_combine(sets.midcast.enmity, {
        legs=jse.relic.legs,
    })

    ----------------------------------------------------------------
    -- MAGIC
    ----------------------------------------------------------------
    
    sets.midcast["Enhancing Magic"] = set_combine(sets.idle["Normal"], {     --
        ammo="",
        head=jse.empyrean.head,             -- +25% Duration
        body="",
        hands="",
        legs=jse.relic.legs,                -- +25% Duration (+30% at +3)
        feet="",
        neck="",
        waist="",
        left_ear="",
        right_ear="",
        left_ring="",
        right_ring="",
        back="",
    })

    -- Aims are 501 skill + fill with duration
    sets.midcast.enhancing_skill = set_combine(sets.midcast["Enhancing Magic"], { -- Enhancing skill
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
    })

    sets.midcast["Phalanx"] = {  -- This is for self-casting. Huge HP dip.
        ammo="Staunch Tathlum",
        head=jse.relic.head,
        body={ name="Herculean Vest", augments={'INT+11','Mag. Acc.+15 "Mag.Atk.Bns."+15','Phalanx +5','Accuracy+20 Attack+20',}, priority=61},
        hands={ name="Herculean Gloves", augments={'CHR+8','Accuracy+26','Phalanx +5','Mag. Acc.+16 "Mag.Atk.Bns."+16',}, priority=20},
        legs={ name="Herculean Trousers", augments={'Weapon skill damage +1%','Pet: Attack+13 Pet: Rng.Atk.+13','Phalanx +4','Accuracy+20 Attack+20',}, priority=38},
        feet={ name="Herculean Boots", augments={'"Rapid Shot"+4','"Fast Cast"+3','Phalanx +5','Accuracy+1 Attack+1',}, priority=9},
        neck="Incanter's Torque",
        waist="Olympus Sash",
        left_ear="Andoaa Earring",
        right_ear="Mimir Earring",
        left_ring="Stikini Ring",
        right_ring="Stikini Ring",
        back={name="Moonbeam Cape", priority=250}, -- Replace with Merciful Cape
    }

    sets.midcast["Regen"] = set_combine(sets.midcast["Enhancing Magic"], {
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
    })

    sets.midcast["Refresh"] = set_combine(sets.midcast["Enhancing Magic"], {
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
    })

    sets.midcast["Stoneskin"] = set_combine(sets.midcast.enhancing_skill, { -- Not sure how close we can get to 500 but there are specific pieces I want here.
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
    })

    sets.midcast["Cure"] = {
        ammo="Sapience Orb",
        head={name="Null Masque", priority=100},
        body={name="Adamantite Armor", priority=182},
        hands={name="Nyame Gauntlets", priority=91},
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Loricate Torque +1",                          -- Change to Sacro Gorget
        waist="Sroda Belt",                                 -- 35% cure potency
        left_ear="Mendi. Earring",                          -- 5% cure potency
        right_ear={name="Cryptic Earring", priority=40},
        left_ring={name="Moonbeam Ring", priority=100},
        right_ring={name="Supershear Ring", priority=30},
        back=jse.capes.enmity,
    }

    sets.midcast.SIRD = {                                                                           -- 93% + 10% Merits = 103% SIRD, Consider Peord Claymore to replace waist and Evanescence Ring so that I can bring in Platinum Moogle Belt + Gelatinous Ring +1 for HP
        ammo="Staunch Tathlum",                                                                     -- 10% SIRD
        head=jse.empyrean.head,                                                                     -- 20% SIRD
        body={name="Adamantite Armor", priority=182},
        hands={name="Rawhide Gloves", augments={'HP+50','Accuracy+15','Evasion+20',}, priority=75}, -- 15% SIRD, replace with Regal Gauntlets (10%)
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Moonlight Necklace",                                                                  -- 15% SIRD
        waist="Rumination Sash",                                                                    -- 10% SIRD, replace with Audumbla Sash
        left_ear="Halasz Earring",                                                                  -- 5% SIRD, replace with Magnetic Earring (but my BLM...)
        right_ear={name="Alabaster Earring", priority=100},
        left_ring="Evanescence Ring",                                                               -- 5% SIRD
        right_ring="Murky Ring",                                                                    -- 3% SIRD
        back=jse.capes.SIRD,                                                                        -- 10% SIRD
    }

    -- Attempt a better version of this when I have either Peord Claymore or Epeolatry because I can barely make it as is without enmity
    sets.midcast.SIRD_enmity = {                                                                    -- 93% + 10% Merits = 103% SIRD, 51 enmity
        ammo="Staunch Tathlum",                                                                     -- 10% SIRD
        head=jse.empyrean.head,                                                                     -- 20% SIRD
        body={name="Emet Harness +1", priority=61},                                                 -- 10 Enmity
        hands={name="Rawhide Gloves", augments={'HP+50','Accuracy+15','Evasion+20',}, priority=75}, -- 15% SIRD, replace with Regal Gauntlets (10%)
        legs=jse.empyrean.legs,                                                                     -- 13 enmity
        feet=jse.empyrean.feet,                                                                     -- 8 enmity
        neck="Moonlight Necklace",                                                                  -- 15% SIRD, 15 enmity
        waist="Rumination Sash",                                                                    -- 10% SIRD, replace with Audumbla Sash
        left_ear="Halasz Earring",                                                                  -- 5% SIRD
        right_ear={name="Cryptic Earring", priority=40},                                            -- 5 Enmity
        left_ring="Evanescence Ring",                                                               -- 5% SIRD
        right_ring="Murky Ring",                                                                    -- 3% SIRD
        back=jse.capes.SIRD,                                                                        -- 10% SIRD (eventually SIRD enmity cape with +10)
    }

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
    sets.ja["Vivacious Pulse"] = { -- Probably Empyrean head just for the -na capability
        ammo="Staunch Tathlum",
        head=jse.empyrean.head,
        body={name="Adamantite Armor", priority=182},
        hands={name="Nyame Gauntlets", priority=91}, -- Replace with Regal Gauntlets
        legs=jse.AF.legs,
        feet="Nyame Sollerets",
        neck="Incanter's Torque",
        waist={name="Plat. Mog. Belt", priority=1000},
        left_ear={name="Odnowa Earring +1", priority=110}, -- Replace with Beatific Earring
        right_ear={name="Tuisto Earring", priority=150}, -- Replace with Saxnot Earring
        left_ring="Stikini Ring",
        right_ring="Stikini Ring",
        back={name="Moonbeam Cape", priority=250}, -- Replace with Altruistic Cape
    }

    -- This seems very low HP lol
    sets.ja["Swipe"] = {
        ammo="Pemphredo Tathlum",
        head={name="Agwu's Cap", priority=38},
        body={name="Agwu's Robe", priority=61},
        hands={name="Agwu's Gages", priority=38},
        legs={name="Agwu's Slops", priority=50},
        feet={name="Agwu's Pigaches", priority=27},
        neck="Sibyl Scarf", -- Baetyl Pendant
        waist="Orpheus's Sash",
        left_ear="Friomisi Earring",
        right_ear="Moldavite Earring", -- Crematio Earring
        left_ring={name="Gelatinous Ring +1", priority=135},
        right_ring="Metamor. Ring +1",
        back={ name="Evasionist's Cape", augments={'Enmity+4','"Embolden"+15','"Dbl.Atk."+1',}},
    }

    sets.ja["Lunge"] = sets.ja["Swipe"]

    ----------------------------------------------------------------
    -- WEAPONSKILLS 
    ----------------------------------------------------------------

    -- None of these have DT yet but I can figure that out later
    sets.ws.default = {
        ranged=empty,
        ammo="Knobkierrie",
        head={name="Nyame Helm", priority=91},
        body={name="Nyame Mail", priority=136},
        hands={name="Nyame Gauntlets", priority=91},
        legs={name="Nyame Flanchard", priority=114},
        feet={name="Nyame Sollerets", priority=68},
        neck={name="Null Loop", priority=50},
        waist="Kentarch Belt +1",
        left_ear={name="Odnowa Earring +1", priority=110},
        right_ear="Sherida Earring",
        left_ring="Rufescent Ring",
        right_ring="Petrov Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Dimidiation"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head={name="Nyame Helm", priority=91},
        body={name="Nyame Mail", priority=136},
        hands={name="Nyame Gauntlets", priority=91},
        legs={name="Nyame Flanchard", priority=114},
        feet={name="Nyame Sollerets", priority=68},
        neck={name="Null Loop", priority=50},
        waist="Kentarch Belt +1",
        left_ear="Moonshade Earring",
        right_ear="Sherida Earring",
        left_ring="Rufescent Ring",
        right_ring="Petrov Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Resolution"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head=jse.relic.head,
        body={name="Nyame Mail", priority=136},
        hands={name="Nyame Gauntlets", priority=91},
        legs=jse.empyrean.legs,
        feet={name="Nyame Sollerets", priority=68},
        neck={name="Null Loop", priority=50},
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
        body={name="Nyame Mail", priority=136},
        hands={name="Nyame Gauntlets", priority=91},
        legs=jse.empyrean.legs,
        feet={name="Nyame Sollerets", priority=68},
        neck={name="Null Loop", priority=50},
        waist="Sailfi Belt +1",
        left_ear="Moonshade Earring",
        right_ear="Sherida Earring",
        left_ring="Rufescent Ring",
        right_ring="Petrov Ring",
        back="Null Shawl",
    }

    sets.ws["Herculean Slash"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head={name="Nyame Helm", priority=91},
        body={name="Nyame Mail", priority=136},
        hands={name="Agwu's Gages", priority=38},
        legs={name="Nyame Flanchard", priority=114},
        feet={name="Agwu's Pigaches", priority=27},
        neck="Sibyl Scarf",
        waist="Orpheus's Sash",
        left_ear="Friomisi Earring",
        right_ear="Ishvara Earring",
        left_ring={name="Gelatinous Ring +1", priority=135},
        right_ring="Petrov Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Shockwave"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head={name="Nyame Helm", priority=91},
        body={name="Nyame Mail", priority=136},
        hands={name="Nyame Gauntlets", priority=91},
        legs=jse.empyrean.legs,
        feet={name="Nyame Sollerets", priority=68},
        neck={name="Null Loop", priority=50},
        waist="Sailfi Belt +1",
        left_ear="Cessance Earring",
        right_ear="Sherida Earring",
        left_ring="Rufescent Ring",
        right_ring="Petrov Ring",
        back="Null Shawl",
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
        head={name="Nyame Helm", priority=91},
        body={name="Nyame Mail", priority=136},
        hands={name="Nyame Gauntlets", priority=91},
        legs={name="Nyame Flanchard", priority=114},
        feet={name="Nyame Sollerets", priority=68},
        neck={name="Null Loop", priority=50},
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
        left_ring="Purity Ring", -- 7% Cursna, 7% Holy Water
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

local last_rune = nil

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

        return
    end

    -- Check every other kind of ability
    if spell.action_type == "Ability" then
        if sets.ja[spell.name] then
            equip_set_and_weapon(sets.ja[spell.name])
        end

        -- Lunge checks
        -- We have to store the last rune used + check whether it is still active. We cannot check against spell.element, as it always returns "light".
        -- A little flimsy, as it will always fail if I load the GS *after* using runes, but that shouldn't happen in normal gameplay.
        if spell.type == "Rune" then
            last_rune = spell
        end

        if last_rune and (spell.name == "Lunge" or spell.name == "Swipe") then
            -- Hachirin-no-Obi check
            local double_weather_matches_rune = last_rune.element == world.weather_element and world.weather_intensity == 2
            local weather_and_day_matches_rune = last_rune.element == world.weather_element and last_rune.element == world.day_element

            if (double_weather_matches_rune or weather_and_day_matches_rune) and buffactive[last_rune.name] then
                equip({waist="Hachirin-no-Obi"})
                return
            end

            -- Tenebrae
            if last_rune.name == "Tenebrae" then
                equip({head="Pixie Hairpin +1", left_ring="Archon Ring",})
            end

            -- Lux could have a Weatherspoon check, but I don't have one!
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
        if SIRD == "On" then
            if enmity_spells:contains(spell.name) then
                equip_set_and_weapon(sets.midcast.SIRD_enmity)
            else
                equip_set_and_weapon(sets.midcast.SIRD)
            end

            return
        end

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

        if not matched and (spell.name:match("^Bar") or spell.name == "Aquaveil" or spell.name == "Temper") then
            equip_set_and_weapon(sets.midcast.enhancing_skill)
            matched = true
        end

        -- Enmity, maybe reorder this if I need to
        if not matched and enmity_spells:contains(spell.name) then
            equip_set_and_weapon(sets.midcast.enmity)
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

        -- Embolden overlay (for self-casting)
        if buffactive["Embolden"] and spell.skill == "Enhancing Magic" then
            equip_set_and_weapon(sets.buff.embolden)
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
            add_to_chat(123, "Doom.")
            --send_command("input /p Doom.")
        elseif gain == false and player.status ~= "Dead" and player.status ~= "Engaged Dead" then
            add_to_chat(123, "Doom is removed.")
            --send_command("input /p Doom is removed.")
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

        if weapon_lock == "On" then
            equip_current_weapon()
            send_command("gs disable main;gs disable sub;gs disable range")
        else
            send_command("gs enable main;gs enable sub;gs enable range")
            equip_current_weapon()
        end

    elseif main_command == "togglespeed" then
        toggle_speed = handle_toggle(toggle_speed, "Speed")
        idle()
    
    elseif main_command == "sird" then
        SIRD = handle_toggle(SIRD, "SIRD")
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

    send_command("unbind f5")
    send_command("unbind f6")

    send_command("unbind f8")

    send_command("unbind f9")
    send_command("unbind f10")
    send_command("unbind f12")
end