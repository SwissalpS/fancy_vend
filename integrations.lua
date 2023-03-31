
-- Various email and tell mod support

-- This function takes the position of a vendor and alerts the owner if it has just been emptied
local email_loaded = minetest.get_modpath("email")
local tell_loaded = minetest.get_modpath("tell")
local mail_loaded = minetest.get_modpath("mail") and mail.version == 3 -- recent version only (at this time)

function fancy_vend.alert_owner_if_empty(pos)
	if fancy_vend.no_alerts then return end

	local meta = minetest.get_meta(pos)
	local settings = fancy_vend.get_vendor_settings(pos)
	local owner = meta:get_string("owner")
	local alerted = fancy_vend.stb(meta:get_string("alerted") or "false")
	local status, errorcode = fancy_vend.get_vendor_status(pos)

	-- Message to send
	local input_desc = fancy_vend.get_item_description(settings.input_item)
	local output_desc = fancy_vend.get_item_description(settings.output_item)
	local stock_msg = "Your vendor trading "..
		settings.input_item_qty.." "..input_desc..
		" for "..settings.output_item_qty.." "..output_desc..
		" at position "..minetest.pos_to_string(pos, 0)..
		" has just run out of stock."

	if not alerted and not status and errorcode == "no_output" then
		if mail_loaded then
			local entry = mail.get_storage_entry(owner)

			-- Instead of filling their inbox with mail, get the last message sent by "Fancy Vend"
			-- and append to the message
			-- If there is no last message, then create a new one
			local message
			for _, msg in pairs(entry.inbox) do
				if msg.from == "Fancy Vend" then -- Put a space in the name to avoid impersonation
					message = msg
				end
			end

			if message then
				-- edit existing message and save
				-- Set the message as unread
				message.read = false
				-- Append to the end
				message.body = message.body..stock_msg.."\n"
				-- save messages
				mail.set_storage_entry(owner, entry)

			else
				-- send a new message
				mail.send({
					from = "Fancy Vend",
					to = owner,
					subject = "You have unstocked vendors!",
					body = stock_msg.."\n"
				})
			end

		elseif email_loaded then
			-- Rubenwardy's Email Mod: https://github.com/rubenwardy/email
			email.send_mail("Fancy Vend", owner, stock_msg)

		elseif tell_loaded then
			-- octacians tell mod https://github.com/octacian/tell
			tell.add(owner, "Fancy Vend", stock_msg)
		end

		meta:set_string("alerted", "true")
	end
end
