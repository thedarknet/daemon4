create or replace function static.objective_get(p_quest_id static.objective.quest_id%TYPE, p_obj_index static.objective.obj_index%TYPE, p_lang static.language)
returns refcursor AS $$
declare
  v_ret refcursor;
  begin
  open v_ret for
	SELECT quest_id, obj_index, lt1.value "desc", count, activation_regex, 
       fail_activation_regex, reward_id, objective_type_enum, remote_endpoint
  FROM static.objective o
	INNER join static.localized_text_detail lt1
		on (o.desc_id = lt1.localized_text_id and lt1.language = p_lang)
	WHERE o.obj_index = COALESCE(p_obj_index, o.obj_index)
	AND o.quest_id = COALESCE(p_quest_id, o.quest_id)
	order by 1 asc;

  return v_ret;
end; $$
language PLPGSQL security definer;
;


