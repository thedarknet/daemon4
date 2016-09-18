  
create or replace function static.epic_quest_map_create
  ( p_display_id static.epic_quest_map_sequence.display_id%TYPE
  , p_logic_group_id static.epic_quest_map_sequence.logic_group_id%TYPE
  , p_epic_id static.epic_quest_map_sequence.epic_id%TYPE
  , p_quest_id static.epic_quest_map_sequence.quest_id%TYPE
  , p_failed_epic_id static.epic_quest_map_sequence.failed_epic_id%TYPE
  , p_success_epic_id static.epic_quest_map_sequence.success_epic_id%TYPE
  , p_flags static.epic_quest_map_sequence.flag%TYPE
  , p_modality static.quest_modality
  )
returns void AS $$
declare 
begin
   INSERT INTO static.epic_quest_map_sequence(
            epic_quest_map_seq, display_id, logic_group_id, epic_id, quest_id, 
            failed_epic_id, success_epic_id, flag, modality)
    VALUES (DEFAULT, p_display_id, p_logic_group_id, p_epic_id, p_quest_id, 
            p_failed_epic_id, p_success_epic_id, p_flags, p_modality);
  end; $$
language PLPGSQL security definer;
;

