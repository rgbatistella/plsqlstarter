PROMPT Adding privileges to &&ps_app_owner for &&fmwk_home packages...
GRANT EXECUTE ON &&fmwk_home.APP_LOG_API TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.CNST TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.DT TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.ENV TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.EXCP TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.IO TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.LOGS TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.MAIL TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.MSGS TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.NUM TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.PARM TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.STR TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.TYP TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.TIMER TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.UTIL TO &&ps_app_owner;

PROMPT Adding privileges to &&ps_app_owner for &&fmwk_home sequences...
GRANT SELECT ON &&fmwk_home.APP_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_CHG_LOG_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_DB_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_EMAIL_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_EMAIL_DOC_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_ENV_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_LOCK_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_LOG_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_MSG_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_PARM_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.SEC_PMSN_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.SEC_ROLE_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.SEC_USER_SEQ TO &&ps_app_owner;

PROMPT Adding privileges to &&ps_app_owner for &&fmwk_home tables...
GRANT SELECT, INSERT ON &&fmwk_home.APP TO &&ps_app_owner;
GRANT SELECT, INSERT ON &&fmwk_home.APP_CHG_LOG TO &&ps_app_owner;
GRANT SELECT, INSERT ON &&fmwk_home.APP_CHG_LOG_DTL TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_DB TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.APP_EMAIL TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.APP_EMAIL_DOC TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.APP_ENV TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.APP_ENV_PARM TO &&ps_app_owner;
GRANT select, INSERT, UPDATE, DELETE ON &&fmwk_home.APP_LOCK TO &&ps_app_owner;
GRANT SELECT, INSERT ON &&fmwk_home.APP_LOG TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.APP_MSG TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.APP_PARM TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.SEC_PMSN TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.SEC_ROLE TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.SEC_ROLE_PMSN TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.SEC_USER TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.SEC_USER_APP TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.SEC_USER_ROLE TO &&ps_app_owner;

PROMPT Adding grants so &&ps_app_owner can FK to &&fmwk_home objects...
GRANT REFERENCES ON &&fmwk_home.APP TO &&ps_app_owner;
GRANT REFERENCES ON &&fmwk_home.SEC_USER TO &&ps_app_owner;

PROMPT Adding privileges to &&ps_app_owner for &&fmwk_home types...
GRANT EXECUTE ON &&fmwk_home.NUM_TT TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.STR_TT TO &&ps_app_owner;

PROMPT Adding privileges to &&ps_app_owner for &&fmwk_home views...
GRANT SELECT ON &&fmwk_home.APP_VW TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_ENV_PARM_VW TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_ENV_VW TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_PARM_VW TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.SEC_PMSN_VW TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.SEC_ROLE_PMSN_VW TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.SEC_ROLE_VW TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.SEC_USER_APP_VW TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.SEC_USER_ROLE_VW TO &&ps_app_owner;

