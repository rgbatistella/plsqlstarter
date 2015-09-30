CREATE OR REPLACE PACKAGE app_epg AS

PROCEDURE show_global_attrs;
PROCEDURE show_dads;

PROCEDURE create_dad(i_dad_name IN VARCHAR2, i_vir_path IN VARCHAR2);
PROCEDURE drop_dad(i_dad_name IN VARCHAR2);
PROCEDURE set_attr(i_dad_name IN VARCHAR2, i_attr_name IN VARCHAR2, i_attr_val IN VARCHAR2);
PROCEDURE map_dad_to_schema(i_dad_name IN VARCHAR2, i_schema_name IN VARCHAR2);
PROCEDURE unmap_dad_from_schema(i_dad_name IN VARCHAR2, i_schema_name IN VARCHAR2);

END app_epg;
/
