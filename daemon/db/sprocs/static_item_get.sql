create or replace function static.item_get(p_item_id static.item.item_id%TYPE, p_lang static.language)
returns refcursor AS $$
declare
  v_ret refcursor;
  begin
  open v_ret for
	SELECT item_id, item_type, internal_name, internal_desc, lt1.value "name", lt2.value "description", 
       		max_count, starting_metadata, flag
  	FROM static.item i
	INNER join static.localized_text_detail lt1
		on (i.name_id = lt1.localized_text_id and lt1.language = p_lang)
	INNER JOIN static.localized_text_detail lt2
		on (i.description_id = lt2.localized_text_id and lt2.language = p_lang)
	WHERE i.item_id = COALESCE(p_item_id, i.item_id)
	order by 1 asc;

  return v_ret;
end; $$
language PLPGSQL security definer;
;


