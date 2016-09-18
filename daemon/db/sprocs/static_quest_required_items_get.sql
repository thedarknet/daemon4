create or replace function static.quest_required_item_get(p_quest_id static.quest_required_items.quest_id%TYPE)
returns refcursor AS $$
declare
  v_ret refcursor;
  begin
  open v_ret for
	SELECT quest_id, item_id, must_have_count, num_to_consume_on_activation
  	FROM static.quest_required_items q
	WHERE q.quest_id = COALESCE(p_quest_id, q.quest_id)
	order by 1 asc;

  return v_ret;
end; $$
language PLPGSQL security definer;
;


