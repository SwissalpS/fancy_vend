
local vendor_template = {
    description = "Vending Machine",
    legacy_facedir_simple = true,
    paramtype2 = "facedir",
    groups = {choppy=2, oddly_breakable_by_hand=2, tubedevice=1, tubedevice_receiver=1},
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
    },
    is_ground_content = false,
    light_source = 8,
    sounds = default.node_sound_wood_defaults(),
    drop = fancy_vend.drop_vendor,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Unconfigured Player Vendor")
        meta:set_string("message", "Vendor initialized")
        meta:set_string("owner", "")
        local inv = meta:get_inventory()
        inv:set_size("main", 15*6)
        inv:set_size("wanted_item", 1*1)
        inv:set_size("given_item", 1*1)
        fancy_vend.reset_vendor_settings(pos)
        meta:set_string("log", "")
    end,
    can_dig = fancy_vend.can_dig_vendor,
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return end
        local pointed_node_pos = minetest.get_pointed_thing_position(pointed_thing, false)
        local pointed_node = minetest.get_node(pointed_node_pos)
        if minetest.registered_nodes[pointed_node.name].buildable_to then
            pointed_thing.above = pointed_node_pos
        end
        -- Set variables for access later (for various checks, etc.)
        local name = placer:get_player_name()
        local above_node_pos = table.copy(pointed_thing.above)
        above_node_pos.y = above_node_pos.y + 1
        local above_node = minetest.get_node(above_node_pos).name

        -- If node above is air or the display node, and it is not protected,
        -- attempt to place the vendor. If vendor sucessfully places, place display node above, otherwise alert the user
        if (
          minetest.registered_nodes[above_node].buildable_to or
          above_node == "fancy_vend:display_node") and
          not minetest.is_protected(above_node_pos, name) then
            local success
            itemstack, success = minetest.item_place(itemstack, placer, pointed_thing, nil)
            if above_node ~= "fancy_vend:display_node" and success then
                minetest.set_node(above_node_pos, minetest.registered_nodes["fancy_vend:display_node"])
            end
            -- Set owner
            local meta = minetest.get_meta(pointed_thing.above)
            meta:set_string("owner", placer:get_player_name() or "")

            -- Set default meta
            meta:set_string("log", minetest.serialize({"Vendor placed by "..placer:get_player_name(),}))
            fancy_vend.reset_vendor_settings(pointed_thing.above)
            fancy_vend.refresh_vendor(pointed_thing.above)
        else
            minetest.chat_send_player(name, "Vendors require 2 nodes of space.")
        end

        if minetest.get_modpath("pipeworks") then
            pipeworks.after_place(pointed_thing.above)
        end

        return itemstack
    end,
    on_dig = function(pos, _, digger)
        -- Set variables for access later (for various checks, etc.)
        local name = digger:get_player_name()
        local above_node_pos = table.copy(pos)
        above_node_pos.y = above_node_pos.y + 1

        -- abandon if player shouldn't be able to dig node
        local can_dig = fancy_vend.can_dig_vendor(pos, digger)
        if not can_dig then return end

        -- Try remove display node, if the whole node is able to be removed by the player,
        -- remove the display node and continue to remove vendor,
        -- if it doesn't exist and vendor can be dug continue to remove vendor.
        local success
        if minetest.get_node(above_node_pos).name == "fancy_vend:display_node" then
            if not minetest.is_protected(above_node_pos, name) and not minetest.is_protected(pos, name) then
                minetest.remove_node(above_node_pos)
                fancy_vend.remove_item(above_node_pos)
                success = true
            else
                success = false
            end
        else
            if not minetest.is_protected(pos, name) then
                success = true
            else
                success = false
            end
        end

        -- If failed to remove display node, don't remove vendor. since protection
        -- for whole vendor was checked at display removal, protection need not be re-checked
        if success then
            minetest.remove_node(pos)
            minetest.handle_node_drops(pos, {fancy_vend.drop_vendor}, digger)
            if minetest.get_modpath("pipeworks") then
                pipeworks.after_dig(pos)
            end
        end
    end,
    tube = {
        input_inventory = "main",
        connect_sides = {left = 1, right = 1, back = 1, bottom = 1},
        insert_object = function(pos, _, stack)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local remaining = inv:add_item("main", stack)
            fancy_vend.refresh_vendor(pos)
            return remaining
        end,
        can_insert = function(pos, _, stack)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local settings = fancy_vend.get_vendor_settings(pos)
            if settings.split_stacks then
                stack = stack:peek_item(1)
            end
            if settings.accept_output_only then
                if stack:get_name() ~= settings.output_item then
                    return false
                end
            end
            return inv:room_for_item("main", stack)
        end,
    },
    allow_metadata_inventory_move = function(pos, _, _, to_list, _, count, player)
        if not fancy_vend.can_access_vendor_inv(player, pos) or
          to_list == "wanted_item" or to_list == "given_item" then
            return 0
        end
        return count
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if not fancy_vend.can_access_vendor_inv(player, pos) then
            return 0
        end
        if listname == "wanted_item" or listname == "given_item" then
            local inv = minetest.get_meta(pos):get_inventory()
            inv:set_stack(listname, index, ItemStack(stack:get_name()))
            local settings = fancy_vend.get_vendor_settings(pos)
            if listname == "wanted_item" then
                settings.input_item = stack:get_name()
            elseif listname == "given_item" then
                settings.output_item = stack:get_name()
            end
            fancy_vend.set_vendor_settings(pos, settings)
            return 0
        end
        return stack:get_count()
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        if not fancy_vend.can_access_vendor_inv(player, pos) then
            return 0
        end
        if listname == "wanted_item" or listname == "given_item" then
            local inv = minetest.get_meta(pos):get_inventory()
            local fake_stack = inv:get_stack(listname, index)
            fake_stack:take_item(stack:get_count())
            inv:set_stack(listname, index, fake_stack)
            local settings = fancy_vend.get_vendor_settings(pos)
            if listname == "wanted_item" then
                settings.input_item = ""
            elseif listname == "given_item" then
                settings.output_item = ""
            end
            fancy_vend.set_vendor_settings(pos, settings)
            return 0
        end
        return stack:get_count()
    end,
    on_rightclick = function(pos, _, clicker)
        local node = minetest.get_node(pos)
        if node.name == "fancy_vend:display_node" then
            pos.y = pos.y - 1
        end
        fancy_vend.show_vendor_formspec(clicker, pos)
    end,
    on_metadata_inventory_move = function(pos, _, _, _, _, _, player)
        minetest.log("action",
          player:get_player_name().." moves stuff in vendor at "..
          minetest.pos_to_string(pos)
        )
        fancy_vend.refresh_vendor(pos)
    end,
    on_metadata_inventory_put = function(pos, _, _, stack, player)
        minetest.log("action",
          player:get_player_name().." moves "..
          stack:get_name().." to vendor at "..minetest.pos_to_string(pos)
        )
        fancy_vend.refresh_vendor(pos)
    end,
    on_metadata_inventory_take = function(pos, _, _, stack, player)
        minetest.log("action",
          player:get_player_name().." takes "..
          stack:get_name().." from vendor at "..
          minetest.pos_to_string(pos)
        )
        fancy_vend.refresh_vendor(pos)
    end,
    on_blast = function()
        -- TNT immunity
    end,
}

