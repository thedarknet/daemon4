create or replace function static.upsert_localized_text_detail 
  ( p_text_id static.localized_text.text_id%TYPE
  , p_lang_id static.language
  , p_text_data static.localized_text_detail.value%TYPE
    ) 
returns numeric AS $$
declare 
  
begin
	INSERT INTO static.localized_text_detail (localized_text_id, language, value)
		values (p_text_id, p_lang_id, p_text_data)
		ON CONFLICT (localized_text_id, language) 
		DO UPDATE SET language = p_lang_id, value = p_text_data
		WHERE static.localized_text_detail.localized_text_id = p_text_id;
		

	return p_text_id;
end; $$
language PLPGSQL security definer;
;
