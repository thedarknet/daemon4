-- allows you to remove an item from a bag
CREATE OR REPLACE FUNCTION live.inventory_remove_item_from_bag 
	(p_bag_instance_id live.inventory_details.bag_instance_id%type
	, p_item_id numeric
	, p_number_to_remove numeric)
RETURNS refcursor
AS
$$
declare
	v_cur refcursor;
	v_ret refcursor;
	v_rec record;
	v_number_left numeric :=p_number_to_remove;
BEGIN

	open v_cur for
	select count 
	from live.inventory_details a
	where a.bag_instance_id = p_bag_instance_id
	and a.item_id = p_item_id;

	LOOP
		fetch v_cur into v_rec;
		exit when not found;

		if v_number_left >= v_rec.count THEN
			delete from live.inventory_details 
			where bag_instance_id = p_bag_instance_id
			and item_id = p_item_id;
		ELSE
			update live.inventory_details
			set count = count-v_number_left
			where bag_instance_id = p_bag_instance_id
			and item_id = p_item_id;
		END IF;

		v_number_left:=v_number_left - v_rec.count;

	END LOOP;
	close v_cur;

	open v_ret for
	select bag_instance_id, item_id, count
	from live.inventory_details
	where bag_instance_id = p_bag_instance_id
	and item_id = p_item_id;

	return v_ret;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
