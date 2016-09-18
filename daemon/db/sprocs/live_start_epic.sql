create or replace function live.start_epic( p_account_id live.account.account_id%TYPE, p_epic_id static.epic.epic_id%TYPE, p_code text )
returns 
	TABLE(object_type live.epic_object_type, action_type live.epic_action_type, action_text static.localized_text_detail.value%TYPE, action_count int)
AS $$
declare
	v_cur_time timestamp;
	v_epic_id static.epic.epic_id%TYPE;
	v_found_code boolean = false;
	v_lang live.account.language_id%TYPE;
begin
	select now() + time_shift, language_id into v_cur_time, v_lang
	from live.account
	where account_id = p_account_id;

	if p_epic_id is not null then
		-- check if the epic is already in progress
		if (select count(1)
			from live.epic
			where epic_id = p_epic_id
				and account_id = p_account_id
				and complete_time is null
				and fail_time is null) > 0
		then
			perform live.throw_epic_in_progress();
		end if;

		-- ensure account is eligible
		if live.is_eligible_for_epic(p_account_id, p_epic_id, v_cur_time) = false 
		then
			perform live.throw_epic_not_available();
		end if;

		return query(select * from live.start_epic_internal(p_account_id, p_epic_id, v_lang));
	end if;

	-- look for any hidden epics that could be activated by the code
	if p_code is not null then
		for v_epic_id in 
			select epic_id 
			from static.epic 
			where activation_regex ~* p_code
				and live.is_eligible_for_epic(p_account_id, epic_id, v_cur_time)
		loop
			return query(select * from live.start_epic_internal(p_account_id, v_epic_id, v_lang));
			v_found_code = true;
		end loop;
		-- no epics found for code
		if v_found_code = false then
			perform live.throw_epic_not_available();
		end if;
	end if;
end; $$
language PLPGSQL security definer;
;

-- Called once all verification has been done
create or replace function live.start_epic_internal( p_account_id live.account.account_id%TYPE, p_epic_id static.epic.epic_id%TYPE, p_lang live.account.language_id%TYPE)
returns 
	TABLE(object_type live.epic_object_type, action_type live.epic_action_type, action_text static.localized_text_detail.value%TYPE, action_count int)
AS $$
declare
	v_live_epic_id live.epic.live_epic_id%TYPE;
	v_quest_id static.quest.quest_id%TYPE;
	v_logic_group static.epic_quest_map_sequence.logic_group_id%TYPE;
begin
	insert into live.epic (account_id, epic_id, start_time)
	values (p_account_id, p_epic_id, now())
	returning live_epic_id into v_live_epic_id;

	select min(logic_group_id) into v_logic_group
	from static.epic_quest_map_sequence
	where epic_id = p_epic_id;

	return query ( 
		select 
			'EPIC'::live.epic_object_type
		  , 'START'::live.epic_action_type
		  , static.get_localized_text(start_text_id, p_lang) 
		  , 1
		from static.epic 
		where epic_id = p_epic_id);
	return query (select * from live.start_quest_logic_group( v_live_epic_id, v_logic_group, p_lang ));
	return;

end; $$
language PLPGSQL security definer;
;

