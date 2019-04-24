-- app
INSERT INTO app (APP_ID, APP_CD, APP_NM, APP_DESCR)
VALUES (1, 'CORE', 'Core', 'Core Framework');

INSERT INTO app (APP_ID, APP_CD, APP_NM, APP_DESCR)
VALUES (2, 'TKT', 'Ticketing', 'Trouble Ticket System');

INSERT INTO app (APP_ID, APP_CD, APP_NM, APP_DESCR)
VALUES (3, 'INV', 'Invoicing', 'Customer Billing');

-- app_db
INSERT INTO app_db (DB_ID, DB_NM, DB_DESCR)
VALUES (app_db_seq.NEXTVAL, '&&core_db', 'Dev');

INSERT INTO app_db (DB_ID, DB_NM, DB_DESCR)
VALUES (app_db_seq.NEXTVAL, 'ORCL_TEST', 'Test');

INSERT INTO app_db (DB_ID, DB_NM, DB_DESCR)
VALUES (app_db_seq.NEXTVAL, 'ORCL_PROD', 'Prod');



-- sec_user
INSERT INTO sec_user (USER_ID, USER_NM, PREF_NM)
VALUES (sec_user_seq.NEXTVAL, 'bcoulam', '"Mtn Goat"');

INSERT INTO sec_user (USER_ID, USER_NM, PREF_NM)
VALUES (sec_user_seq.NEXTVAL, 'johndoe', 'John Doe');

-- sec_user_app
INSERT INTO sec_user_app (user_id, app_id)
VALUES ((SELECT user_id FROM sec_user WHERE user_nm = 'bcoulam'), (SELECT app_id FROM app WHERE app_cd = 'CORE'));

INSERT INTO sec_user_app (user_id, app_id)
VALUES ((SELECT user_id FROM sec_user WHERE user_nm = 'bcoulam'), (SELECT app_id FROM app WHERE app_cd = 'TKT'));
INSERT INTO sec_user_app (user_id, app_id)
VALUES ((SELECT user_id FROM sec_user WHERE user_nm = 'johndoe'), (SELECT app_id FROM app WHERE app_cd = 'TKT'));

INSERT INTO sec_user_app (user_id, app_id)
VALUES ((SELECT user_id FROM sec_user WHERE user_nm = 'bcoulam'), (SELECT app_id FROM app WHERE app_cd = 'INV'));
INSERT INTO sec_user_app (user_id, app_id)
VALUES ((SELECT user_id FROM sec_user WHERE user_nm = 'johndoe'), (SELECT app_id FROM app WHERE app_cd = 'INV'));

-- sec_role
INSERT INTO sec_role (ROLE_ID, APP_ID, ROLE_NM, ROLE_DESCR)
VALUES (sec_role_seq.NEXTVAL, (SELECT app_id FROM app WHERE app_cd = 'TKT'), 'Administrator', 'Ticketing administrator');

INSERT INTO sec_role (ROLE_ID, APP_ID, ROLE_NM, ROLE_DESCR)
VALUES (sec_role_seq.NEXTVAL, (SELECT app_id FROM app WHERE app_cd = 'TKT'), 'NOC Manager', 'Network Operations Center Manager');

INSERT INTO sec_role (ROLE_ID, APP_ID, ROLE_NM, ROLE_DESCR)
VALUES (sec_role_seq.NEXTVAL, (SELECT app_id FROM app WHERE app_cd = 'TKT'), 'NOC Tech', 'Network Operations Center Technician');

INSERT INTO sec_role (ROLE_ID, APP_ID, ROLE_NM, ROLE_DESCR)
VALUES (sec_role_seq.NEXTVAL, (SELECT app_id FROM app WHERE app_cd = 'INV'), 'Administrator', 'Company administrator and CFO');

INSERT INTO sec_role (ROLE_ID, APP_ID, ROLE_NM, ROLE_DESCR)
VALUES (sec_role_seq.NEXTVAL, (SELECT app_id FROM app WHERE app_cd = 'INV'), 'Billing Supervisor', 'Responsible for AR.');

INSERT INTO sec_role (ROLE_ID, APP_ID, ROLE_NM, ROLE_DESCR)
VALUES (sec_role_seq.NEXTVAL, (SELECT app_id FROM app WHERE app_cd = 'INV'), 'Billing Analyst', 'Analyzes billing disputes and ensures bills are produced on cycle.');

INSERT INTO sec_role (ROLE_ID, APP_ID, ROLE_NM, ROLE_DESCR)
VALUES (sec_role_seq.NEXTVAL, (SELECT app_id FROM app WHERE app_cd = 'INV'), 'Customer Service', 'Serves customers calling with billing questions.');


