
---------------------------
-- Vendor Upgrade System --
---------------------------

local old_vendor_mods = string.split((minetest.setting_get("fancy_vend_old_vendor_mods") or ""), ",")
local old_vendor_mods_table = {}

for i in pairs(old_vendor_mods) do
	old_vendor_mods_table[old_vendor_mods[i]] = true
end

local base_upgrade_template = {
	description = "Shop Upgrade (Try and place to upgrade)",
	legacy_facedir_simple = true,
	paramtype2 = "facedir",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1},
	is_ground_content = false,
	light_source = 8,
	sounds = default.node_sound_wood_defaults(),
	drop = fancy_vend.drop_vendor,
	tiles = {
		"player_vend.png", "player_vend.png",
		"player_vend.png", "player_vend.png",
		"player_vend.png", "upgrade_front.png",
	},
	on_place = function(itemstack)
		return ItemStack(fancy_vend.drop_vendor.." "..itemstack:get_count())
	end,
	allow_metadata_inventory_move = function(pos, _, _, _, _, count, player)
		local meta = minetest.get_meta(pos)
		if player:get_player_name() ~= meta:get_string("owner") then return 0 end
		return count
	end,
	allow_metadata_inventory_put = function(pos, _, _, stack, player)
		local meta = minetest.get_meta(pos)
		if player:get_player_name() ~= meta:get_string("owner") then return 0 end
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, _, _, stack, player)
		local meta = minetest.get_meta(pos)
		if player:get_player_name() ~= meta:get_string("owner") then return 0 end
		return stack:get_count()
	end,
}

local clear_craft_vendors = {}

if old_vendor_mods_table["currency"] then
	local currency_template = table.copy(base_upgrade_template)

	currency_template.can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("stock") and
			inv:is_empty("customers_gave") and
			inv:is_empty("owner_wants") and
			inv:is_empty("owner_gives") and
			(meta:get_string("owner") == player:get_player_name() or
			minetest.check_player_privs(player:get_player_name(), {protection_bypass = true}))
	end
	currency_template.on_rightclick = function(pos, _, clicker)
		local meta = minetest.get_meta(pos)
		local list_name = "nodemeta:"..pos.x..","..pos.y..","..pos.z
		if clicker:get_player_name() == meta:get_string("owner") then
			minetest.show_formspec(clicker:get_player_name(),"fancy_vend:currency_shop_formspec",
				"size[8,9.5]"..
				"label[0,0;".."Customers gave:".."]"..
				"list["..list_name..";customers_gave;0,0.5;3,2;]"..
				"label[0,2.5;".."Your stock:".."]"..
				"list["..list_name..";stock;0,3;3,2;]"..
				"label[5,0;".."You want:".."]"..
				"list["..list_name..";owner_wants;5,0.5;3,2;]"..
				"label[5,2.5;".."In exchange, you give:".."]"..
				"list["..list_name..";owner_gives;5,3;3,2;]"..
				"list[current_player;main;0,5.5;8,4;]"
			)
		end
	end

	minetest.register_node(":currency:shop", currency_template)

	table.insert(clear_craft_vendors, "currency:shop")
end

if old_vendor_mods_table["easyvend"] then
	local nodes = {"easyvend:vendor", "easyvend:vendor_on", "easyvend:depositor", "easyvend:depositor_on"}
	for i in pairs(nodes) do
		minetest.register_node(":"..nodes[i], base_upgrade_template)
		table.insert(clear_craft_vendors, nodes[i])
	end
end

if old_vendor_mods_table["vendor"] then
	local nodes = {"vendor:vendor", "vendor:depositor"}
	for i in pairs(nodes) do
		minetest.register_node(":"..nodes[i], base_upgrade_template)
		table.insert(clear_craft_vendors, nodes[i])
	end
end

if old_vendor_mods_table["money"] then
	local money_template = table.copy(base_upgrade_template)
	money_template.can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("main") and
			(meta:get_string("owner") == player:get_player_name() or
			minetest.check_player_privs(player:get_player_name(), {protection_bypass = true}))
	end
	money_template.on_rightclick = function(pos, _, clicker)
		local meta = minetest.get_meta(pos)
		local list_name = "nodemeta:"..pos.x..","..pos.y..","..pos.z
		if clicker:get_player_name() == meta:get_string("owner") then
			minetest.show_formspec(clicker:get_player_name(),"fancy_vend:money_shop_formspec",
				"size[8,10;]"..
				"list["..list_name..";main;0,0;8,4;]"..
				"list[current_player;main;0,6;8,4;]"
			)
		end
	end
	local nodes = {"money:barter_shop", "money:shop", "money:admin_shop", "money:admin_barter_shop"}
	for i in pairs(nodes) do
		minetest.register_node(":"..nodes[i], money_template)
		table.insert(clear_craft_vendors, nodes[i])
	end
end

for i_n in pairs(clear_craft_vendors) do
	local currency_crafts = minetest.get_all_craft_recipes(i_n)
	if currency_crafts then
		for i in pairs(currency_crafts) do
			minetest.clear_craft(currency_crafts[i])
		end
	end
end
