create or replace function badge.data_by_radio ( p_radio_id badge.badge.RADIO_ID%TYPE )
returns refcursor
AS $$
declare
	v_ret refcursor;
begin
	open v_ret for
	select RADIO_ID, PRIV_KEY, FLAGS, REG_KEY, account_id,
	display_name, registration_time
	FROM badge
	where account_id = p_radio_id;

	return v_ret;
end; $$
language PLPGSQL security definer;
;

