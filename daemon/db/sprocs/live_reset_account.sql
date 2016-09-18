create or replace function live.reset_account( p_account_id live.account.account_id%TYPE )
returns void
AS $$
begin
	delete from live.objective 
	where live_quest_id in (
		select live_quest_id 
		from live.quest q
		inner join live.epic e
			on e.live_epic_id = q.live_epic_id
		and e.account_id = p_account_id);

	delete from live.quest 
	where live_epic_id in (
		select live_epic_id
		from live.epic
		where account_id = p_account_id);

	delete from live.epic 
	where account_id = p_account_id;
end; $$
language PLPGSQL security definer;
;

