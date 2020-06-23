
local tmp = {}

minetest.register_entity("fancy_vend:display_item",{
    hp_max = 1,
    visual = "wielditem",
    visual_size = {x = 0.33, y = 0.33},
    collisionbox = {0, 0, 0, 0, 0, 0},
    physical = false,
    textures = {"air"},
    on_activate = function(self, staticdata)
        if tmp.nodename ~= nil and tmp.texture ~= nil then
            self.nodename = tmp.nodename
            tmp.nodename = nil
            self.texture = tmp.texture
            tmp.texture = nil
        else
            if staticdata ~= nil and staticdata ~= "" then
                local data = staticdata:split(';')
                if data and data[1] and data[2] then
                    self.nodename = data[1]
                    self.texture = data[2]
                end
            end
        end
        if self.texture ~= nil then
            self.object:set_properties({textures = {self.texture}})
        end
        self.object:set_properties({automatic_rotate = fancy_vend.autorotate_speed})
    end,
    get_staticdata = function(self)
        if self.nodename ~= nil and self.texture ~= nil then
            return self.nodename .. ';' .. self.texture
        end
        return ""
    end,
})

function fancy_vend.remove_item(pos)
    local objs = minetest.get_objects_inside_radius(pos, .5)
    if objs then
        for _, obj in ipairs(objs) do
            if obj and obj:get_luaentity() and obj:get_luaentity().name == "fancy_vend:display_item" then
                obj:remove()
            end
        end
    end
end

function fancy_vend.update_item(pos, node)
    pos.y = pos.y + 1
    fancy_vend.remove_item(pos)
    if minetest.get_node(pos).name ~= "fancy_vend:display_node" then
        minetest.log("warning", "[fancy_vend]: Placing display item inside "..
          minetest.get_node(pos).name.." at "..minetest.pos_to_string(pos)..
          " is not permitted, aborting"
        )
        return
    end
    pos.y = pos.y - 1
    local meta = minetest.get_meta(pos)
    if meta:get_string("item") ~= "" then
        pos.y = pos.y + (12 / 16 + 0.11)
        tmp.nodename = node.name
        tmp.texture = ItemStack(meta:get_string("item")):get_name()
        pos.y = pos.y - (12 / 16 + 0.11)
    end
end
