create or replace function live.start_quest( p_live_epic_id live.epic.live_epic_id%TYPE, p_logic_group static.epic_quest_map_sequence.logic_group_id%TYPE, p_quest_id static.quest.quest_id%TYPE, p_lang live.account.language_id%TYPE )
returns 
	TABLE(object_type live.epic_object_type, action_type live.epic_action_type, action_text static.localized_text_detail.value%TYPE, action_count int)
AS $$
declare
	v_live_quest_id live.quest.live_quest_id%TYPE;
begin
	insert into live.quest (live_quest_id, live_epic_id, logic_group_id, quest_id, start_time) 
	values (DEFAULT, p_live_epic_id, p_logic_group, p_quest_id, now())
	returning live_quest_id into v_live_quest_id;

	insert into live.objective (live_quest_id, objective_id, current_count, start_time)
		select 
		    v_live_quest_id
		  , objective_id
		  , 0
		  , now()
		 from static.objective
		 where quest_id = p_quest_id;

	return query ( 
		select 
			'QUEST'::live.epic_object_type
		  , 'START'::live.epic_action_type
		  , static.get_localized_text(start_text_id, p_lang) 
		  , 1
		from static.quest 
		where quest_id = p_quest_id);
	return;

end; $$
language PLPGSQL security definer;
;
