--select static.remove_epic_map(1)
--
create or replace function static.epic_quest_map_sequence_delete
  ( p_epic_id static.epic_quest_map_sequence.epic_id%TYPE
  )
returns void AS $$
declare 
begin
  delete from static.epic_quest_map_sequence where epic_id = p_epic_id;
end; $$
language PLPGSQL security definer;
;

