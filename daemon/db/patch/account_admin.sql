SET SCHEMA 'live';
ALTER TABLE account ADD COLUMN user_type varchar(32);
ALTER TABLE account ALTER COLUMN user_type SET DEFAULT 'player';
