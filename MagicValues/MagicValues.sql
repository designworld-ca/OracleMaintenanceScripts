/* https://blogs.oracle.com/oraclemagazine/the-magic-kingdom
What is the best way to avoid hard-coding literal “magic values” in my PL/SQL-based applications?
By Steven Feuerstein Oracle ACE Director
May/June 2009
*/
DROP TABLE magic_values
/

CREATE TABLE magic_values
(
   name                   VARCHAR2 (100) UNIQUE
 , description            VARCHAR2 (4000)
 , VALUE                  VARCHAR2 (4000)
 , identifier             VARCHAR2 (100) UNIQUE
 , datatype               VARCHAR2 (100) DEFAULT 'VARCHAR2(32767)'
 , function_return_type   VARCHAR2 (100)
)
/

/*
First a simple approach of providing a function to return the value. 
*/

BEGIN
   DELETE FROM magic_values;

   INSERT INTO magic_values (
                                name
                              , description
                              , VALUE
              )
       VALUES (
                  'Maximum salary'
                , 'You cannot earn more than this in a single year.'
                , '10000000'
              );

   INSERT INTO magic_values (
                                name
                              , description
                              , VALUE
              )
       VALUES (
                  'Earliest supported date'
                , 'The application will not work with dates before this.'
                , 'ADD_MONTHS (SYSDATE, -60)'
              );

   INSERT INTO magic_values (name, description, VALUE
                            )
       VALUES ('Open status', NULL, '''OPEN'''
              );

   COMMIT;
END;
/

CREATE OR REPLACE PACKAGE get_magic_values
IS
   FUNCTION varchar2_value (NAME_IN IN magic_values.name%TYPE)
      RETURN varchar2 
      $IF dbms_db_version.ver_le_10_2
      $THEN
        /* No result cache available prior to Oracle11g */
      $ELSE
        RESULT_CACHE
      $END
      ;

   FUNCTION date_value (NAME_IN IN magic_values.name%TYPE)
      RETURN date 
      $IF dbms_db_version.ver_le_10_2
      $THEN
        /* No result cache available prior to Oracle11g */
      $ELSE
        RESULT_CACHE
      $END
      ;

   FUNCTION number_value (NAME_IN IN magic_values.name%TYPE)
      RETURN number 
      $IF dbms_db_version.ver_le_10_2
      $THEN
        /* No result cache available prior to Oracle11g */
      $ELSE
        RESULT_CACHE
      $END
      ;
END get_magic_values;
/

CREATE OR REPLACE PACKAGE BODY get_magic_values
IS
   FUNCTION varchar2_value (NAME_IN IN magic_values.name%TYPE)
      RETURN VARCHAR2
      $IF dbms_db_version.ver_le_10_2
      $THEN
        /* No result cache available prior to Oracle11g */
      $ELSE
          RESULT_CACHE RELIES_ON ( magic_values )
      $END
   IS
      l_value    magic_values.VALUE%TYPE;
      l_return   VARCHAR2 (32767);
   BEGIN
      SELECT VALUE
        INTO l_value
        FROM magic_values
       WHERE name = NAME_IN;

      EXECUTE IMMEDIATE 'BEGIN :actual_value := ' || l_value || '; END;'
         USING OUT l_return;

      RETURN l_return;
   END varchar2_value;

   FUNCTION date_value (NAME_IN IN magic_values.name%TYPE)
      RETURN DATE
      $IF dbms_db_version.ver_le_10_2
      $THEN
        /* No result cache available prior to Oracle11g */
      $ELSE
          RESULT_CACHE RELIES_ON ( magic_values )
      $END
   IS
      l_value    magic_values.VALUE%TYPE;
      l_return   DATE;
   BEGIN
      SELECT VALUE
        INTO l_value
        FROM magic_values
       WHERE name = NAME_IN;

      EXECUTE IMMEDIATE 'BEGIN :actual_value := ' || l_value || '; END;'
         USING OUT l_return;

      RETURN l_return;
   END date_value;

   FUNCTION number_value (NAME_IN IN magic_values.name%TYPE)
      RETURN NUMBER
      $IF dbms_db_version.ver_le_10_2
      $THEN
        /* No result cache available prior to Oracle11g */
      $ELSE
          RESULT_CACHE RELIES_ON ( magic_values )
      $END
   IS
      l_value   NUMBER;
   BEGIN
      SELECT VALUE
        INTO l_value
        FROM magic_values
       WHERE name = NAME_IN;

      RETURN l_value;
   END number_value;
END get_magic_values;
/

