PROMPT Adding privileges to &&ps_app_owner for &&fmwk_home packages...
GRANT EXECUTE ON &&fmwk_home.APP_LOG_API TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.CNST TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.DT TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.ENV TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.EXCP TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.IO TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.LOGS TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.NUM TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.PARM TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.STR TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.TIMER TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.TYP TO &&ps_app_owner;

PROMPT Adding privileges to &&ps_app_owner for &&fmwk_home sequences...
GRANT SELECT ON &&fmwk_home.APP_CHG_LOG_SEQ TO &&ps_app_owner;
GRANT SELECT ON &&fmwk_home.APP_LOG_SEQ TO &&ps_app_owner;

PROMPT Adding privileges to &&ps_app_owner for &&fmwk_home tables...
GRANT SELECT, INSERT ON &&fmwk_home.APP_CHG_LOG TO &&ps_app_owner;
GRANT SELECT, INSERT ON &&fmwk_home.APP_CHG_LOG_DTL TO &&ps_app_owner;
GRANT SELECT, INSERT, DELETE ON &&fmwk_home.APP_LOG TO &&ps_app_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON &&fmwk_home.APP_PARM TO &&ps_app_owner;

PROMPT Adding privileges to &&ps_app_owner for &&fmwk_home types...
GRANT EXECUTE ON &&fmwk_home.DT_TT TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.NUM_TT TO &&ps_app_owner;
GRANT EXECUTE ON &&fmwk_home.STR_TT TO &&ps_app_owner;

