create or replace function static.quest_get(p_quest_id static.quest.quest_id%TYPE, p_lang static.language)
returns refcursor AS $$
declare
  v_ret refcursor;
  begin
  open v_ret for
	SELECT quest_id, internal_name, lt1.value "name", lt2.value "start_text", lt3.value "success_text", 
       lt4.value "fail_text", lt5.value "summary_text", reward_id
  FROM static.quest q
	INNER join static.localized_text_detail lt1
		on (q.name_id = lt1.localized_text_id and lt1.language = p_lang)
	INNER join static.localized_text_detail lt2
		on (q.start_text_id = lt2.localized_text_id and lt2.language = p_lang)
	INNER join static.localized_text_detail lt3
		on (q.success_text_id = lt3.localized_text_id and lt3.language = p_lang)
	INNER join static.localized_text_detail lt4
		on (q.fail_text_id = lt4.localized_text_id and lt4.language = p_lang)
	INNER join static.localized_text_detail lt5
		on (q.summary_text_id = lt5.localized_text_id and lt5.language = p_lang)
	WHERE q.quest_id = COALESCE(p_quest_id, q.quest_id)
	order by 1 asc;

  return v_ret;
end; $$
language PLPGSQL security definer;
;


