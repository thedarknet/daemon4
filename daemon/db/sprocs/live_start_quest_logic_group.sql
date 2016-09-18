create or replace function live.start_quest_logic_group ( p_live_epic_id live.epic.live_epic_id%TYPE, p_logic_group static.epic_quest_map_sequence.logic_group_id%TYPE, p_lang live.account.language_id%TYPE )
returns 
	TABLE(object_type live.epic_object_type, action_type live.epic_action_type, action_text static.localized_text_detail.value%TYPE, action_count int)
AS $$
declare
	v_quest_id static.quest.quest_id%TYPE;
begin
	-- begin starting quests
	for v_quest_id in
		select quest_id 
		from static.epic_quest_map_sequence qm
		inner join live.epic le
			on le.epic_id = qm.epic_id
		where le.live_epic_id = p_live_epic_id
		  and logic_group_id = p_logic_group
	loop
		return query (select * from live.start_quest(p_live_epic_id, p_logic_group, v_quest_id, p_lang));
	end loop;	

end; $$
language PLPGSQL security definer;
;
