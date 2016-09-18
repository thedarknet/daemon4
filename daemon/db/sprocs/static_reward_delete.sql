create or replace function static.reward_delete
  ( p_internal_name 	static.reward.internal_name%TYPE
  )
returns void AS $$
declare 
begin
	DELETE FROM  static.reward
	where internal_name = p_internal_name;
end; $$
language PLPGSQL security definer;
;

