create or replace function static.event_upsert(
	p_internal_name static.event.internal_name%TYPE,
	p_name static.localized_text_detail.value%TYPE,
	p_desc static.localized_text_detail.value%TYPE,
	p_start_time timestamp,
	p_end_time timestamp,
	p_language static.language
	)
returns integer as $$
declare
	v_name_id static.localized_text.text_id%TYPE;
	v_desc_id static.localized_text.text_id%TYPE;
	v_event_id static.event.event_id%TYPE;
begin
	select static.get_localized_text_id_or_insert(p_language,p_name) into v_name_id;
	select static.get_localized_text_id_or_insert(p_language,p_desc) into v_desc_id;
	
	INSERT INTO static.event(
            event_id, internal_name, name_id, desc_id, time_range)
	VALUES (DEFAULT, p_internal_name, v_name_id, v_desc_id, tsrange(p_start_time, p_end_time, '[)'))
	ON CONFLICT (internal_name)
	DO UPDATE
	SET name_id = v_name_id
		, desc_id = v_desc_id
		, time_range =  tsrange(p_start_time, p_end_time, '[)')
	where static.event.internal_name = p_internal_name
	returning event_id into v_event_id;

	return v_event_id;
end;
$$
language PLPGSQL security definer;
;
