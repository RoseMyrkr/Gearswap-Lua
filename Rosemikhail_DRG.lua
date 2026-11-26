---@diagnostic disable: lowercase-global, undefined-global
include("Modes.lua")

----------------------------------------------------------------
-- NOTES
----------------------------------------------------------------

-- High buff vs low buff WS sets (sets.ws["Stardiver"].high_buff, etc.)
-- How do I make this more generic for other jobs? How do I extend this to be able to use other modes like WS accuracy? ["WS"].high_buff, ["WS"].acc etc.
-- WS Modes = M{"Low Buff", "High Buff", "Accuracy"} ["WS"]["High Buff"]. Can you use tables like this? What if there is no mode attached? Default.
-- local set_exists = sets.ws[spell.name]

-- if set_exists then
--     if high_buff == true and set_exists.high_buff then
--         equip_set_and_weapon(set_exists.high_buff)
--     else
--         equip_set_and_weapon(set_exists)
--     end
-- else
--     equip_set_and_weapon(sets.ws.default) -- Unhandled Weapon Skills
-- end

-- Potentially a wyvern DT overlay toggle

-- Weapon Skills
-- Vim's Torque +1
-- Fotia gorget
-- Fotia belt

-- Consider ody specific engaged sets (this means no Hasso or Last Resort) and allow for lower gear haste in regular sets

-- Switch to Ephramad's Ring (sigh....)

-- Drakesbane requires more critty things

----------------------------------------------------------------
-- VARIABLES & COMMANDS
----------------------------------------------------------------

-- Modes and toggles
weapon_mode = M{} -- This is automatically populated
engaged_mode = M{} -- This is automatically populated
idle_mode = M{"Normal", "DT"}

toggle_speed = "Off"
weapon_lock = "Off"

-- Midcast helpers
breath_map = {
    ["Flame Breath"] = "Elemental Breath",
    ["Frost Breath"] = "Elemental Breath",
    ["Sand Breath"] = "Elemental Breath",
    ["Gust Breath"] = "Elemental Breath",
    ["Hydro Breath"] = "Elemental Breath",
    ["Lightning Breath"] = "Elemental Breath",
    ["Healing Breath"] = "Healing Breath",
    ["Healing Breath II"] = "Healing Breath", -- Not sure if this or the following are needed
    ["Healing Breath III"] = "Healing Breath",
    ["Healing Breath IV"] = "Healing Breath",
}

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

