do $$declare
	v_reward_id numeric;
begin
	SELECT static.reward_insert('test4') into v_reward_id;
	raise notice 'reward_id %',v_reward_id;
	perform static.reward_delete('test4');
	SELECT static.reward_insert('test4') into v_reward_id;
	raise notice 'reward_id %',v_reward_id;
end$$;

