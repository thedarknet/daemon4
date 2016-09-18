--select static.upsert_epic('internal','internal desc','demetrius','mysite', 'd@d.com',1::boolean,1::boolean,1::boolean
--      ,current_timestamp::timestamp, current_timestamp::timestamp,1::smallint,'ALWAYS'::static.epic_visibility
--      ,'name'::text, 'p_start_text'::text, 'p_success_text'::text, 'p_fail'::text, 'p_desc'::text,'p_inprogressing'::text
--      ,'p_complete'::text,'p_long_desc'::text,1::integer,'en'::static.language,0::numeric)

create or replace function static.epic_upsert
  ( p_internal_name static.epic.internal_name%TYPE
  , p_internal_desc static.epic.internal_desc%TYPE
  , p_author static.epic.author%TYPE
  , p_author_site static.epic.author_site%TYPE
  , p_author_email static.epic.author_email%TYPE
  , p_author_public static.epic.author_public%TYPE
  , p_author_site_public static.epic.author_site_public%TYPE
  , p_author_email_public static.epic.author_email_public%TYPE
  , p_start_date static.epic.start_date%TYPE
  , p_end_date static.epic.end_date%TYPE
  , p_group_size static.epic.group_size%TYPE
  , p_visibility static.epic_visibility
  , p_name static.localized_text_detail.value%TYPE
  , p_start_text static.localized_text_detail.value%TYPE
  , p_success_text static.localized_text_detail.value%TYPE
  , p_fail_text static.localized_text_detail.value%TYPE
  , p_desc  static.localized_text_detail.value%TYPE
  , p_inprogress_desc static.localized_text_detail.value%TYPE
  , p_complete_desc static.localized_text_detail.value%TYPE
  , p_long_desc static.localized_text_detail.value%TYPE
  , p_repeat_count static.epic.repeat_count%TYPE
  , p_language static.language
  , p_flags static.epic.flags%TYPE
  , p_activation_regex static.epic.activation_regex%TYPE
  )
returns integer AS $$
declare 
  v_epic_id static.epic.epic_id%TYPE;
  v_name_id static.localized_text.text_id%TYPE;
  v_start_text_id static.localized_text.text_id%TYPE;
  v_success_text_id static.localized_text.text_id%TYPE;
  v_fail_text_id static.localized_text.text_id%TYPE;
  v_desc_id static.localized_text.text_id%TYPE;
  v_inprogress_desc_id static.localized_text.text_id%TYPE;
  v_complete_desc_id static.localized_text.text_id%TYPE;
  v_long_desc_id static.localized_text.text_id%TYPE;
begin
  select static.get_localized_text_id_or_insert(p_language,p_name) into v_name_id;
  select static.get_localized_text_id_or_insert(p_language,p_start_text) into v_start_text_id;
  select static.get_localized_text_id_or_insert(p_language,p_success_text) into v_success_text_id;
  select static.get_localized_text_id_or_insert(p_language,p_fail_text) into v_fail_text_id;
  select static.get_localized_text_id_or_insert(p_language,p_desc) into v_desc_id;
  select static.get_localized_text_id_or_insert(p_language,p_inprogress_desc) into v_inprogress_desc_id;
  select static.get_localized_text_id_or_insert(p_language,p_complete_desc) into v_complete_desc_id;
  select static.get_localized_text_id_or_insert(p_language,p_long_desc) into v_long_desc_id;

  insert into static.epic ( internal_name, internal_desc, author,
	author_site, author_email, author_public, author_site_public,
	author_email_public, start_date, end_date, group_size,
	name_id, start_text_id, success_text_id, fail_text_id,
	desc_id, inprogress_desc_id, complete_desc_id, long_desc_id,
	repeat_count, flags, visibility_enum, activation_regex)
	VALUES ( p_internal_name, p_internal_desc, p_author, p_author_site, p_author_email,
		p_author_public, p_author_site_public,p_author_email_public,p_start_date,p_end_date,
		p_group_size,v_name_id,v_start_text_id,v_success_text_id,v_fail_text_id,
		v_desc_id,v_inprogress_desc_id,v_complete_desc_id,v_long_desc_id,p_repeat_count,p_flags,p_visibility,p_activation_regex)
	ON CONFLICT (internal_name)
	DO UPDATE
	SET internal_desc = p_internal_desc
        , author = p_author
        , author_site = p_author_site
        , author_email = p_author_email
        , author_public = p_author_public
        , author_site_public = p_author_site_public
        , author_email_public = p_author_email_public
        , start_date = p_start_date
        , end_date = p_end_date
        , group_size = p_group_size
        , visibility_enum = p_visibility
        , name_id = v_name_id
        , start_text_id = v_start_text_id
        , success_text_id = v_success_text_id
        , fail_text_id = v_fail_text_id
        , desc_id = v_desc_id
        , inprogress_desc_id = v_inprogress_desc_id
        , complete_desc_id = v_complete_desc_id
        , long_desc_id = v_long_desc_id
        , repeat_count = p_repeat_count
        , flags = p_flags
        , activation_regex = p_activation_regex
      where static.epic.internal_name = p_internal_name
      returning epic_id into v_epic_id;
    
  return v_epic_id;
end; $$
language PLPGSQL security definer;
;

