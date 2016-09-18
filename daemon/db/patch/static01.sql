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

CREATE SCHEMA static;


ALTER SCHEMA static OWNER TO daemon_admin;

SET search_path = static, pg_catalog;

CREATE TYPE epic_visibility AS ENUM (
    'HIDDEN',
    'ALWAYS',
    'ELIGIBLE'
);

CREATE TYPE language AS ENUM (
    'en'
);


CREATE TYPE objective_type AS ENUM (
    'TEXT',
    'REMOTE',
    'KEY_FIXED',
    'KEY_DYNAMIC'
);


CREATE TYPE quest_modality AS ENUM (
    'MANDATORY',
    'OPTIONAL'
);

-- 
CREATE TYPE inventory_bag_type AS ENUM (
    'ITEM',
    'SKILL',
    'CURRENCY'
);


SET default_with_oids = false;

CREATE TABLE epic (
    epic_id numeric NOT NULL,
    internal_name character varying(63) NOT NULL,
    internal_desc character varying(1023) NOT NULL,
    author character varying(63) NOT NULL,
    author_site character varying(255),
    author_email character varying(255),
    author_public boolean NOT NULL,
    author_site_public boolean NOT NULL,
    author_email_public boolean NOT NULL,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    group_size smallint NOT NULL,
    name_id integer NOT NULL,
    start_text_id integer,
    success_text_id integer,
    fail_text_id integer,
    desc_id integer NOT NULL,
    inprogress_desc_id integer NOT NULL,
    complete_desc_id integer NOT NULL,
    long_desc_id integer NOT NULL,
    repeat_count integer NOT NULL,
    flags numeric,
    visibility_enum epic_visibility NOT NULL,
    activation_regex text,
    CONSTRAINT epic_c0 CHECK ((group_size > 0)),
    CONSTRAINT epic_c1 CHECK ((repeat_count > 0))
);

COMMENT ON TABLE epic IS 'For an epic to be activated:
	All required epics must be competed (epic_required_epics ) and the first quest is activatable.';

alter table static.epic add CONSTRAINT epic_internal_name_unq UNIQUE (internal_name);

COMMENT ON COLUMN epic.flags IS 'flag (1<<0) = Is event scope - if no then when we instance epic no not add event id';

CREATE SEQUENCE epic_epic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE epic_epic_id_seq OWNED BY epic.epic_id;

CREATE SEQUENCE epic_quest_map_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE epic_quest_map_sequence (
    epic_quest_map_seq numeric DEFAULT nextval('epic_quest_map_seq'::regclass) NOT NULL,
    display_id numeric NOT NULL,
    logic_group_id numeric NOT NULL,
    epic_id numeric NOT NULL,
    quest_id numeric NOT NULL,
    success_epic_id numeric,
    failed_epic_id numeric,
    flag numeric DEFAULT 0 NOT NULL,
    modality quest_modality NOT NULL
);


ALTER TABLE static.epic_quest_map_sequence
  ADD CONSTRAINT epic_quest_map_seq_unq UNIQUE (epic_id, quest_id, logic_group_id, display_id);

--
--

COMMENT ON TABLE epic_quest_map_sequence IS 'mapping of quests to epics.
logic groups are used to group quests together, see column comment';


--
--

COMMENT ON COLUMN epic_quest_map_sequence.display_id IS 'the order to display the quests in the quest tree';


--
--

COMMENT ON COLUMN epic_quest_map_sequence.logic_group_id IS 'if two quests are in the same logic group then:
  if the modality is:
     both are mandatory then both must be completed before the logic group is completed allowing the epic to move on to the next logic group
    both are optional then as soon as 1 is complete the logic group completes
    if one is optional and 1 is mandatory:  once the mandatory one is complete then the logic group is considered complete.  If the optional is not completed before the mandatory then the user does not get a chance to complete it.';


--
--

COMMENT ON COLUMN epic_quest_map_sequence.success_epic_id IS 'epic_id to attempt to activate if this quest is completed successfully';


