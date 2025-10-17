local S = atl_server_statistics.S

local reset_stat_alias_keys = {"playtime", "craft", "place", "mine", "kill", "death"}

local reset_stat_alias_map = {
	playtime = {key = "PlayTime", label = S("Playtime")},
	craft = {key = "Items Crafted", label = S("Craft")},
	place = {key = "Nodes Placed", label = S("Placed")},
	mine = {key = "Nodes Dug", label = S("Mined")},
	kill = {key = "Kills Count", label = S("Kills")},
	death = {key = "Deaths Count", label = S("Deaths")},
}

local function send_reset_message(player_name, message, is_confirmation)
	if is_confirmation then
		return minetest.chat_send_player(player_name,
			minetest.colorize(atl_server_statistics.reset_color_message, message))
	end
	return minetest.chat_send_player(player_name, message)
end

local function send_invalid_usage(player_name)
	send_reset_message(player_name, S("-!- Invalid command usage"), false)
	local help_command = minetest.registered_chatcommands["help"]
	if help_command and help_command.func then
		local _, help_message = help_command.func(player_name, "reset")
		if help_message and help_message ~= "" then
			for line in help_message:gmatch("[^\n]+") do
				send_reset_message(player_name, line, false)
			end
		end
	else
		local command_definition = minetest.registered_chatcommands["reset"] or {}
		local params = command_definition.params or ""
		local description = command_definition.description or S("Allows you to reset statistics after confirmation")
		local usage_line
		if params ~= "" then
			usage_line = "/reset " .. params .. ": " .. description
		else
			usage_line = "/reset: " .. description
		end
		send_reset_message(player_name, usage_line, false)
	end
end

minetest.register_chatcommand("stats", {
	description = S("Allows you to display your current statistics or those of a target player"),
	params = "<player_name>",
	func = function(player_name, param)
		local target_player_name = param ~= "" and param or player_name
		if not atl_server_statistics.player_has_stats(target_player_name) then
			return minetest.chat_send_player(player_name,
				minetest.colorize(atl_server_statistics.color_message, S("-!- No statistics available for @1.", target_player_name)))
		end
		if atl_server_statistics.is_player_online(target_player_name) then
			atl_server_statistics.update_playtime_on_stats(target_player_name)
		end
		local stats_message = S("-!- Statistics of @1:", target_player_name) .. " "
		for _, stat in ipairs(atl_server_statistics.statistics) do
			local value = atl_server_statistics.get_value(target_player_name, stat)
			if value > 0 then
				stats_message = stats_message .. string.format("%s %s  |  ", stat, (stat == "PlayTime" and atl_server_statistics.format_playtime(value)) or value)
			end
		end
		minetest.chat_send_player(player_name, minetest.colorize(atl_server_statistics.color_message, stats_message))
	end,
})

minetest.register_chatcommand("reset", {
	description = S("Allows you to reset your statistics or specific stats of others after confirmation"),
	params = "<none | name stat | list>",
	func = function(player_name, param)
		local param_value = param or ""
		if param_value ~= "" then
			if param_value:lower() == "list" then
				local stats_label = S("Statistics:")
				local stats_names = table.concat(reset_stat_alias_keys, ", ")
				local message = stats_label .. " " .. stats_names
				send_reset_message(player_name, message, false)
				return
			end
			local args = {}
			for word in param_value:gmatch("%S+") do
				table.insert(args, word)
			end
			if #args == 2 then
				if not minetest.check_player_privs(player_name, {ban = true}) then
					send_reset_message(player_name,
						S("-!- You do not have permission to reset other players' statistics."), false)
					return
				end
				local target_player_name = args[1]
				local stat_alias_input = args[2]
				local stat_alias = stat_alias_input:lower()
				local stat_entry = reset_stat_alias_map[stat_alias]
				if not stat_entry then
					send_invalid_usage(player_name)
					return
				end
				if not minetest.player_exists(target_player_name) then
					send_reset_message(player_name,
						S("-!- Player @1 is not registered.", target_player_name), false)
					return
				end
				if not atl_server_statistics.player_has_stats(target_player_name) then
					send_reset_message(player_name,
						S("-!- No statistics available for @1.", target_player_name), false)
					return
				end
				local current_time = os.time()
				local request_entry = atl_server_statistics.reset_requests[player_name]
				if type(request_entry) == "table" and request_entry.type == "target"
					and request_entry.target == target_player_name and request_entry.stat_key == stat_entry.key then
					if current_time - request_entry.timestamp <= atl_server_statistics.time_before_end_request then
						atl_server_statistics.reset_single_stat(target_player_name, stat_entry.key)
						send_reset_message(player_name,
							S("-!- Statistic @1 for @2 has been reset.", stat_entry.label, target_player_name), false)
						atl_server_statistics.reset_requests[player_name] = nil
					else
						atl_server_statistics.reset_requests[player_name] = {
							type = "target",
							target = target_player_name,
							stat_key = stat_entry.key,
							timestamp = current_time,
						}
						send_reset_message(player_name,
							S("-!- Statistics reset request has expired. Please try again."), false)
					end
				else
					atl_server_statistics.reset_requests[player_name] = {
						type = "target",
						target = target_player_name,
						stat_key = stat_entry.key,
						timestamp = current_time,
					}
					send_reset_message(player_name,
						S("-!- To confirm resetting @1 for @2, type /reset @3 again within the next @4 seconds.",
							stat_entry.label, target_player_name,
							target_player_name .. " " .. stat_alias,
							atl_server_statistics.time_before_end_request), true)
				end
				return
			end
			send_invalid_usage(player_name)
			return
		end

		local current_time = os.time()
		local request_entry = atl_server_statistics.reset_requests[player_name]
		if type(request_entry) == "table" and request_entry.type == "self" then
			if current_time - request_entry.timestamp <= atl_server_statistics.time_before_end_request then
				atl_server_statistics.reset_player_stats(player_name)
				send_reset_message(player_name, S("-!- Your statistics have been reset."), true)
				atl_server_statistics.reset_requests[player_name] = nil
			else
						atl_server_statistics.reset_requests[player_name] = {type = "self", timestamp = current_time}
						send_reset_message(player_name, S("-!- Statistics reset request has expired. Please try again."), false)
						return
			end
		else
					atl_server_statistics.reset_requests[player_name] = {type = "self", timestamp = current_time}
					send_reset_message(player_name,
						S("-!- To confirm the reset of your statistics, type /reset again within the next @1 seconds.", atl_server_statistics.time_before_end_request),
						true)
		end
	end,
})

minetest.register_chatcommand("leaderboard", {
	description = S("Displays the leaderboard with tabs for each statistics domain"),
	func = function(player_name)
		local player = minetest.get_player_by_name(player_name)
		if atl_server_statistics.is_player_online(player_name) then
			atl_server_statistics.update_playtime_on_stats(player_name)
		end

		atl_server_statistics.gui:show(player)
	end,
})

if minetest.settings:get_bool("atl_server_statistics.simplified_command") ~= true then
	minetest.register_chatcommand("s", minetest.registered_chatcommands["stats"])
	minetest.register_chatcommand("ld", minetest.registered_chatcommands["leaderboard"])
end
