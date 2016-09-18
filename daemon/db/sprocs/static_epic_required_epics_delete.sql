CREATE OR REPLACE FUNCTION static.epic_required_epics_map_delete(p_target_epic_id static.epic_required_epics.target_epic_id%TYPE)
  RETURNS void AS
$BODY$
declare 
begin
  DELETE FROM static.epic_required_epics
  where target_epic_id = p_target_epic_id;

end; $BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
 ;