-- sec_user_role
INSERT INTO sec_user_role (USER_ID, ROLE_ID)
VALUES ((SELECT user_id FROM sec_user WHERE user_nm = 'bcoulam')
       ,(SELECT role_id FROM sec_role WHERE app_id = (SELECT app_id FROM app WHERE app_cd = 'TKT') AND role_nm = 'Administrator'));

INSERT INTO sec_user_role (USER_ID, ROLE_ID)
VALUES ((SELECT user_id FROM sec_user WHERE user_nm = 'bcoulam')
       ,(SELECT role_id FROM sec_role WHERE app_id = (SELECT app_id FROM app WHERE app_cd = 'INV') AND role_nm = 'Administrator'));

INSERT INTO sec_user_role (USER_ID, ROLE_ID)
VALUES ((SELECT user_id FROM sec_user WHERE user_nm = 'johndoe')
       ,(SELECT role_id FROM sec_role WHERE app_id = (SELECT app_id FROM app WHERE app_cd = 'TKT') AND role_nm = 'NOC Tech'));

INSERT INTO sec_user_role (USER_ID, ROLE_ID)
VALUES ((SELECT user_id FROM sec_user WHERE user_nm = 'johndoe')
       ,(SELECT role_id FROM sec_role WHERE app_id = (SELECT app_id FROM app WHERE app_cd = 'INV') AND role_nm = 'Customer Service'));


-- app_parm
INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'LDAP Server', 'Contact Mike Muckracker @ 303.888.4321 if questions.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'App Server', '');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'Client Request Timeout', 'Timeout is in seconds.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'Default IO Directory', 'Default should be adjust for *nix systems. This parm is required for package IO to function.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'Default IO File Name', 'This parm is required for package IO to function.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'Default Log File Directory', 'This parameter is required by the LOGS and API_APP_LOG packages.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'Default Email File Directory', 'This parm is required for package MAIL to function.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'Default Log Targets', 'This parameter is required by the LOGS package.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'Debug', 'To turn all debug messages on, use either "all", "on", "true", "yes" or "y". '||
'To turn all debug messages off, use either "none", "off", "false", "no" or "n". '||
'If finer control is needed over when debug logging takes place, use session=<session_id>, '||
'unit=<pkg1,proc2,trigger,etc.>, or user=<client_id>. See comments for logs.dbg() for a detailed explanation.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'Debug Toggle Check Interval', 'The amount of time, in minutes, before logs.dbg will check to see if someone has now turned on debugging by changing the Debug parameter value.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'Log Archive Directory', 'This parm is required if you wish APP_LOG_API.trim_table to archive APP_LOG messages to a file.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'Default Email Targets', 'Required by the MAIL package. Indicates the desired email destination types.');

INSERT INTO app_parm (PARM_ID, PARM_NM, PARM_COMMENTS)
VALUES (app_parm_seq.NEXTVAL, 'SMTP Host', 'Required to send emails from the DB.');




-- app_env
-- Note that the three ticketing environments are all on the same database.
-- This demonstrates how one could, if pinched for space or hardware, have
-- multiple testing environments on a single machine using the Core framework
-- and some private synonyms and appropriate grants.
INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, APP_VERSION, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
       ,(SELECT app_id FROM app WHERE app_cd = 'CORE')
       ,'Core Dev'
       ,(SELECT db_id FROM app_db WHERE db_descr = 'Dev')
       ,'2.2'
       ,UPPER('&&fmwk_home')
       ,'');
INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, APP_VERSION, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
        ,(SELECT app_id FROM app WHERE app_cd = 'CORE')
        ,'Core Test'
        ,(SELECT db_id FROM app_db WHERE db_descr = 'Test')
       ,'2.0'
        ,UPPER('&&fmwk_home')
        ,'');
INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, APP_VERSION, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
        ,(SELECT app_id FROM app WHERE app_cd = 'CORE')
        ,'Core Prod'
        ,(SELECT db_id FROM app_db WHERE db_descr = 'Prod')
       ,'1.0'
        ,UPPER('&&fmwk_home')
        ,'');

-- This demonstrates how you can have multiple environments on a single database,
-- (in this case TKT_DEV and TKT_TEST co-exist on the same Dev database). Such a 
-- setup is great to conserve resources and licensing costs as long as performance 
-- and load testing aren't a concern).
INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
        ,(SELECT app_id FROM app WHERE app_cd = 'TKT')
        ,'Ticketing Dev'
        ,(SELECT db_id FROM app_db WHERE db_descr = 'Dev')
        ,'TKT_DEV'
        ,'TKT_DEV_CLIENT');
INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
        ,(SELECT app_id FROM app WHERE app_cd = 'TKT')
        ,'Ticketing Test'
        ,(SELECT db_id FROM app_db WHERE db_descr = 'Dev')
        ,'TKT_TEST'
        ,'TKT_TEST_CLIENT');
INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
        ,(SELECT app_id FROM app WHERE app_cd = 'TKT')
        ,'Ticketing Prod'
        ,(SELECT db_id FROM app_db WHERE db_descr = 'Prod')
        ,'TKT'
        ,'TKT_CLIENT');

-- This demonstrates the more typical setup where a given application lives in just
-- one object-owning schema on each environment.
INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
        ,(SELECT app_id FROM app WHERE app_cd = 'INV')
        ,'Billing Dev'
        ,(SELECT db_id FROM app_db WHERE db_descr = 'Dev')
        ,'BLG'
        ,'BLG_CLIENT');
INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
        ,(SELECT app_id FROM app WHERE app_cd = 'INV')
        ,'Billing Test'
        ,(SELECT db_id FROM app_db WHERE db_descr = 'Test')
        ,'BLG'
        ,'BLG_CLIENT');
INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
        ,(SELECT app_id FROM app WHERE app_cd = 'INV')
        ,'Billing Prod'
        ,(SELECT db_id FROM app_db WHERE db_descr = 'Prod')
        ,'BLG'
        ,'BLG_CLIENT');



-- app_env_parm
-- LDAP Server
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'LDAP Server')
       ,'&&ldap_server_address');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'LDAP Server')
       ,'&&ldap_server_address');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'LDAP Server')
       ,REPLACE('&&ldap_server_address',389,636));
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'LDAP Server')
       ,'&&ldap_server_address');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'LDAP Server')
       ,'&&ldap_server_address');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'LDAP Server')
       ,REPLACE('&&ldap_server_address',389,636));
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'LDAP Server')
       ,'&&ldap_server_address');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'LDAP Server')
       ,'&&ldap_server_address');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'LDAP Server')
       ,REPLACE('&&ldap_server_address',389,636));

-- Client Request Timeout
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Client Request Timeout')
       ,'60');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Client Request Timeout')
       ,'30');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Client Request Timeout')
       ,'30');

-- Default IO Directory
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO Directory')
       ,'CORE_DIR');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO Directory')
       ,'CORE_DIR');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO Directory')
       ,'CORE_DIR');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO Directory')
       ,'CORE_DIR');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO Directory')
       ,'CORE_DIR');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO Directory')
       ,'CORE_DIR');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO Directory')
       ,'CORE_DIR');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO Directory')
       ,'CORE_DIR');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO Directory')
       ,'CORE_DIR');

-- Default IO File Name
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO File Name')
       ,'core_log.log');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO File Name')
       ,'core_log.log');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO File Name')
       ,'core_log.log');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO File Name')
       ,'ticketing_dev.log');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO File Name')
       ,'ticketing_test.log');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO File Name')
       ,'ticketing_prod.log');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO File Name')
       ,'billing_dev.log');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO File Name')
       ,'billing_test.log');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default IO File Name')
       ,'billing_prod.log');

-- Default Log File Directory
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log File Directory')
       ,'CORE_LOGS');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log File Directory')
       ,'CORE_LOGS');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log File Directory')
       ,'CORE_LOGS');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log File Directory')
       ,'CORE_LOGS');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log File Directory')
       ,'CORE_LOGS');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log File Directory')
       ,'CORE_LOGS');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log File Directory')
       ,'CORE_LOGS');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log File Directory')
       ,'CORE_LOGS');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log File Directory')
       ,'CORE_LOGS');
       
-- Default Email File Directory
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email File Directory')
       ,'CORE_MAIL');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email File Directory')
       ,'CORE_MAIL');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email File Directory')
       ,'CORE_MAIL');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email File Directory')
       ,'CORE_MAIL');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email File Directory')
       ,'CORE_MAIL');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email File Directory')
       ,'CORE_MAIL');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email File Directory')
       ,'CORE_MAIL');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email File Directory')
       ,'CORE_MAIL');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email File Directory')
       ,'CORE_MAIL');
       
-- Default Log Targets
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log Targets')
       ,'Screen=Y,Table=Y,File=Y');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log Targets')
       ,'Screen=N,Table=Y,File=N');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log Targets')
       ,'Screen=N,Table=Y,File=N');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log Targets')
       ,'Screen=Y,Table=Y,File=N');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log Targets')
       ,'Screen=Y,Table=Y,File=N');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log Targets')
       ,'Screen=N,Table=Y,File=N');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log Targets')
       ,'Screen=Y,Table=Y,File=N');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log Targets')
       ,'Screen=Y,Table=Y,File=N');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Log Targets')
       ,'Screen=N,Table=Y,File=N');
       
-- Debug
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug')
       ,'Off');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug')
       ,'Off');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug')
       ,'Off');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug')
       ,'Off');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug')
       ,'Off');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug')
       ,'Off');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Dev')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug')
       ,'Off');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Test')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug')
       ,'Off');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Prod')
       ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug')
       ,'Off');
       
