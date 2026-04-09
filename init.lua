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

-- Remove the old "connect_time" field
local mod_storage = atl_server_statistics.mod_storage
if mod_storage:get_int("removed_connect_time") == 0 then
	for field in pairs(mod_storage:to_table().fields) do
		if field:sub(-13) == "_connect_time" then
			mod_storage:set_string(field, "")
		end
	end
	mod_storage:set_int("removed_connect_time", 1)
end
