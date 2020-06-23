
---------------
-- Copy Tool --
---------------

local function get_vendor_pos_and_settings(pointed_thing)
    if pointed_thing.type ~= "node" then return false end
    local pos = minetest.get_pointed_thing_position(pointed_thing, false)
    local node = minetest.get_node(pos)
    if node.name == "fancy_vend:display_node" then
        pos.y = pos.y - 1
        node = minetest.get_node(pos)
    end
    if not fancy_vend.is_vendor(node.name) then return false end

    local settings = fancy_vend.get_vendor_settings(pos)

    return pos, settings
end

minetest.register_tool("fancy_vend:copy_tool",{
    inventory_image = "copier.png",
    description = "Geminio Wand (For copying vendor settings, right click to"..
      "copy settings, left click to paste settings.)",
    stack_max = 1,
    on_place = function(itemstack, placer, pointed_thing)
        local pos, settings = get_vendor_pos_and_settings(pointed_thing)
        if not pos then return end

        local meta = itemstack:get_meta()
        meta:set_string("settings", minetest.serialize(settings))

        minetest.chat_send_player(placer:get_player_name(), "Settings saved.")

        return itemstack
    end,
    on_use = function(itemstack, user, pointed_thing)
        local pos, current_settings = get_vendor_pos_and_settings(pointed_thing)
        if not pos then return end

        local meta = itemstack:get_meta()
        local node_meta = minetest.get_meta(pos)
        local new_settings = minetest.deserialize(meta:get_string("settings"))
        if not new_settings then
          minetest.chat_send_player(
            user:get_player_name(),
            "No settings to set with. Right-click first on the vendor you want to copy settings from."
          )
          return
        end

        if fancy_vend.can_modify_vendor(pos, user) then

            new_settings.input_item = current_settings.input_item
            new_settings.input_item_qty = current_settings.input_item_qty
            new_settings.output_item = current_settings.output_item
            new_settings.output_item_qty = current_settings.output_item_qty

            -- Admin vendor priv check
            if not minetest.check_player_privs(node_meta:get_string("owner"), {admin_vendor=true}) and
              new_settings.admin_vendor then
                new_settings.admin_vendor = current_settings.admin_vendor
            end

            fancy_vend.set_vendor_settings(pos, new_settings)
            fancy_vend.refresh_vendor(pos)
            minetest.chat_send_player(user:get_player_name(), "Settings set.")
        else
            minetest.chat_send_player(user:get_player_name(), "You cannot modify this vendor.")
        end
    end,
})

minetest.register_craft({
    output = "fancy_vend:copy_tool",
    recipe = {
        {"default:stick","",                      ""               },
        {"",             "default:obsidian_shard",""               },
        {"",             "",                      "default:diamond"},
    }
})

minetest.register_craft({
    output = "fancy_vend:copy_tool",
    recipe = {
        {"",               "",                      "default:stick"},
        {"",               "default:obsidian_shard",""             },
        {"default:diamond","",                      ""             },
    }
})
