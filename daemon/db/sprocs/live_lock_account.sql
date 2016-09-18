create or replace function live.lock_account(p_account_id live.account.account_id%TYPE)
returns void AS $$
begin
	perform from live.account where account_id = p_account_id for update;
end; $$
language PLPGSQL security definer;
;

