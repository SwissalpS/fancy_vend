
function fancy_vend.swap_vendor(pos, vendor_type)
    local node = minetest.get_node(pos)
    node.name = vendor_type
    minetest.swap_node(pos, node)
end

function fancy_vend.get_correct_vendor(settings)
    if settings.admin_vendor then
        if settings.depositor then
            return "fancy_vend:admin_depo"
        else
            return "fancy_vend:admin_vendor"
        end
    else
        if settings.depositor then
            return "fancy_vend:player_depo"
        else
            return "fancy_vend:player_vendor"
        end
    end
end

function fancy_vend.is_vendor(name)
    local vendor_names = {
        "fancy_vend:player_vendor",
        "fancy_vend:player_depo",
        "fancy_vend:admin_vendor",
        "fancy_vend:admin_depo",
    }
    for _,n in ipairs(vendor_names) do
        if name == n then
            return true
        end
    end
    return false
end


function fancy_vend.refresh_vendor(pos)
    local node = minetest.get_node(pos)
    if node.name:split(":")[1] ~= "fancy_vend" then
        return false, "not a vendor"
    end

    local settings = fancy_vend.get_vendor_settings(pos)
    local meta = minetest.get_meta(pos)
    local status, errorcode = fancy_vend.get_vendor_status(pos)
    local correct_vendor = fancy_vend.get_correct_vendor(settings)

    if status or errorcode ~= "no_output" then
        meta:set_string("alerted", "false")
    end

    if status then
        meta:set_string("infotext", (settings.admin_vendor and "Admin" or "Player")..
          " Vendor trading "..settings.input_item_qty.." "..
          minetest.registered_items[settings.input_item].description..
          " for "..settings.output_item_qty.." "..
          minetest.registered_items[settings.output_item].description..
          " (owned by " .. meta:get_string("owner") .. ")"
        )

        if meta:get_string("configured") == "" then
            meta:set_string("configured", "true")
            if minetest.get_modpath("awards") then
                local name = meta:get_string("owner")
                local data = awards.player(name)

                -- Ensure fancy_vend_configure table is in data
                if not data.fancy_vend_configure then
                    data.fancy_vend_configure = {}
                end

                awards.increment_item_counter(data, "fancy_vend_configure", correct_vendor)

                local total_item_count = 0

                for _, v in pairs(data.fancy_vend_configure) do
                    total_item_count = total_item_count + v
                end

                if awards.get_item_count(data, "fancy_vend_configure", "fancy_vend:player_vendor") >= 1 then
                    awards.unlock(name, "fancy_vend:seller")
                end
                if awards.get_item_count(data, "fancy_vend_configure", "fancy_vend:player_depo") >= 1 then
                    awards.unlock(name, "fancy_vend:trader")
                end
                if total_item_count >= 10 then
                    awards.unlock(name, "fancy_vend:shop_keeper")
                end
                if total_item_count >= 25 then
                    awards.unlock(name, "fancy_vend:merchant")
                end
                if total_item_count >= 100 then
                    awards.unlock(name, "fancy_vend:super_merchant")
                end
                if total_item_count >= 9001 then
                    awards.unlock(name, "fancy_vend:god_merchant")
                end
            end
        end

        if settings.depositor then
            if meta:get_string("item") ~= settings.input_item then
                meta:set_string("item", settings.input_item)
                fancy_vend.update_item(pos, node)
            end
        else
            if meta:get_string("item") ~= settings.output_item then
                meta:set_string("item", settings.output_item)
                fancy_vend.update_item(pos, node)
            end
        end
    else
        meta:set_string("infotext", "Inactive "..
          (settings.admin_vendor and "Admin" or "Player")..
          " Vendor"..fancy_vend.make_inactive_string(errorcode)..
          " (owned by " .. meta:get_string("owner") .. ")"
        )
        if meta:get_string("item") ~= "fancy_vend:inactive" then
            meta:set_string("item", "fancy_vend:inactive")
            fancy_vend.update_item(pos, node)
        end

        if not status and errorcode == "no_room" then
            minetest.chat_send_player(meta:get_string("owner"),
              "[Fancy_Vend]: Error with vendor at "..minetest.pos_to_string(pos, 0)..
              ": does not have room for payment."
            )
            meta:set_string("alerted", "true")
        end
    end

    if correct_vendor ~= node.name then
        fancy_vend.swap_vendor(pos, correct_vendor)
    end
end
