--[[

Fiesta: Players spawn with random weapons

Gametypes: fiesta or teamfiesta

]]--

-- config

-- end of config

api_version = "1.9.0.0"

local weapons = {
	"weapons\\plasma pistol\\plasma pistol",
	"weapons\\plasma rifle\\plasma rifle",
	"weapons\\assault rifle\\assault rifle",
	"weapons\\sniper rifle\\sniper rifle",
	"weapons\\pistol\\pistol",
	"weapons\\needler\\mp_needler",
	"weapons\\shotgun\\shotgun",
	"weapons\\flamethrower\\flamethrower",
	"weapons\\plasma_cannon\\plasma_cannon",
	"weapons\\rocket launcher\\rocket launcher",
}

local max_weapon = table.getn(weapons)

local tag_ids = { }

function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"startfiesta")
end

function startfiesta()
    local mode = get_var(0, "$mode")
	if (mode == "fiesta" or mode == "teamfiesta") then
		register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
		register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn")
		register_callback(cb['EVENT_OBJECT_SPAWN'],"OnObjectSpawn")
        register_callback(cb['EVENT_DIE'],"OnPlayerDie")
	end
end

function OnGameEnd()
	unregister_callback(cb['EVENT_SPAWN'])
    unregister_callback(cb['EVENT_OBJECT_SPAWN'])
    unregister_callback(cb['EVENT_DIE'])
end

function OnPlayerSpawn(player_index)
	execute_command("wdel " .. player_index)
	local weapon_num = get_random_weapon_index()
	give_weapon(weapon_num, player_index)
    give_weapon(get_random_weapon_index(weapon_num), player_index)
end

function get_random_weapon_index(exclude)
    if exclude == nil then return rand(1, max_weapon + 1) end
    local i = 0
    while i < 50 do
        local maybe = rand(1, max_weapon + 1)
        if (maybe ~= exclude) then return maybe end
        i = i + 1
    end
    return 1
end

function give_weapon(weapon_num, player_index)
	local tag = lookup_tag("weap", weapons[weapon_num])
	local meta_id = read_dword(tag + 0xC)
	tag_ids[meta_id] = true
	local weapon = spawn_object("weap", "ignorethis", 0, 0, 0, 0, meta_id)
	assign_weapon(weapon, player_index)
end

function OnObjectSpawn(player_index, tag_id, parent_id, new_obj_id)
    if player_index == 0 and not tag_ids[tag_id] then
        return false
    end
    tag_ids[tag_id] = false -- cheeky
end

function OnPlayerDie(player_index, killer_string)
    execute_command("wdrop " .. player_index) -- so only the currently held weapon gets dropped
    execute_command("wdel " .. player_index)
end

function OnScriptUnload()	end
