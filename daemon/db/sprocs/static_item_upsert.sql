create or replace function static.item_upsert
  ( p_internal_name 	static.item.internal_name%TYPE
  , p_internal_desc 	static.item.internal_desc%TYPE
  , p_item_type 	static.item.item_type%TYPE
  , p_name 			static.localized_text_detail.value%TYPE
  , p_desc  		static.localized_text_detail.value%TYPE
  , p_max_count  	static.item.max_count%TYPE
  , p_meta_data   public.hstore
  , p_flags	 		static.item.flag%TYPE
  , p_language 	static.language
  )
returns integer AS $$
declare 
  v_name_id static.localized_text.text_id%TYPE;
  v_desc_id static.localized_text.text_id%TYPE;
  v_item_id static.item.item_id%TYPE;
begin
  select static.get_localized_text_id_or_insert(p_language,p_name) into v_name_id;
  select static.get_localized_text_id_or_insert(p_language,p_desc) into v_desc_id;

  INSERT INTO static.item(
            item_id, item_type, internal_name, internal_desc
				, name_id, description_id, 
            max_count, starting_metadata, flag
			)
    VALUES (DEFAULT, p_item_type, p_internal_name, p_internal_desc, v_name_id, v_desc_id, 
            p_max_count, p_meta_data, p_flags)
	ON CONFLICT (internal_name)
	DO UPDATE
	SET item_type=p_item_type  
		, internal_name=p_internal_name
		, internal_desc=p_internal_desc
		, name_id=v_name_id
		, description_id=v_desc_id
		, max_count=p_max_count
		, starting_metadata=p_meta_data
		, flag=p_flags
	where static.item.internal_name = p_internal_name
		returning item_id into v_item_id;
    
  return v_item_id;
end; $$
language PLPGSQL security definer;
;

