CREATE OR REPLACE FUNCTION static.epic_required_epics_create(p_target_epic_id static.epic_required_epics.target_epic_id%TYPE, 
		p_required_epic_id static.epic_required_epics.required_epic_id%TYPE)
  RETURNS void AS
$BODY$
declare 
begin
  INSERT INTO static.epic_required_epics(
            target_epic_id, required_epic_id)
    VALUES (p_target_epic_id,p_required_epic_id) 
    ON CONFLICT DO NOTHING;
end; $BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
 ;
