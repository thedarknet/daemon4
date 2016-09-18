create user darknet_user with nocreatedb nocreaterole nocreateuser LOGIN password 'darknet_user';
grant connect on database daemon to darknet_user;
grant connect on database daemon to daemon_admin;
grant create on database daemon to daemon_admin;

select * from pg_user;
select * from pg_database;


