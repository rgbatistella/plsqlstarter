CREATE OR REPLACE VIEW user_session
AS
SELECT * FROM v$session 
WHERE username = (SYS_CONTEXT('userenv','session_user'));

GRANT SELECT ON user_session to PUBLIC;

CREATE PUBLIC SYNONYM user_session FOR sys.user_session;

