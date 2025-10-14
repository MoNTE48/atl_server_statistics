local S = atl_server_statistics.S

local function generate_row(rank, y, row_color, stats_name, player_stat)
	local formatted_value

	if stats_name == "PlayTime" then
		formatted_value = atl_server_statistics.format_playtime(player_stat.value)
	else
		formatted_value = tostring(player_stat.value)
	end

	return
		"box[0.3," .. y .. ";11.15,0.6;" .. row_color .. "]" ..
		"box[9," .. y .. ";2.45,0.6;#6dafb7]" ..
		"box[0.3," .. y .. ";0.7,0.6;#4a606c]" ..
		"label[0.4," .. y + 0.3 .. ";" .. rank .. "]" ..
		"label[2.6," .. y + 0.3 .. ";" .. player_stat.name .. "]" ..
		"label[9.1," .. y + 0.3 .. ";" .. formatted_value .. "]"
end

function atl_server_statistics.generate_stats_table(stats_name, player_name)
	local players_stats = {}
	local mod_storage = atl_server_statistics.mod_storage
	local all_keys = mod_storage:to_table().fields

	for key, _ in pairs(all_keys) do
		if key:find("_" .. stats_name) then
			local name = key:sub(1, -(#stats_name + 2))
			local stat_value = mod_storage:get_int(key)
			table.insert(players_stats, {name = name, value = stat_value})
		end
	end

	table.sort(players_stats, function(a, b)
		return a.value > b.value
	end)

	local result_lines = ""
	local player_rank = nil
	local player_stat_in_list = nil

	for i = 1, #players_stats do
		local player_stat = players_stats[i]
		if player_stat.name == player_name then
			player_rank = i
			player_stat_in_list = player_stat
		end

		if i <= 10 then
			local row_color = i == 1 and "#363d4b" or "#434c5e"
			local y = 1.8 + (i - 1) * 0.775
			result_lines = result_lines ..
				generate_row(i, y, row_color, stats_name, player_stat)
		end
	end

	if player_stat_in_list then
		result_lines = result_lines ..
			generate_row(player_rank, 10.1, "#434c5e", stats_name, player_stat_in_list)
	end
	return result_lines
end

local base_tabs = table.concat({
--	S("Messages"),
	S("Playtime"),
	S("Mined"),
	S("Placed"),
	S("Craft"),
	S("Deaths"),
	S("Kills"),
}, ",")

function atl_server_statistics.create_base_formspec(selected_tab, player)
	local formspec = "formspec_version[4]size[11.75,11]" ..
		"tabheader[0.3,1.1;10.25,0.8;leaderboard_tabs;" .. base_tabs .. ";" .. selected_tab .. ";true;true]"

	if minetest.global_exists("inv_themes") then
		local theme = inv_themes.get_theme(player)
		formspec = formspec .. theme:close_btn()
	else
		formspec = formspec ..
			"image_button_exit[10.75,0.3;0.7,0.7;close.png;exit;;true;false;close_pressed.png]"
	end

	formspec = formspec ..
		"label[0.3,1.5;" .. S("Rank:") .. "]" ..
		"label[2.5,1.5;" .. S("Player Name:") .. "]" ..
		"label[9,1.5;" .. S("Stats:") .. "]" ..
		"label[0.3,9.8;" .. S("Your Rank:") .. "]" ..
		"label[2.5,9.8;" .. S("Your Name:") .. "]" ..
		"label[9,9.8;" .. S("Your Stats:") .. "]"

	return formspec
end
