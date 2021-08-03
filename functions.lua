

function fancy_vend.send_message(pos, channel, msg)
	if channel and channel ~= "" then
		digilines.receptor_send(pos, digilines.rules.default, channel, msg)
	end
end


function fancy_vend.set_vendor_settings(pos, SettingsDef)
	local meta = minetest.get_meta(pos)
	meta:set_string("settings", minetest.serialize(SettingsDef))
end

function fancy_vend.reset_vendor_settings(pos)
	local settings_default = {
		input_item = "", -- Don't change this unless you plan on setting this up to add this item to the inventories
		output_item = "", -- Don't change this unless you plan on setting this up to add this item to the inventories
		input_item_qty = 1,
		output_item_qty = 1,
		admin_vendor = false,
		depositor = false,
		currency_eject = false,
		accept_output_only = false,
		split_incoming_stacks = false,
		inactive_force = false,
		accept_worn_input = true,
		accept_worn_output = true,
		digiline_channel = "",
		co_sellers = "",
		banned_buyers = "",
		auto_sort = false,
	}
	fancy_vend.set_vendor_settings(pos, settings_default)
	return settings_default
end

function fancy_vend.get_vendor_settings(pos)
	local meta = minetest.get_meta(pos)
	local settings = minetest.deserialize(meta:get_string("settings"))
	if not settings then
		return fancy_vend.reset_vendor_settings(pos)
	else
		-- If settings added by newer versions of fancy_vend are nil then send defaults
		if settings.auto_sort == nil then
			settings.auto_sort = false
		end

		-- Sanitatize number values (backwards compat)
		settings.input_item_qty = (
			type(settings.input_item_qty) == "number" and
			math.abs(settings.input_item_qty) or 1
		)
		settings.output_item_qty = (
			type(settings.output_item_qty) == "number" and
			math.abs(settings.output_item_qty) or 1
		)
		return settings
	end
end



function fancy_vend.can_buy_from_vendor(pos, player)
	local player_name = player:get_player_name()
	local settings = fancy_vend.get_vendor_settings(pos)
	local banned_buyers = string.split((settings.banned_buyers or ""), "[, ]+", false, nil, true)
	for _, name in pairs(banned_buyers) do
		if name == player_name then
			return false
		end
	end
	return true
end

function fancy_vend.can_modify_vendor(pos, player)
	local meta = minetest.get_meta(pos)
	local is_owner = false
	if meta:get_string("owner") == player:get_player_name() or
		minetest.check_player_privs(player, {protection_bypass = true}) then
		is_owner = true
	end
	return is_owner
end

function fancy_vend.can_dig_vendor(pos, player)
	local inv = minetest.get_meta(pos):get_inventory()
	return inv:is_empty("main") and fancy_vend.can_modify_vendor(pos, player)
end

function fancy_vend.can_access_vendor_inv(player, pos)
	local player_name = player:get_player_name()
	local meta = minetest.get_meta(pos)
	if minetest.check_player_privs(player, {protection_bypass = true}) or
		meta:get_string("owner") == player_name then
		return true
	end
	local settings = fancy_vend.get_vendor_settings(pos)
	local co_sellers = string.split((settings.co_sellers or ""), "[, ]+", false, nil, true)
	for _, name in pairs(co_sellers) do
		if name == player_name then
			return true
		end
	end
	return false
end
