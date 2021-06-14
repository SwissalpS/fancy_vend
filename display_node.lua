
-- Register a copy of the display node with no drops to make players separating
-- the obsidian glass with something like a piston a non-issue.
local display_node_def = table.copy(minetest.registered_nodes[fancy_vend.display_node])

display_node_def.drop = ""
display_node_def.pointable = false
display_node_def.groups.not_in_creative_inventory = 1
display_node_def.description = "Fancy Vendor Display Node (you hacker you!)"

if pipeworks then
	display_node_def.digiline = {
		wire = {
			rules = pipeworks.digilines_rules
		}
	}
end

minetest.register_node("fancy_vend:display_node", display_node_def)


-- LBM to refresh entities after clearobjects
minetest.register_lbm({
	label = "Refresh vendor display",
	name = "fancy_vend:display_refresh",
	nodenames = {"fancy_vend:display_node"},
	run_at_every_load = true,
	action = function(pos, node)
		pos.y = pos.y - 1
		fancy_vend.update_item(pos, node)
	end
})
