create or replace function badge.record_pairing ( p_radio_id1 badge.badge_pairing.radio_id1%TYPE
		  , p_radio_id2  badge.badge_pairing.radio_id2%TYPE
		  , p_paring_key badge.badge_pairing.pairing_code%TYPE )
returns void
AS $$
begin
	INSERT INTO badge.badge_pairing(
		radio_id1, radio_id2, pairing_code)
		VALUES (p_radio_id1, p_radio_id2, p_paring_key);
end; $$
language PLPGSQL security definer;
;

