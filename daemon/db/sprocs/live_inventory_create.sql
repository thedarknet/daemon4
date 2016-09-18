-- allows you to create an inventory
CREATE OR REPLACE FUNCTION live.inventory_create (p_account_id live.inventory.account_id%type)
RETURNS numeric
AS
$$
declare
v_inventory_id live.inventory.inventory_id%type;
BEGIN
  insert into live.inventory(account_id, inventory_id) values (p_account_id, DEFAULT)
  	on conflict (account_id)
  	do update 
  		 set inventory_id = live.inventory.inventory_id 
  		 where live.inventory.account_id = p_account_id
	returning live.inventory.inventory_id into v_inventory_id;

	return v_inventory_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
