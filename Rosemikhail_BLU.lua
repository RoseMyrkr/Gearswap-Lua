---@diagnostic disable: lowercase-global, undefined-global
include("Modes.lua")

----------------------------------------------------------------
-- NOTES
----------------------------------------------------------------

-- I have no interest in expanding this past a basic spell and quest machine

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------

-- Modes and toggles
weapon_mode = M{"Kitty Rod", "Naegling", "Maxentius"}
engaged_mode = M{}
idle_mode = M{"Learning", "Normal",}

weapon_lock = "Off"

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
        "[F5] Weapon: %s [F6] Engaged: %s [F7] Idle: %s [F8] Weapon Lock: %s [F9] Speed: %s ",
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
    send_command("wait 5;input /lockstyleset 34")
end

function update_macro_book()
    -- BLU macro book
    send_command("input /macro book 15;input /macro set 1")
end

update_lockstyle()
update_macro_book()

-- Individual spells should be added in the following way: sets.precast["Impact"]. This goes for precast and midcast.
function get_sets()
    ----------------------------------------------------------------
    -- WEAPON SETS
    ----------------------------------------------------------------
    
    weapon_sets = {
        ["Kitty Rod"] = {
            gear = {
                main="Kitty Rod",
                sub=empty,
            },
            engaged_sets = {"Idle"}, -- Use the default
            overrides = {},
        },
        ["Naegling"] = {
            gear = {
                main="Naegling",
                sub="Genmei Shield",
            },
            engaged_sets = {"Idle", "TP"}, -- Use the default
            overrides = {},
        },
        ["Maxentius"] = {
            gear = {
                main="Maxentius",
                sub="Ammurapi Shield",
            },
            engaged_sets = {"Idle", "TP"},  -- Use the default
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
        --head="",
        --body="",
        hands="Magus Bazubands",
        --legs="",
        --feet="",
    }

    jse.relic = {
        --head="",
        --body="",
        --hands="",
        --legs="",
        --feet="",
    }

    jse.empyrean = {
        --head="",
        --body="",
        --hands="",
        --legs="",
        --feet="",
    }

    jse.capes = {
        -- lol
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

    sets.idle["Normal"] = {
        ammo="Staunch Tathlum",
        head="Nyame Helm",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Warder's Charm +1",
        waist="Null Belt",
        left_ear="Arete del Luna +1",
        right_ear="Etiolation Earring",
        left_ring="Murky Ring",
        right_ring="Dark Ring",
        back="Null Shawl",
    }

    sets.idle["Learning"] = {
        ammo="Staunch Tathlum",
        head="Null Masque",
        body="Adamantite Armor",
        hands=jse.AF.hands,
        legs={ name="Hagondes Pants +1", augments={'Phys. dmg. taken -4%','Magic dmg. taken -3%','"Avatar perpetuation cost" -4',}},
        feet={ name="Hag. Sabots +1", augments={'Phys. dmg. taken -4%','Magic dmg. taken -4%','"Mag.Atk.Bns."+27',}},
        neck="Incanter's Torque",
        waist="Plat. Mog. Belt",
        left_ear="Alabaster Earring",
        right_ear="Genmei Earring",
        left_ring="Stikini Ring",
        right_ring="Stikini Ring",
        back="Null Shawl",
    }

    ----------------------------------------------------------------
    -- MELEE "IDLE"
    ----------------------------------------------------------------
    
    sets.engaged["TP"] = {
        ammo="Amar Cluster",
        head="Malignance Chapeau",
        body="Ayanmo Corazza +2",
        hands="Nyame Gauntlets",
        legs="Aya. Cosciales +2",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Kentarch Belt +1",
        left_ear="Crep. Earring",
        right_ear="Telos Earring",
        left_ring="Murky Ring",
        right_ring="Petrov Ring",
        back="Null Shawl",
    }

    ----------------------------------------------------------------
    -- PRECAST
    ----------------------------------------------------------------

    -- Could drop the Prolix Ring and replace it with the Lebeche Ring
    sets.precast.fast_cast = { -- Terrible and bad 51% FC
        main="Maxentius",
        sub="Chanter's Shield",
        ammo="Sapience Orb",
        head="Jhakri Coronal +2",
        body="Jhakri Robe +2",
        hands={ name="Leyline Gloves", augments={'Accuracy+12','Mag. Acc.+14','"Mag.Atk.Bns."+15','"Fast Cast"+2',}},
        legs="Orvail Pants +1",
        feet={ name="Carmine Greaves +1", augments={'HP+80','MP+80','Phys. dmg. taken -4',}},
        neck="Voltsurge Torque",
        waist="Plat. Mog. Belt", -- Losing 3% FC for HP balancing this is so sad
        left_ear="Loquac. Earring",
        right_ear="Etiolation Earring",
        left_ring="Prolix Ring",
        right_ring="Kishar Ring",
        back="Fi Follet Cape +1",
    }

    ----------------------------------------------------------------
    -- JOB ABILITIES 
    ----------------------------------------------------------------

    ----------------------------------------------------------------
    -- WEAPONSKILLS
    ----------------------------------------------------------------

    sets.ws.default = { -- Generic physical
        ammo="Oshasha's Treatise",
        head="Nyame Helm",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Kentarch Belt +1",
        left_ear="Moonshade Earring",
        right_ear="Ishvara Earring",
        left_ring="Rufescent Ring",
        right_ring="Metamor. Ring +1",
        back="Null Shawl",
    }

    sets.ws["Savage Blade"] = {
        ammo="Oshasha's Treatise",
        head="Nyame Helm",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Kentarch Belt +1",
        left_ear="Moonshade Earring",
        right_ear="Ishvara Earring",
        left_ring="Rufescent Ring",
        right_ring="Metamor. Ring +1",
        back="Null Shawl",
    }

    sets.ws["Black Halo"] = {
        ammo="Oshasha's Treatise",
        head="Ischkur Turban",
        body="Nyame Mail",
        hands="Jhakri Cuffs +2",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Moonshade Earring",
        right_ear="Telos Earring",
        left_ring="Rufescent Ring",
        right_ring="Metamor. Ring +1",
        back="Null Shawl",
    }

    ----------------------------------------------------------------
    -- BUFF
    ----------------------------------------------------------------

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

    -- There are many kinds of abilities, so let's check Weapon Skills first, as they count as an "Ability"
    if spell.type == "WeaponSkill" then
        if idle_mode.current == "Learning" then
            idle()
            return
        end

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

function midcast(spell)
    if idle_mode.current == "Learning" then
        idle()
    end

    if buffactive["doom"] then
        equip(sets.buff.doom)
    end
end

function aftercast(spell)
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

function sub_job_change(new,old)
    update_lockstyle()
    update_macro_book()
end

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

    send_command("unbind f9")
    send_command("unbind f12")
end