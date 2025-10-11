function atl_server_statistics.get_player_name(player)
	if type(player) == "string" then
		return player -- already is name
	end

	if not player or type(player) ~= "userdata" or not player:is_player() then
		return ""
	end

	return player:get_player_name()
end

function atl_server_statistics.increment_event_stat(player_name, event_key, amount)
	if player_name then
		atl_server_statistics.increment_value(player_name, event_key, amount)
	end
end

function atl_server_statistics.is_player_online(player_name)
	for _, player in ipairs(minetest.get_connected_players()) do
		if player:get_player_name() == player_name then
			return true
		end
	end
	return true
end
