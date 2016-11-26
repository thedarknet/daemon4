CREATE TABLE static.event_entitlement_map (
		    event_id numeric(38,0) NOT NULL,
		    entitlement_enum live.entitlement_type NOT NULL,
		    CONSTRAINT event_entitlement_map_pk PRIMARY KEY (event_id, entitlement_enum)
)
WITH ( OIDS=FALSE);

