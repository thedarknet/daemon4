create or replace function live.complete_quest ( p_live_quest_id live.quest.live_quest_id%TYPE, p_metadata live.inventory_details.metadata%TYPE , p_lang live.account.language_id%TYPE )
returns 
	TABLE(object_type live.epic_object_type, action_type live.epic_action_type, action_text static.localized_text_detail.value%TYPE, action_count int)
AS $$
declare
	v_live_epic_id live.epic.live_epic_id%TYPE;
	v_quest_id static.quest.quest_id%TYPE;
	v_cur_logic_group static.epic_quest_map_sequence.logic_group_id%TYPE;
	v_next_logic_group static.epic_quest_map_sequence.logic_group_id%TYPE;
	v_success_epic_id static.epic_quest_map_sequence.success_epic_id%TYPE;
	v_account_id live.account.account_id%TYPE;
	v_reward_id static.reward.reward_id%TYPE;
begin
	update live.quest
	set complete_time = now()
	where live_quest_id = p_live_quest_id
		and complete_time is null
		and fail_time is null
	returning live_epic_id, logic_group_id, quest_id into v_live_epic_id, v_cur_logic_group, v_quest_id;

	if v_live_epic_id is not null then
		return query (
			select
			    'QUEST'::live.epic_object_type
			  , 'SUCCESS'::live.epic_action_type
			  , static.get_localized_text(success_text_id, p_lang)
			  , 1
			  from static.quest
			  where quest_id = v_quest_id);

			select reward_id into v_reward_id
			from static.quest
			where quest_id = v_quest_id;

		-- start new epics if nessasary
		select success_epic_id, account_id into v_success_epic_id, v_account_id
		from live.quest q
		inner join live.epic e
			on e.live_epic_id = q.live_epic_id
		inner join static.epic_quest_map_sequence qm
			on qm.epic_id = e.epic_id
		where qm.logic_group_id = v_cur_logic_group
			and q.live_quest_id = p_live_quest_id;

			if v_reward_id is not null then 
				return query (select * from live.grant_reward(v_account_id, v_reward_id, p_metadata, p_lang));
			end if;

		if v_success_epic_id is not null then
			return query (select * from live.start_epic(v_account_id, v_success_epic_id, null));
		end if;

		-- check if logic group is completed
		if (select count(1)
			from live.quest q
			inner join static.epic_quest_map_sequence qm
				on qm.quest_id = q.quest_id and qm.logic_group_id = q.logic_group_id
			inner join live.epic e
				on e.live_epic_id = q.live_epic_id
			where e.live_epic_id = v_live_epic_id
				and q.logic_group_id = v_cur_logic_group
				and qm.modality = 'MANDATORY'
				and q.complete_time is null
				and q.fail_time is null) = 0
		then
			-- find next logic group
			select min(logic_group_id) into v_next_logic_group
			from live.epic e
			inner join static.epic_quest_map_sequence qm
				on qm.epic_id = e.epic_id
			where e.live_epic_id = v_live_epic_id
				and qm.logic_group_id > v_cur_logic_group;

			-- start next logic group if it exists or close out the epic
			if v_next_logic_group is not null then
				return query (select * from live.start_quest_logic_group( v_live_epic_id, v_next_logic_group, p_lang ));
			else
				return query (select * from live.complete_epic(v_live_epic_id, p_lang));
			end if;
		end if;
	end if;

end; $$
language PLPGSQL security definer;
;
