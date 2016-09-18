--
-- PostgreSQL database dump
--


SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
--
CREATE SCHEMA live;
 
--
--
SET search_path = live, pg_catalog;

--
--

CREATE TYPE entitlement_type AS ENUM (
    'LOGIN',
    'EDITOR',
    'ADMIN'
);


--

CREATE TYPE inventory_action_type AS ENUM (
    'ADD',
    'REMOVE'
);

--

CREATE TYPE epic_object_type AS ENUM (
    'EPIC',
    'QUEST',
    'OBJECTIVE',
    'ITEM'
);

-- 
CREATE TYPE epic_action_type AS ENUM (
    'START',
    'SUCCESS',
    'FAIL',
    'RECEIVE',
    'USE'
);

--

CREATE TABLE account (
    account_id bigint NOT NULL,
    external_provider_id character varying(255) NOT NULL,
    language_id static.language NOT NULL,
    create_time timestamp without time zone NOT NULL,
    time_shift interval NOT NULL,
    remote_service_name character varying(255) NOT NULL,
    remote_service_account_name character varying(255) NOT NULL,
    display_name character varying(30) NOT NULL 
);


COMMENT ON COLUMN account.remote_service_name IS 'facebook, twitter, google play';


--

CREATE SEQUENCE account_account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE account_account_id_seq OWNED BY account.account_id;


CREATE TABLE account_entitlement (
    account_id numeric NOT NULL,
    entitlement_enum entitlement_type NOT NULL,
    create_datetime time without time zone DEFAULT now() NOT NULL
);



CREATE TABLE epic (
    live_epic_id numeric NOT NULL,
    account_id bigint NOT NULL,
    epic_id integer NOT NULL,
    start_time timestamp without time zone NOT NULL,
    complete_time timestamp without time zone,
    fail_time timestamp without time zone,
    event_id integer,
    CONSTRAINT epic_c0 CHECK ((((complete_time IS NULL) AND (fail_time IS NULL)) OR ((complete_time IS NULL) AND (fail_time IS NOT NULL)) OR ((complete_time IS NOT NULL) AND (fail_time IS NULL))))
);



CREATE SEQUENCE epic_live_epic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE epic_live_epic_id_seq OWNED BY epic.live_epic_id;

create type event_type as enum ('epic_granted', 'epic_completed', 'quest_started', 'quest_failed', 'quested_completed');

CREATE TABLE event_queue (
    event_id bigint NOT NULL,
    account_id integer NOT NULL,
    event_type_id event_type NOT NULL,
    time_inserted timestamp without time zone NOT NULL,
    time_processed timestamp without time zone,
    time_delivered timestamp without time zone
);



CREATE SEQUENCE event_queue_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE event_queue_event_id_seq OWNED BY event_queue.event_id;


CREATE TABLE event_values (
    value_id bigint NOT NULL,
    event_id bigint NOT NULL,
    int_value integer,
    str_value character varying(4096)
);


CREATE SEQUENCE event_values_value_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE event_values_value_id_seq OWNED BY event_values.value_id;


CREATE SEQUENCE inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE bag_instance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;




--each player only get's 1 inventory, bags are by event
CREATE TABLE inventory (
    account_id bigint NOT NULL,
    inventory_id numeric DEFAULT nextval('inventory_id_seq'::regclass) NOT NULL
);


CREATE TABLE inventory_bags (
	bag_instance_id   numeric DEFAULT nextval('bag_instance_id_seq'::regclass) NOT NULL,
	bag_type_id		  static.inventory_bag_type NOT NULL,
	inventory_id      numeric NOT NULL,
	event_id		  integer
);


CREATE TABLE inventory_details (
    bag_instance_id numeric NOT NULL,
    item_id numeric NOT NULL,
    count numeric,
    metadata public.hstore
);


CREATE SEQUENCE inventory_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE TABLE inventory_transaction (
    inventory_transaction_seq_id numeric DEFAULT nextval('inventory_transaction_id_seq'::regclass) NOT NULL,
    item_id 							numeric NOT NULL,
	 bag_instance_id_source 		numeric NOT NULL,
    action_type_id 					inventory_action_type NOT NULL,
    source_system 					text NOT NULL,
	 bag_instance_id_target			numeric,
    comment text
);


CREATE TABLE keys (
    objective_id integer NOT NULL,
    key character varying(63) NOT NULL,
    claimed_epic_id integer
);


CREATE SEQUENCE objective_instance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE quest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



CREATE TABLE objective (
    live_objective_id numeric DEFAULT nextval('objective_instance_id_seq'::regclass) NOT NULL,
    live_quest_id bigint NOT NULL,
    objective_id integer NOT NULL,
    current_count integer NOT NULL,
    start_time timestamp without time zone NOT NULL,
    complete_time timestamp without time zone,
    fail_time timestamp without time zone,
    CONSTRAINT objective_c0 CHECK ((current_count >= 0)),
    CONSTRAINT objective_c1 CHECK ((((complete_time IS NULL) AND (fail_time IS NULL)) OR ((complete_time IS NULL) AND (fail_time IS NOT NULL)) OR ((complete_time IS NOT NULL) AND (fail_time IS NULL))))
);


