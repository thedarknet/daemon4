CREATE TABLE static.event_entitlement_map (
		    event_id numeric(38,0) NOT NULL,
		    entitlement_enum live.entitlement_type NOT NULL,
		    CONSTRAINT event_entitlement_map_pk PRIMARY KEY (event_id, entitlement_enum)
)
WITH ( OIDS=FALSE);

ALTER TABLE live.account_entitlement
   ALTER COLUMN account_id TYPE bigint;

ALTER TABLE live.account_entitlement
  ADD CONSTRAINT account_entitlement_account_fk FOREIGN KEY (account_id) REFERENCES live.account (account_id)
   ON UPDATE NO ACTION ON DELETE NO ACTION;

alter type live.entitlement_type add value 'OPERATIVE';

ALTER TABLE static.event DROP CONSTRAINT event_g0;
