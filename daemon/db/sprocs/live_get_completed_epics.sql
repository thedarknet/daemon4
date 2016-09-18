create or replace function live.get_completed_epics( p_account_id live.account.account_id%TYPE )
returns 
	table( id live.epic.live_epic_id%TYPE
		 , name static.localized_text_detail.value%TYPE
		 , description static.localized_text_detail.value%TYPE
		 , long_desc static.localized_text_detail.value%TYPE
		 , group_size static.epic.group_size%TYPE
		 , flags static.epic.flags%TYPE
		 , status text
		 , complete_time live.epic.complete_time%TYPE
		 ) 
AS $$
declare
	v_lang static.language;
begin

	select language_id into v_lang
	from live.account
	where account_id = p_account_id;

	return query(
		select 
		    e.live_epic_id
		  , static.get_localized_text(se.name_id, v_lang)
		  , static.get_localized_text(se.complete_desc_id, v_lang)
		  , static.get_localized_text(se.long_desc_id, v_lang)
		  , se.group_size
		  , se.flags
		  , case when e.complete_time is not null then 'SUCCESS' else 'FAIL' end status
		  , coalesce(e.complete_time, e.fail_time)
		from static.epic se
		inner join live.epic e
		    on e.epic_id = se.epic_id
		where account_id = p_account_id
			and (e.complete_time is not null or e.fail_time is not null)
	);
end; $$
language PLPGSQL security definer;
;