CREATE TABLE quest (
    live_quest_id numeric DEFAULT nextval('quest_id_seq'::regclass) NOT NULL,
    live_epic_id bigint NOT NULL,
    logic_group_id bigint NOT NULL,
    quest_id integer NOT NULL,
    start_time timestamp without time zone NOT NULL,
    complete_time timestamp without time zone,
    fail_time timestamp without time zone,
    CONSTRAINT quest_c0 CHECK ((((complete_time IS NULL) AND (fail_time IS NULL)) OR ((complete_time IS NULL) AND (fail_time IS NOT NULL)) OR ((complete_time IS NOT NULL) AND (fail_time IS NULL))))
);


ALTER TABLE ONLY account ALTER COLUMN account_id SET DEFAULT nextval('account_account_id_seq'::regclass);


ALTER TABLE ONLY epic ALTER COLUMN live_epic_id SET DEFAULT nextval('epic_live_epic_id_seq'::regclass);


ALTER TABLE ONLY event_queue ALTER COLUMN event_id SET DEFAULT nextval('event_queue_event_id_seq'::regclass);


ALTER TABLE ONLY event_values ALTER COLUMN value_id SET DEFAULT nextval('event_values_value_id_seq'::regclass);


ALTER TABLE ONLY account
    ADD CONSTRAINT account_pk PRIMARY KEY (account_id);

ALTER TABLE ONLY account
    ADD CONSTRAINT account_u0 UNIQUE (external_provider_id);


ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_pk PRIMARY KEY (live_epic_id);


ALTER TABLE ONLY event_queue
    ADD CONSTRAINT event_queue_pk PRIMARY KEY (event_id);


ALTER TABLE ONLY event_values
    ADD CONSTRAINT event_values_pk PRIMARY KEY (value_id);


ALTER TABLE ONLY inventory_details
    ADD CONSTRAINT inventory_details_uqi UNIQUE (bag_instance_id, item_id);

ALTER TABLE ONLY inventory_bags
    ADD CONSTRAINT inventory_details_pk PRIMARY KEY (bag_instance_id);

CREATE UNIQUE INDEX inventory_bags_u0 
    ON inventory_bags (inventory_id, bag_type_id, coalesce(event_id, 0));


CREATE INDEX inventory_bags_inv
   ON inventory_bags (inventory_id ASC NULLS LAST);

ALTER TABLE ONLY inventory
    ADD CONSTRAINT inventory_id_unq UNIQUE (inventory_id);

--only 1 inventory per account
ALTER TABLE ONLY inventory
    ADD CONSTRAINT inventory_pk PRIMARY KEY (account_id);


ALTER TABLE ONLY inventory_transaction
    ADD CONSTRAINT inventory_transaction_pk PRIMARY KEY (inventory_transaction_seq_id);


ALTER TABLE ONLY keys
    ADD CONSTRAINT keys_pk PRIMARY KEY (objective_id, key);


ALTER TABLE ONLY account_entitlement
    ADD CONSTRAINT live_entitlement_pk PRIMARY KEY (account_id, entitlement_enum);


ALTER TABLE ONLY objective
    ADD CONSTRAINT objective_pk PRIMARY KEY (live_objective_id);


ALTER TABLE ONLY quest
    ADD CONSTRAINT quest_pk PRIMARY KEY (live_quest_id);


ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_r0 FOREIGN KEY (account_id) REFERENCES account(account_id);


ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_r1 FOREIGN KEY (epic_id) REFERENCES static.epic(epic_id);


ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_r2 FOREIGN KEY (event_id) REFERENCES static.event(event_id);


ALTER TABLE ONLY event_queue
    ADD CONSTRAINT event_queue_r0 FOREIGN KEY (account_id) REFERENCES account(account_id);


ALTER TABLE ONLY event_values
    ADD CONSTRAINT event_values_r0 FOREIGN KEY (event_id) REFERENCES event_queue(event_id);


ALTER TABLE ONLY inventory_details
    ADD CONSTRAINT inventory_bags_details_fk FOREIGN KEY (bag_instance_id) REFERENCES inventory_bags(bag_instance_id);


ALTER TABLE ONLY inventory
    ADD CONSTRAINT inventory_r0 FOREIGN KEY (account_id) REFERENCES account(account_id);

ALTER TABLE ONLY inventory_bags
    ADD CONSTRAINT inventory_bags_fk FOREIGN KEY (event_id) REFERENCES static.event(event_id);


ALTER TABLE ONLY inventory_details
    ADD CONSTRAINT item_inventory_detail_fk FOREIGN KEY (item_id) REFERENCES static.item(item_id);


ALTER TABLE ONLY keys
    ADD CONSTRAINT keys_fk0 FOREIGN KEY (objective_id) REFERENCES static.objective(objective_id);


ALTER TABLE ONLY keys
    ADD CONSTRAINT keys_fk1 FOREIGN KEY (claimed_epic_id) REFERENCES epic(live_epic_id);


ALTER TABLE ONLY objective
    ADD CONSTRAINT objective_r1 FOREIGN KEY (objective_id) REFERENCES static.objective(objective_id);


ALTER TABLE ONLY objective
    ADD CONSTRAINT quest_objective_fk FOREIGN KEY (live_quest_id) REFERENCES quest(live_quest_id);
--

ALTER TABLE ONLY quest
    ADD CONSTRAINT quest_r0 FOREIGN KEY (live_epic_id) REFERENCES epic(live_epic_id);


ALTER TABLE ONLY quest
    ADD CONSTRAINT quest_r1 FOREIGN KEY (quest_id) REFERENCES static.quest(quest_id);
--

