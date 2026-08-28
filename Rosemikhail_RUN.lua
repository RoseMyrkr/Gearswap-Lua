---@diagnostic disable: lowercase-global, undefined-global
include("Modes.lua")

----------------------------------------------------------------
-- NOTES
----------------------------------------------------------------

--[[

SWIPE AND LUNGE DAMAGE JA Hachirin-no-obi check specific to RUN:
There are 3 terms taken into account for the Obi.
    First Weather, Second Weather, Matching Day.
    If 2/3 terms match the element of your Rune(s), Hachirin-no-Obi will be better.

May need a cry for help if I'm paralysed/sleeping/doomed.

Force SIRD set toggle would be handy - right now it's just the fallback casting set for any spells that fall through the cracks instead of switching to "idle" like I do on other luas.
- Certain abilities will want "enmity SIRD" sets - this includes Flash, Foil, Stun (/DRK) and /BLU enmity spells
- If SIRD toggle on, then check enmity spell list - if contains spell.name, equip enmity sird, otherwise, regular sird

DOOMED SET

Need to check for enmity spells and apply an enmity set
- do enmity JAs need this?



-- Maybe consider resist death set / toggle overlay or whatever?

-- Idle embolden overlay
    -- Also needs to be in my buff_change
    -- Current functionality should apply embolden gear when I gain the buff and remove it when I don't

- Update barspell logic to care about the fact that elemental and status barspells have different resistance calculations
    - i.e. status ones have a base potency, so I could just cast in conserve or idle
    - Steal from WHM

- See if hachirin no obi logic works with blu magic or if it even needs to

-- Possibly have a "casting mode" for SIRD vs effect

-- upgrade loricate torque and all of the other unm items

-- May need a force phalanx set toggle, rather than having it as an idle

-- augment aettir

-- alber strap for enmity set potentially
-- potentially fulltime utu grip or khonsu for DT + accuracy


-- I have a choice probably - do I lump in enmity JAs into a list and use a generic enmity set? Or do I keep them separate
    - Probably keep them separate so I can use the various JA improvement bits of gear
-- Okay so where does that leave spells like flash and foil? Right now they're in a list. Maybe it's better than they are, because then I can select between full enmity, safe enmity or SIRD


-- Precast needs to ignore stuff like runes


 -- Maybe I should instead do ALLOWED spell types for precast aye? Instead of ignored spell types lmao. Realistically this needs to only be JAs. Remember that they need to survive into midcast.
]]

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------

-- Modes and toggles
weapon_mode = M{"Aettir", "Naegling", "Kaja Chopper", "Kaja Axe"} -- Update these
engaged_mode = M{"Skilling", "Physical", "Parrying", "Magical", "TP"}
idle_mode = M{"Normal", "Phalanx"}

toggle_speed = "Off"
weapon_lock = "Off"

