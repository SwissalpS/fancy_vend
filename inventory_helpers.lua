

-- Inventory helpers:

-- Function to sort inventory (Taken from technic_chests)
function fancy_vend.sort_inventory(inv)
    local inlist = inv:get_list("main")
    local typecnt = {}
    local typekeys = {}
    for _, st in ipairs(inlist) do
        if not st:is_empty() then
            local n = st:get_name()
            local w = st:get_wear()
            local m = st:get_metadata()
            local k = string.format("%s %05d %s", n, w, m)
            if not typecnt[k] then
                typecnt[k] = {
                    name = n,
                    wear = w,
                    metadata = m,
                    stack_max = st:get_stack_max(),
                    count = 0,
                }
                table.insert(typekeys, k)
            end
            typecnt[k].count = typecnt[k].count + st:get_count()
        end
    end
    table.sort(typekeys)
    local outlist = {}
    for _, k in ipairs(typekeys) do
        local tc = typecnt[k]
        while tc.count > 0 do
            local c = math.min(tc.count, tc.stack_max)
            table.insert(outlist, ItemStack({
                name = tc.name,
                wear = tc.wear,
                metadata = tc.metadata,
                count = c,
            }))
            tc.count = tc.count - c
        end
    end
    if #outlist > #inlist then return end
    while #outlist < #inlist do
        table.insert(outlist, ItemStack(nil))
    end
    inv:set_list("main", outlist)
end

function fancy_vend.free_slots(inv, listname, itemname, quantity)
    local size = inv:get_size(listname)
    local free = 0
    for i=1,size do
        local stack = inv:get_stack(listname, i)
        if stack:is_empty() or stack:get_free_space() > 0 then
            if stack:is_empty() then
                free = free + ItemStack(itemname):get_stack_max()
            elseif stack:get_name() == itemname then
                free = free + stack:get_free_space()
            end
        end
    end
    if free < quantity then
        return false
    else
        return true
    end
end

function fancy_vend.inv_insert(inv, listname, itemstack, quantity, from_table, pos, input_eject)
    local stackmax = itemstack:get_stack_max()
    local name = itemstack:get_name()
    local stacks = {}
    local remaining_quantity = quantity

    -- Add the full stacks to the list
    while remaining_quantity > stackmax do
        table.insert(stacks, {name = name, count = stackmax})
        remaining_quantity = remaining_quantity - stackmax
    end
    -- Add the remaining stack to the list
    table.insert(stacks, {name = name, count = remaining_quantity})

   -- If tool add wears ignores if from_table = nil (eg, due to vendor beig admin vendor)
    if minetest.registered_tools[name] and from_table then
        for i in pairs(stacks) do
            local from_item_table = from_table[i].item:to_table()
            stacks[i].wear = from_item_table.wear
        end
    end

    -- if has metadata add metadata
    if from_table then
        for i in pairs(stacks) do
            local from_item_table = from_table[i].item:to_table()
            if from_item_table.name == name then
                if from_item_table.metadata then
                  -- Apparently some mods *cough* digtron *cough* do use deprecated metadata strings
                    stacks[i].metadata = from_item_table.metadata
                end
                if from_item_table.meta then
                  -- Most mods use metadata tables which is the correct method but ok
                    stacks[i].meta = from_item_table.meta
                end
            end
        end
    end

    -- Add to inventory or eject to pipeworks/hoppers (whichever is applicable)
    local output_tube_connected = false
    local output_hopper_connected = false
    if input_eject and pos then
        local pos_under = vector.new(pos)
        pos_under.y = pos_under.y - 1
        local node_under = minetest.get_node(pos_under)
        if minetest.get_item_group(node_under.name, "tubedevice") > 0 then
            output_tube_connected = true
        end
        if node_under.name == "hopper:hopper" or node_under.name == "hopper:hopper_side" then
            output_hopper_connected = true
        end
    end
    for i in pairs(stacks) do
        if output_tube_connected then
            pipeworks.tube_inject_item(
              pos,
              pos,
              vector.new(0, -1, 0),
              stacks[i],
              minetest.get_meta(pos):get_string("owner")
            )
        else
            local leftovers = ItemStack(stacks[i])
            if output_hopper_connected then
                local pos_under = {x = pos.x, y = pos.y-1, z = pos.z}
                local hopper_inv = minetest.get_meta(pos_under):get_inventory()
                leftovers = hopper_inv:add_item("main", leftovers)
            end
            if not leftovers:is_empty() then
                inv:add_item(listname, leftovers)
            end
        end
    end
end

function fancy_vend.inv_remove(inv, listname, remove_table, itemstring, quantity)
    local count = 0
    for i in pairs(remove_table) do
        count = count + remove_table[i].item:get_count()
        inv:set_stack(listname, remove_table[i].id, nil)
    end
    -- Add back items if too many were taken
    if count > quantity then
        inv:add_item(listname, ItemStack({name = itemstring, count = count - quantity}))
    end
end

function fancy_vend.inv_contains_items(inv, listname, itemstring, quantity, ignore_wear)
    local minimum = quantity
    local get_items = {}
    local count = 0

    for i=1,inv:get_size(listname) do
        local stack = inv:get_stack(listname, i)
        if stack:get_name() == itemstring then
            if ignore_wear or (not minetest.registered_tools[itemstring] or stack:get_wear() == 0) then
                count = count + stack:get_count()
                table.insert(get_items, {id=i, item=stack})
                if count >= minimum then
                    return true, get_items
                end
            end
        end
    end
    return false
end
