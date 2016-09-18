
create or replace function static.quest_required_items_upsert
  ( p_quest_id	 			static.quest_required_items.quest_id%TYPE
  , p_item_id	 			static.quest_required_items.item_id%TYPE
  , p_must_have_count	static.quest_required_items.must_have_count%TYPE
  , p_num_to_take			static.quest_required_items.num_to_consume_on_activation%TYPE
  )
returns integer AS $$
declare 
	v_quest_id static.quest_required_items.quest_id%type;
begin
	INSERT INTO static.quest_required_items(
            quest_id, item_id, must_have_count, num_to_consume_on_activation)
    VALUES (p_quest_id, p_item_id, p_must_have_count, p_num_to_take)
	ON CONFLICT (quest_id, item_id)
	DO UPDATE
	SET must_have_count = p_must_have_count
		, num_to_consume_on_activation=p_num_to_take
	where static.quest_required_items.quest_id = p_quest_id
	AND static.quest_required_items.item_id = p_item_id
		returning quest_id into v_quest_id;
    
  return v_quest_id;
end; $$
language PLPGSQL security definer;
;

