SET SERVEROUTPUT ON SIZE 1000000
DECLARE
BEGIN
   dbms_output.put_line('Set User Context');
   env.init_client_ctx('bcoulam');
   env.tag_session(i_module => 'ENV TEST', i_action => 'TAG SESSION', i_info => 'test');
   env.set_ctx_val('authentication attempts', 5);

   dbms_output.put_line('USER_ID: '||env.get_client_id);
   dbms_output.put_line('USER_IP: '||env.get_client_ip);
   dbms_output.put_line('CLIENT_HOST: '||env.get_client_host);
   dbms_output.put_line('OS_USER: '||env.get_client_os_user);
   dbms_output.put_line('CLIENT_PROGRAM: '||env.get_client_program);
   dbms_output.put_line('CLIENT_MODULE: '||env.get_client_module);
   dbms_output.put_line('CLIENT_ACTION: '||env.get_client_action);
   dbms_output.put_line('SESSION_USER: '||env.get_session_user);
   dbms_output.put_line('CURRENT_SCHEMA: '||env.get_current_schema);
   dbms_output.put_line('DB_VERSION: '||env.get_db_version);
   dbms_output.put_line('DB_NAME: '||env.get_db_name);
   dbms_output.put_line('DB_INSTANCE_NAME: '||env.get_db_instance_name);
   dbms_output.put_line('DB_INSTANCE_ID: '||env.get_db_instance_id);
   dbms_output.put_line('SERVER_HOST: '||env.get_server_host);
   dbms_output.put_line('SID: '||env.get_sid);
   dbms_output.put_line('SESSION_ID: '||env.get_session_id);
   dbms_output.put_line('OS_PID: '||env.get_os_pid);
   
   dbms_output.put_line('SCHEMA_EMAIL_ADDRESS: '||env.get_schema_email_address);
   dbms_output.put_line('DBID (per app_db): '||env.get_db_id);
   dbms_output.put_line('APP_ID: '||env.get_app_id);
   dbms_output.put_line('APP_ID: '||env.get_app_id('PSOL'));
   dbms_output.put_line('APP_CD: '||env.get_app_cd); 
   dbms_output.put_line('APP_CD: '||env.get_app_cd(i_app_id => env.get_app_id('PSOL'))); 
   dbms_output.put_line('ENV_NM: '||env.get_env_nm);
   dbms_output.put_line('ENV_NM: '||env.get_env_nm('PSOL'));
   dbms_output.put_line('DIR_PATH: '||env.get_dir_path(i_dir_nm => 'CORE_LOGS'));
   dbms_output.put_line('WHO_CALLED_ME: '||env.who_called_me);
   dbms_output.put_line('WHO_AM_I: '||env.who_am_i);
   dbms_output.put_line('LINE_NUM_HERE: '||env.line_num_here);
   -- env.who_called_me and who_am_i are best called from deep within 
   -- packages, not here from a shallow anonymous block.
   -- env.get_routine_nm must be called with a package name and line number,
   -- which are always changing and tough to create a test script with an
   -- expected result that can be coded for.
   dbms_output.put_line('Custom CTX Value [5]: '||SYS_CONTEXT('APP_CORE_CTX','authentication attempts'));
   dbms_output.put_line('Custom CTX Value [5]: '||SYS_CONTEXT('app_core_ctx','authentication attempts'));
   env.clear_ctx_val('authentication attempts');   
   dbms_output.put_line('Custom CTX Value []: '||SYS_CONTEXT('APP_CORE_CTX','authentication attempts'));
   env.set_ctx_val('authentication attempts', 5);
   dbms_output.put_line('Custom CTX Value [5]: '||SYS_CONTEXT('APP_CORE_CTX','authentication attempts'));
   env.clear_ctx('APP_CORE_CTX');
   dbms_output.put_line('Custom CTX Value []: '||SYS_CONTEXT('APP_CORE_CTX','authentication attempts'));
   env.set_ctx_val('authentication attempts', 5);
   dbms_output.put_line('Custom CTX Value [5]: '||SYS_CONTEXT('APP_CORE_CTX','authentication attempts'));
   env.clear_ctx;
   dbms_output.put_line('Custom CTX Value []: '||SYS_CONTEXT('APP_CORE_CTX','authentication attempts'));

   env.untag_session;

END;
/


BEGIN
   -- Now set things back to blank, just like a good Java client would when
   -- returning a connection to the connection pool. This has to be run as a
   -- separate block. If you include it with the upper one, it wipes out the
   -- data kept in the dbms_output buffer.
   dbms_output.put_line('Re-Init');
   env.reset_client_ctx;
END;
/

