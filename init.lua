--  /$$$$$$$$                                           /$$    /$$                          /$$
-- | $$_____/                                          | $$   | $$                         | $$
-- | $$    /$$$$$$  /$$$$$$$   /$$$$$$$ /$$   /$$      | $$   | $$ /$$$$$$  /$$$$$$$   /$$$$$$$
-- | $$$$$|____  $$| $$__  $$ /$$_____/| $$  | $$      |  $$ / $$//$$__  $$| $$__  $$ /$$__  $$
-- | $$__/ /$$$$$$$| $$  \ $$| $$      | $$  | $$       \  $$ $$/| $$$$$$$$| $$  \ $$| $$  | $$
-- | $$   /$$__  $$| $$  | $$| $$      | $$  | $$        \  $$$/ | $$_____/| $$  | $$| $$  | $$
-- | $$  |  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$         \  $/  |  $$$$$$$| $$  | $$|  $$$$$$$
-- |__/   \_______/|__/  |__/ \_______/ \____  $$          \_/    \_______/|__/  |__/ \_______/
--                                      /$$  | $$
--                                     |  $$$$$$/
--                                      \______/
--
-- A full-featured, fully-integrated vendor mod for Minetest

fancy_vend = {
  display_node = (minetest.settings:get("fancy_vend.display_node") or "default:obsidian_glass"),
  max_logs = (tonumber(minetest.settings:get("fancy_vend.log_max")) or 40),
  autorotate_speed = (tonumber(minetest.settings:get("fancy_vend.autorotate_speed")) or 1),
  no_alerts = minetest.settings:get_bool("fancy_vend.no_alerts"),
  drop_vendor = "fancy_vend:player_vendor"
}

local MP = minetest.get_modpath("fancy_vend")
dofile(MP.."/display_node.lua")
dofile(MP.."/privileges.lua")
dofile(MP.."/utils.lua")
dofile(MP.."/disable_global.lua")
dofile(MP.."/awards.lua")
dofile(MP.."/display_item.lua")
dofile(MP.."/functions.lua")
dofile(MP.."/inventory_helpers.lua")
dofile(MP.."/integrations.lua")
dofile(MP.."/purchase.lua")
dofile(MP.."/formspecs.lua")
dofile(MP.."/node_helpers.lua")
dofile(MP.."/receive_fields.lua")
dofile(MP.."/vendor_node.lua")
dofile(MP.."/copy_tool.lua")
dofile(MP.."/upgrade.lua")
