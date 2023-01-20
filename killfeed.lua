--[[

Killfeed: Ignore, this script was made since my friends didn't have killfeed, but that just a msxml issue
'
]]--

--	config

--	end of config

api_version = "1.9.0.0"

function OnScriptLoad()
end

function die(PlayerIndex, KillerIndex)
	local victimname = get_var(PlayerIndex, "$name")
	if(PlayerIndex == KillerIndex) then
		say_all(victimname .. " committed suicide")	
	elseif (tonumber(KillerIndex) > 0) then
		local killername = get_var(KillerIndex, "$name")
		say_all(killername .. " killed " .. victimname)
	else
		say_all(victimname .. " died")
	end
end

function OnScriptUnload()	
end
