--[[

One in the Chamber: Players with only one bullet, all melee and bullets are one shot kills.
Every kill grants another bullet, 3 lives per player

Gametypes: one

]]--

--	config

--	end of config

api_version = "1.9.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_GAME_START'],"startgame")
end

function startgame()
	if (get_var(0, "$mode") == "one") then 
		execute_command("disable_all_objects 0 1")
		register_callback(cb['EVENT_GAME_END'],"endgame")
		register_callback(cb['EVENT_SPAWN'],"playerspawn")
		register_callback(cb['EVENT_DAMAGE_APPLICATION'],"playerdamage")
		register_callback(cb['EVENT_JOIN'],"playerjoin")
		register_callback(cb['EVENT_DIE'],"playerdie")
	end
end
function playerjoin(PlayerIndex)
	execute_command("var_add lives 4")
	execute_command("var_set lives 3 " .. PlayerIndex)
end

function playerspawn(PlayerIndex)
	execute_command("wdel " .. PlayerIndex) -- remove weapons
    local tag_id = lookup_tag("weap", "weapons\\pistol\\pistol")
    local meta_id = read_dword(tag_id + 0xC)
    -- say_all(meta_id)
    local pistol = spawn_object("weap", "ignorethis", 0, 0, 0, 0, meta_id)
    assign_weapon(pistol, PlayerIndex)
	execute_command("mag " .. PlayerIndex .. " 1 5") -- one in the mag
	execute_command("ammo " .. PlayerIndex .. " 0 5") -- zero in the bag
	execute_command("nades " .. PlayerIndex .. " 0") -- no nades
end

function playerdamage(PlayerIndex, Causer, MetaID, Damage)
	if(Causer ~= 0 and player_present(Causer)) then
		execute_command("mag " .. Causer .. " +1")
		execute_command("score " .. Causer .. " +9")
		-- say_all(MetaID)
		return true, 5000
	end
end
function playerdie(PlayerIndex, Causer)
	execute_command("var_set lives -1 " .. PlayerIndex)
	local lives = get_var(PlayerIndex, "$lives")
	if (lives == "0") then
		for i = 1,16,1
		do
			if (i ~= PlayerIndex) then
				execute_command("score " .. i .. " +5")
				say(i, "Survivor Bonus: +5")
			end
		end
	end
end

function endgame()	-- clean up
	execute_command("disable_all_objects 0 0")
	execute_command("var_del lives")
	unregister_callback(cb['EVENT_DAMAGE_APPLICATION'])
	unregister_callback(cb['EVENT_DIE'])
	unregister_callback(cb['EVENT_SPAWN'])
	unregister_callback(cb['EVENT_JOIN'])	
end

function OnScriptUnload()	end
