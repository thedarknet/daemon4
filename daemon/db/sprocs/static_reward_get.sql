create or replace function static.reward_get(p_reward_id static.reward.reward_id%TYPE)
returns refcursor AS $$
declare
  v_ret refcursor;
  begin
  open v_ret for
	SELECT reward_id, internal_name
  	FROM static.reward r
	WHERE r.reward_id = COALESCE(p_reward_id, r.reward_id)
	order by 1 asc;

  return v_ret;
end; $$
language PLPGSQL security definer;
;


