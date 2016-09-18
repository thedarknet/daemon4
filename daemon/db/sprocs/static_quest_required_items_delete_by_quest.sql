create or replace function static.quest_required_items_delete_by_quest
  ( p_quest_id static.quest_required_items.quest_id%TYPE
  )
returns void AS $$
declare 
begin
  delete from static.quest_required_items where quest_id = p_quest_id;
end; $$
language PLPGSQL security definer;
;

