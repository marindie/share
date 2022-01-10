CREATE TABLESPACE  TS_CMDAT01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_CMDAT01.dbf' SIZE 4000M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_CMDAT01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
CREATE TABLESPACE  TS_CMDAT01_TEST  DATAFILE 'C:\Oracle\oradata\NXDB\TS_CMDAT01_TEST.dbf' SIZE 20M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_CMDAT01_TEST.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
CREATE TABLESPACE  TS_CMIDX01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_CMIDX01.dbf' SIZE 500M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_CMIDX01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
create user icscmapp identified by slccmapp
  default tablespace TS_CMDAT01
temporary tablespace TEMP;



--TS_AMDAT01, TS_AMIDX01 => icsamapp/slcamapp
CREATE TABLESPACE  TS_AMDAT01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_AMDAT01.dbf' SIZE 1024M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_AMDAT01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
CREATE TABLESPACE  TS_AMIDX01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_AMIDX01.dbf' SIZE 512M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_AMIDX01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
create user icsamapp identified by slcamapp
  default tablespace TS_AMDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icsamapp;

--TS_CPDAT01, TS_CPIDX01 => icscpapp/slccpapp
CREATE TABLESPACE  TS_CPDAT01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_CPDAT01.dbf' SIZE 100M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_CPDAT01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
CREATE TABLESPACE  TS_CPIDX01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_CPIDX01.dbf' SIZE 10M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_CPIDX01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
create user icscpapp identified by slccpapp
  default tablespace TS_CPDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icscpapp;

--TS_CSDAT01, TS_CSIDX01 => icscsapp/slccsapp
CREATE TABLESPACE  TS_CSDAT01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_CSDAT01.dbf' SIZE 3000M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_CSDAT01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
CREATE TABLESPACE  TS_CSDAT0100  DATAFILE 'C:\Oracle\oradata\NXDB\TS_CSDAT0100.dbf' SIZE 10M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_CSDAT0100.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
CREATE TABLESPACE  TS_CSDAT01001  DATAFILE 'C:\Oracle\oradata\NXDB\TS_CSDAT01001.dbf' SIZE 10M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_CSDAT01001.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
CREATE TABLESPACE  TS_CSIDX01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_CSIDX01.dbf' SIZE 50M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_CSIDX01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
create user icscsapp identified by slccsapp
  default tablespace TS_CSDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icscsapp;

--TS_RCDAT01, TS_RCIDX01 => icsrcapp/slcrcapp
CREATE TABLESPACE  TS_RCDAT01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_RCDAT01.dbf' SIZE 400M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_RCDAT01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
CREATE TABLESPACE  TS_RCIDX01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_RCIDX01.dbf' SIZE 20M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_RCIDX01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
create user icsrcapp identified by slcrcapp
  default tablespace TS_RCDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icsrcapp;

--TS_STDAT01, TS_STIDX01 => icsstapp/slcstapp
CREATE TABLESPACE  TS_STDAT01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_STDAT01.dbf' SIZE 600M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_STDAT01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
CREATE TABLESPACE  TS_STIDX01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_STIDX01.dbf' SIZE 300M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_STIDX01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;
create user icsstapp identified by slcstapp
  default tablespace TS_STDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icsstapp;

--TS_STDAT01, TS_STIDX01 => icsstapp01/slcstapp01
create user icsstapp01 identified by slcstapp01
  default tablespace TS_STDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icsstapp01;

--변경포인트

-- TS_ECMDAT01, TS_ECMIDX01 => icsecmapp/slcecmapp
CREATE TABLESPACE  TS_ECMDAT01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_ECMDAT01.dbf' SIZE 4000M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_ECMDAT01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;

CREATE TABLESPACE  TS_ECMIDX01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_ECMIDX01.dbf' SIZE 500M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_ECMIDX01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;

create user icsecmapp identified by slcecmapp
  default tablespace TS_ECMDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icsecmapp;


-- TS_EMSDAT01, TS_EMSIDX01 => icsemsapp/slcemsapp
CREATE TABLESPACE  TS_EMSDAT01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_EMSDAT01.dbf' SIZE 4000M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_EMSDAT01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;

CREATE TABLESPACE  TS_EMSIDX01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_EMSIDX01.dbf' SIZE 500M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_EMSIDX01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;

create user icsemsapp identified by slcemsapp
  default tablespace TS_EMSDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icsemsapp;

--- icsetcapp/slcetcapp
create user icsetcapp identified by slcetcapp
  default tablespace TS_CPDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icsetcapp;

--- us_etleus/us_etleus
create user us_etleus identified by us_etleus
  default tablespace TS_CPDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO us_etleus;

create user icsbtapp identified by slcbtapp
  default tablespace TS_CMDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icsbtapp;
grant dba to icsbtapp;


create user icsmsapp identified by slcmsapp
  default tablespace TS_CMDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icsmsapp;
grant dba to icsmsapp;




create user icsnhapp identified by slcnhapp
  default tablespace TS_CMDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icsnhapp;


create user icsabapp identified by slcabapp
  default tablespace TS_CMDAT01
temporary tablespace TEMP;

GRANT CONNECT,RESOURCE,CREATE VIEW TO icsabapp;




--자원순환
CREATE TABLESPACE  TS_RRDAT01  DATAFILE 'C:\Oracle\oradata\NXDB\TS_RRDAT01.dbf' SIZE 2000M;
ALTER DATABASE DATAFILE 'C:\Oracle\oradata\NXDB\TS_RRDAT01.dbf' 
AUTOEXTEND ON
NEXT 10K
MAXSIZE UNLIMITED
;

create user icsrrapp identified by slcrrapp
  default tablespace TS_RRDAT01
temporary tablespace TEMP;
GRANT CONNECT,RESOURCE,CREATE VIEW TO icsrrapp;

grant dba to icsrrapp;
grant dba to icsabapp;
grant dba to icsnhapp;

grant dba to icscmapp;
grant dba to icsrcapp;
grant dba to icscsapp;
grant dba to icsamapp;
grant dba to icsstapp;
grant dba to icscpapp;
grant dba to icsecmapp;
grant dba to icsemsapp;
grant dba to icsetcapp;
grant dba to icsmsapp;


