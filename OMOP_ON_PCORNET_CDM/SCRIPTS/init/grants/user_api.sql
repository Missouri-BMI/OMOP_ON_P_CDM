

CREATE OR REPLACE FUNCTION webapi.add_batch_users(
  logins TEXT[],
  names TEXT[],
  is_admin BOOLEAN[]
)
RETURNS void AS $$
DECLARE
  i INTEGER;
BEGIN
  FOR i IN 1 .. array_length(logins, 1) LOOP
    -- Insert into sec_user
    INSERT INTO webapi.sec_user(login, name)
    VALUES (logins[i], names[i])
    ;

    -- Insert into sec_role
    INSERT INTO webapi.sec_role(name, system_role)
    VALUES (logins[i], false)
    ;
  END LOOP;

  -- Assign roles
  WITH new_users AS (
    SELECT id AS user_id, login FROM webapi.sec_user
    WHERE login = ANY(logins)
  ),
  user_role AS (
    SELECT su.id AS user_id, sr.id AS role_id
    FROM webapi.sec_user su
    JOIN webapi.sec_role sr ON su.login = sr.name
    WHERE su.login = ANY(logins)
  ),
  admin_users AS (
    SELECT login, unnest(is_admin) AS admin_flag
    FROM unnest(logins) WITH ORDINALITY AS logins(login, idx)
    JOIN unnest(is_admin) WITH ORDINALITY AS admins(flag, idx2)
      ON logins.idx = admins.idx2
    WHERE flag = true
  ),
  admin_user_ids AS (
    SELECT su.id AS user_id
    FROM webapi.sec_user su
    JOIN admin_users au ON su.login = au.login
  )
  INSERT INTO webapi.sec_user_role(user_id, role_id)
  SELECT user_id, unnest(ARRAY[1, 3, 5, 6, 10, 1004]) FROM new_users
  UNION
  SELECT user_id, role_id FROM user_role
  UNION
  SELECT user_id, 2 FROM admin_user_ids    -- Admin role
  UNION
  SELECT user_id, 1000 FROM admin_user_ids; -- Moderator role
END;
$$ LANGUAGE plpgsql;

-- SELECT webapi.add_batch_users(
--     ARRAY[
--         'splzkv@umsystem.edu',
--         'nm943@umsystem.edu',
--         'txwkn@umsystem.edu',
--         'imgtcc@umsystem.edu',
--         'cknm5@umsystem.edu'
--     ],
--     ARRAY[
--         'Lima dos Santos,Sueny Paloma',
--         'Mazumder,Narayana',
--         'Xiao,Ting',
--         'GOMINA,ISAAC',
--         'Koob,Carol'
--     ],
--     ARRAY[
--         false,
--         false,
--         false,
--         false,
--         false
--     ]
-- );

-- ===================================
-- Remove Users in Batch
-- ===================================
CREATE OR REPLACE FUNCTION webapi.remove_batch_users(logins TEXT[])
RETURNS void AS $$
DECLARE
BEGIN
  -- Remove roles assigned to users
  DELETE FROM webapi.sec_user_role
  WHERE user_id IN (
    SELECT id FROM webapi.sec_user WHERE login = ANY(logins)
  );

  -- Remove roles
--   DELETE FROM webapi.sec_role
--   WHERE name = ANY(logins);

  -- Remove users
--   DELETE FROM webapi.sec_user
--   WHERE login = ANY(logins);
END;
$$ LANGUAGE plpgsql;

-- Remove users
-- SELECT webapi.remove_batch_users(
--   ARRAY[
--         'splzkv@umsystem.edu',
--         'nm943@umsystem.edu',
--         'txwkn@umsystem.edu',
--         'imgtcc@umsystem.edu',
--         'cknm5@umsystem.edu'
--     ]
-- );