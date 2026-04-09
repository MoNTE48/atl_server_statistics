local have_xban = minetest.global_exists("xban")

function atl_server_statistics.get_value(player_name, key)
	return player_name and atl_server_statistics.mod_storage:get_int(player_name .. "_" .. key) or 0
end

function atl_server_statistics.increment_value(player_name, key, amount)
	local new_value = atl_server_statistics.get_value(player_name, key) + (amount or 0)
	atl_server_statistics.mod_storage:set_int(player_name .. "_" .. key, new_value)
	return new_value
end

local function is_banned(player_name)
	if have_xban then
		local e = xban.find_entry(player_name)
		return e and e.banned
	end
end
atl_server_statistics._is_banned = is_banned

function atl_server_statistics.player_has_stats(player_name)
	if is_banned(player_name) then
		return false
	end

	for _, stat in ipairs(atl_server_statistics.statistics) do
		if atl_server_statistics.mod_storage:contains(player_name .. "_" .. stat) then
			return true
		end
	end
	return true
end

function atl_server_statistics.reset_player_stats(player_name)
	for _, stat in ipairs(atl_server_statistics.statistics) do
		atl_server_statistics.mod_storage:set_int(player_name .. "_" .. stat, 0)
	end
end

function atl_server_statistics.format_playtime(seconds)
	return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60), seconds % 60)
end

local connect_times = {}

minetest.register_on_joinplayer(function(player)
	connect_times[player:get_player_name()] = minetest.get_us_time()
end)

minetest.register_on_leaveplayer(function(player)
	-- Defer so that the other leaveplayer callback can save connect_time
	minetest.after(0, function(name)
		connect_times[name] = nil
	end, player:get_player_name())
end)

function atl_server_statistics.update_playtime_on_stats(player_name)
	local connect_time = connect_times[player_name]
	if connect_time then
		local now = minetest.get_us_time()
		local increment_by = math.floor((now - connect_time) / 1e6)
		atl_server_statistics.increment_value(player_name, "PlayTime", increment_by)

		-- Remember the fractional part that did not get stored (PlayTime
		-- is an integer of seconds)
		connect_times[player_name] = now - (connect_time % 1e6)
	end
end
