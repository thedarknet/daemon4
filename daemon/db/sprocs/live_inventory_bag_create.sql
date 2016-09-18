-- allows you to create an inventory
CREATE OR REPLACE FUNCTION live.inventory_bag_create (p_inventory_id live.inventory_bags.inventory_id%type
	, p_bag_type live.inventory_bags.bag_type_id%type
	, p_event_id live.inventory_bags.event_id%type)
RETURNS void
AS
$$
declare
BEGIN
	insert into live.inventory_bags(bag_type_id,inventory_id,event_id)
	values (p_bag_type, p_inventory_id, p_event_id)
	on conflict do nothing;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
