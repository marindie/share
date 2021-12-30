# ORACLE Databae Client 11.2.0.1 DOWNLOAD
# http://www.oracle.com/technetwork/database/enterprise-edition/downloads/112010-linx8664soft-100572.html

# NATEIFS_STG 은 Oracle Database Client 로 설치해서 사용중
# /home/oracle/client 에 있음
# runInstaller 로 설치하면 ORACLE_HOME 과 같은 환경 변수의 경로에 설치 파일들이 깔린다.

#====================
# Add Group
#====================
groupadd oinstall
groupadd dba
useradd -m -d /home/oracle -g oinstall -G dba -s /bin/bash oracle
passwd oracle

#====================
# Create Directory
#====================
/home/oracle/app/product/11.2.0.4/client_1

#====================
# Install Package
#====================
yum -y install unixODBC binutils* compat* gcc* glibc* ksh libgcc* libstdc* libaio* make* sysstat*
# binutils-2.20.51.0.2-5.36.el6 (x86_64) 
# compat-libcap1-1.10-1 (x86_64) 
# compat-libstdc++-33-3.2.3-69.el6 (x86_64) 
# compat-libstdc++-33-3.2.3-69.el6 (i686) 
# gcc-4.4.7-4.el6 (x86_64) 
# gcc-c++-4.4.7-4.el6 (x86_64) 
# glibc-2.12-1.132.el6 (i686) 
# glibc-2.12-1.132.el6 (x86_64) 
# glibc-devel-2.12-1.132.el6 (x86_64) 
# glibc-devel-2.12-1.132.el6 (i686) 
# ksh 
# libgcc-4.4.7-4.el6 (i686) 
# libgcc-4.4.7-4.el6 (x86_64) 
# libstdc++-4.4.7-4.el6 (x86_64) 
# libstdc++-4.4.7-4.el6 (i686) 
# libstdc++-devel-4.4.7-4.el6 (x86_64) 
# libstdc++-devel-4.4.7-4.el6 (i686) 
# libaio-0.3.107-10.el6 (x86_64) 
# libaio-0.3.107-10.el6 (i686) 
# libaio-devel-0.3.107-10.el6 (x86_64) 
# libaio-devel-0.3.107-10.el6 (i686) 
# make-3.81-20.el6
# sysstat-9.0.4-22.el6 (x86_64)

vi /etc/profile
export TMP=/tmp
export TMPDIR=/tmp
export ORACLE_BASE=/home/oracle/app
export ORACLE_SID=WIDEDEV
export ORACLE_HOME=${ORACLE_BASE}/product/11.2.0.4/client_1
export TNS_ADMIN=${ORACLE_BASE}/product/11.2.0.4/client_1/network/admin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:${LD_LIBRARY_PATH}
export PATH=$ORACLE_HOME/bin:${PATH}
export SQLPATH=$ORACLE_HOME:${SQLPATH}
export NLS_LANG=KOREAN_KOREA.KO16MSWIN949

# 반드시 ORACLE_BASE 경로에 있을 필요는 없음.
unzip -q linux_11gR2_client_x86_64.zip -d /home/oracle
chown -R oracle:dba /home/oracle

su - oracle
cp /home/oracle/client/response/client_install.rsp /home/oracle/client/response/client_nate_install.rsp 
sed -i'' -r -e "s/^UNIX_GROUP_NAME=.*/UNIX_GROUP_NAME=dba/" /home/oracle/client/response/client_nate_install.rsp
sed -i'' -r -e "s/^INVENTORY_LOCATION=.*/INVENTORY_LOCATION=\/home\/oracle\/app\/oraInventory/" /home/oracle/client/response/client_nate_install.rsp
sed -i'' -r -e "s/^SELECTED_LANGUAGES=.*/SELECTED_LANGUAGES=en,ko/" /home/oracle/client/response/client_nate_install.rsp
sed -i'' -r -e "s/^ORACLE_HOME=.*/ORACLE_HOME=\/home\/oracle\/app\/product\/11.2.0.4\/client_1/" /home/oracle/client/response/client_nate_install.rsp
sed -i'' -r -e "s/^ORACLE_BASE=.*/ORACLE_BASE=\/home\/oracle\/app/" /home/oracle/client/response/client_nate_install.rsp
sed -i'' -r -e "s/^oracle.install.client.installType=.*/oracle\.install\.client\.installType=Administrator/" /home/oracle/client/response/client_nate_install.rsp

grep "^UNIX_GROUP_NAME=" /home/oracle/client/response/client_nate_install.rsp 
grep "^INVENTORY_LOCATION=" /home/oracle/client/response/client_nate_install.rsp 
grep "^SELECTED_LANGUAGES=" /home/oracle/client/response/client_nate_install.rsp 
grep "^ORACLE_HOME=" /home/oracle/client/response/client_nate_install.rsp 
grep "^ORACLE_BASE=" /home/oracle/client/response/client_nate_install.rsp 
grep "^oracle.install.client.installType=" /home/oracle/client/response/client_nate_install.rsp 

# 설치전 내용 검사
/home/oracle/client/runInstaller -silent -executePrereqs -responseFile /home/oracle/client/response/client_nate_install.rsp

# 설치 시작
/home/oracle/client/runInstaller -silent -responseFile /home/oracle/client/response/client_nate_install.rsp

# 설치 완료 후 root 로 실행 해야 할 녀석들
/home/oracle/app/oraInventory/orainstRoot.sh
/home/oracle/app/product/11.2.0.4/client_1/root.sh
cp tnsnames.ora $ORACLE_HOME/network/admin
