
-- Awards
if minetest.get_modpath("awards") then
	awards.register_award("fancy_vend:getting_fancy", {
		title = "Getting Fancy",
		description = "Craft a fancy vendor.",
		trigger = {
			type = "craft",
			item = fancy_vend.rop_vendor,
			target = 1,
		},
		icon = "player_vend_front.png^awards_level1.png",
	})
	awards.register_award("fancy_vend:wizard", {
		title = "You're a Wizard",
		description = "Craft a copy tool.",
		trigger = {
			type = "craft",
			item = "fancy_vend:copy_tool",
			target = 1,
		},
		icon = "copier.png",
	})
	awards.register_award("fancy_vend:trader", {
		title = "Trader",
		description = "Configure a depositor.",
		icon = "player_depo_front.png",
	})
	awards.register_award("fancy_vend:seller", {
		title = "Seller",
		description = "Configure a vendor.",
		icon = "player_vend_front.png^awards_level2.png",
	})
	awards.register_award("fancy_vend:shop_keeper", {
		title = "Shop Keeper",
		description = "Configure 10 vendors or depositors.",
		icon = "player_vend_front.png^awards_level3.png",
	})
	awards.register_award("fancy_vend:merchant", {
		title = "Merchant",
		description = "Configure 25 vendors or depositors.",
		icon = "player_vend_front.png^awards_level4.png",
	})
	awards.register_award("fancy_vend:super_merchant", {
		title = "Super Merchant",
		description = "Configure 100 vendors or depositors. How do you even have this much stuff to sell?",
		icon = "player_vend_front.png^awards_level5.png",
	})
	awards.register_award("fancy_vend:god_merchant", {
		title = "God Merchant",
		description = "Configure 9001 vendors or depositors. Ok wot.",
		icon = "player_vend_front.png^awards_level6.png",
		secret = true, -- Oi. Cheater.
	})
end
