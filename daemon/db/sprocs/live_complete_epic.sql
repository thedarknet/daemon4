create or replace function live.complete_epic ( p_live_epic_id live.epic.live_epic_id%TYPE, p_lang live.account.language_id%TYPE )
returns 
	TABLE(object_type live.epic_object_type, action_type live.epic_action_type, action_text static.localized_text_detail.value%TYPE, action_count int)
AS $$
declare
	v_epic_id static.epic.epic_id%TYPE;
begin
	update live.epic
	set complete_time = now()
	where live_epic_id = p_live_epic_id
		and complete_time is null
		and fail_time is null
	returning epic_id into v_epic_id;

	if v_epic_id is not null then
		return query (
		select
		    'EPIC'::live.epic_object_type
		  , 'SUCCESS'::live.epic_action_type
		  , static.get_localized_text(success_text_id, p_lang) 
		  , 1
		  from static.epic
		  where epic_id = v_epic_id);
	end if;
	
end; $$
language PLPGSQL security definer;
;
