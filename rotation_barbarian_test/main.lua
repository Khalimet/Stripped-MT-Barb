local inner_calm_buff = false
local last_spell_id = nil -- This will store the ID of the last spell cast
local bash_counter = 0
local last_mighty_throw_cast_time = 0
local mighty_throw_cooldown = 1.0 -- Example cooldown for Mighty Throw (in seconds)- Spell IDs

local BASH_SPELL_ID = 200765
local MIGHTY_THROW_SPELL_ID = 1611316
local local_player = get_local_player();
if local_player == nil then
    return
end
local buffs = local_player:get_buffs()  
local character_id = local_player:get_character_class_id();
local is_barbarian = character_id == 1;
if not is_barbarian then
     return
end;

local menu = require("menu");

local spells =
{
    bash                = require("spells/bash"),
    mighty_throw       = require("spells/mighty_throw"),
    call_of_the_ancients = require("spells/call_of_the_ancients"),
    challenging_shout   = require("spells/challenging_shout"),
    rallying_cry        = require("spells/rallying_cry"),
    charge              = require("spells/charge"),
    steel_grasp          = require("spells/steel_grasp"),
    war_cry             = require("spells/war_cry"),
}

on_render_menu (function ()

    if not menu.main_tree:push("Barbarian: Base") then
        return;
    end;

    menu.main_boolean:render("Enable Plugin", "");

    if menu.main_boolean:get() == false then
      -- plugin not enabled, stop rendering menu elements
      menu.main_tree:pop();
      return;
   end;
 
    spells.bash.menu();
    spells.mighty_throw.menu();
    spells.call_of_the_ancients.menu();
    spells.challenging_shout.menu();
    spells.rallying_cry.menu();
    spells.charge.menu();
    spells.steel_grasp.menu();
    spells.war_cry.menu();

    menu.main_tree:pop();

end
)

local can_move = 0.0;
local cast_end_time = 0.0;
local WantToCastMightyThrow = false
local TimeSinceLastMove = 0;
local my_utility = require("my_utility/my_utility");
local my_target_selector = require("my_utility/my_target_selector");

