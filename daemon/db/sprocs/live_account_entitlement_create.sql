CREATE OR REPLACE FUNCTION live.account_entitlement_create(p_account_id live.account_entitlement.account_id%TYPE, 
	p_entitlement live.entitlement_type)
  RETURNS void as
$BODY$
declare
	v_lang live.account.language_id%TYPE;
BEGIN
	INSERT INTO live.account_entitlement(
		account_id, entitlement_enum, create_datetime)
	VALUES (p_account_id, p_entitlement, now());
end; $BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER;
