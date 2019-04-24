INSTALLATION:

Simple to install. Takes me about 15 seconds to run the script on 11g once you've prepared.

Preparation Steps:

1. First. Are you on Windows or Linux? This will affect the path separator / or \ in paths given.
2. Second. Are you the DBA? Do you have the ability and freedom to run this script as SYSDBA, which creates schemas, roles, directories and an Oracle Text index? If not, time to take your favorite DBA to lunch. You'll need a powerful friend in order to install this framework.
3. You will need to decide whether to install the framework in an existing schema or a new schema. The install script assumes the latter. If you wish to use an existing schema, customize or comment out the call to _create_schema.sql and _create_roles.sql
4. You will need to know your company's base internet domain. 
5. You will need to know your company's SMTP server address (if any). This is for the optional proactive monitoring and emailing/texting from the database feature.
6. You will need to know your company's LDAP directory server address. This is for the optional authentication from LDAP feature.
7. The framework can log errors, informational and debug messages to the DB host filesystem, as well as keep file copies of sent emails. If you desire this optional feature, you will need to create a directory on your filesystem to hold these files. The installation will ask you for the path to this directory.
8. Open __InstallStarterFmwk.sql and read the comments there to make decisions about schemas and tablespaces.
   8a. You may need to do a little customization to meet your shop's needs and standards. The information in __InstallStarterFmwk.sql should point you in the right direction.

Installation Steps:
Note: Requires latest version of SQL*Plus that matches your database version.

1. Start SQL*Plus
2. Connect SYS as SYSDBA and run __InstallStarterFmwk.sql from the directory where you unzipped the SourceForge zip file.
3. Answer the questions, hitting Enter/Return after entering each answer. Some questions have a default value. If you like the default, just hit Enter/Return instead of re-typing the default.
   3a. If there were errors, examine the output in the __InstallStarterFmwk.log. Run __UninstallStarterFmwk.sql to drop the schemas created and try again.
4. The _populate_sample_data.sql that runs during installation populates a number of tables in the framework with sample data which are designed to show the evaluator what it is like to set up multiple applications pointing to multiple schemas on the same database which all share the framework. Examine this data and the accompanying ReleaseNotes.pdf (in the Docs subdirectory) until the sample data is no longer useful. Then delete the sample data for the TKT and INV schemas/apps in the reverse order from which it was created. Then remove the TKT, TKT_DEV and TKT_TEST schemas from your database.


