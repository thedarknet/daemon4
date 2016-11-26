do $$declare
	v_t1 numeric;
	v_t2 numeric;
	v_account_id bigint;
	v_account_id_op bigint;
	v_event1 bigint;
	v_event2 bigint;
	v_epic1 bigint;
	v_epic2 bigint;
begin
	select static.get_localized_text_id_or_insert('en'::static.language,'dc25') into v_t1;
	select static.get_localized_text_id_or_insert('en'::static.language,'dc25darknet') into v_t2;
	
	INSERT INTO static.event(
            event_id, internal_name, name_id, desc_id, time_range)
	VALUES (DEFAULT, 'dc25', v_t1, v_t2, tsrange('2016-11-01'::timestamp, '2017-11-01'::timestamp, '[)'))
	returning event_id into v_event1;

	select static.get_localized_text_id_or_insert('en'::static.language,'dc25-operatives') into v_t1;
	select static.get_localized_text_id_or_insert('en'::static.language,'dc25-operatives darknet') into v_t2;

	INSERT INTO static.event(
            event_id, internal_name, name_id, desc_id, time_range)
	VALUES (DEFAULT, 'dc25-operatives', v_t1, v_t2, tsrange('2016-11-01'::timestamp, '2017-11-01'::timestamp, '[)'))
	returning event_id into v_event2;

	--need stored proc for this?
	INSERT INTO static.event_entitlement_map(event_id, entitlement_enum)
	VALUES (v_event1, 'LOGIN'::live.entitlement_type);
	INSERT INTO static.event_entitlement_map(event_id, entitlement_enum)
	VALUES (v_event2, 'OPERATIVE'::live.entitlement_type);

	SELECT live.upsert_account('1234','test','dcomes','cmdc0de','en') into v_account_id;

	perform live.account_entitlement_create(v_account_id, 'LOGIN'::live.entitlement_type);

	SELECT live.upsert_account('4321','test','dcomes_op','cmdc0de_op','en') into v_account_id_op;
	perform live.account_entitlement_create(v_account_id_op, 'LOGIN'::live.entitlement_type);
	perform live.account_entitlement_create(v_account_id_op, 'OPERATIVE'::live.entitlement_type);

	SELECT static.epic_upsert(
		'LoginEpic'::character varying, 'LoginEpic'::character varying, 'cmd'::character varying,
		'site'::character varying, 'email'::character varying, true, true, true,
		now()::timestamp without time zone, '2018-01-01'::timestamp without time zone, 1::smallint,
		'ALWAYS'::static.epic_visibility, 'name'::text, 'start text'::text,
		'success'::text, 'fail'::text, 'desc'::text, 'in progress'::text,
		'complete'::text, 'long'::text,1, 'en'::static.language, 0, 'start'
		) into v_epic1;

	SELECT static.epic_upsert(
		'OperativeEpic'::character varying, 'OperativeEpic'::character varying, 'cmd'::character varying,
		'site'::character varying, 'email'::character varying, true, true, true,
		now()::timestamp without time zone, '2018-01-01'::timestamp without time zone, 1::smallint,
		'ALWAYS'::static.epic_visibility, 'name'::text, 'start text'::text,
		'success'::text, 'fail'::text, 'desc'::text, 'in progress'::text,
		'complete'::text, 'long'::text,1, 'en'::static.language, 0, 'start'
		) into v_epic2;

	INSERT INTO static.event_epic(event_id, epic_id)
	VALUES (v_event1, v_epic1);

	INSERT INTO static.event_epic(event_id, epic_id)
	VALUES (v_event2, v_epic2);

end $$;

--1 row should come back for account id #1
--select * from live.get_available_epics(1);
--2 rows should come back for account id #2
--select * from live.get_available_epics(2);
