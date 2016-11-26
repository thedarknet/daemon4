CREATE OR REPLACE FUNCTION live.account_get_remote_data (p_account_id live.inventory.account_id%type)
returns 
	TABLE(
		display_name live.account.display_name%TYPE
	  , lang_id live.account.language_id%TYPE
	  ,	bag_type_id live.inventory_bags.bag_type_id%TYPE
	  , internal_name static.item.internal_name%TYPE
	  , flags static.item.flag%TYPE
	  , count live.inventory_details.count%TYPE
	  , max_count static.item.max_count%TYPE
	  , metadata live.inventory_details.metadata%TYPE)

AS $$
declare
BEGIN
	return query (
		select 
		    a.display_name
		  , a.language_id
		  , b.bag_type_id
		  , si.internal_name
		  , flag
		  , id.count
		  , si.max_count
		  , id.metadata
		from live.get_current_events(p_account_id) ce,
		live.inventory_details id
		inner join static.item si
			on si.item_id = id.item_id
		inner join live.inventory_bags b
			on id.bag_instance_id = b.bag_instance_id
		inner join live.inventory i
			on i.inventory_id = b.inventory_id
		right outer join live.account a
			on a.account_id = i.account_id
		where a.account_id = p_account_id
			and (id.count > 0 or id.count is null)
			and (b.event_id is null or b.event_id = ce.id));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
