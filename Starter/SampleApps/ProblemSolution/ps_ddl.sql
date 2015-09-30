DROP TABLE ps_sol CASCADE CONSTRAINTS PURGE;
DROP TABLE ps_prob CASCADE CONSTRAINTS PURGE;
DROP TABLE ps_prob_src PURGE;
DROP SEQUENCE ps_prob_seq;
DROP SEQUENCE ps_sol_seq;
DROP SEQUENCE ps_prob_src_seq;

CREATE SEQUENCE ps_prob_src_seq;
CREATE SEQUENCE ps_prob_seq;
CREATE SEQUENCE ps_sol_seq;

CREATE TABLE ps_prob_src
(
 prob_src_id INTEGER NOT NULL
,prob_src_nm VARCHAR2(30 CHAR) NOT NULL
,prob_src_defn VARCHAR2(255 CHAR) NOT NULL
,display_order NUMBER NOT NULL
,active_flg VARCHAR2(1 BYTE) DEFAULT 'Y' NOT NULL
,prnt_prob_src_id INTEGER
,CONSTRAINT ps_prob_src_pk PRIMARY KEY (prob_src_id)
,CONSTRAINT ps_prob_src_uk UNIQUE (prob_src_nm)
,CONSTRAINT pps_active_flg_chk CHECK (active_flg IN ('Y','N'))
,CONSTRAINT pps_prnt_prob_src_id_fk FOREIGN KEY (prnt_prob_src_id) REFERENCES ps_prob_src (prob_src_id)
)
/
CREATE INDEX pps_prnt_prob_src_id_idx ON ps_prob_src(prnt_prob_src_id)
/
COMMENT ON TABLE ps_prob_src IS 'Problem Source: User-amendable list of the various sources of problems encountered in an IT shop.';
COMMENT ON COLUMN ps_prob_src.prob_src_id IS 'Problem Source ID: Surrogate key for this table. Currently filled manually by data population scripts.';
COMMENT ON COLUMN ps_prob_src.prob_src_nm IS 'Problem Source Value: Name or code for the source system, environment, hardware or software from which the error was first detected or originated.';
COMMENT ON COLUMN ps_prob_src.prob_src_defn IS 'Problem Source Definition: Full definition of the source system, environment, hardware or software from which the error was first detected or originated.';
COMMENT ON COLUMN ps_prob_src.display_order IS 'Display Order: In case the users wish one set of values to be ordered in a non-alphabetical manner, this allows them to customize the ordering of values.';
COMMENT ON COLUMN ps_prob_src.active_flg IS 'Active Flag: Flag that indicates if the record is active (Y) or not (N).';
COMMENT ON COLUMN ps_prob_src.prnt_prob_src_id IS 'Parent Problem Source ID: Self-referring foreign key. Filled if the sources of problems become so numerous that categorization or hierarchy is needed.';

CREATE TABLE ps_prob
(
 prob_id INTEGER NOT NULL
,prob_key VARCHAR2(50 CHAR) NOT NULL
,prob_key_txt VARCHAR2(4000 CHAR)
,prob_notes VARCHAR2(4000 CHAR)
,prob_src_id INTEGER
,otx_sync_col VARCHAR2(1 BYTE) DEFAULT 'N' NOT NULL
,CONSTRAINT ps_prob_pk PRIMARY KEY (prob_id)
,CONSTRAINT ps_prob_uk UNIQUE (prob_key, prob_key_txt)
,CONSTRAINT ps_prob_src_id_fk FOREIGN KEY (prob_src_id) REFERENCES ps_prob_src (prob_src_id)
)
/
CREATE INDEX psp_prob_src_id_idx ON ps_prob(prob_src_id)
/
COMMENT ON TABLE ps_prob IS 'Problem: Record of the errors, issues and problems encountered day-to-day.';
COMMENT ON COLUMN ps_prob.prob_id IS 'Problem ID: Surrogate key for records in this table.';
COMMENT ON COLUMN ps_prob.prob_key IS 'Problem Key: Typically the OS, Database, or application-specific error
 ID or name. Usually found at the top of an error stack, or in the title of error and warning dialogs. If
 this problem is not related to an identifiable error, give the problem a short name or code which
 adequately identifies the situation.';
COMMENT ON COLUMN ps_prob.prob_key_txt IS 'Problem Key Text: Optional. Typically the error message that came
 with the error ID, minus the specific non-repeatable, contextual information.';
COMMENT ON COLUMN ps_prob.prob_notes IS 'Problem Notes: You could use this field to store context surrounding
 the problem, like time of day it was observed, environment, concurrent processes, contacts, vendor case
 IDs, etc.';
COMMENT ON COLUMN ps_prob.prob_src_id IS 'Problem Source ID: Optional ID of the problem source. FK to PS_PROB_SRC.';
COMMENT ON COLUMN ps_prob.otx_sync_col IS 'Oracle Text Sync Column: A dummy column used as both the base column for multi-column context indexes, as well as the column that must be updated to Y whenever any data is changed or added so that the Oracle Text CTX_DDL.sync procedure will pick up the changes.';

CREATE TABLE ps_sol
(
 sol_id INTEGER NOT NULL
,prob_id INTEGER NOT NULL
,sol_notes VARCHAR2(4000)
,CONSTRAINT ps_sol_pk PRIMARY KEY (sol_id)
,CONSTRAINT pss_prob_id_fk FOREIGN KEY (prob_id) REFERENCES ps_prob (prob_id)
)
/
COMMENT ON TABLE ps_sol IS 'Solution: Record of the possible solutions to a given problem. Some problems 
 will have only one solutions, others may have several alternatives.';
COMMENT ON COLUMN ps_sol.sol_id IS 'Solution ID: Surrogate key for records in this table.';
COMMENT ON COLUMN ps_sol.prob_id IS 'Problem ID: Foreign key to PS_PROB.';
COMMENT ON COLUMN ps_sol.sol_notes IS 'Solution Notes: Steps to take to solve the related problem.';

CREATE INDEX pss_prob_id_idx ON ps_sol (prob_id)
/
