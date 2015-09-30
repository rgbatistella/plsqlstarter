CREATE OR REPLACE PACKAGE BODY app_epg AS

PROCEDURE show_global_attrs IS
   l_attr_names  dbms_epg.varchar2_table;
   l_attr_values dbms_epg.varchar2_table;
BEGIN
   dbms_epg.get_all_global_attributes(l_attr_names, l_attr_values);

   IF (l_attr_names.COUNT > 0) THEN
      FOR a IN l_attr_names.first .. l_attr_names.last LOOP
         dbms_output.put_line(l_attr_names(a) || ' = ' ||l_attr_values(a));
      END LOOP;
   ELSE
      dbms_output.put_line('INFO: No global attributes found.'); 
   END IF;
END show_global_attrs;

PROCEDURE show_dads IS
   l_dad_names   dbms_epg.varchar2_table;
   l_paths       dbms_epg.varchar2_table;
   l_attr_names  dbms_epg.varchar2_table;
   l_attr_values dbms_epg.varchar2_table;
BEGIN
   dbms_epg.get_dad_list(dad_names => l_dad_names);
   IF l_dad_names.COUNT > 0 THEN
      FOR d IN l_dad_names.FIRST .. l_dad_names.LAST LOOP
         dbms_output.put_line('DAD[' || TO_CHAR(d) || ']: ' ||l_dad_names(d));
         
         dbms_output.put_line('Mapped to the following virtual paths...');
         l_paths.DELETE;
         dbms_epg.get_all_dad_mappings(l_dad_names(d), l_paths);
         IF (l_paths.COUNT > 0) THEN
            FOR p IN l_paths.FIRST .. l_paths.LAST LOOP
               dbms_output.put_line(' Path => ' || l_paths(p));
            END LOOP;
         ELSE
            dbms_output.put_line('INFO: No attributes for DAD '||l_dad_names(d));
         END IF;
         
         dbms_output.put_line('Has the following attributes...');
         l_attr_names.DELETE;
         l_attr_values.DELETE;
         dbms_epg.get_all_dad_attributes(l_dad_names(d),
                                         l_attr_names,
                                         l_attr_values);
         IF (l_attr_names.COUNT > 0) THEN
            FOR a IN l_attr_names.FIRST .. l_attr_names.LAST LOOP
               dbms_output.put_line(l_attr_names(a) || ' = ' ||l_attr_values(a));
            END LOOP;
         ELSE
            dbms_output.put_line('INFO: No attributes for DAD '||l_dad_names(d));
         END IF;
         
         dbms_output.put_line(''); -- blank line to break up output
      END LOOP;
   END IF;
   
END show_dads;

PROCEDURE create_dad
(
   i_dad_name IN VARCHAR2,
   i_vir_path IN VARCHAR2
) IS
BEGIN
   dbms_epg.create_dad(dad_name => i_dad_name, PATH => i_vir_path);
END create_dad;

PROCEDURE drop_dad(i_dad_name IN VARCHAR2)
IS
BEGIN
   dbms_epg.drop_dad(dad_name => i_dad_name);
END drop_dad;

PROCEDURE set_attr
(
   i_dad_name  IN VARCHAR2,
   i_attr_name IN VARCHAR2,
   i_attr_val  IN VARCHAR2
) IS
BEGIN
   dbms_epg.set_dad_attribute(dad_name   => i_dad_name,
                              attr_name  => i_attr_name,
                              attr_value => i_attr_val);
END set_attr;

PROCEDURE map_dad_to_schema
(
   i_dad_name    IN VARCHAR2,
   i_schema_name IN VARCHAR2
) IS
BEGIN
   dbms_epg.authorize_dad(dad_name => i_dad_name,
                          user     => UPPER(i_schema_name));
END map_dad_to_schema;

PROCEDURE unmap_dad_from_schema
(
   i_dad_name    IN VARCHAR2,
   i_schema_name IN VARCHAR2
) IS
BEGIN
   dbms_epg.deauthorize_dad(dad_name => i_dad_name,
                            USER     => UPPER(i_schema_name));
END unmap_dad_from_schema;


END app_epg;
/
