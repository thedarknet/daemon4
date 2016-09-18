create or replace function live.upsert_account( p_external_provider_id live.account.external_provider_id%TYPE
                                              , p_remote_service_name live.account.remote_service_name%TYPE 
                                              , p_remote_service_account_name live.account.remote_service_account_name%TYPE
                                              , p_display_name live.account.display_name%TYPE
                                              , p_lang static.language)
returns live.account.account_id%TYPE AS $$
declare
    v_account_id live.account.account_id%TYPE;
    v_inventory_id live.inventory.inventory_id%TYPE;
    v_event_id static.event.event_id%TYPE;
    v_bag_type static.inventory_bag_type;
begin
	insert into live.account (create_time, language_id, external_provider_id, remote_service_name, remote_service_account_name, display_name, time_shift)
	values (now(), p_lang, p_external_provider_id, p_remote_service_name, p_remote_service_account_name, p_display_name, '0'::interval)
	on conflict (external_provider_id) do update
		set language_id = p_lang
		where live.account.external_provider_id = p_external_provider_id
	returning account_id into v_account_id;

	update live.account
		set display_name = p_display_name || 'player' || v_account_id
		where account_id = v_account_id and display_name = '';

	-- get current event id
	v_event_id = live.get_current_event(v_account_id);

	-- create inventory
	v_inventory_id = live.inventory_create(v_account_id);

	-- create generic and event bags
	for v_bag_type in (select unnest(enum_range(NULL::static.inventory_bag_type)))
	loop
		perform live.inventory_bag_create(v_inventory_id, v_bag_type, null);
		perform live.inventory_bag_create(v_inventory_id, v_bag_type, v_event_id);
	end loop;

	return v_account_id;
end; $$
language PLPGSQL security definer;
;

