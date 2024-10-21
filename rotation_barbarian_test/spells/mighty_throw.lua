local my_utility = require("my_utility/my_utility")

-- Menu elements for Mighty Throw spell
local menu_elements_mighty_throw_base =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "mighty_throw_base_main_bool")),
}

-- Function to render the menu for Mighty Throw
local function menu()
    if menu_elements_mighty_throw_base.tree_tab:push("Mighty Throw") then
        menu_elements_mighty_throw_base.main_boolean:render("Enable Spell", "")
        menu_elements_mighty_throw_base.tree_tab:pop()
    end
end

-- Spell ID for Mighty Throw
local spell_id_mighty_throw = 1611316

-- Spell data for Mighty Throw
local mighty_throw_spell_data = spell_data:new(
    2.0,                            -- radius
    1.5,                            -- range
    0.6,                            -- cast_delay
    0.0,                            -- projectile_speed
    false,                          -- has_collision
    spell_id_mighty_throw,          -- spell_id
    spell_geometry.rectangular,     -- geometry_type
    targeting_type.targeted         -- targeting_type
)

-- Variable to track when the next cast is allowed
local next_time_allowed_cast = 0.0

-- Logic for casting Mighty Throw
local function logics(target)
    if not menu_elements_mighty_throw_base.main_boolean:get() then
        return false
    end

    local is_spell_allowed = my_utility.is_spell_allowed(true, next_time_allowed_cast, spell_id_mighty_throw)
    if not is_spell_allowed then
        return false
    end

    -- Attempt to cast Mighty Throw on the target
    if cast_spell.target(target, mighty_throw_spell_data, false) then
        -- Update the time when the next cast is allowed (12 seconds cooldown)
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + 1.0

        return true
    end

    return false
end

return {
    menu = menu,
    logics = logics
}
