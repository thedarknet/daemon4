create or replace function static.item_stack_count_get(p_item_id static.item.item_id%TYPE)
returns bigint AS $$
declare
	v_max_stack static.item.max_count%type;
  begin
	SELECT max_count
	INTO v_max_stack
  	FROM static.item 
	WHERE item_id = p_item_id;

  return v_max_stack;
end; $$
language PLPGSQL security definer;
;


