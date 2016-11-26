create or replace function live.get_available_epics( p_account_id live.account.account_id%TYPE )
returns 
	table( id static.epic.epic_id%TYPE
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
	v_lang static.language;
begin
	perform live.lock_account(p_account_id);

	select now() + time_shift, language_id into v_cur_time, v_lang
	from live.account
	where account_id = p_account_id;

	return query(
		select 
		    se.epic_id
		  , static.get_localized_text(se.name_id, v_lang)
		  , static.get_localized_text(se.desc_id, v_lang)
		  , static.get_localized_text(se.long_desc_id, v_lang)
		  , case se.end_date when 'infinity' then null else se.end_date end
		  , se.repeat_count
		  , (select count(1) from live.epic le where le.epic_id = se.epic_id and le.complete_time is not null)::integer repeat_current
		  , se.group_size
		  , se.flags
		from static.epic se, static.event_epic ee
		where (se.visibility_enum = 'ALWAYS' or se.visibility_enum = 'ELIGIBLE') 
		and live.is_eligible_for_epic(p_account_id, se.epic_id, v_cur_time)
		and ee.event_id = v_cur_event 
	);
end; $$
language PLPGSQL security definer;
;
