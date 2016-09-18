CREATE OR REPLACE FUNCTION static.epic_required_epic_map_get(p_target_epic_id static.epic_required_epics.target_epic_id%TYPE)
  RETURNS refcursor AS $$
declare 
  v_ret refcursor;
begin
  open v_ret for
  SELECT target_epic_id, required_epic_id
  FROM static.epic_required_epics a
  where a.target_epic_id = COALESCE(p_target_epic_id,a.target_epic_id);
  return v_ret;
end; $$
language PLPGSQL security definer;
;
