# plsqlstarter
The PL/SQL Starter application framework is a collection of PL/SQL packages and related tables, which provide a starting point of robust, pre-tested libraries for custom PL/SQL-based applications. Save months of design/build time.

Features include:

* Standard RBAC authorization data model with role hierarchy
* Dynamic debugging, timing and logging
* Table-driven application properties
* Generic fine-grained column auditing framework
* Standardized exception handling and assertions
* Centralized application messages
* Emailing and file manipulation from the database
* Application, session, database, end user and connection metadata
* DDL library for Agile database build environments
* Named process locking (pessimistic)
* Directory server integration (ldap operations from the database)
* Common string, date and number manipulation routines

The Simple version of the framework is meant for single-schema applications. It only offers logging, error handling and table-driven parameters (with a few extra supporting packages for writing to screen and file, and manipulating dates, strings and numbers).

The full framework (Starter for 9i to 11g and Starter_12c for 12.1+) is meant for multiple applications resident in multiple schemas on the same database, where the common framework is shared between them all. It is more complete and comes with tests, full documentation, sample applications and more.
