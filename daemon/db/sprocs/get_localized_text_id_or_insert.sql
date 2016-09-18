create or replace function static.get_localized_text_id_or_insert
  ( p_lang static.language
  , p_text_data static.localized_text_detail.value%TYPE
    ) 
returns numeric AS $$
declare 
  v_text_id static.localized_text.text_id%TYPE;
begin
	select localized_text_id into v_text_id
	from static.localized_text_detail
	where value = p_text_data;

	if v_text_id is null
	then
  		insert into static.localized_text (text_id) values (DEFAULT) 
			returning text_id into v_text_id;

		perform static.upsert_localized_text_detail(v_text_id, p_lang, p_text_data);	
	end if;

	return v_text_id;
end; $$
language PLPGSQL security definer;
;
