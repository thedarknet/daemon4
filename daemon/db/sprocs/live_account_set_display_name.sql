create or replace function live.account_set_display_name ( p_account_id live.account.account_id%TYPE, p_new_name live.account.display_name%TYPE )
returns 
	void
AS $$
declare
begin
	
	update live.account
	set display_name = p_new_name
	where account_id = p_account_id;

end; $$
language PLPGSQL security definer;
;