-- Debug Toggle Check Interval
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Dev')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug Toggle Check Interval')
        ,'1');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Test')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug Toggle Check Interval')
        ,'1');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Prod')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug Toggle Check Interval')
        ,'1');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Dev')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug Toggle Check Interval')
        ,'1');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Test')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug Toggle Check Interval')
        ,'3');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'TKT' AND ae.env_nm = 'Ticketing Prod')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug Toggle Check Interval')
        ,'5');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Dev')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug Toggle Check Interval')
        ,'1');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Test')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug Toggle Check Interval')
        ,'1');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'INV' AND ae.env_nm = 'Billing Prod')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Debug Toggle Check Interval')
        ,'1');

-- Log Archive Directory
-- Only need to define for the framework schema because this is only used by api_app_log, which is a definer-rights package
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Dev')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Log Archive Directory')
        ,'CORE_LOGS');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Test')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Log Archive Directory')
        ,'CORE_LOGS');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Prod')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Log Archive Directory')
        ,'CORE_LOGS');

-- Default Email Targets
-- Only need to define for the framework schema because this is only used by mail, which is a definer-rights package
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Dev')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email Targets')
        ,'SMTP=N,Table=Y,File=N');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Test')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email Targets')
        ,'SMTP=Y,Table=Y,File=N');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Prod')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'Default Email Targets')
        ,'SMTP=Y,Table=Y,File=N');

-- SMTP Host, change if you have different SMTP servers for Dev, Test, Staging, Prod, etc.
-- Only need to define for the framework schema because this is only used by mail, which is a definer-rights package
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Dev')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'SMTP Host')
        ,'&&smtp_server_address');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Test')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'SMTP Host')
        ,'&&smtp_server_address');
INSERT INTO app_env_parm (ENV_ID, PARM_ID, PARM_VAL)
VALUES ((SELECT env_id FROM app_env ae JOIN app a ON a.app_id = ae.app_id WHERE a.app_cd = 'CORE' AND ae.env_nm = 'Core Prod')
        ,(SELECT parm_id FROM app_parm WHERE parm_nm = 'SMTP Host')
        ,'&&smtp_server_address');


-- app_msg
-- Basic set of standardized messages used by the framework
INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES (0, (SELECT app_id FROM app WHERE app_cd = 'CORE'), 'All Is Well', 'This is not an error. Check the code. No exception was detected.', 'If SQLCODE is called when no exception has occurred, the code will be 0.');
INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES (1, (SELECT app_id FROM app WHERE app_cd = 'CORE'), 'Error Msg', 'This is a context-free error message. The calling app should have passed something to logs.err() or logs.msg().', 'This empty message is not meant to be seen by users.');
INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES (2, (SELECT app_id FROM app WHERE app_cd = 'CORE'), 'Warning Msg', 'This is a context-free warning message. The calling app should have passed something to logs.warn() or logs.msg().', 'This empty message is not meant to be seen by users.');
INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES (3, (SELECT app_id FROM app WHERE app_cd = 'CORE'), 'Info Msg', 'This is a context-free informational message. The calling app should have passed something to logs.info() or logs.msg().', 'This empty message is not meant to be seen by users.');
INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES (4, (SELECT app_id FROM app WHERE app_cd = 'CORE'), 'Debug Msg', 'This is a context-free debug message. The calling app should have passed something to logs.dbg() or logs.msg().', 'This empty message is not meant to be seen by users.');

INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES (5, (SELECT app_id FROM app WHERE app_cd = 'CORE'), 'Missing Msg Code', 'The expected message code was not found in APP_MSG. Please debug the calling code.', 'This empty message is not meant to be seen by users.');
INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES (6, (SELECT app_id FROM app WHERE app_cd = 'CORE'), 'Missing Msg', 'The expected message was not passed in. Please debug the calling code.', NULL);

INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES (9, (SELECT app_id FROM app WHERE app_cd = 'CORE'), 'Ad-Hoc Msg', 'None.', 'This empty message is not meant to be seen. If users are calling logs.msg without a msg_cd, then this msg_cd will be used and whatever they pass in will be the message.');

INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES (10, (SELECT app_id FROM app WHERE app_cd = 'CORE'), 'Assertion Failure', 'An assertion/assumption failed validation.', 'Caller should be passing in a message for each assertion. This message is not meant to be seen.');

INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES (101, (SELECT app_id FROM app WHERE app_cd = 'CORE'), 'Row Lock Held', 'Unable to remove lock @1@ as it is already held FOR UPDATE NOWAIT by another process. Try again later.', '1=lock name');

INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES (102, (SELECT app_id FROM app WHERE app_cd = 'CORE'), 'Logical Lock Held', 'Lock on @1@ already held by @2@. Try again later.','1=table name, 2=app.app_cd');

COMMIT;


