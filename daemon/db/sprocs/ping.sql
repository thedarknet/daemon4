-- Ping allows the service to check if the database is up and functioning
CREATE OR REPLACE FUNCTION live.ping (throw_error boolean)
RETURNS int
AS
$$
BEGIN
  IF throw_error=true THEN
    RAISE 'Intentional DB Error' USING ERRCODE='D0000';
  END IF;
  RETURN (random()*100)::int;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
