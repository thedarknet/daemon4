create or replace function static.objective_delete_by_quest
  ( p_quest_id static.objective.quest_id%TYPE
  )
returns void AS $$
declare 
begin
  delete from static.objective where quest_id = p_quest_id;
end; $$
language PLPGSQL security definer;
;

