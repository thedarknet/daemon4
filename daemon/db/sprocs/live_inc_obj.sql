create or replace function live.inc_obj_by_code ( p_account_id live.account.account_id%TYPE, p_code text )
returns 
	TABLE(
		  live_objective_id live.objective.live_objective_id%TYPE
		, remote_endpoint static.objective.remote_endpoint%TYPE
		, new_count live.objective.current_count%TYPE
		, max_count static.objective.count%TYPE
		, object_type live.epic_object_type
		, action_type live.epic_action_type
		, action_text static.localized_text_detail.value%TYPE
		, action_count int)
AS $$
declare
	v_obj record;
	v_lang live.account.language_id%TYPE;
begin
	select language_id into v_lang
	from live.account
	where account_id = p_account_id;

	-- Find any objectices that the code might apply to
	for v_obj in select 
				     o.live_objective_id
				   , so.objective_type_enum
				   , so.remote_endpoint
				   , so.count
				   , o.current_count
				   , (p_code ~* so.activation_regex) success
				   , (p_code ~* so.fail_activation_regex) fail
	             from live.epic e
	             inner join live.quest q on e.live_epic_id = q.live_epic_id
	             inner join live.objective o on o.live_quest_id = q.live_quest_id
	             inner join static.objective so on so.objective_id = o.objective_id
	             where e.account_id = p_account_id
	               and (p_code ~* so.activation_regex)
	               and o.complete_time is null
	               and o.fail_time is null
	loop
		if v_obj.objective_type_enum = 'REMOTE' then
			return query (select v_obj.live_objective_id, v_obj.remote_endpoint, null::int, null::int, null::live.epic_object_type, null::live.epic_action_type, null::text, null::int);
		else
			return query ( select 
						       null::numeric
						     , null::text
						     , i.new_count
						     , v_obj.count
						     , i.object_type
						     , i.action_type
						     , i.action_text
						     , i.action_count
						   from live.inc_obj_internal(p_account_id, v_obj.live_objective_id, 1, v_obj.count, null, v_lang) i);
		end if;
	end loop;
end; $$
language PLPGSQL security definer;
;

create or replace function live.inc_obj_for_remote ( p_live_objective_id live.objective.objective_id%TYPE, p_count static.objective.count%TYPE, p_metadata live.inventory_details.metadata%TYPE )
returns
	TABLE(new_count live.objective.current_count%TYPE, max_count static.objective.count%TYPE, object_type live.epic_object_type, action_type live.epic_action_type, action_text static.localized_text_detail.value%TYPE, action_count int)
AS $$
declare
	v_account_id live.account.account_id%TYPE;
	v_lang live.account.language_id%TYPE;
	v_max_count static.objective.count%TYPE;
begin
	select
		e.account_id
	  , a.language_id
	  , so.count
	into
	    v_account_id
	  , v_lang
	  , v_max_count
	from live.objective o
	inner join live.quest q
		on q.live_quest_id = o.live_quest_id
	inner join live.epic e
		on e.live_epic_id = q.live_epic_id
	inner join live.account a
		on a.account_id = e.account_id
	inner join static.objective so
		on so.objective_id = o.objective_id
	where o.live_objective_id = p_live_objective_id;

	if v_account_id is not null then
		return query (select 
						  i.new_count
						, v_max_count
						, i.object_type
						, i.action_type
						, i.action_text
						, i.action_count
						from live.inc_obj_internal(v_account_id, p_live_objective_id, p_count, v_max_count, p_metadata, v_lang) i);
	end if;

end; $$
language PLPGSQL security definer;
;

create or replace function live.inc_obj_internal ( p_account_id live.account.account_id%TYPE, p_live_objective_id live.objective.live_objective_id%TYPE, p_count static.objective.count%TYPE, p_max_count static.objective.count%TYPE, p_metadata live.inventory_details.metadata%TYPE, p_lang live.account.language_id%TYPE)
returns 
	TABLE(new_count live.objective.current_count%TYPE, object_type live.epic_object_type, action_type live.epic_action_type, action_text static.localized_text_detail.value%TYPE, action_count int)
AS $$
declare
	v_count live.objective.current_count%TYPE;
	v_live_quest_id live.quest.live_quest_id%TYPE;
	v_obj_id static.objective.objective_id%TYPE;
	v_reward_id static.reward.reward_id%TYPE;
begin
	update live.objective
	  	set current_count = least(current_count + p_count, p_max_count)
		where live_objective_id = p_live_objective_id
			and current_count < p_max_count
		returning current_count, live_quest_id, objective_id into v_count, v_live_quest_id, v_obj_id;

	if v_count is not null then

		return query (
			select 
			    v_count
			  , null::live.epic_object_type
			  , null::live.epic_action_type
			  , static.get_localized_text(desc_id, p_lang)
			  , 1
			from static.objective
			where objective_id = v_obj_id);

		if v_count >= p_max_count then
			update live.objective
				set complete_time = now()
				where live_objective_id = p_live_objective_id;

			select reward_id into v_reward_id
			from static.objective
			where objective_id = v_obj_id;
			
			if v_reward_id is not null then 
				return query (select null::integer, q.* from live.grant_reward(p_account_id, v_reward_id, p_metadata, p_lang) q);
			end if;
		end if;

		if (select count(1) 
			from live.objective
			where live_quest_id = v_live_quest_id
				and complete_time is null
				and fail_time is null) = 0 
		then
			return query (select null::integer, q.* from live.complete_quest(v_live_quest_id, p_metadata, p_lang) q);
		end if;

	end if;
end; $$
language PLPGSQL security definer;
;


