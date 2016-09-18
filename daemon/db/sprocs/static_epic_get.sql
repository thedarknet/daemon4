create or replace function static.epic_get(p_epic_id static.epic.epic_id%TYPE, p_lang static.language)
returns refcursor AS $$
declare
  v_ret refcursor;
  begin
  --todo get all columns from epic
  open v_ret for
	SELECT epic_id, internal_name, internal_desc, author, author_site, author_email, 
		author_public, author_site_public, author_email_public, start_date, 
		end_date, group_size, lt1.value "name", lt2.value "start_text", lt3.value "success_text", 
		lt4.value "fail_text", lt5.value "desc", lt6.value"inprogress_desc_id", lt7.value "complete_desc_id", 
		lt8.value "long_desc_id", repeat_count, flags, visibility_enum, activation_regex
	FROM static.epic e 
	INNER join static.localized_text_detail lt1
		on (e.name_id = lt1.localized_text_id and lt1.language = p_lang)
	INNER JOIN static.localized_text_detail lt2
		on (e.start_text_id = lt2.localized_text_id and lt2.language = p_lang)
	INNER JOIN static.localized_text_detail lt3
		on (e.success_text_id = lt3.localized_text_id and lt3.language = p_lang)
	INNER JOIN static.localized_text_detail lt4
		on (e.fail_text_id = lt4.localized_text_id and lt4.language = p_lang)
	INNER JOIN static.localized_text_detail lt5
		on (e.desc_id = lt5.localized_text_id and lt5.language = p_lang)
	INNER JOIN static.localized_text_detail lt6
		on (e.inprogress_desc_id = lt6.localized_text_id and lt6.language = p_lang)
	INNER JOIN static.localized_text_detail lt7
		on (e.complete_desc_id = lt7.localized_text_id and lt7.language = p_lang)
	INNER JOIN static.localized_text_detail lt8
		on (e.long_desc_id = lt8.localized_text_id and lt8.language = p_lang)
	WHERE e.epic_id = COALESCE(p_epic_id, e.epic_id)
	order by 1 asc;

  return v_ret;
end; $$
language PLPGSQL security definer;
;


