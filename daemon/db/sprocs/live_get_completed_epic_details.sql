create or replace function live.get_completed_epic_details( p_account_id live.account.account_id%TYPE, p_live_epic_id live.epic.live_epic_id%TYPE )
returns 
	table( name static.localized_text_detail.value%TYPE
		 , summary static.localized_text_detail.value%TYPE
		 , description static.localized_text_detail.value%TYPE
		 , status text
		 , modality static.epic_quest_map_sequence.modality%TYPE
		 , complete_time live.epic.complete_time%TYPE
		 ) 
AS $$
declare
	v_lang static.language;
begin

	select language_id into v_lang
	from live.account
	where account_id = p_account_id;

	return query(
		select 
		    static.get_localized_text(sq.name_id, v_lang)
		  , static.get_localized_text(sq.summary_text_id, v_lang)
		  , case
		  		when q.complete_time is null and q.fail_time is null then static.get_localized_text(sq.start_text_id, v_lang)
		  		when q.complete_time is null and q.fail_time is not null then static.get_localized_text(sq.fail_text_id, v_lang)
				else static.get_localized_text(sq.success_text_id, v_lang)
			end description
		  , case
		  		when q.complete_time is null and q.fail_time is null then 'INCOMPLETE'
		  		when q.complete_time is null and q.fail_time is not null then 'FAIL'
				else 'SUCCESS'
			end status
		  , sqms.modality
		  , coalesce(e.complete_time, e.fail_time)
		from static.epic se
		inner join static.epic_quest_map_sequence sqms
			on sqms.epic_id = se.epic_id
		inner join static.quest sq
			on sq.quest_id = sqms.quest_id
		inner join live.epic e
		    on e.epic_id = se.epic_id
		inner join live.quest q
			on q.live_epic_id = e.live_epic_id
		where account_id = p_account_id
			and e.live_epic_id = p_live_epic_id
			and (e.complete_time is not null or e.fail_time is not null)
		order by sqms.logic_group_id, coalesce(e.complete_time, e.fail_time) asc
	);
end; $$
language PLPGSQL security definer;
;