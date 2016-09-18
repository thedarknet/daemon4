CREATE OR REPLACE FUNCTION live.inventory_get (p_account_id live.inventory.account_id%type)
returns 
	TABLE(
		bag_type_id live.inventory_bags.bag_type_id%TYPE
	  , internal_name static.item.internal_name%TYPE
	  , name static.localized_text_detail.value%TYPE
	  , description static.localized_text_detail.value%TYPE
	  , flags static.item.flag%TYPE
	  , count live.inventory_details.count%TYPE
	  , max_count static.item.max_count%TYPE
	  , metadata live.inventory_details.metadata%TYPE)

AS $$
declare
	v_lang live.account.language_id%TYPE;
	v_cur_event static.event.event_id%TYPE = live.get_current_event(p_account_id);
BEGIN
	select language_id into v_lang
	from live.account
	where account_id = p_account_id;

	return query (
		select 
			b.bag_type_id
		  , si.internal_name
		  , static.get_localized_text(si.name_id, v_lang)
		  , static.get_localized_text(si.description_id, v_lang)
		  , flag
		  , id.count
		  , si.max_count
		  , id.metadata
		from live.inventory_details id
		inner join static.item si
			on si.item_id = id.item_id
		inner join live.inventory_bags b
			on id.bag_instance_id = b.bag_instance_id
		inner join live.inventory i
			on i.inventory_id = b.inventory_id
		where i.account_id = p_account_id
			and id.count > 0
			and (b.event_id is null or b.event_id = v_cur_event));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
