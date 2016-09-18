create or replace function live.account_set_type ( p_account_id live.account.account_id%TYPE, p_new_type live.account.user_type%TYPE )
returns 
	void
AS $$
declare
begin
	
	update live.account
	set user_type = p_new_type
	where account_id = p_account_id;

end; $$
language PLPGSQL security definer;
;
