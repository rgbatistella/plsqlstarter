INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.NEXTVAL,  'ORA Errors', 'Oracle Errors of all kinds (ORA, PLS, TNS, etc.)', 1, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.NEXTVAL,'Oracle Database','Problems with Oracle Database Server',1.1,'Y',1);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.NEXTVAL,'Oracle EPG','Problems with Oracle Embedded PL/SQL Gateway',1.2,'Y',1);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.NEXTVAL,'Oracle Text','Problems using Oracle Text',1.3,'Y',1);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.NEXTVAL,  'Windows', 'Windows error messages, shortcuts, tips and tricks.', 2, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.NEXTVAL,  'Shell', 'Problems working with shell scripts.', 3, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.NEXTVAL,  'Linux', 'Linux annoyances.', 4, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.NEXTVAL,  'Java', 'Issues workinng with Java.', 5, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.NEXTVAL,  'SubVersion', 'Problems with Subversion.', 6, 'Y', NULL);
INSERT INTO ps_prob_src (prob_src_id, prob_src_nm, prob_src_defn, display_order, active_flg, prnt_prob_src_id)
VALUES (ps_prob_src_seq.NEXTVAL,  'App Server', 'Issues with the application server.', 7, 'Y', NULL);
COMMIT;

