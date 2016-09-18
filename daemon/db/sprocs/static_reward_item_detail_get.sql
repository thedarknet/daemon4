create or replace function static.reward_item_detail_get
	(p_reward_id static.reward_item_details.reward_id%TYPE
	,p_item_id static.reward_item_details.item_id%TYPE
	,p_language static.localized_text_detail.language%TYPE
	)
returns refcursor AS $$
declare
  v_ret refcursor;
  begin
  open v_ret for
	SELECT r.reward_id, r.item_id, r.count, lt1.value as "name"
  	FROM static.reward_item_details r
  	JOIN static.item i ON i.item_id=r.item_id
	INNER JOIN static.localized_text_detail lt1
		on (i.name_id = lt1.localized_text_id and lt1.language = p_language)
	WHERE r.reward_id = COALESCE(p_reward_id, r.reward_id)
	AND r.item_id = COALESCE(p_item_id, r.item_id)
	order by 1 asc;

  return v_ret;
end; $$
language PLPGSQL security definer;
;


