create or replace function badge.data_by_accountid ( p_account_id badge.badge.account_id%TYPE )
returns TABLE(
	  radio_id badge.badge.RADIO_ID%TYPE
	, priv_key badge.badge.PRIV_KEY%TYPE
	, flags badge.badge.FLAGS%TYPE
	, reg_key badge.badge.REG_KEY%TYPE
	, account_id badge.badge.account_id%TYPE
	, display_name badge.badge.display_name%TYPE
	, registration_time badge.badge.registration_time%TYPE)
AS $$
declare
begin
	return query (
		select b.RADIO_ID, b.PRIV_KEY, b.FLAGS, b.REG_KEY, b.account_id, b.display_name, b.registration_time
		FROM badge.badge b
		where b.account_id = p_account_id
		and b.registration_time is not null
	);
end; $$
language PLPGSQL security definer;
;

