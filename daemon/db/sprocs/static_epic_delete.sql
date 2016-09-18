create or replace function static.epic_delete(p_epic_id static.epic.epic_id%TYPE)
returns int AS $$
declare
  begin
  --todo get all columns from epic
	DELETE FROM static.epic  
	WHERE epic_id = p_epic_id;

	return 1;
end; $$
language PLPGSQL security definer;
;


