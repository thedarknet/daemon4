create or replace function static.objective_delete
  ( p_quest_id static.objective.quest_id%TYPE,
  	p_obj_index static.objective.obj_index%TYPE
  )
returns void AS $$
declare 
begin
  delete from static.objective where quest_id = p_quest_id and obj_index = p_obj_index;
end; $$
language PLPGSQL security definer;
;
