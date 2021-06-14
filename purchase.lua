

function fancy_vend.make_purchase(pos, player, lots)
	if not fancy_vend.can_buy_from_vendor(pos, player) then
		return false, "You cannot purchase from this vendor"
	end

	local settings = fancy_vend.get_vendor_settings(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local player_inv = player:get_inventory()
	local status, errorcode = fancy_vend.get_vendor_status(pos)

	-- Double check settings, vendors which were incorrectly set up before this bug fix won't matter anymore
	settings.input_item_qty = math.abs(settings.input_item_qty)
	settings.output_item_qty = math.abs(settings.output_item_qty)

	if status then
		-- Get input and output quantities after multiplying by lot count
		local output_qty = settings.output_item_qty * lots
		local input_qty = settings.input_item_qty * lots

		-- Perform inventory checks
		local ct = fancy_vend.run_inv_checks(pos, player, lots)

		if ct.player_has then
			if ct.player_fits then
				if settings.admin_vendor then
					minetest.log("action", player:get_player_name().." trades "..
						settings.input_item_qty.." "..settings.input_item.." for "..
						settings.output_item_qty.." "..settings.output_item..
						" using vendor at "..minetest.pos_to_string(pos)
					)

					fancy_vend.inv_remove(player_inv, "main", ct.player_item_table, settings.input_item, input_qty)
					fancy_vend.inv_insert(player_inv, "main", ItemStack(settings.output_item), output_qty, nil)

					-- TODO: send proper message
					--[[
					if minetest.get_modpath("digilines") then
						send_message(pos, settings.digiline_channel, msg)
					end
					--]]

					return true, "Trade successful"
				elseif ct.vendor_has then
					if ct.vendor_fits then
						minetest.log("action", player:get_player_name()..
							" trades "..settings.input_item_qty.." "..
							settings.input_item.." for "..settings.output_item_qty..
							" "..settings.output_item.." using vendor at "..
							minetest.pos_to_string(pos)
						)

						fancy_vend.inv_remove(inv, "main", ct.vendor_item_table, settings.output_item, output_qty)
						fancy_vend.inv_remove(player_inv, "main", ct.player_item_table, settings.input_item, input_qty)
						fancy_vend.inv_insert(player_inv, "main",
							ItemStack(settings.output_item), output_qty, ct.vendor_item_table
						)
						fancy_vend.inv_insert(inv, "main",
							ItemStack(settings.input_item), input_qty, ct.player_item_table,
							pos, (minetest.get_modpath("pipeworks") and settings.currency_eject)
						)

						-- Run mail mod checks
						fancy_vend.alert_owner_if_empty(pos)

						return true, "Trade successful"
					else
						return false, "Vendor has insufficient space"
					end
				else
					return false, "Vendor has insufficient resources"
				end
			else
				return false, "You have insufficient space"
			end
		else
			return false, "You have insufficient funds"
		end
	else
		return false, "Vendor is inactive"..fancy_vend.make_inactive_string(errorcode)
	end
end