--
--

COMMENT ON COLUMN epic_quest_map_sequence.flag IS 'Flags - 
	(1<<0) completing quest completes epic';


--
--

CREATE TABLE epic_required_epics (
    target_epic_id numeric NOT NULL,
    required_epic_id numeric NOT NULL
);



--
--

COMMENT ON TABLE epic_required_epics IS ' epics that must be done before the target epic can be started';


--
--

CREATE TABLE event (
    event_id integer NOT NULL,
    internal_name character varying(63) NOT NULL,
    name_id integer NOT NULL,
    desc_id integer NOT NULL,
    time_range tsrange NOT NULL,
    CONSTRAINT event_g0 EXCLUDE USING gist (time_range WITH &&)
);



--
--

CREATE TABLE event_epic (
    event_id integer NOT NULL,
    epic_id integer NOT NULL
);



--
--

CREATE SEQUENCE event_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
--

ALTER SEQUENCE event_event_id_seq OWNED BY event.event_id;


--
--

CREATE TABLE item (
    item_id numeric NOT NULL,
    item_type inventory_bag_type NOT NULL,
    internal_name character varying(63) NOT NULL,
    internal_desc text,
    name_id bigint NOT NULL,
    description_id bigint,
    max_count bigint,
    starting_metadata public.hstore,
    flag numeric DEFAULT 0 NOT NULL,
    CONSTRAINT item_c0 CHECK (((max_count IS NULL) OR (max_count > 0)))
);



--
--

COMMENT ON COLUMN item.flag IS 'Add flag
		(1<<0) Is event Scope:   if no then when we instance item no not add event id';


--
--

CREATE SEQUENCE item_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
--

ALTER SEQUENCE item_item_id_seq OWNED BY item.item_id;


--
--

CREATE TABLE localized_text (
    text_id bigint NOT NULL
);



--
--

CREATE TABLE localized_text_detail (
    localized_text_id bigint NOT NULL,
    language language NOT NULL,
    value text NOT NULL
);



--
--

CREATE SEQUENCE localized_text_text_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
--

ALTER SEQUENCE localized_text_text_id_seq OWNED BY localized_text.text_id;


--
--

CREATE TABLE objective (
    objective_id integer NOT NULL,
    quest_id integer NOT NULL,
    obj_index integer NOT NULL,
    desc_id integer NOT NULL,
    count integer NOT NULL,
    activation_regex text,
    fail_activation_regex text,
    reward_id integer,
    objective_type_enum objective_type NOT NULL,
    remote_endpoint text,
    CONSTRAINT objective_c0 CHECK ((count > 0)),
    CONSTRAINT objective_c1 CHECK ((obj_index >= 0))
);



--
--

CREATE SEQUENCE objective_objective_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
--

ALTER SEQUENCE objective_objective_id_seq OWNED BY objective.objective_id;


--
--

CREATE TABLE quest (
    quest_id numeric NOT NULL,
    internal_name character varying(63) NOT NULL,
    name_id integer NOT NULL,
    start_text_id integer,
    success_text_id integer,
    fail_text_id integer,
    summary_text_id integer,
    reward_id integer
);



--
--

CREATE SEQUENCE quest_quest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
--

ALTER SEQUENCE quest_quest_id_seq OWNED BY quest.quest_id;


--
--

CREATE TABLE quest_required_items (
    quest_id numeric NOT NULL,
    item_id numeric NOT NULL,
    must_have_count numeric NOT NULL,
    num_to_consume_on_activation numeric DEFAULT 0 NOT NULL
);



--
--

COMMENT ON COLUMN quest_required_items.must_have_count IS 'count of the item you have to have in your inventory';


--
--

COMMENT ON COLUMN quest_required_items.num_to_consume_on_activation IS 'number of items to consume on quest activation';


--
--

--
--

CREATE TABLE reward (
    reward_id integer NOT NULL,
    internal_name character varying(63) NOT NULL
);



