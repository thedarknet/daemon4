create or replace function static.get_localized_text
  ( p_text_id static.localized_text_detail.localized_text_id%TYPE
  ,	p_lang static.language) 
returns static.localized_text_detail.value%TYPE AS $$
declare 
  v_text static.localized_text_detail.value%TYPE;
begin
	select value into v_text
	from static.localized_text_detail
	where localized_text_id = p_text_id
	  and language = p_lang;

	if v_text is null
	then
		v_text = '(UNKNOWN)';
	end if;

	return v_text;
end; $$
language PLPGSQL security definer;
;
