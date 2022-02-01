#/bin/bash
echo "==== Welcome to removeDB Script ===="

echo -n "Password:" 
read -s password

if [ "${password}" != "uaprofile" ]; then
        echo
        exit;
fi

echo
echo "==================================="
echo "     START DB DELETION PROCESS     "
echo "==================================="

export ORACLE_SID=GWIDEDEV
echo " ORACLE_SID= $ORACLE_SID "

echo -n "Type 'yes' to Delete Database ($ORACLE_SID) : "
read -s confirm

if [ "${confirm^^}" == "YES" ]; then
dbca -silent -deleteDatabase -sourceDB GWIDEDEV -sysDBAUserName sys -sysDBAPassword password
else
        echo "$confirm^^"
        exit;
fi