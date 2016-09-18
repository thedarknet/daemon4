create or replace function static.reward_upsert
  ( p_internal_name 	static.reward.internal_name%TYPE
  )
returns integer AS $$
declare 
	v_reward_id static.reward.reward_id%TYPE;
begin
	INSERT INTO static.reward( reward_id, internal_name)
    VALUES (DEFAULT, p_internal_name)
    ON CONFLICT DO NOTHING;

    SELECT reward_id INTO v_reward_id
    FROM static.reward
    WHERE internal_name = p_internal_name;
    
	RETURN v_reward_id;
end; $$
language PLPGSQL security definer;
;

