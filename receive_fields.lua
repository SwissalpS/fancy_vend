
local function get_max_lots(pos, player)
    local max = 0

    while fancy_vend.run_inv_checks(pos, player, max).overall do
        max = max + 1
    end

    return math.max(0, max -1)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = formname:split(":")[1]
    if name ~= "fancy_vend" then return end
    local formtype = formname:split(":")[2]
    formtype = formtype:split(";")[1]
    local pos = minetest.string_to_pos(formname:split(";")[2])
    if not pos then return end

    local node = minetest.get_node(pos)
    if not fancy_vend.is_vendor(node.name) then return end

    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local player_inv = player:get_inventory()
    local settings = fancy_vend.get_vendor_settings(pos)

    -- Handle settings changes
    if fancy_vend.can_modify_vendor(pos, player) then
        for i in pairs(fields) do
            if fancy_vend.stb(fields[i]) ~= settings[i] then
                settings[i] = fancy_vend.stb(fields[i])
            end
        end

        -- Check number-only fields contain only numbers
        if not tonumber(settings.input_item_qty) then
            settings.input_item_qty = 1
        else
            settings.input_item_qty = math.floor(math.abs(tonumber(settings.input_item_qty)))
        end
        if not tonumber(settings.output_item_qty) then
            settings.output_item_qty = 1
        else
            settings.output_item_qty = math.floor(math.abs(tonumber(settings.output_item_qty)))
        end

        -- Check item quantities aren't too high (which could lead to additional
        -- processing for no reason), if so, set it to the maximum the player inventory can handle
        if ItemStack(settings.output_item):get_stack_max() * player_inv:get_size("main") < settings.output_item_qty then
            settings.output_item_qty = ItemStack(settings.output_item):get_stack_max() * player_inv:get_size("main")
        end

        if ItemStack(settings.input_item):get_stack_max() * player_inv:get_size("main") < settings.input_item_qty then
            settings.input_item_qty = ItemStack(settings.input_item):get_stack_max() * player_inv:get_size("main")
        end

        -- Admin vendor priv check
        if not minetest.check_player_privs(meta:get_string("owner"), {admin_vendor=true})
          and fields.admin_vendor == "true" then
            settings.admin_vendor = false
        end

        fancy_vend.set_vendor_settings(pos, settings)
        fancy_vend.refresh_vendor(pos)
    end

    if fields.quit then
        if fancy_vend.can_access_vendor_inv(player, pos) and settings.auto_sort then
            fancy_vend.sort_inventory(inv)
        end
        return true
    end

    if fields.sort and fancy_vend.can_access_vendor_inv(player, pos) then
        fancy_vend.sort_inventory(inv)
    end

    if fields.buy then
        local lots = math.floor(tonumber(fields.lot_count) or 1)
        -- prevent negative numbers
        lots = math.max(lots, 1)
        local success, message = fancy_vend.make_purchase(pos, player, lots)
        if success then
            -- Add to vendor logs
            local logs = minetest.deserialize(meta:get_string("log"))
            for i in pairs(logs) do
                if i >= fancy_vend.max_logs then
                    table.remove(logs, 1)
                end
            end
            table.insert(logs, "Player "..player:get_player_name().." purchased "..lots.." lots from this vendor.")
            meta:set_string("log", minetest.serialize(logs))

            -- Send digiline message if applicable
            if minetest.get_modpath("digilines") then
                local msg = {
                    buyer = player:get_player_name(),
                    lots = lots,
                    settings = settings,
                }
                fancy_vend.send_message(pos, settings.digiline_channel, msg)
            end
        end
        -- Set message and refresh vendor
        if message then
            meta:set_string("message", message)
        end
        fancy_vend.refresh_vendor(pos)
    elseif fields.lot_fill then
        minetest.show_formspec(
          player:get_player_name(),
          "fancy_vend:buyer;"..minetest.pos_to_string(pos),
          fancy_vend.get_vendor_buyer_fs(pos, player, get_max_lots(pos, player))
        )
        return true
    end

    if fancy_vend.can_access_vendor_inv(player, pos) then
        if fields.inv_tovendor then
            minetest.log("action", player:get_player_name()..
            " moves inventory contents to vendor at "..
              minetest.pos_to_string(pos)
            )
            fancy_vend.move_inv(player_inv, inv, nil)
            fancy_vend.refresh_vendor(pos)
        elseif fields.inv_output_tovendor then
            minetest.log("action", player:get_player_name()..
              " moves output items in inventory to vendor at "..
              minetest.pos_to_string(pos)
            )
            fancy_vend.move_inv(player_inv, inv, settings.output_item)
            fancy_vend.refresh_vendor(pos)
        elseif fields.inv_fromvendor then
            minetest.log("action", player:get_player_name()..
              " moves inventory contents from vendor at "..
              minetest.pos_to_string(pos)
            )
            fancy_vend.move_inv(inv, player_inv, nil)
            fancy_vend.refresh_vendor(pos)
        elseif fields.inv_input_fromvendor then
            minetest.log("action", player:get_player_name()..
              " moves input items from vendor at "..
              minetest.pos_to_string(pos)
            )
            fancy_vend.move_inv(inv, player_inv, settings.input_item)
            fancy_vend.refresh_vendor(pos)
        end
    end

    -- Handle page changes
    if fields.button_log then
        minetest.show_formspec(
          player:get_player_name(),
          "fancy_vend:log;"..minetest.pos_to_string(pos),
          fancy_vend.get_vendor_log_fs(pos)
        )
        return
    elseif fields.button_settings then
        minetest.show_formspec(
          player:get_player_name(),
          "fancy_vend:settings;"..minetest.pos_to_string(pos),
          fancy_vend.get_vendor_settings_fs(pos)
        )
        return
    elseif fields.button_inv then
        minetest.show_formspec(
          player:get_player_name(),
          "fancy_vend:default;"..minetest.pos_to_string(pos),
          fancy_vend.get_vendor_default_fs(pos, player)
        )
        return
    elseif fields.button_buy then
        minetest.show_formspec(
          player:get_player_name(),
          "fancy_vend:buyer;"..minetest.pos_to_string(pos),
          fancy_vend.get_vendor_buyer_fs(pos, player, (tonumber(fields.lot_count) or 1))
        )
        return
    end

    -- Update formspec
    if formtype == "log" then
        minetest.show_formspec(
          player:get_player_name(),
          "fancy_vend:log;"..minetest.pos_to_string(pos),
          fancy_vend.get_vendor_log_fs(pos, player)
        )
    elseif formtype == "settings" then
        minetest.show_formspec(
          player:get_player_name(),
          "fancy_vend:settings;"..minetest.pos_to_string(pos),
          fancy_vend.get_vendor_settings_fs(pos, player)
        )
    elseif formtype == "default" then
        minetest.show_formspec(
          player:get_player_name(),
          "fancy_vend:default;"..minetest.pos_to_string(pos),
          fancy_vend.get_vendor_default_fs(pos, player)
        )
    elseif formtype == "buyer" then
        minetest.show_formspec(
          player:get_player_name(),
          "fancy_vend:buyer;"..minetest.pos_to_string(pos),
          fancy_vend.get_vendor_buyer_fs(pos, player, (tonumber(fields.lot_count) or 1))
        )
    end
end)
