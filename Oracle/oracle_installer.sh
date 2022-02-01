#==============
# 이미지로 OS 설치시 반드시 swap 메모리 사이즈 확인 할것. 만들때 4G로 했더니 SWAP 도 4G 이상 요구되었음
# root user start
# Locale Change 
#=============
sed -i'' -e "s/UTF-8/eucKR/" /etc/sysconfig/i18n
sed -i'' -e "\$a\export LANG=\"ko_KR.eucKR\"" /etc/profile
source /etc/sysconfig/i18n

#=============
# HOST ADD
#=============
sed -i'' -e "\$a\192.168.1.204 uapdb" /etc/hosts

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
useradd -m -d /home/oraUAP -g oinstall -G dba,oper oraUAP
echo "wideps1!" | passwd oraUAP --stdin

#==============
# Change Privilege
#==============
mkdir -p /ORACLE/product/11.2/uapdb
mkdir -p /ORACLE/oradata/WIDEDEV # 테이블 스페이스 저장 폴더용
mkdir -p /ORACLE/oradata/GWIDEDEV # 테이블 스페이스 저장 폴더용

#===========================
#/home/oraUAP/.bash_profile 
#===========================
sed -i'' -r -e "/^# User specific environment and startup programs/a\export ORACLE_BASE=\/ORACLE\nexport ORACLE_HOME=\$ORACLE_BASE\/product\/11.2\/uapdb\nexport ORACLE_SID=WIDEDEV\nexport ORACLE_TERM=xterm\nexport PATH=\/usr\/sbin:\$PATH\nexport PATH=\$PATH:\$ORACLE_HOME\/bin\nexport LD_LIBRARY_PATH=\$ORACLE_HOME\/lib:\/lib:\/usr\/lib:\/usr\/local\/lib\nexport CLASSPATH=$ORACLE_HOME\/JRE:$ORACLE_HOME\/jlib:$ORACLE_HOME\/rdbms\/jlib\nexport NLS_LANG=KOREAN_KOREA.KO16MSWIN949\n" /home/oraUAP/.bash_profile

#==============
# Oracle Installer Start
#==============
unzip -q linux.x64_11gR2_database_1of2.zip -d /ORACLE
unzip -q linux.x64_11gR2_database_2of2.zip -d /ORACLE

#=================
# kernel Parameter Setting
# =================
sed -i'' -e "\$a\kernel.sem = 250 32000 100 128\nfs.file-max = 6815744\nnet.ipv4.ip_local_port_range = 9000 65500\nnet.core.rmem_default = 262144\nnet.core.rmem_max = 4194304\nnet.core.wmem_default = 262144\nnet.core.wmem_max = 1048586\nfs.aio-max-nr = 1048576" /etc/sysctl.conf
sysctl -p

#================= 
# USER RESOURCE LIMIT Setting
#=================
sed -i'' -e "\$a\# Parameter for SKT\n*               soft    nofile          8192\n*               hard    nofile          65536\n*               soft    nproc           8192\n*               hard    nproc           16384\n*               soft    core            20480\n" /etc/security/limits.conf

