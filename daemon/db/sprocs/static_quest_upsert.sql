
create or replace function static.quest_upsert
  ( p_internal_name	 	static.quest.internal_name%TYPE
  , p_name				 	static.localized_text_detail.value%TYPE
  , p_start_text 			static.localized_text_detail.value%TYPE
  , p_success_text 		static.localized_text_detail.value%TYPE
  , p_fail_text  			static.localized_text_detail.value%TYPE
  , p_summary_text		static.localized_text_detail.value%TYPE
  , p_reward_id					static.quest.reward_id%TYPE
  , p_language 	static.language
  )
returns integer AS $$
declare 
  v_name_id static.localized_text.text_id%TYPE;
  v_start_id static.quest.start_text_id%TYPE;
  v_success_id static.quest.success_text_id%TYPE;
  v_fail_id static.quest.fail_text_id%TYPE;
  v_summary_id static.quest.summary_text_id%TYPE;
  v_quest_id static.quest.quest_id%TYPE;
begin
  select static.get_localized_text_id_or_insert(p_language,p_name) into v_name_id;
  select static.get_localized_text_id_or_insert(p_language,p_start_text) into v_start_id;
  select static.get_localized_text_id_or_insert(p_language,p_success_text) into v_success_id;
  select static.get_localized_text_id_or_insert(p_language,p_fail_text) into v_fail_id;
  select static.get_localized_text_id_or_insert(p_language,p_summary_text) into v_summary_id;

	INSERT INTO static.quest(
            quest_id, internal_name, name_id, start_text_id, success_text_id, 
            fail_text_id, summary_text_id, reward_id)
    VALUES (DEFAULT, p_internal_name, v_name_id, v_start_id, v_success_id, v_fail_id, v_summary_id, p_reward_id)
	ON CONFLICT (internal_name)
	DO UPDATE
	SET name_id=v_name_id
		, start_text_id=v_start_id
		, success_text_id = v_success_id
		, fail_text_id = v_fail_id
		, summary_text_id = v_summary_id
		, reward_id=p_reward_id
	where static.quest.internal_name = p_internal_name
		returning quest_id into v_quest_id;
    
  return v_quest_id;
end; $$
language PLPGSQL security definer;
;