if pipeworks then
    vendor_template.digiline = {
        receptor = {},
        effector = {
        action = function() end
        },
        wire = {
        rules = pipeworks.digilines_rules
        },
    }
end

local player_vendor = table.copy(vendor_template)
player_vendor.tiles = {
        "player_vend.png", "player_vend.png",
        "player_vend.png", "player_vend.png",
        "player_vend.png", "player_vend_front.png",
    }

local player_depo = table.copy(vendor_template)
player_depo.tiles = {
        "player_depo.png", "player_depo.png",
        "player_depo.png", "player_depo.png",
        "player_depo.png", "player_depo_front.png",
    }
player_depo.groups.not_in_creative_inventory = 1

local admin_vendor = table.copy(vendor_template)
admin_vendor.tiles = {
        "admin_vend.png", "admin_vend.png",
        "admin_vend.png", "admin_vend.png",
        "admin_vend.png", "admin_vend_front.png",
    }
admin_vendor.groups.not_in_creative_inventory = 1

local admin_depo = table.copy(vendor_template)
admin_depo.tiles = {
        "admin_depo.png", "admin_depo.png",
        "admin_depo.png", "admin_depo.png",
        "admin_depo.png", "admin_depo_front.png",
    }
admin_depo.groups.not_in_creative_inventory = 1

minetest.register_node("fancy_vend:player_vendor", player_vendor)
minetest.register_node("fancy_vend:player_depo", player_depo)
minetest.register_node("fancy_vend:admin_vendor", admin_vendor)
minetest.register_node("fancy_vend:admin_depo", admin_depo)

minetest.register_craft({
    output = "fancy_vend:player_vendor",
    recipe = {
        { "default:gold_ingot", fancy_vend.display_node,          "default:gold_ingot"},
        { "default:diamond",   "default:mese_crystal",        "default:diamond"},
        { "default:gold_ingot","default:chest_locked","default:gold_ingot"},
    }
})


-- Hopper support
if minetest.get_modpath("hopper") then
    hopper:add_container({
        {"side", "fancy_vend:player_vendor", "main"}
    })

    hopper:add_container({
        {"side", "fancy_vend:player_depo", "main"}
    })
end
