create or replace function static.event_get(
	p_event_id static.event.event_id%TYPE
	, p_internal_name static.event.internal_name%TYPE
	, p_language static.language
	)
returns refcursor AS $$
declare
  v_ret refcursor;
begin
  open v_ret for
  SELECT event_id, internal_name, lt1.value "name", lt2.value "desc", 
		lower(time_range) start_time, upper(time_range) end_time
  FROM static.event a 
	INNER JOIN static.localized_text_detail lt1
		on (a.name_id = lt1.localized_text_id and lt1.language = p_language)
	INNER JOIN static.localized_text_detail lt2
		on (a.desc_id = lt2.desc_id and lt2.language = p_language)
  WHERE a.event_id = COALESCE(p_event_id, a.event_id)
	AND a.internal_name = COALESCE(p_internal_name, a.internal_name);
  return v_ret;
end;
$$
language PLPGSQL security definer;
;