--
--

CREATE TABLE reward_item_details (
    reward_id integer NOT NULL,
    item_id integer NOT NULL,
    count integer NOT NULL,
    CONSTRAINT reward_item_details_c0 CHECK ((count > 0))
);



--
--

CREATE SEQUENCE reward_reward_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
--

ALTER SEQUENCE reward_reward_id_seq OWNED BY reward.reward_id;


--
--

ALTER TABLE ONLY epic ALTER COLUMN epic_id SET DEFAULT nextval('epic_epic_id_seq'::regclass);


--
--

ALTER TABLE ONLY event ALTER COLUMN event_id SET DEFAULT nextval('event_event_id_seq'::regclass);


--
--

ALTER TABLE ONLY item ALTER COLUMN item_id SET DEFAULT nextval('item_item_id_seq'::regclass);


--
--

ALTER TABLE ONLY localized_text ALTER COLUMN text_id SET DEFAULT nextval('localized_text_text_id_seq'::regclass);


--
--

ALTER TABLE ONLY objective ALTER COLUMN objective_id SET DEFAULT nextval('objective_objective_id_seq'::regclass);


--
--

ALTER TABLE ONLY quest ALTER COLUMN quest_id SET DEFAULT nextval('quest_quest_id_seq'::regclass);


--
--

ALTER TABLE ONLY reward ALTER COLUMN reward_id SET DEFAULT nextval('reward_reward_id_seq'::regclass);



ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_pk PRIMARY KEY (epic_id);


--
--

ALTER TABLE ONLY epic_quest_map_sequence
    ADD CONSTRAINT epic_quest_map_pk PRIMARY KEY (epic_quest_map_seq);


--
--

ALTER TABLE ONLY epic_required_epics
    ADD CONSTRAINT epic_required_epics_pk PRIMARY KEY (target_epic_id, required_epic_id);


--
--

ALTER TABLE ONLY event_epic
    ADD CONSTRAINT event_epic_pk PRIMARY KEY (event_id, epic_id);


--
--

ALTER TABLE ONLY event
    ADD CONSTRAINT event_pk PRIMARY KEY (event_id);


--
--

ALTER TABLE ONLY event
    ADD CONSTRAINT event_u0 UNIQUE (internal_name);


--
--

ALTER TABLE ONLY item
    ADD CONSTRAINT item_pk PRIMARY KEY (item_id);


--
--

ALTER TABLE ONLY item
    ADD CONSTRAINT item_u0 UNIQUE (internal_name);


--
--

ALTER TABLE ONLY localized_text_detail
    ADD CONSTRAINT localized_text_detail_pk PRIMARY KEY (localized_text_id, language);


--
--

ALTER TABLE ONLY localized_text
    ADD CONSTRAINT localized_text_pk PRIMARY KEY (text_id);


--
--

ALTER TABLE ONLY objective
    ADD CONSTRAINT objective_pk PRIMARY KEY (objective_id);


--
--

ALTER TABLE ONLY objective
    ADD CONSTRAINT objective_u0 UNIQUE (quest_id, obj_index);


--
--

ALTER TABLE ONLY quest
    ADD CONSTRAINT quest_pk PRIMARY KEY (quest_id);


ALTER TABLE static.quest
  ADD CONSTRAINT quest_internal_name_unq UNIQUE (internal_name);
--
--

ALTER TABLE ONLY quest_required_items
    ADD CONSTRAINT quest_required_items_pk PRIMARY KEY (quest_id, item_id);


--
--

ALTER TABLE ONLY reward_item_details
    ADD CONSTRAINT reward_item_details_pk PRIMARY KEY (reward_id, item_id);


--
--

ALTER TABLE ONLY reward
    ADD CONSTRAINT reward_pk PRIMARY KEY (reward_id);


--
--

ALTER TABLE ONLY reward
    ADD CONSTRAINT reward_u0 UNIQUE (internal_name);


