create user remote_admin nocreateuser LOGIN password 'password';
create database remotes owner remote_admin;

create user badge_user with nocreatedb nocreaterole nocreateuser LOGIN password 'badge_user';
grant connect on database remotes to badge_user;

select * from pg_user;
select * from pg_database;


