CREATE OR REPLACE PACKAGE gem
AS

PROCEDURE set_client_id(i_client_id IN VARCHAR2);
FUNCTION get_client_id RETURN VARCHAR2;
-- sets the value of a named attribute into the app context, optionally only for the given client
PROCEDURE set_ctx
(
   i_attr_nm   IN VARCHAR2,
   i_attr_val  IN VARCHAR2,
   i_client_id IN VARCHAR2 DEFAULT NULL
);
PROCEDURE clear_client_id;
-- clears just the named attribute, optionally only for the given client
PROCEDURE clear_ctx_attr
(
   i_attr_nm   IN VARCHAR2,
   i_client_id IN VARCHAR2 DEFAULT NULL
);
-- clears all attributes belonging to the given client
PROCEDURE clear_client_attrs(i_client_id IN VARCHAR2);
-- clears the whole app context
PROCEDURE clear_ctx;
PROCEDURE clear_pkg_state;
PROCEDURE clear_session;

END gem;
/

CREATE OR REPLACE PACKAGE BODY gem
AS
g_client_id VARCHAR2(100);
g_app_ctx   VARCHAR2(10) := 'gem_ctx';

FUNCTION get_client_id RETURN VARCHAR2
IS
BEGIN
   RETURN SYS_CONTEXT('userenv', 'client_identifier');
END get_client_id;

PROCEDURE set_client_id(i_client_id IN VARCHAR2) IS
BEGIN
   g_client_id := i_client_id;
   dbms_session.set_identifier(i_client_id);
END set_client_id;

PROCEDURE set_ctx
(
   i_attr_nm   IN VARCHAR2,
   i_attr_val  IN VARCHAR2,
   i_client_id IN VARCHAR2 DEFAULT NULL
) IS
BEGIN
   dbms_session.set_context(namespace => g_app_ctx
                           ,ATTRIBUTE => LOWER(i_attr_nm)
                           ,VALUE     => i_attr_val
                           ,username  => NULL
                           ,client_id => i_client_id);
END set_ctx;

PROCEDURE clear_client_id IS
BEGIN
   dbms_session.clear_identifier;
END clear_client_id;

PROCEDURE clear_ctx_attr
(
   i_attr_nm   IN VARCHAR2,
   i_client_id IN VARCHAR2 DEFAULT NULL
) IS
BEGIN
   dbms_session.clear_context(namespace => g_app_ctx
                             ,ATTRIBUTE => i_attr_nm
                             ,client_id => i_client_id);
END clear_ctx_attr;

PROCEDURE clear_client_attrs(i_client_id IN VARCHAR2) IS
BEGIN
   dbms_session.clear_context(namespace => g_app_ctx
                             ,client_id => i_client_id);
END clear_client_attrs;

PROCEDURE clear_ctx IS
BEGIN
   dbms_session.clear_all_context(namespace => g_app_ctx);
END clear_ctx;

PROCEDURE clear_pkg_state IS
BEGIN
   dbms_session.reset_package;
END clear_pkg_state;

PROCEDURE clear_session IS
BEGIN
   g_client_id := NULL; -- probably redundant considering the next call to reset pkg state
   clear_pkg_state;
   clear_ctx;
   clear_client_id;
END clear_session;

END gem;
/

CREATE OR REPLACE CONTEXT gem_ctx USING gem ACCESSED GLOBALLY;
