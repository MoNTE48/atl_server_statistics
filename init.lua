atl_server_statistics = {
	S = minetest.get_translator("atl_server_statistics"),
	mod_storage = minetest.get_mod_storage(),
	statistics = {"Messages Count", "Deaths Count", "Kills Count", "Nodes Dug", "Nodes Placed", "Items Crafted", "PlayTime"},
	color_message = "",
	reset_color_message = "#bce712",
	time_before_end_request = 30,
	reset_requests = {},
}

function atl_server_statistics.load_file(path)
	local status, err = pcall(dofile, path)
	if not status then
		minetest.log("error", "-!- Failed to load file: " .. path .. " - Error: " .. err)
	else
		minetest.log("action", "-!- Successfully loaded file: " .. path)
	end
end

local modpath = minetest.get_modpath("atl_server_statistics")

local files_to_load = {
	"script/storage.lua",
	"script/event.lua",
	"script/command.lua",
	"script/util.lua",
	"script/formspec.lua",
}

for _, file in ipairs(files_to_load) do
	atl_server_statistics.load_file(modpath .. "/" .. file)
end
