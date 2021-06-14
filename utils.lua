
function fancy_vend.bts(bool)
	if bool == false then
		return "false"
	elseif bool == true then
		return "true"
	else
		return bool
	end
end

function fancy_vend.stb(str)
	if str == "false" then
		return false
	elseif str == "true" then
		return true
	else
		return str
	end
end


function fancy_vend.get_vendor_status(pos)
	local settings = fancy_vend.get_vendor_settings(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if fancy_vend.all_inactive_force then
		return false, "all_inactive_force"
	elseif settings.input_item == "" or settings.output_item == "" then
		return false, "unconfigured"
	elseif settings.inactive_force then
		return false, "inactive_force"
	elseif not minetest.check_player_privs(meta:get_string("owner"), {admin_vendor=true}) and
		settings.admin_vendor == true then
		return false, "no_privs"
	elseif not fancy_vend.inv_contains_items(
		inv, "main", settings.output_item, settings.output_item_qty, settings.accept_worn_output) and
		not settings.admin_vendor then
		return false, "no_output"
	elseif not fancy_vend.free_slots(inv, "main", settings.input_item, settings.input_item_qty) and
		not settings.admin_vendor then
		return false, "no_room"
	else
		return true
	end
end

function fancy_vend.make_inactive_string(errorcode)
	local status_str = ""
	if errorcode == "unconfigured" then
		status_str = status_str.." (unconfigured)"
	elseif errorcode == "inactive_force" then
		status_str = status_str.." (forced)"
	elseif errorcode == "no_output" then
		status_str = status_str.." (out of stock)"
	elseif errorcode == "no_room" then
		status_str = status_str.." (no room)"
	elseif errorcode == "no_privs" then
		status_str = status_str.." (seller has insufficient privilages)"
	elseif errorcode == "all_inactive_force" then
		status_str = status_str.." (all vendors disabled temporarily by admin)"
	end
	return status_str
end

function fancy_vend.get_item_description(itemname)
	local desc = itemname
	local def = minetest.registered_items[itemname]
	if def and def.description ~= "" then
		desc = def.description
	end
	return desc
end
