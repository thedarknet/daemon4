CREATE OR REPLACE FUNCTION live.inventory_add_item_to_bag 
	(p_bag_instance_id live.inventory_details.bag_instance_id%type
	, p_item_id numeric
	, p_number_to_add numeric)
RETURNS refcursor
AS
$$
declare
	v_max_stack_count numeric;
	v_cur refcursor;
	v_items_in_bag numeric;
	v_number_to_add numeric;
BEGIN
	select static.item_stack_count_get(p_item_id) into v_max_stack_count;

	select least(v_max_stack_count,p_number_to_add) into v_number_to_add;

	INSERT INTO live.inventory_details
		(bag_instance_id, item_id, count) 
	VALUES(p_bag_instance_id, p_item_id, v_number_to_add)
	ON CONFLICT (bag_instance_id, item_id)
	do update 
		set count = least(live.inventory_details.count+p_number_to_add, v_max_stack_count)
		where live.inventory_details.bag_instance_id = p_bag_instance_id
		and live.inventory_details.item_id = p_item_id;

	select count(1) into v_items_in_bag from live.inventory_details where bag_instance_id = p_bag_instance_id;

	if v_items_in_bag > 1000 then
		RAISE 'TOO MANY ITEMS IN THE BAG' USING ERRCODE='I000';	
	end if;

	open v_cur for 
	select bag_instance_id, item_id, count
	from live.inventory_details
	where bag_instance_id = p_bag_instance_id
 	and item_id = p_item_id;

	return v_cur;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
