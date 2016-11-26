create or replace function live.get_current_event( p_account_id live.account.account_id%TYPE )
returns 
	table ( id static.event.event_id%TYPE)
AS $$
declare
	v_cur_time timestamp;
begin
	select now() + time_shift into v_cur_time
	from live.account
	where account_id = p_account_id;

	return query (
		select se.event_id 
		from static.event se, static.event_entitlement_map eem,
			live.account_entitlement ae
		where time_range @> v_cur_time
		and se.event_id = eem.event_id
		and ae.account_id = p_account_id
		and eem.entitlement_enum = ae.entitlement_enum
	);
end; $$
language PLPGSQL security definer;
;
