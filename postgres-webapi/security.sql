insert into atlas_security.demo_security (username,password) 
values ('mhmcb@umsystem.edu', '$2a$10$kSTwBygJuGzVqlk.VepJBecbclDTk0v5uxB2RV6Y6qvb74uMQL7HK');

--do login, extract user_id

insert into sec_user_role(user_id, role_id)
values(1000, 2);--admin

insert into sec_user_role(user_id, role_id)
values(1000, 10);--atlas_user

insert into sec_user_role(user_id, role_id)
values(1000, 3);

insert into sec_user_role(user_id, role_id)
values(1000, 5);

insert into sec_user_role(user_id, role_id)
values(1000, 6);

mosaa@umsystem.edu