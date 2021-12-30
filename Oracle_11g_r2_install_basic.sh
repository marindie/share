# Download Oracle 11g r2 64bit Linux 
# Go to the following URL and Download
# https://www.oracle.com/technetwork/database/enterprise-edition/downloads/112010-linx8664soft-100572.html

# Download CentOS6.6 64bit
# Go to the following URL and Download minimal version of CentOS6.6
# http://vault.centos.org/6.6/isos/x86_64/

# Download glibc-2.3.4-2.43.el4_8.2.i686.rpm
# Go to the following URL and Download glibc-2.3.4-2.43.el4_8.2.i686.rpm
# http://rpm.pbone.net/index.php3?stat=3&limit=6&srodzaj=1&dl=40&search=glibc-2.3.4-2&field[]=1&field[]=2

# Ready to install Oracle 
# Now Copy linux.x64_11gR2_database_1of2.zip linux.x64_11gR2_database_2of2.zip into your root home directory


#=============
# HOST ADD
#=============
sed -i'' -e "\$a\192.168.1.204 oradb" /etc/hosts

#==============
# Package Install
#==============
yum -y update
yum -y groupinstall "X Window System"  "GNOME Desktop Environment" "Desktop" "Fonts" "Korean Support"
yum install -y binutils compat-libcap* gcc* glibc* ksh libgcc* libstdc* libaio* make* sysstat* unixODBC* elfutils-libelf-devel unzip wget compat-libstdc++-33-3.2.3

wget ftp://ftp.pbone.net/mirror/www.whiteboxlinux.org/whitebox/4/en/os/x86_64/WhiteBox/RPMS/pdksh-5.2.14-30.x86_64.rpm
rpm -Uvh --nodeps pdksh-5.2.14-30.x86_64.rpm
rpm -Uvh glibc-2.3.4-2.43.el4_8.2.i686.rpm --nodeps --force

#==============
# Group Add
#==============
groupadd oinstall
groupadd dba
groupadd oper

#==============
# Create User
#==============
useradd -m -d /home/oracle -g oinstall -G dba,oper oracle
echo "oracle123" | passwd oracle --stdin

#==============
# Create Directory For Tablespace (Use this path to create tablespace data file)
#==============
mkdir -p /ORACLE/product/11.2/db
mkdir -p /ORACLE/oradata/ORADB

#==============
# Define Oracle Environment for oracle user
#==============
# sed command
sed -i'' -r -e "/^# User specific environment and startup programs/a\export ORACLE_BASE=\/ORACLE\nexport ORACLE_HOME=\$ORACLE_BASE\/product\/11.2\/db\nexport ORACLE_SID=ORADB\nexport ORACLE_TERM=xterm\nexport PATH=\/usr\/sbin:\$PATH\nexport PATH=\$PATH:\$ORACLE_HOME\/bin\nexport LD_LIBRARY_PATH=\$ORACLE_HOME\/lib:\/lib:\/usr\/lib:\/usr\/local\/lib\nexport CLASSPATH=$ORACLE_HOME\/JRE:$ORACLE_HOME\/jlib:$ORACLE_HOME\/rdbms\/jlib\nexport NLS_LANG=American_America.AL32UTF8\n" /home/oraUAP/.bash_profile

#==============
# Kernel Parameter 
#==============
# sed command
sed -i'' -e "\$a\kernel.sem = 250 32000 100 128\nfs.file-max = 6815744\nnet.ipv4.ip_local_port_range = 9000 65500\nnet.core.rmem_default = 262144\nnet.core.rmem_max = 4194304\nnet.core.wmem_default = 262144\nnet.core.wmem_max = 1048586\nfs.aio-max-nr = 1048576" /etc/sysctl.conf
# apply the kernel parameter change
sysctl -p

#==============
# USER RESOURCE LIMIT Setting
#==============
# sed command
sed -i'' -e "\$a\*               hard    nofile          65536\n*               soft    nproc           8192\n*               hard    nproc           16384\n*               soft    core            20480\n" /etc/security/limits.conf

#==============
# Use response file to install oracle instance in silent mode
#==============
# When we install oracle in linux, we use command runInstaller.
# Since I prefer to use CLI than GUI, I will use silent mode.
# That way I can install oracle without GUI (X Window, in this case)
# Oracle provide us three response files that can used to create oracle instance, listener, and database. So I will use response file

# Copy responfile from "Directory_where_you_unziped_downloaded_files/response" directory. In my case /ORACLE/database/response
# There is db_install.rsp file which can be used to install oracle instance.
cp /ORACLE/database/response/db_install.rsp /ORACLE/database/response/oracle_install.rsp

