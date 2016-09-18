-- Add database errors here
create or replace function live.throw_epic_not_available( )
returns 
	void
AS $$
begin
	raise 'Epic not available' using errcode='D0001';
end; $$
language PLPGSQL security definer;
;

-- Add database errors here
create or replace function live.throw_epic_in_progress( )
returns 
	void
AS $$
begin
	raise 'Epic already in progress' using errcode='D0002';
end; $$
language PLPGSQL security definer;
;