#/bin/bash
#SET PATH VARIABLE
ORADATA="/ORACLE/oradata"
USER="upadm"
PWD="oracle08"
SYS_PWD="password"
CHARSET="KO16MSWIN949"

echo -n "Password:" 
read -s password

if [ "${password}" != "uaprofile" ]; then
	echo 
	exit;
fi

echo

echo "==== Welcome to createDB Script ===="
echo "   ORADATA PATH = $ORADATA "
echo "   USER = $USER "
echo "   PWD = $PWD "
echo "   SYS_PWD = $SYS_PWD "
echo "   DB CHARACTER SET = $CHARSET "

FILE_LIST="FUNCTION_DDL.SQL
INDEX_DDL.SQL
PROCEDURE_DDL.SQL
SEQUENCE_DDL.SQL
importTab.sh
export.dmp"

for file in $FILE_LIST
do
	if [ ! -f $file ]; then
		echo " $file Is Missing. Check The Files. "
		exit;
	fi
done

echo
echo "==================================="
echo "     START DB CREATION PROCESS     "
echo "==================================="

echo -n "ORACLE_SID:" 
read -s ORA_SID
export ORACLE_SID=${ORA_SID}
echo " ORACLE_SID= ${ORACLE_SID} "

echo -n "Type 'yes' to Create Database ($ORACLE_SID) : "
read -s confirm
echo ""

if [ "${confirm^^}" == "YES" ]; then

echo "==================================="
echo "     DATABASE CREATION START       "
echo "==================================="

dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname $ORACLE_SID -sid $ORACLE_SID -sysDBAUserName sys -sysDBAPassword password -responseFile NO_VALUE -characterSet $CHARSET -memoryPercentage 20 -emConfiguration NONE

echo "==================================="
echo "     DATABASE CREATION END         "
echo "==================================="
echo

echo "============================"
echo "     CHECK DB INFO          "
echo "============================"

sqlplus "/as sysdba" << EOF
SELECT INSTANCE_NAME, STATUS, DATABASE_STATUS FROM V\$INSTANCE;
SELECT * FROM GLOBAL_NAME;
SELECT NAME FROM V\$DATAFILE;
EXIT;
EOF

echo "========================================"
echo "     DATABASE OBJECT CREATION START     "
echo "========================================"

sqlplus "/as sysdba" << EOF
CREATE TABLESPACE DATA01 DATAFILE '$ORADATA/$ORACLE_SID/data01.dbf' SIZE 64M AUTOEXTEND ON SEGMENT SPACE MANAGEMENT AUTO;
CREATE TABLESPACE DATA02 DATAFILE '$ORADATA/$ORACLE_SID/data02.dbf' SIZE 64M AUTOEXTEND ON SEGMENT SPACE MANAGEMENT AUTO;
CREATE TABLESPACE DATA03 DATAFILE '$ORADATA/$ORACLE_SID/data03.dbf' SIZE 64M AUTOEXTEND ON SEGMENT SPACE MANAGEMENT AUTO;
CREATE TABLESPACE DATA04 DATAFILE '$ORADATA/$ORACLE_SID/data04.dbf' SIZE 64M AUTOEXTEND ON SEGMENT SPACE MANAGEMENT AUTO;

CREATE TABLESPACE INDEX01 DATAFILE '$ORADATA/$ORACLE_SID/index01.dbf' SIZE 64M AUTOEXTEND ON SEGMENT SPACE MANAGEMENT AUTO;
CREATE TABLESPACE INDEX02 DATAFILE '$ORADATA/$ORACLE_SID/index02.dbf' SIZE 64M AUTOEXTEND ON SEGMENT SPACE MANAGEMENT AUTO;
CREATE TABLESPACE INDEX03 DATAFILE '$ORADATA/$ORACLE_SID/index03.dbf' SIZE 64M AUTOEXTEND ON SEGMENT SPACE MANAGEMENT AUTO;
CREATE TABLESPACE INDEX04 DATAFILE '$ORADATA/$ORACLE_SID/index04.dbf' SIZE 64M AUTOEXTEND ON SEGMENT SPACE MANAGEMENT AUTO;

CREATE TABLESPACE TS_MWADM DATAFILE '$ORADATA/$ORACLE_SID/ts_mwadm.dbf' SIZE 64M AUTOEXTEND ON SEGMENT SPACE MANAGEMENT AUTO;
CREATE TABLESPACE BIG_IDX DATAFILE '$ORADATA/$ORACLE_SID/big_idx.dbf' SIZE 64M AUTOEXTEND ON SEGMENT SPACE MANAGEMENT AUTO;
CREATE TABLESPACE BIG_DATA DATAFILE '$ORADATA/$ORACLE_SID/big_data.dbf' SIZE 64M AUTOEXTEND ON SEGMENT SPACE MANAGEMENT AUTO;

CREATE USER VAM IDENTIFIED BY $PWD DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;
CREATE USER MIG IDENTIFIED BY $PWD DEFAULT TABLESPACE BIG_DATA QUOTA UNLIMITED ON BIG_DATA;
CREATE USER PMH IDENTIFIED BY $PWD DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;
CREATE USER UAPIS IDENTIFIED BY $PWD DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;
CREATE USER UAPIFS IDENTIFIED BY $PWD DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;

CREATE ROLE CONNECT2;
GRANT CONNECT, CONNECT2, RESOURCE TO VAM;
GRANT CONNECT, CONNECT2, RESOURCE TO MIG;
GRANT CONNECT, CONNECT2, RESOURCE TO PMH;
GRANT CONNECT, CONNECT2, RESOURCE TO UAPIS;
GRANT CONNECT, CONNECT2, RESOURCE TO UAPIFS;

CREATE USER $USER IDENTIFIED BY $PWD DEFAULT TABLESPACE DATA01 QUOTA UNLIMITED ON DATA01;
GRANT CONNECT, CONNECT2, RESOURCE, DBA TO $USER;

CONNECT $USER/$PWD

@SEQUENCE_DDL.SQL
EOF

./importTab.sh

sqlplus $USER/$PWD << EOF
@INDEX_DDL.SQL
@FUNCTION_DDL.SQL
@PROCEDURE_DDL.SQL
@SYNONYM_DDL.SQL
@USER_TAB_PRIV_DCL.SQL
DECLARE 
JOB_NO NUMBER;
BEGIN
DBMS_JOB.SUBMIT(JOB_NO, 'ADD_PARTITIONS();', SYSDATE, 'SYSDATE + 1');
DBMS_OUTPUT.PUT_LINE('JOB NO : '||JOB_NO);
DBMS_JOB.RUN(JOB_NO);
END;
/
EOF

echo "========================================"
echo "     DATABASE OBJECT CREATION END       "
echo "========================================"

echo "==================================="
echo "     END DB CREATION PROCESS     "
echo "==================================="
else
	echo 
	exit;
fi


