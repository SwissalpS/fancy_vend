
-- Various email and tell mod support

-- This function takes the position of a vendor and alerts the owner if it has just been emptied
local email_loaded = minetest.get_modpath("email")
local tell_loaded = minetest.get_modpath("tell")
local mail_loaded = minetest.get_modpath("mail")

function fancy_vend.alert_owner_if_empty(pos)
	if fancy_vend.no_alerts then
		return
	end

	local meta = minetest.get_meta(pos)
	local settings = fancy_vend.get_vendor_settings(pos)
	local owner = meta:get_string("owner")
	local alerted = fancy_vend.stb(meta:get_string("alerted") or "false") -- check
	local status, errorcode = fancy_vend.get_vendor_status(pos)

	-- Message to send
	local stock_msg = "Your vendor trading "..settings.input_item_qty.." "..
		minetest.registered_items[settings.input_item].description..
		" for "..settings.output_item_qty.." "..
		minetest.registered_items[settings.output_item].description..
		" at position "..minetest.pos_to_string(pos, 0)..
		" has just run out of stock."

	if not alerted and not status and errorcode == "no_output" then
		-- Rubenwardy's Email Mod: https://github.com/rubenwardy/email
		if mail_loaded then
			local inbox = {}

			-- load messages
			if not mail.apiversion then
				-- cheapie's mail mod https://cheapiesystems.com/git/mail/
				if not mail.messages[owner] then mail.messages[owner] = {} end
				inbox = mail.messages[owner]

			elseif mail.apiversion >= 1.1 then
				-- webmail fork https://github.com/thomasrudin-mt/mail (per player storage)
				inbox = mail.getMessages(owner)

			end

			-- Instead of filling their inbox with mail, get the last message sent by "Fancy Vend"
			-- and append to the message
			-- If there is no last message, then create a new one
			local message
			for _, msg in pairs(inbox) do
				if msg.sender == "Fancy Vend" then -- Put a space in the name to avoid impersonation
					message = msg
				end
			end

			if message then
				-- Set the message as unread
				message.unread = true

				-- Append to the end
				message.body = message.body..stock_msg.."\n"
			else
				mail.send("Fancy Vend", owner, "You have unstocked vendors!", stock_msg.."\n")
			end

			-- save messages
			if not mail.apiversion then
				-- cheapie's mail mod https://cheapiesystems.com/git/mail/
				mail.save()

			elseif mail.apiversion >= 1.1 then
				-- webmail fork https://github.com/thomasrudin-mt/mail
				mail.setMessages(owner, inbox)

			end

			meta:set_string("alerted", "true")

			return

		elseif email_loaded then
			email.send_mail("Fancy Vend", owner, stock_msg)

			meta:set_string("alerted", "true")

			return

		elseif tell_loaded then
			-- octacians tell mod https://github.com/octacian/tell
			tell.add(owner, "Fancy Vend", stock_msg)

			meta:set_string("alerted", "true")

			return
		end
	end
end
