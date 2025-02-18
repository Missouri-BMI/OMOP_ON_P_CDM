-- Add user
insert into atlas_security.demo_security(username,password) values
('user_id1', 'hashed_password'),
('user_id2', 'hashed_password');

-- Add user to security user
insert into webapi.sec_user(login) values
('user_id1'),
('user_id2');

-- create user role
insert into webapi.sec_role(name,system_role) values
('user_id1', false),
('user_id2', false);

-- assign user roles to users
with new_users as (
	select id as user_id, login from webapi.sec_user
	where login in (
		'user_id1',
		'user_id2'
	)
),
user_role as (
	select su.id as user_id, sr.id as role_id from webapi.sec_user  as su
	join webapi.sec_role as sr
	on su.login = sr.name
	where login in (
		'user_id1',
		'user_id2'
	)
)
insert into webapi.sec_user_role (user_id, role_id)
select user_id, 1 from new_users --public
union
select user_id, 3 from new_users --concept_ set creator
union
select user_id, 5 from new_users -- cohort creator
union 
select user_id, 6 from new_users --- cohort reader
union
select user_id, 10 from new_users -- ATLAS user
union
select user_id, 1009 from new_users--MU SOURCE
union
select user_id, 1019 from new_users--GPC SOURCE
union
select user_id, 1021 from new_users--SANDBOX
union
select user_id, role_id from user_role;
-- admin
--union
--select user_id, 2 from new_users; -admin
--union
--select user_id, 1000 from new_users; -moderator