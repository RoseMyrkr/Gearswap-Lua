---@diagnostic disable: lowercase-global, undefined-global
include("Modes.lua")

----------------------------------------------------------------
-- NOTES
----------------------------------------------------------------

-- So apparently it's good to have a high buff and a low buff version of WS sets.
-- I suppose it's possible to achieve this by doing sets.ws.high_buff["Stardiver"], etc.
-- For now, I'll just assume low buffs in all of my sets and go for high buff when I feel a bit more fleshed out, I think.

-- GET CAPES!!!!!! AMBUSCADE AMBUSCADE AMBUSCADE!!!

-- Might need to emulate geomancer code in that on "call wyvern", "dismiss" or the pet dying, gearswap won't necessarily register it right away for sets
-- So, on summoning, if I'm meant to switch to a wyvern friendly set, or if my wyvern updates while I'm engaging, I probably want to check and replace any gear in pet_change
-- Skip aftercast in that scenario for call wyvern at least - let pet_change notice and put any specific idle/engaged gear on if necessary
-- I think this is relevant to the sroda earring

-- Sroda earring check. I could have an overlay for Telos in the idle function for engaged. Or I could do sets.engaged.wyvern["TP"] and sets.engaged.no_wyvern["TP"]
-- Some sets don't use Telos though... So how do I deal with that?
    -- if wyvern == dead and engaged.[engaged_mode.current].no_wyvern then
    --     equip(engaged.no_wyvern[engaged_mode.current].no_wyvern)
    -- else
    --     equip(engaged[engaged_mode.current])
    -- end
-- Separate subset for sets that need a dead wyvern variant

-- Potentially a wyvern DT overlay toggle

----------------------------------------------------------------
-- VARIABLES & COMMANDS
----------------------------------------------------------------

-- Modes and toggles
weapon_mode = M{} -- This is automatically populated
engaged_mode = M{} -- This is automatically populated
idle_mode = M{"Normal", "Regain/Regen"}

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
    send_command("wait 5;input /lockstyleset 34")
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
            engaged_sets = {"Fencer", "Safety"},
            overrides = {},
        },
        ["Naegling Kraken"] = {
            index = 3,
            gear = {
                main="Naegling",
                sub="Kraken Club",
            },
            engaged_sets = {"Kraken"},
            overrides = {},
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

    sets.idle["Normal"] = { -- Probably Adamantite for easy DT and DEF, Carrier's Sash for belt, etc.

    }

    sets.idle["Regain/Regen"] = { -- Gleti's. Note lower MEVA.

    }

    ----------------------------------------------------------------
    -- MELEE "IDLE"
    ----------------------------------------------------------------

    -- Consider having a version of this set that uses Telos Earring instead of Sroda Earring if the Wyvern is missing
    sets.engaged["TP"] = { -- /SAM /DRK Make sure I have enough haste when I've lost subjob haste on DRK (assuming I use that job)

    }

    sets.engaged["TP"].no_wyvern = set_combine(sets.engaged["TP"], {

    })

    -- Consider having a version of this set that uses Telos Earring instead of Sroda Earring if the Wyvern is missing
    sets.engaged["Fencer"] = { -- /WAR

    }

    sets.engaged["Fencer"].no_wyvern = set_combine(sets.engaged["Fencer"], {

    })

    -- Consider having a version of this set that uses Telos Earring instead of Sroda Earring if the Wyvern is missing
    sets.engaged["Safety"] = { -- Maximal DT and MEVA if I'm suffering

    }

    sets.engaged["Safety"].no_wyvern = set_combine(sets.engaged["Safety"], {

    })

    sets.engaged["Kraken"] = { -- /DNC

    }

    -- sets.engaged["Glass"] = {
    -- }

    -- sets.engaged["Glass"].no_wyvern = set_combine(sets.engaged["Glass"], {
    -- })

    ----------------------------------------------------------------
    -- PRECAST
    ----------------------------------------------------------------

    sets.precast.fast_cast = { -- % FC

    }

    ----------------------------------------------------------------
    -- MAGIC
    ----------------------------------------------------------------

    ----------------------------------------------------------------
    -- JOB ABILITIES 
    ----------------------------------------------------------------
    
    sets.ja["Call Wyvern"] = {

    }

    sets.ja["Spirit Surge"] = sets.ja["Call Wyvern"]

    sets.ja["Jump"] = {

    }
    
    sets.ja["High Jump"] = sets.ja["Jump"]

    sets.ja["Soul Jump"] = sets.ja["Jump"]

    sets.ja["Spirit Jump"] = {

    }

    sets.ja["Angon"] = { -- Consider TH for easy tagging

    }

    sets.ja["Spirit Link"] = {

    }

    sets.ja["Ancient Circle"] = {

    }

    -- Nothing for Steady Wing, as HP swaps don't work for that

    ----------------------------------------------------------------
    -- PET
    ----------------------------------------------------------------

    -- NOTE THAT YOU CAN BE HIT WHENEVER YOUR WYVERN IS DOING A THING.
    -- THESE WANT DT. IF I'M LOSING DT TO A SWAP, ADD SOME BACK IN.

    sets.pet["Elemental Breath"] = { -- I don't know if this applies when I ask the Wyvern to do it or when the Wyvern does it regardless

    }

    sets.pet["Healing Breath"] = { -- I don't know if this applies when I ask the Wyvern to do it or when the Wyvern does it regardless

    }

    ----------------------------------------------------------------
    -- WEAPONSKILLS
    ----------------------------------------------------------------

    sets.ws.default = { -- Generic physical

    }

    sets.ws["Impulse Drive"] = {
 
    }

    sets.ws["Vorpal Thrust"] = {

    }
    
    sets.ws["Wheeling Thrust"] = {

    }

    sets.ws["Penta Thrust"] = {

    }

    sets.ws["Stardiver"] = { -- Do I go for crit build or regular build? Potentially have a check for the main weapon. If Shining One, use crit.

    }

    sets.ws["Sonic Thrust"] = {

    }

    sets.ws["Cammlain's Torment"] = {

    }

    sets.ws["Drakesbane"] = {

    }

    sets.ws["Savage Blade"] = {

    }

    sets.ws["Judgement"] = {

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
    end -- Remove this end when I'm using the magic

    -- Consider spell stuff when I have actual spells. Maybe for warp and trusts?

    -- elseif spell.action_type == "Magic" then
    --     if sets.precast[spell.name] then
    --         equip_set_and_weapon(sets.precast[spell.name])
    --     else
    --         equip_set_and_weapon(sets.precast.fast_cast) -- General purpose
    --     end
    -- end

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