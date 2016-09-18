create or replace function live.get_current_event( p_account_id live.account.account_id%TYPE )
returns 
	static.event.event_id%TYPE
AS $$
declare
	v_cur_time timestamp;
	v_cur_event static.event.event_id%TYPE;
begin
	select now() + time_shift into v_cur_time
	from live.account
	where account_id = p_account_id;

	select event_id into v_cur_event
	from static.event
	where time_range @> v_cur_time;

	return v_cur_event;
end; $$
language PLPGSQL security definer;
;