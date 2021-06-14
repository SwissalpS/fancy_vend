

-- Craftitem to display when vendor is inactive (Use just image for this???)
minetest.register_craftitem("fancy_vend:inactive",{inventory_image = "inactive.png",})



local modstorage = minetest.get_mod_storage()

if modstorage:get_string("all_inactive_force") == "" then
	modstorage:set_string("all_inactive_force", "false")
end

fancy_vend.all_inactive_force = fancy_vend.stb(modstorage:get_string("all_inactive_force"))

minetest.register_chatcommand("disable_all_vendors", {
	description = "Toggle vendor inactivity.",
	privs = {disable_vendor=true},
	func = function()
		if fancy_vend.all_inactive_force then
			fancy_vend.all_inactive_force = false
			modstorage:set_string("all_inactive_force", "false")
		else
			fancy_vend.all_inactive_force = true
			modstorage:set_string("all_inactive_force", "true")
		end
	end,
})
