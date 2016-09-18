CREATE OR REPLACE FUNCTION live.inventory_transaction_create 
	( p_item_id live.inventory_transaction.item_id%type,
	p_bag_instance_id_source live.inventory_transaction.bag_instance_id_source%type,
  		p_action_type_id live.inventory_action_type,
  		p_source_system live.inventory_transaction.source_system%type,
  		p_bag_instance_id_target live.inventory_transaction.bag_instance_id_target%type,
  		p_comment text)
RETURNS numeric
AS
$$
declare
	v_inventory_transaction_seq_id live.inventory_transaction.inventory_transaction_seq_id%type;
BEGIN
INSERT INTO live.inventory_transaction(
            item_id, bag_instance_id_source, 
            action_type_id, source_system, bag_instance_id_target, comment)
    VALUES (p_item_id, p_bag_instance_id_source, p_action_type_id, p_source_system,
			p_bag_instance_id_target, p_comment)
		returning inventory_transaction_seq_id into v_inventory_transaction_seq_id;
	return v_inventory_transaction_seq_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
