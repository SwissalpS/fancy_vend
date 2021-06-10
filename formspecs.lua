
function fancy_vend.get_vendor_buyer_fs(pos, _, lots)
    local base = "size[8,9]"..
        "label[0,0;Owner wants:]"..
        "label[0,1.25;for:]"..
        "button[0,2.7;2,1;buy;Buy]"..
        "label[2.8,2.9;lots.]"..
        "button[0,3.6;2,1;lot_fill;Fill lots to max.]"..
        "list[current_player;main;0,4.85;8,1;]"..
        "list[current_player;main;0,6.08;8,3;8]"..
        "listring[current_player;main]"..
        "field_close_on_enter[lot_count;false]"

    -- Add dynamic elements
    local settings = fancy_vend.get_vendor_settings(pos)
    local meta = minetest.get_meta(pos)
    local status, errorcode = fancy_vend.get_vendor_status(pos)

    local input_item = minetest.registered_items[settings.input_item]
    local output_item = minetest.registered_items[settings.output_item]

    local itemstuff

    if input_item and output_item then
        itemstuff =
            "item_image_button[0,0.4;1,1;"..settings.input_item..";ignore;]"..
            "label[0.9,0.6;"..settings.input_item_qty.." "..input_item.description.."]"..
            "item_image_button[0,1.7;1,1;"..settings.output_item..";ignore;]"..
            "label[0.9,1.9;"..settings.output_item_qty.." "..output_item.description.."]"
    else
        return "size[8,9]"..
            "label[0.9,0.6;Unknown items detected, vendor not fully functional!]"
    end

    local status_str
    if status then
        status_str = "active"
    else
        status_str = "inactive"..fancy_vend.make_inactive_string(errorcode)
    end
    local status_fs =
    "label[4,0.4;Vendor status: "..status_str.."]"..
    "label[4,0.8;Message: "..meta:get_string("message").."]"..
    "label[4,0;Vendor owned by: "..meta:get_string("owner").."]"

    local setting_specific = ""
    if not settings.accept_worn_input then
        setting_specific = setting_specific.."label[4,1.6;Vendor will not accept worn tools.]"
    end
    if not settings.accept_worn_output then
        setting_specific = setting_specific.."label[4,1.2;Vendor will not sell worn tools.]"
    end

    local fields = "field[2.2,3.2;1,0.6;lot_count;;"..(lots or 1).."]"

    local fs = base..itemstuff..status_fs..setting_specific..fields
    return fs
end

function fancy_vend.get_vendor_settings_fs(pos)
    local base = "size[9,9]"..
        "label[2.8,0.5;Input item]"..
        "label[6.8,0.5;Output item]"..
        "image[0,1.3;1,1;debug_btn.png]"..
        "item_image_button[0,2.3;1,1;default:book;button_log;]"..
        "item_image_button[0,3.3;1,1;default:gold_ingot;button_buy;]"..
        "list[current_player;main;1,4.85;8,1;]"..
        "list[current_player;main;1,6.08;8,3;8]"..
        "listring[current_player;main]"..
        "button_exit[0,8;1,1;btn_exit;Done]"

    -- Add dynamic elements
    local pos_str = pos.x..","..pos.y..","..pos.z
    local settings = fancy_vend.get_vendor_settings(pos)

    if settings.admin_vendor then
        base = base.."item_image[0,0.3;1,1;default:chest]"
    else
        base = base.."item_image_button[0,0.3;1,1;default:chest;button_inv;]"
    end

    local inv =
        "list[nodemeta:"..pos_str..";wanted_item;1,0.3;1,1;]"..
        "list[nodemeta:"..pos_str..";given_item;5,0.3;1,1;]"..
        "listring[nodemeta:"..pos_str..";wanted_item]"..
        "listring[nodemeta:"..pos_str..";given_item]"

    local fields =
        "field[2.2,0.8;1,0.6;input_item_qty;;"..settings.input_item_qty.."]"..
        "field[6.2,0.8;1,0.6;output_item_qty;;"..settings.output_item_qty.."]"..
        "field[1.3,4.1;2.66,1;co_sellers;Co-Sellers:;"..settings.co_sellers.."]"..
        "field[3.86,4.1;2.66,1;banned_buyers;Banned Buyers:;"..settings.banned_buyers.."]"..
        "field_close_on_enter[input_item_qty;false]"..
        "field_close_on_enter[output_item_qty;false]"..
        "field_close_on_enter[co_sellers;false]"..
        "field_close_on_enter[banned_buyers;false]"

    local checkboxes =
        "checkbox[1,2.2;inactive_force;Force vendor into an inactive state.;"..
          fancy_vend.bts(settings.inactive_force).."]"..
        "checkbox[1,2.6;depositor;Set this vendor to a Depositor.;"..fancy_vend.bts(settings.depositor).."]"..
        "checkbox[1,3.0;accept_worn_output;Sell worn tools.;"..fancy_vend.bts(settings.accept_worn_output).."]"..
        "checkbox[5,3.0;accept_worn_input;Buy worn tools.;"..fancy_vend.bts(settings.accept_worn_input).."]"..
        "checkbox[5,2.6;auto_sort;Automatically sort inventory.;"..fancy_vend.bts(settings.auto_sort).."]"

    -- Admin vendor checkbox only if owner is admin
    local meta = minetest.get_meta(pos)
    if minetest.check_player_privs(meta:get_string("owner"), {admin_vendor=true}) or settings.admin_vendor then
        checkboxes = checkboxes..
            "checkbox[5,2.2;admin_vendor;Set vendor to an admin vendor.;"..
              fancy_vend.bts(settings.admin_vendor).."]"
    end


    -- Optional dependancy specific elements
    if minetest.get_modpath("pipeworks") or minetest.get_modpath("hopper") then
        checkboxes = checkboxes..
            "checkbox[1,1.7;currency_eject;Eject incoming currency.;"..fancy_vend.bts(settings.currency_eject).."]"
        if minetest.get_modpath("pipeworks") then
            checkboxes = checkboxes..
            "checkbox[5,1.3;accept_output_only;Accept for-sale item only.;"..
              fancy_vend.bts(settings.accept_output_only).."]"..
            "checkbox[1,1.3;split_incoming_stacks;Split incoming stacks.;"..
              fancy_vend.bts(settings.split_incoming_stacks).."]"
        end
    end

    if minetest.get_modpath("digilines") then
        fields = fields..
            "field[6.41,4.1;2.66,1;digiline_channel;Digiline Channel:;"..settings.digiline_channel.."]"..
            "field_close_on_enter[digiline_channel;false]"
    end

    local fs = base..inv..fields..checkboxes
    return fs