#=======================
# INSTALL RESPONSE 파일 수정
#=======================
cp /ORACLE/database/response/db_install.rsp /ORACLE/database/response/uapdb_install.rsp
sed -i'' -r -e "s/^oracle.install.option=.*/oracle\.install\.option=INSTALL_DB_SWONLY/" /ORACLE/database/response/uapdb_install.rsp
sed -i'' -r -e "s/^UNIX_GROUP_NAME=.*/UNIX_GROUP_NAME=oinstall/" /ORACLE/database/response/uapdb_install.rsp
sed -i'' -r -e "s/^INVENTORY_LOCATION=.*/INVENTORY_LOCATION=\/ORACLE\/oraInventory/" /ORACLE/database/response/uapdb_install.rsp
sed -i'' -r -e "s/^SELECTED_LANGUAGES=.*/SELECTED_LANGUAGES=en,ko/" /ORACLE/database/response/uapdb_install.rsp
sed -i'' -r -e "s/^ORACLE_HOME=.*/ORACLE_HOME=\/ORACLE\/product\/11.2\/uapdb/" /ORACLE/database/response/uapdb_install.rsp
sed -i'' -r -e "s/^ORACLE_BASE=.*/ORACLE_BASE=\/ORACLE/" /ORACLE/database/response/uapdb_install.rsp
sed -i'' -r -e "s/^oracle.install.db.InstallEdition=.*/oracle\.install\.db\.InstallEdition=EE/" /ORACLE/database/response/uapdb_install.rsp
sed -i'' -r -e "s/^oracle.install.db.DBA_GROUP=.*/oracle\.install\.db\.DBA_GROUP=dba/" /ORACLE/database/response/uapdb_install.rsp
sed -i'' -r -e "s/^oracle.install.db.OPER_GROUP=.*/oracle\.install\.db\.OPER_GROUP=oper/" /ORACLE/database/response/uapdb_install.rsp
sed -i'' -r -e "s/^DECLINE_SECURITY_UPDATES=.*/DECLINE_SECURITY_UPDATES=true/" /ORACLE/database/response/uapdb_install.rsp

grep "^oracle.install.option=" /ORACLE/database/response/uapdb_install.rsp
grep "^UNIX_GROUP_NAME=" /ORACLE/database/response/uapdb_install.rsp
grep "^INVENTORY_LOCATION=" /ORACLE/database/response/uapdb_install.rsp
grep "^SELECTED_LANGUAGES=" /ORACLE/database/response/uapdb_install.rsp
grep "^UNIX_GROUP_NAME=" /ORACLE/database/response/uapdb_install.rsp
grep "^ORACLE_HOME=" /ORACLE/database/response/uapdb_install.rsp
grep "^ORACLE_BASE=" /ORACLE/database/response/uapdb_install.rsp
grep "^oracle.install.db.InstallEdition=" /ORACLE/database/response/uapdb_install.rsp
grep "^oracle.install.db.DBA_GROUP=" /ORACLE/database/response/uapdb_install.rsp
grep "^oracle.install.db.OPER_GROUP=" /ORACLE/database/response/uapdb_install.rsp
grep "^DECLINE_SECURITY_UPDATES=" /ORACLE/database/response/uapdb_install.rsp

chown -R oraUAP:oinstall /ORACLE
chmod -R 755 /ORACLE

#=================
# oraUAP From Here
#=================
su - oraUAP

# /ORACLE/database/runInstaller -silent -executePrereqs -responseFile /ORACLE/database/response/uapdb_install.rsp
# 해당 결과 log를 보면서 에러가 없는지 확인.
# 마지막 로그 밑에 "INFO: Advice is CONTINUE" 와 같은 형태로 Advice 결과가 나옴. CONTINUE 이면 설치 진행 가능
/ORACLE/database/runInstaller -silent -responseFile /ORACLE/database/response/uapdb_install.rsp

#=================
# 새로운 창 열어서 아래거 실행
#=================
exit
/ORACLE/oraInventory/orainstRoot.sh
/ORACLE/product/11.2/uapdb/root.sh
chown -R oraUAP:oinstall /ORACLE
chmod -R 755 /ORACLE

su - oraUAP

#=================
# Create Listener
#=================
cp /ORACLE/database/response/netca.rsp /ORACLE/database/response/uapdb_netca.rsp
netca /silent /responseFile /ORACLE/database/response/uapdb_netca.rsp

#=================
# DB 실행 준비 (oraUAP 계정)
#=================
cp -rp exp /home/oraUAP
chown -R oraUAP:oinstall /home/oraUAP
chmod 777 /home/oraUAP/exp

# ./createDB.sh 실행시 command not found 9 와 같은 에러와 함께 실행이 된다.
# 이러면 UTF-8 파일이 eucKR 로 넘어오면서 깨진것이니 해당 파일 삭제 후 vi로 새로 복사해서 넣자
