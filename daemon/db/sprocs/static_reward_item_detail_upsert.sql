create or replace function static.reward_item_detail_upsert
  ( p_reward_id  	static.reward_item_details.reward_id%TYPE
  , p_item_id	 	static.reward_item_details.item_id%TYPE	
  , p_count	 		static.reward_item_details.count%TYPE	
  )
returns integer AS $$
declare 
	v_reward_id numeric;
begin
	INSERT INTO static.reward_item_details (
            reward_id, item_id, count)
    VALUES (p_reward_id, p_item_id, p_count)
	ON CONFLICT(reward_id, item_id)
	DO UPDATE
	SET count = p_count
	WHERE static.reward_item_details.reward_id = p_reward_id
	AND static.reward_item_details.item_id = p_item_id
		returning reward_id into v_reward_id;
    
  return v_reward_id;
end; $$
language PLPGSQL security definer;
;
