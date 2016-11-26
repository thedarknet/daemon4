create or replace function live.grant_reward ( p_account_id live.account.account_id%TYPE, p_reward_id static.reward.reward_id%TYPE, p_metadata live.inventory_details.metadata%TYPE, p_lang live.account.language_id%TYPE )
returns 
	TABLE(object_type live.epic_object_type, action_type live.epic_action_type, action_text static.localized_text_detail.value%TYPE, action_count int)
AS $$
declare
	v_rec record;
	--TODO: THIS IS BROKEN currently we only put rewards into default bags...
	v_old_count live.inventory_details.count%TYPE;
	v_new_count live.inventory_details.count%TYPE;
begin
	for v_rec in select
				     r.item_id 
				   , r.count
				   , it.item_type
				   , static.get_localized_text(it.name_id, p_lang) item_name
				   , it.max_count
				   , b.bag_instance_id
				   , coalesce(id.count, 0) current_count
				 from static.reward_item_details r
				 inner join static.item it
				   on it.item_id = r.item_id
				 inner join live.inventory_bags b
				   on b.bag_type_id = it.item_type 
				     and (((it.flag::bigint & 1)=0 and b.event_id = 1) or ((it.flag::bigint & 1)=1 and b.event_id is null))
				 inner join live.inventory i
				   on b.inventory_id = i.inventory_id
				 left outer join live.inventory_details id
				   on id.bag_instance_id = b.bag_instance_id and id.item_id = it.item_id
				 where r.reward_id = p_reward_id
				 	and i.account_id = p_account_id

	loop
		insert into live.inventory_details (bag_instance_id, item_id, count, metadata)
			values (v_rec.bag_instance_id, v_rec.item_id, least(v_rec.count, v_rec.max_count), p_metadata)
		on conflict on constraint inventory_details_uqi
		do update
			set count = least(live.inventory_details.count+v_rec.count, v_rec.max_count)
		returning count into v_new_count;

		if v_new_count - v_rec.current_count > 0 then
			return query ( select 'ITEM'::live.epic_object_type, 'RECEIVE'::live.epic_action_type, v_rec.item_name, (v_new_count - v_rec.current_count)::int );
		end if;

	end loop; 
end; $$
language PLPGSQL security definer;
;