end

function fancy_vend.get_vendor_default_fs(pos, player)
    local base = "size[16,11]"..
        "item_image[0,0.3;1,1;default:chest]"..
        "list[current_player;main;4,6.85;8,1;]"..
        "list[current_player;main;4,8.08;8,3;8]"..
        "listring[current_player;main]"..
        "button[1,6.85;3,1;inv_tovendor;All To Vendor]"..
        "button[12,6.85;3,1;inv_fromvendor;All From Vendor]"..
        "button[1,8.08;3,1;inv_output_tovendor;Output To Vendor]"..
        "button[12,8.08;3,1;inv_input_fromvendor;Input From Vendor]"..
        "button[1,9.31;3,1;sort;Sort Inventory]"..
        "button_exit[0,10;1,1;btn_exit;Done]"

    -- Add dynamic elements
    local pos_str = pos.x..","..pos.y..","..pos.z
    local inv_lists =
        "list[nodemeta:"..pos_str..";main;1,0.3;15,6;]"..
        "listring[nodemeta:"..pos_str..";main]"

    local settings_btn
    if fancy_vend.can_modify_vendor(pos, player) then
        settings_btn =
        "image_button[0,1.3;1,1;debug_btn.png;button_settings;]"..
        "item_image_button[0,2.3;1,1;default:book;button_log;]"..
        "item_image_button[0,3.3;1,1;default:gold_ingot;button_buy;]"
    else
        settings_btn =
        "image[0,1.3;1,1;debug_btn.png]"..
        "item_image[0,2.3;1,1;default:book]"..
        "item_image[0,3.3;1,1;default:gold_ingot;button_buy;]"
    end

    local fs = base..inv_lists..settings_btn
    return fs
end


function fancy_vend.get_vendor_log_fs(pos)
    local base = "size[9,9]"..
        "image_button[0,1.3;1,1;debug_btn.png;button_settings;]"..
        "item_image[0,2.3;1,1;default:book]"..
        "item_image_button[0,3.3;1,1;default:gold_ingot;button_buy;]"..
        "button_exit[0,8;1,1;btn_exit;Done]"

    -- Add dynamic elements
    local meta = minetest.get_meta(pos)
    local logs = minetest.deserialize(meta:get_string("log"))

    local settings = fancy_vend.get_vendor_settings(pos)
    if settings.admin_vendor then
        base = base.."item_image[0,0.3;1,1;default:chest]"
    else
        base = base.."item_image_button[0,0.3;1,1;default:chest;button_inv;]"
    end

    if not logs then logs = {"Error loading logs",} end
    local logs_tl =
        "textlist[1,0.5;7.8,8.6;logs;"..table.concat(logs, ",").."]"..
        "label[1,0;Showing (up to "..fancy_vend.max_logs..") recent log entries:]"

    local fs = base..logs_tl
    return fs
end

function fancy_vend.show_buyer_formspec(player, pos)
    minetest.show_formspec(player:get_player_name(), "fancy_vend:buyer;"..
      minetest.pos_to_string(pos), fancy_vend.get_vendor_buyer_fs(pos, player, nil)
    )
end

function fancy_vend.show_vendor_formspec(player, pos)
    local settings = fancy_vend.get_vendor_settings(pos)
    if fancy_vend.can_access_vendor_inv(player, pos) then
        local status, errorcode = fancy_vend.get_vendor_status(pos)
        if (
          (not status and errorcode == "unconfigured")
          and
          fancy_vend.can_modify_vendor(pos, player)
        ) or settings.admin_vendor then
            minetest.show_formspec(player:get_player_name(), "fancy_vend:settings;"..
              minetest.pos_to_string(pos), fancy_vend.get_vendor_settings_fs(pos)
            )
        else
            minetest.show_formspec(player:get_player_name(), "fancy_vend:default;"..
              minetest.pos_to_string(pos), fancy_vend.get_vendor_default_fs(pos, player)
            )
        end
    else
        fancy_vend.show_buyer_formspec(player, pos)
    end
end
