create schema badge;

set schema 'badge';

CREATE TABLE BADGE (
	RADIO_ID 	numeric NOT NULL, 
	PRIV_KEY		text NOT NULL, 
	FLAGS			numeric NOT NULL, 
	REG_KEY		text NOT NULL,
	account_id  bigint NULL,
	display_name text NULL,
	registration_time timestamp NULL,
	constraint badge_pk primary key (RADIO_ID)
);

CREATE TABLE BADGE_PAIRING (
	RADIO_ID1	numeric NOT NULL,
	RADIO_ID2	numeric NOT NULL,
	PAIRING_CODE text NOT NULL,
	CONSTRAINT B_PAIRING_PK primary key (RADIO_ID1, RADIO_ID2)
);

ALTER TABLE badge.badge_pairing
  ADD CONSTRAINT badge_radio1_fk FOREIGN KEY (radio_id1) REFERENCES badge.badge (radio_id)
   ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE badge.badge_pairing
  ADD CONSTRAINT badge_radio2_fk FOREIGN KEY (radio_id2) REFERENCES badge.badge (radio_id)
   ON UPDATE NO ACTION ON DELETE NO ACTION;
