--[[

Gun Game: Players work through a rotation of weapons, each kill grants a new weapon

Gametypes: gungame

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
	"weapons\\plasma_cannon\\plasma_cannon",
	"weapons\\flamethrower\\flamethrower",
	"weapons\\shotgun\\shotgun",
	"weapons\\needler\\mp_needler",
	"weapons\\pistol\\pistol",
	"weapons\\sniper rifle\\sniper rifle",
	"weapons\\assault rifle\\assault rifle",
	"weapons\\plasma rifle\\plasma rifle",
	"weapons\\plasma pistol\\plasma pistol",
	"weapons\\ball\\ball"
}

local score_limit = table.getn(weapons) * 10

local melee_ids = { }

local player_data = { }

local oddball_id = 0

function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"startgungame")
end

function startgungame()
	if (get_var(0, "$mode") == "gungame") then
		execute_command("disable_all_objects 0 1")
		execute_command("scorelimit " .. score_limit)
		register_callback(cb['EVENT_JOIN'],"OnPlayerJoin")
		register_callback(cb['EVENT_DIE'],"OnPlayerDie")
		register_callback(cb['EVENT_GAME_END'],"OnGameEnd")
		register_callback(cb['EVENT_SPAWN'],"OnPlayerSpawn") 
		register_callback(cb['EVENT_DAMAGE_APPLICATION'],"OnDamageApplication")
		register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
		register_callback(cb['EVENT_WEAPON_DROP'], "OnWeaponDrop")
		for i,weapon_string in ipairs(weapons) do
			local melee_string = string.match(weapon_string, '^[^\\]+\\[^\\]+\\') .. "melee"
			if (string.match(weapon_string, "plasma_cannon")) then -- since plasma_cannon isn't simple
				melee_string = "weapons\\plasma_cannon\\effects\\plasma_cannon_melee"
			end
			local melee_tag = lookup_tag("jpt!", melee_string) -- if this doesn't work, server crashes
			local melee_id = read_dword(melee_tag + 0xC)
			melee_ids[melee_id] = true
			if (string.match(weapon_string, "ball")) then -- take note of oddball_id
				oddball_id = melee_id
			end
		end
	end
end

function OnGameEnd()
	execute_command("disable_all_object 0 0")
	unregister_callback(cb['EVENT_JOIN'])
	unregister_callback(cb['EVENT_DIE'])
	unregister_callback(cb['EVENT_SPAWN'])
	unregister_callback(cb['EVENT_DAMAGE_APPLICATION'])
	unregister_callback(cb['EVENT_LEAVE'])
	unregister_callback(cb['EVENT_WEAPON_DROP'])
end

function OnPlayerJoin(player_index)
	player_data[player_index] = {
		weapon_num = 1,
		dmg_id = 0,
		weapon_id = 0
	}
end
function OnPlayerLeave(player_index)
	player_data[player_index] = nil
end
function set_weapon(player_index)
	execute_command("wdel " .. player_index)
	local weapon_num = player_data[player_index].weapon_num
	local tag = lookup_tag("weap", weapons[weapon_num])
	local meta_id = read_dword(tag + 0xC)
	local weapon = spawn_object("weap", "ignorethis", 0, 0, 0, 0, meta_id)
	player_data[player_index].weapon_id = weapon
	assign_weapon(weapon, player_index)
	execute_command("nades " .. player_index .. " 0")
end

function OnPlayerSpawn(player_index)
	set_weapon(player_index)
end

function OnDamageApplication(player_index, causer_index, meta_id, damage, hit_string, back_tap) 
	if causer_index < 1 or player_index == causer_index then return end
	player_data[causer_index].dmg_id = meta_id
	if (melee_ids[meta_id]) then -- one shot melees
		return true, damage * 4
	end
end

function demote(player_index)
	local weapon_num = player_data[player_index].weapon_num
	if (weapon_num > 1) then
		player_data[player_index].weapon_num = weapon_num - 1
	end
	set_score(player_index)
end

function OnWeaponDrop(player_index)
	local weapon_id = player_data[player_index].weapon_id
	if (weapon_id ~= nil) then
		say(player_index, "Press melee to use oddball")
		assign_weapon(weapon_id, player_index)
	end
end

function OnPlayerDie(player_index, killer_string)
	local killer_index = tonumber(killer_string)
	if (killer_index < 1 or killer_index == player_index) then
		demote(player_index)
		return
	end
	local meta_id = player_data[killer_index].dmg_id
	if (melee_ids[meta_id] and meta_id ~= oddball_id) then
		demote(player_index)
		player_data[killer_index].dmg_id = 0
		set_score(killer_index)
		return
	elseif (meta_id ~= 0) then
		--promote killer
		player_data[killer_index].weapon_num = player_data[killer_index].weapon_num + 1
		--clear dmg_id of killer
		player_data[killer_index].dmg_id = 0
		set_score(killer_index)
		set_weapon(killer_index)
		return
	end
end

function set_score(player_index)
	local weapon_num = player_data[player_index].weapon_num
	local score = (weapon_num - 1) * 10
	execute_command("score " .. player_index .. " " .. score)
end

function OnScriptUnload()	end
