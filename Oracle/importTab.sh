#/bin/bash
export ORACLE_SID=GWIDEDEV
imp gaebal_upadm/gaebal_upadm FROMUSER=UPADM TOUSER=GAEBAL_UPADM file=/home/oraUAP/user/wony/export.dmp \
log=/home/oraUAP/user/wony/import.log GRANTS=N INDEXES=N CONSTRAINTS=N STATISTICS=NONE