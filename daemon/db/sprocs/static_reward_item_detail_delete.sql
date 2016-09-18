create or replace function static.reward_item_detail_delete
  ( p_reward_id 	static.reward_item_details.reward_id%TYPE
  , p_item_id 		static.reward_item_details.item_id%TYPE
  )
returns void AS $$
declare 
begin
	DELETE FROM  static.reward_item_details
	where reward_id = p_reward_id
	AND item_id = p_item_id;
end; $$
language PLPGSQL security definer;
;