-- Midcast helpers
match_list = S{"Cure", "Regen"}
ignored_spell_types = S{"Samba", "Waltz", "Jig", "Step", "Flourish1", "Flourish2", "Scholar", "Rune", "Ward"}
enmity_spells = S{"Flash"}

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
    -- WEAPON SETS
    ----------------------------------------------------------------

    weapon_sets = {
        ["Aettir"] = {
            gear = {
                main="Aettir",
                sub="Khonsu", -- Potentially refined grip later
            },
            engaged_sets = {"Skilling", "Physical", "Parrying", "Magical", "TP"},
            overrides = {
                -- ["Magical"] = {
                --     main="Aettir",
                --     sub="Irenic Strap +1",
                -- },
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
            engaged_sets = {"TP"},
            overrides = {},
        },
        ["Kaja Chopper"] = {
            gear = {
                main="Kaja Chopper",
                sub="Khonsu",
            },
            engaged_sets = {"Skilling", "TP"},
            overrides = {},
        },
        ["Kaja Axe"] = {
            gear = {
                main="Kaja Axe",
                sub=empty,
            },
            engaged_sets = {"Skilling", "TP"},
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

    --San dOria Feet
    --Bastok Hands
    --Windurst Head
    --Jeuno Legs 

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
        --idle="",
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
    
    -- May be worth keeping a RUN +1 earring for Regen received

    sets.idle["Normal"] = { -- Used not only when running around but also for unengaged tanking
        ammo="Staunch Tathlum",     -- -2% DT, Resistance
        head="Null Masque",         -- -10% DT, 2 regain, 1 refresh
        body="Nyame Mail",          -- -9% DT  -- Consider Empyrean body for enmity retention, Consider AF body for refresh, Adamantite (if I ever get it) for more hp
        hands="Nyame Gauntlets",    -- -7% DT
        legs="Nyame Flanchard",     -- -8% DT
        feet="Nyame Sollerets",     -- -7% DT
        neck="Loricate Torque +1",  -- -6 DT
        waist="", -- Engraved Belt
        left_ear="", -- Tuisto Earring
        right_ear="", -- Odnowa Earring +1
        left_ring="", -- Gelatinous Ring +1
        right_ring="", -- Moonlight Ring or Warden's Ring
        back="Null Shawl",
    }

    sets.idle["Phalanx"] = {
        ammo="Staunch Tathlum",         -- -2% DT, Resistance, 10% SIRD
        head=jse.relic.head,
        body={ name="Herculean Vest", augments={'INT+11','Mag. Acc.+15 "Mag.Atk.Bns."+15','Phalanx +5','Accuracy+20 Attack+20',}},
        hands={ name="Herculean Gloves", augments={'CHR+8','Accuracy+26','Phalanx +5','Mag. Acc.+16 "Mag.Atk.Bns."+16',}},
        legs={ name="Herculean Trousers", augments={'INT+2','Pet: Haste+1','Phalanx +3','Mag. Acc.+10 "Mag.Atk.Bns."+10',}},
        feet={ name="Herculean Boots", augments={'Rng.Atk.+25','Crit. hit damage +1%','Phalanx +2','Accuracy+11 Attack+11','Mag. Acc.+11 "Mag.Atk.Bns."+11',}},
        neck="Loricate Torque +1",      -- -6 DT
        waist="Plat. Mog. Belt",        -- -3% DT
        left_ear="", -- Tuisto Earring
        right_ear="", -- Alabaster Earring
        left_ring="", -- Gelatinous Ring +1
        right_ring="", -- Moonbeam/light Ring
        back="", --Moonbeam/light Cape
    }

    ----------------------------------------------------------------
    -- ENGAGED
    ----------------------------------------------------------------

    -- May be worth keeping a RUN +1 earring for Regen received

    sets.engaged["Physical"] = {
        range="",
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

    sets.engaged["Parrying"] = {
        range="",
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

    sets.engaged["Magical"] = {
        range="",
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

    -- I don't expect that I'll be using this much
    sets.engaged["TP"] = {
        range=empty,
        ammo="Amar Cluster",
        head="Null Masque",
        body="Adamantite Armor",
        hands="Nyame Gauntlets",    -- -7% DT
        legs="Nyame Flanchard",     -- -8% DT
        feet="Nyame Sollerets",     -- -7% DT
        neck="Null Loop",
        waist="Null Belt",
        left_ear="Crep. Earring",
        right_ear="Regal Earring", -- Replace with Telos Earring
        left_ring="Lehko's Ring",
        right_ring="Defending Ring",
        back="Null Shawl",
    }

    --Temporary set
    sets.engaged["Skilling"] = {
        range=empty,
        ammo="Staunch Tathlum",
        head="Guide Beret",
        body=jse.relic.body,
        hands=jse.AF.hands,
        legs="Temachtiani Pants",
        feet="Temachtiani Boots",
        neck="Elite Royal Collar",
        waist="Olseni Belt",
        left_ear="Alabaster Earring",
        right_ear={ name="Erilaz Earring +1", augments={'System: 1 ID: 1676 Val: 0','Accuracy+12','Mag. Acc.+12','Damage taken-4%',}},
        left_ring="Lehko's Ring",
        right_ring="Jubilee Ring",
        back="Reiki Cloak",
    }

    -- Not sure if I'll bother having separate max DPS and hybrid TP sets. Maybe just do hybrid?

    ----------------------------------------------------------------
    -- PRECAST
    ----------------------------------------------------------------

    sets.precast.fast_cast = set_combine(sets.idle["Normal"], {
    })

    -- With Inspiration, we could potentially have very easy fast cast
    -- Maybe have a check to decide between shitty fast cast vs inspiration fast cast

    ----------------------------------------------------------------
    -- ENMITY
    ----------------------------------------------------------------
    
    -- Potentially need an enmity mode
    -- Normal enmity vs safe enmity for fights that have encumbrance

    sets.midcast.enmity = {
        range=empty,
        ammo="",
        head="",
        body="Emet Harness +1",
        hands=jse.relic.hands,
        legs=jse.empyrean.legs,
        feet="",
        neck="Unmoving Collar +1",
        waist="Rumination Sash",
        left_ear="Friomisi Earring",
        right_ear="Cryptic Earring",
        left_ring="Eihwaz Ring",
        right_ring="Petrov Ring",
        back="Reiki Cloak",

        -- Will this actually be midcast or precast? JAs and spells are different, after all.
    }

    sets.midcast.enmity_safe = {
        range="",
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

        -- Will this actually be midcast or precast? JAs and spells are different, after all.
    }

    sets.midcast["Foil"] = {
        -- Equip Futhark Trousers here
        -- Possibly inherit from enmity in general?
    }

    ----------------------------------------------------------------
    -- MAGIC
    ----------------------------------------------------------------
    
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

    sets.midcast["Enfeebling Magic"] = {}

    sets.midcast["Phalanx"] = {
        ammo="",
        head=jse.relic.head,
        body={ name="Herculean Vest", augments={'INT+11','Mag. Acc.+15 "Mag.Atk.Bns."+15','Phalanx +5','Accuracy+20 Attack+20',}},
        hands={ name="Herculean Gloves", augments={'CHR+8','Accuracy+26','Phalanx +5','Mag. Acc.+16 "Mag.Atk.Bns."+16',}},
        legs={ name="Herculean Trousers", augments={'INT+2','Pet: Haste+1','Phalanx +3','Mag. Acc.+10 "Mag.Atk.Bns."+10',}},
        feet={ name="Herculean Boots", augments={'Rng.Atk.+25','Crit. hit damage +1%','Phalanx +2','Accuracy+11 Attack+11','Mag. Acc.+11 "Mag.Atk.Bns."+11',}},
        neck="",
        waist="",
        left_ear="",
        right_ear="",
        left_ring="",
        right_ring="",
        back="",
    } -- This is for self-casting

    sets.midcast["Regen"] = {}

    -- Could potentially have a check to see if it's me or someone else I'm casting this on.
    sets.midcast["Refresh"] = {}

    sets.midcast["Aquaveil"] = {} -- We want 500 enhancing magic skill.

    sets.midcast.barspell = {} -- We want 500 enhancing magic skill.

    sets.midcast["Temper"] = {} -- We want 500 enhancing magic skill.

    sets.midcast["Stoneskin"] = {} -- Not sure how close we can get to 500 but there are specific pieces I want here.

    sets.midcast["Cure"] = {}

    sets.midcast.SIRD = {} -- General SIRD set for when I'm struggling to cast spells

    sets.midcast.SIRD_enmity = {} -- For my enmity spells when I'm struggling to cast them

    ----------------------------------------------------------------
    -- JOB ABILITIES 
    ----------------------------------------------------------------

    -- It appears that you still want the enmity set combined with whatever JAs might be used for that

    sets.ja["Valiance"] = set_combine(sets.midcast.enmity, { -- It's totally possible that I should just make the set from scratch but we'll see!
        body = jse.AF.body,
    })

    sets.ja["Vallation"] = sets.ja["Valiance"]

    sets.ja["Battuta"] = {
        -- I unno
    }

    sets.ja["Rayke"] = {
        -- I unno
    }

    sets.ja["Gambit"] = {
        -- I unno
    }

    sets.ja["Swordplay"] = {
        -- I unno
    }

    sets.ja["Elemental Sforzo"] = {
        -- I unno
    }

    sets.ja["Liement"] = {
        -- I unno
    }

    sets.ja["Vivacious Pulse"] = {
        -- I unno
    }

    sets.ja["Swipe"] = {
        -- I unno
    }

    sets.ja["Lunge"] = sets.ja["Swipe"]

    ----------------------------------------------------------------
    -- WEAPONSKILLS 
    ----------------------------------------------------------------

    sets.ws.default = { -- Obviously needs to be updated
        ammo="Oshasha's Treatise",
        head="Nyame Helm",
        body="Nyame Mail",
        hands="Nyame Gauntlets",
        legs=jse.empyrean.feet,
        feet="Nyame Sollerets",
        neck="Rep. Plat. Medal",
        waist="Grunfeld Rope",
        left_ear="Ethereal Earring",
        right_ear="Cessance Earring",
        left_ring="Rufescent Ring",
        right_ring="Rajas Ring",
        back="Alabaster Mantle",
    }

    sets.ws["Dimidiation"] = {
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

    sets.ws["Resolution"] = {
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

    sets.ws["Fimbulvetre"] = {
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

    sets.ws["Savage Blade"] = {
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

    -- Runefencer buffs
    if buffactive["Embolden"] then
        equip({""}) -- TODO: Evasionist's cape
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

        -- If the spell matches one of the match_list spells.
        for match in match_list:it() do
            if spell.name:match(match) then
                equip_set_and_weapon(sets.midcast[match])
                matched = true
                break
            end
        end

        -- If the spell is any Regen spell - More essential if we had regen modes, but we don't.
        -- Regen is now within the match list
        -- if not matched and spell.name:match("Regen") then
        --     equip_set_and_weapon(sets.midcast["Regen"])
        --     matched = true
        -- end

        -- If the spell name EXACTLY matches.
        if not matched and sets.midcast[spell.name] then
            equip_set_and_weapon(sets.midcast[spell.name])
            matched = true
        end

        -- TODO: Update this
        if not matched and spell.name:match("^Bar") then
            equip_set_and_weapon(sets.midcast.barspell)
            matched = true
        end

        -- Missing elemental

        -- Missing enfeebling

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
            equip_set_and_weapon(sets.midcast.SIRD)
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
    idle()
end

function buff_change(name, gain, buff_details)
    if not midaction() then
        if name == "Embolden" then
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

-- If I want to stop enabling when I don't need to, I could do a "last_mode" variable

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