function build_weapon_modes(weapon_sets)
    local weapons = {}

    for weapon, _ in pairs (weapon_sets) do
        weapons[#weapons + 1] = weapon
    end

    -- Why don't you just unpack in the same order that you were added, buddy?
    table.sort(weapons, function (a, b)
        return weapon_sets[a].index < weapon_sets[b].index
    end)

    add_to_chat(200, string.format("There are %s weapon modes.", #weapons))
    weapon_mode = M{table.unpack(weapons)}
end

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
-- LOCKSTYLE & MACROS
----------------------------------------------------------------

function update_lockstyle()
    send_command("wait 5;input /lockstyleset 17")
end

function update_macro_book()
    -- DRG macro book
    if player.sub_job == "SAM" then
        send_command("input /macro book 15;input /macro set 1")
    elseif player.sub_job == "DNC" then
        send_command("input /macro book 16;input /macro set 1")
    elseif player.sub_job == "WAR" then
        send_command("input /macro book 17;input /macro set 1")
    end
end

update_lockstyle()
update_macro_book()

-- Individual spells should be added in the following way: sets.precast["Impact"]. This goes for precast and midcast.
function get_sets()
    ----------------------------------------------------------------
    -- WEAPON SETS
    ----------------------------------------------------------------
    -- Note that engaged_sets is automatically populated with Idle and TP if left empty.
    -- "Idle" is treated as a keyword and refers to whichever set the current idle mode is using.

    weapon_sets = {
        ["Shining One"] = {
            index = 1,
            gear = {
                main="Shining One",
                sub="Khonsu",
            },
            engaged_sets = {"TP", "Safety"},
            overrides = {},
        },
        ["Naegling"] = {
            index = 2,
            gear = {
                main="Naegling",
                sub=empty,
            },
            engaged_sets = {"Fencer", "Safety", "Kraken"},
            overrides = {
                ["Kraken"] = {
                    main="Naegling",
                    sub="Kraken Club",
                }
            },
        },
        ["Mafic Cudgel"] = {
            index = 3,
            gear = {
                main="Mafic Cudgel",
                sub=empty,
            },
            engaged_sets = {"Fencer", "Safety", "Kraken"},
            overrides = {
                ["Kraken"] = {
                    main="Naegling",
                    sub="Kraken Club",
                }
            },
        },
    }

    build_weapon_modes(weapon_sets)
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
        head="Vishap Armet +3",
        body="Vishap Mail +3",
        hands="Vishap Finger Gauntlets +3",
        legs="Vishap Brais +3",
        feet="Vishap Greaves +3",
    }

    jse.relic = {
        head="Pteroslaver Armet +2",
        body="Pteroslaver Mail +2",
        hands="Pteroslaver Finger Gauntlets +2",
        legs="Pteroslaver Brais +2",
        feet="Pteroslaver Greaves +2",
    }

    jse.empyrean = {
        head="Peltast's Mezail +3",
        body="Peltast's Plackart +3",
        hands="Peltast's Vambraces +3",
        legs="Peltast's Cuissots +3",
        feet="Peltast's Schynbalds +3",
    }

    jse.capes = {
        -- lol
    }

    -- TP: Dex +20, Accuracy +20 Attack +20, Accuracy +10, Dbl.Atk. +10, Phys. dmg. taken -10% (Technically I don't need the phys damage but like yolo)
    -- STR WSD: STR+20, Accuracy+20 Attack+20, STR+10, Weapon skill damage+10, Phys. dmg. taken-10% (Diarmuid, Impulse Drive, Camlann's Torment, Savage Blade)
    -- STR DA: STR+20, Accuracy+20 Attack+20, STR+10, Dbl.Atk.+10, Phys. dmg. taken-10% (Stardiver No Shining One)
    -- STR Crit: STR+20, Accuracy+20 Attack+20, STR+10, Crit.hit rate+10, Phys. dmg. taken-10% (Stardiver Shining One, Drakesbane)
    -- DEX WSD: DEX+20, Accuracy+20 Attack+20, DEX+10, Weapon skill damage+10%, Phys. dmg. taken-10% (Geirskogul)

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
    sets.pet = {}                   -- Leave this empty

    ----------------------------------------------------------------
    -- IDLE MODES
    ----------------------------------------------------------------

    sets.idle["Normal"] = {                 -- 29 PDT, 22 DT (51 PDT, Cap MDT with Shell V) + 6 DT temporarily
        ammo="Staunch Tathlum",             -- 2 DT
        head="Null Masque",                 -- 10 DT, 2 Regain
        body="Gleti's Cuirass",             -- 9 PDT, 3 Regain
        hands="Gleti's Gauntlets",          -- 7 PDT, 2 Regain
        legs="Gleti's Breeches",            -- 8 PDT, 3 Regain
        feet="Gleti's Boots",               -- 5 PDT, 2 Regain
        neck={ name="Dgn. Collar +1", augments={'Path: A',}}, -- Wyvern level, ??? Wyvern DT
        waist="Null Belt",                  -- Replace with Carrier's Sash
        left_ear="Arete del Luna +1",
        right_ear={ name="Pel. Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+11','Mag. Acc.+11','Crit.hit rate+3',}}, -- Wyvern level
        left_ring="Murky Ring",             -- 10 DT
        right_ring="Shneddick Ring",        -- Resists
        back="Null Shawl",                  -- MEVA
    }

    sets.idle["DT"] = set_combine(sets.idle["Normal"], { -- +27 DT (Would cap DT on the main set with Staunch Tathlum +1)
        body="Adamantite Armor",            -- 20 DT
        feet="Nyame Sollerets",             -- 7 DT
    })

    ----------------------------------------------------------------
    -- MELEE "IDLE"
    ----------------------------------------------------------------

    -- Re-sim everything here when I actually have capes

    sets.engaged["TP"] = { -- /SAM /DRK
        ranged=empty,
        ammo="Coiste Bodhar",
        head="Null Masque",     -- Replace with Hjarrandi Helm
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet="Carmine Greaves +1",
        neck="Anu Torque",      -- Replace with Vim Torque +1
        waist="Sailfi Belt +1",
        left_ear="Sherida Earring",
        right_ear="Sroda Earring",
        left_ring="Murky Ring",
        right_ring="Lehko's Ring",
        back="Null Shawl",
    }

    sets.engaged["TP"].no_wyvern = set_combine(sets.engaged["TP"], {
        right_ear="Telos Earring",
    })

    sets.engaged["Fencer"] = { -- Sword
        ranged=empty,
        ammo="Coiste Bodhar",
        head="Ischkur Turban",  -- Replace with Hjarrandi Helm
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet="Carmine Greaves +1",
        neck="Null Loop",      -- Replace with Vim Torque +1
        waist="Sailfi Belt +1",
        left_ear="Sherida Earring",
        right_ear="Sroda Earring",
        left_ring="Murky Ring",
        right_ring="Lehko's Ring",
        back="Null Shawl",
    }

    sets.engaged["Fencer"].no_wyvern = set_combine(sets.engaged["Fencer"], {
        right_ear="Telos Earring",
    })

    sets.engaged["Safety"] = { -- Maximal DT and MEVA if I'm suffering
        ranged=empty,
        ammo="Coiste Bodhar",
        head="Nyame Helm",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck={ name="Dgn. Collar +1", augments={'Path: A',}},
        waist="Sailfi Belt +1",
        left_ear="Sherida Earring",
        right_ear="Sroda Earring",
        left_ring="Murky Ring",
        right_ring="Lehko's Ring",
        back="Null Shawl",
    }

    sets.engaged["Safety"].no_wyvern = set_combine(sets.engaged["Safety"], {
        right_ear="Telos Earring",
    })

    sets.engaged["Kraken"] = { -- /DNC
        ranged=empty,
        ammo="Coiste Bodhar",
        head="Ischkur Turban",      -- Replace with Hjarrandi Helm
        body=jse.empyrean.body,
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Anu Torque",          -- Replace with Vim Torque +1
        waist="Kentarch Belt +1",
        left_ear="Sherida Earring",
        right_ear="Alabaster Earring",
        left_ring="Murky Ring",
        right_ring="Lehko's Ring",
        back="Null Shawl",
    }

    ----------------------------------------------------------------
    -- PRECAST
    ----------------------------------------------------------------

    sets.precast.fast_cast = set_combine(sets.idle["Normal"], { --  45 FC
        ammo="Sapience Orb",            -- 2 FC
        --head=,
        body="Sacro Breastplate",       -- 10 FC
        hands={ name="Leyline Gloves", augments={'Accuracy+12','Mag. Acc.+14','"Mag.Atk.Bns."+15','"Fast Cast"+2',}}, -- 7 FC
        legs="Enif Cosciales",          -- 8 FC
        feet={ name="Carmine Greaves +1", augments={'HP+80','MP+80','Phys. dmg. taken -4',}}, -- 8 FC
        neck="Voltsurge Torque",        -- 4 FC
        --waist=,
        left_ear="Etiolation Earring",  -- 1 FC
        right_ear="Loquac. Earring",    -- 2 FC
        left_ring="Prolix Ring",        -- 2 FC
        right_ring="Naji's Loop",       -- 1 FC
        --back=
    })

    ----------------------------------------------------------------
    -- MAGIC
    ----------------------------------------------------------------

    ----------------------------------------------------------------
    -- JOB ABILITIES 
    ----------------------------------------------------------------
    
    sets.ja["Call Wyvern"] = {
        body=jse.relic.body,
    }

    sets.ja["Spirit Surge"] = sets.ja["Call Wyvern"]

    sets.ja["Jump"] = {
        ammo="Coiste Bodhar",           -- Replace with Aurgelmir orb (/+1)
        head="Ischkur Turban",          -- Replace with Flamma Zucchetto +2 (Ambuscade)
        body=jse.AF.body,
        hands=jse.AF.hands,
        legs=jse.relic.legs,
        feet=jse.AF.feet,               -- Replace with Ostro Greaves
        neck="Anu Torque",              -- Replace with Vim Torque
        waist="Sailfi Belt +1",
        left_ear="Sherida Earring",
        right_ear="Telos Earring",
        left_ring="Petrov Ring",        -- Replace with Niqmaddu Ring
        right_ring="Lehko's Ring",      -- Replace with Chirich Ring (maybe)
        back="Null Shawl",              -- Replace with JSE cape
    }
    
    sets.ja["High Jump"] = sets.ja["Jump"]

    sets.ja["Soul Jump"] = sets.ja["Jump"]

    sets.ja["Spirit Jump"] = set_combine(sets.ja["Jump"], { 
        feet=jse.empyrean.feet,
    })

    sets.ja["Angon"] = { -- Consider TH for easy tagging
        ammo="Angon",
        hands=jse.relic.hands,
    }

    sets.ja["Spirit Link"] = {
        hands=jse.empyrean.hands,
        feet=jse.relic.feet,
        -- Add Pratik Earring
    }

    sets.ja["Ancient Circle"] = {
        legs=jse.AF.legs,
    }

    -- Nothing for Steady Wing, as HP swaps don't work for that

    ----------------------------------------------------------------
    -- PET
    ----------------------------------------------------------------

    -- NOTE THAT YOU CAN BE HIT WHENEVER YOUR WYVERN IS DOING A THING.
    -- THESE WANT DT. IF I'M LOSING DT TO A SWAP, ADD SOME BACK IN.
    -- Expand these if I feel like it later.

    sets.pet["Elemental Breath"] = { -- I don't know if this applies when I ask the Wyvern to do it or when the Wyvern does it regardless
        head=jse.relic.head,
    }

    sets.pet["Healing Breath"] = { -- I don't know if this applies when I ask the Wyvern to do it or when the Wyvern does it regardless
        head=jse.relic.head,
    }

    ----------------------------------------------------------------
    -- WEAPONSKILLS
    ----------------------------------------------------------------

    sets.ws.default = { -- Generic physical, based on Stardiver because shrug
        ranged=empty,
        ammo="Coiste Bodhar",
        head=jse.empyrean.head,
        body="Gleti's Cuirass",
        hands="Gleti's Gauntlets",
        legs=jse.empyrean.legs,
        feet="Gleti's Boots",
        neck={ name="Dgn. Collar +1", augments={'Path: A',}},
        waist="Sailfi Belt +1",
        left_ear="Moonshade Earring",
        right_ear={ name="Pel. Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+11','Mag. Acc.+11','Crit.hit rate+3',}},
        left_ring="Sroda Ring",
        right_ring="Lehko's Ring",
        back="Null Shawl",
    }

    sets.ws["Impulse Drive"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head=jse.empyrean.head,
        body="Gleti's Cuirass",
        hands="Gleti's Gauntlets",
        legs=jse.empyrean.legs,
        feet="Gleti's Boots",
        neck={ name="Dgn. Collar +1", augments={'Path: A',}},
        waist="Sailfi Belt +1",
        left_ear="Moonshade Earring",
        right_ear={ name="Pel. Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+11','Mag. Acc.+11','Crit.hit rate+3',}},
        left_ring="Epaminondas's Ring",
        right_ring="Lehko's Ring",
        back="Alabaster Mantle",
    }

    -- sets.ws["Vorpal Thrust"] = {
    -- }
    
    -- sets.ws["Wheeling Thrust"] = {
    -- }

    -- sets.ws["Penta Thrust"] = {
    -- }

    sets.ws["Stardiver"] = {
        ranged=empty,
        ammo="Coiste Bodhar",
        head=jse.empyrean.head,
        body="Gleti's Cuirass",
        hands="Gleti's Gauntlets",
        legs=jse.empyrean.legs,
        feet="Gleti's Boots",
        neck={ name="Dgn. Collar +1", augments={'Path: A',}},
        waist="Sailfi Belt +1",
        left_ear="Moonshade Earring",
        right_ear={ name="Pel. Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+11','Mag. Acc.+11','Crit.hit rate+3',}},
        left_ring="Sroda Ring",
        right_ring="Lehko's Ring",
        back="Null Shawl",
    }

    -- Do this when I need to AOE something
    sets.ws["Sonic Thrust"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head=jse.empyrean.head,
        body="Gleti's Cuirass",
        hands="Gleti's Gauntlets",
        legs=jse.empyrean.legs,
        feet="Nyame Sollerets",
        neck={ name="Dgn. Collar +1", augments={'Path: A',}},
        waist="Sailfi Belt +1",
        left_ear="Moonshade Earring",
        right_ear={ name="Pel. Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+11','Mag. Acc.+11','Crit.hit rate+3',}},
        left_ring="Epaminondas's Ring",
        right_ring="Lehko's Ring",
        back="Alabaster Mantle",
    }

    -- -- I don't have this yet, so don't bother simming
    -- sets.ws["Cammlain's Torment"] = {
    -- }

    -- -- I don't have this yet, so don't bother simming
    -- sets.ws["Drakesbane"] = {
    -- }

    sets.ws["Savage Blade"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head=jse.empyrean.head,
        body=jse.empyrean.body,
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck={ name="Dgn. Collar +1", augments={'Path: A',}},
        waist="Sailfi Belt +1",
        left_ear="Thrud Earring",
        right_ear="Moonshade Earring",
        left_ring="Epaminondas's Ring",
        right_ring="Rufescent Ring",
        back="Null Shawl",
    }

    sets.ws["Judgement"] = {
        ranged=empty,
        ammo="Knobkierrie",
        head=jse.empyrean.head,
        body="Nyame Mail",
        hands=jse.empyrean.hands,
        legs=jse.empyrean.legs,
        feet=jse.empyrean.feet,
        neck="Null Loop",
        waist="Kentarch Belt +1",
        left_ear="Thrud Earring",
        right_ear="Moonshade Earring",
        left_ring="Epaminondas's Ring",
        right_ring="Rufescent Ring",
        back="Null Shawl",
    }

    ----------------------------------------------------------------
    -- BUFF
    ----------------------------------------------------------------

    -- Consider separating into Holy Water on self vs Cursna received sets because if I cast Cursna on myself I may want to use Menelaus's Ring
    sets.buff.doom = {
        neck="Nicander's Necklace", -- 20% Cursna, 30% Holy Water
        waist="Gishdubar Sash", -- 10% Cursna
        left_ring="Purity Ring", -- 7% Cursna, 7% Holy Water
        right_ring="Blenmot's Ring +1", -- 10% Holy Water
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
    local function wyvern_engaged_check()
        if pet.isvalid == false and sets.engaged[engaged_mode.current].no_wyvern then
            equip_set_and_weapon(sets.engaged[engaged_mode.current].no_wyvern)
        else
            equip_set_and_weapon(sets.engaged[engaged_mode.current])
        end
    end

    -- Choose between engaged set and regular idle
    if player.status == "Engaged" then
        if engaged_mode.current == "Idle" then
            equip_set_and_weapon(sets.idle[idle_mode.current])
        else
            --equip_set_and_weapon(sets.engaged[engaged_mode.current])
            wyvern_engaged_check()
        end
    else
        equip_set_and_weapon(sets.idle[idle_mode.current])

        -- Speed overlay
        if toggle_speed == "On" then
            equip({right_ring="Shneddick Ring",})
        end
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
    if toggle_speed == "On" then
        add_to_chat(123, "Consider disabling the speed toggle!")
    end

    if spell.type == "WeaponSkill" then
        if sets.ws[spell.name] then
            equip_set_and_weapon(sets.ws[spell.name])
        else
            equip_set_and_weapon(sets.ws.default) -- Unhandled Weapon Skills
        end

    elseif spell.action_type == "Ability" then
        if sets.ja[spell.name] then
            equip_set_and_weapon(sets.ja[spell.name])
        end

    elseif spell.action_type == "Magic" then
        if sets.precast[spell.name] then
            equip_set_and_weapon(sets.precast[spell.name])
        else
            equip_set_and_weapon(sets.precast.fast_cast) -- General purpose
        end
    end

    if buffactive["doom"] then
        equip(sets.buff.doom)
    end
end

function midcast(spell)

    -- Missing anything spell-related

    if buffactive["doom"] then
        equip(sets.buff.doom)
    end
end

function aftercast(spell)
    -- I imagine Gearswap will not immediately register the pet's summoning, so any pet-related swaps will wait until pet_change for the idle swap
    if spell.name == "Call Wyvern" then
        return
    end

    idle()
end

function buff_change(name, gain, buff_details)
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

function pet_change(pet,gain) -- Until I know any better
    if not midaction() then
        idle()
    end
end

function pet_midcast(spell)
    add_to_chat(123, string.format("Pet is using %s.", spell.name))

    if not midaction() then
        -- Breath check
        local match_breath = breath_map[spell.name]
            
        if match_breath then
            equip_set_and_weapon(sets.pet[match_breath])
        end
    end

    -- Wear my doom gear even if my pet is doing a thing
    if buffactive["doom"] then
        equip(sets.buff.doom)
    end
end

function pet_aftercast(spell)
    if not midaction() then
        idle()
    end
end

function pet_status_change(new,old) -- Delete if unnecessary
    if not midaction() then
        idle()
    end
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