-- on_update callback
on_update(function ()

    local local_player = get_local_player();
    if not local_player then
        return;
    end
    
    if menu.main_boolean:get() == false then
        -- if plugin is disabled dont do any logic
        return;
    end;

    local current_time = get_time_since_inject()
    if current_time < cast_end_time then
        return;
    end;
	
	if local_player:get_current_speed() ~= 0 then 
		TimeSinceLastMove = get_time_since_inject()
		inner_calm_buff = false
	end
	
	if TimeSinceLastMove + 3 < get_time_since_inject() then 
		
		inner_calm_buff = true
	end
      -- Track active spell
    last_spell_id = local_player:get_active_spell_id()
    local buffs = local_player:get_buffs() 
    for _, buff in ipairs(buffs) do
        if buff.name_hash == 201523 then  -- Replace `inner_calm_buff_name` with the actual name of the buff
			if local_player:get_current_speed() ~= 0 then 
				TimeSinceLastMove = get_time_since_inject()
				inner_calm_buff = false
			end
	
			if TimeSinceLastMove + 3 < get_time_since_inject() then 
				inner_calm_buff = true
			end
            break  
        end
    end

    
       -- Check if Bash was cast
    --   if last_spell_id == BASH_SPELL_ID then
    --    bash_counter = bash_counter + 1 -- Increment Bash counter
    --    return
    --end
	--
    --       -- Check if Mighty Throw was cast
    --if last_spell_id == MIGHTY_THROW_SPELL_ID then
    --    console.print("Casted Mighty Throw, resetting Bash counter.")
    --    bash_counter = 0 -- Reset Bash counter after casting Mighty Throw
    --    last_mighty_throw_cast_time = current_time -- Track Mighty Throw cooldown
    --    cast_end_time = current_time + 1.0 -- Prevent rapid recasting
    --    return -- Exit to prevent further actions this update cycle
    --end

    -- Check if any action is allowed (utility function)
    if not my_utility.is_action_allowed() then
        return;
    end  

    local screen_range = 16.0;
    local player_position = get_player_position();

    local collision_table = { false, 2.0 };
    local floor_table = { true, 5.0 };
    local angle_table = { false, 90.0 };

    local entity_list = my_target_selector.get_target_list(
        player_position,
        screen_range, 
        collision_table, 
        floor_table, 
        angle_table);

    local target_selector_data = my_target_selector.get_target_selector_data(
        player_position, 
        entity_list);

    if not target_selector_data.is_valid then
        return;
    end

    local is_auto_play_active = auto_play.is_active();
    local max_range = 10.0;
    if is_auto_play_active then
        max_range = 12.0;
    end

    local best_target = target_selector_data.closest_unit;

    if target_selector_data.has_elite then
        local unit = target_selector_data.closest_elite;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end        
    end

    if target_selector_data.has_boss then
        local unit = target_selector_data.closest_boss;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end
    end

    if target_selector_data.has_champion then
        local unit = target_selector_data.closest_champion;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end
    end   

    if not best_target then
        return;
    end
	WantToCastMightyThrow = false
	 for _, buff in ipairs(buffs) do
        if buff.name_hash == 1294288 and buff.stacks == 4 then 
            WantToCastMightyThrow = true -- or true/false
            break  
        end
    end
    local best_target_position = best_target:get_position();
    local distance_sqr = best_target_position:squared_dist_to_ignore_z(player_position);

    if distance_sqr > (max_range * max_range) then            
        best_target = target_selector_data.closest_unit;
        local closer_pos = best_target:get_position();
        local distance_sqr_2 = closer_pos:squared_dist_to_ignore_z(player_position);
        if distance_sqr_2 > (max_range * max_range) then
            return;
        end
    end

         -- Spell casting logic
    -- Simplified casting order without dependency between Bash and Mighty Throw

    -- Check if Mighty Throw should be cast (priority over Bash if ready)
    
    if WantToCastMightyThrow == true and spells.mighty_throw.logics(best_target) then  
         console.print("YEEHAAW")-- Update the time for Mighty Throw
        cast_end_time = current_time + 0.5 -- Small delay to prevent rapid recasting
        return
    end
    

    -- Only cast Bash if Mighty Throw is not ready to be cast
    if WantToCastMightyThrow == false and spells.bash.logics(entity_list) then
        console.print("Casted Bash")
        cast_end_time = current_time + 0.2 -- Set the cast time to prevent rapid casting
         -- Increment Bash counter
        return
    end
    -- Check utility/buff spells next (e.g., Shouts)
    if spells.challenging_shout.logics() then
        return
    end

    if spells.war_cry.logics() then
        return
    end

    if spells.rallying_cry.logics() then
        return
    end

    -- Check other active abilities or movement spells
    if spells.charge.logics(best_target) then
        cast_end_time = current_time + 0.2
        return
    end

    if spells.steel_grasp.logics() then
        return
    end

    if spells.call_of_the_ancients.logics() then
        return
    end


     -- auto play engage far away monsters
     local move_timer = get_time_since_inject()
     if move_timer < can_move then
         return;
     end;
 
 
     local is_auto_play = my_utility.is_auto_play_enabled();
     if is_auto_play then
         local player_position = local_player:get_position();
         local is_dangerous_evade_position = evade.is_dangerous_position(player_position);
         if not is_dangerous_evade_position then
             local closer_target = target_selector.get_target_closer(player_position, 15.0);
             if closer_target then
                 -- if is_blood_mist then
                 --     local closer_target_position = closer_target:get_position();
                 --     local move_pos = closer_target_position:get_extended(player_position, -5.0);
                 --     if pathfinder.move_to_cpathfinder(move_pos) then
                 --         cast_end_time = current_time + 0.40;
                 --         can_move = move_timer + 1.50;
                 --         --console.print("auto play move_to_cpathfinder - 111")
                 --     end
                 -- else
                     local closer_target_position = closer_target:get_position();
                     local move_pos = closer_target_position:get_extended(player_position, 4.0);
                     if pathfinder.move_to_cpathfinder(move_pos) then
                         can_move = move_timer + 1.50;
                         --console.print("auto play move_to_cpathfinder - 222")
                     end
                 -- end
                 
             end
         end
     end
 
 end)
 
 local draw_player_circle = false;
 local draw_enemy_circles = false;
 
 on_render(function ()
 
     if menu.main_boolean:get() == false then
         return;
     end;
 
     local local_player = get_local_player();
     if not local_player then
         return;
     end
 
     local player_position = local_player:get_position();
     local player_screen_position = graphics.w2s(player_position);
     if player_screen_position:is_zero() then
         return;
     end
 
     if draw_player_circle then
         graphics.circle_3d(player_position, 8, color_white(85), 3.5, 144)
         graphics.circle_3d(player_position, 6, color_white(85), 2.5, 144)
     end    
 
     if draw_enemy_circles then
         local enemies = actors_manager.get_enemy_npcs()
 
         for i,obj in ipairs(enemies) do
         local position = obj:get_position();
         local distance_sqr = position:squared_dist_to_ignore_z(player_position);
         local is_close = distance_sqr < (8.0 * 8.0);
             -- if is_close then
                 graphics.circle_3d(position, 1, color_white(100));
 
                 local future_position = prediction.get_future_unit_position(obj, 0.4);
                 graphics.circle_3d(future_position, 0.5, color_yellow(100));
             -- end;
         end;
     end
 
 
     -- glow target -- quick pasted code cba about this game
 
     local screen_range = 16.0;
     local player_position = get_player_position();
 
     local collision_table = { false, 2.0 };
     local floor_table = { true, 5.0 };
     local angle_table = { false, 90.0 };
 
     local entity_list = my_target_selector.get_target_list(
         player_position,
         screen_range, 
         collision_table, 
         floor_table, 
         angle_table);
 
     local target_selector_data = my_target_selector.get_target_selector_data(
         player_position, 
         entity_list);
 
     if not target_selector_data.is_valid then
         return;
     end
  
     local is_auto_play_active = auto_play.is_active();
     local max_range = 10.0;
     if is_auto_play_active then
         max_range = 12.0;
     end
 
     -- console.print(max_range)
 
     local best_target = target_selector_data.closest_unit;
 
     if target_selector_data.has_elite then
         local unit = target_selector_data.closest_elite;
         local unit_position = unit:get_position();
         local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
         if distance_sqr < (max_range * max_range) then
             best_target = unit;
         end        
     end
 
     if target_selector_data.has_boss then
         local unit = target_selector_data.closest_boss;
         local unit_position = unit:get_position();
         local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
         if distance_sqr < (max_range * max_range) then
             best_target = unit;
         end
     end
 
     if target_selector_data.has_champion then
         local unit = target_selector_data.closest_champion;
         local unit_position = unit:get_position();
         local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
         if distance_sqr < (max_range * max_range) then
             best_target = unit;
         end
     end   
 
     if not best_target then
         return;
     end
 
     if best_target and best_target:is_enemy()  then
         local glow_target_position = best_target:get_position();
         local glow_target_position_2d = graphics.w2s(glow_target_position);
         graphics.line(glow_target_position_2d, player_screen_position, color_red(180), 2.5)
         graphics.circle_3d(glow_target_position, 0.80, color_red(200), 2.0);
     end
 
 
 end);
 
 console.print("Lua Plugin - Barbarian Base - Version 1.5");


