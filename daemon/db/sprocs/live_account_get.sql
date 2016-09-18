create or replace function live.account_get ( p_account_id live.account.account_id%TYPE )
returns 
	TABLE(account_id live.account.account_id%TYPE, display_name live.account.display_name%TYPE, user_type live.account.user_type%TYPE)
AS $$
declare
begin
	return query (
		select 
		    a.account_id
		  , a.display_name
		  , a.user_type
		from live.account a
		where a.account_id = p_account_id
	);
end; $$
language PLPGSQL security definer;
;

create or replace function live.account_get_by_remote_account ( p_service live.account.remote_service_name%TYPE, p_account live.account.remote_service_account_name%TYPE )
returns 
	TABLE(account_id live.account.account_id%TYPE, display_name live.account.display_name%TYPE, user_type live.account.user_type%TYPE)
AS $$
declare
begin
	return query(select * from live.account_get ((select a.account_id from live.account a where remote_service_name = p_service and remote_service_account_name = p_account)));
end; $$
language PLPGSQL security definer;
;
