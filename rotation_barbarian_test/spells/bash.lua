local my_utility = require("my_utility/my_utility")

-- Menu elements for Bash skill
local menu_elements_bash_base = 
{
    tree_tab           = tree_node:new(1),
    main_boolean       = checkbox:new(true, get_hash(my_utility.plugin_label .. "bash_main_bool_base")),
    use_as_filler_only = checkbox:new(true, get_hash(my_utility.plugin_label .. "bash_use_as_filler_only")),
}

-- Render the Bash menu
local function menu()
    if menu_elements_bash_base.tree_tab:push("Bash") then
        menu_elements_bash_base.main_boolean:render("Enable Spell", "")
        if menu_elements_bash_base.main_boolean:get() then
            menu_elements_bash_base.use_as_filler_only:render("Filler Only", "Only cast if Fury is low")
        end
        menu_elements_bash_base.tree_tab:pop()
    end
end

-- Bash skill setup
local spell_id_bash = 200765
local spell_range = 2 -- Close melee range

local spell_data_bash = spell_data:new(
    0.0,                        -- radius (melee skill, no range area)
    spell_range,                -- range (close range for melee attack)
    0.0,                        -- cast_delay (instant cast)
    0.0,                        -- projectile_speed (no projectile)
    true,                       -- has_collision (direct hit)
    spell_id_bash,              -- spell_id
    spell_geometry.rectangular, -- geometry_type (rectangular for melee skills)
    targeting_type.targeted     -- targeting_type (directly target enemy)
)

local function subtract2D(v1, v2,field)
	if field == true then 
		local X1 = v1:x() - v2:x();
		local V1 = v1:y() - v2:y();
		local Z1 = v1:z() - v2:z();
		return vec3:new(X1, V1,Z1)
	end
	
	
	local X1 = v1:x() - v2.x;
	local V1 = v1:y() - v2.y;
	return vec3:new(X1, V1)
	
end


local function magnitude(vec)
    return math.sqrt(vec:x()^2 + vec:y()^2 + vec:z()^2)
end

local function normalize(vec)
    local mag = magnitude(vec)
    if mag == 0 then
        return { x = 0, y = 0, z = 0 }  -- Return zero vector if magnitude is zero
    else
        return { x = vec:x() / mag, y = vec:y() / mag, z = vec:z() / mag }
    end
end

-- Main logic for Bash
local function logics(entity_list)
    if not menu_elements_bash_base.main_boolean:get() then
        return false
    end
	
    local is_spell_allowed = my_utility.is_spell_allowed(true, 0, spell_id_bash)
    if not is_spell_allowed then
        return false
    end

	local player_local = get_local_player();
	
    local player_position = player_local:get_position()
    if not player_position then
        return false
    end

	
    -- Filter entities within Bash range
    local filtered_entities = {}
    for _, target in ipairs(entity_list) do
        local target_position = target:get_position()
        if target_position then
            local distance_sqr = player_position:squared_dist_to_ignore_z(target_position)
            if distance_sqr <= (spell_range * spell_range) then
                table.insert(filtered_entities, { entity = target, distance_sqr = distance_sqr })
            end
        end
    end

    -- Sort by distance and cast Bash on the closest target
    table.sort(filtered_entities, function(a, b) return a.distance_sqr < b.distance_sqr end)
	
	
	
	
    local target = filtered_entities[1] and filtered_entities[1].entity
    if target then
	
		local DirectionToTarget = subtract2D(target:get_position(),player_position,true)
		local Norm = normalize(DirectionToTarget)
		
	--if cast_spell.target(target, spell_data_bash, false) then
        if cast_spell.position(spell_id_bash, vec3:new(Norm.x * 0.3 + player_position:x(),Norm.y * 0.3+ player_position:y(),Norm.z * 0.3+ player_position:z()), 5) then
			--console.print( target:get_position():z())
            return true
        end
    end

    return false
end

return {
    menu = menu,
    logics = logics
}
