SET VERIFY OFF

INSERT INTO app (APP_ID, APP_CD, APP_NM, APP_DESCR)
VALUES (app_seq.NEXTVAL, 'PSOL', 'Problem-Solution Knowledgebase', 'Generic problem-solution entry and search application, based on the Embedded PL/SQL Gateway within Oracle.');

-- Now the application has been added to the framework, we need to identify ourselves to the framework
-- for the table data auditing mechanisms to function.
BEGIN
   env.init_client_ctx(i_client_id => 'install', i_app_cd => 'PSOL');
END;
/

INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
       , env.get_app_id('PSOL')
       , 'ProbSol Dev'
       , (SELECT db_id FROM app_db WHERE db_descr = 'Dev')
       , UPPER('&&ps_app_owner')
       , 'ANONYMOUS');
INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
       , env.get_app_id('PSOL')
       , 'ProbSol Test'
       , (SELECT db_id FROM app_db WHERE db_descr = 'Test')
       , UPPER('&&ps_app_owner')
       , 'ANONYMOUS');
INSERT INTO app_env (ENV_ID, APP_ID, ENV_NM, DB_ID, OWNER_ACCOUNT, ACCESS_ACCOUNT)
VALUES ( app_env_seq.NEXTVAL
       , env.get_app_id('PSOL')
       , 'ProbSol Prod'
       , (SELECT db_id FROM app_db WHERE db_descr = 'Prod')
       , UPPER('&&ps_app_owner')
       , 'ANONYMOUS');

INSERT INTO app_msg (MSG_ID, APP_ID, MSG_CD, MSG, MSG_DESCR)
VALUES ( app_msg_seq.NEXTVAL
       , (SELECT app_id FROM app WHERE app_cd = 'PSOL')
       , 'Invalid Problem ID'
       , 'Unable to find data for Problem ID @1@, probably due to refreshing a page that already deleted that problem ID.'
       , '1 = ps_prob.prob_id');

COMMIT;

DECLARE
BEGIN
   FOR lr IN (SELECT env_id FROM app_env WHERE env_nm LIKE 'ProbSol%') LOOP

      INSERT INTO app_env_parm (env_id, parm_id, parm_val) VALUES (lr.env_id, 4, 'CORE_DIR');
      INSERT INTO app_env_parm (env_id, parm_id, parm_val) VALUES (lr.env_id, 5, 'sol.log');
      INSERT INTO app_env_parm (env_id, parm_id, parm_val) VALUES (lr.env_id, 6, 'CORE_LOGS');
      INSERT INTO app_env_parm (env_id, parm_id, parm_val) VALUES (lr.env_id, 7, 'CORE_MAIL');
      INSERT INTO app_env_parm (env_id, parm_id, parm_val) VALUES (lr.env_id, 8, 'Screen=Y,Table=Y,File=N');
      INSERT INTO app_env_parm (env_id, parm_id, parm_val) VALUES (lr.env_id, 9, 'Off');
      INSERT INTO app_env_parm (env_id, parm_id, parm_val) VALUES (lr.env_id, 10, '1');
      INSERT INTO app_env_parm (env_id, parm_id, parm_val) VALUES (lr.env_id, 12, 'SMTP=Y,Table=Y,File=N');
      INSERT INTO app_env_parm (env_id, parm_id, parm_val) VALUES (lr.env_id, 13, '&&smtp_server_address');            

   END LOOP;   
END;
/   

COMMIT;

SET VERIFY ON