--
--

ALTER TABLE ONLY epic_quest_map_sequence
    ADD CONSTRAINT epic_epic_fail_id_fk FOREIGN KEY (failed_epic_id) REFERENCES epic(epic_id);


--
--

ALTER TABLE ONLY epic_quest_map_sequence
    ADD CONSTRAINT epic_id_epic_success_id_fk FOREIGN KEY (success_epic_id) REFERENCES epic(epic_id);


--
--

ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_r1 FOREIGN KEY (name_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_r2 FOREIGN KEY (start_text_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_r3 FOREIGN KEY (success_text_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_r4 FOREIGN KEY (fail_text_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_r5 FOREIGN KEY (desc_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_r6 FOREIGN KEY (inprogress_desc_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_r7 FOREIGN KEY (complete_desc_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY epic
    ADD CONSTRAINT epic_r8 FOREIGN KEY (long_desc_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY epic_required_epics
    ADD CONSTRAINT epic_required_epic_fk FOREIGN KEY (required_epic_id) REFERENCES epic(epic_id);


--
--

ALTER TABLE ONLY epic_required_epics
    ADD CONSTRAINT epic_target_epic FOREIGN KEY (target_epic_id) REFERENCES epic(epic_id);


--
--

ALTER TABLE ONLY epic_quest_map_sequence
    ADD CONSTRAINT epic_to_epic_id_map_fk1 FOREIGN KEY (epic_id) REFERENCES epic(epic_id);


--
--

ALTER TABLE ONLY event_epic
    ADD CONSTRAINT event_epic_r0 FOREIGN KEY (event_id) REFERENCES event(event_id);


--
--

ALTER TABLE ONLY event_epic
    ADD CONSTRAINT event_epic_r1 FOREIGN KEY (epic_id) REFERENCES epic(epic_id);


--
--

ALTER TABLE ONLY event
    ADD CONSTRAINT event_r0 FOREIGN KEY (name_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY event
    ADD CONSTRAINT event_r1 FOREIGN KEY (desc_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY item
    ADD CONSTRAINT item_fk0 FOREIGN KEY (name_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY item
    ADD CONSTRAINT item_fk1 FOREIGN KEY (description_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY localized_text_detail
    ADD CONSTRAINT localized_text_detail_fk FOREIGN KEY (localized_text_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY objective
    ADD CONSTRAINT objective_r0 FOREIGN KEY (quest_id) REFERENCES quest(quest_id);


--
--

ALTER TABLE ONLY objective
    ADD CONSTRAINT objective_r2 FOREIGN KEY (desc_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY objective
    ADD CONSTRAINT objective_r3 FOREIGN KEY (reward_id) REFERENCES reward(reward_id);


--
--

ALTER TABLE ONLY epic_quest_map_sequence
    ADD CONSTRAINT quest_epic_quest_map_fk FOREIGN KEY (quest_id) REFERENCES quest(quest_id);


--
--

ALTER TABLE ONLY quest
    ADD CONSTRAINT quest_r1 FOREIGN KEY (name_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY quest
    ADD CONSTRAINT quest_r3 FOREIGN KEY (success_text_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY quest
    ADD CONSTRAINT quest_r4 FOREIGN KEY (fail_text_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY quest
    ADD CONSTRAINT quest_r5 FOREIGN KEY (summary_text_id) REFERENCES localized_text(text_id);


--
--

ALTER TABLE ONLY quest
    ADD CONSTRAINT quest_r6 FOREIGN KEY (reward_id) REFERENCES reward(reward_id);


--
--

ALTER TABLE ONLY reward_item_details
    ADD CONSTRAINT reward_item_details_r0 FOREIGN KEY (reward_id) REFERENCES reward(reward_id);


--
--

ALTER TABLE ONLY reward_item_details
    ADD CONSTRAINT reward_item_details_r1 FOREIGN KEY (item_id) REFERENCES item(item_id);