BEGIN
   DBMS_OUTPUT.put_line (get_magic_values.varchar2_value ('Open status'));
   DBMS_OUTPUT.put_line (
      get_magic_values.date_value ('Earliest supported date')
   );
   DBMS_OUTPUT.put_line (get_magic_values.number_value ('Maximum salary'));
END;
/

CREATE OR REPLACE PROCEDURE gen_magic_values_package (
   pkg_name_in IN VARCHAR2 DEFAULT 'GET_MAGIC_VALUES'
 , hide_values_in_body_in IN BOOLEAN DEFAULT TRUE
 , dir_in IN VARCHAR2 DEFAULT NULL
 , ext_in IN VARCHAR2 DEFAULT 'pkg'
)
IS
   CURSOR values_cur
   IS
        SELECT *
          FROM magic_values
      ORDER BY identifier;


   l_code   DBMS_SQL.varchar2a;

   PROCEDURE pl (str IN VARCHAR2)
   IS
   BEGIN
      l_code (l_code.COUNT + 1) := str;
   END;

   PROCEDURE transfer_to_screen_or_file
   IS
      l_file   VARCHAR2 (1000) := pkg_name_in || '.' || ext_in;
   BEGIN
      IF dir_in IS NULL
      THEN
         FOR indx IN l_code.FIRST .. l_code.LAST
         LOOP
            DBMS_OUTPUT.put_line (l_code (indx));
         END LOOP;
      ELSE
         DECLARE
            fid   UTL_FILE.file_type;
         BEGIN
            fid := UTL_FILE.fopen (dir_in, l_file, 'W');

            FOR indx IN l_code.FIRST .. l_code.LAST
            LOOP
               UTL_FILE.put_line (fid, l_code (indx));
            END LOOP;

            UTL_FILE.fclose (fid);
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.put_line (
                  'Failure to write l_code to ' || dir_in || '/' || l_file
               );
               UTL_FILE.fclose (fid);
         END;
      END IF;
   END transfer_to_screen_or_file;
BEGIN
   /* Simple generator, based on DBMS_l_code. */
   pl ('CREATE OR REPLACE PACKAGE ' || pkg_name_in);
   pl ('IS ');

   FOR l_magic_value IN values_cur
   LOOP
      IF l_magic_value.description IS NOT NULL
      THEN
         pl ('/*');
         pl (l_magic_value.description);
         pl ('*/');
      END IF;

      IF hide_values_in_body_in
      THEN
         pl('FUNCTION ' || l_magic_value.identifier || ' RETURN '
            || NVL (l_magic_value.function_return_type
                  , l_magic_value.datatype
                   )
            || ';');
      ELSE
         pl(   l_magic_value.identifier
            || ' CONSTANT '
            || l_magic_value.datatype
            || ' := '
            || l_magic_value.VALUE
            || ';');
      END IF;
   END LOOP;

   pl ('END ' || pkg_name_in || ';');
   pl ('/');

   IF hide_values_in_body_in
   THEN
      pl ('CREATE OR REPLACE PACKAGE BODY ' || pkg_name_in);
      pl ('IS ');

      FOR l_magic_value IN values_cur
      LOOP
         pl('   FUNCTION ' || l_magic_value.identifier || ' RETURN '
            || NVL (l_magic_value.function_return_type
                  , l_magic_value.datatype
                   ));
         pl ('   IS BEGIN RETURN ' || l_magic_value.VALUE || '; END;');
         pl ('   ');
      END LOOP;

      pl ('END ' || pkg_name_in || ';');
      pl ('/');
   END IF;

   transfer_to_screen_or_file ();
END gen_magic_values_package;
/

/* 
Quick demo 
*/

BEGIN
   DELETE FROM magic_values;

   INSERT INTO magic_values 
       VALUES (
                  'Maximum salary'
                , 'You cannot earn more than this
in a single year.'
                , '10000000'
                , 'maximum_salary'
                , 'NUMBER'
                , NULL
              );

   INSERT INTO magic_values
       VALUES (
                  'Earliest supported date'
                , 'The application will not work with dates before this.'
                , 'ADD_MONTHS (SYSDATE, -60)'
                , 'minimum_date'
                , 'DATE'
                , NULL
              );

   INSERT INTO magic_values
       VALUES (
                  'Open status'
                , NULL
                , '''OPEN'''
                , 'open_status'
                , 'VARCHAR2(4)'
                , 'VARCHAR2'
              );

   COMMIT;
END;
/

BEGIN
   gen_magic_values_package ();
END;
/

BEGIN
   gen_magic_values_package (
      pkg_name_in => 'GET_MAGIC_VALUES'
    , hide_values_in_body_in => FALSE
    , dir_in => NULL
    , ext_in => NULL
   );
END;
/