# sed command
sed -i'' -r -e "s/^oracle.install.option=.*/oracle\.install\.option=INSTALL_DB_SWONLY/" /ORACLE/database/response/oracle_install.rsp
sed -i'' -r -e "s/^UNIX_GROUP_NAME=.*/UNIX_GROUP_NAME=oinstall/" /ORACLE/database/response/oracle_install.rsp
sed -i'' -r -e "s/^INVENTORY_LOCATION=.*/INVENTORY_LOCATION=\/ORACLE\/oraInventory/" /ORACLE/database/response/oracle_install.rsp
sed -i'' -r -e "s/^SELECTED_LANGUAGES=.*/SELECTED_LANGUAGES=en,ko/" /ORACLE/database/response/oracle_install.rsp
sed -i'' -r -e "s/^ORACLE_HOME=.*/ORACLE_HOME=\/ORACLE\/product\/11.2\/uapdb/" /ORACLE/database/response/oracle_install.rsp
sed -i'' -r -e "s/^ORACLE_BASE=.*/ORACLE_BASE=\/ORACLE/" /ORACLE/database/response/oracle_install.rsp
sed -i'' -r -e "s/^oracle.install.db.InstallEdition=.*/oracle\.install\.db\.InstallEdition=EE/" /ORACLE/database/response/oracle_install.rsp
sed -i'' -r -e "s/^oracle.install.db.DBA_GROUP=.*/oracle\.install\.db\.DBA_GROUP=dba/" /ORACLE/database/response/oracle_install.rsp
sed -i'' -r -e "s/^oracle.install.db.OPER_GROUP=.*/oracle\.install\.db\.OPER_GROUP=oper/" /ORACLE/database/response/oracle_install.rsp
sed -i'' -r -e "s/^DECLINE_SECURITY_UPDATES=.*/DECLINE_SECURITY_UPDATES=true/" /ORACLE/database/response/oracle_install.rsp

# Check the result
grep "oracle.install.option=" /ORACLE/database/response/oracle_install.rsp
grep "UNIX_GROUP_NAME=" /ORACLE/database/response/oracle_install.rsp
grep "INVENTORY_LOCATION=" /ORACLE/database/response/oracle_install.rsp
grep "SELECTED_LANGUAGES=" /ORACLE/database/response/oracle_install.rsp
grep "ORACLE_HOME=" /ORACLE/database/response/oracle_install.rsp
grep "ORACLE_BASE=" /ORACLE/database/response/oracle_install.rsp
grep "oracle.install.db.InstallEdition=" /ORACLE/database/response/oracle_install.rsp
grep "oracle.install.db.DBA_GROUP=" /ORACLE/database/response/oracle_install.rsp
grep "oracle.install.db.OPER_GROUP=" /ORACLE/database/response/oracle_install.rsp
grep "DECLINE_SECURITY_UPDATES=" /ORACLE/database/response/oracle_install.rsp

#================
# Give oralce installation folder ownership to oracle. Give Read / Execute to files
#================
chown -R oracle:oinstall /ORACLE
chmod -R 755 /ORACLE

#================
# Switch user that will install oracle instance
#================
su - oracle

#================
# Check Oracle install Pre-requisites
#================
# The following will check whether your environment is good enough to install oracle instance.
# You must check log that oracle generate to see if there is critical errors that oracle can not continue install.
# Be aware that you do not have to satisfy all the Pre-requisites.
# You only need to satisfy requirement which is critical.
# Also At the end of each log, there are "INFO: Advice is blar blar". The one you are expecting is "INFO: Advice is CONTINUE" which is ready to install.
/ORACLE/database/runInstaller -silent -executePrereqs -responseFile /ORACLE/database/response/oracle_install.rsp

#================
# Run Installer (Silent Mode)
#================
# When you create oracle instance, listener, and database, you need to run as oracle user who has belongs to oper group
# Make sure your oracle user have oper group
# If there is no critical errors. It will display some warnings and give you log path.
# Where the path is within your oracle installation path, not /tmp
# Then "tail -f log_file" to see the installation process.
# When it finished install, it will give you the following orders that you must run as root.
# Ex). /ORACLE/oraInventory/orainstRoot.sh
# Ex). /ORACLE/product/11.2/db/root.sh
# run those command and Ctrl-c to get out of the tail and switch to oracle user "su - oracle"
/ORACLE/database/runInstaller -silent -responseFile /ORACLE/database/response/oracle_install.rsp

# When installation finished, run the following as root and switch back to oracle user
exit
/ORACLE/oraInventory/orainstRoot.sh
/ORACLE/product/11.2/db/root.sh
su - oracle

# If you connect database as sysdba, it will try to connect to $ORACLE_SID database.
# Since we set ORACLE_SID as ORADB, it will try to connect to ORADB. 
# There is no database yet, so it will say "ORACLE not available"
# if you are insterested to see the status, connect to as sysdba "sqlplus / as sysdba"

#================
# Create Listener (Silent Mode)
#================
cp /ORACLE/database/response/netca.rsp /ORACLE/database/response/oracle_netca.rsp 
netca /silent /responseFile /ORACLE/database/response/oracle_netca.rsp

# If you want to check whether listener is working, type "lsnrctl status"
# But Since there is no database, it will show some errors. But it's ok. We will create database After this.

#================
# Create Database (Silent Mode)
#================
# For Creating Database, I used template, not responsefile. You can also use responsefile if you want
# Also you can change those options in a way you want.
dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname ORADB -sid ORADB -sysDBAUserName sys -sysDBAPassword password -responseFile NO_VALUE -characterSet AL32UTF8 -memoryPercentage 20 -emConfiguration NONE


#================
# Connect to Database as sysdba
#================
sqlplus / as sysdba
# if it does not show anything like ORACLE not available". Then it's working.
# The Thing is, when you create database, oracle try to mount and open the database. 
# So If the database is created without errors, then the status should not be "not available"

