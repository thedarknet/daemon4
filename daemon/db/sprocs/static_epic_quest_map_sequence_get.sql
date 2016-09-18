create or replace function static.epic_quest_map_sequence_get(p_epic_id static.epic_quest_map_sequence.epic_id%TYPE)
returns refcursor AS $$
declare
  v_ret refcursor;
  begin
    open v_ret for
    SELECT epic_quest_map_seq, display_id, logic_group_id, epic_id, quest_id, 
       failed_epic_id, success_epic_id, flag, modality
  FROM static.epic_quest_map_sequence a
  WHERE a.epic_id = COALESCE(p_epic_id, a.epic_id);
  
  return v_ret;
end; $$
language PLPGSQL security definer;
;
