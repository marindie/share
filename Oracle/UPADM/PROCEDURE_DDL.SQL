-- 삭제한 PROCEDURE 리스트
--DAILY_LDAP_CUST_PERSON
--DELETE_CUST_PROF
--INIT_CUST_PROF_IMS
--INIT_LDAP_CUST
--INIT_LDAP_CUST_01
--INIT_LDAP_CUST_MODIFY
--INIT_LDAP_CUST_MODIFY02
--INIT_LDAP_TB_CUST_PROF_01
--INIT_LDAP_TB_CUST_PROF_02
--INIT_LDAP_TB_CUST_PROF_03
--INIT_LDAP_USER
--INSERT_CUST_PROF
--SP_BINUS_DOWN
--SP_CP_LDAP_CONN_REPORT
--TEMP_NISS
--TEST_CODE
--TEST_SYNCCHECK_REPORT
--UPDATE_CUST_PERSON
--UPDATE_CUST_PROF

  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_CUST_TIIS"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_CUST_TIIS
-- 기능 : UAProfiel DB와 다른 시스템(TIIS 등) 연동에서 초기화를 위한
--        SAM 파일생성(TB_CUST_PROF)
-- 변경력: 신규 (2005.04.26) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
CURSOR cur_get_data IS
	-- MMS H/S Menu 에서 사용하는 것
	SELECT        SVC_MNG_NUM
	    || '|' || DEVICE_MNG_NUM
	    || '|' || MOBILE_ID_NUM
	    || '|' || MOBILE_SVC_NUM
	    || '|' || UPDATE_CD
	    || '|' || NVL(TO_CHAR(UPDATE_DT , 'YYYYMMDDHH24MISS'), NULL) AS GET_DATA
	FROM TB_CUST_PROF  ;
    -- 임의로 300만건만

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_TIIS Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_uap_cust_tiis_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TIIS(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_uap_cust_tiis_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00'))|| '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TIIS(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TIIS(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TIIS(INIT)', 'D', substr(err_code,1,150) )
 ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TIIS(INIT)', 'D', substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TIIS(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_TIIS Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TIIS(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TIIS(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TIIS(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TIIS(INIT)', 'D', substr(err_code,1,150) ) ;

       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_PERSON_2"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : init_person_2
-- 기능 : UAProfiel DB와 IMS 연동(주민번호)에서 초기화를 위한
--        SAM 파일생성(TB_CUST_PERSON, TB_CUST_PROF)
-- 변경력: 신규 (2006.05.17) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
CURSOR cur_get_data IS
	SELECT            CUST.SVC_MNG_NUM
			|| '|' || NVL(PER.CUST_TP, '')
            || '|' || NVL(PER.CUST_ID, '') AS GET_DATA
	FROM TB_CUST_PERSON PER
       , TB_CUST_PROF CUST
    WHERE CUST.SVC_MNG_NUM = PER.SVC_MNG_NUM
    ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_PERSON_2 Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_person_2_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON_2(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_person_2_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON_2(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON_2(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON_2(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON_2(INIT)', 'D', substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON_2(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_PERSON_2 Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ]*****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON_2(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON_2(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON_2(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON_2(INIT)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_SAM_TBL"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_SAM_TBL
-- 기능 : 단순쿼리를 통해 원하는 Table의 전체정보를 다운 받는다.
-- 변경력: 신규 (2005.06.09) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    --- 테이블명 변경

    --v_table_name        VARCHAR(50):= 'TB_ADDED_SVC'  ;
    --v_table_name        VARCHAR(50):= 'TB_TEST_NUM'  ;
    v_table_name        VARCHAR(50):= 'TB_CUST_CHILD'  ;

-- --------------------------
CURSOR cur_get_data IS
        /*
		SELECT        added_svc_cd
		    || '|' || offset
		    || '|' || TO_CHAR(start_dt, 'YYYYMMDDHH24MISS')
		    || '|' || cp_sys_id
		    || '|' || cp_mng_cd
		    || '|' || svc_cp_tp
		    || '|' || added_svc_dsc
		    || '|' || added_svc_url
		    || '|' || added_svc_file_nm
		    || '|' || skt_nm
		    || '|' || skt_dept_nm
		    || '|' || skt_office
		    || '|' || skt_mobile
		    || '|' || added_svc_map_cd
		    || '|' || added_tp
		    || '|' || share_yn              AS GET_DATA
		FROM TB_ADDED_SVC
		ORDER BY OFFSET ;
        */

        /*
        SELECT        SVC_MNG_NUM
			|| '|' || REQ_ID
			|| '|' || EXEC_ID
			|| '|' || SVC_TP
			|| '|' || PURPOSE
			|| '|' || TO_CHAR(INIT_DT, 'YYYYMMDDHH24MISS')
			|| '|' || TO_CHAR(UPDATE_DT, 'YYYYMMDDHH24MISS')
			|| '|' || TO_CHAR(EXPIRE_DT, 'YYYYMMDDHH24MISS')
			|| '|' || REQ_NM
			|| '|' || CUST_ID
			|| '|' || ICAS_YN               AS GET_DATA
		from TB_TEST_NUM ;
        */

        SELECT        SVC_MNG_NUM
			|| '|' || CHILD_MOBILE_SVC_NUM
			|| '|' || EXEC_ID
			|| '|' || TO_CHAR(COIS_UPDATE_DT, 'YYYYMMDDHH24MISS')
			|| '|' || UPDATE_CD
			|| '|' || TO_CHAR(REG_DT, 'YYYYMMDDHH24MISS')
			|| '|' || REG_PATH              AS GET_DATA
		FROM TB_CUST_CHILD ;

        /*

        */

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ ' || v_table_name || ' Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_sam_' || v_table_name || '_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_sam_' || v_table_name || '_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                DBMS_OUTPUT.PUT_LINE( 'FOR[' || SUBSTR(err_code,1,150) || ']' );
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        DBMS_OUTPUT.PUT_LINE( 'FOR[' || SUBSTR(err_code,1,150) || ']' );

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        DBMS_OUTPUT.PUT_LINE( 'FOR[' || SUBSTR(err_code,1,150) || ']' );

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            DBMS_OUTPUT.PUT_LINE( 'FOR[' || SUBSTR(err_code,1,150) || ']' );

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================

-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ ' || v_table_name || ' Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			DBMS_OUTPUT.PUT_LINE( 'MAIN[' || SUBSTR(err_code,1,150) || ']' );

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			DBMS_OUTPUT.PUT_LINE( 'MAIN[' || SUBSTR(err_code,1,150) || ']' );

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			DBMS_OUTPUT.PUT_LINE( 'MAIN[' || SUBSTR(err_code,1,150) || ']' );

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			DBMS_OUTPUT.PUT_LINE( 'MAIN[' || SUBSTR(err_code,1,150) || ']' );
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_TB_UAP_ATTR"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_TB_UAP_ATTR
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 조기화를 위한
--        SAM 파일생성(TB_UAP_ATTR)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   CURSOR DEFINE  ( 206자리)
------------------------------
--   COMPO_CD           (  2)
--   SUB_COMPO_CD       (  4)
--   SUB_COMPO_NM       (200)
-- --------------------------
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_CD, '')
			|| '|' || NVL(ATTR_NM, '')
			|| '|' || NVL(NM_SPACE, '')
			|| '|' || NVL(DATA_TP, '')
			|| '|' || NVL(ATTR_TP, '') AS GET_DATA
	FROM TB_UAP_ATTR ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_UAP_ATTR Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_tb_uap_attr_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR(INIT)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_tb_uap_attr_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)

                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CD)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_UAP_ATTR Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')  || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
             error_cnt := error_cnt + 1;
             err_code  := SQLCODE || SQLERRM;
             INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
             VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
             error_cnt := error_cnt + 1;
             err_code  := SQLCODE || SQLERRM;
             INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
             VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
             error_cnt := error_cnt + 1;
             err_code  := SQLCODE || SQLERRM;
             INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
             VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_TB_UAP_ATTR_VAL"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_TB_UAP_ATTR_VAL
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 초기화를 위한
--        SAM 파일생성(TB_UAP_ATTR_VAL)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- ---------------------------------------------------------------------------
--
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   CURSOR DEFINE  ( 206자리)
------------------------------
--   COMPO_CD           (  2)
--   SUB_COMPO_CD       (  4)
--   SUB_COMPO_NM       (200)
-- --------------------------
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_CD, '')
			|| '|' || NVL(ATTR_NM, '')
			|| '|' || NVL(ATTR_VAL, '') AS GET_DATA
	FROM TB_UAP_ATTR_VAL;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_UAP_ATTR_VAL Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_tb_uap_attr_val_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_VAL(INIT)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_tb_uap_attr_val_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_VAL(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_VAL(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_VAL(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_VAL(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	      (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_VAL(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_UAP_ATTR_VAL Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_VAL(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_VAL(INIT)', 'D', SYSDATE, substr(err_code,1,300) );

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_VAL(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_VAL(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INSERT_TEST_DATA" ( cust_cnt IN NUMBER)
IS
	fetch_cnt   NUMBER := 0;
CURSOR cur_get_data IS
    SELECT PREV_MOBILE_SVC_NUM AS GET_DATA FROM tb_chg_plus WHERE rownum <= cust_cnt;

BEGIN
	while fetch_cnt < cust_cnt LOOP
	begin
		fetch_cnt := fetch_cnt + 1;

		INSERT INTO TB_PROC_RETRY
		(  TID
			, EXTEND_DT
			, JOB_CD
			, CP_MNG_CD
			, SVC_MNG_NUM
			, ADDED_SVC_CD
			, UPDATE_CD
			, EVENT_DT
			, RETRY_CNT
			, STATUS
			, REQ_DT, REQ_SEC
			, REP_DT, REP_SEC
			, RES_CD, RES_DSC_CD
			, MAP_YN
		)
		VALUES
		(  ltrim(to_char(fetch_cnt,'00000000000000000000'))
			, sysdate
			, '12'
			, '11101'
			, '8888888888'
			, 'VA99999999'
			, 'I3'
			, sysdate
			, 0
			, '1'
			, to_char(sysdate,'YYYYMMDDHH24MISS'), 0
			, to_char(sysdate,'YYYYMMDDHH24MISS'), 0
			, null, 0
			, 'N'
		);
	end;
    END LOOP;
   	begin
	fetch_cnt := fetch_cnt + 1;

	INSERT INTO TB_PROC_RETRY
	(  TID
		, EXTEND_DT
		, JOB_CD
		, CP_MNG_CD
		, SVC_MNG_NUM
		, ADDED_SVC_CD
		, UPDATE_CD
		, EVENT_DT
		, RETRY_CNT
		, STATUS
		, REQ_DT, REQ_SEC
		, REP_DT, REP_SEC
		, RES_CD, RES_DSC_CD
		, MAP_YN
	)
	VALUES
	(  ltrim(to_char(fetch_cnt,'00000000000000000000'))
		, sysdate
		, '12'
		, '11101'
		, '8888888888'
		, 'VA99999999'
		, 'I3'
		, sysdate-(30/1440)
		, 0
		, '0'
		, to_char(sysdate,'YYYYMMDDHH24MISS'), 0
		, to_char(sysdate,'YYYYMMDDHH24MISS'), 0
		, null, 0
		, 'N'
	);
	end;
	commit;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."CUST_SYNC" (
    v_file_num	IN		VARCHAR2
)
IS
	TYPE mdn IS TABLE OF tb_cust_prof.mobile_svc_num%TYPE
	INDEX BY BINARY_INTEGER;

	TYPE min IS TABLE OF tb_cust_prof.mobile_id_num%TYPE
	INDEX BY BINARY_INTEGER;

	TYPE imsi IS TABLE OF tb_cust_prof.imsi%TYPE
	INDEX BY BINARY_INTEGER;

	TYPE client_id_yn IS TABLE OF tb_cust_prof.client_id_yn%TYPE
	INDEX BY BINARY_INTEGER;

	TYPE net_gen_tp IS TABLE OF tb_cust_prof.net_gen_tp%TYPE
	INDEX BY BINARY_INTEGER;

	TYPE svc_mng_num IS TABLE OF tb_cust_prof.svc_mng_num%TYPE
	INDEX BY BINARY_INTEGER;

	TYPE svc_tp IS TABLE OF tb_cust_prof.svc_tp%TYPE
	INDEX BY BINARY_INTEGER;

	TYPE charge_cd IS TABLE OF tb_cust_person.charge_cd%TYPE
	INDEX BY BINARY_INTEGER;

	TYPE cust_tp IS TABLE OF tb_cust_person.cust_tp%TYPE
	INDEX BY BINARY_INTEGER;

	TYPE child_mobile_svc_num IS TABLE OF tb_cust_child.child_mobile_svc_num%TYPE
	INDEX BY BINARY_INTEGER;

	i_start_num		VARCHAR2(10);
	i_end_num		VARCHAR2(10);

	i_pormat		VARCHAR2(100);

	err_code		VARCHAR2(500);

	sync_mdn			mdn;
	sync_min			min;
	sync_imsi			imsi;
	sync_client_id_yn		client_id_yn;
	sync_net_gen_tp			net_gen_tp;
	sync_svc_mng_num		svc_mng_num;
	sync_svc_tp			svc_tp;
	sync_charge_cd			charge_cd;
	sync_cust_tp			cust_tp;
	sync_child_mobile_svc_num	child_mobile_svc_num;

-- ----------------------------------------------------------------------
-- COUNT0|7C :/<v <1>p
-- ----------------------------------------------------------------------
	i BINARY_INTEGER	:= 0;	/* File ;}<:=C count */

	cust_sync_filedir	VARCHAR2(100) := '/data/ftp/cust';
	cust_sync_filename	VARCHAR2(50)  := 'cust_sync';
	cust_sync_filetype	UTL_FILE.FILE_TYPE;

	l_start NUMBER DEFAULT DBMS_UTILITY.GET_TIME;


BEGIN
	DBMS_OUTPUT.ENABLE (1000000);

	err_code := 'STEP1.';

	IF (v_file_num=1) THEN
		i_start_num := '1000000000';
		i_end_num := '1099999999';
	ELSIF (v_file_num=2) THEN
		i_start_num := '1100000000';
		i_end_num := '119999999';
	ELSIF (v_file_num=3) THEN
		i_start_num := '1200000000';
		i_end_num := '1299999999';
	ELSIF (v_file_num=4) THEN
		i_start_num := '1300000000';
		i_end_num := '1399999999';
	ELSIF (v_file_num=5) THEN
		i_start_num := '1400000000';
		i_end_num := '1499999999';
	ELSIF (v_file_num=6) THEN
		i_start_num := '1500000000';
		i_end_num := '1599999999';
	ELSIF (v_file_num=7) THEN
		i_start_num := '1600000000';
		i_end_num := '1699999999';
	ELSIF (v_file_num=8) THEN
		i_start_num := '1700000000';
		i_end_num := '1799999999';
	ELSIF (v_file_num=9) THEN
		i_start_num := '1800000000';
		i_end_num := '1899999999';
	ELSIF (v_file_num=10) THEN
		i_start_num := '1900000000';
		i_end_num := '1999999999';
	ELSIF (v_file_num=11) THEN
		i_start_num := '7000000000';
		i_end_num := '7099999999';
	ELSIF (v_file_num=12) THEN
		i_start_num := '8000000000';
		i_end_num := '8099999999';
	END IF;
	err_code := 'STEP2.';

	FOR cust_sync IN ( SELECT /*+ all_rows */  a.svc_mng_num, a.mobile_id_num, a.imsi, a.client_id_yn, a.net_gen_tp, a.svc_tp, a.mobile_svc_num,
				b.charge_cd, b.cust_tp,c.child_mobile_svc_num
			    FROM tb_cust_prof a, tb_cust_person b, tb_cust_child c
			    WHERE a.svc_mng_num=b.svc_mng_num
			    AND b.svc_mng_num=c.svc_mng_num(+)
			    AND a.SVC_MNG_NUM between i_start_num AND i_end_num
			    )
	LOOP

		i := i +1;

		sync_svc_mng_num(i)		:= cust_sync.svc_mng_num;
		sync_min(i)			:= cust_sync.mobile_id_num;
		sync_mdn(i)			:= cust_sync.mobile_svc_num;
		sync_imsi(i)			:= cust_sync.imsi;
		sync_client_id_yn(i)		:= cust_sync.client_id_yn;
		sync_net_gen_tp(i)		:= cust_sync.net_gen_tp;
		sync_svc_tp(i)			:= cust_sync.svc_tp;
		sync_charge_cd(i)		:= cust_sync.charge_cd;
		sync_cust_tp(i)			:= cust_sync.cust_tp;
		sync_child_mobile_svc_num(i)	:= cust_sync.child_mobile_svc_num;



		IF sync_min(i) IS NULL THEN
			sync_min(i) := '0000000000';
		END IF;

		IF sync_mdn(i) IS NULL THEN
			sync_mdn(i) := '00000000000';
		END IF;

		IF sync_imsi(i) IS NULL THEN
			sync_imsi(i) := '000000000000000';
		END IF;

		IF sync_client_id_yn(i) IS NULL THEN
			sync_client_id_yn(i) := '0';
		END IF;

		IF sync_net_gen_tp(i) IS NULL THEN
			sync_net_gen_tp(i) := '0';
		ELSE
			IF (sync_net_gen_tp(i) = '2') THEN
				sync_net_gen_tp(i) := 'D';
			ELSIF (sync_net_gen_tp(i) = '3') OR (sync_net_gen_tp(i) = 'D') THEN
				sync_net_gen_tp(i) := 'W';
			END IF;
		END IF;

		IF sync_svc_mng_num(i) IS NULL THEN
			sync_svc_mng_num(i) := '0000000000';
		END IF;

		IF sync_svc_tp(i) IS NULL THEN
			sync_svc_tp(i) := '00';
		END IF;

		IF sync_charge_cd(i) IS NULL THEN
			sync_charge_cd(i) := '0000000000';
		END IF;

		IF sync_cust_tp(i) IS NULL THEN
			sync_cust_tp(i) := '00';
		END IF;

		IF sync_child_mobile_svc_num(i) IS NULL THEN
			sync_child_mobile_svc_num(i) := '00000000000';
		END IF;


	EXIT WHEN sync_svc_mng_num(i) IS NULL;

	END LOOP;
	err_code := 'STEP3.';

	cust_sync_filename := cust_sync_filename;

	cust_sync_filetype := UTL_FILE.FOPEN(cust_sync_filedir, cust_sync_filename||v_file_num||'.dat', 'w');

	FOR cnt IN 1..i
	LOOP


		i_pormat := sync_mdn(cnt)||','||sync_min(cnt)||','||sync_imsi(cnt)||','||sync_client_id_yn(cnt)||','||
				sync_net_gen_tp(cnt)||','||sync_svc_tp(cnt)||','||sync_svc_mng_num(cnt)||','
||sync_charge_cd(cnt)||','||
				sync_cust_tp(cnt)||','||sync_child_mobile_svc_num(cnt);

		UTL_FILE.PUT_LINE(cust_sync_filetype,i_pormat);


	END LOOP;

	UTL_FILE.FCLOSE(cust_sync_filetype);
	err_code := 'STEP4.';
	DBMS_OUTPUT.PUT_LINE(i||'6s@N Cb7B ?O7a');

	DBMS_OUTPUT.PUT_LINE(ROUND((DBMS_UTILITY.GET_TIME - l_start)/100,2) || 'sec');

EXCEPTION
	WHEN OTHERS THEN
		err_code := err_code||'['||SQLERRM||']';
		DBMS_OUTPUT.PUT_LINE('[?!7/]' || err_code );
		UTL_FILE.FCLOSE_ALL;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_V_ADDED_SVC"
IS
-- -----------------------------------------------------------------------------
-- Procedure : init_v_added_svc
-- Discreption : 버추얼 옵션을 가진 부가서비스들을 NGM 변경 Format에 맞추어 파일을
--               생성 일괄적으로 처리할 수 있도록함
--               선행작업으로 참고용 Mapping 테이블(NGM_ADDED_SVC_MAP)에 최신 정보를 넣어서 처리
-- History: (2006.08.11) - complues -
--          신규
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------

-- Result Count
-- -----------------------------------------------------------------------------
	read_cnt    NUMBER := 0;
	write_cnt   NUMBER := 0;
	fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);

-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- --    utl_file_dir='/ftp/ftp'
	file_seq    NUMBER := 1;
	sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
	sam_data_filename   VARCHAR2(50)  := '';
	sam_data_filetype   utl_file.file_type;

-- -------------------------- /*+ INDEX(SVC PK_CUST_ADDED_SVC ) */
CURSOR cur_get_data IS
    SELECT            SVC_MNG_NUM
			|| '|' || ADDED_SVC_CD
			|| '|' || 'I2'
			|| '|' || NVL(EXEC_ID , '' )
			|| '|' || NVL(TO_CHAR(REG_DT , 'YYYYMMDDHH24MISS'), TO_CHAR(SYSDATE , 'YYYYMMDDHH24MISS'))
			|| '|' || NVL(REG_PATH , '' )
			|| '|' || NVL(TO_CHAR(COIS_UPDATE_DT , 'YYYYMMDDHH24MISS'), TO_CHAR(SYSDATE , 'YYYYMMDDHH24MISS'))
            AS GET_DATA
	FROM
		TB_CUST_ADDED_SVC
	WHERE ADDED_SVC_CD IN (  /* 이부분에 리스트 입력 */
							 'VA000DMJMA'
							,'VA000CMDLV'
							,'VA000DMRSV'
							,'VA000DMU10'
							,'VA000VMDLV'
							,'VA000DMS80'
							,'VA000DMS50'
							,'VA000DMS5F'
							,'VA000DALLL'
							,'VA000VPAXN'
							,'VA000VPNCD'
							,'VA000VCIVM'
							,'VA000VWLPN'
							,'VA000VADLT'
							,'VA000VCPCY'
							,'VA000DBMNO'
							,'VA000DMS81'
                            )
    ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_V_ADDED_SVC Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'add_added_svc.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA );
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
  	    COMMIT;
        END;
    END LOOP Process_Loop;
    << end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ init_v_added_svc Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN DUP_VAL_ON_INDEX THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN TOO_MANY_ROWS THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN OTHERS THEN
	     error_cnt := error_cnt + 1;
	     DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_TB_UAP_ATTR_VAL" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_TB_UAP_ATTR_VAL
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 일일 대사를 위해
--        SAM 파일생성(TB_UAP_ATTR_VAL)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- --------------------------------------------------------------------------
---
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   CURSOR DEFINE  ( 206자리)
------------------------------
--   COMPO_CD           (  2)
--   SUB_COMPO_CD       (  4)
--   SUB_COMPO_NM       (200)
-- --------------------------
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_CD, '')
			|| '|' || NVL(ATTR_NM, '')
			|| '|' || NVL(ATTR_VAL, '') AS GET_DATA
	FROM TB_UAP_ATTR_VAL;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP_ATTR_VAL Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_tb_uap_attr_val_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       ( SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_VAL(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'daily_tb_uap_attr_val_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_VAL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_VAL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_VAL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_VAL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_VAL(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP_ATTR_VAL Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_VAL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_VAL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_VAL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_VAL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_TB_UAP_DEL" (
        I_Work_dt               IN DATE DEFAULT SYSDATE
)
IS


    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);

-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    log_cnt     NUMBER := 0;
    day                 VARCHAR2(2) := '';

    v_Get_Data       DBMS_SQL.Varchar2_Table   ;

    N_CURSOR    INTEGER;
    N_RET       INTEGER;
    SQL_TEXT    VARCHAR2(2000);

    fetch_size          NUMBER := 1000 ;
    indx                NUMBER := 1 ;
    v_temp_cnt          NUMBER ;
    v_RecCnt            NUMBER ;

CURSOR cur_get_data IS
        SELECT DEVICE_MNG_NUM AS GET_DATA
        FROM TB_UAP_CHANGE
        WHERE REG_DT >= TRUNC( I_Work_dt - 1 )
          AND REG_DT <  TRUNC( I_Work_dt )
          AND TBL_CD IN ('20', '21')
          AND CHANGE_TP = 'D' ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP_DEL Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_tb_uap_del_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
               (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_DEL(DAILY)', 'S', SYSDATE, 0, 0,0) ;

    COMMIT;

    << Base_Loop >>
    FOR c1 IN cur_get_data LOOP
    BEGIN

        read_cnt := read_cnt + 1;

        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA );

            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;

                        if fetch_cnt = 1000000 then
                            file_seq  := file_seq + 1;
                            fetch_cnt := 0;
                                utl_file.fclose(sam_data_filetype);
                                select 'daily_tb_uap_del_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
                                into    sam_data_filename
                                from    dual ;
                                sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

                        end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_DEL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_DEL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_DEL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;


            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_DEL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;


            COMMIT;
        END;

    END;

    << end_loop >>
    NULL;
    END LOOP Base_Loop;

    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_DEL(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;

        COMMIT;

    utl_file.fclose(sam_data_filetype);


        SELECT NVL(COUNT(*),0) INTO log_cnt FROM GAEBAL_UPADM.TB_JOB_LOG
        WHERE TO_CHAR(RUN_DT, 'YYYYMMDD') = TO_CHAR(SYSDATE, 'YYYYMMDD')
        AND STATUS = 'E' AND PROGRAM LIKE '%DAILY_TB_%';


    SELECT TO_CHAR(SYSDATE,'dd')
        INTO day
    FROM dual;

    if (day = 5 or day = 25) then
            if log_cnt = 9 then
                        select 'daliy_dev_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '_XX.log'
                        into    sam_data_filename
                        from    dual ;
                    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
                    utl_file.fclose(sam_data_filetype);
            end if;
    else
            if log_cnt = 8 then
                        select 'daliy_dev_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '_XX.log'

                        into    sam_data_filename
                        from    dual ;
                    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
                    utl_file.fclose(sam_data_filetype);
            end if;
    end if;

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP_DEL Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');

EXCEPTION
       WHEN NO_DATA_FOUND THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_DEL(DAILY)','D', SYSDATE, substr(err_code,1,300) ) ;


       WHEN DUP_VAL_ON_INDEX THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT,ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_DEL(DAILY)','D', SYSDATE, substr(err_code,1,300) ) ;


       WHEN TOO_MANY_ROWS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_DEL(DAILY)','D', SYSDATE, substr(err_code,1,300) );


       WHEN OTHERS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_DEL(DAILY)','D', SYSDATE, substr(err_code,1,300) ) ;

       COMMIT;

END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_UAP_NIBS" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_UAP_NIBS
-- 기능 : UAProfiel DB와 NIBS 연동에서 일일 대사를 위해 SAM 파일생성(TB_COMPO)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------

-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
/* UA단말정보중 WAP단말기(WAP가능인가?) 의 URI적용단말과
   모든 단말정보의 정보를 추출
   기본적으로 URI를 갖는 단말은 모델상세를 갖지 않는다. 하지만
   Admin페이지에서 확인하기 위한정보로 모델상세를 갖지만 실제적인 모델상세정보는

   Attribute List에서 추출한다. */
CURSOR cur_get_data IS
	SELECT         DEV.DEVICE_MNG_NUM,
	               NVL(TRIM(DEV.URI             ), ' ')
	     || ',' || NVL(TRIM(DEV.PDA_YN          ), 'N')
		 || ',' || NVL(TRIM(DEV.UAF_DEVICE_MANUF), ' ')
		 || ',' || NVL(TRIM(DEV.UAF_DEVICE_MODEL), ' ')
		 || ',' || NVL(TRIM(DEV.COIS_DEVICE_CD  ), ' ')
		 --|| ',' || NVL(TRIM(DEV.COIS_DEVICE_VER ), ' ')
		 || ',' || NVL(TRIM(M.ATTR_VAL          ), ' ') AS GET_DATA
	FROM  (  SELECT DEVICE_MNG_NUM, COMPO_CD, SUB_COMPO_CD, ATTR_NM, ATTR_VAL
			FROM TB_UAP_ATTR_LIST
			WHERE COMPO_CD = 'HW'
			AND SUB_COMPO_CD = ' '
			AND ATTR_NM = 'Model'
		  ) M ,
	     (  SELECT *
	        FROM TB_UAP
	        WHERE UAP_YN = 'Y'
	        OR DEVICE_MNG_NUM IN (
		     	SELECT DEVICE_MNG_NUM
				FROM TB_UAP_ATTR_LIST
				WHERE ATTR_NM = 'BrowserVersion'
				AND ATTR_VAL > '0.9'
				MINUS
				SELECT DEVICE_MNG_NUM
				FROM TB_UAP_ATTR_LIST
				WHERE ATTR_NM = 'BrowserName'
				AND ATTR_VAL = 'UP'
				)
		  ) DEV
	WHERE DEV.DEVICE_MNG_NUM = M.DEVICE_MNG_NUM (+) ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_UAP_NIBS Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_uap_nibs_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'

    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES ( SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_NIBS(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'daily_uap_nibs_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_NIBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_NIBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_NIBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) );

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_NIBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_NIBS(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_UAP_NIBS Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_NIBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_NIBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_NIBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;


       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_NIBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_ADDED_UP_DOWN" (
	 I_Svc_Mng_Num	           IN     TB_CUST_ADDED_SVC.SVC_MNG_NUM%TYPE
	,I_Added_Svc_Cd            IN     TB_CUST_ADDED_SVC.ADDED_SVC_CD%TYPE
	,I_Reg_Dt                  IN     TB_CUST_ADDED_SVC.REG_DT%TYPE
	,I_Exec_Id                 IN     TB_CUST_ADDED_SVC.EXEC_ID%TYPE
	,I_Flag                    IN     VARCHAR2
	,O_Res_Cd                  OUT    VARCHAR2
	--,O_Res_Msg                 OUT    VARCHAR2
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : SP_ADDED_UP_DOWN
-- 기능 : 부가서비스 처리가 안 되었을 경우 호출하여
--        안영되지 않은 고객의 부가서비스정보를 반영한다.
--        입력값:
--               1:서비스관리 번호, 2:부가서비스코드, 3:날짜 4:등록경로, 5:구분 플래그(U:업데이트 D:다운로드)
--        출력값:
--               1:처리코드(정상 : 00 비정상: 00 이외의 값 )
--
-- 변경력: 2003. 12. 24
-- 		1. 신규 생성 - compleus -
-- -----------------------------------------------------------------------------
    ERR_MSG             VARCHAR2(150) ;
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------

-- 단수 참조에서 사용되는 변수
-- -----------------------------------------------------------------------------

    v_Exist_cnt         NUMBER ;
    v_Prg_Nm			VARCHAR2(8) := 'SP_ADDED' ;
-- -----------------------------------------------------------------------------
-- 처리에 사용되 변수
-- -----------------------------------------------------------------------------
BEGIN
	ERR_MSG := '최초 Procedure' ;
	O_Res_Cd := '99' ;

	DBMS_OUTPUT.ENABLE ( 1000000);
	DBMS_OUTPUT.PUT_LINE( '***** [ TB_CUST_ADDED_SVC Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
	-- 기본 입력값 체크
	BEGIN
		-- 길이
		IF LENGTH(I_Svc_Mng_Num) <> 10 THEN
			ERR_MSG := '서비스관리번호의 길이에 문제가 있습니다.' ;
			O_Res_Cd := '11' ;
			--O_Res_Msg := ERR_MSG ;
			RETURN ;
	    END IF ;

	    -- 특수문자 체크
	    IF INSTR(I_Svc_Mng_Num, CHR(0) ) > 0  OR
	       INSTR(I_Svc_Mng_Num, CHR(10) ) > 0  THEN
			ERR_MSG := '서비스관리번호의 값에 유효하지 않은 문자가 있습니다.' ;
			O_Res_Cd := '12' ;
			--O_Res_Msg := ERR_MSG ;
			RETURN ;
	    END IF ;

		IF LENGTH(I_Added_Svc_Cd) <> 5 THEN
			ERR_MSG := '부가서비스코드 길이에 문제가 있습니다.' ;
			O_Res_Cd := '13' ;
			--O_Res_Msg := ERR_MSG ;
			RETURN ;
	    END IF ;

	    -- 특수문자 체크
	    IF INSTR(I_Added_Svc_Cd, CHR(0) ) > 0  OR
	       INSTR(I_Added_Svc_Cd, CHR(10) ) > 0  THEN
			ERR_MSG := '부가서비스코드 값에 유효하지 않은 문자가 있습니다.' ;
			O_Res_Cd := '14' ;
			--O_Res_Msg := ERR_MSG ;
			RETURN ;
	    END IF ;

		IF LENGTH(I_Exec_Id) > 8 THEN
			ERR_MSG := '처리자 길이에 문제가 있습니다.' ;
			O_Res_Cd := '15' ;
			--O_Res_Msg := ERR_MSG ;
			RETURN ;
	    END IF ;

	    -- 특수문자 체크
	    IF INSTR(I_Exec_Id, CHR(0) ) > 0  OR
	       INSTR(I_Exec_Id, CHR(10) ) > 0  THEN
			ERR_MSG := '처리자 값에 유효하지 않은 문자가 있습니다.' ;
			O_Res_Cd := '16' ;
			--O_Res_Msg := ERR_MSG ;
			RETURN ;
	    END IF ;

		IF LENGTH(I_Flag) <> 1 THEN
			ERR_MSG := '입력플래그 길이에 문제가 있습니다.' ;
			O_Res_Cd := '17' ;
			--O_Res_Msg := ERR_MSG ;
			RETURN ;
	    END IF ;

	    -- 특수문자 체크
	    IF INSTR(I_Flag, CHR(0) ) > 0  OR
	       INSTR(I_Flag, CHR(10) ) > 0  THEN
			ERR_MSG := '입력플래그 값에 유효하지 않은 문자가 있습니다.' ;
			O_Res_Cd := '18' ;
			--O_Res_Msg := ERR_MSG ;
			RETURN ;
	    END IF ;

	    IF I_Flag = 'U' OR
	       I_Flag = 'D' THEN
			NULL ;
		ELSE
			ERR_MSG := '입력플래그는 U또는 D입니다.' ;
			O_Res_Cd := '19' ;
			--O_Res_Msg := ERR_MSG ;
			RETURN ;
	    END IF ;
	EXCEPTION
		WHEN OTHERS THEN
			ERR_MSG  := '입력값 체크중 문제가 발생하였습니다.' ;
			O_Res_Cd := '10' ;
			--O_Res_Msg := ERR_MSG ;
			RETURN ;
	END ;

	-- 플래그 값에 따른 처리
	IF I_Flag = 'U' THEN
		-- 기존 데이터 체크(고객 데이터)
		v_Exist_cnt := 0 ;
		BEGIN
			SELECT COUNT(*) INTO v_Exist_cnt

			FROM TB_CUST_PROF
			WHERE SVC_MNG_NUM = I_Svc_Mng_Num ;

			IF v_Exist_cnt = 0 THEN
				ERR_MSG  := '등록할 고객이 존재하지 않습니다.' ;
				O_Res_Cd := '21' ;
				--O_Res_Msg := ERR_MSG ;
				RETURN ;
			END IF ;

			v_Exist_cnt := 0 ;

			-- 부가서비스 확인
			SELECT COUNT(*) INTO v_Exist_cnt
			FROM TB_ADDED_SVC
			WHERE ADDED_SVC_CD = I_Added_Svc_Cd ;

			IF v_Exist_cnt = 0 THEN
				ERR_MSG  := '부가서비스코드가 존재하지 않습니다.' ;
				O_Res_Cd := '22' ;
				--O_Res_Msg := ERR_MSG ;
				RETURN ;
			END IF ;

			-- 기존 부가서비스 등록 확인
			SELECT COUNT(*) INTO v_Exist_cnt
			FROM TB_CUST_ADDED_SVC
			WHERE SVC_MNG_NUM = I_Svc_Mng_Num
			AND ADDED_SVC_CD = I_Added_Svc_Cd ;

			IF v_Exist_cnt = 0 THEN
				ERR_MSG  := '부가서비스 등록 에러' ;
				O_Res_Cd := '28' ;

				INSERT INTO TB_CUST_ADDED_SVC
				VALUES (
					 I_Svc_Mng_Num
				   , I_Added_Svc_Cd
				   , 'I2'
				   , v_Prg_Nm
				   , I_Reg_Dt
				   , I_Exec_Id
				   , I_Reg_Dt
				   ) ;

			ELSE
				ERR_MSG  := '부가서비스 업데이트 에러' ;
				O_Res_Cd := '23' ;

				UPDATE TB_CUST_ADDED_SVC
				SET EXEC_ID = v_Prg_Nm
				   ,REG_DT = I_Reg_Dt
				   ,REG_PATH = I_Exec_Id
				   ,COIS_UPDATE_DT = I_Reg_Dt
				WHERE SVC_MNG_NUM = I_Svc_Mng_Num
				AND ADDED_SVC_CD = I_Added_Svc_Cd ;

			END IF ;

		EXCEPTION
			WHEN OTHERS THEN
				ROLLBACK ;
				ERR_MSG := ERR_MSG || '[' || SUBSTR(SQLERRM,1,200) || ']';
				O_Res_Cd := '98' ;
				--O_Res_Msg := ERR_MSG ;
				DBMS_OUTPUT.PUT_LINE( TRIM(SUBSTR(ERR_MSG,1, 50)) || ':[' || SUBSTR(SQLERRM,1,200) || ']');

				RETURN ;
		END ;

	ELSE
		-- 기존 데이터 체크(부가 서비스)
		v_Exist_cnt := 0 ;

		SELECT COUNT(*) INTO v_Exist_cnt
		FROM TB_CUST_ADDED_SVC
		WHERE SVC_MNG_NUM = I_Svc_Mng_Num
		AND ADDED_SVC_CD = I_Added_Svc_Cd ;

		IF v_Exist_cnt = 0 THEN
			ERR_MSG  := '삭제할 부가서비스에 등록되어 있지 않습니다.' ;
			O_Res_Cd := '24' ;
			--O_Res_Msg := ERR_MSG ;
			RETURN ;
		END IF ;

		BEGIN
			ERR_MSG  := '부가서비스이력 등록 에러' ;
			O_Res_Cd := '25' ;

			INSERT INTO TB_CUST_ADDED_SVC_HIST
			SELECT
				 SVC_MNG_NUM
			   , ADDED_SVC_CD
			   , REG_DT										-- START
			   , I_Reg_Dt									-- END
			   , REG_CD
			   , EXEC_ID
			   , REG_DT
			   , REG_PATH
			   , COIS_UPDATE_DT
			FROM TB_CUST_ADDED_SVC
			WHERE SVC_MNG_NUM = I_Svc_Mng_Num
			AND ADDED_SVC_CD = I_Added_Svc_Cd ;


			ERR_MSG  := '부가서비스이력 등록 에러' ;
			O_Res_Cd := '26' ;

			INSERT INTO TB_CUST_ADDED_SVC_HIST
			VALUES(
				 I_Svc_Mng_Num
			   , I_Added_Svc_Cd
			   , I_Reg_Dt		-- START
			   , I_Reg_Dt		-- END
			   , 'I3'
			   , v_Prg_Nm
			   , I_Reg_Dt
			   , I_Exec_Id
			   , I_Reg_Dt
			   ) ;


			ERR_MSG  := '부가서비스 삭제 에러' ;
			O_Res_Cd := '27' ;

			DELETE FROM TB_CUST_ADDED_SVC
			WHERE SVC_MNG_NUM = I_Svc_Mng_Num
			AND ADDED_SVC_CD = I_Added_Svc_Cd ;

		EXCEPTION
			WHEN OTHERS THEN
				ROLLBACK ;
				ERR_MSG := ERR_MSG || '[' || SUBSTR(SQLERRM,1,200) || ']';
				--O_Res_Msg := ERR_MSG ;
				DBMS_OUTPUT.PUT_LINE( TRIM(SUBSTR(ERR_MSG,1, 50)) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
				RETURN ;
		END ;

	END IF ;

	-- 한서비스관리 번호의 작업이 정상적일 때만 정보 저장
	-- COMMIT ; -- 호출한 사용자가 Transaction을 처리!!
	DBMS_OUTPUT.PUT_LINE( '***** [ TB_CUST_ADDED_SVC Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');

    O_Res_Cd := '00' ;
    --O_Res_Msg := ''  ;
EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK ;
		ERR_MSG := ERR_MSG || '[' || SUBSTR(SQLERRM,1,200) || ']';
		O_Res_Cd := '99' ;
		--O_Res_Msg := ERR_MSG ;
		DBMS_OUTPUT.PUT_LINE( TRIM(SUBSTR(ERR_MSG,1, 50)) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_COIS_CODE_NOMODEL" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_COIS_CODE_NOMODEL
-- 기능 : UAProfile 에서 cois code는 있으나 단말 정보가 없어 no_model로 나오는 정보 추출
-- 변경력: 신규 (2009.7.31) : - stoneviruss -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    VARCHAR2(200);
-- -- --------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- --------------------------------------------------------------------------

-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'

    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    log_cnt     NUMBER := 0;

-- ------------------------------------------------------
CURSOR cur_get_data IS
	SELECT COIS_DEVICE_CD||'|'||COIS_DEVICE_VER||'|'||DEVICE_MNG_NUM || '|' || to_char(update_dt,'YYYYMMDDHH24MISS') AS GET_DATA
	FROM TB_UAP
	WHERE UAF_DEVICE_MODEL IS NULL
	AND URI IS NULL
	AND UPDATE_DT >= TRUNC( I_Work_dt - 1 )
	AND UPDATE_DT <  TRUNC( I_Work_dt );

-- ====================
--  Main Process Start
-- ====================
BEGIN -- 1.

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_COIS_CODE_NOMODEL Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');

-- FILE OPEN
    SELECT 'daily_coid_code_nomodel_' || TO_CHAR(I_Work_dt, 'YYYYMMDD') || '.dat'
    INTO    sam_data_filename
    FROM    dual ;

    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_COIS_CODE_NOMODEL(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP -- 2.
    BEGIN  -- 3.

  --  읽은 DATA Count
        read_cnt := read_cnt + 1;

  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN -- 4.
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
			write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_COIS_CODE_NOMODEL(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_COIS_CODE_NOMODEL(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;

   	   COMMIT;
        END; -- 4.
    END; -- 3.
    << end_loop >>
    NULL;
    END LOOP; -- 2.

-- ===============================================================
-- End Cursor Loop

-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_COIS_CODE_NOMODEL(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_COIS_CODE_NOMODEL END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');

EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_COIS_CODE_NOMODEL(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_COIS_CODE_NOMODEL(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;
       COMMIT;

END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_CUST_PPG" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_CUST_PPG
-- 기능 : UAProfiel DB와 PPG 연동에서 처리할 일일대사용 SAM 파일생성(TB_CUST_PROF)
-- 변경력: 신규 (2003.12.17) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
/* 각각의 PPG임을 알기 위해 각 정보들을 초회하여 처리하되
   가장 많은 정보를 기준( 모든 PPG정보는 application/x-cmf 를 갖음)
   으로 하되 그기준을 i-Touch폰과 합하게 기준으로 잡는다.
   제약 조건으로는 i-Touch와 PPG폰은 서로 배타적인 관계여야 한다. */
CURSOR cur_get_data IS
	SELECT        SKT.SVC_MNG_NUM
	    || '|' || SKT.MOBILE_ID_NUM
	    || '|' || SKT.MOBILE_SVC_NUM
	    || '|' || SKT.NET_GEN_TP
	    || '|' || SKT.CLIENT_ID_YN
	    || '|' || SKT.CLIENT_ID_NET2G
	    || '|' || SKT.CLIENT_ID_NET3G
	    || '|' || SKT.CLIENT_ID_CUST
	    || '|' || SKT.IMSI
	    || '|' || DEV.PPG_SVC
	    || '|' || SKT.UPDATE_CD
	    || '|' || NVL(TO_CHAR(SKT.UPDATE_DT , 'YYYYMMDDHH24MISS'), NULL) AS GET_DATA
	FROM ( SELECT H.SVC_MNG_NUM, H.DEVICE_MNG_NUM, H.MOBILE_ID_NUM, H.MOBILE_SVC_NUM, H.NET_GEN_TP, H.CLIENT_ID_YN, H.CLIENT_ID_NET2G, H.CLIENT_ID_NET3G, H.CLIENT_ID_CUST, H.IMSI, H.UPDATE_CD, H.UPDATE_DT
		   FROM TB_CUST_PROF_HIST H
		   WHERE H.END_DT >= TRUNC( I_Work_dt - 1) -- ONE DAY DATA
		   AND   H.END_DT <  TRUNC( I_Work_dt )
		   AND   H.UPDATE_CD IN ( 'Z1', 'Z2')
       AND   H.MVNO_CD = '0'   -- 2011.07.15 COLUS3 - MVNO사업자 구분코드가 '0'(SKT)인 데이터만 추출
		   AND  NOT EXISTS (
		   		SELECT 'X'
		   		FROM TB_CUST_PROF S
		   		WHERE S.SVC_MNG_NUM = H.SVC_MNG_NUM
		   		)
		   UNION
	       SELECT SVC_MNG_NUM, DEVICE_MNG_NUM, MOBILE_ID_NUM, MOBILE_SVC_NUM, NET_GEN_TP, CLIENT_ID_YN, CLIENT_ID_NET2G, CLIENT_ID_NET3G, CLIENT_ID_CUST, IMSI, UPDATE_CD, UPDATE_DT
		   FROM TB_CUST_PROF
		   WHERE UPDATE_DT >= TRUNC( I_Work_dt - 1) -- ONE DAY DATA
		   AND   UPDATE_DT <  TRUNC( I_Work_dt )
       AND   MVNO_CD = '0'   -- 2011.07.15 COLUS3 - MVNO사업자 구분코드가 '0'(SKT)인 데이터만 추출
       ) SKT ,
		 (select  p3.device_mng_num
		       ,decode(
		             decode(p1.device_mng_num,null ,'0','1')
		           ||decode(p2.device_mng_num,null ,'0','1')
		           ||decode(p3.device_mng_num,null ,'0','1')
		           ||decode(p4.device_mng_num,null ,'0','1')
		           ||decode(p5.device_mng_num,null ,'0','1')
		           ||decode(p6.device_mng_num,null ,'0','1') , '111000', '1', '111100', '2', '001111', '3', '9' ) as PPG_SVC
		from
			(select device_mng_num, attr_val
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'text/vnd.wap.si' ) p1,
			(select device_mng_num, attr_val
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'application/vnd.wap.sic' ) p2,
			(select device_mng_num, attr_val, null
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'application/x-cmf'
			union
			select  p1.device_mng_num, null, '9'
			from
				(select device_mng_num, attr_val
				from tb_uap_attr_list
				where compo_cd = 'BR'
				and sub_compo_cd = ' '
				and attr_nm = 'BrowserName'
				and trim(attr_val) = 'UP' ) p1,
				(select device_mng_num, attr_val
				from tb_uap_attr_list
				where compo_cd = 'BR'
				and sub_compo_cd = ' '
				and attr_nm = 'BrowerVersion'
				and trim(attr_val) = '1.0' ) p2
			where p1.device_mng_num = p2.device_mng_num  ) p3,
			(select device_mng_num, attr_val
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'text/vnd.wap.wml'  ) p4,
			(select device_mng_num, attr_val
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'application/xhtml+xml'  ) p5,
			(select device_mng_num, attr_val
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'application/vnd.wap.xhtml+xml'  ) p6
		where p3.device_mng_num = p1.device_mng_num(+)
		and   p3.device_mng_num = p2.device_mng_num(+)
		and   p3.device_mng_num = p4.device_mng_num(+)
		and   p3.device_mng_num = p5.device_mng_num(+)
		and   p3.device_mng_num = p6.device_mng_num(+) ) dev
	WHERE DEV.DEVICE_MNG_NUM = SKT.DEVICE_MNG_NUM ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_CUST_PPG Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') ||' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_cust_ppg_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PPG(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'daily_cust_ppg_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PPG(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PPG(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PPG(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PPG(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PPG(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_CUST_PPG Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PPG(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PPG(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PPG(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PPG(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_IN_CHARGE_CD" (
	i_charge_cd        IN     TB_CUST_PERSON.CHARGE_CD%TYPE
)IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_IN_CHARGE_CD
-- 기능 : UAProfiel DB와 IMS 연동(요금제코드)에서 초기화를 위한
--        SAM 파일생성(TB_CUST_PERSON, TB_CUST_PROF)
--        임시로 사용하고 PMH로 적용시 사용 안함
-- 변경력: 신규 (2005.11.09) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
CURSOR cur_get_data IS
	SELECT    SVC_MNG_NUM
			--|| '|' || NVL(CHARGE_CD, '')
                        AS GET_DATA
	FROM TB_CUST_PERSON
    WHERE CHARGE_CD = i_charge_cd ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_IN_CHARGE_CD Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_in_charge_cd_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_IN_CHARGE_CD(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_in_charge_cd_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) );

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_IN_CHARGE_CD(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_IN_CHARGE_CD Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_IN_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_IN_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_IN_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_IN_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_TB_UAP"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_TB_UAP
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 초기화를 위한
--        SAM 파일생성(TB_UAP)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

-- -- -----------------------------------------------------------------------------
-- -- Cursor
-- -- -----------------------------------------------------------------------------

CURSOR cur_get_data IS
	SELECT       NVL(DEVICE_MNG_NUM, '')
		 || '|' || NVL(URI, '')
		 || '|' || NVL(UAP_YN, '')
		 || '|' || NVL(COIS_DEVICE_CD, '')
		 || '|' || NVL(COIS_DEVICE_VER, '')
		 || '|' || NVL(PDA_YN, '')
		 || '|' || NVL(UAF_DEVICE_MANUF, '')
		 || '|' || NVL(UAF_DEVICE_MODEL, '')
		 || '|' || NVL(UAF_DEVICE_MODEL_DSC, '') AS GET_DATA
	 FROM TB_UAP
	 ORDER BY DEVICE_MNG_NUM ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_UAP Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_tb_uap_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP(INIT)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA );
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_tb_uap_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END LOOP Process_Loop;
    << end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_UAP Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		error_cnt := error_cnt + 1;
		err_code  := SQLCODE || SQLERRM;
		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
		VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

	WHEN DUP_VAL_ON_INDEX THEN
		error_cnt := error_cnt + 1;
		err_code  := SQLCODE || SQLERRM;
		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
		VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

	WHEN TOO_MANY_ROWS THEN
		error_cnt := error_cnt + 1;
		err_code  := SQLCODE || SQLERRM;
		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
		VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

	WHEN OTHERS THEN
	     error_cnt := error_cnt + 1;
	     err_code  := SQLCODE || SQLERRM;
	     INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
	     VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP(INIT)', 'D', SYSDATE, substr(err_code,1,300) );
	COMMIT;
END;
/







  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_OPEN_CP"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_OPEN_CP
-- History: (2005.05.11) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- ----------------------------------------------------------------------------

-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

-- -- -----------------------------------------------------------------------------
-- -- Cursor
-- -- -----------------------------------------------------------------------------
CURSOR cur_get_data IS
	SELECT        NVL(CP.OPEN_CP_CD         , '')
		|| '|' || NVL(CP.PASSWD             , '')
		|| '|' || NVL(CP.COIS_OFFSET        , '')
		|| '|' || NVL(CP.CP_NM              , '')
		|| '|' || NVL(CP.CP_DSC             , '')
		|| '|' || NVL(CP.ACTIVE_YN          , '')
		|| '|' || NVL(CP.DEV_NM             , '')
		|| '|' || NVL(CP.DEV_EMAIL          , '')
		|| '|' || NVL(CP.DEV_OFFICE         , '')
		|| '|' || NVL(CP.DEV_MOBILE         , '')
		|| '|' || NVL(TRIM(CP.EXEC_ID)      , '')
		|| '|' || NVL(TO_CHAR(CP.UPDATE_DT , 'YYYYMMDDHH24MISS'), '')
		|| '|' || NVL(TRIM(CP.REG_PATH)     , '')
		|| '|' || NVL(TO_CHAR(CP.COIS_UPDATE_DT , 'YYYYMMDDHH24MISS'), '')
		|| '|' || NVL(GRT.G_MAPPING_YN      , '')
		|| '|' || NVL(GRT.MAPPING_CMT       , '')
		|| '|' || NVL(GRT.G_AUTH_YN         , '')
		|| '|' || NVL(GRT.AUTH_CMT          , '')
		|| '|' || NVL(GRT.G_UAP_YN          , '')
		|| '|' || NVL(GRT.UAP_CMT           , '')
        AS GET_DATA
	FROM TB_OPEN_CP CP
	    ,TB_OPEN_GRANT GRT
	WHERE CP.OPEN_CP_CD = GRT.OPEN_CP_CD (+);
     -- WHERE CP.CP_MNG_CD < '5000'
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_OPEN_CP Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_open_cp.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA );
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
  	    COMMIT;
        END;
    END LOOP Process_Loop;
    << end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_OPEN_CP Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN DUP_VAL_ON_INDEX THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN TOO_MANY_ROWS THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN OTHERS THEN
	     error_cnt := error_cnt + 1;
	     DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_TB_SUB_COMPO" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_TB_SUB_COMPO
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 일일 대사를 위해
--        SAM 파일생성(TB_SUB_COMPO)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   CURSOR DEFINE  ( 206자리)
------------------------------
--   COMPO_CD           (  2)
--   SUB_COMPO_CD       (  4)
--   SUB_COMPO_NM       (200)
-- --------------------------
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_NM, '') AS GET_DATA
	FROM TB_SUB_COMPO ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_SUB_COMPO Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');-- FILE OPEN
    select 'daily_tb_sub_compo_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       ( SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES ( SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_SUB_COMPO(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'daily_tb_sub_compo_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_SUB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;


            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_SUB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_SUB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_SUB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_SUB_COMPO(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_SUB_COMPO Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_SUB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_SUB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_SUB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_SUB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_TB_UAP" (
        I_Work_dt               IN DATE DEFAULT SYSDATE
)
IS

    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);

    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    v_Get_Data       DBMS_SQL.Varchar2_Table   ;

    N_CURSOR    INTEGER;
    N_RET       INTEGER;
    SQL_TEXT    VARCHAR2(2000);

    fetch_size          NUMBER := 1000 ;
    indx                NUMBER := 1 ;
    v_temp_cnt          NUMBER ;
    v_RecCnt            NUMBER ;

CURSOR cur_get_data IS
        SELECT DEVICE_MNG_NUM
        FROM TB_UAP_CHANGE
        WHERE REG_DT >= TRUNC( I_Work_dt - 1 )
          AND REG_DT <  TRUNC( I_Work_dt )
          AND TBL_CD IN ('20', '21')
          AND CHANGE_TP != 'D' ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');

    select 'daily_tb_uap_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat' into sam_data_filename from dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');


    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
               (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP(DAILY)', 'S', SYSDATE, 0, 0, 0) ;

    COMMIT;

    << Base_Loop >>
    FOR c1 IN cur_get_data LOOP
    BEGIN

            BEGIN

                SQL_TEXT :='SELECT NVL(DEVICE_MNG_NUM, '''')			'
				|| ' || ''|'' || NVL(URI, '''')			'
                                || ' || ''|'' || NVL(UAP_YN, '''')              '
                                || ' || ''|'' || NVL(COIS_DEVICE_CD, '''')      '
                                || ' || ''|'' || NVL(COIS_DEVICE_VER, '''')     '
                                || ' || ''|'' || NVL(PDA_YN, '''')              '
                                || ' || ''|'' || NVL(UAF_DEVICE_MANUF, '''')    '
                                || ' || ''|'' || NVL(UAF_DEVICE_MODEL, '''')    '
                                || ' || ''|'' || NVL(UAF_DEVICE_MODEL_DSC, '''')  AS GET_DATA
'
                                || ' FROM TB_UAP                                '
                                || ' WHERE DEVICE_MNG_NUM = ''' || C1.DEVICE_MNG_NUM || ''''
                                || ' ORDER BY DEVICE_MNG_NUM ' ;


                N_CURSOR := DBMS_SQL.OPEN_CURSOR;
                DBMS_SQL.PARSE(N_CURSOR, SQL_TEXT, DBMS_SQL.NATIVE);

                        DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 1, v_Get_Data, fetch_size, indx );

                N_RET := DBMS_SQL.EXECUTE(N_CURSOR);

                v_temp_cnt := 1 ;

                << Internal_Cursor_Loop >>
                LOOP
                    N_RET := DBMS_SQL.FETCH_ROWS(N_CURSOR);
                    --DBMS_OUTPUT.PUT_LINE(N_RET);
                    v_RecCnt := DBMS_SQL.LAST_ROW_COUNT ;
                    --DBMS_OUTPUT.PUT_LINE('FETCH_CNT [' || v_RecCnt || ']');

                    DBMS_SQL.COLUMN_VALUE(N_CURSOR, 1, v_Get_Data);
                    /*
                    DBMS_OUTPUT.PUT_LINE('v_RecCnt        [' || v_RecCnt || ']');
                    DBMS_OUTPUT.PUT_LINE('v_Get_Data      [' || v_Get_Data(v_temp_cnt) ||']');
                    */

                    v_temp_cnt := v_temp_cnt + 1 ;

                    EXIT WHEN N_RET != fetch_size ;
                END LOOP Internal_Cursor_Loop ;

                IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
                    DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

                    IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
                        DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
                    END IF;
            END ;

            << Process_Loop >>
            FOR i IN 1..v_RecCnt LOOP

                read_cnt := read_cnt + 1;

                BEGIN

                    utl_file.put_line(sam_data_filetype, v_Get_Data(i) );

                    write_cnt := write_cnt + 1;
                    fetch_cnt := fetch_cnt + 1;

                                if fetch_cnt = 1000000 then
                                    file_seq  := file_seq + 1;
                                    fetch_cnt := 0;
                                        utl_file.fclose(sam_data_filetype);
                                        select 'daily_tb_uap_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
                                        into    sam_data_filename from dual ;
					sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

				end if;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                                INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;


		    WHEN DUP_VAL_ON_INDEX THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                                INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;


                    WHEN TOO_MANY_ROWS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                                INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;


                    WHEN OTHERS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

                    COMMIT;
                END;
            END LOOP Process_Loop;
    END;
    << end_loop >>
    NULL;
    END LOOP Base_Loop;


    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP(DAILY)', 'E', SYSDATE, read_cnt,write_cnt, error_cnt) ;

        COMMIT;

    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');

EXCEPTION
       WHEN NO_DATA_FOUND THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP(DAILY)', 'D', SYSDATE, substr(err_code,1,300) );

       WHEN DUP_VAL_ON_INDEX THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN

                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_UAF_TO_UAP" (
	 I_Uaf_Attr          IN  VARCHAR2
	,I_Uaf_Val           IN  VARCHAR2
	,I_Asso_Uaf_Attr     IN  VARCHAR2
	,I_Asso_Uaf_Val      IN  VARCHAR2
	,O_RecCnt            OUT NUMBER
	,O_Compo_cd          OUT DBMS_SQL.VARCHAR2_TABLE
	,O_Sub_Compo_cd      OUT DBMS_SQL.VARCHAR2_TABLE
	,O_Attr_nm           OUT DBMS_SQL.VARCHAR2_TABLE
	,O_Attr_Val          OUT DBMS_SQL.VARCHAR2_TABLE
    ,O_RsltYN           OUT VARCHAR2
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : SP_UAF_TO_UAP
-- 기능 : 예전 UA Field 정보의 값으로 UA Profile 의 정보를 확인 하려 할때 호출하며
--        예전 field명과 value값을 입력으로 하고, 여러개의 결과 Row를 리턴받을수 있다.
--
-- 변경력: 2003. 10. 08
-- 		1. 신규 생성 - compleus -
-- -----------------------------------------------------------------------------
	ERR_MSG	          VARCHAR2(200);
	v_uaf_attr        VARCHAR2(30);
	v_uaf_val         VARCHAR2(80);
	v_asso_uaf_attr   VARCHAR2(30);
	v_asso_uaf_val    VARCHAR2(80);

	v_uap1_attr_nm    VARCHAR2(40);
	v_uap1_value_cnt  NUMBER := 0 ;
	v_uap2_attr_nm    VARCHAR2(40);
	v_uap2_value_cnt  NUMBER := 0 ;
	v_uap3_attr_nm    VARCHAR2(40);
	v_uap3_value_cnt  NUMBER := 0 ;
	v_job_flag		  CHAR(1):= 'Y' ;

    v_temp_cnt          NUMBER ;
    -- FETCH 할 변수
    N_CURSOR    INTEGER;
    N_RET       INTEGER;
    SQL_TEXT    VARCHAR2(2500);

    fetch_size          NUMBER := 10 ;
    indx                NUMBER := 1 ;

BEGIN
    ERR_MSG := '매핑 PROCEDURE를 실행 에러발생' ;
    O_RsltYN := 'N' ;
	v_uaf_attr      := UPPER(I_Uaf_Attr);
	v_uaf_val       := I_Uaf_Val       ;
	v_asso_uaf_attr := UPPER(I_Asso_Uaf_Attr) ;
	v_asso_uaf_val  := I_Asso_Uaf_Val  ;
	--DBMS_OUTPUT.ENABLE ( 1000000);
	--DBMS_OUTPUT.PUT_LINE( '***** [ SP_UAF_TO_UAP Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');

	-- 입력 값 체크
	IF ( v_uaf_attr IS NULL OR
	     v_uaf_val	IS NULL ) THEN
		ERR_MSG := '해당 필드명 또는 값이 없습니다. 값을 입력 해주십시오' ;
		RETURN ;
	END IF;

	IF ( v_asso_uaf_attr IS NULL OR
	     v_asso_uaf_val  IS NULL ) THEN
		-- 동일 한 값으로 셋팅
	    v_asso_uaf_attr := v_uaf_attr ;
	    v_asso_uaf_val  := v_uaf_val ;
	END IF;

	BEGIN -- 2
		-- 해당 매핑 정보가 존재하는가?
		ERR_MSG := '매핑테이블 조회중 ERROR 발생.' ;
		SELECT     UAP1_ATTR_NM,   UAP1_VALUE_CNT,   UAP2_ATTR_NM,   UAP2_VALUE_CNT,   UAP3_ATTR_NM,   UAP3_VALUE_CNT
			INTO v_uap1_attr_nm, v_uap1_value_cnt, v_uap2_attr_nm, v_uap2_value_cnt, v_uap3_attr_nm, v_uap3_value_cnt
		FROM TB_UAF_UAP_MAPPING
		WHERE UAF_ATTR = v_uaf_attr
		AND UAF_VAL = v_uaf_val
		AND ASSO_UAF_ATTR = v_asso_uaf_attr
		AND ASSO_UAF_VAL = v_asso_uaf_val;

        /*
		DBMS_OUTPUT.PUT_LINE('UAP1_ATTR_NM   [' || v_uap1_attr_nm                 || ']');
		DBMS_OUTPUT.PUT_LINE('UAP1_VALUE_CNT [' || TO_CHAR(v_uap1_value_cnt,'0')  || ']');
		DBMS_OUTPUT.PUT_LINE('UAP2_ATTR_NM   [' || v_uap2_attr_nm                 || ']');
		DBMS_OUTPUT.PUT_LINE('UAP2_VALUE_CNT [' || TO_CHAR(v_uap2_value_cnt,'0')  || ']');
        */

	   EXCEPTION
		WHEN NO_DATA_FOUND THEN
			ERR_MSG := '해당되는 매핑 정보가 없습니다.' ;
			v_job_flag := 'N' ;
            /*
			DBMS_OUTPUT.PUT_LINE('---- MAPPING DATA NOT FOUND ----');
			DBMS_OUTPUT.PUT_LINE('UAF_ATTR   [' || v_uaf_attr    || ']');
			DBMS_OUTPUT.PUT_LINE('UAF_VAL    [' || v_uaf_val     || ']');
            */

			RETURN ;
		WHEN OTHERS THEN
			--DBMS_OUTPUT.PUT_LINE( TRIM(ERR_MSG) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
			RETURN ;

	END;	-- 2

	BEGIN	-- 3
		ERR_MSG := '커서1 선언중 ERROR 발생' ;

	    -- 건수가 존재하면 그 건수 만큼 쿼리를 생성한다.
	    IF v_uap1_value_cnt > 0 THEN
	        FOR i IN 1..v_uap1_value_cnt LOOP
	            IF i = v_uap1_value_cnt THEN
	                SQL_TEXT := SQL_TEXT || ' SELECT COMPO_CD1, SUB_COMPO_CD1, UAP1_ATTR_NM, UAP1_ATTR_VAL' || i || ' FROM TB_UAF_UAP_MAPPING '
							||  ' WHERE UAF_ATTR = '''      || v_uaf_attr      || ''''
							||  ' AND UAF_VAL = '''         || v_uaf_val       || ''''
	                        ||  ' AND ASSO_UAF_ATTR = '''   || v_asso_uaf_attr || ''''
							||  ' AND ASSO_UAF_VAL = '''    || v_asso_uaf_val  || ''''  ;
	            ELSE
	                SQL_TEXT := SQL_TEXT || ' SELECT COMPO_CD1, SUB_COMPO_CD1, UAP1_ATTR_NM, UAP1_ATTR_VAL' || i || ' FROM TB_UAF_UAP_MAPPING '
							||  ' WHERE UAF_ATTR = '''      || v_uaf_attr      || ''''
							||  ' AND UAF_VAL = '''         || v_uaf_val       || ''''
	                        ||  ' AND ASSO_UAF_ATTR = '''   || v_asso_uaf_attr || ''''
							||  ' AND ASSO_UAF_VAL = '''    || v_asso_uaf_val  || ''''
	                        ||  ' UNION ' ;
	            END IF;
	        END LOOP ;
	    END IF ;

        ERR_MSG := '커서2 선언중 ERROR 발생' ;
        -- UAP2쪽에 값이 있으면 다시 한번 돌아 보자꾸나...
        IF v_uap2_value_cnt > 0 THEN
	        FOR i IN 1..v_uap2_value_cnt LOOP
	             --DBMS_OUTPUT.PUT_LINE( '두곳 다있는 정보');
                SQL_TEXT := SQL_TEXT || ' UNION '
                        ||  ' SELECT COMPO_CD2, SUB_COMPO_CD2, UAP2_ATTR_NM, UAP2_ATTR_VAL' || i || ' FROM TB_UAF_UAP_MAPPING '
						||  ' WHERE UAF_ATTR = '''      || v_uaf_attr      || ''''
						||  ' AND UAF_VAL = '''         || v_uaf_val       || ''''
                        ||  ' AND ASSO_UAF_ATTR = '''   || v_asso_uaf_attr || ''''
						||  ' AND ASSO_UAF_VAL = '''    || v_asso_uaf_val  || ''''  ;
	        END LOOP ;
        END IF;

        ERR_MSG := '커서3 선언중 ERROR 발생' ;
        -- UAP3쪽에 값이 있으면 다시 한번 돌아 보자꾸나...
        IF v_uap3_value_cnt > 0 THEN
	        FOR i IN 1..v_uap3_value_cnt LOOP
	             --DBMS_OUTPUT.PUT_LINE( '세곳 다있는 정보');
                SQL_TEXT := SQL_TEXT || ' UNION '
                        ||  ' SELECT COMPO_CD3, SUB_COMPO_CD3, UAP3_ATTR_NM, UAP3_ATTR_VAL' || i || ' FROM TB_UAF_UAP_MAPPING '
						||  ' WHERE UAF_ATTR = '''      || v_uaf_attr      || ''''
						||  ' AND UAF_VAL = '''         || v_uaf_val       || ''''
                        ||  ' AND ASSO_UAF_ATTR = '''   || v_asso_uaf_attr || ''''
						||  ' AND ASSO_UAF_VAL = '''    || v_asso_uaf_val  || ''''  ;
	        END LOOP ;
        END IF;

	    -- ============
	    -- CURSOR 처리
	    -- ============
        ERR_MSG := '커서 실행중 ERROR 발생' ;
        -- DBMS_OUTPUT.PUT_LINE( 'SQL_TEXT:[' || length(SQL_TEXT) || ']');
	    N_CURSOR := DBMS_SQL.OPEN_CURSOR;
	    DBMS_SQL.PARSE(N_CURSOR, SQL_TEXT, DBMS_SQL.NATIVE);

		DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 1, O_Compo_cd, fetch_size, indx );
		DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 2, O_Sub_Compo_cd, fetch_size, indx );
		DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 3, O_Attr_nm,  fetch_size, indx );
		DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 4, O_Attr_Val, fetch_size, indx );

		N_RET := DBMS_SQL.EXECUTE(N_CURSOR);

        v_temp_cnt := 1 ;
        ERR_MSG := '패치 실행중 ERROR 발생' ;
		LOOP
			N_RET := DBMS_SQL.FETCH_ROWS(N_CURSOR);
			--DBMS_OUTPUT.PUT_LINE(N_RET);
			O_RecCnt := DBMS_SQL.LAST_ROW_COUNT ;
			--DBMS_OUTPUT.PUT_LINE('FETCH_CNT [' || O_RecCnt || ']');

			DBMS_SQL.COLUMN_VALUE(N_CURSOR, 1, O_Compo_cd);
			DBMS_SQL.COLUMN_VALUE(N_CURSOR, 2, O_Sub_Compo_cd);
			DBMS_SQL.COLUMN_VALUE(N_CURSOR, 3, O_Attr_nm);
			DBMS_SQL.COLUMN_VALUE(N_CURSOR, 4, O_Attr_Val);

            /*
			DBMS_OUTPUT.PUT_LINE('O_RecCnt       [' || O_RecCnt                    || ']');
			DBMS_OUTPUT.PUT_LINE('O_Compo_cd     [' || O_Compo_cd(v_temp_cnt)      || ']');
			DBMS_OUTPUT.PUT_LINE('O_Sub_Compo_cd [' || O_Sub_Compo_cd(v_temp_cnt)  || ']');
			DBMS_OUTPUT.PUT_LINE('O_Attr_nm      [' || O_Attr_nm(v_temp_cnt)       || ']');
			DBMS_OUTPUT.PUT_LINE('O_Attr_Val     [' || O_Attr_Val(v_temp_cnt)      || ']');
            */

            v_temp_cnt := v_temp_cnt + 1 ;

			EXIT WHEN N_RET != fetch_size ;
	    END LOOP;
	    DBMS_SQL.CLOSE_CURSOR(N_CURSOR);

	EXCEPTION
		WHEN OTHERS THEN
			--DBMS_OUTPUT.PUT_LINE( TRIM(ERR_MSG) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
            NULL ;

	END;	-- 3

    ERR_MSG := '정상' ;
	--DBMS_OUTPUT.PUT_LINE( '***** [ SP_UAF_TO_UAP Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    O_RsltYN := 'Y' ;

EXCEPTION
	WHEN OTHERS THEN
		--DBMS_OUTPUT.PUT_LINE( TRIM(ERR_MSG) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
		ROLLBACK ;

END;	-- 1.
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."TEMP_INIT_ADDED_SVC_CD"
IS

-- -----------------------------------------------------------------------------
-- Procedure명 : temp_init_added_svc_cd
-- 기능 : 부가서비스 코드를 입력하면 CP에 내려줄 SAM파일을 추출함(초기화)
--        SAM 파일생성(TB_CUST_ADDED_SVC, TB_CUST_PROF)
--        format --> 부가서비스코드;서비스관리번호;MIN;MDN;COIS변경시간;처리자
-- 변경력: 신규 (2005.06.09) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq            NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    v_Exist_cnt         NUMBER ;
-- --------------------------
CURSOR cur_get_data IS
    -- 부가서비스 테이블에 있다하더라도 고객정보 테이블에 존재하지 않는 데이터는

    -- 인정하지 못함으로 아래 쿼리 사용가능(outer join무의미)
	SELECT       CUST.SVC_MNG_NUM
        || ';' || CUST.MOBILE_ID_NUM
        || ';' || CUST.MOBILE_SVC_NUM
        || ';' || ADDED.ADDED_SVC_CD AS GET_DATA
	FROM
	    (SELECT SVC_MNG_NUM
		    , ADDED_SVC_CD
		    , TO_CHAR(COIS_UPDATE_DT,'YYYYMMDDHH24MISS')AS COIS_UPDATE_DT
		    , REG_PATH
		FROM TB_CUST_ADDED_SVC
		WHERE ADDED_SVC_CD in (  'CAFRE'
									,'CNFRE'
									,'CB035'
									,'CB070'
									,'CB150'
									,'CDSAF'
									,'CDMEN' )
	    ) ADDED,
	    TB_CUST_PROF CUST
	WHERE ADDED.SVC_MNG_NUM = CUST.SVC_MNG_NUM ;


    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ temp_init_added_svc_cd Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'ims_' ||  TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'temp_init_added_svc_cd(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'ims_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'temp_init_added_svc_cd(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'temp_init_added_svc_cd(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'temp_init_added_svc_cd(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'temp_init_added_svc_cd(INIT)', 'D', substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'temp_init_added_svc_cd(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ temp_init_added_svc_cd Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'temp_init_added_svc_cd(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'temp_init_added_svc_cd(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'temp_init_added_svc_cd(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'temp_init_added_svc_cd(INIT)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_SUM_NATEIFS_TRANS_MIN10"
( vPROC_DATETIME_IN IN varchar2 )
IS
	vPROC_DATETIME	varchar2(14);			-- 통계 기준 시각.
	vProcedure_Name CONSTANT varchar2(30) := 'SUM_NATEIFS_TRANS_MIN10';			-- 직접연동 / 간접연동의 분단위 통계 테이블 명.

	vJOB_SEQ		NUMBER;
	vERR_CODE       varchar2(20);

BEGIN
	DBMS_OUTPUT.ENABLE (1000000);
	DBMS_OUTPUT.PUT_LINE( '***** [' || vProcedure_Name || '] Procedure START.... ******* ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') );

-- 프로시져 시작.. 통계 기준 일자시각 설정. 7분전 시각의 10분단위 통계.(즉 매 0~7분 이내에 돌면, 전 10분대역 통계 처리)
-- 매 시각 3분에 돌게 crontab 설정
	IF ( vPROC_DATETIME_IN IS NULL ) OR (LENGTH(vPROC_DATETIME_IN) < 10 ) THEN
		SELECT TO_CHAR(SYSDATE - 7/24/60, 'YYYYMMDDHH24MI') into vPROC_DATETIME  FROM DUAL;
	ELSE
		vPROC_DATETIME := vPROC_DATETIME_IN;
	END IF;

-- 프로시져 시작 시각... 시작 log 입력 후 최종 성공여부 처리시 사용.
--	SELECT SEQ_JOB_LOG.NEXTVAL into vJOB_SEQ  FROM DUAL;

--    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
 --       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
  --  VALUES (vJOB_SEQ, vProcedure_Name || ' INPUT PARAM : ' || vPROC_DATETIME, 'S', SYSDATE, 0, 0, 0) ;

	-- 최종 TEMP 데이터에 대한 통계 처리...
	INSERT into TB_NATEIFS_TRAN_MIN10
			SELECT SUBSTR(vPROC_DATETIME,1,11), PROCESS_CODE, OP_CD, RESULT_CODE, SUM(ACCESS_CNT)
			FROM TB_NATEIFS_TRAN_MIN
			WHERE PROCESS_DT LIKE SUBSTR(vPROC_DATETIME,1,11) || '%'
			GROUP BY SUBSTR(vPROC_DATETIME,1,11), PROCESS_CODE, OP_CD, RESULT_CODE
			;

--	UPDATE TB_JOB_LOG SET STATUS = 'E' WHERE SEQ = vJOB_SEQ;

	COMMIT;

EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK;

	vERR_CODE := TO_CHAR(SQLCODE);

--	UPDATE GAEBAL_UPADM.TB_JOB_LOG SET STATUS = 'F' WHERE SEQ = vJOB_SEQ;
	COMMIT;

	DBMS_OUTPUT.PUT_LINE( '***** [' || vProcedure_Name || '] EXCEPTION - others ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') );
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_SUM_NATEIFS_TRANS_HOUR"
( vPROC_DATETIME_IN IN varchar2 )
IS
	vPROC_DATETIME	varchar2(14);			-- 통계 기준 시각.
	vProcedure_Name CONSTANT varchar2(30) := 'SUM_NATEIFS_TRANS_HOUR';			-- 직접연동 / 간접연동의 분단위통계 테이블 명.

	vJOB_SEQ		NUMBER;
	vERR_CODE       varchar2(20);

BEGIN
	DBMS_OUTPUT.ENABLE (1000000);
	DBMS_OUTPUT.PUT_LINE( '***** [' || vProcedure_Name || '] Procedure START.... ******* ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') );

-- 프로시져 시작.. 통계 기준 일자시각 설정. 20분전 시각의 1 시간 단위 통계.(즉 매 0~20분 이내에 돌면, 전 1시간 대역 통계 처리)
-- 매 시각 4분에 돌게 crontab 설정
	IF ( vPROC_DATETIME_IN IS NULL ) OR (LENGTH(vPROC_DATETIME_IN) < 10 ) THEN
		SELECT TO_CHAR(SYSDATE - 20/24/60, 'YYYYMMDDHH24MI') into vPROC_DATETIME  FROM DUAL;
	ELSE
		vPROC_DATETIME := vPROC_DATETIME_IN;
	END IF;

-- 프로시져 시작 시각... 시작 log 입력 후 최종 성공여부 처리시 사용.
--	SELECT SEQ_JOB_LOG.NEXTVAL into vJOB_SEQ  FROM DUAL;

--    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
 --       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
  --  VALUES (vJOB_SEQ, vProcedure_Name || ' INPUT PARAM : ' || vPROC_DATETIME, 'S', SYSDATE, 0, 0, 0) ;

	-- 최종 TEMP 데이터에 대한 통계 처리...
	INSERT into TB_NATEIFS_TRAN_HOUR
			SELECT SUBSTR(vPROC_DATETIME,1,10), PROCESS_CODE, OP_CD, RESULT_CODE, SUM(ACCESS_CNT)
			FROM TB_NATEIFS_TRAN_MIN10
			WHERE PROCESS_DT LIKE SUBSTR(vPROC_DATETIME,1,10) || '%'
			GROUP BY SUBSTR(vPROC_DATETIME,1,10), PROCESS_CODE, OP_CD, RESULT_CODE
			;

--	UPDATE TB_JOB_LOG SET STATUS = 'E' WHERE SEQ = vJOB_SEQ;

	COMMIT;

EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK;

	vERR_CODE := TO_CHAR(SQLCODE);

--	UPDATE GAEBAL_UPADM.TB_JOB_LOG SET STATUS = 'F' WHERE SEQ = vJOB_SEQ;
	COMMIT;

	DBMS_OUTPUT.PUT_LINE( '***** [' || vProcedure_Name || '] EXCEPTION - others ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') );
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_SUM_CP_TRANS_MIN"
( vPROC_DATETIME_IN IN varchar2 )
--( vPROC_DATETIME IN SP_SUM_CP_TRANS_MIN.EVENT_DATETIME%TYPE )
IS
	vPROC_DATETIME	varchar2(14);			-- 통계 기준 시각.
	vProcedure_Name CONSTANT varchar2(20) := 'SP_SUM_CP_TRANS_MIN';			-- 직접연동 / 간접연동의 분단위 통계 테이블 명.

	vJOB_SEQ		NUMBER;
	vERR_CODE       varchar2(20);

BEGIN
	DBMS_OUTPUT.ENABLE (1000000);
	DBMS_OUTPUT.PUT_LINE( '***** [' || vProcedure_Name || '] Procedure START.... *******' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') );

-- 프로시져 시작.. 통계 기준 일자시각 설정. 3분전 통계.
	IF ( vPROC_DATETIME_IN IS NULL ) OR (LENGTH(vPROC_DATETIME_IN) < 11 ) THEN
		SELECT TO_CHAR(SYSDATE - 3/24/60, 'YYYYMMDDHH24MI') into vPROC_DATETIME  FROM DUAL;
	ELSE
		vPROC_DATETIME := vPROC_DATETIME_IN;
	END IF;

-- 프로시져 시작 시각... 시작 log 입력 후 최종 성공여부 처리시 사용.
	SELECT SEQ_JOB_LOG.NEXTVAL into vJOB_SEQ  FROM DUAL;

    INSERT INTO TB_JOB_LOG
        (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (vJOB_SEQ, vProcedure_Name || ' INPUT PARAM : ' || vPROC_DATETIME, 'S', SYSDATE, 0, 0, 0) ;

	-- 최종 TEMP 데이터에 대한 통계 처리...
	INSERT into TB_CP_TRAN_MIN
			SELECT DATE_DT, SERVER_NAME, CP_MNG_CD, RESULT_CODE, SUM(ACCESS_CNT)
			  FROM TB_CP_TRANSACTION
			 WHERE DATE_DT LIKE vPROC_DATETIME || '%'
			 GROUP BY DATE_DT, SERVER_NAME, CP_MNG_CD, RESULT_CODE
			;

	UPDATE TB_JOB_LOG SET STATUS = 'E' WHERE SEQ = vJOB_SEQ;

	COMMIT;

EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK;

	vERR_CODE := TO_CHAR(SQLCODE);

	UPDATE TB_JOB_LOG SET STATUS = 'F' WHERE SEQ = vJOB_SEQ;
	COMMIT;

	DBMS_OUTPUT.PUT_LINE( '***** [' || vProcedure_Name || '] EXCEPTION - others ' ||
TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') );
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_ADDED_SVC_VIEW" (
	 I_Svc_Mng_num      IN VARCHAR2
    ,I_Ldap_Format_YN   IN CHAR DEFAULT 'Y'
    ,I_File_YN          IN CHAR DEFAULT 'N'
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : SP_ADDED_SVC_VIEW
-- 기능 : 서비스관리번호를 입력하면 가입 부가서비스 리스트를 보여 준다.
--        File유무에 따라 N이면 단순히 보여주기만 하며(디폴트), Y인경우 해당 디렉
--        토리에 정보를 기록한다.
-- 변경력: 신규 (2006.06.19) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq            NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    v_Exist_cnt         NUMBER ;
    v_Svc_Mng_Num       VARCHAR2(10) := I_Svc_Mng_num ;
    v_File_YN           CHAR(1) := I_File_YN ;
-- --------------------------
CURSOR cur_get_data IS
	SELECT            SVC.ADDED_SVC_CD
			|| '$' || SVC.REG_CD
			|| '$' || NVL(SVC.EXEC_ID             , '' )
			|| '$' || NVL(TO_CHAR(SVC.REG_DT , 'YYYYMMDDHH24MISS'), '')
			|| '$' || NVL(TRIM(SVC.REG_PATH)       , '' )
			|| '$' || NVL(TO_CHAR(SVC.COIS_UPDATE_DT , 'YYYYMMDDHH24MISS'), NULL)
            AS GET_DATA
	FROM
	    TB_CUST_ADDED_SVC SVC
	WHERE SVC.SVC_MNG_NUM = v_Svc_Mng_Num ;


    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ SP_ADDED_SVC_VIEW Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'sp_added_svc_view_' || TO_CHAR(SYSDATE, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'a');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	--KS INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	--KS     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	--KS VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_ADDED_SVC_VIEW(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	--KS COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write or Console Print
            IF ( v_File_YN = 'Y' ) THEN
                utl_file.put_line(sam_data_filetype, c1.GET_DATA);
            ELSE
                IF ( I_Ldap_Format_YN = 'Y' ) THEN
                    DBMS_OUTPUT.PUT_LINE( 'skt-added-tot: ' || c1.GET_DATA ) ;
                ELSE
                    DBMS_OUTPUT.PUT_LINE( c1.GET_DATA ) ;
                END IF ;
            END IF ;
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
        EXCEPTION
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            --KS INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                --KS VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_ADDED_SVC_VIEW(SP)', 'D', substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	--KS INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	--KS        (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	--KS VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_ADDED_SVC_VIEW(SP)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	--KS COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '[ READ  COUNT  [' || read_cnt  || ']');

    IF ( v_File_YN = 'Y' ) THEN
        DBMS_OUTPUT.PUT_LINE( '[ WRITE COUNT  [' || write_cnt || ']');
    END IF ;

    DBMS_OUTPUT.PUT_LINE( '***** [ SP_ADDED_SVC_VIEW Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			--KS INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			--KS VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_ADDED_SVC_VIEW(SP)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_LBSP_CODE_DOWN" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_LBSP_CODE_DOWN
-- 기능 : UAProfile 에서 LBSP 에 Cois코드와 model코드(또는 URI)를 넘겨주기 위함
-- 변경력: 신규 (2004.7.13) : - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    VARCHAR2(200);
-- -- --------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- --------------------------------------------------------------------------

-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'

    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    log_cnt     NUMBER := 0;

-- ------------------------------------------------------
CURSOR cur_get_data IS
	SELECT DATA AS GET_DATA
	FROM
	   (SELECT UPPER(COIS_DEVICE_CD) || '|' || UPPER(UAF_DEVICE_MANUF) || UAF_DEVICE_MODEL AS DATA
		FROM TB_UAP
		WHERE UAF_DEVICE_MANUF IS NOT NULL
		AND   UAF_DEVICE_MODEL IS NOT NULL
		UNION
		SELECT UPPER(COIS_DEVICE_CD) || '|' || URI AS DATA
		FROM TB_UAP
		WHERE UAP_YN = 'Y')
	;

-- ====================
--  Main Process Start
-- ====================
BEGIN -- 1.

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_LBSP_CODE_DOWN Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');

-- FILE OPEN
    SELECT 'daily_lbsp_d_' || TO_CHAR(I_Work_dt, 'YYYYMMDD') || '.dat'
    INTO    sam_data_filename
    FROM    dual ;

    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');


-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LBSP_CODE_DOWN(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP -- 2.
    BEGIN  -- 3.

  --  읽은 DATA Count
        read_cnt := read_cnt + 1;

  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN -- 4.
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
			write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LBSP_CODE_DOWN(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LBSP_CODE_DOWN(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;

   	   COMMIT;
        END; -- 4.
    END; -- 3.
    << end_loop >>
    NULL;
    END LOOP; -- 2.
-- ===============================================================
-- 수작업 Cois코드
-- ===============================================================

--  COIS_Code | Device_Code
--  SCH-E150 / SCH-E150M
    utl_file.put_line(sam_data_filetype, 'SSEB|SS50');
    utl_file.put_line(sam_data_filetype, 'SSEB|SS84');

--  IM-5000
    utl_file.put_line(sam_data_filetype, 'SI39|SK12');
    utl_file.put_line(sam_data_filetype, 'SI39|SK17');
    utl_file.put_line(sam_data_filetype, 'SKC3|SK14');
    utl_file.put_line(sam_data_filetype, 'SKC3|SK15');
    utl_file.put_line(sam_data_filetype, 'SKC3|SK16');

--  IM-7200 / IM-7200P
    utl_file.put_line(sam_data_filetype, 'SKE8|SK28');
    utl_file.put_line(sam_data_filetype, 'SKE7|SK28');

--  StarTAC2004 / StarTAC2004M / StarTAC2004SE
    utl_file.put_line(sam_data_filetype, 'MTCC|MT22');
    utl_file.put_line(sam_data_filetype, 'MTCD|MT20');
    utl_file.put_line(sam_data_filetype, 'MTCE|MT20');

--  MS-280 / MS-280M
    utl_file.put_line(sam_data_filetype, 'MTE6|MT23');
    utl_file.put_line(sam_data_filetype, 'MTE7|MT15');

--  S2 / S2M
    utl_file.put_line(sam_data_filetype, 'PCC6|HD20');
    utl_file.put_line(sam_data_filetype, 'PCCC|HD16');

--  PG-S5500C / PG-S550L / PG-S500CM
    utl_file.put_line(sam_data_filetype, 'PCC9|HD21');
    utl_file.put_line(sam_data_filetype, 'PCCB|HD21');
    utl_file.put_line(sam_data_filetype, 'PCCD|HD17');

--  VK-100 / VK-100M
    utl_file.put_line(sam_data_filetype, 'VKC1|VK02');
    utl_file.put_line(sam_data_filetype, 'VKC2|VK01');

--  LG-SD100S / LG-SD100A / LG-SD100
    utl_file.put_line(sam_data_filetype, 'LGCV|LG21');
    utl_file.put_line(sam_data_filetype, 'LGCL|LG50');
    utl_file.put_line(sam_data_filetype, 'LGC9|LG50');

--  SCH-330(R/C) / SCH-330SS / SCH-330
    utl_file.put_line(sam_data_filetype, 'SSER|SS54');

--  LG-SD1100L / LG-SD1100 / LG-SD2100
    utl_file.put_line(sam_data_filetype, 'LGCB|LG22');
    utl_file.put_line(sam_data_filetype, 'LGCb|LG31');
    utl_file.put_line(sam_data_filetype, 'LGCD|LG31');
    utl_file.put_line(sam_data_filetype, 'LGCD|LG23');
    utl_file.put_line(sam_data_filetype, 'LGCA|LG31');
    utl_file.put_line(sam_data_filetype, 'LGCA|LG23');

--  LG-SD1010
    utl_file.put_line(sam_data_filetype, 'LGC7|LG26');

--  SCH-X130 / SCH-X130SK
    utl_file.put_line(sam_data_filetype, 'SSC7|SS14');
    utl_file.put_line(sam_data_filetype, 'SSCA|SS18');

--  SCH-X137 / SCH-X137SS
    utl_file.put_line(sam_data_filetype, 'SSCW|SSA7');

--  SCH-X210 / SCH-X210SK
    utl_file.put_line(sam_data_filetype, 'SSC5|SS15');
    utl_file.put_line(sam_data_filetype, 'SSC6|SS19');

--  V.67A / V.67
    utl_file.put_line(sam_data_filetype, 'MTC1|MTA1');
    utl_file.put_line(sam_data_filetype, 'MV67|MTA1');

--  CX-300DA / CX-300DV
    utl_file.put_line(sam_data_filetype, 'LGC4|LGA6');
    utl_file.put_line(sam_data_filetype, 'E540|LG15');

--  SCH-X580 / SCH-X570
    utl_file.put_line(sam_data_filetype, 'SSD2|SS31');
    utl_file.put_line(sam_data_filetype, 'SSD1|SS33');

--  LG-SD9220 / LG-SD220
    utl_file.put_line(sam_data_filetype, 'LGCX|LG55');
    utl_file.put_line(sam_data_filetype, 'LGCY|LG50');

--  SCH-X127 / SCH-X127SS / SCH-X127A
    utl_file.put_line(sam_data_filetype, 'SSCB|SSA4');
    utl_file.put_line(sam_data_filetype, 'SSCS|SSA3');
    utl_file.put_line(sam_data_filetype, 'SSCV|SSA3');

--  LG-SD230 / LG-SD9230
    utl_file.put_line(sam_data_filetype, 'LGD1|LG57');
    utl_file.put_line(sam_data_filetype, 'LGD2|LG56');
    utl_file.put_line(sam_data_filetype, 'LGD5|LG56');

--  IM-3000 / IM-3000S
    utl_file.put_line(sam_data_filetype, 'SK19|SK09');
    utl_file.put_line(sam_data_filetype, 'SK18|SKA1');

--  LG-i1000 / LG-D510A LG 서비스센터에서 동일기종이라고 하여 임으로 입력하나 단말상으로는 다른기종임
--  전체에 관한것이 아니고 E530 의 Cois코드만 처리
    utl_file.put_line(sam_data_filetype, 'E530|LGA5');
    utl_file.put_line(sam_data_filetype, 'LG09|LG06');

--  LG-SD1110 / LG-SD1100(Upgrade1)
    utl_file.put_line(sam_data_filetype, 'LGCD|LG24');
    utl_file.put_line(sam_data_filetype, 'LGCC|LG31');

--  PT-S130 / PT-S130D
    utl_file.put_line(sam_data_filetype, 'PCEE|PC45');

--  PH-S6500 / PH-S6500D / PH-S6500RC
    utl_file.put_line(sam_data_filetype, 'PCD2|PC34');

-- ===============================================================
-- End Cursor Loop

-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LBSP_CODE_DOWN(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_LBSP_CODE_DOWN END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DDHH24:MI:SS')    || ' ] *****');

EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LBSP_CODE_DOWN(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LBSP_CODE_DOWN(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;
       COMMIT;

END; --1
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_CHARGE_CD"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_CHARGE_CD
-- 기능 : UAProfiel DB와 IMS 연동(요금제코드)에서 초기화를 위한
--        SAM 파일생성(TB_CUST_PERSON, TB_CUST_PROF)
--        임시로 사용하고 PMH로 적용시 사용 안함
-- 변경력: 신규 (2005.11.09) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
CURSOR cur_get_data IS
	SELECT            SVC_MNG_NUM
			|| '|' || NVL(CHARGE_CD, '')
            AS GET_DATA
	FROM TB_CUST_PERSON
    ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CHARGE_CD Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_charge_cd_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_charge_cd_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CHARGE_CD Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;


       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CHARGE_CD(INIT)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_TB_SUB_COMPO"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_TB_SUB_COMPO
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 초기화를 위한
--        SAM 파일생성(TB_SUB_COMPO)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   CURSOR DEFINE  ( 206자리)
------------------------------
--   COMPO_CD           (  2)
--   SUB_COMPO_CD       (  4)
--   SUB_COMPO_NM       (200)
-- --------------------------
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_NM, '') AS GET_DATA
	FROM TB_SUB_COMPO ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_SUB_COMPO Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_tb_sub_compo_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_SUB_COMPO(INIT)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_tb_sub_compo_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)

                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_SUB_COMPO(INIT)', 'D', SYSDATE,substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)

                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_SUB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_SUB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_SUB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_SUB_COMPO(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_SUB_COMPO Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
             error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_SUB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_SUB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_SUB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_SUB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300)) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_FW_DOWN_INTER_TEST" (
     I_Ua_Manufacturer   IN      TB_UAP.UAF_DEVICE_MANUF%TYPE
    ,I_Ua_Model          IN      TB_UAP.UAF_DEVICE_MODEL%TYPE
    ,O_RsltYN           OUT      VARCHAR2
    ,O_WriteCnt         OUT      VARCHAR2
    ,O_FileName         OUT      VARCHAR2
)
IS
-- -----------------------------------------------------------------------------

-- Procedure명 : SP_FW_DOWN_INTER
-- 기능 : UAProfiel DB와 다른 시스템 SoftwareDownload 에서 호출되며 각 모델정보로
--        파일을 생성하고 파일명을 리턴한다.
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt            NUMBER := 0;
    write_cnt           NUMBER := 0;
    fetch_cnt           NUMBER := 0;
    error_cnt           NUMBER := 0;
    err_code            VARCHAR2(200);
    log_data            VARCHAR2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/fds'
    file_seq            NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/swd';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    -- FETCH 할 변수

    N_CURSOR            INTEGER;
    N_RET               INTEGER;
    PUT_TEXT            VARCHAR2(200);
    SQL_TEXT            VARCHAR2(1500);

    v_RsltMsg           VARCHAR2(200) := '';
    v_FileName          VARCHAR2(1000) := '';
    v_Cnt               NUMBER := 0 ;
    v_Ua_Manufacturer   VARCHAR2(2) := '';
    v_Ua_Model          VARCHAR2(2) := '';

-- -----------------------------
--   CURSOR Define  ( 301 자리)
-- -----------------------------
-- TB_SVC_NATE.SVC_INST_NO         (11)

-- ====================
--  Main Process Start
-- ====================
BEGIN   -- 1.
    -- 1. 입력값 체크
    O_RsltYN := 'N';

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    --INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
    --   (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    --VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_DOWN_INTER', 'S', SYSDATE, 0, 0, 0) ;
    --COMMIT;

    SQL_TEXT := 'SELECT MOBILE_SVC_NUM                      '
        || '    || '',''                                    '
        || '    || SUBSTRB(NVL(DEV.UAF_DEVICE_MANUF,''''),1)'
        || '    || '',''                                    '
        || '    || SUBSTRB(NVL(DEV.UAF_DEVICE_MODEL,''''),1)'
        || '    || '',''                                    '
        || '    || NVL(ATTR.ATTR_VAL,'''')                  '
        || '    || '',''                                    '
        || '    || NVL(TO_CHAR(SKT.UPDATE_DT, ''YYYYMMDDHH24MISS''), RPAD('' '', 14))'
        || 'FROM TB_CUST_PROF      SKT,                     '
        || '     TB_UAP            DEV,                     '
        || '     TB_UAP_ATTR_LIST  ATTR                     ';

    --- 제조사 로직 처리
    IF TRIM(I_Ua_Manufacturer) IS NULL THEN
        v_Ua_Manufacturer := 'XX' ;
    ELSE
        v_Ua_Manufacturer := TRIM(I_Ua_Manufacturer) ;
    END IF ;

    SQL_TEXT := SQL_TEXT || 'WHERE DEV.UAF_DEVICE_MANUF like ''%''||TRIM(:b_Ua_Manufacturer)||''%''';

    --- Device Model 로직 처리
    IF TRIM(I_Ua_Model) IS NULL THEN
                v_Ua_Model := 'XX' ;
    ELSE
        v_Ua_Model := TRIM(I_Ua_Model) ;
    END IF ;

    SQL_TEXT := SQL_TEXT || 'AND DEV.UAF_DEVICE_MODEL like ''%''||UPPER(TRIM(:b_Ua_Model))||''%''';


    -- 마무리 TEXT
    SQL_TEXT := SQL_TEXT  || 'AND DEV.DEVICE_MNG_NUM = SKT.DEVICE_MNG_NUM  '
                          || 'AND DEV.DEVICE_MNG_NUM = ATTR.DEVICE_MNG_NUM '
                          || 'AND ATTR.COMPO_CD      = ''SW''              '
                          || 'AND ATTR.SUB_COMPO_CD  = '' ''               '
                          || 'AND ATTR.ATTR_NM       = ''SoftwareNumber''  ';

    --dbms_output.put_line(SQL_TEXT);

    N_CURSOR := DBMS_SQL.OPEN_CURSOR;

    DBMS_SQL.PARSE(N_CURSOR, SQL_TEXT, DBMS_SQL.NATIVE );

--    IF TRIM(I_Ua_Manufacturer) IS NOT NULL THEN
        DBMS_SQL.BIND_VARIABLE(N_CURSOR, ':b_Ua_Manufacturer', I_Ua_Manufacturer) ;
--    END IF ;

--    IF TRIM(I_Ua_Model) IS NOT NULL THEN
        DBMS_SQL.BIND_VARIABLE(N_CURSOR, ':b_Ua_Model', I_Ua_Model) ;
--    END IF ;

    DBMS_SQL.DEFINE_COLUMN(N_CURSOR, 1, PUT_TEXT, 200);

    N_RET := DBMS_SQL.EXECUTE(N_CURSOR);


-- FILE OPEN
    select  'FW_' || UPPER(trim(v_Ua_Manufacturer)) || '_' || trim(v_Ua_Model) || '_' || TO_CHAR(SYSDATE, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'

      into  sam_data_filename
      from  dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
    v_FileName := trim(sam_data_filename)  ;

    LOOP
        IF DBMS_SQL.FETCH_ROWS(N_CURSOR) = 0 THEN
            EXIT;
        END IF;

        DBMS_SQL.COLUMN_VALUE(N_CURSOR, 1, PUT_TEXT);
        --DBMS_OUTPUT.PUT_LINE(PUT_TEXT);
        BEGIN   -- 2.
      --  읽은 DATA Count
            read_cnt := read_cnt + 1;
      --    -----------------------
      --    READ DATA를 FILE WRITE
      --    -----------------------
      -- Data Write
            utl_file.put_line( sam_data_filetype, TRIM(PUT_TEXT) );
        -- WRITE DATA 건수 Count
                write_cnt := write_cnt + 1;
                fetch_cnt := fetch_cnt + 1;
    --  백만건 단위로 file name에 seq를 붙여서 만듬.... --
                if fetch_cnt = 1000000 then
                    file_seq  := file_seq + 1;
                    fetch_cnt := 0 ;
                    utl_file.fclose(sam_data_filetype);
                    select  'FW_' || UPPER(trim(v_Ua_Manufacturer)) || '_' || trim(v_Ua_Model) || '_' || TO_CHAR(SYSDATE, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'

                      into  sam_data_filename
                      from  dual ;
                    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
                    v_FileName := trim(v_FileName) || ',' || trim(sam_data_filename) ;
                end if;
            EXCEPTION
                WHEN OTHERS THEN
                    error_cnt := error_cnt + 1;
                    --DBMS_OUTPUT.PUT_LINE(sqlerrm);
                    --err_code := 'FILE WRITE [' || SQLCODE  || ']' ;
                    --INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                    --VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_DOWN_INTER', 'D', err_code ) ;
                    --DBMS_OUTPUT.PUT_LINE('FILE WRITE4[' || SUBSTR(c1.GET_DATA, -11, 11) || '][' || SQLCODE || ']');
                    COMMIT;
        END;  -- 2.
        << end_loop >>
        NULL;
    END LOOP;

    DBMS_SQL.CLOSE_CURSOR(N_CURSOR);

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log 파일에 남김..

    --INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
    --       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    --VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_DOWN_INTER', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
    --COMMIT;

-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);


O_RsltYN := 'Y';
O_WriteCnt := TO_CHAR(write_cnt) ;
O_FileName := v_FileName  ;

/*
FOR i IN 1..O_WriteCnt LOOP
        DBMS_OUTPUT.PUT_LINE('O_FileName[' || i || '][' || SUBSTR( O_FileName, ( 25 * (i - 1) + 1 ),  24 ) || '
]');
END LOOP ;
*/

EXCEPTION
       WHEN OTHERS THEN
                error_cnt := error_cnt + 1;

                IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
                        DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
                END IF;

                if utl_file.is_open(sam_data_filetype) then
                        utl_file.fclose(sam_data_filetype);
                end if;

                err_code := 'MAIN [' || SQLCODE || ']' ;
                --INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                --VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_DOWN_INTER', 'D', err_code ) ;
                --DBMS_OUTPUT.PUT_LINE('MAIN' || SQLCODE );
       --COMMIT;
END;  -- 1.
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_NMSPACE"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_NMSPACE
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

CURSOR cur_get_data IS
	SELECT         NVL(NM_SPACE, '')
		 || '|' || NVL(TRIM(NM_SPACE_DSC), '')
         AS GET_DATA
	 FROM TB_NM_SPACE ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_NMSPACE Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_nmspace.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	    COMMIT;
        END;
    END LOOP Process_Loop;
	<< end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_NMSPACE Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_ATTR_LIST"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_ATTR_LIST
-- History: (2005.05.20) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

CURSOR cur_get_data IS
	SELECT         NVL(DEVICE_MNG_NUM, '')
		 || '|' || NVL(COMPO_CD, '')
		 || '|' || NVL(SUB_COMPO_CD, '')
		 || '|' || NVL(ATTR_NM, '')
		 || '|' || NVL(ATTR_VAL,'')
         || '|' || NVL(SEQ,'')
         AS GET_DATA
	 FROM TB_UAP_ATTR_LIST ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_ATTR_LIST Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_attr_list.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	    COMMIT;
        END;
    END LOOP Process_Loop;
	<< end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_ATTR_LIST Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_OPEN_CP_DOWN" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_OPEN_CP_DOWN
-- 기능 : UAProfiel DB와 OK NATE에서 망개방CP의 Sync유지를 위해서 실행
-- 변경력: 신규 (2004.72.9) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- --------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- --------------------------------------------------------------------------

-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/netopen'

    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/netopen';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    log_cnt     NUMBER := 0;

-- ------------------------------------------------------
CURSOR cur_get_data IS
	SELECT         NVL(A.OPEN_CP_CD,' ')
		|| '||' || NVL(A.PASSWD,' ')
		|| '||' || NVL(A.CP_NM,' ')
		--|| '||' || NVL(A.CP_DSC,' ')
		|| '||' || NVL(A.ACTIVE_YN,' ')
		|| '||' || NVL(A.DEV_NM,' ')
		|| '||' || NVL(A.DEV_EMAIL,' ')
		|| '||' || NVL(A.DEV_OFFICE,' ')
		|| '||' || NVL(A.DEV_MOBILE,' ')
		|| '||' || NVL(TO_CHAR(A.UPDATE_DT, 'YYYYMMDDHH24MISS'), ' ')
		|| '||' || NVL(TO_CHAR(A.UPDATE_DT, 'YYYYMMDDHH24MISS'), ' ') AS GET_DATA
	FROM TB_OPEN_CP A
	ORDER BY A.OPEN_CP_CD ;
-- ====================
--  Main Process Start
-- ====================
BEGIN -- 1.

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_OPEN_CP_DOWN Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');

-- FILE OPEN
    select 'daily_rdb_cp_info_' || TO_CHAR(I_Work_dt, 'YYYYMMDD') || '.dat'
    into    sam_data_filename
    from    dual ;

    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_OPEN_CP_DOWN(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP -- 2.
    BEGIN  -- 3.

  --  읽은 DATA Count
        read_cnt := read_cnt + 1;

  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN -- 4.
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
			write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT,  ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_OPEN_CP_DOWN(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_OPEN_CP_DOWN(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	   COMMIT;
        END; -- 4.
    END; -- 3.
    << end_loop >>
    NULL;
    END LOOP; -- 2.
-- ===============================================================
-- End Cursor Loop

-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_OPEN_CP_DOWN(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_OPEN_CP_DOWN END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');

EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_OPEN_CP_DOWN(DAILY)', 'D', SYSDATE, substr(err_code,1,300) );
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_OPEN_CP_DOWN(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;

END; --1
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_TB_UAP_ATTR_LIST_DEL" (
        I_Work_dt               IN DATE DEFAULT SYSDATE
)
IS

    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);

    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    v_Get_Data       DBMS_SQL.Varchar2_Table   ;

    N_CURSOR    INTEGER;
    N_RET       INTEGER;
    SQL_TEXT    VARCHAR2(2000);

    fetch_size          NUMBER := 1000 ;
    indx                NUMBER := 1 ;
    v_temp_cnt          NUMBER ;
    v_RecCnt            NUMBER ;

CURSOR cur_get_data IS
        SELECT DEVICE_MNG_NUM AS GET_DATA
        FROM TB_UAP_CHANGE
        WHERE REG_DT >= TRUNC( I_Work_dt - 1 )
          AND REG_DT <  TRUNC( I_Work_dt )
          AND TBL_CD IN ('20', '22')
          AND CHANGE_TP = 'D' ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP_ATTR_LIST_DEL Procedure START '|| TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
    -- FILE OPEN
    select 'daily_tb_uap_attr_list_del_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');


    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
               (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST_DEL(DAILY)', 'S', SYSDATE, 0, 0, 0) ;

    COMMIT;

    << Base_Loop >>
    FOR c1 IN cur_get_data LOOP
    BEGIN

        read_cnt := read_cnt + 1;


        BEGIN

            utl_file.put_line(sam_data_filetype, c1.GET_DATA );

            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;

                        if fetch_cnt = 1000000 then
                            file_seq  := file_seq + 1;
                            fetch_cnt := 0;
                                utl_file.fclose(sam_data_filetype);
                                select 'daily_tb_uap_attr_list_del_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
                                into    sam_data_filename
				from    dual ;
                                sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

                        end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST_DEL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST_DEL(DAILY)', 'D', SYSDATE,substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST_DEL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST_DEL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            COMMIT;
        END;

    END;
    << end_loop >>
    NULL;
    END LOOP Base_Loop;

    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST_DEL(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;

        COMMIT;

    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP_ATTR_LIST_DEL Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');

EXCEPTION
       WHEN NO_DATA_FOUND THEN
             error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST_DEL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
             error_cnt := error_cnt + 1;
             err_code  := SQLCODE || SQLERRM;
             INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)

             VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST_DEL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
             error_cnt := error_cnt + 1;
             err_code  := SQLCODE || SQLERRM;
             INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
             VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST_DEL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
             error_cnt := error_cnt + 1;
             err_code  := SQLCODE || SQLERRM;
             INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
             VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST_DEL(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."MONTHLY_CUST_ADDED_COUNT"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : monthly_cust_added_count
-- 기능 : 증권VM 및 TCASH 부가서비스의 전월기준 총 가입자 수
--        정보의 이력을 SAM 파일생성(TB_CUST_ADDED_SVC)
--        * 같은 내용도 모두 출력
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
        log_cnt     NUMBER := 0;
        err_code    varchar2(200);
        VM_COUNT        NUMBER := 0;
        TCASH_COUNT  NUMBER := 0;
        T_SYSDATE       varchar2(20);
-- -- --------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- --------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
        sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
        sam_data_filename   VARCHAR2(50)  := '';
        sam_data_filetype   utl_file.file_type;

-- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
        DBMS_OUTPUT.ENABLE ( 1000000);
        DBMS_OUTPUT.PUT_LINE( '***** [ monthly_cust_added_count Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');

        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
                (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
        VALUES (SEQ_JOB_LOG.NEXTVAL, 'monthly_cust_added_count(monthly)', 'S', SYSDATE, 0, 0, 0) ;
        COMMIT;

-- FILE OPEN
        SELECT  'monthly_cust_added_count_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.dat'
        INTO     sam_data_filename
        FROM    DUAL ;

        sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

-- SYSDATE
        SELECT TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')
        INTO T_SYSDATE
        FROM DUAL;

-- VM COUNT
        SELECT COUNT(*)
        INTO VM_COUNT
        FROM TB_CUST_ADDED_SVC
        WHERE ADDED_SVC_CD in (
        'NA00000371'  --우리투자증권 ⓜ스톡
        ,'NA00000374'  --증권거래VM(대우Wi-TOP)
        ,'NA00000375'  --증권거래VM(대우)
        ,'NA00000394'  --증권거래VM(굿모닝신한증권)
        ,'NA00000370'  --증권거래VM(대신)
        ,'NA00000380'  --증권거래VM(미래에셋)
        ,'NA00000388'  --증권거리VM(부국증권)
        ,'NA00000384'  --증권거리VM(SK증권)
        ,'NA00000392'  --증권거래VM(대한투자신탁)
        ,'NA00000393'  --증권거래VM(신흥증권)
        ,'NA00000381'  --증권거래VM(E*Trade)
        ,'NA00000383'  --증권거래VM(동양)
        ,'NA00000382'  --증권거래VM(한화)
        ,'NA00000379'  --증권거래VM(동원)
        ,'NA00000377'  --증권거래VM(키움닷컴)
        ,'NA00000376'  --증권거래VM(교보)
        ,'NA00000387'  --증권거리VM(한양증권)
        ,'NA00001991'  --3G MSTOCK 동양증권
        ,'NA00001989'  --3G MSTOCK SK증권
        ,'NA00002215'  --삼성증권(WIPI)정액제
        ,'NA00002205'  --3G MSTOCK 굿모닝신한증권
        ,'NA00002207'  --3G MSTOCK CJ투자증권
        ,'NA00002217'  --SKT WIPI 유진증권
        ,'NA00002216'  --유퍼스트무버WIPIC
        ,'NA00002232'  --ⓜ스톡 PLUS(교보증권)
        ,'NA00002355'  --HiFive바로증권(하나대투)
        ,'NA00002359'  --3G MSTOCK 한화증권
        ,'NA00002362'  --3G MSTOCK 한국투자증권
        ,'NA00002490'  --SKT WIPI KB투자증권
        ,'NA00002489'  --미래에셋 VM 증권 정액제
        ,'NA00002612'  --대기화면 증권서비스
        ,'NA00002702'  --대신증권 대기화면
        ,'NA00002703'  --키움증권 대기화면
        ,'NA00002704'  --미래에셋 대기화면
        ,'NA00002705'  --KB투자증권 대기화면
        ,'NA00002710'  --신한금융투자대기화면
        ,'NA00002720'  --현대증권 대기화면
        ,'NA00002721'  --우리투자증권대기화면
        ,'NA00002774'  --동양종금증권대기화면
        ,'NA00002775'  --이트레이드 대기화면
        ,'NA00002776'  --유진투자증권대기화면
        ,'NA00002779'  --SK증권 대기화면
        ,'NA00002838'  --대우증권 대기화면
        ,'NA00002859'  --HMC투자증권 대기화면
        ,'NA00002860'  --하나대투증권대기화면
        ,'NA00002858'  --메리츠증권 대기화면
        ,'NA00002809'  --한국투자증권대기화면
        )
        AND TO_CHAR(REG_DT, 'YYYYMM') < TO_CHAR(SYSDATE, 'YYYYMM');

-- T CASH COUNT
        SELECT COUNT(*)
        INTO TCASH_COUNT
        FROM TB_CUST_ADDED_SVC
        WHERE ADDED_SVC_CD in (
        'NC00000029'  --T cash 휴대폰 간편충전 정액제
        ,'NC00000030'  --T cash 청소년 간편충전 정액제1
        ,'NC00000031'  --T cash 청소년 간편충전 정액제2
        ,'NC00000033'  --T cash 청소년 용돈충전 정액제2
        ,'NC00000042'  --Tcash충전-모바일카드
        )
        AND TO_CHAR(REG_DT, 'YYYYMM') < TO_CHAR(SYSDATE, 'YYYYMM');

        utl_file.put_line(sam_data_filetype, TO_CHAR(SYSDATE, 'YYYYMM') ||','|| 'MPLAYON_VM' ||','|| VM_COUNT ||','|| T_SYSDATE);
        utl_file.put_line(sam_data_filetype, TO_CHAR(SYSDATE, 'YYYYMM') ||','|| 'TCASH_AUTOCHRG' ||','|| TCASH_COUNT ||','|| T_SYSDATE);
        utl_file.fclose(sam_data_filetype);

--  최종 작업결과를 Log Table에 남김..
        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
                (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
        VALUES (SEQ_JOB_LOG.NEXTVAL, 'monthly_cust_added_count(monthly)', 'E', SYSDATE, 0, 0, 0) ;

        COMMIT;

-- --------------------------------------------------------------------------
-- 작업완료 확인 파일생성
-- --------------------------------------------------------------------------
        SELECT  NVL(COUNT(*),0)
        INTO     log_cnt
        FROM    TB_JOB_LOG
        WHERE   TO_CHAR(RUN_DT, 'YYYYMMDD') = TO_CHAR(SYSDATE, 'YYYYMMDD')
                AND STATUS = 'E' AND PROGRAM LIKE 'monthly_cust_added_count%';

        if log_cnt >= 1 then  -- 작업 완료 Log 남김
                SELECT  'monthly_cust_added_count_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.log'
                INTO     sam_data_filename
                FROM    DUAL;

                sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
                utl_file.put_line(sam_data_filetype, log_cnt);
                utl_file.fclose(sam_data_filetype);
        end if;

        DBMS_OUTPUT.PUT_LINE( '***** [ VM COUNT  [' || VM_COUNT || '] *****');
        DBMS_OUTPUT.PUT_LINE( '***** [ TCASH COUNT  [' || TCASH_COUNT || '] *****');
        DBMS_OUTPUT.PUT_LINE( '***** [ monthly_cust_added_count Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');

EXCEPTION
        WHEN OTHERS THEN
                err_code  := SQLCODE || SQLERRM;

                INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'monthly_cust_added_count(monthly)', 'D', SYSDATE, substr(err_code,1,150) ) ;
                DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  || '] *****');
                COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_FW_VIEW" (
     I_Ua_Manufacturer   IN  TB_UAP.UAF_DEVICE_MANUF%TYPE
    ,I_Ua_Model          IN  TB_UAP.UAF_DEVICE_MODEL%TYPE
    ,O_RsltYN           OUT  VARCHAR2
    ,O_RecCnt           OUT  NUMBER
    ,O_Record           OUT  DBMS_SQL.VARCHAR2_TABLE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : SP_FW_VIEW
-- 기능 : UAProfiel DB와 다른 시스템 SoftwareDownload 연동에서 해당 단말정보를
--        DownLoad 하기전에 호출되어, Download될 정호를 확인하는데 호출
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count -- O_Record           OUT DBMS_SQL.VARCHAR2_TABLE
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    VARCHAR2(200);
    log_data    VARCHAR2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------

    -- FETCH 할 변수
    N_CURSOR    INTEGER;
    N_RET       INTEGER;
    SQL_TEXT    VARCHAR2(1500);

    fetch_size  NUMBER := 1000 ;
    indx        NUMBER := 1 ;
-- ====================
--  Main Process Start
-- ====================
BEGIN   -- 1.
    -- 1. 입력값 체크
    O_RsltYN := 'N';

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	--INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	--   (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	--VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_VIEW', 'S', SYSDATE, 0, 0, 0) ;
	--COMMIT;

    -- 제조사 와 모델명으로 조회
    SQL_TEXT :=    'SELECT DISTINCT SUBSTRB(NVL(DEV.UAF_DEVICE_MANUF,''''),1) '
				|| '|| '','''
				|| '|| SUBSTRB(NVL(DEV.UAF_DEVICE_MODEL,''''),1) '
				|| ' FROM  TB_UAP DEV '
				|| 'WHERE  DEV.UAF_DEVICE_MANUF like ''%''||TRIM(:b_Ua_Manufacturer)||''%'''
				|| '  AND  DEV.UAF_DEVICE_MODEL like ''%''||TRIM(:b_Ua_Model)||''%'''
			;
    -- ============
    -- CURSOR 처리
    -- ============
    N_CURSOR := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(N_CURSOR, SQL_TEXT, DBMS_SQL.NATIVE);
    O_RsltYN := '7';

    -- 제조사 와 모델명으로 조회
    DBMS_SQL.BIND_VARIABLE(N_CURSOR, ':b_Ua_Manufacturer', I_Ua_Manufacturer) ;
    DBMS_SQL.BIND_VARIABLE(N_CURSOR, ':b_Ua_Model'       , I_Ua_Model       ) ;

    DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 1, O_Record, fetch_size, indx );

    N_RET := DBMS_SQL.EXECUTE(N_CURSOR);

    LOOP
		N_RET := DBMS_SQL.FETCH_ROWS(N_CURSOR);
		--DBMS_OUTPUT.PUT_LINE(N_RET);
		O_RecCnt := DBMS_SQL.LAST_ROW_COUNT ;
		--DBMS_OUTPUT.PUT_LINE('FETCH_CNT [' || O_RecCnt || ']');

		DBMS_SQL.COLUMN_VALUE(N_CURSOR, 1, O_Record);
    EXIT WHEN N_RET != fetch_size ;

    END LOOP;

    DBMS_SQL.CLOSE_CURSOR(N_CURSOR);

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log 파일에 남김..
	--INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	--      (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	--VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_VIEW', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;

	--COMMIT;
	O_RsltYN := 'Y';

EXCEPTION
       WHEN NO_DATA_FOUND THEN
			O_RsltYN := 'Y';
			O_RecCnt := 0 ;

			IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
				DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
			END IF ;

			err_code := 'MAIN  [' || SUBSTR(SQLERRM,1,200) || ' : ' || SQLCODE ||']' ;
			--INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			--VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_VIEW', 'D', err_code ) ;
			--DBMS_OUTPUT.PUT_LINE('MAIN' || SUBSTR(SQLERRM,1,200)  );

       WHEN OTHERS THEN
            O_RsltYN := 'N';
            error_cnt := error_cnt + 1;

			IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
				DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
			END IF ;

            err_code := 'MAIN  [' || SUBSTR(SQLERRM,1,200) || ' : ' || SQLCODE ||']' ;
			--INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			--VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_VIEW', 'D', err_code ) ;
			--DBMS_OUTPUT.PUT_LINE('MAIN' || SUBSTR(SQLERRM,1,200)  );

		--COMMIT;
END;  -- 1.
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_CHARGE_CD" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_CHARGE_CD
-- 기능 : UAProfiel DB와 다른 시스템(IMS) 연동에서 일일 대사를 위해(요금제코드)
--        SAM 파일생성(TB_CUST_PERSON, TB_CUST_PROF)
--        임시로 사용하고 PMH로 적용시 사용 안함
-- 변경력: 신규 (2005.11.09) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   CURSOR DEFINE  ( 206자리)
------------------------------
--   COMPO_CD           (  2)
--   SUB_COMPO_CD       (  4)
--   SUB_COMPO_NM       (200)
-- --------------------------
CURSOR cur_get_data IS
    /* 하루동안 변경 된 정보가 고객정보와 고객개인정보에 있으므로 그런 건에 대한
 사항을 같이
       처리 하기위한 UNION 처리 */
    SELECT COL_DATA AS GET_DATA
    FROM (
		SELECT            PROF.SVC_MNG_NUM
				|| '|' || NVL(PROF.MOBILE_SVC_NUM, '')|| '|' || NVL(PROF.MOBILE_ID_NUM, '')|| '|' || NVL(PROF.CLIENT_ID_CUST, '')
				|| '|' || NVL(PROF.DEVICE_MNG_NUM, '')|| '|' || TO_CHAR(PROF.UPDATE_DT, 'YYYYMMDDHH24MISS') || '|' ||NVL(PERSON.CHARGE_CD, '') AS COL_DATA
		FROM TB_CUST_PERSON PERSON, TB_CUST_PROF PROF
	    WHERE   PERSON.SVC_MNG_NUM =PROF.SVC_MNG_NUM
            AND PERSON.CHARGE_CD IN ('CTBBA', 'CTBSV', 'CTSTA', 'CCOOL', 'CTPLS')
	    AND PERSON.UPDATE_DT >= TRUNC( I_Work_dt - 1) -- ONE DAY DATA
	    AND PERSON.UPDATE_DT <  TRUNC( I_Work_dt )
            AND PROF.MVNO_CD = '0' -- 2011.07.15 COLUS3 - MVNO사업자 구분코드가 '0'(SKT)인 데이터만 추출
            )
    ;
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_CHARGE_CD Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') ||' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_charge_cd_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CHARGE_CD(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;
    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'daily_charge_cd_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CHARGE_CD(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CHARGE_CD(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CHARGE_CD(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CHARGE_CD(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CHARGE_CD(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_CHARGE_CD Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CHARGE_CD(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CHARGE_CD(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CHARGE_CD(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CHARGE_CD(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_CUST_PROF" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_CUST_PROF
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 일일 대사를 위한 변경분
--        SAM 파일생성
-- 변경력: 신규 (2003.11.05) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/cust'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    log_cnt     NUMBER := 0;
-- ---------------------------
--   CURSOR DEFINE  ( 45자리)
------------------------------
--   SVC_MNG_NUM         (10)
--   UPDATE_CD           ( 2)
--   MOBILE_SVC_NUM      (11)
--   COIS_DEVICE_CD      ( 4)
--   COIS_DEVICE_VER     ( 4)
--   UPDATE_DT           (14)
-- --------------------------
CURSOR cur_get_data IS
	SELECT  RPAD(NVL(SKT.SVC_MNG_NUM, ' '), 10, ' ')
	     || RPAD(NVL(SKT.UPDATE_CD, ' '), 2, ' ')
	     || RPAD(NVL(SKT.MOBILE_SVC_NUM, ' '), 11, ' ')
	     || RPAD(NVL(DEV.COIS_DEVICE_CD, ' '), 4, ' ')
	     || RPAD(NVL(DEV.COIS_DEVICE_VER, ' '), 4, ' ')
	     || NVL(TO_CHAR(SKT.UPDATE_DT, 'YYYYMMDDHH24MISS'), RPAD(' ', 14)) AS GET_DATA
	FROM ( SELECT H.SVC_MNG_NUM, H.UPDATE_CD, H.MOBILE_SVC_NUM, H.END_DT AS UPDATE_DT, H.DEVICE_MNG_NUM
		   FROM TB_CUST_PROF_HIST H
		   WHERE H.END_DT >= TRUNC( I_Work_dt - 1) -- ONE DAY DATA
		   AND   H.END_DT <  TRUNC( I_Work_dt )
		   AND   H.UPDATE_CD IN ( 'Z1', 'Z2', 'Z4' )
                   AND   H.MVNO_CD = '0'     -- 2011.07.15 COLUS3 - MVNO사업자 구분코드가 '0'(SKT)인 데이터만 추출
		   AND  NOT EXISTS (
		   		SELECT 'X'
		   		FROM TB_CUST_PROF S
		   		WHERE S.SVC_MNG_NUM = H.SVC_MNG_NUM
		   		)
		   UNION
	       SELECT SVC_MNG_NUM, UPDATE_CD, MOBILE_SVC_NUM, UPDATE_DT, DEVICE_MNG_NUM
		   FROM TB_CUST_PROF
		   WHERE UPDATE_DT >= TRUNC( I_Work_dt - 1) -- ONE DAY DATA
		   AND   UPDATE_DT <  TRUNC( I_Work_dt )
                   AND   MVNO_CD = '0'    -- 2011.07.15 COLUS3 - MVNO사업자 구분코드가 '0'(SKT)인 데이터만 추출
              )  SKT,
	     TB_UAP DEV
	WHERE SKT.DEVICE_MNG_NUM = DEV.DEVICE_MNG_NUM
	ORDER BY SKT.UPDATE_DT ;
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_CUST_PROF Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_cust_prof_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;
    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'daily_cust_prof_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
-- --------------------------------------------------------------------------
-- 작업완료 확인 파일생성
-- --------------------------------------------------------------------------
	SELECT NVL(COUNT(*),0) INTO log_cnt FROM GAEBAL_UPADM.TB_JOB_LOG
	WHERE TO_CHAR(RUN_DT, 'YYYYMMDD') = TO_CHAR(SYSDATE, 'YYYYMMDD')
	AND STATUS = 'E' AND PROGRAM LIKE '%DAILY_CUST_PROF%';
	--------
	-- 일단 고객정보에대해 돌아가는것이 하나니깐 하나만 돌아갔으면 그걸로 오케이 하야겠지.
	--------
    if log_cnt > 0 then  -- 작업 완료 Log 남김
		select 'daliy_cust_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '_XX.log'
		into    sam_data_filename
		from    dual ;
	    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
	    utl_file.fclose(sam_data_filetype);
    end if;
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_CUST_PROF END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_CUST_MMS_VER"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_CUST_MMS_VER
-- 기능 : UAProfiel DB와 MMS버젼별 연동에서 초기화를 위한
--        SAM 파일생성(TB_CUST_PROF, TB_UAP, TB_UAP_ATTR_LIST)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
CURSOR cur_get_data IS
	-- MMS H/S Menu 에서 사용하는 것
	SELECT           CUST.SVC_MNG_NUM
	       || ',' || DEV.MODEL_CD
	       || ',' || DEV.MMS_VER AS GET_DATA
	FROM
	    (
	      SELECT SVC_MNG_NUM, DEVICE_MNG_NUM
	      FROM TB_CUST_PROF
	      WHERE DEVICE_MNG_NUM IN (
	         SELECT DISTINCT DEVICE_MNG_NUM
	         FROM TB_UAP_ATTR_LIST
	         WHERE ATTR_NM = 'MmsVersion'
	         )
	    ) CUST,
	    (
	      SELECT A.DEVICE_MNG_NUM, NVL(UPPER(A.UAF_DEVICE_MANUF),'XX') || NVL(A.UAF_DEVICE_MODEL, 'XX') MODEL_CD, B.ATTR_VAL AS MMS_VER
	      FROM TB_UAP A,
	          ( SELECT DISTINCT DEVICE_MNG_NUM, ATTR_VAL
	            FROM TB_UAP_ATTR_LIST
	           WHERE ATTR_NM = 'MmsVersion' ) B
	      WHERE A.DEVICE_MNG_NUM = B.DEVICE_MNG_NUM
	    ) DEV
	WHERE CUST.DEVICE_MNG_NUM = DEV.DEVICE_MNG_NUM ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_MMS_VER Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_cust_mms_ver_' || TO_CHAR(SYSDATE, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_MMS_VER(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_cust_mms_ver_' || TO_CHAR(SYSDATE, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_MMS_VER(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_MMS_VER Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')   || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_MMS_VER(INIT)', 'D', substr(err_code,1,150) ) ;


       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_MMS_VER(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_MMS_VER(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_MMS_VER(INIT)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_CUST_PROF"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_CUST_PROF
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 초기화를 위한
--        SAM 파일생성(TB_CUST_PROF)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
CURSOR cur_get_data IS
	-- MMS H/S Menu 에서 사용하는 것
	SELECT        SVC_MNG_NUM
	    || '|' || DEVICE_MNG_NUM
	    || '|' || MOBILE_ID_NUM
	    || '|' || MOBILE_SVC_NUM
	    || '|' || NET_GEN_TP
	    || '|' || CLIENT_ID_YN
	    || '|' || CLIENT_ID_NET2G
	    || '|' || CLIENT_ID_NET3G
	    || '|' || CLIENT_ID_CUST
	    || '|' || IMSI
	    || '|' || IMEI
	    || '|' || UPDATE_CD
	    || '|' || NVL(TO_CHAR(UPDATE_DT , 'YYYYMMDDHH24MISS'), NULL)
	    || '|' || UPDATE_PATH     AS GET_DATA
	FROM TB_CUST_PROF  ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_PROF Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_uap_cust_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_uap_cust_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_PROF Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF(INIT)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_TB_COMPO"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_TB_COMPO
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 초기화를 위한
--        SAM 파일생성(TB_COMPO)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   CURSOR DEFINE  ( 52자리)
------------------------------
--   COMPO_CD           ( 2)
--   COMPO_NM           (50)
-- --------------------------
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(COMPO_NM, '') AS GET_DATA
	FROM TB_COMPO ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_COMPO Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_tb_compo_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES ( SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_COMPO(INIT)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_tb_compo_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_COMPO(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_COMPO Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
             error_cnt := error_cnt + 1;
             err_code  := SQLCODE || SQLERRM;
   	         INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
             VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
             error_cnt := error_cnt + 1;
             err_code  := SQLCODE || SQLERRM;
             INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
             VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300)) ;

       WHEN TOO_MANY_ROWS THEN
             error_cnt := error_cnt + 1;
             err_code  := SQLCODE || SQLERRM;
             INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
             VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
             error_cnt := error_cnt + 1;
             err_code  := SQLCODE || SQLERRM;
             INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
             VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_COMPO(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_SKT_HIST_DEL" (
	 I_Work_dt 	IN DATE DEFAULT SYSDATE - 180,
	 I_Del_Flag IN CHAR DEFAULT 'H'
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : SP_SKT_HIST_DEL
-- 기능 : 해당되는 날짜 이전의 고객 이력 정보를 삭제 한다.
--        날짜        : 해당요일 이전데이터 대상(기본적으로 현재일로 180일이전)
--        삭제 구분  H: History 만 삭제 한다. 이 경우 고객정보 쪽에 존재하지 않더
--                      라도 History는 남아있음(기본적으로 Z1,Z2 일 가능성이 많음)
--                   A: 모든정보 삭제 기본적인 기능은 H와 같으나, 고객정보쪽에 존재
--                      하지 않는경우에는 이력도 삭제 한다.
--
-- 변경력: 2004. 10. 29
--         1. 신규 생성 - compleus -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
	fetch_cnt   NUMBER := 0;  -- 작업 대상건수
	error_cnt   NUMBER := 0;
	target_cnt  NUMBER := 0;  -- 총 대상건수
    del_cnt     NUMBER := 0;  -- 총 대상건수에서 삭제한 건수
    alive_cnt   NUMBER := 0;  -- 총 대상건수에서 삭제하고 남은 건수
    err_code    VARCHAR2(300);
    ERR_MSG     VARCHAR2(100);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -----------------------------------------------------------------------------
-- 단수 참조에서 사용되는 변수
-- -----------------------------------------------------------------------------
    v_temp_cnt          NUMBER ;
    v_Target_cnt        NUMBER ;
    v_Exist_cnt         NUMBER ;
-- -----------------------------------------------------------------------------
-- 처리에 사용되 변수
-- -----------------------------------------------------------------------------


-- 입력날짜 보다(기본 180일전) 이전 대상 전체 확인
CURSOR cur_get_data IS
	SELECT  DISTINCT SVC_MNG_NUM
	FROM TB_CUST_PROF_HIST
	WHERE END_DT <=  I_Work_dt ;

BEGIN
	ERR_MSG := '최초 Procedure' ;

	DBMS_OUTPUT.ENABLE ( 1000000);
	DBMS_OUTPUT.PUT_LINE( '***** [ SP_SKT_HIST_DEL Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || '] *****');

    ERR_MSG := '에러로그파일 열기' ;-- FILE OPEN
    select 'sp_skt_hist_del_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

    ERR_MSG := 'DB 로그 시작' ;
    -- 시작 로그 DB저장
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_SKT_HIST_DEL(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    ERR_MSG := '데이터 FATCH' ;
    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
	    -- 메인 처리
	    BEGIN
	    	fetch_cnt := fetch_cnt + 1 ;

	        -- 에러메시지 셋팅
	        ERR_MSG := 'FATCH 처리에러 서비스관리번호[' || c1.SVC_MNG_NUM || ']' ;

	        -- 전체 이력 건수
	    	SELECT COUNT(*) INTO v_Exist_cnt
	    	FROM TB_CUST_PROF_HIST
	    	WHERE SVC_MNG_NUM = c1.SVC_MNG_NUM ;

	    	-- 작업 대상 이력 건수
	    	SELECT COUNT(*) INTO v_Target_cnt
	    	FROM TB_CUST_PROF_HIST
	    	WHERE SVC_MNG_NUM = c1.SVC_MNG_NUM
	    	AND END_DT <=  I_Work_dt ;

	    	target_cnt := target_cnt + v_Target_cnt ;

			-- 작업 대상의 건수가 총 이력 건수와 같으면 한건은 지우면 안됨
			IF ( v_Exist_cnt = v_Target_cnt ) THEN
				-- 최종적 1건의 정보는 남기고 대상 이력 삭제
				DELETE FROM TB_CUST_PROF_HIST
				WHERE ( SVC_MNG_NUM, START_DT, END_DT ) NOT IN ( SELECT SVC_MNG_NUM, MAX(START_DT), MAX(END_DT)
				                                           FROM TB_CUST_PROF_HIST
				                                           WHERE SVC_MNG_NUM = c1.SVC_MNG_NUM
				                                           GROUP BY SVC_MNG_NUM )
				AND SVC_MNG_NUM = c1.SVC_MNG_NUM
				AND END_DT <=  I_Work_dt ;
			ELSE
				-- 모든 이력 삭제
				DELETE FROM TB_CUST_PROF_HIST
				WHERE SVC_MNG_NUM = c1.SVC_MNG_NUM
				AND END_DT <=  I_Work_dt ;
			END IF ;

			-- 삭제 건수 확인
			del_cnt := del_cnt + SQL%ROWCOUNT ;
			alive_cnt := alive_cnt + ( v_Target_cnt - SQL%ROWCOUNT ) ;

			v_temp_cnt := 0 ;
			-- 고객정보에 없는 정보도 삭제
			IF (I_Del_Flag  = 'A') THEN
				SELECT COUNT(*) INTO v_temp_cnt
				FROM TB_CUST_PROF
				WHERE SVC_MNG_NUM = c1.SVC_MNG_NUM ;

				IF ( v_temp_cnt = 0 ) THEN
					DELETE FROM TB_CUST_PROF_HIST
					WHERE SVC_MNG_NUM = c1.SVC_MNG_NUM ;

					del_cnt := del_cnt + SQL%ROWCOUNT ;

					-- 삭제 처리가 되었다고 하면 살아 있는 건수는 없는거니깐 1건 마이너스!
					IF ( SQL%ROWCOUNT > 0 ) THEN
						alive_cnt := alive_cnt - 1 ;
					END IF ;

				END IF ;

			END IF ;

			COMMIT ;

	    EXCEPTION
	        WHEN OTHERS THEN
	        	error_cnt := error_cnt + 1 ;
                err_code  := ERR_MSG || SQLCODE || SQLERRM;
                ROLLBACK ;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_SKT_HIST_DEL(DAILY)', 'D', substr(err_code,1,300) ) ;

	        	utl_file.put_line(sam_data_filetype, ERR_MSG );
				--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
				if error_cnt = 1000000 then
					file_seq  := file_seq + 1;
					fetch_cnt := 0;
					utl_file.fclose(sam_data_filetype);
					select 'sp_skt_hist_del_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
					into    sam_data_filename
					from    dual ;
					sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
				end if;

		   	    COMMIT;
		END ;
    END LOOP Process_Loop;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	ERR_MSG := 'DB 로그 종료' ;
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_SKT_HIST_DEL(DAILY)', 'E', SYSDATE, fetch_cnt, del_cnt, error_cnt) ;
	COMMIT;

	ERR_MSG := '파일 닫기' ;
    utl_file.fclose(sam_data_filetype);

	ERR_MSG := '화면 출력' ;
    DBMS_OUTPUT.PUT_LINE( '***** [ 대상건수     [' || fetch_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [   총대상건수 [' || target_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [    총삭제건수[' || del_cnt    || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [    존재건수  [' || alive_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ 에러건수     [' || error_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ SP_SKT_HIST_DEL Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');

EXCEPTION
       WHEN NO_DATA_FOUND THEN
			err_code  := ERR_MSG || SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_SKT_HIST_DEL(DAILY)', 'D', substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := ERR_MSG || SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_SKT_HIST_DEL(DAILY)', 'D', substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := ERR_MSG || SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_SKT_HIST_DEL(DAILY)', 'D', substr(err_code,1,300) ) ;


       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := ERR_MSG || SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_SKT_HIST_DEL(DAILY)', 'D', substr(err_code,1,300) ) ;
       COMMIT;
END;	-- 1.
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_UAP"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_UAP
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

-- -- -----------------------------------------------------------------------------
-- -- Cursor
-- -- -----------------------------------------------------------------------------
CURSOR cur_get_data IS
	SELECT     DEVICE_MNG_NUM
		 || '|' || NVL(URI, '')
		 || '|' || NVL(UAP_YN, '')
		 || '|' || NVL(COIS_DEVICE_CD, '')
		 || '|' || NVL(COIS_DEVICE_VER, '')
		 || '|' || NVL(PDA_YN, '')
		 || '|' || NVL(UAF_DEVICE_MANUF, '')
		 || '|' || NVL(UAF_DEVICE_MODEL, '')
		 || '|' || NVL(UAF_DEVICE_MODEL_DSC, '')
         || '|' || NVL(TRIM(EXEC_ID), '')
         || '|' || NVL(TO_CHAR(UPDATE_DT , 'YYYYMMDDHH24MISS'), TO_CHAR(SYSDATE , 'YYYYMMDDHH24MISS'))
         || '|' || NVL(TRIM(UPDATE_PATH), '')
         || '|' || NVL(TO_CHAR(COIS_UPDATE_DT , 'YYYYMMDDHH24MISS'), TO_CHAR(SYSDATE , 'YYYYMMDDHH24MISS'))
         AS GET_DATA
	 FROM TB_UAP
	 ORDER BY DEVICE_MNG_NUM ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_UAP Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');-- FILE OPEN
    select 'init_ldap_uap.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA );
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
  	    COMMIT;
        END;
    END LOOP Process_Loop;
    << end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_UAP Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_UAF_MAP"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_UAF_MAP
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

CURSOR cur_get_data IS
	SELECT        DEVICE_MNG_NUM
        || '|' || SUBSTR(UAF_DATA, 1,1)
		|| '|' || SUBSTR(UAF_DATA, 2,2)
		|| '|' || SUBSTR(UAF_DATA, 4,2)
		|| '|' || SUBSTR(UAF_DATA, 6,2)
		|| '|' || SUBSTR(UAF_DATA, 8,2)
		|| '|' || SUBSTR(UAF_DATA,10,3)
		|| '|' || SUBSTR(UAF_DATA,13,3)
		|| '|' || SUBSTR(UAF_DATA,16,2)
		|| '|' || SUBSTR(UAF_DATA,18,2)
		|| '|' || SUBSTR(UAF_DATA,20,2)
        AS GET_DATA
	 FROM TB_UAF_MAP
     ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_UAF_MAP Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
	-- FILE OPEN
    select 'init_ldap_uaf_map.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	    COMMIT;
        END;
    END LOOP Process_Loop;
	<< end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_UAF_MAP Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '*****  MAIN [' || SQLCODE || SQLERRM || '] *****');
       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '*****  MAIN [' || SQLCODE || SQLERRM || '] *****');
       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '*****  MAIN [' || SQLCODE || SQLERRM || '] *****');
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '*****  MAIN [' || SQLCODE || SQLERRM || '] *****');
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_DATATP"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_DATATP
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

CURSOR cur_get_data IS
	SELECT         NVL(DATA_TP, '')
		 || '|' || NVL(TRIM(DATA_TP_DSC), '')
         AS GET_DATA
	 FROM TB_DATA_TP ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_DATATP Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_datatp.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	    COMMIT;
        END;
    END LOOP Process_Loop;
	<< end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_DATATP Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '*****  MAIN [' || SQLCODE || SQLERRM || '] *****');
       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '*****  MAIN [' || SQLCODE || SQLERRM || '] *****');
       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '*****  MAIN [' || SQLCODE || SQLERRM || '] *****');
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '*****  MAIN [' || SQLCODE || SQLERRM || '] *****');
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_COMPO"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_COMPO
-- History: (2005.05.20) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- RESULT COUNT VARIABLE
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(COMPO_NM, '')
            || '|' || NVL(COMPO_SEQ, '')
            || '|' || NVL(TRIM(COMPO_DSC), '')
            || '|'
            -- 실적용때는 위에꺼 주석처리할고 아래 주석해지
            --|| '|' || NVL(TRIM(RESOURCE_URI), '')
            AS GET_DATA
	FROM TB_COMPO ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_COMPO Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_compo.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA Count
            write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_COMPO Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    ||' ] *****');
EXCEPTION
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_ATTR_VAL"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_ATTR_VAL
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
--
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_CD, '')
			|| '|' || NVL(ATTR_NM, '')
			|| '|' || NVL(ATTR_VAL, '')
            || '|' || NVL(TRIM(ATTR_VAL_DSC), '')
            AS GET_DATA
	FROM TB_UAP_ATTR_VAL;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_ATTR_VAL Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_attr_val.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA Count
            write_cnt := write_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_ATTR_VAL Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_TB_UAP_ATTR_LIST" (
        I_Work_dt               IN DATE DEFAULT SYSDATE
)
IS

    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);

    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    v_Get_Data       DBMS_SQL.Varchar2_Table   ;

    N_CURSOR    INTEGER;
    N_RET       INTEGER;
    SQL_TEXT    VARCHAR2(2000);

    fetch_size          NUMBER := 1000 ;
    indx                NUMBER := 1 ;
    v_temp_cnt          NUMBER ;
    v_RecCnt            NUMBER ;

CURSOR cur_get_data IS
        SELECT DEVICE_MNG_NUM
        FROM TB_UAP_CHANGE
        WHERE REG_DT >= TRUNC( I_Work_dt - 1 )
          AND REG_DT <  TRUNC( I_Work_dt )
          AND TBL_CD IN ('20', '22')
          AND CHANGE_TP != 'D' ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP_ATTR_LIST Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_tb_uap_attr_list_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'

    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');


    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
               (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST(DAILY)', 'S', SYSDATE,0, 0, 0) ;

    COMMIT;

    << Base_Loop >>
    FOR c1 IN cur_get_data LOOP
    BEGIN
            BEGIN

                SQL_TEXT :='SELECT       NVL(DEVICE_MNG_NUM, '''')       '
                                || ' || ''|'' || NVL(COMPO_CD, '''')             '
                                || ' || ''|'' || NVL(SUB_COMPO_CD, '''')         '
                                || ' || ''|'' || NVL(ATTR_NM, '''')              '
                                || ' || ''|'' || NVL(ATTR_VAL,'''') AS GET_DATA  '
                                || ' FROM TB_UAP_ATTR_LIST           '
                                || ' WHERE DEVICE_MNG_NUM = ''' || C1.DEVICE_MNG_NUM || '''' ;


                N_CURSOR := DBMS_SQL.OPEN_CURSOR;
                DBMS_SQL.PARSE(N_CURSOR, SQL_TEXT, DBMS_SQL.NATIVE);

			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 1, v_Get_Data         , fetch_size, indx );

                N_RET := DBMS_SQL.EXECUTE(N_CURSOR);

                v_temp_cnt := 1 ;
                << Internal_Cursor_Loop >>
                LOOP
                    N_RET := DBMS_SQL.FETCH_ROWS(N_CURSOR);
                    --DBMS_OUTPUT.PUT_LINE(N_RET);
                    v_RecCnt := DBMS_SQL.LAST_ROW_COUNT ;
                    --DBMS_OUTPUT.PUT_LINE('FETCH_CNT [' || v_RecCnt || ']');

                    DBMS_SQL.COLUMN_VALUE(N_CURSOR, 1, v_Get_Data       );
                    /*
                    DBMS_OUTPUT.PUT_LINE('v_RecCnt        [' || v_RecCnt      || ']');
                    DBMS_OUTPUT.PUT_LINE('v_Get_Data      [' || v_Get_Data(v_temp_cnt)      || ']');
                    */

                    v_temp_cnt := v_temp_cnt + 1 ;

                    EXIT WHEN N_RET != fetch_size ;
                END LOOP Internal_Cursor_Loop ;

                IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
                    DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
                END IF;

            EXCEPTION
                WHEN OTHERS THEN

                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

                    IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
                        DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
                    END IF;
            END ;

            << Process_Loop >>
            FOR i IN 1..v_RecCnt LOOP

                read_cnt := read_cnt + 1;

                BEGIN

                    utl_file.put_line(sam_data_filetype, v_Get_Data(i) );


                    write_cnt := write_cnt + 1;
                    fetch_cnt := fetch_cnt + 1;

                                if fetch_cnt = 1000000 then
                                    file_seq  := file_seq + 1;
                                    fetch_cnt := 0;
                                        utl_file.fclose(sam_data_filetype);
                                        select 'daily_tb_uap_attr_list_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
                                        into    sam_data_filename
                                        from    dual ;
                                        sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

                                end if;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                                INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

                    WHEN DUP_VAL_ON_INDEX THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                                INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

                    WHEN TOO_MANY_ROWS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                                INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;


                    WHEN OTHERS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;

                            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

                    COMMIT;
                END;
            END LOOP Process_Loop;
    END;
    << end_loop >>
    NULL;

    END LOOP Base_Loop;

    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST(DAILY)', 'E', SYSDATE,read_cnt, write_cnt, error_cnt) ;

        COMMIT;


    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP_ATTR_LIST Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DDHH24:MI:SS')    || ' ] *****');

EXCEPTION
       WHEN NO_DATA_FOUND THEN

                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;


       WHEN TOO_MANY_ROWS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR_LIST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_SKT_HIST_PROC" (
         I_Proc_Key                      IN  VARCHAR2
        ,I_Proc_Code         IN  VARCHAR2
        ,I_Exec_Id           IN  VARCHAR2
    ,O_RsltYN           OUT  VARCHAR2
    ,O_RsltMsg          OUT  VARCHAR2
)
IS
-- -----------------------------------------------------------------------------

-- Procedure명 : SP_CUST_PROF_HIST_MIG
-- 기능 : 고객 불만처리 또는 기타 고객가입자이력의 과거정보가 요청 되었을 경우
--        Migration하기 전 Format의 이전 데이터를 현 UAProfile 의 Foramat에 맞게


--        바꾸어 입력을 하고 이전 데이터에서는 삭제 처리를 한다
--        조회구분키 0: 서비스관리번호 조회
--                   1: 서비스번호 조회(MDN/MSISDN)
--
-- 변경력: 2003. 11. 09
--         1. 신규 생성 - compleus -
-- 변경력: 2006. 08. 08
--         2. 이력이 상당히 오래되었고 과거 이력에서 가져올 필요가 없어
--            정보요청시 처리는 하지 않고 정상결과가 전달 되도록 처리함 - compleus -
-- -----------------------------------------------------------------------------
    ERR_MSG             VARCHAR2(150) ;
BEGIN
    ERR_MSG := '정상[0]';

    O_RsltYN := 'Y' ;
    O_RsltMsg := ERR_MSG ;
        -- DBMS_OUTPUT.PUT_LINE( '***** [ SP_SKT_HIST_PROC Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');


EXCEPTION
        WHEN OTHERS THEN
                O_RsltMsg := ERR_MSG ;
                -- DBMS_OUTPUT.PUT_LINE( TRIM(ERR_MSG) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
                ROLLBACK ;
END;    -- 1.
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_FW_DOWN_INTER" (
     I_Ua_Manufacturer   IN      TB_UAP.UAF_DEVICE_MANUF%TYPE
    ,I_Ua_Model          IN      TB_UAP.UAF_DEVICE_MODEL%TYPE
    ,O_RsltYN           OUT      VARCHAR2
    ,O_WriteCnt         OUT      VARCHAR2
    ,O_FileName         OUT      VARCHAR2
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : SP_FW_DOWN_INTER
-- 기능 : UAProfiel DB와 다른 시스템 SoftwareDownload 에서 호출되며 각 모델정보로
--        파일을 생성하고 파일명을 리턴한다.
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt            NUMBER := 0;
    write_cnt           NUMBER := 0;
    fetch_cnt           NUMBER := 0;
    error_cnt           NUMBER := 0;
    err_code            VARCHAR2(200);
    log_data            VARCHAR2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/fds'
    file_seq            NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/swd';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    -- FETCH 할 변수

    N_CURSOR            INTEGER;
    N_RET               INTEGER;
    PUT_TEXT            VARCHAR2(200);
    SQL_TEXT            VARCHAR2(1500);

    v_RsltMsg           VARCHAR2(200) := '';
    v_FileName          VARCHAR2(1000) := '';
    v_Cnt               NUMBER := 0 ;
    v_Ua_Manufacturer   VARCHAR2(2) := '';
    v_Ua_Model          VARCHAR2(2) := '';

-- -----------------------------
--   CURSOR Define  ( 301 자리)
-- -----------------------------
-- TB_SVC_NATE.SVC_INST_NO         (11)

-- ====================
--  Main Process Start
-- ====================
BEGIN   -- 1.
    -- 1. 입력값 체크
    O_RsltYN := 'N';

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    --INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
    --   (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    --VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_DOWN_INTER', 'S', SYSDATE, 0, 0, 0) ;
    --COMMIT;

    SQL_TEXT := 'SELECT MOBILE_SVC_NUM                      '
        || '	|| '',''                                    '
        || '	|| SUBSTRB(NVL(DEV.UAF_DEVICE_MANUF,''''),1)'
        || '	|| '',''                                    '
        || '	|| SUBSTRB(NVL(DEV.UAF_DEVICE_MODEL,''''),1)'
        || '	|| '',''                                    '
        || '	|| NVL(ATTR.ATTR_VAL,'''')                  '
        || '	|| '',''                                    '
        || '	|| NVL(TO_CHAR(SKT.UPDATE_DT, ''YYYYMMDDHH24MISS''), RPAD('' '', 14))'
        || 'FROM TB_CUST_PROF      SKT,                     '
        || '     TB_UAP            DEV,                     '
        || '     TB_UAP_ATTR_LIST  ATTR                     ';

    --- 제조사 로직 처리
    IF TRIM(I_Ua_Manufacturer) IS NULL THEN
        v_Ua_Manufacturer := 'XX' ;
    ELSE
        v_Ua_Manufacturer := TRIM(I_Ua_Manufacturer) ;
    END IF ;

    SQL_TEXT := SQL_TEXT || 'WHERE DEV.UAF_DEVICE_MANUF like ''%''||TRIM(:b_Ua_Manufacturer)||''%''';

    --- Device Model 로직 처리
    IF TRIM(I_Ua_Model) IS NULL THEN

		v_Ua_Model := 'XX' ;
    ELSE
        v_Ua_Model := TRIM(I_Ua_Model) ;
    END IF ;

    SQL_TEXT := SQL_TEXT || 'AND DEV.UAF_DEVICE_MODEL like ''%''||UPPER(TRIM(:b_Ua_Model))||''%''';


    -- 마무리 TEXT
    SQL_TEXT := SQL_TEXT  || 'AND DEV.DEVICE_MNG_NUM = SKT.DEVICE_MNG_NUM  '
                          || 'AND DEV.DEVICE_MNG_NUM = ATTR.DEVICE_MNG_NUM '
                          || 'AND ATTR.COMPO_CD      = ''SW''              '
                          || 'AND ATTR.SUB_COMPO_CD  = '' ''               '
                          || 'AND ATTR.ATTR_NM       = ''SoftwareNumber''  ';

    --dbms_output.put_line(SQL_TEXT);

    N_CURSOR := DBMS_SQL.OPEN_CURSOR;

    DBMS_SQL.PARSE(N_CURSOR, SQL_TEXT, DBMS_SQL.NATIVE );

--    IF TRIM(I_Ua_Manufacturer) IS NOT NULL THEN
        DBMS_SQL.BIND_VARIABLE(N_CURSOR, ':b_Ua_Manufacturer', I_Ua_Manufacturer) ;
--    END IF ;

--    IF TRIM(I_Ua_Model) IS NOT NULL THEN
        DBMS_SQL.BIND_VARIABLE(N_CURSOR, ':b_Ua_Model', I_Ua_Model) ;
--    END IF ;

    DBMS_SQL.DEFINE_COLUMN(N_CURSOR, 1, PUT_TEXT, 200);

    N_RET := DBMS_SQL.EXECUTE(N_CURSOR);


-- FILE OPEN
    select  'FW_' || UPPER(trim(v_Ua_Manufacturer)) || '_' || trim(v_Ua_Model) || '_' || TO_CHAR(SYSDATE, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
      into  sam_data_filename
      from  dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
    v_FileName := trim(sam_data_filename)  ;

    LOOP
        IF DBMS_SQL.FETCH_ROWS(N_CURSOR) = 0 THEN
            EXIT;
        END IF;

        DBMS_SQL.COLUMN_VALUE(N_CURSOR, 1, PUT_TEXT);
        --DBMS_OUTPUT.PUT_LINE(PUT_TEXT);
        BEGIN   -- 2.
      --  읽은 DATA Count
            read_cnt := read_cnt + 1;
      --    -----------------------
      --    READ DATA를 FILE WRITE
      --    -----------------------
      -- Data Write
            utl_file.put_line( sam_data_filetype, TRIM(PUT_TEXT) );
        -- WRITE DATA 건수 Count
                write_cnt := write_cnt + 1;
                fetch_cnt := fetch_cnt + 1;
    --  백만건 단위로 file name에 seq를 붙여서 만듬.... --
                if fetch_cnt = 1000000 then
                    file_seq  := file_seq + 1;
                    fetch_cnt := 0 ;
                    utl_file.fclose(sam_data_filetype);
                    select  'FW_' || UPPER(trim(v_Ua_Manufacturer)) || '_' || trim(v_Ua_Model) || '_' || TO_CHAR(SYSDATE, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
                      into  sam_data_filename
                      from  dual ;
                    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
                    v_FileName := trim(v_FileName) || ',' || trim(sam_data_filename) ;
                end if;
            EXCEPTION
                WHEN OTHERS THEN
                    error_cnt := error_cnt + 1;
                    --DBMS_OUTPUT.PUT_LINE(sqlerrm);
                    --err_code := 'FILE WRITE [' || SQLCODE  || ']' ;
                    --INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                    --VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_DOWN_INTER', 'D', err_code ) ;
                    --DBMS_OUTPUT.PUT_LINE('FILE WRITE4[' || SUBSTR(c1.GET_DATA, -11, 11) || '][' || SQLCODE || ']');
                    COMMIT;
        END;  -- 2.
        << end_loop >>
        NULL;
    END LOOP;

    DBMS_SQL.CLOSE_CURSOR(N_CURSOR);

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log 파일에 남김..

    --INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
    --       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    --VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_DOWN_INTER', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
    --COMMIT;

-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);


O_RsltYN := 'Y';
O_WriteCnt := TO_CHAR(write_cnt) ;
O_FileName := v_FileName  ;

/*
FOR i IN 1..O_WriteCnt LOOP
	DBMS_OUTPUT.PUT_LINE('O_FileName[' || i || '][' || SUBSTR( O_FileName, ( 25 * (i - 1) + 1 ),  24 ) || ']');
END LOOP ;
*/

EXCEPTION
       WHEN OTHERS THEN
		error_cnt := error_cnt + 1;

		IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
			DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
		END IF;

		if utl_file.is_open(sam_data_filetype) then
			utl_file.fclose(sam_data_filetype);
		end if;

		err_code := 'MAIN [' || SQLCODE || ']' ;
		--INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
		--VALUES (SEQ_JOB_LOG.NEXTVAL, 'SP_FW_DOWN_INTER', 'D', err_code ) ;
		--DBMS_OUTPUT.PUT_LINE('MAIN' || SQLCODE );
       --COMMIT;
END;  -- 1.
/






  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_FW_DOWN" (
     I_Ua_Manufacturer    IN     TB_UAP.UAF_DEVICE_MANUF%TYPE
    ,I_Ua_Model           IN     TB_UAP.UAF_DEVICE_MODEL%TYPE
    ,O_RsltYN            OUT     VARCHAR2
    ,O_WriteCnt          OUT     VARCHAR2
    ,O_FileName          OUT     VARCHAR2
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : SP_FW_DOWN
-- 기능 : UAProfiel DB와 다른 시스템 SoftwareDownload 연동에서 해당 단말정보를
--        DownLoad 하기위해 호출되며 호출된 정보로 SP_FW_DOWN_INTER Procedure를
--        재차 호출하여 처리한다.
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
	v_Ua_Manufacturer TB_UAP.UAF_DEVICE_MANUF%TYPE  := I_Ua_Manufacturer ;
	v_Ua_Model        TB_UAP.UAF_DEVICE_MODEL%TYPE  := I_Ua_Model        ;
	v_RsltYN          VARCHAR2(50)  := NULL ;
	v_FileCnt         VARCHAR2(200) := NULL ;
	v_FileName        VARCHAR2(2000) := NULL ;
BEGIN


    v_RsltYN := 'N';

    IF ( TRIM(I_Ua_Manufacturer) IS NULL ) OR ( TRIM(I_Ua_Model) IS NULL ) THEN
		O_RsltYN := 'W';
		O_WriteCnt := NULL ;
		O_FileName := NULL ;
		RETURN;
    END IF ;
    /*
    dbms_output.put_line('       서버쪽 시작');
    dbms_output.put_line('       MANUFACTURER[' || I_Ua_Manufacturer || ']');
    dbms_output.put_line('       MODEL_NM    [' || I_Ua_Model || ']');
    dbms_output.put_line('       RESULT_YN   [' || O_RsltYN || ']');
    dbms_output.put_line('       O_FileName  [' || O_FileName || ']');
    dbms_output.put_line('       -------------------------------------------------');
    */

    sp_fw_down_inter(v_Ua_Manufacturer,v_Ua_Model ,v_RsltYN, v_FileCnt, v_FileName) ;

    /*
    DBMS_OUTPUT.ENABLE ( 1000000);
    dbms_output.put_line('       -------------------------------------------------');
    dbms_output.put_line('       RESULT_YN   [' || v_RsltYN || ']');
    dbms_output.put_line('       O_WriteCnt   [' || v_FileCnt || ']');
    dbms_output.put_line('       O_FileName  [' || v_FileName || ']');
    dbms_output.put_line('       서버쪽 끝1');
    */

    O_RsltYN := v_RsltYN ;
    O_WriteCnt := v_FileCnt ;
    O_FileName := v_FileName ;

    /*
	FOR i IN 1..O_WriteCnt LOOP
		DBMS_OUTPUT.PUT_LINE('O_FileName[' || i || '][' || SUBSTR( O_FileName, ( 25 * (i - 1) + 1 ),  24 ) || ']');
	END LOOP ;
	*/

    exception
        when others then
	       dbms_output.put_line('       ERROR[' || SQLERRM || ']');

END;  -- 1.
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_ADDED_CODE_NAME" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_ADDED_CODE_NAME
-- 기능 : UAProfile 에서 WICC 에 부가서비스코드,명을 넘겨주기 위함
-- 변경력: 신규 (2009.7.31) : - stoneviruss -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    VARCHAR2(200);
-- -- --------------------------------------------------------------------------

-- -- OUTPUT TEXT FILE VARIABLE
-- -- --------------------------------------------------------------------------

-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'

    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    log_cnt     NUMBER := 0;

-- ------------------------------------------------------
CURSOR cur_get_data IS
    SELECT ADDED_SVC_CD || '|' || ADDED_SVC_DSC AS GET_DATA
    FROM TB_ADDED_SVC
    WHERE START_DT >= TRUNC( I_Work_dt - 1 )
      AND START_DT <  TRUNC( I_Work_dt );

-- ====================
--  Main Process Start
-- ====================
BEGIN -- 1.

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_ADDED_CODE_NAME Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');

-- FILE OPEN
    SELECT 'daily_added_code_name_' || TO_CHAR(I_Work_dt, 'YYYYMMDD') || '.dat'
    INTO    sam_data_filename
    FROM    dual ;

    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_ADDED_CODE_NAME(DAILY)', 'S', SYSDATE, 0, 0, 0);
    COMMIT;

    FOR c1 IN cur_get_data LOOP -- 2.
    BEGIN  -- 3.

  --  읽은 DATA Count
        read_cnt := read_cnt + 1;

  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN -- 4.
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
			write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_ADDED_CODE_NAME(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_ADDED_CODE_NAME(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;

   	   COMMIT;
        END; -- 4.
    END; -- 3.
    << end_loop >>
    NULL;
    END LOOP; -- 2.

-- ===============================================================
-- End Cursor Loop

-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_ADDED_CODE_NAME(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_ADDED_CODE_NAME END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');

EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_ADDED_CODE_NAME(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_ADDED_CODE_NAME(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;
       COMMIT;

END;
/






  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_BP_JOB_SETTING"
IS
BEGIN
/*ALARM OFF */
    /*반복작업*/
    UPDATE TB_CP_MNG SET SMS_YN='N'
    WHERE CP_MNG_CD IN
    (
        SELECT CP_MNG_CD
        FROM TB_CP_JOB_LIST
        WHERE TO_CHAR(FROM_DT, 'HH24' ) = TO_CHAR(SYSDATE, 'HH24')
        AND TO_CHAR(TO_DT, 'YYYYMMDD') >= TO_CHAR(SYSDATE, 'YYYYMMDD')
        AND JOB_TYPE = 'D'
    )
    AND SMS_YN='Y';
    COMMIT;

    /*일회용*/
    UPDATE TB_CP_MNG SET SMS_YN='N'
    WHERE CP_MNG_CD IN
    (
        SELECT CP_MNG_CD FROM TB_CP_JOB_LIST
        WHERE TO_CHAR(FROM_DT, 'YYYYMMDD HH24' ) = TO_CHAR(SYSDATE, 'YYYYMMDD HH24')
        AND JOB_TYPE = 'O'
    )
    AND SMS_YN='Y';
    COMMIT;

/*ALARM ON */
    /*반복작업*/
    UPDATE TB_CP_MNG SET SMS_YN='Y'
    WHERE CP_MNG_CD IN
    (
        SELECT CP_MNG_CD
        FROM TB_CP_JOB_LIST
        WHERE TO_CHAR(TO_DT, 'HH24' ) = TO_CHAR(SYSDATE, 'HH24')
        AND TO_CHAR(TO_DT, 'YYYYMMDD') >= TO_CHAR(SYSDATE, 'YYYYMMDD')
        AND JOB_TYPE = 'D'
    )
    AND SMS_YN='N';
    COMMIT;

    /*일회용*/
    UPDATE TB_CP_MNG SET SMS_YN='Y'
    WHERE CP_MNG_CD IN
    (
        SELECT CP_MNG_CD FROM TB_CP_JOB_LIST
        WHERE TO_CHAR(TO_DT, 'YYYYMMDD HH24' ) = TO_CHAR(SYSDATE, 'YYYYMMDD HH24')
        AND JOB_TYPE = 'O'
    )
    AND SMS_YN='N';
    COMMIT;

END ;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_CUST_MVNO" (
        I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_CUST_MVNO
-- 목적 : 과금검증시스템(유레카)에서 MVNO 고객 사용내역 조회를 위한 MVNO_CD(사업자구분코드) 정보 연동에 대한 업무 요청 건
-- 변경력: 신규 (2012.08.16) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단, initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/cust'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
-- 추출 포맷 : 서비스관리번호,MDN,MIN,MVNO_CD,가입상태(사용중/해지),변경일자
-- 업무 코드 : A1,C1,D3,F1,F2,M1,U1,Z1,Z3,Z4
-- --------------------------
CURSOR cur_get_data IS
        SELECT A.SVC_MNG_NUM
        || ',' || A.MOBILE_SVC_NUM
        || ',' || A.MOBILE_ID_NUM
        || ',' || A.MVNO_CD
	|| ',' || DECODE(A.UPDATE_CD,'Z1','N','Z2','N','Z4','N','Z5','N','Y')
        || ',' || TO_CHAR(A.UPDATE_DT,'yyyymmddhh24miss')
        || ',' || B.COIS_DEVICE_CD AS GET_DATA
        FROM  TB_CUST_PROF_HIST A, TB_UAP B
      WHERE A.END_DT >= to_date(to_char(sysdate-1,'YYYYMMDD'),'YYYYMMDD') -- ONE DAY DATA
                        AND   A.END_DT <  to_date(to_char(sysdate,'YYYYMMDD'),'YYYYMMDD')
                                AND A.MVNO_CD != '0'
                                AND A.DEVICE_MNG_NUM = B.DEVICE_MNG_NUM
        UNION
        SELECT A.SVC_MNG_NUM
        || ',' || A.MOBILE_SVC_NUM
        || ',' || A.MOBILE_ID_NUM
        || ',' || A.MVNO_CD
        || ',' || DECODE(A.UPDATE_CD,'Z1','N','Z2','N','Z4','N','Z5','N','Y')
        || ',' || TO_CHAR(A.UPDATE_DT,'yyyymmddhh24miss')
        || ',' || B.COIS_DEVICE_CD
        FROM  TB_CUST_PROF A, TB_UAP B
        WHERE A.UPDATE_DT >= to_date(to_char(sysdate-1,'YYYYMMDD'),'YYYYMMDD') -- ONE DAY DATA

                        AND   A.UPDATE_DT <  to_date(to_char(sysdate,'YYYYMMDD'),'YYYYMMDD')
                                AND A.MVNO_CD != '0'
                                AND A.DEVICE_MNG_NUM = B.DEVICE_MNG_NUM ;

BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000 );
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_CUST_MVNO Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'DAILY_CUST_MVNO_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
               (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES ( SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_MVNO', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
                        if fetch_cnt = 1000000 then
                            file_seq  := file_seq + 1;
                            fetch_cnt := 0;
                                utl_file.fclose(sam_data_filetype);
                                select 'DAILY_CUST_MVNO_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
                                into    sam_data_filename
                                from    dual ;
                                sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
                        end if;
        EXCEPTION
                   WHEN OTHERS THEN
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_MVNO', 'D', SYSDATE, substr(err_code,1,150) ) ;
                        DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  || '] *****');

            COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_MVNO', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
        COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_CUST_MVNO Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN OTHERS THEN
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_MVNO', 'D', SYSDATE, substr(err_code,1,150) ) ;
                        DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  ||'] *****');
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_UAP_WAP_FMS" (
        I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_UAP_WAP_FMS
-- 기능 : UAProfiel DB와 FMS 연동에서 처리할 내용으로 WAP G/W를 통해 변경된 고객
--        정보의 이력을 SAM 파일생성(TB_CUST_PROF, TB_CUST_PROF_HIST)
--        * 같은 내용도 모두 출력
-- 변경력: 신규 (2005.06.23) - complues -
--         변경 (2009.12.04) : cur_get_data 커서의 SVC_MNG_NUM 조건 삭제 (smhong)
--         변경 (2010.04.13) : NET_GEN_TP에서 2G("2")만 저장 (Lee Dong Hwan)
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    log_cnt     NUMBER := 0;
    err_code    varchar2(200);
-- -- --------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- --------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
CURSOR cur_get_data IS
        SELECT           cust.SVC_MNG_NUM
                        ||'|' || NVL(TO_CHAR(cust.START_DT , 'YYYYMMDDHH24MISS'), NULL)
                        ||'|' || NVL(TO_CHAR(cust.END_DT , 'YYYYMMDDHH24MISS'), NULL)
                        ||'|' || cust.DEVICE_MNG_NUM
                        ||'|' || dev.MODEL
                        ||'|' || dev.COIS_DEVICE_CD
                        ||'|' || cust.MOBILE_ID_NUM
                        ||'|' || cust.MOBILE_SVC_NUM
                        ||'|' || cust.EXEC_ID
                        ||'|' || NVL(TO_CHAR(cust.COIS_UPDATE_DT , 'YYYYMMDDHH24MISS'), NULL)
                        ||'|' || cust.UPDATE_CD
                        ||'|' || NVL(TO_CHAR(cust.UPDATE_DT , 'YYYYMMDDHH24MISS'), NULL)
                        ||'|' || cust.UPDATE_PATH AS GET_DATA
        FROM
                      (SELECT   SVC_MNG_NUM
                                ,START_DT
                                ,END_DT
                                ,DEVICE_MNG_NUM
                                ,MOBILE_ID_NUM
                                ,MOBILE_SVC_NUM
                                ,EXEC_ID
                                ,COIS_UPDATE_DT
                                ,UPDATE_CD
                                ,UPDATE_DT
                                ,UPDATE_PATH
                               	,NET_GEN_TP
                FROM TB_CUST_PROF_HIST
                WHERE END_DT >= TRUNC(I_Work_dt -1 ) -- LIMIT DAY START
                AND   END_DT <  TRUNC(I_Work_dt    ) -- LIMIT DAY END
                AND   UPDATE_PATH = 'WAP-BRO'        -- FROM BROKER MODIFY
                AND   MVNO_CD = '0'                  -- 2011.07.15 COLUS3 - MVNO사업자 구분코드가 '0'(SKT)인 데이터만 추출
                UNION ALL
                SELECT   SVC_MNG_NUM
                                ,UPDATE_DT AS START_DT
                                ,UPDATE_DT AS END_DT
                                ,DEVICE_MNG_NUM
                                ,MOBILE_ID_NUM
                                ,MOBILE_SVC_NUM
                                ,TRIM(EXEC_ID) AS EXEC_ID
                                ,COIS_UPDATE_DT
                                ,UPDATE_CD
                                ,UPDATE_DT
                                ,TRIM(UPDATE_PATH) AS UPDATE_PATH
                                ,NET_GEN_TP
                FROM TB_CUST_PROF
                WHERE UPDATE_DT >= TRUNC(I_Work_dt) -1 -- LIMIT DAY START
                AND   UPDATE_DT <  TRUNC(I_Work_dt)    -- LIMIT DAY END
                AND   UPDATE_PATH = 'WAP-BRO'        -- FROM BROKER MODIFY
            ) cust ,
           (SELECT UAP.DEVICE_MNG_NUM, UAP.COIS_DEVICE_CD , NVL(LST.MODEL, 'No_Model') AS MODEL
                FROM TB_UAP UAP
                    ,(SELECT DEVICE_MNG_NUM, ATTR_VAL AS MODEL
                      FROM TB_UAP_ATTR_LIST
                      WHERE COMPO_CD = 'HW'
                      AND   SUB_COMPO_CD = ' '
                      AND   ATTR_NM = 'Model' ) LST
                WHERE UAP.DEVICE_MNG_NUM = LST.DEVICE_MNG_NUM(+)
            ) dev
    WHERE cust.DEVICE_MNG_NUM = DEV.DEVICE_MNG_NUM
-- 마케팅PI팀 요청요청으로 2G/3G 중 2G만 필터링
    AND	cust.NET_GEN_TP = '2'
-- 마케팅PI 김지연M 요청으로 서비스관리번호 필터링 제거
--    AND SUBSTR(cust.SVC_MNG_NUM,1,2) NOT IN ( '80', '88', '70', '90' )
    ORDER BY cust.SVC_MNG_NUM, cust.START_DT DESC , cust.END_DT DESC
    ;
-- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_UAP_WAP_FMS Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_uap_wap_fms_' || TO_CHAR(SYSDATE, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
             (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMS(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
        COMMIT;
    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
  --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
  -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
                        if fetch_cnt = 1000000 then
                            file_seq  := file_seq + 1;
                            fetch_cnt := 0;
                                utl_file.fclose(sam_data_filetype);
                                select 'daily_uap_wap_fms_' || TO_CHAR(SYSDATE, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
                                into    sam_data_filename
                                from    dual ;
                                sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename,'w');
                        end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMS(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMS(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMS(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMS(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
               (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMS(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
        COMMIT;
-- --------------------------------------------------------------------------
-- 작업완료 확인 파일생성
-- --------------------------------------------------------------------------
        SELECT NVL(COUNT(*),0) INTO log_cnt FROM GAEBAL_UPADM.TB_JOB_LOG
        WHERE TO_CHAR(RUN_DT, 'YYYYMMDD') = TO_CHAR(SYSDATE, 'YYYYMMDD')
        AND STATUS = 'E' AND PROGRAM LIKE '%DAILY_UAP_WAP_FMS%';
        --------
        -- 단말정보는 총 1개의 프로시져가 돌아감. 이상이 생겨 두번돌린다든지 할때에는수동으로 로그파일 생성할것.
        --------
    if log_cnt >= 1 then  -- 작업 완료 Log 남김
                select 'daily_uap_wap_fms_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '_XX.log'
                into    sam_data_filename
                from    dual ;
            sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
            utl_file.fclose(sam_data_filetype);
    end if;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_UAP_WAP_FMS Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMS(DAILY)', 'D',
 SYSDATE, substr(err_code,1,150) ) ;
            DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150) || '] *****');

       WHEN DUP_VAL_ON_INDEX THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMS(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  || '] *****');
       WHEN TOO_MANY_ROWS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMS(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  || '] *****');
       WHEN OTHERS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMS(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  || '] *****');
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_ADDED_SVC_BETWEEN" (
	 I_Added_Svc_Cd IN TB_ADDED_SVC.ADDED_SVC_CD%TYPE
    ,I_Meta_Seq     IN NUMBER DEFAULT NULL
    ,I_Start_Date   IN DATE   DEFAULT SYSDATE
    ,I_End_Date     IN DATE   DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_ADDED_SVC_BETWEEN
-- 기능 : 부가서비스 코드를 입력하면 CP에 내려줄 SAM파일을 추출함(초기화)
--        시작일과 종료일을 두어 해당 기간 내의 정보를 처리
--        SAM 파일생성(TB_CUST_ADDED_SVC, TB_CUST_PROF)
--        시작일 7/21 종료일 7/22 인 경우 7/21 정보만 추출 (7/22이전)
--        format --> 부가서비스코드;서비스관리번호;MIN;MDN;COIS변경시간;처리자
-- 변경력: 신규 (2005.07.22) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq            NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    v_Exist_cnt         NUMBER ;
    v_added_svc_cd      TB_ADDED_SVC.ADDED_SVC_CD%TYPE := I_Added_Svc_Cd ;
    v_start_date        DATE  := I_Start_Date ;
    v_end_date          DATE  := I_End_Date ;
-- --------------------------
CURSOR cur_get_data IS
    -- 부가서비스 테이블에 있다하더라도 고객정보 테이블에 존재하지 않는 데이터는
    -- 인정하지 못함으로 아래 쿼리 사용가능(outer join무의미)
	SELECT        ADDED.ADDED_SVC_CD
        || ';' || CUST.SVC_MNG_NUM
        || ';' || CUST.MOBILE_ID_NUM
        || ';' || DECODE( LENGTH(CUST.MOBILE_SVC_NUM), 10, SUBSTR(CUST.MOBILE_SVC_NUM, 1,3) || '0' || SUBSTR(CUST.MOBILE_SVC_NUM, 4),
                                                           CUST.MOBILE_SVC_NUM )
        || ';' || ADDED.COIS_UPDATE_DT
        || ';' || NVL(TRIM(ADDED.REG_PATH),'NONE' ) AS GET_DATA
	FROM
	    (SELECT SVC_MNG_NUM
		    , ADDED_SVC_CD
		    , TO_CHAR(COIS_UPDATE_DT,'YYYYMMDDHH24MISS')AS COIS_UPDATE_DT
		    , REG_PATH
		FROM TB_CUST_ADDED_SVC
		WHERE ADDED_SVC_CD = v_added_svc_cd
        AND  REG_DT  >= trunc( v_start_date )
        AND  REG_DT  <  trunc( v_end_date   )
	    ) ADDED,
	    TB_CUST_PROF CUST
	WHERE ADDED.SVC_MNG_NUM = CUST.SVC_MNG_NUM ;


    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_ADDED_SVC_BETWEEN Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'META_' || v_added_svc_cd || '_' || TO_CHAR(v_start_date, 'YYYYMMDD-') || TO_CHAR(v_end_date, 'YYYYMMDD_')  || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_BETWEEN(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'META_' || v_added_svc_cd || '_' || TO_CHAR(v_start_date, 'YYYYMMDD-') || TO_CHAR(v_end_date, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_BETWEEN(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_BETWEEN(INIT)', 'D', SYSDATE, substr(err_code,1,150)) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_BETWEEN(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_BETWEEN(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;

    -- 처리 완료 로그 기록 여부
    IF ( I_Meta_Seq IS NULL ) THEN
        DBMS_OUTPUT.PUT_LINE( '***** [ DB No Writing ] *****');
    ELSE
        -- 존재 여부 조회
        SELECT COUNT(*) INTO v_Exist_cnt
        FROM TB_META_BUF
        WHERE META_SEQ = I_Meta_Seq ;

        IF ( v_Exist_cnt = 0 ) THEN
            DBMS_OUTPUT.PUT_LINE( '***** [ DB Not Found ] *****');
        ELSE
            UPDATE TB_META_BUF
            SET FILE_CNT = file_seq
               ,META_CNT = write_cnt
               ,FILE_NM  = 'META_' || v_added_svc_cd || '_' || TO_CHAR(v_start_date, 'YYYYMMDD-') || TO_CHAR(v_end_date, 'YYYYMMDD')
            WHERE META_SEQ = I_Meta_Seq ;

            DBMS_OUTPUT.PUT_LINE( '***** [ DB Log Update Success ] *****');
        END IF ;
    END IF ;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_BETWEEN(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_ADDED_SVC_BETWEEN Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_BETWEEN(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_BETWEEN(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_BETWEEN(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_BETWEEN(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_ADDED_SVC_CD" (
	 I_Added_Svc_Cd IN TB_ADDED_SVC.ADDED_SVC_CD%TYPE
    ,I_Meta_Seq     IN NUMBER DEFAULT NULL
)
IS
-- -----------------------------------------------------------------------------

-- Procedure명 : INIT_ADDED_SVC_CD
-- 기능 : 부가서비스 코드를 입력하면 CP에 내려줄 SAM파일을 추출함(초기화)
--        SAM 파일생성(TB_CUST_ADDED_SVC, TB_CUST_PROF)
--        format --> 부가서비스코드;서비스관리번호;MIN;MDN;COIS변경시간;처리자
-- 변경력: 신규 (2005.06.09) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq            NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    v_Exist_cnt         NUMBER ;
    v_added_svc_cd  TB_ADDED_SVC.ADDED_SVC_CD%TYPE := I_Added_Svc_Cd ;
-- --------------------------
CURSOR cur_get_data IS
    -- 부가서비스 테이블에 있다하더라도 고객정보 테이블에 존재하지 않는 데이터는

    -- 인정하지 못함으로 아래 쿼리 사용가능(outer join무의미)
	SELECT        ADDED.ADDED_SVC_CD
        || ';' || CUST.SVC_MNG_NUM
        || ';' || CUST.MOBILE_ID_NUM
        || ';' || DECODE( LENGTH(CUST.MOBILE_SVC_NUM), 10, SUBSTR(CUST.MOBILE_SVC_NUM, 1,3) || '0' || SUBSTR(CUST.MOBILE_SVC_NUM, 4),
                                                           CUST.MOBILE_SVC_NUM )
        || ';' || ADDED.COIS_UPDATE_DT
        || ';' || NVL(TRIM(ADDED.REG_PATH),'NONE' ) AS GET_DATA
	FROM
	    (SELECT SVC_MNG_NUM
		    , ADDED_SVC_CD
		    , TO_CHAR(COIS_UPDATE_DT,'YYYYMMDDHH24MISS')AS COIS_UPDATE_DT
		    , REG_PATH
		FROM TB_CUST_ADDED_SVC
		WHERE ADDED_SVC_CD = v_added_svc_cd
	    ) ADDED,
	    TB_CUST_PROF CUST
	WHERE ADDED.SVC_MNG_NUM = CUST.SVC_MNG_NUM ;


    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_ADDED_SVC_CD Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'META_' || v_added_svc_cd || '_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'META_' || v_added_svc_cd || '_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;

    -- 처리 완료 로그 기록 여부
    IF ( I_Meta_Seq IS NULL ) THEN
        DBMS_OUTPUT.PUT_LINE( '***** [ DB No Writing ] *****');
    ELSE
        -- 존재 여부 조회
        SELECT COUNT(*) INTO v_Exist_cnt
        FROM TB_META_BUF
        WHERE META_SEQ = I_Meta_Seq ;

        IF ( v_Exist_cnt = 0 ) THEN
            DBMS_OUTPUT.PUT_LINE( '***** [ DB Not Found ] *****');
        ELSE
            UPDATE TB_META_BUF
            SET FILE_CNT = file_seq
               ,META_CNT = write_cnt
               ,FILE_NM  = 'META_' || v_added_svc_cd || '_' || TO_CHAR(SYSDATE, 'YYYYMM')
            WHERE META_SEQ = I_Meta_Seq ;

            DBMS_OUTPUT.PUT_LINE( '***** [ DB Log Update Success ] *****');
        END IF ;
    END IF ;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_ADDED_SVC_CD Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', SYSDATE, substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_CUST_TING"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_CUST_TING
-- 기능 : UAProfile의 TING 요금제 가입자 초기화를 위한 SAM 파일생성(TB_CUST_PROF,
--        TB_CUST_PERSON )
--        CTBBA:팅버디
--        CTBSV:팅버디세이브
--        CTSTA:팅 별 요금제
--        CCOOL:Ting100
--        CTPLS:Ting500
-- 변경력: 신규 (2005.09.23) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
-- CTBBA	 팅버디
-- CTBSV	 팅버디세이브
-- CTSTA	팅 별 요금제
-- CCOOL	Ting100
-- CTPLS	Ting500
-- --------------------------
CURSOR cur_get_data IS
	SELECT          CST.SVC_MNG_NUM
	      || ',' || CST.MOBILE_SVC_NUM
	      || ',' || CST.MOBILE_ID_NUM
	      || ',' || NVL(CST.CLIENT_ID_CUST, '')
	      || ',' || CST.DEVICE_MNG_NUM
	      || ',' || NVL(TO_CHAR(UPDATE_DT , 'YYYYMMDDHH24MISS'), '')
	      || ',' || CD.CHARGE_CD AS GET_DATA
	FROM
		TB_CUST_PROF CST,
	   (SELECT SVC_MNG_NUM, CHARGE_CD
		FROM TB_CUST_PERSON
		WHERE CHARGE_CD IN (
			 'CTBBA'
			,'CTBSV'
			,'CTSTA'
			,'CCOOL'
			,'CTPLS'
		   )
	    AND ROWNUM < 10001
	    )CD
	WHERE CST.SVC_MNG_NUM = CD.SVC_MNG_NUM ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_TING Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_cust_ting_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TING(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_cust_ting_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TING(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TING(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TING(INIT)', 'D', substr(err_code,1,150)) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TING(INIT)', 'D', substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TING(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_TING Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TING(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TING(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TING(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_TING(INIT)', 'D', substr(err_code,1,150) );
       COMMIT;
END;
/


  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_TEST_NUM"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_TEST_NUM
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- --------------------------------------------------------------------------
---
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

-- -- -----------------------------------------------------------------------------
-- -- Cursor
-- -- -----------------------------------------------------------------------------
CURSOR cur_get_data IS
	SELECT        SVC_MNG_NUM
		|| '|' || NVL(TRIM(REQ_ID)     , '')
		|| '|' || NVL(TRIM(EXEC_ID)    , '')
		|| '|' || NVL(SVC_TP           , '')
		|| '|' || REPLACE( REPLACE(PURPOSE,CHR('13'),''),CHR('10'),'')
		|| '|' || NVL(TO_CHAR(INIT_DT    , 'YYYYMMDDHH24MISS'), '')
		|| '|' || NVL(TO_CHAR(UPDATE_DT  , 'YYYYMMDDHH24MISS'), '')
		|| '|' || NVL(TO_CHAR(EXPIRE_DT  , 'YYYYMMDDHH24MISS'), '')
		|| '|' || NVL(REQ_NM           , '')
		|| '|' || NVL(TRIM(CUST_ID)    , '')
		|| '|' || NVL(ICAS_YN          , '')

         AS GET_DATA
	 FROM TB_TEST_NUM
     ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_TEST_NUM Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_test_num.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA );
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
  	    COMMIT;
        END;
    END LOOP Process_Loop;
    << end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_TEST_NUM Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN DUP_VAL_ON_INDEX THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN TOO_MANY_ROWS THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN OTHERS THEN
	     error_cnt := error_cnt + 1;
	     DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_SUB_COMPO"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_SUB_COMPO
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   CURSOR DEFINE  ( 206자리)
------------------------------
--   COMPO_CD           (  2)
--   SUB_COMPO_CD       (  4)
--   SUB_COMPO_NM       (200)
-- --------------------------
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_NM, '')
            || '|' || NVL(TRIM(SUB_COMPO_DSC), '') AS GET_DATA
	FROM TB_SUB_COMPO ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_SUB_COMPO Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_sub_compo.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA Count
            write_cnt := write_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_SUB_COMPO Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
      COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_DEVICE"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_DEVICE
-- History: (2005.05.20) - complues -
--          (2005.11.04) 프로시져 명칭 변경 INIT_LDAP_TB_UAP -> INIT_LDAP_DEVICE
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

-- -- -----------------------------------------------------------------------------
-- -- Cursor
-- -- -----------------------------------------------------------------------------
CURSOR cur_get_data IS
	SELECT            NVL( UAP.DEVICE_MNG_NUM         , '')          -- DEVICE_MNG_NUM
			|| '|' || NVL( LST.COMPO_CD               , '')             -- COMPO_CD
			|| '|' || NVL( LST.SUB_COMPO_CD           , '')          -- SUB_COMPO_CD
			|| '|' || NVL( LST.ATTR_NM                , '')           -- ATTR_NM
			|| '|' || NVL( LST.ATTR_VAL               , '')       -- ATTR_VAL
			|| '|' || NVL( LST.SEQ                    , '')    -- SEQ
			|| '|' || NVL( UAP.URI                    , '')                                                       -- URI
			|| '|' || NVL( UAP.UAP_YN                 , '')                                                       -- UAP_YN
			|| '|' || NVL( UAP.COIS_DEVICE_CD         , '')                       -- COIS_DEVICE_CD
			|| '|' || NVL( UAP.COIS_DEVICE_VER        , '')                                                       -- COIS_DEVICE_VER
			|| '|' || NVL( UAP.PDA_YN                 , '')                                                       -- PDA_YN
			|| '|' || NVL( UAP.UAF_DEVICE_MANUF       , '')                         -- UAF_DEVICE_MANUF
			|| '|' || NVL( UAP.UAF_DEVICE_MODEL       , '')                                                       -- UAF_DEVICE_MODEL
			|| '|' || NVL(TRIM(UAP.UAF_DEVICE_MODEL_DSC) , '')                                                    -- UAF_DEVICE_MODEL_DSC
			|| '|' || NVL(TRIM(UAP.EXEC_ID)           , '')    -- EXEC_ID
			|| '|' || NVL(TO_CHAR(UAP.UPDATE_DT , 'YYYYMMDDHH24MISS'), '')-- UPDATE_DT
			|| '|' || NVL(TRIM(UAP.UPDATE_PATH)       , '')                                                       -- UPDATE_PATH
            || '|' || NVL(TO_CHAR(UAP.COIS_UPDATE_DT , 'YYYYMMDDHH24MISS'), '')       -- COIS_UPDATE_DT
			|| '|' || NVL(TRIM(VAL.ATTR_VAL_DSC)      , '')          -- ATTR_VAL_DSC
			|| '|' || NVL( ATTR.NM_SPACE              , '')           -- NM_SPACE
			|| '|' || NVL( ATTR.DATA_TP               , '')        -- DATA_TP
			|| '|' || NVL( ATTR.ATTR_TP               , '')    -- ATTR_TP
			|| '|' || NVL( ATTR.RESOLUTION_RULE       , '')-- RESOLUTION_RULE
			|| '|' || NVL( ATTR.MANDATORY_YN          , '')    -- MANDATORY_YN
			|| '|' || NVL( ATTR.AUTHORITATIVE_YN      , '')     -- AUTHORITATIVE_YN
			|| '|' || NVL( ATTR.CASE_SENSITIVE_YN     , '')          -- CASE_SENSITIVE_YN
			|| '|' || NVL( ATTR.BITMAP_SEQ            , '')                -- BITMAP_SEQ
			|| '|' || NVL(TRIM(ATTR.ATTR_DSC)         , '')               -- ATTR_DSC
			|| '|' || NVL( SUB.SUB_COMPO_NM           , '')            -- SUB_COMPO_NM
			|| '|' || NVL(TRIM(SUB.SUB_COMPO_DSC)     , '')             -- SUB_COMPO_DSC
            || '|' || NVL( CMP.COMPO_NM               , '')                        -- COMPO_NM
			|| '|' || NVL( CMP.COMPO_SEQ              , '')                     -- COMPO_SEQ
			|| '|' || NVL(TRIM(CMP.COMPO_DSC)         , '')                   -- COMPO_DSC
            AS GET_DATA
	FROM (SELECT DEVICE_MNG_NUM
		  FROM TB_UAP
		  UNION
		  SELECT DEVICE_MNG_NUM
		  FROM TB_UAP_ATTR_LIST) BAS
	    ,TB_UAP UAP
	    ,TB_UAP_ATTR_LIST LST
	    ,TB_UAP_ATTR_VAL VAL
	    ,TB_UAP_ATTR ATTR
	    ,TB_SUB_COMPO SUB
	    ,TB_COMPO CMP
	WHERE BAS.DEVICE_MNG_NUM = UAP.DEVICE_MNG_NUM(+)
	AND   UAP.DEVICE_MNG_NUM = LST.DEVICE_MNG_NUM(+)
	AND   LST.COMPO_CD = VAL.COMPO_CD(+)
	AND   LST.SUB_COMPO_CD = VAL.SUB_COMPO_CD(+)
	AND   LST.ATTR_NM = VAL.ATTR_NM(+)
	AND   LST.ATTR_VAL = VAL.ATTR_VAL(+)
	AND   VAL.COMPO_CD = ATTR.COMPO_CD(+)
	AND   VAL.SUB_COMPO_CD = ATTR.SUB_COMPO_CD(+)
	AND   VAL.ATTR_NM = ATTR.ATTR_NM(+)
	AND   VAL.COMPO_CD = SUB.COMPO_CD(+)
	AND   VAL.SUB_COMPO_CD = SUB.SUB_COMPO_CD(+)
	AND   VAL.COMPO_CD = CMP.COMPO_CD(+)
    ORDER BY BAS.DEVICE_MNG_NUM DESC
		,CMP.COMPO_SEQ
		,LST.SUB_COMPO_CD
		,ATTR.BITMAP_SEQ
		,LST.SEQ
    ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_DEVICE Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_device.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    read_cnt := 0 ;

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, read_cnt || '|' || c1.GET_DATA );
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
  	    COMMIT;
        END;
    END LOOP Process_Loop;
    << end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_DEVICE Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_MIG_CP_CUST"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_MIG_CP_CUST
-- History: (2006.08.16) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
	read_cnt    NUMBER := 0;
	write_cnt   NUMBER := 0;
	fetch_cnt   NUMBER := 0;

-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- --    utl_file_dir='/ftp/ftp'
	file_seq    NUMBER := 1;
	sam_data_filedir    VARCHAR2(100) := '/data/ftp/swd';
	sam_data_filename   VARCHAR2(50)  := '';
	sam_data_filetype   utl_file.file_type;
	v_svc_mng_num   VARCHAR2(10) ;
	v_pre_added_svc_cd      CHAR(10) ;
	v_crt_added_svc_cd      CHAR(10) ;
-- -------------------------- /*+ INDEX(SVC PK_CUST_ADDED_SVC ) *//*+ full(cust) full(svc) use_hash(cust, svc) */
CURSOR cur_get_data IS
    SELECT       /*+ full(cust) full(svc) use_hash(cust, svc) */
                 CUST.SVC_MNG_NUM
        ,        SVC.ADDED_SVC_CD
        ,        SVC.ADDED_SVC_CD
        || ';' || CUST.SVC_MNG_NUM
        || ';' || CUST.MOBILE_ID_NUM
        || ';' || DECODE( LENGTH(CUST.MOBILE_SVC_NUM), 10, SUBSTR(CUST.MOBILE_SVC_NUM, 1,3) || '0' || SUBSTR(CUST.MOBILE_SVC_NUM, 4),
                                                           CUST.MOBILE_SVC_NUM )
        || ';' || NVL(TO_CHAR(SVC.COIS_UPDATE_DT , 'YYYYMMDDHH24MISS'), '' )
        || ';' || NVL(TRIM(SVC.REG_PATH),'NONE' ) AS GET_DATA
	FROM
		TB_CUST_PROF  CUST,
		TB_CUST_ADDED_SVC SVC
	WHERE CUST.SVC_MNG_NUM = SVC.SVC_MNG_NUM
    ORDER BY 2 , 1 ;

    -- CVCJ @[>w@O 1bAX
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_MIG_CP_CUST Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    -- CJ1bH-

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  DATA Count
        read_cnt := read_cnt + 1;

        -- Gv@g <-:q=:0|8.9xH#
        v_svc_mng_num := c1.SVC_MNG_NUM ;

        IF read_cnt = 1 THEN
            v_pre_added_svc_cd := c1.ADDED_SVC_CD ;

			-- FILE OPEN
		    sam_data_filename :=  v_pre_added_svc_cd || '.dat' ;
            sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w', 12000 );
        ELSE
            v_crt_added_svc_cd := c1.ADDED_SVC_CD ;

            /* 1bA8 A$:8?M Gv@g A$:80! 00@:8i @L@|?! FD@O?! >20m */
	        IF v_pre_added_svc_cd = v_crt_added_svc_cd THEN
				NULL ;
	        /* 1W78D! >J@88i ;u7N?n FD@O@; ?,4Y*/
	        ELSE
	        	utl_file.fclose(sam_data_filetype);

				-- FILE OPEN
			    sam_data_filename :=  v_crt_added_svc_cd || '.dat' ;
	            sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w', 12000 );
	        END IF ;

        END IF ;

        utl_file.put_line(sam_data_filetype, c1.GET_DATA);
        write_cnt := write_cnt + 1;

		v_pre_added_svc_cd := v_crt_added_svc_cd ;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE( '***** WRITE [' || SQLERRM || '][' || v_svc_mng_num ||'] *****');
        COMMIT;
    END;
    END LOOP Process_Loop ;

-- ===============================================================
-- End Cursor Loop
-- ===============================================================

-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_MIG_CP_CUST Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
	WHEN OTHERS THEN
	   DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '][' || v_svc_mng_num || '] *****');
	   COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_CHILD_NUM"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_CHILD_NUM
-- History: (2005.11.04) - complues -
--          자번호 추가 및 실제 DATA Set
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;

-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

CURSOR cur_get_data IS
    SELECT            SVC_MNG_NUM
		|| '|' || NVL(CHILD_MOBILE_SVC_NUM      , '' ) AS GET_DATA
	FROM TB_CUST_CHILD
        ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_CHILD_NUM Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_child_num.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w', 32767 );
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  DATA Count
        read_cnt := read_cnt + 1;
        utl_file.put_line(sam_data_filetype, c1.GET_DATA );
        write_cnt := write_cnt + 1;

    EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  DBMS_OUTPUT.PUT_LINE( '***** WRITE [' || SQLERRM || '] *****');
		WHEN DUP_VAL_ON_INDEX THEN
		  DBMS_OUTPUT.PUT_LINE( '***** WRITE [' || SQLERRM || '] *****');
		WHEN TOO_MANY_ROWS THEN
		  DBMS_OUTPUT.PUT_LINE( '***** WRITE [' || SQLERRM || '] *****');
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE( '***** WRITE [' || SQLERRM || '] *****');
			COMMIT;
    END;
    END LOOP Process_Loop ;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================

-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_CHILD_NUM Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
    || ' ] *****');
EXCEPTION
	WHEN NO_DATA_FOUND THEN
	   DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN DUP_VAL_ON_INDEX THEN
	   DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN TOO_MANY_ROWS THEN
	   DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
		COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_ERR_FILTER_END_COIS" (
    l_limit_cnt IN NUMBER DEFAULT 3
)IS
-- -----------------------------------------------------------------------------
-- Procedure명 : SP_ERR_FILTER_END_COIS
-- 기능 : 불법단말 용의 단말 리스트를 모두 추출한 후 그 타입에서 실제 용의가 높은
--        고객정보만을 출력한다.
--
-- 변경력: 2004. 05. 13
--         1. 신규 생성 - compleus -
--         2005. 12. 08 : 조건별로 파일 하나만을 생성하도록 변경
-- -----------------------------------------------------------------------------
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/cust'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    fetch_cnt           NUMBER := 0 ;   -- 파일을 자르기위한 작업건수
    write_cnt           NUMBER := 0 ;   -- 총 write 작업건수
    read_cnt            NUMBER := 0 ;   -- 총 read 작업건수

    v_auth_read_cnt     NUMBER := 0 ;   -- 이전고객가입이력에서 읽은 건수
    v_auth_in_cnt       NUMBER := 0 ;   -- 고객가입이력에 삽인된 건수
    v_auth_del_cnt      NUMBER := 0 ;   -- 이전고객가입이력에서 삭제된 건수
    v_auth_skip_cnt     NUMBER := 0 ;   -- PK 중복발생으로 Skip된 건수

    ERR_MSG             VARCHAR2(150) ;
-- -----------------------------------------------------------------------------
-- 단수 참조에서 사용되는 변수
-- -----------------------------------------------------------------------------
    v_Base_Svc_Mng_Num  VARCHAR2(11) ;

    v_Modify_Cnt        NUMBER := 0;
    v_temp_cnt          NUMBER ;
    v_RecCnt            NUMBER ;
    v_Modify_limit      NUMBER := l_limit_cnt  ;    -- 변경횟수 이상인 건에 대한 추출
-- -----------------------------------------------------------------------------
-- 처리에 사용되 변수
-- -----------------------------------------------------------------------------
	v_Svc_Mng_Num        DBMS_SQL.Varchar2_Table    ;
	v_Start_Dt           DBMS_SQL.Date_Table        ;
	v_End_Dt             DBMS_SQL.Date_Table        ;
	v_Device_Mng_Num     DBMS_SQL.Varchar2_Table    ;
	v_Device_Mng_Dsc     DBMS_SQL.Varchar2_Table    ;
	v_Mobile_Id_Num      DBMS_SQL.Varchar2_Table    ;
	v_Mobile_Svc_Num     DBMS_SQL.Varchar2_Table    ;
	v_Exec_Id            DBMS_SQL.Varchar2_Table    ;
	v_Cois_Update_Dt     DBMS_SQL.Date_Table        ;
	v_Update_Cd          DBMS_SQL.Varchar2_Table    ;
	v_Update_Dt          DBMS_SQL.Date_Table        ;
	v_Update_Path        DBMS_SQL.Varchar2_Table    ;

    v_End_Exec_Id        VARCHAR2(8) ;


    -- FETCH 할 변수
    N_CURSOR    INTEGER;
    N_RET       INTEGER;
    SQL_TEXT    VARCHAR2(2000);

    fetch_size          NUMBER := 1000 ;
    indx                NUMBER := 1 ;
-------------------
-- 전체 서비스관리번호중에서서 추출함
-------------------
CURSOR cur_get_data1 IS
	SELECT DISTINCT SVC_MNG_NUM
	FROM GAEBAL_UPADM.TB_CUST_HIST_BOOL ;
	-- 10개만 우선 테스트

BEGIN
	ERR_MSG := '최초 SP_ERR_FILTER_END_COIS 실행' ;

	DBMS_OUTPUT.ENABLE ( 1000000);
	DBMS_OUTPUT.PUT_LINE( '***** [ SP_ERR_FILTER_END_COIS Procedure START ' || TO_CHAR
(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');

	-- FILE OPEN
    select 'boolbeop_' || TO_CHAR(sysdate, 'YYYYMM') || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

    << Main_Process_Loop >>
    FOR C1 IN cur_get_data1 LOOP
    	ERR_MSG := '내부 Main_Process_Loop 작업 처리 '|| read_cnt ||'에서 에러 발생' ;

    	read_cnt   := read_cnt + 1 ;
        v_Base_Svc_Mng_Num := C1.svc_mng_num ;

    	BEGIN	-- 2
	        -- 에러메시지 셋팅
	        ERR_MSG := '내부 Internal_Cursor_Loop 작업 초기화에서 에러 발생' ;

	        -- 각각의 대상에 대한 추출
            -- 다음 대상들은 비교 기준에서 빼준다(이유: 특정한 이유로 인하여 System적으로 변경을 일으켰으므로)
	        SQL_TEXT :=' SELECT * FROM TB_CUST_HIST_BOOL '
					|| ' WHERE SVC_MNG_NUM = ''' || v_Base_Svc_Mng_Num || ''''
					|| ' AND EXEC_ID NOT IN ( ''DUP_AUTO'', ''UAPIS'' , ''PRIME''  , ''SIMUL''  ,''ADMIN'') ' ;

			-- DBMS_OUTPUT.PUT_LINE( 'SQL [' || SQL_TEXT || ']');
	        -- ============
	        -- CURSOR 처리
	        -- ============
	        N_CURSOR := DBMS_SQL.OPEN_CURSOR;
	        DBMS_SQL.PARSE(N_CURSOR, SQL_TEXT, DBMS_SQL.NATIVE);

			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 1, v_Svc_Mng_Num    , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 2, v_Start_Dt       , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 3, v_End_Dt         , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 4, v_Device_Mng_Num , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 5, v_Device_Mng_Dsc , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 6, v_Mobile_Id_Num  , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 7, v_Mobile_Svc_Num , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 8, v_Exec_Id        , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 9, v_Cois_Update_Dt , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR,10, v_Update_Cd      , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR,11, v_Update_Dt      , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR,12, v_Update_Path    , fetch_size, indx );

	        N_RET := DBMS_SQL.EXECUTE(N_CURSOR);


	        v_temp_cnt := 1 ;
	        << Internal_Cursor_Loop >>
	        LOOP
	            N_RET := DBMS_SQL.FETCH_ROWS(N_CURSOR);
	            --DBMS_OUTPUT.PUT_LINE(N_RET);
	            v_RecCnt := DBMS_SQL.LAST_ROW_COUNT ;
	            --DBMS_OUTPUT.PUT_LINE('FETCH_CNT [' || v_RecCnt || ']');

	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 1, v_Svc_Mng_Num     );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 2, v_Start_Dt        );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 3, v_End_Dt          );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 4, v_Device_Mng_Num  );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 5, v_Device_Mng_Dsc  );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 6, v_Mobile_Id_Num   );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 7, v_Mobile_Svc_Num  );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 8, v_Exec_Id         );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 9, v_Cois_Update_Dt  );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR,10, v_Update_Cd       );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR,11, v_Update_Dt       );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR,12, v_Update_Path     );

	            /*
	            DBMS_OUTPUT.PUT_LINE('v_RecCnt         [' || v_RecCnt                      || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Svc_Mng_Num    [' || v_Svc_Mng_Num(v_temp_cnt)     || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Start_Dt       [' || v_Start_Dt(v_temp_cnt)        || ']');
	            DBMS_OUTPUT.PUT_LINE('v_End_Dt         [' || v_End_Dt(v_temp_cnt)          || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Device_Mng_Num [' || v_Device_Mng_Num(v_temp_cnt)  || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Device_Mng_Dsc [' || v_Device_Mng_Dsc(v_temp_cnt)  || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Mobile_Id_Num  [' || v_Mobile_Id_Num(v_temp_cnt)   || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Mobile_Svc_Num [' || v_Mobile_Svc_Num(v_temp_cnt)  || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Exec_Id        [' || v_Exec_Id(v_temp_cnt)         || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Cois_Update_Dt [' || v_Cois_Update_Dt(v_temp_cnt)  || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Update_Cd      [' || v_Update_Cd(v_temp_cnt)       || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Update_Dt      [' || v_Update_Dt(v_temp_cnt) || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Update_Path    [' || v_Update_Path(v_temp_cnt)     || ']');
	            */

	            v_temp_cnt := v_temp_cnt + 1 ;

	            EXIT WHEN N_RET != fetch_size ;
	        END LOOP Internal_Cursor_Loop ;

	        IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
	            DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
	        END IF;

	    EXCEPTION
	        WHEN OTHERS THEN
	            IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
	                DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
	            END IF;

				RETURN;
	    END ;

		v_Modify_Cnt := 0 ;

	    << Process_Loop >>
	    FOR i IN 1..v_RecCnt LOOP
	    	BEGIN
	    		ERR_MSG := '내부 Process_Loop 작업 처리 For'|| i ||'에서 에러 발생' ;

				-- 비교을 위해 처음 데이터는 따로 처리하지 않는다.
				-- 만약! 혹시라도 한껀뿐인 데이터라면 무시하게 되어 상관은 없다.
				--DBMS_OUTPUT.PUT_LINE('v_RecCnt [' || v_RecCnt || ']');
				--DBMS_OUTPUT.PUT_LINE('      svc[' || v_Svc_Mng_Num(i) || '][' || read_cnt || '] v_Device_Mng_Dsc[' || v_Device_Mng_Dsc(i) || '] v_Exec_Id[' || v_Exec_Id(i) ||'](' || i || ')' );

		        IF ( i <> 1 ) THEN
		        	-- 비교대상이 No_Model이 아닌것만 비교를 한다.
		        	-- DBMS_OUTPUT.PUT_LINE('      svc[' || v_Svc_Mng_Num(i) || '][' || v_Device_Mng_Dsc(i)|| ']:[' || v_Device_Mng_Dsc(i-1) || ']' );
		        	IF ( v_Device_Mng_Dsc(i)   = 'No_Model' OR
		        	     v_Device_Mng_Dsc(i-1) = 'No_Model' ) THEN
		        		NULL ;
		        	ELSE
		        		-- 비교하되 현재의 EXEC_ID가 WAPGW2, BWAPLOG2 일때만 이전 데이터와 비교 한다.
		        		-- 이유는 모든 데이터와의 정확한 비교를 위해서 (안도영과장 요청 2004-09-03)
		        		IF ( ( v_Exec_Id(i) = 'WAPGW2'   ) OR ( v_Exec_Id(i) = 'BWAPLOG2' ) ) THEN
		        			IF ( v_Device_Mng_Dsc(i) <> v_Device_Mng_Dsc(i-1) ) THEN
			        			v_Modify_Cnt := v_Modify_Cnt + 1 ;
			        		END IF ;  -- 비교 IF
		        		END IF ;  -- 변경 IF
		        	END IF ;  -- Mo_model IF

					/*
			        DBMS_OUTPUT.PUT_LINE('-----------------------------------------------');
			        DBMS_OUTPUT.PUT_LINE('v_RecCnt         [' || v_RecCnt || ']/['   || i || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Svc_Mng_Num    [' || v_Svc_Mng_Num(i)    || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Start_Dt       [' || to_char(v_Start_Dt(i),'YYYYMMDDHH24MISS')       || ']');
			        DBMS_OUTPUT.PUT_LINE('v_End_Dt         [' || to_char(v_End_Dt(i),'YYYYMMDDHH24MISS')         || ']');

			        DBMS_OUTPUT.PUT_LINE('v_Device_Mng_Num [' || v_Device_Mng_Num(i) || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Device_Mng_Dsc [' || v_Device_Mng_Dsc(i) || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Mobile_Id_Num  [' || v_Mobile_Id_Num(i)  || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Mobile_Svc_Num [' || v_Mobile_Svc_Num(i) || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Exec_Id        [' || v_Exec_Id(i)        || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Cois_Update_Dt [' || to_char(v_Cois_Update_Dt(i),'YYYYMMDDHH24MISS') || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Update_Cd      [' || v_Update_Cd(i)      || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Update_Dt      [' || to_char(v_Update_Dt(i),'YYYYMMDDHH24MISS')      || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Update_Path    [' || v_Update_Path(i)    || ']');
			        */

		        END IF;

                -- 최종 변경 처리경로가 COIS인가를 확인 하기 위함
		        IF ( i = v_RecCnt) THEN
                    v_End_Exec_Id := v_Exec_Id(i) ;
                END IF ;

		    EXCEPTION
		        WHEN OTHERS THEN
					DBMS_OUTPUT.PUT_LINE( TRIM(ERR_MSG) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
		    END ;

		END LOOP Process_Loop ;

        -- 건수 별로 데이터 파일 생성
        -- 최종 데이터가 COIS를 통해 변경되었으면 그 고객은 정신차린 고객으로 인정하고, 데이터로 남기지 말아야 한다.
        -- 임상조과장 요청(2005-02-27)

        IF ( v_End_Exec_Id = 'COIS' ) THEN
            NULL;
        ELSE
            -- v_Modify_limit회 이상 변경 되었으면 File에 쓰고 싶어 한다.
            IF ( v_Modify_Cnt > 0 ) THEN
	            BEGIN
	                ERR_MSG := '정보 Write 작업 처리 '|| v_Base_Svc_Mng_Num ||'에서 에러 발생' ;

	                -- 변경횟수를 원하는 예상하는 값이 나오도록 처리
	                IF ( v_Modify_Cnt > v_Modify_limit ) THEN
	                    v_Modify_Cnt := v_Modify_limit ;
	                END IF ;

		            -- Data Write(변경 횟수를 서비스관리번호와 같이 기록한다)
			        utl_file.put_line(sam_data_filetype, v_Modify_Cnt || '|' || v_Base_Svc_Mng_Num);

		            -- WRITE DATA 건수 Count
					write_cnt := write_cnt + 1;
					fetch_cnt := fetch_cnt + 1;
		        EXCEPTION
		            WHEN OTHERS THEN
						DBMS_OUTPUT.PUT_LINE( TRIM(ERR_MSG) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
		        END;
            ELSE
                NULL ;
            END IF ; -- 변경 횟수 체크
        END IF ;    -- 마지막 COIS 체크

        v_Modify_Cnt := 0 ;

	END LOOP Main_Process_Loop ;


    DBMS_OUTPUT.PUT_LINE( '***** [ 총 조회 대상 건수 ' || read_cnt    || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ 파일 기록 카운트  ' || write_cnt   || ' ] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ SP_ERR_FILTER_END_COIS Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');

-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE( TRIM(ERR_MSG) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
		ROLLBACK ;

END;
/





  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_UAP_DUP"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : SP_UAP_DUP
-- 기능 : 고객 불만처리 또는 기타 고객가입자이력의 과거정보가 요청 되었을 경우
--        Migration하기 전 Format의 이전 데이터를 현 UAProfile 의 Foramat에 맞게

--        바꾸어 입력을 하고 이전 데이터에서는 삭제 처리를 한다
--
-- 변경력: 2003. 11. 09
-- 		1. 신규 생성 - compleus -
-- -----------------------------------------------------------------------------
    ERR_MSG             VARCHAR2(150) ;
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    v_fetch_cnt         NUMBER := 0 ;   -- 작업기준 Fetch 건수
    v_hist_in_cnt	    NUMBER := 0 ;	-- 이력에 인서트한 건수
    v_info_up_cnt		NUMBER := 0 ;	-- 고객정보 변경 건수
    v_mw_in_cnt         NUMBER := 0 ;	-- Midware연동 테이블 인서트한 건수
    v_vam_in_cnt        NUMBER := 0 ;	-- Midware연동 테이블 인서트한 건수
    v_err_cnt			NUMBER := 0 ;	-- 처리중 에러인 서비스관리번호 건수

-- -----------------------------------------------------------------------------
-- 단수 참조에서 사용되는 변수
-- -----------------------------------------------------------------------------
    v_temp_cnt          NUMBER ;
    v_Exist_cnt         NUMBER ;
    v_Status            CHAR(1) := 'N' ;
    v_Res_Cd            CHAR(4) ;
    v_Proc_Flag         CHAR(1) ;

    v_To_Dev_Cnt		NUMBER := 0 ;
    v_From_Dev_Cnt		NUMBER := 0 ;

    v_Job_start_dt      DATE ;
    v_end_dt            DATE ;
    v_RecCnt            NUMBER ;
    v_Seq				NUMBER ;
-- -----------------------------------------------------------------------------
-- 처리에 사용되 변수
-- -----------------------------------------------------------------------------

	v_Svc_Mng_Num       DBMS_SQL.Varchar2_Table   ;
	v_Device_Mng_Num    DBMS_SQL.Varchar2_Table   ;
	v_Mobile_Id_Num     DBMS_SQL.Varchar2_Table   ;
	v_Mobile_Svc_Num    DBMS_SQL.Varchar2_Table   ;
	v_Net_Gen_Tp        DBMS_SQL.Varchar2_Table   ;
	v_Client_Id_Yn      DBMS_SQL.Varchar2_Table   ;
	v_Client_Id_Net2G   DBMS_SQL.Varchar2_Table   ;
	v_Client_Id_Net3G   DBMS_SQL.Varchar2_Table   ;
	v_Client_Id_Cust    DBMS_SQL.Varchar2_Table   ;
	v_Imsi              DBMS_SQL.Varchar2_Table   ;
	v_Imei              DBMS_SQL.Varchar2_Table   ;
	v_Exec_Id           DBMS_SQL.Varchar2_Table   ;
	v_Cois_Update_Dt    DBMS_SQL.Date_Table       ;
	v_Update_Cd         DBMS_SQL.Varchar2_Table   ;
	v_Update_Dt         DBMS_SQL.Date_Table       ;
	v_Update_Path       DBMS_SQL.Varchar2_Table   ;

    -- FETCH 할 변수
    N_CURSOR    INTEGER;
    N_RET       INTEGER;
    SQL_TEXT    VARCHAR2(2000);

    fetch_size          NUMBER := 1000 ;
    indx                NUMBER := 1 ;
-- 중복 처리 대상
CURSOR cur_get_data IS
	SELECT *
	FROM "GAEBAL_UPADM".TB_UAP_DUP
	WHERE STATUS = 'P' ;

BEGIN
	ERR_MSG := '최초 Procedure' ;
	v_Status := 'N' ;
	v_Res_Cd := 'E999' ;

	DBMS_OUTPUT.ENABLE ( 1000000);
	DBMS_OUTPUT.PUT_LINE( '***** [ SP_UAP_DUP Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ]*****');

    -- 메인 처리
    << Base_Loop >>
    FOR C1 IN cur_get_data LOOP
		BEGIN
	    	v_Seq := C1.SEQ ;
	    	v_fetch_cnt := v_fetch_cnt + 1 ;
			v_Job_start_dt := SYSDATE ;
			v_Proc_Flag := 'Y' ;

			-- 입력값에서 에러가 발생되면
			-- 입력값 체크
			IF v_Proc_Flag = 'Y' THEN
				IF TRIM(C1.TO_DEVICE_MNG_NUM) = TRIM(C1.FROM_DEVICE_MNG_NUM) THEN
					ERR_MSG  := '같은 단말기관리코드는 처리할 수 없습니다.' ;
					v_Status := 'Y' ;
					v_Res_Cd := 'W001' ;
					v_Proc_Flag := 'N' ;
				END IF ;
			END IF ;

			IF v_Proc_Flag = 'Y' THEN
				IF INSTR(TRIM(C1.TO_DEVICE_MNG_NUM), CHR(10)) > 0  OR
				   INSTR(TRIM(C1.TO_DEVICE_MNG_NUM), CHR(0) ) > 0  OR
				   INSTR(TRIM(C1.TO_DEVICE_MNG_NUM), CHR(12)) > 0  OR
				   INSTR(TRIM(C1.TO_DEVICE_MNG_NUM), ' '    ) > 0  OR
				   INSTR(TRIM(C1.FROM_DEVICE_MNG_NUM), CHR(10)) > 0  OR
				   INSTR(TRIM(C1.FROM_DEVICE_MNG_NUM), CHR(0) ) > 0  OR
				   INSTR(TRIM(C1.FROM_DEVICE_MNG_NUM), CHR(12)) > 0  OR
				   INSTR(TRIM(C1.FROM_DEVICE_MNG_NUM), ' '    ) > 0  THEN
					ERR_MSG  := '단말기관리번호에 특수문자 값이 존재합니다.' ;
					v_Status := 'Y' ;
					v_Res_Cd := 'W002' ;
					v_Proc_Flag := 'N' ;
				END IF ;
			END IF ;

			IF v_Proc_Flag = 'Y' THEN
				SELECT COUNT(*) INTO v_Exist_cnt
				FROM "GAEBAL_UPADM".TB_UAP
				WHERE DEVICE_MNG_NUM = C1.TO_DEVICE_MNG_NUM ;

				IF v_Proc_Flag = 'Y' THEN
					IF v_Exist_cnt = 0 THEN
						ERR_MSG  := 'Target 단말기관리코드 ' || C1.TO_DEVICE_MNG_NUM || ' 가 존재하지 않습니다.' ;
						v_Status := 'Y' ;
						v_Res_Cd := 'W003' ;
						v_Proc_Flag := 'N' ;
					END IF ;
				END IF ;
			END IF ;

			IF v_Proc_Flag = 'Y' THEN

				SELECT COUNT(*) INTO v_Exist_cnt
				FROM "GAEBAL_UPADM".TB_UAP_ATTR_LIST
				WHERE DEVICE_MNG_NUM = C1.TO_DEVICE_MNG_NUM ;

				IF v_Exist_cnt = 0 THEN
					ERR_MSG  := 'Target 단말기관리코드 ' || C1.TO_DEVICE_MNG_NUM || ' 의 LIST가 존재하지 않습니다.' ;
					v_Status := 'Y' ;
					v_Res_Cd := 'W004' ;
					v_Proc_Flag := 'N' ;
				END IF ;
			END IF ;

			/*
			-- 혹시 세밀한점검을 필요로 하면 Comment 처리를 해제한다.
			-- Comment를 지우면 프로그램을 유동적으로 사용하지 못함.
			-- (예. 단말기관리번호만 지우려면 다른식으로 해야함 -_-;;)
			IF v_Proc_Flag = 'Y' THEN
				SELECT COUNT(*) INTO v_Exist_cnt
				FROM "GAEBAL_UPADM".TB_UAP
				WHERE DEVICE_MNG_NUM = C1.FROM_DEVICE_MNG_NUM ;

				IF v_Proc_Flag = 'Y' THEN
					IF v_Exist_cnt = 0 THEN
						ERR_MSG  := '변경 할' || C1.FROM_DEVICE_MNG_NUM || ' 의 단말기관리코드가 존재하지 않습니다.' ;
						v_Status := 'Y' ;
						v_Res_Cd := 'W005' ;
						v_Proc_Flag := 'N' ;
					END IF ;
				END IF ;
			END IF ;

			IF v_Proc_Flag = 'Y' THEN

				SELECT COUNT(*) INTO v_Exist_cnt
				FROM "GAEBAL_UPADM".TB_UAP_ATTR_LIST
				WHERE DEVICE_MNG_NUM = C1.FROM_DEVICE_MNG_NUM ;

				IF v_Exist_cnt = 0 THEN
					ERR_MSG  := '변경 할' || C1.FROM_DEVICE_MNG_NUM || ' 의 단말기관리코드 LIST가 존재하지 않습니다.' ;
					v_Status := 'Y' ;
					v_Res_Cd := 'W006' ;
					v_Proc_Flag := 'N' ;
				END IF ;
			END IF ;
			*/

			-- 입력값에서 에러가 발생되면
			IF v_Proc_Flag = 'N' THEN
				BEGIN
					-- 처리결과값 업데이트
					UPDATE "GAEBAL_UPADM".TB_UAP_DUP
					SET   STATUS = v_Status
					    , RES_CD = v_Res_Cd
					    , RES_DESC = RES_DESC || ' MSG:'  || ERR_MSG
					    , START_DT = v_Job_start_dt
					    , END_DT = SYSDATE
					WHERE SEQ = C1.SEQ ;
				EXCEPTION
					WHEN OTHERS THEN
						-- 잡로그 완성
						DBMS_OUTPUT.PUT_LINE( '입력값 CHECK 처리결과 INSERT [' || SQLERRM || ']' ) ;
						NULL ;
				END ;
				-- 다음 처리로 가기 위해서
				GOTO  Base_Loop_Continue ;
			END IF ;

			-- 변경될 단말기 건수
			SELECT COUNT(*) INTO v_To_Dev_Cnt
			FROM "GAEBAL_UPADM".TB_CUST_PROF
			WHERE DEVICE_MNG_NUM = C1.TO_DEVICE_MNG_NUM ;

			-- 변경할 단말기 건수
			SELECT COUNT(*) INTO v_From_Dev_Cnt
			FROM "GAEBAL_UPADM".TB_CUST_PROF
			WHERE DEVICE_MNG_NUM = C1.FROM_DEVICE_MNG_NUM ;

			v_info_up_cnt := 0 ;

		    BEGIN
		        -- 에러메시지 셋팅
		        ERR_MSG := '내부 Internal_Cursor_Loop 작업 초기화 및 처리에서 에러 발생' ;

		        -- 각각의 대상에 대한 추출
		        SQL_TEXT :=' SELECT '
						|| '      SVC_MNG_NUM     '
						|| '    , DEVICE_MNG_NUM  '
						|| '    , MOBILE_ID_NUM   '
						|| '    , MOBILE_SVC_NUM  '
						|| '    , NET_GEN_TP      '
						|| '    , CLIENT_ID_YN    '
						|| '    , CLIENT_ID_NET2G '
						|| '    , CLIENT_ID_NET3G '
						|| '    , CLIENT_ID_CUST  '
						|| '    , IMSI            '
						|| '    , IMEI            '
						|| '    , EXEC_ID         '
						|| '    , COIS_UPDATE_DT  '
						|| '    , UPDATE_CD       '
						|| '    , UPDATE_DT       '
						|| '    , UPDATE_PATH     '
						||' FROM "GAEBAL_UPADM".TB_CUST_PROF '
						||' WHERE DEVICE_MNG_NUM = ''' || C1.FROM_DEVICE_MNG_NUM || '''' ;

		        -- ============
		        -- CURSOR 처리
		        -- ============
		        N_CURSOR := DBMS_SQL.OPEN_CURSOR;
		        DBMS_SQL.PARSE(N_CURSOR, SQL_TEXT, DBMS_SQL.NATIVE);

				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 1 ,v_Svc_Mng_Num    , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 2 ,v_Device_Mng_Num , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 3 ,v_Mobile_Id_Num  , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 4 ,v_Mobile_Svc_Num , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 5 ,v_Net_Gen_Tp     , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 6 ,v_Client_Id_Yn   , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 7 ,v_Client_Id_Net2G, fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 8 ,v_Client_Id_Net3G, fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 9 ,v_Client_Id_Cust , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 10,v_Imsi           , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 11,v_Imei           , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 12,v_Exec_Id        , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 13,v_Cois_Update_Dt , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 14,v_Update_Cd      , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 15,v_Update_Dt      , fetch_size, indx );
				DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 16,v_Update_Path    , fetch_size, indx );

		        N_RET := DBMS_SQL.EXECUTE(N_CURSOR);

		        v_temp_cnt := 1 ;
		        << Internal_Cursor_Loop >>
		        LOOP
		            N_RET := DBMS_SQL.FETCH_ROWS(N_CURSOR);
		            --DBMS_OUTPUT.PUT_LINE(N_RET);
		            v_RecCnt := DBMS_SQL.LAST_ROW_COUNT ;
		            --DBMS_OUTPUT.PUT_LINE('FETCH_CNT [' || v_RecCnt || ']');

		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 1 ,v_Svc_Mng_Num     );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 2 ,v_Device_Mng_Num  );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 3 ,v_Mobile_Id_Num   );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 4 ,v_Mobile_Svc_Num  );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 5 ,v_Net_Gen_Tp      );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 6 ,v_Client_Id_Yn    );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 7 ,v_Client_Id_Net2G );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 8 ,v_Client_Id_Net3G );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 9 ,v_Client_Id_Cust  );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 10,v_Imsi            );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 11,v_Imei            );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 12,v_Exec_Id         );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 13,v_Cois_Update_Dt  );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 14,v_Update_Cd       );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 15,v_Update_Dt       );
		            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 16,v_Update_Path     );

		            /*
		            DBMS_OUTPUT.PUT_LINE('v_RecCnt          [' || v_RecCnt                      || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Svc_Mng_Num     [' || v_Svc_Mng_Num(v_temp_cnt)     || ']')
;
		            DBMS_OUTPUT.PUT_LINE('v_Device_Mng_Num  [' || v_Device_Mng_Num(v_temp_cnt)  || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Mobile_Id_Num   [' || v_Mobile_Id_Num(v_temp_cnt)   || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Mobile_Svc_Num  [' || v_Mobile_Svc_Num(v_temp_cnt)  || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Net_Gen_Tp      [' || v_Net_Gen_Tp(v_temp_cnt)      || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Client_Id_Yn    [' || v_Client_Id_Yn(v_temp_cnt)    || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Client_Id_Net2G [' || v_Client_Id_Net2G(v_temp_cnt) || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Client_Id_Net3G [' || v_Client_Id_Net3G(v_temp_cnt) || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Client_Id_Cust  [' || v_Client_Id_Cust(v_temp_cnt)  || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Imsi            [' || v_Imsi(v_temp_cnt)    || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Imei            [' || v_Imei(v_temp_cnt)            || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Exec_Id         [' || v_Exec_Id(v_temp_cnt)  || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Cois_Update_Dt  [' || v_Cois_Update_Dt(v_temp_cnt)  || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Update_Cd       [' || v_Update_Cd(v_temp_cnt)|| ']');
		            DBMS_OUTPUT.PUT_LINE('v_Update_Dt       [' || v_Update_Dt(v_temp_cnt)       || ']');
		            DBMS_OUTPUT.PUT_LINE('v_Update_Path     [' || v_Update_Path(v_temp_cnt)     || ']');
		            */

		            v_temp_cnt := v_temp_cnt + 1 ;

		            EXIT WHEN N_RET != fetch_size ;
		        END LOOP Internal_Cursor_Loop ;

		        IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
		            DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
		        END IF;

		    EXCEPTION
		        WHEN OTHERS THEN
		            IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
		                DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
		            END IF;
		            ERR_MSG  := ERR_MSG || '[' || SQLERRM || ']';
		            v_Status := 'N' ;
		            v_Res_Cd := 'E002' ;

		            BEGIN
			            -- 처리결과 저장
						UPDATE "GAEBAL_UPADM".TB_UAP_DUP
						SET   STATUS = v_Status
						    , RES_CD = v_Res_Cd
						    , RES_DESC = RES_DESC || ' MSG:'  || ERR_MSG
						    , START_DT = v_Job_start_dt
						    , END_DT = SYSDATE
						WHERE SEQ = C1.SEQ ;
						COMMIT ;
					EXCEPTION
						WHEN OTHERS THEN
							-- 잡로그 완성
							DBMS_OUTPUT.PUT_LINE( 'Internal_Cursor_Loop 처리결과 INSERT [' || SQLERRM || ']' ) ;
							NULL ;
					END ;
					-- 다음 처리로 가기 위해서
					GOTO Base_Loop_Continue ;
		    END ;

			-- ============
			-- 메인처리
			-- ============
		    << Process_Loop >>
		    FOR i IN 1..v_RecCnt LOOP
		        ERR_MSG := '내부 Process_Loop 작업 처리 '|| i ||'에서 에러 발생' ;
				v_end_dt := SYSDATE ;

				-- TB_CUST_PROF_HIST 입력
				BEGIN
					ERR_MSG := '내부 Process_Loop 작업 처리 에러 ' || i ||'(TB_CUST_PROF_HIST INSERT)' ;
					INSERT INTO "GAEBAL_UPADM".TB_CUST_PROF_HIST
					(
						 SVC_MNG_NUM
						,START_DT
						,END_DT
						,DEVICE_MNG_NUM
						,MOBILE_ID_NUM
						,MOBILE_SVC_NUM
						,NET_GEN_TP
						,CLIENT_ID_YN
						,CLIENT_ID_NET2G
						,CLIENT_ID_NET3G
						,CLIENT_ID_CUST
						,IMSI
						,IMEI
						,EXEC_ID
						,COIS_UPDATE_DT
						,UPDATE_CD
						,UPDATE_DT
						,UPDATE_PATH
					) VALUES (
						 v_Svc_Mng_Num(i)
						,v_Update_Dt(i)
						,v_end_dt						-- 현제시간
						,v_Device_Mng_Num(i)
						,v_Mobile_Id_Num(i)
						,v_Mobile_Svc_Num(i)
						,v_Net_Gen_Tp(i)
						,v_Client_Id_Yn(i)
						,v_Client_Id_Net2G(i)
						,v_Client_Id_Net3G(i)
						,v_Client_Id_Cust(i)
						,v_Imsi(i)
						,v_Imei(i)
						,v_Exec_Id(i)
						,v_Cois_Update_Dt(i)
						,v_Update_Cd(i)
						,v_Update_Dt(i)
						,v_Update_Path(i)
					) ;
					v_hist_in_cnt := v_hist_in_cnt + 1 ;

					-- TB_CUST_PROF 수정
					ERR_MSG := '내부 Process_Loop 작업 처리 에러 ' || i ||'(TB_CUST_PROF UPDATE)' ;

					UPDATE "GAEBAL_UPADM".TB_CUST_PROF
					SET	  DEVICE_MNG_NUM = C1.TO_DEVICE_MNG_NUM
					    , EXEC_ID        = 'DUP_AUTO'
					    , UPDATE_CD      = 'C1'				-- 기기변경
					    , UPDATE_DT      = v_end_dt
					    , UPDATE_PATH    = C1.EXEC_ID
					WHERE SVC_MNG_NUM = v_Svc_Mng_Num(i) ;
					v_info_up_cnt := v_info_up_cnt + 1 ;


					-- MIDWARE용 CP참조 테이블 입력 TB_CUST_UAP_MW_BUF
					ERR_MSG := 'Internal_Cursor_Loop 에러 ' || i ||'(TB_CUST_UAP_MW_BUF INSERT)' ;

					INSERT INTO "GAEBAL_UPADM".TB_CUST_UAP_MW_BUF
					(
						 SEQ
						,SVC_MNG_NUM
						,UPDATE_CD
						,COIS_UPDATE_DT
						,UPDATE_DT
					) VALUES (
						 SEQ_CUST_UAP_MW.NEXTVAL
						,v_Svc_Mng_Num(i)
						,'C1'
						,v_Cois_Update_Dt(i)
						,v_end_dt
					) ;

					v_mw_in_cnt := v_mw_in_cnt + 1 ;

					-- 고도화용 CP참조 테이블 입력 TB_CUST_UAP_VAM_BUF
					ERR_MSG := 'Internal_Cursor_Loop 에러 ' || i ||'(TB_CUST_UAP_VAM_BUF INSERT)' ;

					INSERT INTO "GAEBAL_UPADM".TB_CUST_UAP_VAM_BUF
					(
						 SEQ
						,SVC_MNG_NUM
						,UPDATE_CD
						,COIS_UPDATE_DT
						,UPDATE_DT
					) VALUES (
						 SEQ_CUST_UAP_VAM.NEXTVAL
						,v_Svc_Mng_Num(i)
						,'C1'
						,v_Cois_Update_Dt(i)
						,v_end_dt
					) ;

					v_vam_in_cnt := v_vam_in_cnt + 1 ;

				-- 한개의 서비스관리번호당 COMMIT 처리
				COMMIT ;

		        EXCEPTION
		            WHEN NO_DATA_FOUND THEN
						ERR_MSG := ERR_MSG || '[' || SUBSTR(SQLERRM,1,200) || ']' ;
						v_err_cnt := v_err_cnt + 1 ;
						DBMS_OUTPUT.PUT_LINE( TRIM(SUBSTR(ERR_MSG,1, 50)) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
						ROLLBACK ;
		            WHEN OTHERS THEN
						ERR_MSG := ERR_MSG || '[' || SUBSTR(SQLERRM,1,200) || ']' ;
						v_err_cnt := v_err_cnt + 1 ;
						DBMS_OUTPUT.PUT_LINE( TRIM(SUBSTR(ERR_MSG,1, 50)) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
						ROLLBACK ;
		        END ;  -- 2

		    END LOOP Process_Loop ;


			IF v_err_cnt = 0 THEN
			    -- 해당 단말기관리번호의 데이터 삭제(TB_UAP_ATTR_LIST)
			    BEGIN
			    	DELETE FROM "GAEBAL_UPADM".TB_UAP_ATTR_LIST
			    	WHERE DEVICE_MNG_NUM = C1.FROM_DEVICE_MNG_NUM ;
			    EXCEPTION
			    	WHEN OTHERS THEN
			    		ROLLBACK ;
			    		ERR_MSG  := '단말기정보 LIST 처리 중 에러' ;
			            v_Status := 'N' ;
			            v_Res_Cd := 'E003' ;

			            BEGIN
				            -- 처리결과 저장
							UPDATE "GAEBAL_UPADM".TB_UAP_DUP
							SET   STATUS = v_Status
							    , RES_CD = v_Res_Cd
							    , RES_DESC = RES_DESC || ' MSG:'  || ERR_MSG
							    , START_DT = v_Job_start_dt
							    , END_DT = SYSDATE
							WHERE SEQ = C1.SEQ ;
							COMMIT ;
						EXCEPTION
							WHEN OTHERS THEN
								-- 잡로그 완성
								DBMS_OUTPUT.PUT_LINE( '단말기정보 LIST 처리결과 INSERT [' || SQLERRM || ']' ) ;
								NULL ;
						END ;
						-- 다음 처리로 가기 위해서
						GOTO Base_Loop_Continue ;
			    END ;

			END IF ;

		    IF v_err_cnt = 0 THEN
			    -- 해당 단말기관리번호의 데이터 추가( TB_UAP_CHANGE )
			    BEGIN
			    	INSERT INTO  "GAEBAL_UPADM".TB_UAP_CHANGE
			    	(
						 SEQ
						,REG_DT
						,TBL_CD
						,CHANGE_TP
						,DEVICE_MNG_NUM
						,URI
			    	)
			    	SELECT
						 SEQ_UAP_CHANGE.NEXTVAL
						,SYSDATE
						,'20'		-- TB_UAP와 TB_UAP_ATTR_LIST가 동시에 변경
						,'D'        -- 삭제 처리
						,DEVICE_MNG_NUM
						,URI
					FROM "GAEBAL_UPADM".TB_UAP
			    	WHERE DEVICE_MNG_NUM = C1.FROM_DEVICE_MNG_NUM ;

			    	COMMIT ;
			    EXCEPTION
			    	WHEN OTHERS THEN
			    		ROLLBACK ;
			    		ERR_MSG  := '변경정보 알림 처리 중 에러' ;
			            v_Status := 'N' ;
			            v_Res_Cd := 'E006' ;

						BEGIN
				            -- 처리결과 저장
							UPDATE "GAEBAL_UPADM".TB_UAP_DUP
							SET   STATUS = v_Status
							    , RES_CD = v_Res_Cd
							    , RES_DESC = RES_DESC || ' MSG:'  || ERR_MSG
							    , START_DT = v_Job_start_dt
							    , END_DT = SYSDATE
							WHERE SEQ = C1.SEQ ;
							COMMIT ;
						EXCEPTION
							WHEN OTHERS THEN
								-- 잡로그 완성
								DBMS_OUTPUT.PUT_LINE( '단말기정보 처리결과 INSERT [' || SQLERRM || ']' ) ;
								NULL ;
						END ;
						-- 다음 처리로 가기 위해서
						GOTO Base_Loop_Continue ;
			    END ;

			END IF ;
			/*
		    IF v_err_cnt = 0 THEN
			    -- 매핑테이블(IFS용) 해당 단말기관리번호의 데이터 복사( TB_UAF_MAP )
			    BEGIN
			    	SELECT COUNT(*) INTO v_Exist_cnt
			    	FROM "GAEBAL_UPADM".TB_UAF_MAP
			    	WHERE DEVICE_MNG_NUM = C1.TO_DEVICE_MNG_NUM ;

			    	IF v_Exist_cnt = 0 THEN
			    		INSERT INTO "GAEBAL_UPADM".TB_UAF_MAP(DEVICE_MNG_NUM, UAF_DATA)
			    		SELECT C1.FROM_DEVICE_MNG_NUM
			    		      ,UAF_DATA
			    		FROM "GAEBAL_UPADM".TB_UAF_MAP
			    		WHERE DEVICE_MNG_NUM = C1.TO_DEVICE_MNG_NUM ;
			    	ELSE
			    		UPDATE "GAEBAL_UPADM".TB_UAF_MAP
			    		SET UAF_DATA = ( SELECT UAF_DATA
			    						 FROM "GAEBAL_UPADM".TB_UAF_MAP
			    						 WHERE DEVICE_MNG_NUM = C1.TO_DEVICE_MNG_NUM )
						WHERE DEVICE_MNG_NUM = C1.FROM_DEVICE_MNG_NUM ;
			    	END IF ;

			    	COMMIT ;
			    EXCEPTION
			    	WHEN OTHERS THEN
			    		ROLLBACK ;
			    		ERR_MSG  := 'TB_UAF_MAP 변경 처리 중 에러' ;
			            v_Status := 'N' ;
			            v_Res_Cd := 'E008' ;

						BEGIN
				            -- 처리결과 저장
							UPDATE "GAEBAL_UPADM".TB_UAP_DUP
							SET   STATUS = v_Status
							    , RES_CD = v_Res_Cd
							    , RES_DESC = RES_DESC || ' MSG:'  || ERR_MSG
							    , START_DT = v_Job_start_dt
							    , END_DT = SYSDATE
							WHERE SEQ = C1.SEQ ;
							COMMIT ;
						EXCEPTION
							WHEN OTHERS THEN
								-- 잡로그 완성
								DBMS_OUTPUT.PUT_LINE( '매핑테이블(IFS용) INSERT OR UPDATE [' || SQLERRM|| ']' ) ;
								NULL ;
						END ;
						-- 다음 처리로 가기 위해서
						GOTO Base_Loop_Continue ;
			    END ;

			END IF ;
			*/

		    IF v_err_cnt = 0 THEN
			    -- 매핑테이블(IFS용) 해당 단말기관리번호의 데이터 삭제( TB_UAF_MAP )
			    BEGIN
			    	DELETE FROM "GAEBAL_UPADM".TB_UAF_MAP
			    	WHERE DEVICE_MNG_NUM = C1.FROM_DEVICE_MNG_NUM ;

			    	COMMIT ;
			    EXCEPTION
			    	WHEN OTHERS THEN
			    		ROLLBACK ;
			    		ERR_MSG  := 'TB_UAF_MAP 처리 중 에러' ;
			            v_Status := 'N' ;
			            v_Res_Cd := 'E007' ;

						BEGIN
				            -- 처리결과 저장
							UPDATE "GAEBAL_UPADM".TB_UAP_DUP
							SET   STATUS = v_Status
							    , RES_CD = v_Res_Cd
							    , RES_DESC = RES_DESC || ' MSG:'  || ERR_MSG
							    , START_DT = v_Job_start_dt
							    , END_DT = SYSDATE
							WHERE SEQ = C1.SEQ ;
							COMMIT ;
						EXCEPTION
							WHEN OTHERS THEN
								-- 잡로그 완성
								DBMS_OUTPUT.PUT_LINE( '매핑테이블(IFS용) DELETE [' || SQLERRM || ']' ) ;
								NULL ;
						END ;
						-- 다음 처리로 가기 위해서
						GOTO Base_Loop_Continue ;
			    END ;

			END IF ;

		    IF v_err_cnt = 0 THEN
			    -- 해당 단말기관리번호의 데이터 삭제(TB_UAP)
			    BEGIN
			    	DELETE FROM "GAEBAL_UPADM".TB_UAP
			    	WHERE DEVICE_MNG_NUM = C1.FROM_DEVICE_MNG_NUM ;
			    EXCEPTION
			    	WHEN OTHERS THEN
			    		ROLLBACK ;
			    		ERR_MSG  := '단말기정보 처리 중 에러' ;
			            v_Status := 'N' ;
			            v_Res_Cd := 'E004' ;

						BEGIN
				            -- 처리결과 저장
							UPDATE "GAEBAL_UPADM".TB_UAP_DUP
							SET   STATUS = v_Status
							    , RES_CD = v_Res_Cd
							    , RES_DESC = RES_DESC || ' MSG:'  || ERR_MSG
							    , START_DT = v_Job_start_dt
							    , END_DT = SYSDATE
							WHERE SEQ = C1.SEQ ;
							COMMIT ;
						EXCEPTION
							WHEN OTHERS THEN
								-- 잡로그 완성
								DBMS_OUTPUT.PUT_LINE( '단말기정보 처리결과 INSERT [' || SQLERRM || ']' ) ;
								NULL ;
						END ;
						-- 다음 처리로 가기 위해서
						GOTO Base_Loop_Continue ;
			    END ;

			END IF ;

		    -- 모든처리 완료
		    IF v_err_cnt > 0 THEN
	    		ERR_MSG  := '[' || C1.FROM_DEVICE_MNG_NUM || ' CNT(' || v_From_Dev_Cnt ||') --> ' || C1.TO_DEVICE_MNG_NUM || ' CNT(' || v_To_Dev_Cnt || ')]/'
	    		         || '[' || C1.FROM_DEVICE_MNG_NUM || '변경처리]/[처리대상 : ' || v_From_Dev_Cnt || '건]/[정상처리 : ' || v_info_up_cnt || '건]/'
	    		         || '[에러 처리: ' || v_err_cnt || '건]/[미 처 리 : ' || ( v_temp_cnt - v_info_up_cnt ) ||'건]/';
	            v_Status := 'Y' ;
	            v_Res_Cd := 'W000' ;
		    ELSE
	    		ERR_MSG  := '[' || C1.FROM_DEVICE_MNG_NUM || ' CNT(' || v_From_Dev_Cnt ||') --> ' || C1.TO_DEVICE_MNG_NUM || ' CNT(' || v_To_Dev_Cnt || ')]/'
	    		         || '[' || C1.FROM_DEVICE_MNG_NUM || '변경처리]/[처리대상 : ' || v_From_Dev_Cnt || '건]/[정상처리 : ' || v_info_up_cnt || '건]/' ;
	            v_Status := 'Y' ;
	            v_Res_Cd := 'I000' ;
		    END IF ;

		    -- 한 처리가 완료되면 요청 테이블 업데이트
			BEGIN
				-- 처리결과값 업데이트
				UPDATE "GAEBAL_UPADM".TB_UAP_DUP
				SET   STATUS = v_Status
				    , RES_CD = v_Res_Cd
				    , RES_DESC = RES_DESC || ' MSG:'  || ERR_MSG
				    , START_DT = v_Job_start_dt
				    , END_DT = SYSDATE
				WHERE SEQ = C1.SEQ ;
				COMMIT ;
			EXCEPTION
				WHEN OTHERS THEN
					-- 잡로그 완성
					DBMS_OUTPUT.PUT_LINE( '정상처리 최종결과 INSERT [' || SQLERRM || ']' ) ;
					NULL ;
			END ;

		EXCEPTION
	        WHEN OTHERS THEN
				ERR_MSG := ERR_MSG || '[' || SUBSTR(SQLERRM,1,200) || ']';
				ROLLBACK ;
		END ;

		<< Base_Loop_Continue >>
		NULL;
    END LOOP Base_Loop ;


	-- 한서비스관리 번호의 작업이 정상적일 때만 정보 저장
	COMMIT ;
	DBMS_OUTPUT.PUT_LINE( '***** [ SP_UAP_DUP Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');

EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK ;

		ERR_MSG := ERR_MSG || '[' || SUBSTR(SQLERRM,1,200) || ']';
		v_Status := 'N' ;
		v_Res_Cd := 'E999' ;

		BEGIN
			UPDATE "GAEBAL_UPADM".TB_UAP_DUP
			SET   STATUS = v_Status
			    , RES_CD = v_Res_Cd
			    , RES_DESC = RES_DESC || ' MSG:'  || ERR_MSG
			    , START_DT = v_Job_start_dt
			    , END_DT = SYSDATE
			WHERE SEQ = v_Seq ;
			COMMIT ;
		EXCEPTION
			WHEN OTHERS THEN
				-- 잡로그 완성
				DBMS_OUTPUT.PUT_LINE( 'Internal_Cursor_Loop 처리결과 INSERT [' || SQLERRM || ']' ) ;
				NULL ;
		END ;
		DBMS_OUTPUT.PUT_LINE( TRIM(SUBSTR(ERR_MSG,1, 50)) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
END;	-- 1.
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_UAP_WAP_FMI"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_UAP_WAP_FMI
-- 기능 : SKT사용자 대상으로 안드로이드 스마트폰 여부 확인
--        정보의 이력을 SAM 파일생성(TB_USER_LIST,TB_CUST_PROF,TB_UAP,TB_UAP_ATTR_LIST)
--        * 같은 내용도 모두 출력
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    log_cnt     NUMBER := 0;
    err_code    varchar2(200);
-- -- --------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- --------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
CURSOR cur_get_data IS
SELECT          SABUN.USER_ID
                ||'|'|| SABUN.MDN_NM
                ||'|'|| CUST.DEVICE_MNG_NUM
                ||'|'|| DEL.MODEL
                ||'|'|| NAME.OSName
                ||'|'|| VEN.OSVendor
                ||'|'|| VER.OSVersion AS GET_DATA
FROM
                (SELECT USER_ID,MDN_NM
                        FROM TB_FMI_SRC
                        ) SABUN,
                (SELECT MOBILE_SVC_NUM,DEVICE_MNG_NUM
                        FROM TB_CUST_PROF
                        WHERE  MVNO_CD = '0'  -- 2011.07.15 COLUS3 - MVNO사업자 구분코드가 '0'(SKT)인 데이터만 추출
                        ) CUST,
                (SELECT DEVICE_MNG_NUM, NVL(ATTR_VAL,'No_Model') AS MODEL
                        FROM TB_UAP_ATTR_LIST
                        WHERE COMPO_CD = 'HW'
                        AND   SUB_COMPO_CD = ' '
                        AND   ATTR_NM = 'Model'
                        ) DEL,
                (SELECT DEVICE_MNG_NUM, ATTR_VAL AS OSName
                        FROM TB_UAP_ATTR_LIST
                        WHERE COMPO_CD = 'SW'
                        AND   SUB_COMPO_CD = ' '
                        AND   ATTR_NM = 'OSName'
                        ) NAME,
                (SELECT DEVICE_MNG_NUM, ATTR_VAL AS OSVendor
                        FROM TB_UAP_ATTR_LIST
                        WHERE COMPO_CD = 'SW'
                        AND   SUB_COMPO_CD = ' '
                        AND   ATTR_NM = 'OSVendor'
                        ) VEN,
                (SELECT DEVICE_MNG_NUM, ATTR_VAL AS OSVersion
                        FROM TB_UAP_ATTR_LIST
                        WHERE COMPO_CD = 'SW'
                        AND   SUB_COMPO_CD = ' '
                        AND   ATTR_NM = 'OSVersion'
                        ) VER
WHERE SABUN.MDN_NM = CUST.MOBILE_SVC_NUM
AND CUST.DEVICE_MNG_NUM = DEL.DEVICE_MNG_NUM(+)
AND CUST.DEVICE_MNG_NUM = NAME.DEVICE_MNG_NUM(+)
AND CUST.DEVICE_MNG_NUM = VEN.DEVICE_MNG_NUM(+)
AND CUST.DEVICE_MNG_NUM = VER.DEVICE_MNG_NUM(+)
ORDER BY SABUN.USER_ID
    ;
-- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_UAP_WAP_FMI Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'DAILY_UAP_WAP_FMI_' || TO_CHAR(SYSDATE, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
             (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMI(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
        COMMIT;
    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
  --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
  -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
                        if fetch_cnt = 1000000 then
                            file_seq  := file_seq + 1;
                            fetch_cnt := 0;
                                utl_file.fclose(sam_data_filetype);
                                select 'DAILY_UAP_WAP_FMI_' || TO_CHAR(SYSDATE, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
                                into    sam_data_filename
                                from    dual ;
                                sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
                        end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMI(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMI(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMI(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMI(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
               (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMI(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
        COMMIT;
-- --------------------------------------------------------------------------
-- 작업완료 확인 파일생성
-- --------------------------------------------------------------------------
        SELECT NVL(COUNT(*),0) INTO log_cnt FROM GAEBAL_UPADM.TB_JOB_LOG
        WHERE TO_CHAR(RUN_DT, 'YYYYMMDD') = TO_CHAR(SYSDATE, 'YYYYMMDD')
        AND STATUS = 'E' AND PROGRAM LIKE '%DAILY_UAP_WAP_FMI%';
        --------
        -- 단말정보는 총 1개의 프로시져가 돌아감. 이상이 생겨 두번돌린다든지 할때에는수동으로 로그파일 생성할것.
        --------
    if log_cnt >= 1 then  -- 작업 완료 Log 남김
                select 'DAILY_UAP_WAP_FMI_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '_XX.log'
                into    sam_data_filename
                from    dual ;
            sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
            utl_file.put_line(sam_data_filetype, log_cnt);
            utl_file.fclose(sam_data_filetype);
    end if;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_UAP_WAP_FMI Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMI(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  || '] *****');
       WHEN DUP_VAL_ON_INDEX THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMI(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  || '] *****');
       WHEN TOO_MANY_ROWS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMI(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  || '] *****');
       WHEN OTHERS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_WAP_FMI(DAILY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
            DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  || '] *****');
       COMMIT;
END;
/








  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_ADDED_SVC_CD_REQ" (
	 I_Added_Svc_Cd IN TB_ADDED_SVC.ADDED_SVC_CD%TYPE
    ,I_Meta_Seq     IN NUMBER DEFAULT NULL
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_ADDED_SVC_CD
-- 기능 : 부가서비스 코드를 입력하면 CP에 내려줄 SAM파일을 추출함(초기화)
--        SAM 파일생성(TB_CUST_ADDED_SVC, TB_CUST_PROF)
--        format --> 부가서비스코드;서비스관리번호;MIN;MDN;CHANGE_MDN;COIS변경시간;처리자
-- 변경력: 신규 (2005.06.09) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq            NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    v_Exist_cnt         NUMBER ;
    v_added_svc_cd  TB_ADDED_SVC.ADDED_SVC_CD%TYPE := I_Added_Svc_Cd ;
-- --------------------------
CURSOR cur_get_data IS
    -- 부가서비스 테이블에 있다하더라도 고객정보 테이블에 존재하지 않는 데이터는
    -- 인정하지 못함으로 아래 쿼리 사용가능(outer join무의미)
	SELECT        ADDED.ADDED_SVC_CD
        || ';' || CUST.SVC_MNG_NUM
        || ';' || CUST.MOBILE_ID_NUM
        || ';' || DECODE( LENGTH(CUST.MOBILE_SVC_NUM), 10, SUBSTR(CUST.MOBILE_SVC_NUM, 1,3) || '0' || SUBSTR(CUST.MOBILE_SVC_NUM, 4),
                                                           CUST.MOBILE_SVC_NUM )
        || ';' || PLUS.PREV_MOBILE_SVC_NUM
        || ';' || ADDED.COIS_UPDATE_DT
        || ';' || NVL(TRIM(ADDED.REG_PATH),'NONE' ) AS GET_DATA
	FROM
	    (SELECT SVC_MNG_NUM
		    , ADDED_SVC_CD
		    , TO_CHAR(COIS_UPDATE_DT,'YYYYMMDDHH24MISS')AS COIS_UPDATE_DT
		    , REG_PATH
		FROM TB_CUST_ADDED_SVC
		WHERE ADDED_SVC_CD = v_added_svc_cd
	    ) ADDED,
	    TB_CUST_PROF CUST,
	    TB_CHG_PLUS PLUS
	WHERE ADDED.SVC_MNG_NUM = CUST.SVC_MNG_NUM
	     AND ADDED.SVC_MNG_NUM = PLUS.SVC_MNG_NUM (+)
	;


    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_ADDED_SVC_CD Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'META_' || v_added_svc_cd || '_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'META_' || v_added_svc_cd || '_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;

    -- 처리 완료 로그 기록 여부
    IF ( I_Meta_Seq IS NULL ) THEN
        DBMS_OUTPUT.PUT_LINE( '***** [ DB No Writing ] *****');
    ELSE
        -- 존재 여부 조회
        SELECT COUNT(*) INTO v_Exist_cnt
        FROM TB_META_BUF
        WHERE META_SEQ = I_Meta_Seq ;

        IF ( v_Exist_cnt = 0 ) THEN
            DBMS_OUTPUT.PUT_LINE( '***** [ DB Not Found ] *****');
        ELSE
            UPDATE TB_META_BUF
            SET FILE_CNT = file_seq
               ,META_CNT = write_cnt
               ,FILE_NM  = 'META_' || v_added_svc_cd || '_' || TO_CHAR(SYSDATE, 'YYYYMM')
            WHERE META_SEQ = I_Meta_Seq ;

            DBMS_OUTPUT.PUT_LINE( '***** [ DB Log Update Success ] *****');
        END IF ;
    END IF ;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'E', SYSDATE, read_cnt,write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_ADDED_SVC_CD Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_CD(INIT)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."ADD_PARTITIONS"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : add_partitions
-- 기능 : IFS쪽에서 사용하는 테이블에 대한 Table영역(Partition)을 생성하고 삭제
--        이것이 호출 되지 않았을경우에는 저장영영에러가 발생하여 IFS가 정상 업무
--        진행 할 수 없다.
-- 변경력: 신규 (2003.10.09) - complues -
--       : 추가 (2003.12.28) 기존 파티션만 생성해주는 것에서 기존 파티션을 삭제하는 로직 추가
--                           생성과 삭제를 같이 해줌으로 서로 어긋나게 실행 되어 발생하는 장애 제거
--                           - complues -
--       : 추가 (2004.10.27) 고도화1차 개발에서 사용하는 History 테이블의 파티션 추가삭제 로직 추가
--                           - complues -
--       : 추가 (2005.03.11) 고도화1차 개발에서 사용하는 History 테이블의 파티션 삭제 날짜 변경 15일로
--                           - complues -
--       : 추가 (2005.11.11) LDAP 개발에서 사용하는 PMH간 Log 테이블 삭제
--                           - complues -
-- -----------------------------------------------------------------------------

	sql_stmt    VARCHAR2(200);
	YYYYMMDD    VARCHAR2(8);
	YYYYMM      VARCHAR2(6);
	YYYY	    integer;
	RANGE_YEAR  integer;
	RANGE_DATE  VARCHAR2(8);
	FUTURE_ROOM integer;
	BACK_ROOM integer;

BEGIN

    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
        (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'ADD_PARTITIONS', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

	-----------------------------------
	----- TB_MSG_QUEUE ADD Partition
	-----------------------------------
/*	LOOP
		SELECT TO_CHAR(TO_DATE(MAX(SUBSTR(PARTITION_NAME,14,8)),'YYYYMMDD')+1,'YYYYMMDD')
			INTO YYYYMMDD
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_MSG_QUEUE';

		SELECT TO_CHAR(TO_DATE(MAX(SUBSTR(PARTITION_NAME,14,8)),'YYYYMMDD')+2,'YYYYMMDD')
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_MSG_QUEUE';

		FUTURE_ROOM := TO_DATE(YYYYMMDD,'YYYYMMDD') - TRUNC(SYSDATE);

		-- 만들어져 있는것이 일주일전까지 만들어 져 있는가 를 확인
		IF FUTURE_ROOM > 1 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_MSG_QUEUE ADD PARTITION TB_MSG_QUEUE_'||YYYYMMDD||
					'  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;
*/
	-----------------------------------
	----- TB_MSG_QUEUE DROP Partition
	-----------------------------------
/*	LOOP

		SELECT TO_CHAR(TO_DATE(MIN(SUBSTR(PARTITION_NAME,14,8)),'YYYYMMDD'),'YYYYMMDD')
			INTO YYYYMMDD
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_MSG_QUEUE';

		BACK_ROOM := TO_DATE(YYYYMMDD,'YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 4일전 전인가를 확인
		IF BACK_ROOM > -1 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_MSG_QUEUE DROP PARTITION TB_MSG_QUEUE_'||YYYYMMDD ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;
*/
	-----------------------------------
	----- TB_PROC_TRANS_HIST ADD Partition(고도화팀 추가 2004-10-27 시작)
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(MAX(SUBSTR(PARTITION_NAME,20,8)),'YYYYMMDD')+1,'YYYYMMDD')
			INTO YYYYMMDD
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_PROC_TRANS_HIST';

		SELECT TO_CHAR(TO_DATE(MAX(SUBSTR(PARTITION_NAME,20,8)),'YYYYMMDD')+2,'YYYYMMDD')
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_PROC_TRANS_HIST';

		FUTURE_ROOM := TO_DATE(YYYYMMDD,'YYYYMMDD') - TRUNC(SYSDATE);
		-- 만들어져 있는것이 일주일전까지 만들어 져 있는가 를 확인
		IF FUTURE_ROOM > 3 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_PROC_TRANS_HIST ADD PARTITION TB_PROC_TRANS_HIST_'||YYYYMMDD||
		           '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_PROC_TRANS_HIST DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(MIN(SUBSTR(PARTITION_NAME,20,8)),'YYYYMMDD'),'YYYYMMDD')
			INTO YYYYMMDD
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_PROC_TRANS_HIST';

		BACK_ROOM := TO_DATE(YYYYMMDD,'YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 15일전 전인가를 확인
		IF BACK_ROOM > -15 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_PROC_TRANS_HIST DROP PARTITION TB_PROC_TRANS_HIST_'||YYYYMMDD ;
		--dbms_output.put_line('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;
	-- (고도화팀 추가 2004-10-27 끝 )

	-- (LDAP팀 추가 2005-11-11 시작 )
	-----------------------------------
	----- TB_PMH_IFS_LOG ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(MAX(SUBSTR(PARTITION_NAME,16,8)),'YYYYMMDD')+1,'YYYYMMDD')
			INTO YYYYMMDD
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_PMH_IFS_LOG';

		SELECT TO_CHAR(TO_DATE(MAX(SUBSTR(PARTITION_NAME,16,8)),'YYYYMMDD')+2,'YYYYMMDD')
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_PMH_IFS_LOG';

		FUTURE_ROOM := TO_DATE(YYYYMMDD,'YYYYMMDD') - TRUNC(SYSDATE);
		-- 만들어져 있는것이 일주일전까지 만들어 져 있는가 를 확인
		IF FUTURE_ROOM > 3 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_PMH_IFS_LOG ADD PARTITION TB_PMH_IFS_LOG_'||YYYYMMDD||
		           '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_PMH_IFS_LOG DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(MIN(SUBSTR(PARTITION_NAME,16,8)),'YYYYMMDD'),'YYYYMMDD')
			INTO YYYYMMDD
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_PMH_IFS_LOG';

		BACK_ROOM := TO_DATE(YYYYMMDD,'YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 15일전 전인가를 확인
		IF BACK_ROOM > -15 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_PMH_IFS_LOG DROP PARTITION TB_PMH_IFS_LOG_'||YYYYMMDD ;
		--dbms_output.put_line('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;
	-- (LDAP팀 추가 2005-11-11 끝 )

	-----------------------------------
	----- TB_MSG_QUEUE ADD Partition
	-----------------------------------
/*	LOOP
		SELECT TO_CHAR(TO_DATE(MAX(SUBSTR(PARTITION_NAME,14,8)),'YYYYMMDD')+1,'YYYYMMDD')
			INTO YYYYMMDD
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_MSG_QUEUE';

		SELECT TO_CHAR(TO_DATE(MAX(SUBSTR(PARTITION_NAME,14,8)),'YYYYMMDD')+2,'YYYYMMDD')
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_MSG_QUEUE';

		FUTURE_ROOM := TO_DATE(YYYYMMDD,'YYYYMMDD') - TRUNC(SYSDATE);

		-- 만들어져 있는것이 일주일전까지 만들어 져 있는가 를 확인
		IF FUTURE_ROOM > 7 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_MSG_QUEUE ADD PARTITION TB_MSG_QUEUE_'||YYYYMMDD||
					'  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_MSG_QUEUE DROP Partition
	-----------------------------------
	LOOP

		SELECT TO_CHAR(TO_DATE(MIN(SUBSTR(PARTITION_NAME,14,8)),'YYYYMMDD'),'YYYYMMDD')
			INTO YYYYMMDD
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_MSG_QUEUE';

		BACK_ROOM := TO_DATE(YYYYMMDD,'YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 4일전 전인가를 확인
		IF BACK_ROOM > -4 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_MSG_QUEUE DROP PARTITION TB_MSG_QUEUE_'||YYYYMMDD ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CDS_LOG ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,12,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CDS_LOG';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,12,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CDS_LOG';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CDS_LOG ADD PARTITION TB_CDS_LOG_'||YYYYMM||
		           '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CDS_LOG DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),12,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CDS_LOG';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 3달 전인가를 확인
		IF BACK_ROOM > -93 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CDS_LOG DROP PARTITION TB_CDS_LOG_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;
*/


	-----------------------------------
	----- TB_CDS_IFS_ERR ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CDS_IFS_ERR';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CDS_IFS_ERR';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CDS_IFS_ERR ADD PARTITION PT_'||YYYYMM||
		           '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CDS_IFS_ERR DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CDS_IFS_ERR';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 1년 전인가를 확인
		IF BACK_ROOM > - 365 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CDS_IFS_ERR DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

/*	LOOP
		SELECT MAX(SUBSTR(PARTITION_NAME,4,4))+1
			INTO YYYY
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CDS_IFS_ERR';

		SELECT MAX(SUBSTR(PARTITION_NAME,4,4))+2
			INTO RANGE_YEAR
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CDS_IFS_ERR';

		FUTURE_ROOM := TO_DATE(YYYY||'0101','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 1년 전인가를 확인
		IF FUTURE_ROOM > 365 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CDS_IFS_ERR ADD PARTITION PT_'||YYYY||
		          '  VALUES LESS THAN ('''||RANGE_YEAR||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CDS_IFS_ERR DROP Partition
	-----------------------------------
	LOOP
		SELECT MIN(SUBSTR(PARTITION_NAME,4,4))
			INTO YYYY
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CDS_IFS_ERR';

		BACK_ROOM := TO_DATE(YYYY||'0101','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 1년 전인가를 확인
		IF BACK_ROOM > - 365 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CDS_IFS_ERR DROP PARTITION PT_'||YYYY;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;
*/
---------------------------  PROFILE SERVER 관련 추가 항목 ---------------------------------------------
	-----------------------------------
	----- TB_CP_SERVICE_INFO ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_SERVICE_INFO';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_SERVICE_INFO';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_SERVICE_INFO ADD PARTITION PT_'||YYYYMM||
		           '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CP_SERVICE_INFO DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_SERVICE_INFO';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 180일 전인가를 확인
		IF BACK_ROOM > - 180 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_SERVICE_INFO DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CP_ERR_INFO ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_ERR_INFO';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_ERR_INFO';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_ERR_INFO ADD PARTITION PT_'||YYYYMM||
                    '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CP_ERR_INFO DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_ERR_INFO';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 120일 전인가를 확인
		IF BACK_ROOM > - 120 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_ERR_INFO DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;


	-----------------------------------
	----- TB_CP_LDAP_CONN_HIST ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_LDAP_CONN_HIST';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_LDAP_CONN_HIST';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_LDAP_CONN_HIST ADD PARTITION PT_'||YYYYMM||
		           '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CP_LDAP_CONN_HIST DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_LDAP_CONN_HIST';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 1년 전인가를 확인
		IF BACK_ROOM > - 365 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_LDAP_CONN_HIST DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_ADULT_SERVICE_LOG ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_ADULT_SERVICE_LOG';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_ADULT_SERVICE_LOG';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_ADULT_SERVICE_LOG ADD PARTITION PT_'||YYYYMM||
		          '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_ADULT_SERVICE_LOG DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_ADULT_SERVICE_LOG';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 6개월 전인가를 확인
		IF BACK_ROOM > - 186 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_ADULT_SERVICE_LOG DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CUST_PROF_GLR_HIST ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_PROF_GLR_HIST';


		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_PROF_GLR_HIST';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CUST_PROF_GLR_HIST ADD PARTITION PT_'||YYYYMM||
		          '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CUST_PROF_GLR_HIST DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_PROF_GLR_HIST';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 6개월 전인가를 확인
		IF BACK_ROOM > - 186 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CUST_PROF_GLR_HIST DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CP_SVC_SUM ADD Partition
	-----------------------------------
	LOOP
		SELECT MAX(SUBSTR(PARTITION_NAME,4,4))+1
			INTO YYYY
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_SVC_SUM';

		SELECT MAX(SUBSTR(PARTITION_NAME,4,4))+2
			INTO RANGE_YEAR
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_SVC_SUM';

		FUTURE_ROOM := TO_DATE(YYYY||'0101','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 1년 전인가를 확인
		IF FUTURE_ROOM > 365 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_SVC_SUM ADD PARTITION PT_'||YYYY||
		          '  VALUES LESS THAN ('''||RANGE_YEAR||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CP_SVC_SUM DROP Partition
	-----------------------------------
	LOOP
		SELECT MIN(SUBSTR(PARTITION_NAME,4,4))
			INTO YYYY
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_SVC_SUM';

		BACK_ROOM := TO_DATE(YYYY||'0101','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 2년 전인가를 확인
		IF BACK_ROOM > - 730 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_SVC_SUM DROP PARTITION PT_'||YYYY ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CP_IF_SUM ADD Partition
	-----------------------------------
	LOOP
		SELECT MAX(SUBSTR(PARTITION_NAME,4,4))+1
			INTO YYYY
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_IF_SUM';

		SELECT MAX(SUBSTR(PARTITION_NAME,4,4))+2
			INTO RANGE_YEAR
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_IF_SUM';

		FUTURE_ROOM := TO_DATE(YYYY||'0101','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 1년 전인가를 확인
		IF FUTURE_ROOM > 365 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_IF_SUM ADD PARTITION PT_'||YYYY||
		           '  VALUES LESS THAN ('''||RANGE_YEAR||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CP_IF_SUM DROP Partition
	-----------------------------------
	LOOP
		SELECT MIN(SUBSTR(PARTITION_NAME,4,4))
			INTO YYYY
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_IF_SUM';

		BACK_ROOM := TO_DATE(YYYY||'0101','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 2년 전인가를 확인
		IF BACK_ROOM > - 730 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_IF_SUM DROP PARTITION PT_'||YYYY ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CP_ERR_SUM ADD Partition
	-----------------------------------
	LOOP
		SELECT MAX(SUBSTR(PARTITION_NAME,4,4))+1
			INTO YYYY
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_ERR_SUM';

		SELECT MAX(SUBSTR(PARTITION_NAME,4,4))+2
			INTO RANGE_YEAR
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_ERR_SUM';

		FUTURE_ROOM := TO_DATE(YYYY||'0101','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 1년 전인가를 확인
		IF FUTURE_ROOM > 365 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_ERR_SUM ADD PARTITION PT_'||YYYY||
		           '  VALUES LESS THAN ('''||RANGE_YEAR||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CP_ERR_SUM DROP Partition
	-----------------------------------
	LOOP
		SELECT MIN(SUBSTR(PARTITION_NAME,4,4))
			INTO YYYY
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CP_ERR_SUM';

		BACK_ROOM := TO_DATE(YYYY||'0101','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 2년 전인가를 확인
		IF BACK_ROOM > - 730 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CP_ERR_SUM DROP PARTITION PT_'||YYYY ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_GLR_IFS_ERR ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_GLR_IFS_ERR';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_GLR_IFS_ERR';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_GLR_IFS_ERR ADD PARTITION PT_'||YYYYMM||
		          '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_GLR_IFS_ERR DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_GLR_IFS_ERR';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 3개월 전인가를 확인
		IF BACK_ROOM > - 93 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_GLR_IFS_ERR DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_IFS_REQ_SUM ADD Partition
	-----------------------------------
	LOOP
		SELECT MAX(SUBSTR(PARTITION_NAME,4,4))+1
			INTO YYYY
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_IFS_REQ_SUM';

		SELECT MAX(SUBSTR(PARTITION_NAME,4,4))+2
			INTO RANGE_YEAR
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_IFS_REQ_SUM';

		FUTURE_ROOM := TO_DATE(YYYY||'0101','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 1년 전인가를 확인
		IF FUTURE_ROOM > 365 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_IFS_REQ_SUM ADD PARTITION PT_'||YYYY||
		          '  VALUES LESS THAN ('''||RANGE_YEAR||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_IFS_REQ_SUM DROP Partition
	-----------------------------------
	LOOP
		SELECT MIN(SUBSTR(PARTITION_NAME,4,4))
			INTO YYYY
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_IFS_REQ_SUM';

		BACK_ROOM := TO_DATE(YYYY||'0101','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 2년 전인가를 확인
		IF BACK_ROOM > - 730 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_IFS_REQ_SUM DROP PARTITION PT_'||YYYY;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CUST_PROF_HIST ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_PROF_HIST';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_PROF_HIST';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CUST_PROF_HIST ADD PARTITION PT_'||YYYYMM||
		          '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
--		          '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CUST_PROF_HIST DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_PROF_HIST';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 1년 전인가를 확인
		IF BACK_ROOM > - 365 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CUST_PROF_HIST DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CUST_ADDED_SVC_HIST ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_ADDED_SVC_HIST';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_ADDED_SVC_HIST';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CUST_ADDED_SVC_HIST ADD PARTITION PT_'||YYYYMM||
		          '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
--		          '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CUST_ADDED_SVC_HIST DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_ADDED_SVC_HIST';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 1년 전인가를 확인
		IF BACK_ROOM > - 365 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CUST_ADDED_SVC_HIST DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_LIMIT_HIST ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_LIMIT_HIST';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_LIMIT_HIST';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_LIMIT_HIST ADD PARTITION PT_'||YYYYMM||
		          '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
--		          '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_LIMIT_HIST DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_LIMIT_HIST';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 6개월 전인가를 확인
		IF BACK_ROOM > - 186 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_LIMIT_HIST DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CHG_PLUS_HIST ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CHG_PLUS_HIST';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CHG_PLUS_HIST';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CHG_PLUS_HIST ADD PARTITION PT_'||YYYYMM||
		          '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
--		          '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CHG_PLUS_HIST DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CHG_PLUS_HIST';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 6개월 전인가를 확인
		IF BACK_ROOM > - 186 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CHG_PLUS_HIST DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CUST_CHILD_HIST ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_CHILD_HIST';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_CHILD_HIST';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CUST_CHILD_HIST ADD PARTITION PT_'||YYYYMM||
		          '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
--		          '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CUST_CHILD_HIST DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_CHILD_HIST';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 6개월 전인가를 확인
		IF BACK_ROOM > - 186 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CUST_CHILD_HIST DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CUST_UAP_MW_BUF_HIST ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_UAP_MW_BUF_HIST';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_UAP_MW_BUF_HIST';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CUST_UAP_MW_BUF_HIST ADD PARTITION PT_'||YYYYMM||
		          '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
--		          '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_CUST_UAP_MW_BUF_HIST DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_CUST_UAP_MW_BUF_HIST';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 3개월 전인가를 확인
		IF BACK_ROOM > - 93 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_CUST_UAP_MW_BUF_HIST DROP PARTITION PT_'||YYYYMM ;

		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_OPMD_HIST ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_OPMD_HIST';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_OPMD_HIST';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_OPMD_HIST ADD PARTITION PT_'||YYYYMM||
		          '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
--		          '  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_OPMD_HIST DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_OPMD_HIST';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 3개월 전인가를 확인
		IF BACK_ROOM > - 93 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_OPMD_HIST DROP PARTITION PT_'||YYYYMM ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_MULTI_NUM_HIST ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),1),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_MULTI_NUM_HIST';

		SELECT TO_CHAR(ADD_MONTHS(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,6)),'YYYYMM'),2),'YYYYMM')||'01'
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_MULTI_NUM_HIST';

		FUTURE_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 한달 전인가를 확인
		IF FUTURE_ROOM > 31 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_MULTI_NUM_HIST ADD PARTITION PT_'||YYYYMM||
		          '  VALUES LESS THAN (TO_DATE('''||RANGE_DATE||''',''YYYYMMDD''))';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_MULTI_NUM_HIST DROP Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(SUBSTR(MIN(PARTITION_NAME),4,6),'YYYYMM'),'YYYYMM')
			INTO YYYYMM
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_MULTI_NUM_HIST';

		BACK_ROOM := TO_DATE(YYYYMM||'01','YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 1년 전인가를 확인
		IF BACK_ROOM > - 365 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_MULTI_NUM_HIST DROP PARTITION PT_'||YYYYMM ;
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_JOB_LOG DELETE
	-----------------------------------
	DELETE FROM TB_JOB_LOG WHERE  RUN_DT < sysdate - 90;
	commit;
	--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );

	-----------------------------------
	----- TB_WAP_LOG_ERR DELETE
	-----------------------------------
	DELETE FROM TB_WAP_LOG_ERR WHERE PROC_DT < TO_CHAR(sysdate-90,'YYYYMMDD');
	commit;
	--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );

    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
        (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'ADD_PARTITIONS', 'E', SYSDATE, 0, 0, 0) ;
    COMMIT;

END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_MIG_LDAP_CHILD_NUM"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_MIG_LDAP_CHILD_NUM
-- History: (2005.11.04) - complues -
--          자번호 추가 및 실제 DATA Set
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;

-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

CURSOR cur_get_data IS
    SELECT            SVC_MNG_NUM
		|| '|' || NVL(CHILD_MOBILE_SVC_NUM      , '' ) AS GET_DATA
	FROM TB_CUST_CHILD
        ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_MIG_LDAP_CHILD_NUM Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'ua_custchild.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w', 32767 );
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  DATA Count
        read_cnt := read_cnt + 1;
        utl_file.put_line(sam_data_filetype, c1.GET_DATA );
        write_cnt := write_cnt + 1;

    EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  DBMS_OUTPUT.PUT_LINE( '***** WRITE [' || SQLERRM || '] *****');
		WHEN DUP_VAL_ON_INDEX THEN
		  DBMS_OUTPUT.PUT_LINE( '***** WRITE [' || SQLERRM || '] *****');
		WHEN TOO_MANY_ROWS THEN
		  DBMS_OUTPUT.PUT_LINE( '***** WRITE [' || SQLERRM || '] *****');
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE( '***** WRITE [' || SQLERRM || '] *****');
			COMMIT;
    END;
    END LOOP Process_Loop ;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================

-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_MIG_LDAP_CHILD_NUM Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
	WHEN NO_DATA_FOUND THEN
	   DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN DUP_VAL_ON_INDEX THEN
	   DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN TOO_MANY_ROWS THEN
	   DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
		COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_URI_REF"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_URI_REF
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE

-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

CURSOR cur_get_data IS
	SELECT         NVL(COMPO_CD, '')
		 || '|' || NVL(TRIM(SUB_COMPO_CD), ' ')
         || '|' || NVL(ATTR_NM, '')
         || '|' || NVL(URI_SEQ, '')
         || '|' || NVL(URI_TP, '')
         AS GET_DATA
	 FROM TB_URI_REF
     ORDER BY URI_SEQ ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_URI_REF Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_uri_ref.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	    COMMIT;
        END;
    END LOOP Process_Loop;
	<< end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_URI_REF Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_CODE_GRANT"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_CODE_GRANT
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

-- -- -----------------------------------------------------------------------------
-- -- Cursor
-- -- -----------------------------------------------------------------------------
CURSOR cur_get_data IS
	SELECT        NVL(GRANT_CD   , '' )
		|| '|' || NVL(GRANT_NM   , '' )
		|| '|' || NVL(GRANT_DSC  , '' )
         AS GET_DATA
	 FROM TB_GRANT
     ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_CODE_GRANT Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_code_grant.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA );
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
  	    COMMIT;
        END;
    END LOOP Process_Loop;
    << end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_CODE_GRANT Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN DUP_VAL_ON_INDEX THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN TOO_MANY_ROWS THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN OTHERS THEN
	     error_cnt := error_cnt + 1;
	     DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_TB_COMPO" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_TB_COMPO
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 일일 대사를 위해
--        SAM 파일생성(TB_COMPO)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   CURSOR DEFINE  ( 52자리)
------------------------------
--   COMPO_CD           ( 2)
--   COMPO_NM           (50)
-- --------------------------
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(COMPO_NM, '') AS GET_DATA
	FROM TB_COMPO ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_COMPO Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_tb_compo_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES ( SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_COMPO(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'daily_tb_compo_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_COMPO(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_COMPO Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_COMPO(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_LDAP_CUST_ADDED_SVC" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_LDAP_CUST_ADDED_SVC
-- 기능 : UAProfiel DB와 LDAP간의 정보를 확인 하기 위한 처리로 고객정보 Sync를 위한
--        일일대사용 SAM 파일 생성
--
-- 변경력: 신규 (2005.11.14) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   각 컬럼 구분자는 콤마(,)
--   또한 아무값도 없을때에는 Space 한자리로 할까? 어？까?(일단 sync프로그램 짜보고 -_-; 힘들다)
------------------------------
-- --------------------------
CURSOR cur_get_data IS
    SELECT        SVC_MNG_NUM
		|| '|' || NVL(ADDED_SVC_CD    , ' ' )
		|| '|' || NVL(REG_CD          , ' ' )
		|| '|' || NVL(TRIM(EXEC_ID)   , ' ' )
		|| '|' || NVL(TO_CHAR(REG_DT, 'YYYYMMDDHH24MISS'), ' ')
		|| '|' || NVL(TRIM(REG_PATH)  , ' ' )
		|| '|' || NVL(TO_CHAR(COIS_UPDATE_DT, 'YYYYMMDDHH24MISS'), ' ')
    AS GET_DATA
    FROM TB_CUST_ADDED_SVC
    WHERE  REG_DT >= TRUNC( I_Work_dt - 1) -- ONE DAY DATA
    AND    REG_DT <  TRUNC( I_Work_dt )
    ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_LDAP_CUST_ADDED_SVC Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_ldap_cust_added_svc_' || TO_CHAR(I_Work_dt, 'YYYYMMDD') || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_ADDED_SVC(DAILY)', 'S', SYSDATE, 0, 0, 0) ;

    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;

-- 따로 파일명 구분하지 말자~
--             fetch_cnt := fetch_cnt + 1;
-- --  백만건 단위로 file name에 seq를 붙여서 만듬.... --
-- 			if fetch_cnt = 1000000 then
-- 			    file_seq  := file_seq + 1;
-- 			    fetch_cnt := 0;
-- 				utl_file.fclose(sam_data_filetype);
-- 				select 'daily_ldap_cust_added_svc_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
-- 				into    sam_data_filename
-- 				from    dual ;
-- 				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- 			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_ADDED_SVC(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_ADDED_SVC(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_ADDED_SVC(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_ADDED_SVC(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_ADDED_SVC(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_LDAP_CUST_ADDED_SVC Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_ADDED_SVC(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_ADDED_SVC(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_ADDED_SVC(DAILY)', 'D', SYSDATE, substr(err_code,1,300)) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_ADDED_SVC(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_UAP_TO_CUST" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : daily_uap_to_cust.
-- 기능 : UAProfile의 단말정보를 SAM파일로 만들어 CUSTDB쪽에 넘겨줌으로써 UAPIS조회시
--        발생되는 에러요인을 없애고 매일 단말정보를 만들어 낸다.
--        UAPIS에서의 에러가 없어지면 그땐 이 프로시져의 수명을 다한다.
-- 변경력: 신규 (2003.12.30) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/appl'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    log_cnt     NUMBER := 0;
-- ---------------------------
--   CURSOR DEFINE  ( 45자리)
------------------------------
--   SVC_MNG_NUM         (10)
--   UPDATE_CD           ( 2)
--   MOBILE_SVC_NUM      (11)
--   COIS_DEVICE_CD      ( 4)
--   COIS_DEVICE_VER     ( 4)
--   UPDATE_DT           (14)
-- --------------------------
CURSOR cur_get_data IS
	select /*+ index(b) */
		 dev.device_mng_num
		|| '|' ||  nvl(m.attr_val,'')
		|| '|' ||  decode(dev.pda_yn,'Y','0',NULL,'0',decode(b.attr_val,NULL,'0','UP','9','http://mobileinternet.nate.com/rdf/service-name#CyberNet', '1','1.2','2','2'))
		|| '|' ||  nvl(dev.pda_yn,'N')
		|| '|' ||  decode(v.attr_val,NULL,'N','Y')
		|| '|' ||  nvl(substr(ltrim(g.attr_val,'player/vnd.skt.gnex;ver='),1,1),'0')
		|| '|' ||  decode(s.attr_val,NULL,'N','Y')
		|| '|' ||  nvl(replace(ltrim(w.attr_val,'application/x-witop;ver='),'.',''),'00') AS GET_DATA
	from tb_uap dev,
		(select device_mng_num, attr_val
		 from tb_uap_attr_list
		 where compo_cd = 'HW'
		 and sub_compo_cd = ' '
		 and attr_nm = 'Model'
		 and attr_val > ' ') m ,
		(select device_mng_num, attr_val
		 from tb_uap_attr_list
		 where compo_cd = 'SC'
		 and sub_compo_cd = ' '
		 and attr_nm = 'Supported-Services'
		 and attr_val = 'http://mobileinternet.nate.com/rdf/service-name#NateDrive') v,
		(select device_mng_num, attr_val
		 from tb_uap_attr_list
		 where compo_cd = 'SW'
		 and sub_compo_cd = ' '
		 and attr_nm = 'CcppAccept'
		 and attr_val like 'application/vnd.skt.skvm%') s,
		(select device_mng_num, attr_val
		 from tb_uap_attr_list
		 where compo_cd = 'SW'
		 and sub_compo_cd = ' '
		 and attr_nm = 'CcppAccept'
		 and attr_val like 'player/vnd.skt.gnex;ver=%') g,
		(select device_mng_num, attr_val
		 from tb_uap_attr_list
		 where compo_cd = 'SW'
		 and sub_compo_cd = ' '
		 and attr_nm = 'CcppAccept'
		 and attr_val like 'application/x-witop;ver=%') w,
		( 	-- WAP 단말이 아닌 리스트
         select /*+ index(tb_uap_attr_list) */ a.device_mng_num , a.attr_val
		 from tb_uap_attr_list a
		 where (    a.compo_cd = 'SC'
		 		and a.sub_compo_cd = ' '
		 		and a.attr_nm = 'Supported-Services'
		 		and a.attr_val = 'http://mobileinternet.nate.com/rdf/service-name#CyberNet' )
		    or (    a.compo_cd = 'BR'
		        and a.sub_compo_cd = ' '
		        and a.attr_nm = 'BrowserName'
		        and a.attr_val = 'UP' )
		 union
		 	-- WAP 단말인 리스트
		 select distinct a.device_mng_num ,a.attr_val
		 from tb_uap_attr_list a
		 where a.device_mng_num not in (
			 select /*+ index(tb_uap_attr_list) */ distinct device_mng_num
			 from tb_uap_attr_list
			 where (    compo_cd = 'SC'
			 		and sub_compo_cd = ' '
			 		and attr_nm = 'Supported-Services'
			 		and attr_val = 'http://mobileinternet.nate.com/rdf/service-name#CyberNet' )
			    or (    compo_cd = 'BR'
			        and sub_compo_cd = ' '
			        and attr_nm = 'BrowserName'
			        and attr_val = 'UP' )
			        )
		 and   a.compo_cd = 'WC'
	     and   a.sub_compo_cd = ' '
	     and   a.attr_nm = 'WmlScriptVersion'
	     and   a.attr_val = '1.2' ) b
	where dev.device_mng_num = m.device_mng_num (+)
	and   dev.device_mng_num = v.device_mng_num (+)
	and   dev.device_mng_num = s.device_mng_num (+)
	and   dev.device_mng_num = g.device_mng_num (+)
	and   dev.device_mng_num = w.device_mng_num (+)
	and   dev.device_mng_num = b.device_mng_num (+) ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_UAP_TO_CUST Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_uap_to_cust.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_TO_CUST(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_TO_CUST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_TO_CUST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_TO_CUST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_TO_CUST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_TO_CUST(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_UAP_TO_CUST END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_TO_CUST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_TO_CUST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_TO_CUST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_UAP_TO_CUST(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_ERR_FILTER"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : SP_ERR_FILTER
-- 기능 : 불법단말 용의 단말 리스트를 모두 추출한 후 그 타입에서 실제 용의가 높은
--        고객정보만을 출력한다.
--
-- 변경력: 2004. 05. 13
--         1. 신규 생성 - compleus -
-- -----------------------------------------------------------------------------
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/cust'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    fetch_cnt           NUMBER := 0 ;   -- 파일을 자르기위한 작업건수
    write_cnt           NUMBER := 0 ;   -- 총 write 작업건수
    read_cnt            NUMBER := 0 ;   -- 총 read 작업건수

    v_auth_read_cnt     NUMBER := 0 ;   -- 이전고객가입이력에서 읽은 건수
    v_auth_in_cnt       NUMBER := 0 ;   -- 고객가입이력에 삽인된 건수
    v_auth_del_cnt      NUMBER := 0 ;   -- 이전고객가입이력에서 삭제된 건수
    v_auth_skip_cnt     NUMBER := 0 ;   -- PK 중복발생으로 Skip된 건수

    ERR_MSG             VARCHAR2(150) ;
-- -----------------------------------------------------------------------------
-- 단수 참조에서 사용되는 변수
-- -----------------------------------------------------------------------------
    v_Base_Svc_Mng_Num  VARCHAR2(11) ;

    v_Modify_Cnt        NUMBER := 0;
    v_temp_cnt          NUMBER ;
    v_RecCnt            NUMBER ;
    v_Modify_limit      NUMBER := 3 ;    -- 변경횟수 이상인 건에 대한 추출
-- -----------------------------------------------------------------------------
-- 처리에 사용되 변수
-- -----------------------------------------------------------------------------
	v_Svc_Mng_Num        DBMS_SQL.Varchar2_Table    ;
	v_Start_Dt           DBMS_SQL.Date_Table        ;
	v_End_Dt             DBMS_SQL.Date_Table        ;
	v_Device_Mng_Num     DBMS_SQL.Varchar2_Table    ;
	v_Device_Mng_Dsc     DBMS_SQL.Varchar2_Table    ;
	v_Mobile_Id_Num      DBMS_SQL.Varchar2_Table    ;
	v_Mobile_Svc_Num     DBMS_SQL.Varchar2_Table    ;
	v_Exec_Id            DBMS_SQL.Varchar2_Table    ;
	v_Cois_Update_Dt     DBMS_SQL.Date_Table        ;
	v_Update_Cd          DBMS_SQL.Varchar2_Table    ;
	v_Update_Dt          DBMS_SQL.Date_Table        ;
	v_Update_Path        DBMS_SQL.Varchar2_Table    ;


    -- FETCH 할 변수
    N_CURSOR    INTEGER;
    N_RET       INTEGER;
    SQL_TEXT    VARCHAR2(2000);

    fetch_size          NUMBER := 1000 ;
    indx                NUMBER := 1 ;
-------------------
-- 전체 서비스관리번호중에서서 추출함
-------------------
CURSOR cur_get_data1 IS
	SELECT DISTINCT SVC_MNG_NUM
	FROM GAEBAL_UPADM.TB_CUST_HIST_BOOL ;
	-- 10개만 우선 테스트

BEGIN
	ERR_MSG := '최초 SP_ERR_FILTER 실행' ;

	DBMS_OUTPUT.ENABLE ( 1000000);
	DBMS_OUTPUT.PUT_LINE( '***** [ SP_ERR_FILTER Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');

	-- FILE OPEN
    select 'boolbeop_' || TO_CHAR(sysdate, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

    << Main_Process_Loop >>
    FOR C1 IN cur_get_data1 LOOP
    	ERR_MSG := '내부 Main_Process_Loop 작업 처리 '|| read_cnt ||'에서 에러 발생' ;

    	read_cnt   := read_cnt + 1 ;
        v_Base_Svc_Mng_Num := C1.svc_mng_num ;

    	BEGIN	-- 2
	        -- 에러메시지 셋팅
	        ERR_MSG := '내부 Internal_Cursor_Loop 작업 초기화에서 에러 발생' ;

	        -- 각각의 대상에 대한 추출
	        SQL_TEXT :=' SELECT * FROM TB_CUST_HIST_BOOL '
					|| ' WHERE SVC_MNG_NUM = ''' || v_Base_Svc_Mng_Num || ''''
					|| ' AND EXEC_ID NOT IN ( ''DUP_AUTO'', ''UAPIS'' , ''PRIME'' ) ' ;

			-- DBMS_OUTPUT.PUT_LINE( 'SQL [' || SQL_TEXT || ']');
	        -- ============
	        -- CURSOR 처리
	        -- ============
	        N_CURSOR := DBMS_SQL.OPEN_CURSOR;
	        DBMS_SQL.PARSE(N_CURSOR, SQL_TEXT, DBMS_SQL.NATIVE);

			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 1, v_Svc_Mng_Num    , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 2, v_Start_Dt       , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 3, v_End_Dt         , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 4, v_Device_Mng_Num , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 5, v_Device_Mng_Dsc , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 6, v_Mobile_Id_Num  , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 7, v_Mobile_Svc_Num , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 8, v_Exec_Id        , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 9, v_Cois_Update_Dt , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR,10, v_Update_Cd      , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR,11, v_Update_Dt      , fetch_size, indx );
			DBMS_SQL.DEFINE_ARRAY(N_CURSOR,12, v_Update_Path    , fetch_size, indx );

	        N_RET := DBMS_SQL.EXECUTE(N_CURSOR);


	        v_temp_cnt := 1 ;
	        << Internal_Cursor_Loop >>
	        LOOP
	            N_RET := DBMS_SQL.FETCH_ROWS(N_CURSOR);
	            --DBMS_OUTPUT.PUT_LINE(N_RET);
	            v_RecCnt := DBMS_SQL.LAST_ROW_COUNT ;
	            --DBMS_OUTPUT.PUT_LINE('FETCH_CNT [' || v_RecCnt || ']');

	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 1, v_Svc_Mng_Num     );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 2, v_Start_Dt        );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 3, v_End_Dt          );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 4, v_Device_Mng_Num  );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 5, v_Device_Mng_Dsc  );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 6, v_Mobile_Id_Num   );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 7, v_Mobile_Svc_Num  );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 8, v_Exec_Id         );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 9, v_Cois_Update_Dt  );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR,10, v_Update_Cd       );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR,11, v_Update_Dt       );
	            DBMS_SQL.COLUMN_VALUE(N_CURSOR,12, v_Update_Path     );

	            /*
	            DBMS_OUTPUT.PUT_LINE('v_RecCnt         [' || v_RecCnt                      || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Svc_Mng_Num    [' || v_Svc_Mng_Num(v_temp_cnt)     || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Start_Dt       [' || v_Start_Dt(v_temp_cnt)    || ']');
	            DBMS_OUTPUT.PUT_LINE('v_End_Dt         [' || v_End_Dt(v_temp_cnt)          || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Device_Mng_Num [' || v_Device_Mng_Num(v_temp_cnt)  || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Device_Mng_Dsc [' || v_Device_Mng_Dsc(v_temp_cnt)  || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Mobile_Id_Num  [' || v_Mobile_Id_Num(v_temp_cnt)   || ']');

	            DBMS_OUTPUT.PUT_LINE('v_Mobile_Svc_Num [' || v_Mobile_Svc_Num(v_temp_cnt)  || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Exec_Id        [' || v_Exec_Id(v_temp_cnt)         || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Cois_Update_Dt [' || v_Cois_Update_Dt(v_temp_cnt)  || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Update_Cd      [' || v_Update_Cd(v_temp_cnt)       || ']');
	            DBMS_OUTPUT.PUT_LINE('v_Update_Dt      [' || v_Update_Dt(v_temp_cnt)       ||']');
	            DBMS_OUTPUT.PUT_LINE('v_Update_Path    [' || v_Update_Path(v_temp_cnt)     || ']');
	            */

	            v_temp_cnt := v_temp_cnt + 1 ;

	            EXIT WHEN N_RET != fetch_size ;
	        END LOOP Internal_Cursor_Loop ;

	        IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
	            DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
	        END IF;

	    EXCEPTION
	        WHEN OTHERS THEN
	            IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
	                DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
	            END IF;

				RETURN;
	    END ;

		v_Modify_Cnt := 0 ;

	    << Process_Loop >>
	    FOR i IN 1..v_RecCnt LOOP
	    	BEGIN
	    		ERR_MSG := '내부 Process_Loop 작업 처리 For'|| i ||'에서 에러 발생' ;

				-- 비교을 위해 처음 데이터는 따로 처리하지 않는다.
				-- 만약! 혹시라도 한껀뿐인 데이터라면 무시하게 되어 상관은 없다.
				--DBMS_OUTPUT.PUT_LINE('v_RecCnt [' || v_RecCnt || ']');
				--DBMS_OUTPUT.PUT_LINE('      svc[' || v_Svc_Mng_Num(i) || '][' || read_cnt|| ']v_Device_Mng_Dsc [' || v_Device_Mng_Dsc(i) || '](' || i || ')' );

		        IF ( i <> 1 ) THEN
		        	-- 비교대상이 No_Model이 아닌것만 비교를 한다.
		        	-- DBMS_OUTPUT.PUT_LINE('      svc[' || v_Svc_Mng_Num(i) || '][' || v_Device_Mng_Dsc(i) || ']:[' || v_Device_Mng_Dsc(i-1) || ']' );
		        	IF ( v_Device_Mng_Dsc(i)   = 'No_Model' OR
		        	     v_Device_Mng_Dsc(i-1) = 'No_Model' ) THEN
		        		NULL ;
		        	ELSE
		        		-- 비교하되 현재의 EXEC_ID가 WAPGW2, BWAPLOG2 일때만 이전 데이터와 비교 한다.
		        		-- 이유는 모든 데이터와의 정확한 비교를 위해서 (안도영과장 요청 2004-09-03)
		        		IF ( ( v_Exec_Id(i) = 'WAPGW2'   ) OR ( v_Exec_Id(i) = 'BWAPLOG2' ) ) THEN
			        		IF ( v_Device_Mng_Dsc(i) <> v_Device_Mng_Dsc(i-1) ) THEN
			        			v_Modify_Cnt := v_Modify_Cnt + 1 ;
			        		END IF ;  -- 비교 IF
		        		END IF ;  -- 변경 IF
		        	END IF ;  -- Mo_model IF

					/*
			        DBMS_OUTPUT.PUT_LINE('-----------------------------------------------');
			        DBMS_OUTPUT.PUT_LINE('v_RecCnt         [' || v_RecCnt || ']/['   || i || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Svc_Mng_Num    [' || v_Svc_Mng_Num(i)    || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Start_Dt       [' || to_char(v_Start_Dt(i),'YYYYMMDDHH24MISS')  || ']');
			        DBMS_OUTPUT.PUT_LINE('v_End_Dt         [' || to_char(v_End_Dt(i),'YYYYMMDDHH24MISS')         || ']');

			        DBMS_OUTPUT.PUT_LINE('v_Device_Mng_Num [' || v_Device_Mng_Num(i) || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Device_Mng_Dsc [' || v_Device_Mng_Dsc(i) || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Mobile_Id_Num  [' || v_Mobile_Id_Num(i)  || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Mobile_Svc_Num [' || v_Mobile_Svc_Num(i) || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Exec_Id        [' || v_Exec_Id(i)        || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Cois_Update_Dt [' || to_char(v_Cois_Update_Dt(i),'YYYYMMDDHH24MISS') || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Update_Cd      [' || v_Update_Cd(i)      || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Update_Dt      [' || to_char(v_Update_Dt(i),'YYYYMMDDHH24MISS')      || ']');
			        DBMS_OUTPUT.PUT_LINE('v_Update_Path    [' || v_Update_Path(i)    || ']');
			        */

		        END IF;

				-- v_Modify_limit회 이상 변경 되었으면 File에 정보를 남기고 다음 데이터로 이동한다.
				IF ( v_Modify_Cnt >= v_Modify_limit ) THEN
			        BEGIN
			        	v_Modify_Cnt := 0 ;

				        ERR_MSG := '내부 Process_Loop 작업 처리 IF'|| i ||'에서 에러 발생' ;
					--  Data Write
						utl_file.put_line(sam_data_filetype, v_Base_Svc_Mng_Num );
					-- WRITE DATA 건수 Count
						write_cnt := write_cnt + 1;
						fetch_cnt := fetch_cnt + 1;

					--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
						IF fetch_cnt = 1000000 THEN
							file_seq  := file_seq + 1;
							fetch_cnt := 0;
							utl_file.fclose(sam_data_filetype);

							SELECT 'boolbeop_' || TO_CHAR(sysdate, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
							INTO    sam_data_filename
							FROM    dual ;
							sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
						END IF;

						-- Loop 해지 다음 서비스번호에 대한 처리
						GOTO Process_Loop_End ;

			        EXCEPTION
			            WHEN OTHERS THEN
							DBMS_OUTPUT.PUT_LINE( TRIM(ERR_MSG) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
			        END;
				END IF ;

		    EXCEPTION
		        WHEN OTHERS THEN
					DBMS_OUTPUT.PUT_LINE( TRIM(ERR_MSG) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
		    END ;

		END LOOP Process_Loop ;

		<< Process_Loop_End  >>
		NULL ;
	END LOOP Main_Process_Loop ;


    DBMS_OUTPUT.PUT_LINE( '***** [ 총 조회 대상 건수 ' || read_cnt    || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ 파일 기록 카운트  ' || write_cnt    || ' ] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ SP_ERR_FILTER Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') ||' ] *****');

-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE( TRIM(ERR_MSG) || ':[' || SUBSTR(SQLERRM,1,200) || ']');
		ROLLBACK ;

END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_ADDED_SVC_PERSON" (
	 I_Added_Svc_Cd IN CHAR
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_ADDED_SVC_PERSON
-- 기능 : 부가서비스 코드를 입력하면 CP에 내려줄 SAM파일(주민번호 포함)을 추출함(초기화)
--        format --> 부가서비스코드;서비스관리번호;MIN;MDN;COIS변경시간;처리자;주민번호6자리
-- 변경력: 신규 (2005.07.25) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    v_added_svc_cd      CHAR(5) := I_Added_Svc_Cd ;
-- --------------------------
CURSOR cur_get_data IS
    -- 부가서비스 테이블에 있다하더라도 고객정보 테이블에 존재하지 않는 데이터는

    -- 인정하지 못함으로 아래 쿼리 사용가능(outer join무의미)
	SELECT        ADDED.ADDED_SVC_CD
        || ';' || CUST.SVC_MNG_NUM
        || ';' || CUST.MOBILE_ID_NUM
        || ';' || DECODE( LENGTH(CUST.MOBILE_SVC_NUM), 10, SUBSTR(CUST.MOBILE_SVC_NUM, 1,3) || '0' || SUBSTR(CUST.MOBILE_SVC_NUM, 4),
                                                           CUST.MOBILE_SVC_NUM )
        || ';' || ADDED.COIS_UPDATE_DT
        || ';' || NVL(TRIM(ADDED.REG_PATH),'NONE' )
        || ';' || DECODE( LENGTH(PER.CUST_ID), 13 , SUBSTR(PER.CUST_ID, 1,6),  '' )
        AS GET_DATA
	FROM
	    (SELECT SVC_MNG_NUM
		    , ADDED_SVC_CD
		    , TO_CHAR(COIS_UPDATE_DT,'YYYYMMDDHH24MISS')AS COIS_UPDATE_DT
		    , REG_PATH
		FROM TB_CUST_ADDED_SVC
		WHERE ADDED_SVC_CD = v_added_svc_cd
	    ) ADDED,
	    TB_CUST_PROF CUST ,
        TB_CUST_PERSON PER
	WHERE ADDED.SVC_MNG_NUM = CUST.SVC_MNG_NUM
    AND   CUST.SVC_MNG_NUM = PER.SVC_MNG_NUM ;


    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_ADDED_SVC_PERSON Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'META_' || v_added_svc_cd || '_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_PERSON(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'META_' || v_added_svc_cd || '_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;


            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_PERSON(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_ADDED_SVC_PERSON Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_ADDED_SVC_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_CUST_PPG"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_CUST_PPG
-- 기능 : UAProfiel DB와 PPG 연동에서 초기화를 위한 SAM 파일생성(TB_CUST_PROF)
--        PPG 가능 단말만을 추출하여 초기화함
-- 변경력: 신규 (2003.12.16) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
/* 각각의 PPG임을 알기 위해 각 정보들을 초회하여 처리하되
   가장 많은 정보를 기준( 모든 PPG정보는 application/x-cmf 를 갖음)
   으로 하되 그기준을 i-Touch폰과 합하게 기준으로 잡는다.
   제약 조건으로는 i-Touch와 PPG폰은 서로 배타적인 관계여야 한다. */
CURSOR cur_get_data IS
	SELECT        SKT.SVC_MNG_NUM
	    || '|' || SKT.MOBILE_ID_NUM
	    || '|' || SKT.MOBILE_SVC_NUM
	    || '|' || SKT.NET_GEN_TP
	    || '|' || SKT.CLIENT_ID_YN
	    || '|' || SKT.CLIENT_ID_NET2G
	    || '|' || SKT.CLIENT_ID_NET3G
	    || '|' || SKT.CLIENT_ID_CUST
	    || '|' || SKT.IMSI
	    || '|' || DEV.PPG_SVC
	    || '|' || SKT.UPDATE_CD
	    || '|' || NVL(TO_CHAR(SKT.UPDATE_DT , 'YYYYMMDDHH24MISS'), NULL) AS GET_DATA
	FROM TB_CUST_PROF SKT ,
		(select  p3.device_mng_num
		       ,decode(
		             decode(p1.device_mng_num,null ,'0','1')
		           ||decode(p2.device_mng_num,null ,'0','1')
		           ||decode(p3.device_mng_num,null ,'0','1')
		           ||decode(p4.device_mng_num,null ,'0','1')
		           ||decode(p5.device_mng_num,null ,'0','1')
		           ||decode(p6.device_mng_num,null ,'0','1') , '111000', '1', '111100', '2', '001111', '3', '9' ) as PPG_SVC
		from
			(select device_mng_num, attr_val
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'text/vnd.wap.si' ) p1,
			(select device_mng_num, attr_val
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'application/vnd.wap.sic' ) p2,
			(select device_mng_num, attr_val, null
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'application/x-cmf'
			union
			select  p1.device_mng_num, null, '9'
			from
				(select device_mng_num, attr_val
				from tb_uap_attr_list
				where compo_cd = 'BR'
				and sub_compo_cd = ' '
				and attr_nm = 'BrowserName'
				and trim(attr_val) = 'UP' ) p1,
				(select device_mng_num, attr_val
				from tb_uap_attr_list
				where compo_cd = 'BR'
				and sub_compo_cd = ' '
				and attr_nm = 'BrowerVersion'
				and trim(attr_val) = '1.0' ) p2
			where p1.device_mng_num = p2.device_mng_num  ) p3,
			(select device_mng_num, attr_val
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'text/vnd.wap.wml'  ) p4,
			(select device_mng_num, attr_val
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'application/xhtml+xml'  ) p5,
			(select device_mng_num, attr_val
			from tb_uap_attr_list
			where compo_cd = 'PC'
			and sub_compo_cd = ' '
			and attr_nm = 'Push-Accept'
			and trim(attr_val) = 'application/vnd.wap.xhtml+xml'  ) p6
		where p3.device_mng_num = p1.device_mng_num(+)
		and   p3.device_mng_num = p2.device_mng_num(+)
		and   p3.device_mng_num = p4.device_mng_num(+)
		and   p3.device_mng_num = p5.device_mng_num(+)
		and   p3.device_mng_num = p6.device_mng_num(+) ) dev
	WHERE DEV.DEVICE_MNG_NUM = SKT.DEVICE_MNG_NUM ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_PPG Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DDHH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_cust_ppg_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PPG(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_cust_ppg_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PPG(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PPG(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PPG(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PPG(INIT)', 'D', substr(err_code,1,150) ) ;


   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PPG(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_PPG Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    ||' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PPG(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PPG(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PPG(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PPG(INIT)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_TB_UAP_ATTR_LIST"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_TB_UAP_ATTR_LIST
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 초기화를 위한
--        SAM 파일생성(TB_UAP_ATTR_LIST)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

CURSOR cur_get_data IS
	SELECT         NVL(DEVICE_MNG_NUM, '')
		 || '|' || NVL(COMPO_CD, '')
		 || '|' || NVL(SUB_COMPO_CD, '')
		 || '|' || NVL(ATTR_NM, '')
		 || '|' || NVL(ATTR_VAL,'') AS GET_DATA
	 FROM TB_UAP_ATTR_LIST ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_UAP_ATTR_LIST Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_tb_uap_attr_list_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00'))|| '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_LIST(INIT)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_tb_uap_attr_list_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_LIST(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_LIST(INIT)', 'D', SYSDATE, substr(err_code,1,300) );

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_LIST(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_LIST(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END LOOP Process_Loop;
	<< end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_LIST(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_TB_UAP_ATTR_LIST Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_LIST(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_LIST(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_LIST(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_TB_UAP_ATTR_LIST(INIT)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_CUST_PROF_IMS2"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : INIT_CUST_PROF_IMS
-- 기능 : UAProfiel DB와 다른 시스템(IMS) 연동에서 초기화를 위한
--        SAM 파일생성(TB_CUST_PROF, TB_CUST_PERSON )
-- 변경력: 신규 (2006.01.23) - complues -
-- 변경력: 변경 (2007.09.10) - black_vf -
-- 변경력: 테이블에서 직접 조회 하는 방식으로 변경 (2008.08.08) - smhongi
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
-- Format : 서비스관리번호|MDN|MIN|클라이언트아이디(16)|00|단말관리번호|고객유형|주민번호(7)
-- --------------------------

CURSOR cur_get_data IS
        -- MMS H/S Menu 에서 사용하는 것
        SELECT
                                  CUST.SVC_MNG_NUM
                || '|' || CUST.MOBILE_SVC_NUM
                || '|' || CUST.MOBILE_ID_NUM
                || '|' || NVL(CUST.CLIENT_ID_CUST, '')
                || '|' || '10'                 /* IMS User_Group Defalt */
                || '|' || CUST.DEVICE_MNG_NUM
                || '|' || DECODE( PER.CUST_TP, '01', DECODE(SUBSTR( PER.CUST_ID, 7, 1 ), '1'
, 'M'
                                                                                                  , '2', 'F'

             , '3', 'M'

  , '4', 'F'
                                                                                                  , '5', 'M
'
                                                                                                  , '6', 'F'

         , '7', 'M'
                                                                                                  ,
'8', 'F' ) /* 성별 */
                                                                                                  ,
'C' )          /* OTHERS --> "C" */
                || '|' || SUBSTR( PER.CUST_ID, 1, 7 )||'******'   /* 7자리만 나머지는 "*"로6자리*/ AS GET_DATA
        FROM  TB_CUST_PROF CUST
            , TB_CUST_PERSON PER
        WHERE CUST.SVC_MNG_NUM = PER.SVC_MNG_NUM ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_PROF_IMS Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_cust_ims2_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
             (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
        VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF_IMS(INIT)', 'S', SYSDATE, 0, 0, 0) ;
        COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --     READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
                        if fetch_cnt = 1000000 then
                            file_seq  := file_seq + 1;
                            fetch_cnt := 0;
                                utl_file.fclose(sam_data_filetype);
                                select 'init_cust_ims2_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
                                into    sam_data_filename
                                from    dual ;
                                sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
                        end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF_IMS(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF_IMS(INIT)', 'D', substr(err_code,1,150) ) ;


            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF_IMS(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF_IMS(INIT)', 'D', substr(err_code,1,150) ) ;

            COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
               (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
        VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF_IMS(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
        COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    -- 최종완료 로그파일 생성
    sam_data_filename := 'init_cust_ims2.log' ;

        sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename,'w');
        utl_file.put_line(sam_data_filetype, '***** [ WRITE COUNT  [' || write_cnt || '] *****');
        utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_CUST_PROF_IMS Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF_IMS(INIT)', 'D',substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF_IMS(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF_IMS(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_CUST_PROF_IMS(INIT)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_ADDED"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_ADDED
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;

    v_all_added_svc     VARCHAR2(4000) ;
    v_added_svc_cd      TB_ADDED_SVC.ADDED_SVC_CD%TYPE ;

    v_temp_cnt          NUMBER ;
    v_RecCnt            NUMBER ;
-- -----------------------------------------------------------------------------
-- Search Data Val
-- -----------------------------------------------------------------------------
    v_added_svc_n           DBMS_SQL.Varchar2_Table   ;

-- -----------
-- FETCH Val
-- -----------
    N_CURSOR    INTEGER;
    N_RET       INTEGER;
    SQL_TEXT    VARCHAR2(1500);

    fetch_size  NUMBER := 10 ;
    indx        NUMBER := 1 ;


CURSOR cur_get_data IS
	SELECT        ADDED_SVC_CD
		,         NVL(ADDED_SVC_CD       , '' )
		|| '|' || NVL(OFFSET             , '' )
		|| '|' || NVL(TO_CHAR(START_DT  , 'YYYYMMDDHH24MISS'), '')
		|| '|' || NVL(CP_SYS_ID          , '' )
		|| '|' || NVL(CP_MNG_CD          , '' )
		|| '|' || NVL(SVC_CP_TP          , '' )
		|| '|' || NVL(ADDED_SVC_DSC      , '' )
		|| '|' || NVL(ADDED_SVC_URL      , '' )
		|| '|' || NVL(ADDED_SVC_FILE_NM  , '' )
		|| '|' || NVL(SKT_NM             , '' )
		|| '|' || NVL(SKT_DEPT_NM        , '' )
		|| '|' || NVL(SKT_OFFICE         , '' )
		|| '|' || NVL(SKT_MOBILE         , '' )
		|| '|' || NVL(ADDED_SVC_MAP_CD   , '' )
		|| '|' || NVL(ADDED_TP           , '' )
		|| '|' || NVL(SHARE_YN           , '' )  || '|'
         AS GET_DATA
	 FROM TB_ADDED_SVC
     ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_ADDED Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_added.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w', 32767 );
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;

        v_added_svc_cd := c1.ADDED_SVC_CD;

        BEGIN
	        -- Grant_Cd Fatch
			SQL_TEXT :=   'SELECT  CP_MNG_CD '                    -- GRANT_CD
			   || 'FROM TB_SHARE_SVC  '
			   || 'WHERE ADDED_SVC_CD = ''' || v_added_svc_cd || '''' ;

	        -- ============
	        -- CURSOR 처리
	        -- ============
	        N_CURSOR := DBMS_SQL.OPEN_CURSOR;
	        DBMS_SQL.PARSE(N_CURSOR, SQL_TEXT, DBMS_SQL.NATIVE);

			DBMS_SQL.DEFINE_ARRAY(N_CURSOR, 1, v_added_svc_n      , fetch_size, indx );

	        N_RET := DBMS_SQL.EXECUTE(N_CURSOR);

	        v_temp_cnt := 1 ;

	        << Internal_Cursor_Loop >>
	        LOOP
	            N_RET := DBMS_SQL.FETCH_ROWS(N_CURSOR);
	            --DBMS_OUTPUT.PUT_LINE(N_RET);
	            v_RecCnt := DBMS_SQL.LAST_ROW_COUNT ;
	            --DBMS_OUTPUT.PUT_LINE('FETCH_CNT [' || v_RecCnt || ']');

	            DBMS_SQL.COLUMN_VALUE(N_CURSOR, 1, v_added_svc_n       );

	            /*
	            DBMS_OUTPUT.PUT_LINE('v_RecCnt       [' || v_RecCnt || ']');
	            DBMS_OUTPUT.PUT_LINE('v_added_svc_n  [' || v_added_svc_n(v_temp_cnt)        || ']');
	            */

	            v_temp_cnt := v_temp_cnt + 1 ;

	            EXIT WHEN N_RET != fetch_size ;
	        END LOOP Internal_Cursor_Loop ;

	        IF DBMS_SQL.IS_OPEN(N_CURSOR) THEN
	            DBMS_SQL.CLOSE_CURSOR(N_CURSOR);
	        END IF;

        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE( '***** INTERNAL SELECT [' || SQLERRM || '][' || v_added_svc_cd || '] *****');
        END ;


        -- init
        v_all_added_svc := '' ;

        -- Added_Svc Count Loop
		<< Process_Loop >>
		FOR i IN 1..v_RecCnt LOOP
            BEGIN

                IF i = 1 THEN
                    v_all_added_svc := TRIM(v_added_svc_n(i)) ;
                ELSE
                    v_all_added_svc := v_all_added_svc || '$' || TRIM(v_added_svc_n(i)) ;
                END IF ;


		        /*
		        DBMS_OUTPUT.PUT_LINE('-----------------------------------------------');
		        DBMS_OUTPUT.PUT_LINE('v_RecCnt           [' || v_RecCnt || ']/['  || i || ']');
		        DBMS_OUTPUT.PUT_LINE('v_Svc_Mng_Num      [' || v_added_svc_n(i)        || ']');

		        */
	            --DBMS_OUTPUT.PUT_LINE('v_all_grant[' || i || '][' || v_added_svc_n(i)        || ']');
	        EXCEPTION
	            WHEN OTHERS THEN
	                DBMS_OUTPUT.PUT_LINE( '***** FOR [' || SQLERRM || '][' || v_added_svc_cd ||'] *****');
            END ;
        END LOOP Process_Loop ;


  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA || v_all_added_svc );
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                DBMS_OUTPUT.PUT_LINE( '***** WIRTE [' || SQLERRM || '][' || v_added_svc_cd ||'] *****');
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                DBMS_OUTPUT.PUT_LINE( '***** WIRTE [' || SQLERRM || '][' || v_added_svc_cd ||'] *****');
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                DBMS_OUTPUT.PUT_LINE( '***** WIRTE [' || SQLERRM || '][' || v_added_svc_cd ||'] *****');
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                DBMS_OUTPUT.PUT_LINE( '***** WIRTE [' || SQLERRM || '][' || v_added_svc_cd ||'] *****');
   	    COMMIT;
        END;
    END LOOP Process_Loop;
	<< end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_ADDED Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '][' || v_added_svc_cd ||'] *****');
       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '][' || v_added_svc_cd ||'] *****');
       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '][' || v_added_svc_cd ||'] *****');
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '][' || v_added_svc_cd ||'] *****');
       COMMIT;
END;
/




  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_MENU"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_MENU
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

-- -- -----------------------------------------------------------------------------
-- -- Cursor
-- -- -----------------------------------------------------------------------------
CURSOR cur_get_data IS
	SELECT        NVL(MENU_CD   , '' )
		|| '|' || NVL(MENU_NM   , '' )
		|| '|' || NVL(MENU_SEQ  , '' )
		|| '|' || NVL(MENU_DSC  , '' )
         AS GET_DATA
	 FROM TB_MENU
     ORDER BY MENU_SEQ
     ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_MENU Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_menu.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA );
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
  	    COMMIT;
        END;
    END LOOP Process_Loop;
    << end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_MENU Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN DUP_VAL_ON_INDEX THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN TOO_MANY_ROWS THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN OTHERS THEN
	     error_cnt := error_cnt + 1;
	     DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_CP"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_CP
-- History: (2005.05.11) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_cp_filename     VARCHAR2(50)  := '';
    sam_cust_filename   VARCHAR2(50)  := '';
    sam_uap_filename    VARCHAR2(50)  := '';
    sam_icas_filename   VARCHAR2(50)  := '';

    sam_cp_filetype     utl_file.file_type;
    sam_cust_filetype   utl_file.file_type;
    sam_uap_filetype    utl_file.file_type;
    sam_icas_filetype   utl_file.file_type;
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

-- -- -----------------------------------------------------------------------------
-- -- Cursor
-- -- -----------------------------------------------------------------------------
CURSOR cur_get_data IS
	SELECT         CP.CP_MNG_CD
        ,          NVL(CP.CP_MNG_CD          , '')                                                                -- CP_MNG_CD
		|| '|' ||  NVL(CP.CP_NM              , '')                                                                -- CP_NM
		|| '|' ||  NVL(CP.PASSWD             , '')                                                                -- PASSWD
		|| '|' ||  NVL(CP.SVC_DSC            , '')                                                                -- SVC_DSC
		|| '|' ||  NVL(TO_CHAR(CP.CP_REQ_DT , 'YYYYMMDDHH24MISS'), '')                                            -- CP_REQ_DT
		|| '|' ||  NVL(CP.APPROVAL_TP        , '')                                                                -- APPROVAL_TP
		|| '|' ||  NVL(TO_CHAR(CP.CP_APPROVAL_DT , 'YYYYMMDDHH24MISS'), '')                                       --CP_APPROVAL_DT
		|| '|' ||  NVL(CP.FIRST_NM           , '')
   -- FIRST_NM
		|| '|' ||  NVL(CP.FIRST_EMAIL        , '')
   -- FIRST_EMAIL
		|| '|' ||  NVL(CP.FIRST_OFFICE       , '')
      -- FIRST_OFFICE
		|| '|' ||  NVL(CP.FIRST_MOBILE       , '')
          -- FIRST_MOBILE
		|| '|' ||  NVL(CP.SECOND_NM          , '')
              -- SECOND_NM
		|| '|' ||  NVL(CP.SECOND_EMAIL       , '')
               -- SECOND_EMAIL
		|| '|' ||  NVL(CP.SECOND_OFFICE      , '')
                   -- SECOND_OFFICE
		|| '|' ||  NVL(CP.SECOND_MOBILE      , '')
                        -- SECOND_MOBILE
		|| '|' ||  NVL(CP.THIRD_NM           , '')                                                                -- THIRD_NM

		|| '|' ||  NVL(CP.THIRD_EMAIL        , '')                                                                -- THIRD_EMAIL
		|| '|' ||  NVL(CP.THIRD_OFFICE       , '')                                                                -- THIRD_OFFICE
		|| '|' ||  NVL(CP.THIRD_MOBILE       , '')                                                                -- THIRD_MOBILE
		|| '|' ||  NVL(CP.APPLICANT_NM       , '')
-- APPLICANT_NM
		|| '|' ||  NVL(CP.APPLICANT_OFFICE   , '')
    -- APPLICANT_OFFICE
		|| '|' ||  NVL(CP.APPLICANT_MOBILE   , '')
            -- APPLICANT_MOBILE
		|| '|' ||  NVL(CP.APPLICANT_EMAIL    , '')
                    -- APPLICANT_EMAIL
		|| '|' ||  NVL(CP.SYSTEM_OS          , '')
                           -- SYSTEM_OS
		|| '|' ||  NVL(CP.PROGRAM_LANG       , '')
                            -- PROGRAM_LANG
		|| '|' ||  NVL(TRIM(CP.EXEC_ID)      , '')                                                                -- EXEC_ID
		|| '|' ||  NVL(TO_CHAR(CP.UPDATE_DT , 'YYYYMMDDHH24MISS'), '')         									  -- UPDATE_DT
		|| '|' ||  NVL(CP.SKT_NM             , '')        -- SKT_NM
		|| '|' ||  NVL(CP.SKT_DEPT_NM        , '')      -- SKT_DEPT_NM
		|| '|' ||  NVL(CP.SKT_OFFICE         , '')         -- SKT_OFFICE
		|| '|' ||  NVL(CP.SKT_MOBILE         , '')           -- SKT_MOBILE
		|| '|' ||  NVL(CP.SVC_NOTE           , '')             -- SVC_NOTE
		|| '|' ||  NVL(CP.SVC_FLOW           , '')             -- SVC_FLOW
		|| '|' ||  NVL(CP.MAPPING_YN         , '')             -- MAPPING_YN
		|| '|' ||  NVL(CP.MAPPING_DSC        , '')               -- MAPPING_DSC
		|| '|' ||  NVL(CP.UAPROFILE_YN       , '')                  -- UAPROFILE_YN
		|| '|' ||  NVL(CP.UAPROFILE_DSC      , '')                      -- UAPROFILE_DSC
		|| '|' ||  NVL(CP.ICAS_YN            , '')                           -- ICAS_YN
		|| '|' ||  NVL(CP.ICAS_DSC           , '')                          -- ICAS_DSC
		|| '|' ||  NVL(CP.ICAS_CP_IP         , '')                          -- ICAS_CP_IP
		|| '|' ||  NVL(CP.ICAS_NM            , '')                            -- ICAS_NM
		|| '|' ||  NVL(CP.ICAS_DEPT_NM       , '')                           -- ICAS_DEPT_NM
		|| '|' ||  NVL(CP.ICAS_OFFICE        , '')                                                                -- ICAS_OFFICE
		|| '|' ||  NVL(CP.ICAS_MOBILE        , '')                                                                -- ICAS_MOBILE
		|| '|' ||  NVL(CP.ADDEDSVC_YN        , '')                                                                --ADDEDSVC_YN
		|| '|' ||  NVL(CP.ADDEDSVC_DSC       , '')-- ADDEDSVC_DSC
		|| '|' ||  NVL(CP.ICAS_FILE_NM       , '')    -- ICAS_FILE_NM
		|| '|' ||  NVL(CP.ADDEDSVC_FILE_NM   , '')        -- ADDEDSVC_FILE_NM 48
        AS CP_INFO
        --------
		,  '|' ||   NVL(UAP.UAP_BITMAP         , '')
             -- UAP_BITMAP 49
		|| '|' ||  NVL(UAP.UAP_CMT            , '')
               -- UAP_CMT 50
        AS UAP_G
        --------
		,  '|' ||  NVL(CUST.G_CLIENT_ID_YN      , '' )
           -- G_CLIENT_ID_YN      51
		|| '|' || NVL(CUST.G_MOBILE_SVC_NUM_YN , '' )
                        -- G_MOBILE_SVC_NUM_YN 52
		|| '|' || NVL(CUST.G_MOBILE_ID_NUM_YN  , '' )                                                            --G_MOBILE_ID_NUM_YN  53
		|| '|' || NVL(CUST.G_IMSI_YN           , '' )
          -- G_IMSI_YN           54
		|| '|' || NVL(CUST.G_ADDED_SVC_YN      , '' )
                       -- G_ADDED_SVC_YN      55
		|| '|' || NVL(CUST.G_CERTI_CUST_YN     , '' )                                                            -- G_CERTI_CUST_YN     56
		|| '|' || NVL(CUST.G_ALL_ADDED_SVC_YN  , '' )
         -- G_ALL_ADDED_SVC_YN  57
		|| '|' || NVL(CUST.G_SVC_MNG_NUM_YN    , '' )
                      -- G_SVC_MNG_NUM_YN    58
		|| '|' || NVL(CUST.G_CHARGE_CD_YN      , '' )                                                            -- G_CHARGE_CD_YN      59
		|| '|' || NVL(CUST.UAP_CMT             , '' )
        -- UAP_CMT             60
        AS CUST_G
        --------
		,  '|' || NVL(ICAS.ICAS_BITMAP         , '' )
           -- ICAS_BITMAP              61
		|| '|' || NVL(ICAS.ICAS_CMT            , '' )                                                       -- ICAS_CMT            62
        AS ICAS_G
        --------
        ,  '|' ||  ''
     -- 63
        || '|' ||  NVL(CP.SKT_EMP_NO         , '')
     -- SKT_EMP_NO     64
        || '|' ||  NVL(CP.ICAS_EMP_NO        , '')
                    -- ICAS_EMP_NO    65
        AS CP_INFO_ETC
        --- **** 추가 START **** ---
        /*
        || '|' ||  NVL(CP.UAPROFILE_FILE_NM   , '')
                        -- UAPROFILE_FILE_NM
        */
        -- *** --
        /*
        || '|' ||  NVL(CP.CP_CONN_MIN          , '' )                                                            --
 CP_CONN_MIN
        || '|' ||  NVL(CP.CP_CONN_MAX          , '' )
      -- CP_CONN_MAX
        || '|' ||  NVL(CP.CP_CONN_TOT          , '' )
              -- CP_CONN_TOT
        || '|' ||  NVL(CP.CP_TP                , '' )
                      -- CP_TP
        */
        --- **** 추가 END **** ---
	FROM TB_CP CP
	    ,TB_ICAS_GRANT ICAS
	    ,TB_CUST_GRANT CUST
	    ,TB_UAP_GRANT UAP
	WHERE CP.CP_MNG_CD = ICAS.CP_MNG_CD (+)
	AND   CP.CP_MNG_CD = CUST.CP_MNG_CD (+)
	AND   CP.CP_MNG_CD = UAP.CP_MNG_CD (+) ;
     -- WHERE CP.CP_MNG_CD < '5000'
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_CP Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || '] *****');
-- FILE OPEN
    select 'init_ldap_cp.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w', 30000);


    -- 검증 처리를 위한 파일들
    sam_cp_filename   := 'cp.dat'         ;
    sam_cust_filename := 'custgrant.dat'  ;
    sam_uap_filename  := 'uapgrant.dat'   ;
    sam_icas_filename := 'icasgrant.dat'  ;

    sam_cp_filetype   := utl_file.fopen(sam_data_filedir, sam_cp_filename    , 'w' , 10000) ;
    sam_cust_filetype := utl_file.fopen(sam_data_filedir, sam_cust_filename  , 'w' , 10000) ;
    sam_uap_filetype  := utl_file.fopen(sam_data_filedir, sam_uap_filename   , 'w' , 10000) ;
    sam_icas_filetype := utl_file.fopen(sam_data_filedir, sam_icas_filename  , 'w' ,10000) ;
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.CP_INFO || c1.UAP_G || c1.CUST_G || c1.ICAS_G || c1.CP_INFO_ETC );

            -- 검증을 위한 파일생성
            utl_file.put_line(sam_cp_filetype   , c1.CP_INFO    || c1.CP_INFO_ETC );
            utl_file.put_line(sam_cust_filetype , c1.CP_MNG_CD  || c1.CUST_G      );
            utl_file.put_line(sam_uap_filetype  , c1.CP_MNG_CD  || c1.UAP_G       );
            utl_file.put_line(sam_icas_filetype , c1.CP_MNG_CD  || c1.ICAS_G );


    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
  	    COMMIT;
        END;
    END LOOP Process_Loop;
    << end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);

    -- 검증을 위한 처리
    utl_file.fclose(sam_cp_filetype  );
    utl_file.fclose(sam_cust_filetype);
    utl_file.fclose(sam_uap_filetype );
    utl_file.fclose(sam_icas_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_CP Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN DUP_VAL_ON_INDEX THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN TOO_MANY_ROWS THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN OTHERS THEN
	     error_cnt := error_cnt + 1;
	     DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_TB_UAP_ATTR" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_TB_UAP_ATTR
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 일일 대사를 위해
--        SAM 파일생성(TB_UAP_ATTR)
-- 변경력: 신규 (2003.11.26) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------

    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';

    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   CURSOR DEFINE  ( 206자리)
------------------------------
--   COMPO_CD           (  2)
--   SUB_COMPO_CD       (  4)
--   SUB_COMPO_NM       (200)
-- --------------------------
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_CD, '')
			|| '|' || NVL(ATTR_NM, '')
			|| '|' || NVL(NM_SPACE, '')
			|| '|' || NVL(DATA_TP, '')
			|| '|' || NVL(ATTR_TP, '') AS GET_DATA
	FROM TB_UAP_ATTR ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP_ATTR Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_tb_uap_attr_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'daily_tb_uap_attr_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR(DAILY)', 'D', SYSDATE, substr(err_code,1,300)) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_TB_UAP_ATTR Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_UAP_ATTR(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_NEW_DEVICE_MODEL" (
	I_Work_dt IN VARCHAR2 DEFAULT TO_CHAR(SYSDATE-1,'YYYYMMDD')
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : Daily_NEW_DEV_MODEL
-- 기능 : COIS_DEVICE_CD, Cois코드, 모델명, 변경일자를 넘겨주기 위함
-- 변경력: 신규 (2013.08.05) : - KHE -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    VARCHAR2(200);
-- -- --------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- --------------------------------------------------------------------------

-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'

    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    log_cnt     NUMBER := 0;

-- ------------------------------------------------------
CURSOR cur_get_data IS
	SELECT UPPER(COIS_DEVICE_CD) || '|' || UPPER(UAF_DEVICE_MANUF) || UAF_DEVICE_MODEL || '|' || UPPER(b.attr_val) || '|' || to_char(a.UPDATE_DT,'YYYYMMDDHH24MISS') AS GET_DATA
    FROM TB_UAP A,
        (select device_mng_num, attr_val from tb_uap_attr_list where attr_nm = 'Model') B
    WHERE A.device_mng_num = B.device_mng_num(+)
    AND   A.UAF_DEVICE_MANUF IS NOT NULL
    AND   A.UAF_DEVICE_MODEL IS NOT NULL
    AND  TO_CHAR(A.UPDATE_DT,'YYYYMMDD') = I_Work_dt
;

-- ====================
--  Main Process Start
-- ====================
BEGIN -- 1.

    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.PUT_LINE('***** [ DAILY_NEW_DEVICE_MODEL Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE('***** [ WORK DATE [' || I_Work_dt || '] *****');

-- FILE OPEN
    SELECT 'daily_new_device_model_' ||  I_Work_dt  || '.dat'
    INTO    sam_data_filename
    FROM    dual ;

    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_NEW_DEVICE_MODEL(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP -- 2.
    BEGIN  -- 3.

  --  읽은 DATA Count
        read_cnt := read_cnt + 1;

  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN -- 4.
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
			write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD, RUN_DT)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_NEW_DEVICE_MODEL(DAILY)', 'D', SUBSTR(err_code,1,300), sysdate ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD, RUN_DT)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_NEW_DEVICE_MODEL(DAILY)', 'D', SUBSTR(err_code,1,300), sysdate) ;

   	   COMMIT;
        END; -- 4.
    END; -- 3.
    << end_loop >>
    NULL;
    END LOOP; -- 2.

-- ===============================================================
-- End Cursor Loop

-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_NEW_DEVICE_MODEL(DAILY)', 'E', SYSDATE, read_cnt,write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_NEW_DEVICE_MODEL END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');

EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD, RUN_DT)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_NEW_DEVICE_MODEL(DAILY)', 'D', SUBSTR(err_code,1,300), sysdate ) ;
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD, RUN_DT)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_NEW_DEVICE_MODEL(DAILY)', 'D', SUBSTR(err_code,1,300), sysdate ) ;
       COMMIT;

END
;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_BPCIM_XMLDATA" (
	v_MSG_ID			IN VARCHAR2,
	v_SVC_ID			IN VARCHAR2,
	v_XML_DATA			IN CLOB
)
/*
	처리내용 : CLOB 을 활용한 데이터 입력을 위한 procedure
	처리내용 : BPCIM에서 입력된 XML 데이터를 TB_BPCIM_IF 테이블에 insert
				CLOB 컬럼에 데이터를 넣기 위해서는
				1. EMPTY_CLOB을 활용하여 insert
				2. FOR UPDATE 로 해당 컬럼을 lock
				3. DBMS_LOB.WRITE / DBMS_LOB.WRITEAPPEND 활용하여 update 처리.
	made by joajoa. 2012.10.31
*/
IS
	v_clob_selected CLOB;
	v_write_amt     NUMBER;
	v_write_offset  INTEGER := 1;
	v_buf           LONG;
	-- CLOB 컬럼에 한번에 입력시킬 크기(오라클 Buffer 설정과 연관된 것 같음. Buffer 사이즈에 따라 크기 조정)
	v_buf_value     INTEGER := 1000;
	v_clob_length   NUMBER;
	loop_index      INTEGER;
	v_key_data      INTEGER;

BEGIN

	DBMS_OUTPUT.ENABLE ( 1000000);
	DBMS_OUTPUT.PUT_LINE( '***** [ SP_BPCIM_XMLDATA Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');

	-- 새로운 ROW일 경우 offset 초기화
	v_write_offset := 1;

	-- CLOB 초기화를 위한 key Search
	SELECT TB_BPCIM_SEQ.NEXTVAL INTO v_key_data FROM DUAL;
	
	-- CLOB 제외한 값 insert

	INSERT INTO TB_BPCIM_IF
		( SEQ, MSG_ID, SVC_ID, REG_DT, XML_DATA
		)
		VALUES
		(	v_key_data,
			v_MSG_ID,
			v_SVC_ID,
			SYSDATE(),
			EMPTY_CLOB()
		);

	-- CLOB 초기화
	SELECT XML_DATA INTO v_clob_selected FROM TB_BPCIM_IF
	WHERE SEQ = v_key_data
	FOR UPDATE;

	-- 컬럼 DATA가 존재할 경우만
	IF v_XML_DATA is not null THEN
		v_clob_length := DBMS_LOB.GETLENGTH (v_XML_DATA);

		-- CLOB 컬럼에 한번에 입력시킬 수 있는 크기보다 큰 경우 LOOP로 처리
		IF v_clob_length > v_buf_value THEN
			-- DATA 전체 크기를 v_buf_value 크기로 나눈 값만큼 LOOP
			FOR loop_index IN 1 .. TRUNC(v_clob_length / v_buf_value)
			LOOP
				DBMS_OUTPUT.PUT_LINE( cast(loop_index as varchar2) || '. loop_index --------' || cast((v_buf_value * (loop_index - 1)) + 1 as varchar2));

				v_buf := DBMS_LOB.SUBSTR(v_XML_DATA, v_buf_value, (v_buf_value * (loop_index - 1) ) + 1);
				v_write_amt := DBMS_LOB.GETLENGTH (v_buf);
				DBMS_LOB.WRITEAPPEND(v_clob_selected, v_write_amt, v_buf);
			END LOOP;

			-- 나머지 DATA 입력
			IF MOD(v_clob_length, v_buf_value) <> 0 THEN
				v_buf := DBMS_LOB.SUBSTR(v_XML_DATA, MOD(v_clob_length, v_buf_value), (v_clob_length - MOD(v_clob_length, v_buf_value)) + 1);
				v_write_amt := DBMS_LOB.GETLENGTH (v_buf);
				DBMS_LOB.WRITEAPPEND(v_clob_selected, v_write_amt, v_buf);
			END IF;
		-- CLOB 컬럼에 한번에 입력시킬 수 있는 크기보다 작은 경우의 처리
		ELSE
			v_buf := v_XML_DATA;
			v_write_amt := DBMS_LOB.GETLENGTH (v_buf);
			DBMS_LOB.WRITE(v_clob_selected, v_write_amt, v_write_offset, v_buf);
		END IF;
	END IF;

    COMMIT;

EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('***** [ SP_BPCIM_XMLDATA Procedure ERROR ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
		DBMS_OUTPUT.PUT_LINE(SQLCODE || SQLERRM) ;
		ROLLBACK;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."TEST_STATS_ADD_PARTITIONS"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : add_partitions
-- 기능 : IFS쪽에서 사용하는 테이블에 대한 Table영역(Partition)을 생성하고 삭제
--        이것이 호출 되지 않았을경우에는 저장영영에러가 발생하여 IFS가 정상 업무
--        진행 할 수 없다.
-- 변경력: 신규 (2003.10.09) - complues -
-- -----------------------------------------------------------------------------

	sql_stmt    VARCHAR2(200);
	YYYYMMDD    VARCHAR2(8);
	RANGE_DATE  VARCHAR2(8);
	FUTURE_ROOM integer;
	BACK_ROOM integer;

BEGIN
	-----------------------------------
	----- TB_TEST_STATS_DATA ADD Partition
	-----------------------------------
	LOOP
		SELECT TO_CHAR(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,8)),'YYYYMMDD')+1,'YYYYMMDD')
			INTO YYYYMMDD
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_TEST_STATS_DATA';

		SELECT TO_CHAR(TO_DATE(MAX(SUBSTR(PARTITION_NAME,4,8)),'YYYYMMDD')+2,'YYYYMMDD')
			INTO RANGE_DATE
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_TEST_STATS_DATA';

		FUTURE_ROOM := TO_DATE(YYYYMMDD,'YYYYMMDD') - TRUNC(SYSDATE);

		-- 만들어져 있는것이 일주일전까지 만들어져 있는가를 확인
		IF FUTURE_ROOM > 7 THEN
			EXIT;
		END IF;



		sql_stmt := 'ALTER TABLE TB_TEST_STATS_DATA ADD PARTITION PT_'||YYYYMMDD||
					'  VALUES LESS THAN ('''||RANGE_DATE||''')';
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;

	-----------------------------------
	----- TB_MSG_QUEUE DROP Partition
	-----------------------------------
	LOOP

		SELECT TO_CHAR(TO_DATE(MIN(SUBSTR(PARTITION_NAME,4,8)),'YYYYMMDD'),'YYYYMMDD')
			INTO YYYYMMDD
		FROM USER_TAB_PARTITIONS
		WHERE TABLE_NAME = 'TB_TEST_STATS_DATA';

		BACK_ROOM := TO_DATE(YYYYMMDD,'YYYYMMDD') - TRUNC(SYSDATE);

		-- 현재보다 4일전 전인가를 확인
		IF BACK_ROOM > -6 THEN
			EXIT;
		END IF;

		sql_stmt := 'ALTER TABLE TB_TEST_STATS_DATA DROP PARTITION PT_'||YYYYMMDD ;
		--DBMS_OUTPUT.PUT_LINE('SQL:[' || sql_stmt || ']' );
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;


END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_CUST_PROF_CSBS" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_CUST_PROF_CSBS
-- 기능 : UAProfiel DB와 다른 시스템(MMS, MCG등) 연동에서 일일 대사를 위한 변경분(전체)
--        SAM 파일생성(CSBS전용)
-- 변경력: 신규 (2003.11.05) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/cust'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    log_cnt     NUMBER := 0;
-- ---------------------------
--   CURSOR DEFINE  ( 45자리)
------------------------------
--   SVC_MNG_NUM         (10)
--   UPDATE_CD           ( 2)
--   MOBILE_SVC_NUM      (11)
--   COIS_DEVICE_CD      ( 4)
--   COIS_DEVICE_VER     ( 4)
--   UPDATE_DT           (14)
--   DEVICE_MNG_NUM      ( 5)
-- --------------------------
CURSOR cur_get_data IS
	SELECT  RPAD(NVL(SKT.SVC_MNG_NUM, ' '), 10, ' ')
	     || RPAD(NVL(SKT.UPDATE_CD, ' '), 2, ' ')
	     || RPAD(NVL(SKT.MOBILE_SVC_NUM, ' '), 11, ' ')
	     || RPAD(NVL(DEV.COIS_DEVICE_CD, ' '), 4, ' ')
	     || RPAD(NVL(DEV.COIS_DEVICE_VER, ' '), 4, ' ')
	     || NVL(TO_CHAR(SKT.UPDATE_DT, 'YYYYMMDDHH24MISS'), RPAD(' ', 14))
	     || RPAD(NVL(DEV.DEVICE_MNG_NUM, ' '), 5, ' ') AS GET_DATA
	FROM ( SELECT H.SVC_MNG_NUM, H.UPDATE_CD, H.MOBILE_SVC_NUM, H.START_DT AS UPDATE_DT, H.DEVICE_MNG_NUM
		   FROM TB_CUST_PROF_HIST H
		 WHERE H.END_DT >= TRUNC( I_Work_dt - 1) -- ONE DAY DATA
		   AND   H.END_DT <  TRUNC( I_Work_dt )
                   AND   H.MVNO_CD = '0'  -- 2011.07.15 COLUS3 - MVNO사업자 구분코드가 '0'(SKT)인 데이터만 추출
		   UNION
	       SELECT SVC_MNG_NUM, UPDATE_CD, MOBILE_SVC_NUM, UPDATE_DT, DEVICE_MNG_NUM
		   FROM TB_CUST_PROF
		   WHERE UPDATE_DT >= TRUNC( I_Work_dt - 1) -- ONE DAY DATA
		   AND   UPDATE_DT <  TRUNC( I_Work_dt )
                   AND   MVNO_CD = '0'  -- 2011.07.15 COLUS3 - MVNO사업자 구분코드가 '0'(SKT)인 데이터만 추출

             )  SKT,
	     TB_UAP DEV
	WHERE SKT.DEVICE_MNG_NUM = DEV.DEVICE_MNG_NUM
	ORDER BY SKT.UPDATE_DT ;
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_CUST_PROF_CSBS Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_cust_prof_csbs_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF_CSBS(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;
    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'daily_cust_prof_csbs_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF_CSBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF_CSBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF_CSBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF_CSBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF_CSBS(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
-- --------------------------------------------------------------------------
-- 작업완료 확인 파일생성
-- --------------------------------------------------------------------------
	SELECT NVL(COUNT(*),0) INTO log_cnt FROM GAEBAL_UPADM.TB_JOB_LOG
	WHERE TO_CHAR(RUN_DT, 'YYYYMMDD') = TO_CHAR(SYSDATE, 'YYYYMMDD')
	AND STATUS = 'E' AND PROGRAM LIKE '%DAILY_CUST_PROF_CSBS%';
	--------
	-- 일단 고객정보에대해 돌아가는것이 하나니깐 하나만 돌아갔으면 그걸로 오케이 하야겠지.
	--------
    if log_cnt > 0 then  -- 작업 완료 Log 남김
		select 'daliy_cust_csbs_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '_XX.log'
		into    sam_data_filename
		from    dual ;
	    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
	    utl_file.fclose(sam_data_filetype);
    end if;
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_CUST_PROF_CSBS END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF_CSBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF_CSBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF_CSBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_CUST_PROF_CSBS(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_DEV_ATTR_LIST_UKEY"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_DEV_ATTR_LIST_UKEY
-- 기능 : UAProfiel DB와 U-Key간에 SIS값 추출
--        SAM 파일생성(TB_UAP, TB_UAP_ATTR_LIST )
-- 변경력: 신규 (2007.09.10) - black_vf -
-- 파일 생성 날짜는 월 2회 5일과 25일 full data로 내려준다.
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    sam_data_desc	VARCHAR2(200) := '';

    l_start NUMBER DEFAULT DBMS_UTILITY.GET_TIME;   -- 파일 생성 시간 관련 선언
-- --------------------------
-- Format : cois_device_cd|model|sis|device_mng_num
-- --------------------------

CURSOR cur_get_data IS
        SELECT cois_device_cd, model, sis, device_mng_num
	FROM (
		SELECT a.cois_device_cd, substr(c.model, 1, 20) model, b.sis, a.device_mng_num,
		       RANK() OVER(PARTITION BY a.cois_device_cd ORDER BY a.device_mng_num DESC) rank
		FROM tb_uap a,
		     (
		        SELECT device_mng_num, substr(attr_val,23,3) sis
		        FROM tb_uap_attr_list
		        WHERE attr_val like 'image/vnd.skt.sis;ver%'
		        AND attr_nm = 'CcppAccept'
		     ) b,
		     (
		        SELECT device_mng_num, attr_val model
		        FROM tb_uap_attr_list
		        WHERE compo_cd = 'HW'
		        AND attr_nm = 'Model'
		     ) c
		WHERE a.device_mng_num = b.device_mng_num (+)
		AND a.device_mng_num = c.device_mng_num (+)
		AND a.cois_device_cd IS NOT NULL
--		AND a.UPDATE_DT >= TRUNC(SYSDATE-1)
	)
	WHERE rank = 1;  -- rabk 1은 같은 cois_device_cd중에 가장 큰 device_mng_num

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
-- FILE OPEN
    select 'daily_tb_uap_attr_list_ukey_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
             (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_DEV_ATTR_LIST_UKEY', 'S', SYSDATE, 0, 0, 0) ;
        COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;

  --    -----------------------
  --     READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
--	    DBMS_OUTPUT.PUT_LINE( 'TEST : ' ||c1.cois_device_cd||':'||c1.model||':'||c1.sis||':'||c1.device_mng_num);
            utl_file.put_line(sam_data_filetype, c1.cois_device_cd||':'||c1.model||':'||c1.sis||':'||c1.device_mng_num);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
--		utl_file.fclose(sam_data_filetype);
		select 'daily_tb_uap_attr_list_ukey_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.dat'
		into    sam_data_filename
		from    dual ;
		sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_DEV_ATTR_LIST_UKEY', 'D', SYSDATE, substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_DEV_ATTR_LIST_UKEY', 'D', SYSDATE, substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_DEV_ATTR_LIST_UKEY', 'D', SYSDATE, substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
                    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_DEV_ATTR_LIST_UKEY', 'D', SYSDATE, substr(err_code,1,150) ) ;

            COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
               (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_DEV_ATTR_LIST_UKEY', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
        COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);


    DBMS_OUTPUT.PUT_LINE('파일 생성 시간');
    DBMS_OUTPUT.PUT_LINE('---------------');
    DBMS_OUTPUT.PUT_LINE(ROUND((DBMS_UTILITY.GET_TIME - l_start)/100,2) || 'sec');   -- 파일 생성 시간 출력

EXCEPTION
       WHEN NO_DATA_FOUND THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_DEV_ATTR_LIST_UKEY', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_DEV_ATTR_LIST_UKEY', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN TOO_MANY_ROWS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_DEV_ATTR_LIST_UKEY', 'D', SYSDATE, substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
                        error_cnt := error_cnt + 1;
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_TB_DEV_ATTR_LIST_UKEY', 'D', SYSDATE, substr(err_code,1,150) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_PERSON"
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : init_person
-- 기능 : UAProfiel DB와 IMS 연동(주민번호)에서 초기화를 위한
--        SAM 파일생성(TB_CUST_PERSON, TB_CUST_PROF)
-- 변경력: 신규 (2006.05.17) - complues -
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/ftp/ftp'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
CURSOR cur_get_data IS
	SELECT            SVC_MNG_NUM
			|| '|' || NVL(CUST_TP, '')
            || '|' || NVL(CUST_ID, '') AS GET_DATA
	FROM TB_CUST_PERSON
    ;

    -- 최초 작업일 기준
-- ====================
--  Main Process Start
-- ====================
BEGIN
    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_PERSON Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || '] *****');
-- FILE OPEN
    select 'init_person_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	     (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON(INIT)', 'S', SYSDATE, 0, 0, 0) ;
	COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
			if fetch_cnt = 1000000 then
			    file_seq  := file_seq + 1;
			    fetch_cnt := 0;
				utl_file.fclose(sam_data_filetype);
				select 'init_person_' || TO_CHAR(SYSDATE, 'YYYYMM_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
				into    sam_data_filename
				from    dual ;
				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
	INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
	VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON(INIT)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_PERSON Procedure END ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')|| ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON(INIT)', 'D', substr(err_code,1,150) );

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;

			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'INIT_PERSON(INIT)', 'D', substr(err_code,1,150) ) ;
       COMMIT;
END;
/





  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_GRANT_MENU"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_GRANT_MENU
-- History: (2005.11.04) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- -- -----------------------------------------------------------------------------
-- -- 처리에 사용되 변수
-- -- -----------------------------------------------------------------------------

-- -- -----------------------------------------------------------------------------
-- -- Cursor
-- -- -----------------------------------------------------------------------------
CURSOR cur_get_data IS
	SELECT        NVL(GRANT_CD   , '' )
		|| '|' || NVL(MENU_CD    , '' )
		|| '|' || NVL(TO_CHAR(REG_DT  , 'YYYYMMDDHH24MISS'), '')
         AS GET_DATA
	 FROM TB_GRANT_MENU
     ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_GRANT_MENU Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DDHH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_grant_menu.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================

    << Process_Loop >>
    FOR c1 IN cur_get_data LOOP
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA );
    -- WRITE DATA  Count
            write_cnt := write_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
  	    COMMIT;
        END;
    END LOOP Process_Loop;
    << end_loop >>

-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
	utl_file.fclose(sam_data_filetype);
	DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
	DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_GRANT_MENU Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN DUP_VAL_ON_INDEX THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN TOO_MANY_ROWS THEN
		error_cnt := error_cnt + 1;
		DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	WHEN OTHERS THEN
	     error_cnt := error_cnt + 1;
	     DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
	COMMIT;
END;
/






  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."INIT_LDAP_ATTR"
IS
-- -----------------------------------------------------------------------------
-- Procedure : INIT_LDAP_ATTR
-- History: (2005.05.20) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- Result Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
--
CURSOR cur_get_data IS
	SELECT            NVL(COMPO_CD, '')
			|| '|' || NVL(SUB_COMPO_CD, '')
			|| '|' || NVL(ATTR_NM, '')
			|| '|' || NVL(NM_SPACE, '')
			|| '|' || NVL(DATA_TP, '')
			|| '|' || NVL(ATTR_TP, '')
            || '|' || NVL(RESOLUTION_RULE, '')
            || '|' || NVL(MANDATORY_YN, '')
            || '|' || NVL(AUTHORITATIVE_YN, '')
            || '|' || NVL(CASE_SENSITIVE_YN, '')
            || '|' || NVL(BITMAP_SEQ, '')
            || '|' || NVL(ATTR_DSC, '')
            AS GET_DATA
	FROM TB_UAP_ATTR
    ORDER BY BITMAP_SEQ ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_ATTR Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
-- FILE OPEN
    select 'init_ldap_attr.dat'
    into    sam_data_filename

    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA Count
            write_cnt := write_cnt + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ INIT_LDAP_ATTR Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			DBMS_OUTPUT.PUT_LINE( '***** MAIN [' || SQLERRM || '] *****');
       COMMIT;
END;
/


  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_LDAP_CUST_PROF" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_LDAP_CUST_PROF
-- 기능 : UAProfiel DB와 LDAP간의 정보를 확인 하기 위한 처리로 고객정보 Sync를위한
--        일일대사용 SAM 파일 생성
--
-- 변경력: 신규 (2005.11.14) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(200);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- ---------------------------
--   각 컬럼 구분자는 콤마(,)
--   또한 아무값도 없을때에는 Space 한자리로 할까? 어？까?(일단 sync프로그램 짜보고 -_-; 힘들다)
------------------------------
-- --------------------------
CURSOR cur_get_data IS
    SELECT        SVC_MNG_NUM
		|| '|' || NVL(DEVICE_MNG_NUM    , ' ')
		|| '|' || NVL(MOBILE_ID_NUM     , ' ')
		|| '|' || NVL(MOBILE_SVC_NUM    , ' ')
		|| '|' || NVL(NET_GEN_TP        , ' ')
		|| '|' || NVL(CLIENT_ID_YN      , ' ')
		|| '|' || NVL(CLIENT_ID_NET2G   , ' ')
		|| '|' || NVL(CLIENT_ID_NET3G   , ' ')
		|| '|' || NVL(CLIENT_ID_CUST    , ' ')
		|| '|' || NVL(IMSI              , ' ')
		|| '|' || NVL(IMEI              , ' ')
		--|| '|' || NVL(TRIM(EXEC_ID)     , ' ')
		--|| '|' || NVL(TO_CHAR(COIS_UPDATE_DT, 'YYYYMMDDHH24MISS'), ' ')
		--|| '|' || NVL(UPDATE_CD         , ' ')
		--|| '|' || NVL(TO_CHAR(UPDATE_DT, 'YYYYMMDDHH24MISS'), ' ')
		--|| '|' || NVL(TRIM(UPDATE_PATH) , ' ')
    AS GET_DATA
    FROM TB_CUST_PROF
    WHERE  UPDATE_DT >= TRUNC( I_Work_dt - 1) -- ONE DAY DATA
    AND    UPDATE_DT <  TRUNC( I_Work_dt )
    ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_LDAP_CUST_PROF Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'daily_ldap_cust_prof_' || TO_CHAR(I_Work_dt, 'YYYYMMDD') || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_PROF(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;

-- 따로 파일명 구분하지 말자~
--             fetch_cnt := fetch_cnt + 1;
-- --  백만건 단위로 file name에 seq를 붙여서 만듬.... --
-- 			if fetch_cnt = 1000000 then
-- 			    file_seq  := file_seq + 1;
-- 			    fetch_cnt := 0;
-- 				utl_file.fclose(sam_data_filetype);
-- 				select 'daily_ldap_cust_prof_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
-- 				into    sam_data_filename
-- 				from    dual ;
-- 				sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- 			end if;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
         		INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN DUP_VAL_ON_INDEX THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN TOO_MANY_ROWS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   		        INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

   	    COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_PROF(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);
    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_LDAP_CUST_PROF Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
    || ' ] *****');
EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN DUP_VAL_ON_INDEX THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN TOO_MANY_ROWS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;

       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_LDAP_CUST_PROF(DAILY)', 'D', SYSDATE, substr(err_code,1,300) ) ;
       COMMIT;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."DAILY_MIUT_CODE_DOWN" (
	I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : DAILY_MIUT_CODE_DOWN
-- 기능 : UAProfile 에서 MIUT 에 Cois코드, 단말코드, 모델명을 넘겨주기 위함
-- 변경력: 신규 (2009.4.21) : - L.H.J -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    VARCHAR2(200);
-- -- --------------------------------------------------------------------------

-- -- OUTPUT TEXT FILE VARIABLE
-- -- --------------------------------------------------------------------------

-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/dev'

    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/dev';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
    log_cnt     NUMBER := 0;

-- ------------------------------------------------------
CURSOR cur_get_data IS
	SELECT DATA AS GET_DATA
	FROM
	   (SELECT UPPER(COIS_DEVICE_CD) || '|' || UPPER(UAF_DEVICE_MANUF) || UAF_DEVICE_MODEL || '|' || UPPER(b.attr_val) AS DATA
		FROM TB_UAP a,
          (select device_mng_num, attr_val from tb_uap_attr_list where attr_nm = 'Model') b
		WHERE A.device_mng_num = B.device_mng_num(+)
		AND   A.UAF_DEVICE_MANUF IS NOT NULL
		AND   A.UAF_DEVICE_MODEL IS NOT NULL
    );

-- ====================
--  Main Process Start
-- ====================
BEGIN -- 1.

    DBMS_OUTPUT.ENABLE ( 1000000);
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_MIUT_CODE_DOWN Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');

-- FILE OPEN
    SELECT 'daily_miut_d_' || TO_CHAR(I_Work_dt, 'YYYYMMDD') || '.dat'
    INTO    sam_data_filename
    FROM    dual ;

    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');

-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
	       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_MIUT_CODE_DOWN(DAILY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP -- 2.
    BEGIN  -- 3.

  --  읽은 DATA Count
        read_cnt := read_cnt + 1;

  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN -- 4.
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
			write_cnt := write_cnt + 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_MIUT_CODE_DOWN(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;

            WHEN OTHERS THEN
                error_cnt := error_cnt + 1;
                err_code  := SQLCODE || SQLERRM;
   	            INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_MIUT_CODE_DOWN(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;

   	   COMMIT;
        END; -- 4.
    END; -- 3.
    << end_loop >>
    NULL;
    END LOOP; -- 2.

-- ===============================================================
-- End Cursor Loop

-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_MIUT_CODE_DOWN(DAILY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
	COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ DAILY_MIUT_CODE_DOWN END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');

EXCEPTION
       WHEN NO_DATA_FOUND THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_MIUT_CODE_DOWN(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;
       WHEN OTHERS THEN
			error_cnt := error_cnt + 1;
			err_code  := SQLCODE || SQLERRM;
			INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
			VALUES (SEQ_JOB_LOG.NEXTVAL, 'DAILY_MIUT_CODE_DOWN(DAILY)', 'D', SYSDATE, SUBSTR(err_code,1,300) ) ;
       COMMIT;

END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SEMIWEEKLY_CUST_WIFI" (
        I_Work_dt IN DATE DEFAULT SYSDATE
)
IS
-- -----------------------------------------------------------------------------
-- Procedure명 : SEMIWEEKLY_CUST_WIFI
-- 목적 : wifi측위가능폰 조회 절차 변경을 통해 Keep alive air traffic 부하 경감(본부주례 건)
-- 변경력: 신규 (2012.03.15) - complues -
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
-- 결과를 보기위한 Count
-- -----------------------------------------------------------------------------
    read_cnt    NUMBER := 0;
    write_cnt   NUMBER := 0;
    fetch_cnt   NUMBER := 0;
    error_cnt   NUMBER := 0;
    err_code    varchar2(1000);
-- -- -----------------------------------------------------------------------------
-- -- OUTPUT TEXT FILE VARIABLE
-- -- -----------------------------------------------------------------------------
-- -- (log가 남을 Path. 단,initSID.ora에 지정되어 있어야 함)
-- --    utl_file_dir='/data/ftp/cust'
    file_seq    NUMBER := 1;
    sam_data_filedir    VARCHAR2(100) := '/data/ftp/cust';
    sam_data_filename   VARCHAR2(50)  := '';
    sam_data_filetype   utl_file.file_type;
-- --------------------------
-- SvcCharacteristics내 http://mobileinternet.nate.com/rdf/service-name#LocationService 값이 4.x, 5.x 인 단말 MDN 추출
-- --------------------------
CURSOR cur_get_data IS
        SELECT CUST.SVC_MNG_NUM
        || '|' || CUST.MOBILE_SVC_NUM
				|| '|' || CUST.DEVICE_MNG_NUM
				|| '|' || M.ATTR_VAL
				|| '|' || VER.ATTR_VAL AS GET_DATA
				FROM  ( SELECT DEVICE_MNG_NUM, ATTR_VAL
								FROM TB_UAP_ATTR_LIST
								WHERE COMPO_CD = 'HW' AND ATTR_NM = 'Model' ) M ,
     				  ( SELECT DEVICE_MNG_NUM, ATTR_VAL
     				  	FROM TB_UAP_ATTR_LIST
     				  	WHERE SUB_COMPO_CD = 'S008' AND ( ATTR_VAL like '4.%' OR ATTR_VAL like '5.%' )) VER ,
       				TB_CUST_PROF CUST
				WHERE VER.DEVICE_MNG_NUM = CUST.DEVICE_MNG_NUM
				AND VER.DEVICE_MNG_NUM = M.DEVICE_MNG_NUM ;
BEGIN

    DBMS_OUTPUT.ENABLE ( 1000000 );
    DBMS_OUTPUT.PUT_LINE( '***** [ SEMIWEEKLY_CUST_WIFI Procedure START ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ' ] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ WORK DATE [' || I_Work_dt || '] *****');
-- FILE OPEN
    select 'semiweekly_cust_wifi_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(1, '00')) || '.dat'
    into    sam_data_filename
    from    dual ;
    sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
-- ===============================================================
-- Start Cursor Loop
-- ===============================================================
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
               (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES ( SEQ_JOB_LOG.NEXTVAL, 'SEMIWEEKLY_CUST_WIFI(WEEKLY)', 'S', SYSDATE, 0, 0, 0) ;
    COMMIT;

    FOR c1 IN cur_get_data LOOP
    BEGIN
  --  읽은 DATA Count
        read_cnt := read_cnt + 1;
  --    -----------------------
  --    READ DATA를 FILE WRITE
  --    -----------------------
        BEGIN
    --  Data Write
            utl_file.put_line(sam_data_filetype, c1.GET_DATA);
    -- WRITE DATA 건수 Count
            write_cnt := write_cnt + 1;
            fetch_cnt := fetch_cnt + 1;
--  백만건 단위로 file name에 seq를 붙여서 만듬.... --
                        if fetch_cnt = 1000000 then
                            file_seq  := file_seq + 1;
                            fetch_cnt := 0;
                                utl_file.fclose(sam_data_filetype);
                                select 'semiweekly_cust_wifi_' || TO_CHAR(I_Work_dt, 'YYYYMMDD_') || TRIM(TO_CHAR(file_seq, '00')) || '.dat'
                                into    sam_data_filename
                                from    dual ;
                                sam_data_filetype := utl_file.fopen(sam_data_filedir, sam_data_filename, 'w');
                        end if;
        EXCEPTION
                   WHEN OTHERS THEN
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'SEMIWEEKLY_CUST_WIFI(WEEKLY)', 'D', SYSDATE, substr(err_code,1,150) ) ;
                        DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  || '] *****');

            COMMIT;
        END;
    END;
    << end_loop >>
    NULL;
    END LOOP;
-- ===============================================================
-- End Cursor Loop
-- ===============================================================
--  최종 작업결과를 Log Table에 남김..
    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
           (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
    VALUES (SEQ_JOB_LOG.NEXTVAL, 'SEMIWEEKLY_CUST_WIFI(WEEKLY)', 'E', SYSDATE, read_cnt, write_cnt, error_cnt) ;
        COMMIT;
-- --------------------------------------------------------------------------
-- LOG FILE CLOSE
-- --------------------------------------------------------------------------
    utl_file.fclose(sam_data_filetype);

    DBMS_OUTPUT.PUT_LINE( '***** [ WRITE COUNT  [' || write_cnt || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ READ  COUNT  [' || read_cnt  || '] *****');
    DBMS_OUTPUT.PUT_LINE( '***** [ SEMIWEEKLY_CUST_WIFI Procedure END  ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')    || ' ] *****');
EXCEPTION
       WHEN OTHERS THEN
                        err_code  := SQLCODE || SQLERRM;
                        INSERT INTO GAEBAL_UPADM.TB_JOB_LOG (SEQ, PROGRAM, STATUS, RUN_DT, ERR_CD)
                        VALUES (SEQ_JOB_LOG.NEXTVAL, 'SEMIWEEKLY_CUST_WIFI(WEEKLY)', 'D',
  SYSDATE, substr(err_code,1,150) ) ;
                        DBMS_OUTPUT.PUT_LINE( '***** [ MAIN Error [' || substr(err_code,1,150)  || '] *****');
       COMMIT;
END;
/






  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_SYNCCHECK_REPORT" (
        I_Work_dt IN VARCHAR2 DEFAULT NULL
)
IS
    --
    type report_msg_table is table of varchar2(500)
    index by binary_integer;
    type report_msg_cnt is table of number
    index by binary_integer;

    msg_org      report_msg_table;
    msg_sep      report_msg_table;
    msg_cnt      report_msg_cnt;

    i binary_integer := 0;
    j binary_integer := 0;

    dest_date   VARCHAR2(50)  := '';
BEGIN

    if I_Work_dt IS NULL then
        select to_char(sysdate - 1/24, 'YYYYMMDDHH24') into dest_date from dual;
        -- default 로 전 시간대 통계 처리..
    else
        dest_date := I_Work_dt;
    end if;

    DBMS_OUTPUT.ENABLE;

    FOR src_data IN (SELECT result_msg as msg, length(result_msg)-length(replace(result_msg,chr(10),''))+1 as cnt
                   FROM  tb_sync_check
                   WHERE event_dt like dest_date || '%' ) LOOP

        i := i +1 ;

        -- 테이블에 저장
        msg_org(i) := src_data.msg;
        msg_cnt(i) := src_data.cnt;
        if msg_cnt(i)>1 then
            for k in 1..msg_cnt(i) loop
                j := j + 1;
                msg_sep(j) := get_token(msg_org(i),k,chr(10));
            end loop;
        else
            j := j + 1;
            msg_sep(j) := src_data.msg;
        end if;


    END LOOP;

  -- Insert 전에 동일 데이터 삭제
  delete GAEBAL_UPADM.TB_SYNC_CHECK_RESULT
  where event_dt = dest_date;
  commit;

    -- Insert into tb_sync_check_result table , 화면 출력
    FOR cnt IN  1..j   LOOP
        INSERT INTO GAEBAL_UPADM.TB_SYNC_CHECK_RESULT
                   (EVENT_DT,SVC_MNG_NUM, RESULT_TB, RESULT_MSG, CONVERT_MSG)
        VALUES (dest_date
               , get_token(msg_sep(cnt),1,'$')
               , get_token(get_token(msg_sep(cnt),2,' '),1,'@')
               , msg_sep(cnt),
               substr(get_token(get_token(replace(msg_sep(cnt),'4','0'),2,' '),-1,'@')
                                   ,length(get_token(get_token(get_token(replace(msg_sep(cnt),'4','0'),2,' '),-1,'@'),1,':')) + 2
                                   ,length(get_token(get_token(replace(msg_sep(cnt),'4','0'),2,' '),-1,'@'))
                                      -length(get_token(get_token(get_token(replace(msg_sep(cnt),'4','0'),2,' '),-1,'@'),1,':')
                                   )
                         )
               ) ;
        COMMIT;
--        if cnt > j then
--          exit;
--        end if;
--        DBMS_OUTPUT.PUT_LINE('cnt : ' || msg_sep(cnt));
--        DBMS_OUTPUT.PUT_LINE('msg : ' || msg_org(cnt));
--        DBMS_OUTPUT.PUT_LINE('cnt : ' || msg_cnt(cnt));
    END LOOP;

EXCEPTION
       WHEN NO_DATA_FOUND THEN
          DBMS_OUTPUT.PUT_LINE('Exception NO_DATA_FOUND : ');
        commit;
       WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('Exception OTHERS : ');
          commit;
END;
/



  CREATE OR REPLACE PROCEDURE "GAEBAL_UPADM"."SP_SUM_NATEIFS_TRANS_DAILY"
( vPROC_DATETIME_IN IN varchar2 )
IS
	vPROC_DATETIME	varchar2(14);			-- 통계 기준 시각.
	vProcedure_Name CONSTANT varchar2(30) := 'SUM_NATEIFS_TRANS_DAILY';			-- 직접연동 / 간접연동의 분단위 통계 테이블 명.
	vJOB_SEQ		NUMBER;
	vERR_CODE       varchar2(20);
BEGIN
	DBMS_OUTPUT.ENABLE (1000000);
	DBMS_OUTPUT.PUT_LINE( '***** [' || vProcedure_Name || '] Procedure START.... ******* ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') );
-- 프로시져 시작.. 통계 기준 일자시각 설정. 30분전 시각의 1일 단위 통계.(즉 매 0~30분 이내에 돌면, 전 1일 대역 통계 처리)
-- 매일 00시 5분에 돌게 crontab 설정
	IF ( vPROC_DATETIME_IN IS NULL ) OR (LENGTH(vPROC_DATETIME_IN) < 8 ) THEN
		SELECT TO_CHAR(SYSDATE - 30/24/60, 'YYYYMMDDHH24MI') into vPROC_DATETIME  FROM DUAL;
	ELSE
		vPROC_DATETIME := vPROC_DATETIME_IN;
	END IF;
-- 프로시져 시작 시각... 시작 log 입력 후 최종 성공여부 처리시 사용.
--	SELECT SEQ_JOB_LOG.NEXTVAL into vJOB_SEQ  FROM DUAL;

--    INSERT INTO GAEBAL_UPADM.TB_JOB_LOG
--       (SEQ, PROGRAM, STATUS, RUN_DT, READ_CNT, INS_CNT, ERR_CNT)
--  VALUES (vJOB_SEQ, vProcedure_Name || ' INPUT PARAM : ' || vPROC_DATETIME, 'S', SYSDATE, 0, 0, 0) ;
	-- 최종 TEMP 데이터에 대한 통계 처리...
	INSERT into TB_NATEIFS_TRAN_DAILY
			SELECT SUBSTR(vPROC_DATETIME,1,8), PROCESS_CODE, OP_CD, RESULT_CODE, SUM(ACCESS_CNT)
			  FROM TB_NATEIFS_TRAN_HOUR
			 WHERE PROCESS_DT LIKE SUBSTR(vPROC_DATETIME,1,8) || '%'
			 GROUP BY SUBSTR(vPROC_DATETIME,1,8), PROCESS_CODE, OP_CD, RESULT_CODE
			;
--	UPDATE TB_JOB_LOG SET STATUS = 'E' WHERE SEQ = vJOB_SEQ;
	COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK;
	vERR_CODE := TO_CHAR(SQLCODE);
--	UPDATE GAEBAL_UPADM.TB_JOB_LOG SET STATUS = 'F' WHERE SEQ = vJOB_SEQ;
	COMMIT;
	DBMS_OUTPUT.PUT_LINE( '***** [' || vProcedure_Name || '] EXCEPTION - others ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') );
END;
/
