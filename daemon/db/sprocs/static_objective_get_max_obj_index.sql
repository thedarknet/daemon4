create or replace function static.objective_get_max_obj_index(p_quest_id static.quest.quest_id%TYPE)
returns numeric AS $$
declare
	v_max_obj_index numeric;
  begin
	SELECT max(obj_index)
	into v_max_obj_index
  FROM static.objective
	WHERE quest_id = p_quest_id;

  return v_max_obj_index;
end; $$
language PLPGSQL security definer;
;


