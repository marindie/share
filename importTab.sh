#/bin/bash
echo "USER=$1"
echo "PWD=$2"
echo "EXP_PATH=$3"

imp $1/$2 FROMUSER=UPADM TOUSER=UPADM file=$3/export.dmp \
log=$3/import.log GRANTS=N INDEXES=N CONSTRAINTS=N STATISTICS=NONE