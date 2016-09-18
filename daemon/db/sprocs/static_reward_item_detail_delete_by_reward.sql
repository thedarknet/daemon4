create or replace function static.reward_item_detail_delete_by_reward
  ( p_reward_id 	static.reward_item_details.reward_id%TYPE
  )
returns void AS $$
declare 
begin
	DELETE FROM  static.reward_item_details
	where reward_id = p_reward_id;
end; $$
language PLPGSQL security definer;
;

