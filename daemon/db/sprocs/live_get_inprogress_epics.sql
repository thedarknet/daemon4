create or replace function live.get_inprogress_epics( p_account_id live.account.account_id%TYPE )
returns 
	table( id live.epic.live_epic_id%TYPE
		 , name static.localized_text_detail.value%TYPE
		 , description static.localized_text_detail.value%TYPE
		 , long_desc static.localized_text_detail.value%TYPE
		 , end_date static.epic.end_date%TYPE
		 , repeat_max static.epic.repeat_count%TYPE
		 , repeat_count static.epic.repeat_count%TYPE
		 , group_size static.epic.group_size%TYPE
		 , flags static.epic.flags%TYPE
		 ) 
AS $$
declare
	v_cur_time timestamp;
	v_lang live.account.language_id%TYPE;
begin
	select now() + time_shift, language_id into v_cur_time, v_lang
	from live.account
	where account_id = p_account_id;

	return query(
		select 
			e.live_epic_id
		  , static.get_localized_text(se.name_id, v_lang)
		  , static.get_localized_text(se.inprogress_desc_id, v_lang)
		  , static.get_localized_text(se.long_desc_id, v_lang)
		  , case se.end_date when 'infinity' then null else se.end_date end
		  , se.repeat_count
		  , (select count(1) from live.epic le where le.epic_id = se.epic_id and le.complete_time is not null)::integer repeat_current
		  , se.group_size
		  , se.flags
		from live.epic e
		inner join static.epic se
			on se.epic_id = e.epic_id
		where account_id = p_account_id
			and e.complete_time is null
			and e.fail_time is null
	);
end; $$
language PLPGSQL security definer;
;

create or replace function live.get_inprogress_quests( p_account_id live.account.account_id%TYPE )
returns 
	table( id live.quest.live_quest_id%TYPE
		 , live_epic_id live.epic.live_epic_id%TYPE
		 , name static.localized_text_detail.value%TYPE
		 , summary static.localized_text_detail.value%TYPE
		 , description static.localized_text_detail.value%TYPE
		 , status text
		 ) 
AS $$
declare
	v_lang live.account.language_id%TYPE;
begin
	select language_id into v_lang
	from live.account
	where account_id = p_account_id;

	return query(
		select
		    q.live_quest_id
		  , e.live_epic_id
		  , static.get_localized_text(sq.name_id, v_lang)
		  , static.get_localized_text(sq.summary_text_id, v_lang)
		  , case
			  	when q.complete_time is not null then static.get_localized_text(sq.success_text_id, v_lang)
			  	when q.fail_time is not null then static.get_localized_text(sq.fail_text_id, v_lang)
			  	else static.get_localized_text(sq.start_text_id, v_lang)
		  	end
		  , case
			  	when q.complete_time is not null then 'SUCCESS'
			  	when q.fail_time is not null then 'FAILED'
			  	else 'IN_PROGRESS'
		  	end
		from live.quest q
		inner join static.quest sq
			on sq.quest_id = q.quest_id
		inner join live.epic e
			on e.live_epic_id = q.live_epic_id
		inner join static.epic_quest_map_sequence qm
			on qm.epic_id = e.epic_id and qm.quest_id=q.quest_id
		where account_id = p_account_id
			and e.complete_time is null
			and e.fail_time is null
		order by qm.epic_id, q.logic_group_id, qm.display_id
		);
end; $$
language PLPGSQL security definer;
;

create or replace function live.get_inprogress_objectives( p_account_id live.account.account_id%TYPE )
returns 
	table( live_quest_id live.quest.live_quest_id%TYPE
		 , description static.localized_text_detail.value%TYPE
		 , current_count live.objective.current_count%TYPE
		 , count static.objective.count%TYPE
		 ) 
AS $$
declare
	v_lang live.account.language_id%TYPE;
begin
	select language_id into v_lang
	from live.account
	where account_id = p_account_id;

	return query(
		select
		    q.live_quest_id
		  , static.get_localized_text(so.desc_id, v_lang)
		  , o.current_count
		  , so.count
		from live.objective o
		inner join static.objective so
			on so.objective_id = o.objective_id
		inner join live.quest q
			on q.live_quest_id = o.live_quest_id
		inner join live.epic e
			on e.live_epic_id = q.live_epic_id
		where account_id = p_account_id
			and e.complete_time is null
			and e.fail_time is null
		order by obj_index
		);
end; $$
language PLPGSQL security definer;
;