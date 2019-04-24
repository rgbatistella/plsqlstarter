CREATE OR REPLACE PROCEDURE drop_all_obj (i_schema_nm IN VARCHAR2 DEFAULT USER)
IS 
   l_schema_nm         VARCHAR2(30);
   l_object_count           NUMBER;  -- the current count of objects in the schema 
   l_object_count_previous  NUMBER;  -- the previous count of objects in the schema 
   l_sql                    VARCHAR2(1000);  -- the dynamic SQL "drop" statement 
   l_purge_ind              VARCHAR2(10); 
   
   -- a cursor of the "droppable" objects 
   CURSOR cur_obj(i_owner IN VARCHAR2) IS 
    SELECT owner, object_name, object_type 
      FROM dba_objects
     WHERE owner = i_owner
       AND object_type IN ('FUNCTION', 'PACKAGE', 'PROCEDURE', 'SEQUENCE', 
                           'SYNONYM', 'TABLE', 'TYPE', 'VIEW', 'JAVA SOURCE'
                           ,'MATERIALIZED VIEW');
       
   CURSOR cur_q(i_owner IN VARCHAR2) IS
    SELECT owner, name, queue_table
      FROM dba_queues
     WHERE owner = i_owner
       AND queue_type = 'NORMAL_QUEUE';
     
   PROCEDURE purge_dropped_objects IS
   BEGIN
      IF (dbms_db_version.version >= 10) THEN
         dbms_output.put_line('Purging the DBA_RECYCLEBIN...');
         EXECUTE IMMEDIATE ('PURGE DBA_RECYCLEBIN');
      END IF;
   END purge_dropped_objects;

   PROCEDURE drop_q(i_q_owner IN VARCHAR2, i_q_nm IN VARCHAR2, i_q_tbl IN VARCHAR2)
   IS
      lx_queue_is_not EXCEPTION;
      lx_queue_running EXCEPTION;
      lx_queue_tab_is_not EXCEPTION;
      PRAGMA EXCEPTION_INIT(lx_queue_is_not,-24010);
      PRAGMA EXCEPTION_INIT(lx_queue_running,-24011);
      PRAGMA EXCEPTION_INIT(lx_queue_tab_is_not,-24002);
   BEGIN
      BEGIN
         dbms_aqadm.drop_queue(queue_name => i_q_owner||'.'||i_q_nm);
      EXCEPTION
         WHEN lx_queue_is_not THEN
            dbms_output.put_line('Queue '||i_q_owner||'.'||i_q_nm||' does not yet exist. Check spelling to be sure.');
         WHEN lx_queue_running THEN
            dbms_aqadm.stop_queue(queue_name => i_q_owner||'.'||i_q_nm);
            dbms_aqadm.drop_queue(queue_name => i_q_owner||'.'||i_q_nm);
      END;
      
      BEGIN
         dbms_aqadm.drop_queue_table(queue_table => i_q_owner||'.'||i_q_tbl, force=>TRUE);
      EXCEPTION
         WHEN lx_queue_tab_is_not THEN
            dbms_output.put_line('Queue table '||i_q_owner||'.'||i_q_tbl||' does not yet exist. Check spelling to be sure.');
      END;
   END drop_q;
 
BEGIN 
 
   purge_dropped_objects(); 
 
   IF (dbms_db_version.version >= 10) THEN 
      l_purge_ind := 'PURGE'; 
   ELSIF (dbms_db_version.version = 9) THEN 
      l_purge_ind := NULL; 
   END IF; 
   
   l_schema_nm := NVL(UPPER(i_schema_nm), USER);
   dbms_output.put_line('Schema being emptied is '||l_schema_nm);
   
   -- get the current count of objects in the specified schema 
   SELECT COUNT(*)
     INTO l_object_count
     FROM dba_objects
    WHERE owner = l_schema_nm;
   dbms_output.put_line(l_object_count||' objects exist in '||l_schema_nm||'. Dropping...');
   
   -- drop queues
   FOR lq IN cur_q(l_schema_nm) LOOP
      dbms_output.put('Dropping queue '||lq.name||'...');
      drop_q(lq.owner, lq.name, lq.queue_table);
      dbms_output.put('Done');
      dbms_output.new_line;
   END LOOP;
   
   -- set the previous object count higher than current to force entry into following loop 
   l_object_count_previous := l_object_count + 1; 
 
   -- keep attempting to drop objects until the object count remains the same or all objects are gone 
   WHILE NOT ( l_object_count_previous = l_object_count OR l_object_count = 0 ) LOOP 
      
      -- remember the count before attempting to drop objects 
      l_object_count_previous := l_object_count; 
          
      -- loop through the droppable objects 
      FOR rec IN cur_obj(l_schema_nm) LOOP 
          
         -- build the drop statement for the current object 
         l_sql := 'DROP ' || rec.object_type || ' '||rec.owner||'."' || rec.object_name||'"'; 
             
         -- if it is a table, add the CASCADE CONSTRAINTS clause to avoid having 
         --   to drop the tables in a dependency-related order. 
         IF rec.object_type = 'TABLE' THEN 
            l_sql := l_sql || ' CASCADE CONSTRAINTS'||' '||l_purge_ind; 
         END IF; 
                
             
         -- run the drop command, ignoring any errors 
         BEGIN 
            EXECUTE IMMEDIATE l_sql; 
         EXCEPTION 
            WHEN OTHERS THEN 
             NULL; 
         END; 
          
      END LOOP; 
          
      -- get the count of remaining objects after the last set of drop statements
      SELECT COUNT(*)
        INTO l_object_count
        FROM dba_objects
       WHERE owner = l_schema_nm;
       dbms_output.put_line(l_object_count||' objects remain in '||l_schema_nm);
       
   END LOOP; 
   
   dbms_output.new_line;
     
END drop_all_obj; 
/
