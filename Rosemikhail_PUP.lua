---@diagnostic disable: lowercase-global, undefined-global
include("Modes.lua")

----------------------------------------------------------------
-- NOTES
----------------------------------------------------------------

--[[
Using a set that swaps in an ammo will cause my animator to be removed when the TP lock is enabled.
Wondering how I should solve this. And whether any change would adversely affect other jobs.
May be best to just equip ammo and "empty" with priorities when using a manouever I unno
]]

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------

-- Modes and toggles
idle_mode = M{"Normal"} -- TODO: Not sure if I'll even need different idle modes!
weapon_mode = M{"Midnights"}

toggle_speed = "Off"
toggle_tp = "Off" -- This will disable weapon swapping as well

-- Bindings
send_command("bind f5 gs c weaponmode")
send_command("bind f6 gs c idlemode")
send_command("bind f7 gs c toggletp")

send_command("bind f9 gs c togglespeed")
send_command("bind f12 gs c toggletextbox")

-- Help Text
add_to_chat(123, "F5: Switch weapon set, F6: Cycle idle mode")
add_to_chat(123, "F7: Toggle TP lock")
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
        "Wep: %s | Idle: %s | TP Lock: %s | Speed: %s",
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
    send_command("wait 5;input /lockstyleset 35") -- River
end

function update_macro_book()
    send_command("input /macro book 5;input /macro set 1")
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
        --head="",
        --body="",
        --hands="",
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
        --idle="",
    }

    ----------------------------------------------------------------
    -- WEAPON SETS
    ----------------------------------------------------------------
    
    weapon_sets = {
        ["Midnights"] = {
            main={ name="Midnights", augments={'Pet: Attack+25','Pet: Accuracy+25','Pet: Damage taken -3%',}},
            sub=empty,
        },
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
    sets.melee = {}                 -- Leave this empty
    sets.buff = {}                  -- Leave this empty

    ----------------------------------------------------------------
    -- IDLE MODES
    ----------------------------------------------------------------
    
    -- TODO: Upgrade my animatior to an ilvl119 one.
    sets.idle["Normal"] = {                 -- OVERALL -72% DT, -5% PDT(-77% DT+PDT), -7% Pet PDT
        range="Divinator",
        ammo="Automat. Oil +2",             -- Up in Arms lol
        head="Null Masque",                 -- -10% DT Could swap out to Nyame if I need the pet stats
        body="Nyame Mail",                  -- -9% DT
        hands="Nyame Gauntlets",            -- -7% DT
        legs="Nyame Flanchard",             -- -8% DT
        feet="Nyame Sollerets",             -- -7% DT
        neck="Loricate Torque +1",          -- -6% DT
        waist="Isa Belt",                   -- Pet -3% DT
        left_ear="Handler's Earring +1",    -- Pet -4% PDT
        right_ear="Alabaster Earring",      -- -5% DT
        left_ring="Murky Ring",             -- -10% DT
        right_ring="Defending Ring",        -- -10% DT
        back="Cheviot Cape",                -- -5% PDT
    }

    ----------------------------------------------------------------
    -- MELEE "IDLE"
    ----------------------------------------------------------------
    
    -- TODO: Upgrade my animatior to an ilvl119 one.
    sets.melee.TP = {
        range="Divinator",
        ammo="Automat. Oil +2",             -- Up in Arms lol
        head="Malignance Chapeau",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Moonshade Earring",
        right_ear="Friomisi Earring",
        left_ring="Murky Ring",
        right_ring="Lehko's Ring",
        back="Null Shawl",
    }

    ----------------------------------------------------------------
    -- PRECAST
    ----------------------------------------------------------------

    sets.precast.fast_cast = set_combine(sets.idle["Normal"], { -- OVERALL 24% FC, 2% Occ
        --ammo="Impatiens",               -- 10% SIRD, 2% Occ.
        legs="Orvail Pants +1",         -- 5% FC
        neck="Voltsurge Torque",        -- 4% FC
        left_ear="Etiolation Earring",  -- 1% FC
        right_ear="Loquac. Earring",    -- 2% FC
        left_ring="Prolix Ring",        -- 2% FC
        back="Fi Follet Cape +1",       -- 10% FC
    })

    ----------------------------------------------------------------
    -- MAGIC
    ----------------------------------------------------------------
    
    sets.midcast["Enfeebling Magic"] = {
        head=empty,
        body="Cohort Cloak +1",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Incanter's Torque",
        waist="Null Belt",
        left_ear="Gwati Earring",
        right_ear="Lifestorm Earring",
        left_ring="Stikini Ring",
        right_ring="Stikini Ring",
        back="Aurist's Cape +1",
    }

    ----------------------------------------------------------------
    -- JOB ABILITIES 
    ----------------------------------------------------------------

    sets.ja["Overdrive"] = {
        -- I unno
    }

    ----------------------------------------------------------------
    -- WEAPONSKILLS 
    ----------------------------------------------------------------

    sets.ws.default = {
        head="Malignance Chapeau",
        body="Hiza. Haramaki +2", -- Obtain
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Moonshade Earring",
        right_ear="Suppanomimi",
        left_ring="Murky Ring",
        right_ring="Defending Ring",
        back="Null Shawl",
    }

    sets.ws["Shijin Spiral"] = {
        head="Malignance Chapeau",
        body="Hiza. Haramaki +2", -- Obtain
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Moonshade Earring",
        right_ear="Suppanomimi",
        left_ring="Murky Ring",
        right_ring="Defending Ring",
        back="Null Shawl",
    }

    sets.ws["Victory Smite"] = {
        head="Null Masque",
        body="Hiza. Haramaki +2", -- Obtain
        hands="Hizamaru Kote +2", -- Obtain
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Friomisi Earring",
        right_ear="Moonshade Earring",
        left_ring="Murky Ring",
        right_ring="Defending Ring",
        back="Null Shawl",
    }

    sets.ws["Stringing Pummel"] = {
        head="Null Masque",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs="Nyame Flanchard",
        feet="Nyame Sollerets",
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Friomisi Earring",
        right_ear="Moonshade Earring",
        left_ring="Murky Ring",
        right_ring="Lehko's Ring",
        back="Null Shawl",
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
        -- If we ever use spells on PUP, steal stuff from other jobs.
        local matched = false

        -- If the spell skill has a relevant set
        if not matched and sets.midcast[spell.skill] then
            equip_set_and_weapon(sets.midcast[spell.skill])
            matched = true
        end

        -- Any other spell (trusts?)
        if not matched then
            idle()
        end
    end
end

function aftercast(spell)
    idle()
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
    send_command("unbind f5")
    send_command("unbind f6")
    send_command("unbind f7")

    send_command("unbind f9")

    send_command("unbind f12")
end