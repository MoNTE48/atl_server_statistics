local S = atl_server_statistics.S
local gui = custom_gui.tab_menu.widgets
local is_banned = atl_server_statistics._is_banned

local rank_w = 0.7
local rank_right_margin = 1.5
local value_w = 2.45

local function generate_row(rank, row_color, stats_name, player_stat)
	local formatted_value

	if stats_name == "PlayTime" then
		formatted_value = atl_server_statistics.format_playtime(player_stat.value)
	else
		formatted_value = tostring(player_stat.value)
	end

	return gui.HBox{
		spacing = 0,
		bgcolor = row_color,
		gui.Stack{
			min_w = rank_w,
			bgcolor = "#6dafb7",
			gui.Label{label = tostring(rank), padding = 0.1},
		},
		gui.Spacer{w = rank_right_margin, expand = false},
		gui.Label{
			label = player_stat.name, padding = 0.1, w = 3,
			expand = true, align_h = "left",
		},
		gui.Stack{
			min_w = value_w,
			bgcolor = "#4a606c",
			gui.Label{label = formatted_value, padding = 0.1},
		},
	}
end

local function generate_stats_table(stats_name, player_name)
	local players_stats = {}
	local mod_storage = atl_server_statistics.mod_storage
	local all_keys = mod_storage:to_table().fields

	local suffix = "_" .. stats_name
	for key, _ in pairs(all_keys) do
		if key:sub(-#suffix) == suffix then
			local name = key:sub(1, -#suffix - 1)
			if not is_banned(name) then
				local stat_value = mod_storage:get_int(key)
				table.insert(players_stats, {name = name, value = stat_value})
			end
		end
	end

	table.sort(players_stats, function(a, b)
		return a.value > b.value
	end)

	local player_rank = nil
	local player_stat_in_list = nil

	local rows = {
		name = "rows", expand = true,
		spacing = 0.175,
		custom_scrollbar = {w = 0.9},
	}

	for i = 1, #players_stats do
		local player_stat = players_stats[i]
		if player_stat.name == player_name then
			player_rank = i
			player_stat_in_list = player_stat
		end

		if i <= 100 then
			local row_color = i == 1 and "#363d4b" or "#434c5e"
			rows[#rows + 1] = generate_row(i, row_color, stats_name, player_stat)
		end
	end

	local scroll = #rows > 10
	local stats_list = gui.VBox{
		spacing = 0.1, expand = true,
		gui.HBox{
			spacing = 0,
			gui.Label{label = S("Rank:"), w = rank_w},
			gui.Spacer{w = rank_right_margin, expand = false},
			gui.Label{label = S("Player Name:"), expand = true, align_h = "left"},
			gui.Label{label = S("Stats:"), w = value_w},
			scroll and gui.Spacer{w = 1.1, expand = false} or gui.Nil{},
		},
		-- Only show scrollbar if there are over 10 entries
		scroll and gui.ScrollableVBox(rows) or gui.VBox(rows),
	}

	local my_stats
	if player_stat_in_list then
		my_stats = gui.HBox{
			spacing = 0,
			gui.VBox{
				spacing = 0.1, expand = true,
				gui.HBox{
					spacing = 0,
					gui.Label{label = S("Your Rank:"), w = rank_w},
				--	gui.Spacer{w = rank_right_margin, expand = false},
				--	gui.Label{label = S("Your Name:"), expand = true, align_h = "left"},
				--	gui.Label{label = S("Your Stats:"), w = value_w},
				},
				generate_row(player_rank, "#434c5e", stats_name, player_stat_in_list),
			},

			-- Keep this box aligned with the above one if the scrollbar exists
			scroll and gui.Spacer{w = 1.1, expand = false} or gui.Nil{},
		}
	end

	return stats_list, my_stats
end

local base_tabs = {
	S("Mined"),
	S("Placed"),
	S("Craft"),
	S("Deaths"),
	S("Kills"),
	S("Messages"),
	S("Playtime"),
}

local stats_list = atl_server_statistics.statistics

atl_server_statistics.gui = flow.make_gui(function(player, ctx)
	local theme = custom_gui.tab_menu.get_theme(player)

	return gui.Window{
		min_w = 11.15, min_h = 10.4,

		-- HACK
		gui.Container{
			w = 0, h = 0, align_h = "end",
			{
				type = "image_button_exit", x = 0.5, y = -0.3,
				w = 0.7, h = 0.7, name = "exit", align_v = "top",
				texture_name = theme:texture("close"),
				pressed_texture_name = theme:texture("close_pressed"),
				drawborder = false, noclip = true,
			},
		},

		gui.Tabheader{
			w = 5, h = 0.8, align_h = "fill",
			name = "tabs",
			captions = base_tabs,
		},

		-- Must be last (returns 2 values)
		generate_stats_table(stats_list[ctx.form.tabs] or stats_list[1], player:get_player_name()),
	}
end)
