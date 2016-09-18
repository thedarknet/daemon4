create or replace function badge.register ( p_account_id badge.badge.account_id%TYPE, p_code badge.badge.reg_key%TYPE
		  , p_displayName badge.badge.display_name%TYPE )
returns int
AS $$
declare
	v_radio_id badge.badge.radio_id%TYPE;
begin
	
	update badge.badge
	set account_id = p_account_id,
	  	display_name = p_displayName,
	  	registration_time = now()
	where reg_key ilike p_code || '%'
	    and account_id is null
	returning radio_id into v_radio_id;

	if v_radio_id is null then
		return 0;
	end if;

	return 1;

end; $$
language PLPGSQL security definer;
;

