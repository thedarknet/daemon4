create or replace function live.is_eligible_for_epic( p_account_id live.account.account_id%TYPE, p_epic_id static.epic.epic_id%TYPE, p_cur_time timestamp )
returns boolean
AS $$
begin
	
	-- ensure basic reqs
	if (select count(1)	
		from static.epic se
		where epic_id = p_epic_id
			-- ensure current
			and p_cur_time between start_date and end_date
			-- ensure not in progress
			and (select count(1) from live.epic le where le.account_id = p_account_id and le.epic_id = se.epic_id and le.complete_time is null and le.fail_time is null) = 0
			-- ensure there are reps left
			and (select count(1) from live.epic le where le.account_id = p_account_id and le.epic_id = se.epic_id and le.complete_time is not null) < se.repeat_count) = 0
	then
		return false;
	end if;

	
	-- Ensure player has completed all the prereqs
	if (select min(completed) from (
		select se.required_epic_id seid, count(le.epic_id) completed
		from (
			with recursive req(target_epic_id, required_epic_id) as (
				select target_epic_id, required_epic_id 
					from static.epic_required_epics
					where target_epic_id = p_epic_id
				union all
				select r.target_epic_id, r.required_epic_id
			  		from static.epic_required_epics r, req l
			  		where r.target_epic_id = l.required_epic_id)
			select required_epic_id from req ) se
		left outer join live.epic le on le.epic_id=se.required_epic_id and le.complete_time is not null and le.account_id = p_account_id
		group by se.required_epic_id ) c ) = 0 
	then
		return false;
	end if;

	return true;
end; $$
language PLPGSQL security definer;
;