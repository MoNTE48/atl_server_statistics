atl_server_statistics = {
	S = minetest.get_translator("atl_server_statistics"),
	mod_storage = minetest.get_mod_storage(),
	statistics = {
		"Nodes Dug", "Nodes Placed", "Items Crafted",
		"Deaths Count", "Kills Count",
		"Messages Count", "PlayTime",
	},
	color_message = "",
	reset_color_message = "#bce712",
	time_before_end_request = 30,
	reset_requests = {},
}

local modpath = minetest.get_modpath("atl_server_statistics")

local files_to_load = {
	"script/storage.lua",
	"script/event.lua",
	"script/command.lua",
	"script/util.lua",
	"script/gui.lua",
}

for _, file in ipairs(files_to_load) do
	dofile(modpath .. "/" .. file)
end
