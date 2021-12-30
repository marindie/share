===========================
#apache2.4.25 설치 순서
===========================
# 설치 환경 Centos6.10
# 설치된 아파치가 있을시 제거
# rpm -qa | grep httpd
yum remove httpd

# 설치 패키지들
yum update
yum -y install gcc* cpp* compat-gcc* flex* openssl* apr* libjpeg* libpng* freetype* gd-* ncurses* libtermcap* libxml* curl-devel pcre-devel

# apache download url
# http://archive.apache.org/dist/httpd/

# apr download url
# https://apr.apache.org/download.cgi

# tomcat connector download url
# http://tomcat.apache.org/download-connectors.cgi

# tomcat native download url
# https://tomcat.apache.org/download-native.cgi

# 아래의 내용은 필요한 압축 파일들이 전부 존재 한다는 가정하에 진행한다
# 파일 목록  
# apr-1.6.3.tar.gz
# apr-util-1.6.1.tar.gz
# httpd-2.4.25.tar.gz
# jdk1.8.0_92.tar.gz
# tomcat-connectors-1.2.44-src.tar.gz
# tomcat-native-1.1.34-src.tar.gz

# 압축 해제 명령어
tar -zxvf apr-1.6.3.tar.gz
tar -zxvf apr-util-1.6.1.tar.gz
tar -zxvf httpd-2.4.25.tar.gz
tar -zxvf jdk-8u92-linux-x64.tar.gz
tar -zxvf tomcat-connectors-1.2.44-src.tar.gz
tar -zxvf tomcat-native-1.1.34-src.tar.gz

# apr 설치
cd apr-1.6.3
./configure --prefix=/usr/local/src/apr-1.6.3
make 
make install
cd ..

# apr-util 설치
cd apr-util-1.6.1
./configure --prefix=/usr/local/src/apr-util-1.6.1 --with-apr=/usr/local/src/apr-1.6.3
make 
make install
cd ..

# apache 설치
cd httpd-2.4.25
./configure --prefix=/svc/cds/web/apache2.4.25 --with-apr=/usr/local/src/apr-1.6.3 --with-apr-util=/usr/local/src/apr-util-1.6.1 
make
make install
cd ..

ln -s /svc/cds/web/apache2.4.25 /svc/cds/web/apache
# make 시 에러 혹은 다시 configure 하고 싶을때 make distclean 실행 (기존 configure 날려주는듯)

# ./apachectl start 하면 아래 에러 나오는데
# httpd.conf 파일에서 ServerName 주석 해제하고 localhost 로 변경하면 없어짐
# httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.0.1 for ServerName

# 포트 방화벽 해제 (apache는 7081, cdsSvr11 는 8009,9009, 9099, 80 은 그냥 열어두자)
#vi /etc/sysconfig/iptables
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 7081 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 9009 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 9099 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 8009 -j ACCEPT
service iptables save
service iptables restart

# conf 파일 복사 (NATEIFS_STG 에서 가져옴)
cp ./conf/httpd.conf /svc/cds/web/apache2.4.25/conf
cp ./conf/mod_jk.conf /svc/cds/web/apache2.4.25/conf
cp ./conf/workers.properties /svc/cds/web/apache2.4.25/conf

# mod_jk 설치 (tomcat 연동)
# http://tomcat.apache.org/download-connectors.cgi
cd tomcat-connectors-1.2.44-src/native
./configure --with-apxs=/svc/cds/web/apache2.4.25/bin/apxs
make
make install
cd ../..

mkdir -p /ifs_log/apache/
mkdir -p /ifs_log/batch_log/
mkdir -p /ifs_log/CDS_Simul_log/
mkdir -p /ifs_log/CONN/
mkdir -p /ifs_log/DAILY/
mkdir -p /ifs_log/FIFOQ/
mkdir -p /ifs_log/IFSENV/
mkdir -p /ifs_log/LOG/
mkdir -p /ifs_log/out/
mkdir -p /ifs_log/SaverRcvData/
mkdir -p /ifs_log/SYNCCHECKLOG/
mkdir -p /ifs_log/TIDSEQ/
mkdir -p /ifs_log/tomcat/
mkdir -p /ifs_log/UDPSOCK/
mkdir -p /svc/cds/web/apache/logs/error_logs/

========================
Tomcat 설치
========================
#############
# JAVA 설치
#############
mkdir -p /usr/java
mv jdk1.8.0_92 /usr/java
alternatives --install /usr/bin/jar jar /usr/java/jdk1.8.0_92/bin/jar 1
alternatives --install /usr/bin/java java /usr/java/jdk1.8.0_92/bin/java 1
alternatives --install /usr/bin/javac javac /usr/java/jdk1.8.0_92/bin/javac 1
chmod 777 /usr/java/jdk1.8.0_92/bin/*

#vi /etc/profile
##########
# JAVA
##########
#JAVA_HOME=/usr/java/jdk1.7.0_80
#JRE_HOME=/usr/java/jdk1.7.0_80/jre
#PATH=$PATH:JAVA_HOME/bin:JRE_HOME/bin
#export JAVA_HOME JRE_HOME PATH
sed -i'' -e "/# will prevent the need for merging in future updates./a ##########\n# JAVA\n##########\nJAVA_HOME=/usr/java/jdk1.8.0_92\nJRE_HOME=/usr/java/jdk1.8.0_92/jre\nPATH=\$PATH:JAVA_HOME/bin:JRE_HOME/bin\nexport JAVA_HOME JRE_HOME PATH" /etc/profile
source /etc/profile

##########################
# TOMCAT 폴더 복사 및 DB, LDAP 설정 변경 (([NATEIFS_STG 에서 가져옴]DB, LDAP 계정/암호는 동일하다고 가정)
##########################
cp -rp tomcat-7.0.73 /svc/cds/was/
ln -s /svc/cds/was/tomcat-7.0.73 /svc/cds/was/tomcat
cp -rp app /svc/cds/was/

# DB
sed -i'' -r -e "s/\(ADDRESS = \(PROTOCOL = TCP\)\(HOST = .*?\)\(PORT = .*?\)\)/\(ADDRESS = \(PROTOCOL = TCP\)\(HOST = 192\.168\.1\.204\)\(PORT = 1521\)\)/" /svc/cds/was/tomcat/cdsSvr11/conf/server.xml
sed -i'' -r -e "s/\(ADDRESS = \(PROTOCOL = TCP\)\(HOST = .*?\)\(PORT = .*?\)\)/\(ADDRESS = \(PROTOCOL = TCP\)\(HOST = 192\.168\.1\.204\)\(PORT = 1521\)\)/" /svc/cds/was/tomcat/cdsSvr12/conf/server.xml
sed -i'' -r -e "s/\(ADDRESS = \(PROTOCOL = TCP\)\(HOST = .*?\)\(PORT = .*?\)\)/\(ADDRESS = \(PROTOCOL = TCP\)\(HOST = 192\.168\.1\.204\)\(PORT = 1521\)\)/" /svc/cds/was/tomcat/glrSvr11/conf/server.xml
sed -i'' -r -e "s/\(ADDRESS = \(PROTOCOL = TCP\)\(HOST = .*?\)\(PORT = .*?\)\)/\(ADDRESS = \(PROTOCOL = TCP\)\(HOST = 192\.168\.1\.204\)\(PORT = 1521\)\)/" /svc/cds/was/tomcat/glrSvr12/conf/server.xml

sed -i'' -r -e "s/\(CONNECT_DATA =\(SERVICE_NAME = .*?\)\)/\(CONNECT_DATA =\(SERVICE_NAME = WIDEDEV\)\)/" /svc/cds/was/tomcat/cdsSvr11/conf/server.xml
sed -i'' -r -e "s/\(CONNECT_DATA =\(SERVICE_NAME = .*?\)\)/\(CONNECT_DATA =\(SERVICE_NAME = WIDEDEV\)\)/" /svc/cds/was/tomcat/cdsSvr12/conf/server.xml
sed -i'' -r -e "s/\(CONNECT_DATA =\(SERVICE_NAME = .*?\)\)/\(CONNECT_DATA =\(SERVICE_NAME = WIDEDEV\)\)/" /svc/cds/was/tomcat/glrSvr11/conf/server.xml
sed -i'' -r -e "s/\(CONNECT_DATA =\(SERVICE_NAME = .*?\)\)/\(CONNECT_DATA =\(SERVICE_NAME = WIDEDEV\)\)/" /svc/cds/was/tomcat/glrSvr12/conf/server.xml

# LDAP 
sed -i'' -r -e "s/profile.server.use=./profile\.server\.use=N/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc11.properties
sed -i'' -r -e "s/profile.server.profile1.ip=.*/profile\.server\.profile1\.ip=192\.168\.1\.205/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc11.properties
sed -i'' -r -e "s/ldap.server.STG_PRI.ip=.*/ldap\.server\.STG_PRI\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc11.properties

sed -i'' -r -e "s/profile.server.use=./profile\.server\.use=N/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc12.properties
sed -i'' -r -e "s/profile.server.profile1.ip=.*/profile\.server\.profile1\.ip=192\.168\.1\.205/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc12.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB.ip=.*/ldap\.server\.LDAP_TB\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc12.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB.port=.*/ldap\.server\.LDAP_TB\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc12.properties
sed -i'' -r -e "s/ldap.server.ldap_dev.ip=.*/ldap\.server\.ldap_dev\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc12.properties
sed -i'' -r -e "s/ldap.server.ldap_dev.port=.*/ldap\.server\.ldap_dev\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc12.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB_pub.ip=.*/ldap\.server\.LDAP_TB_pub\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc12.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB_pub.port=.*/ldap\.server\.LDAP_TB_pub\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc12.properties
sed -i'' -r -e "s/ldap.server.ldap_dev_pub.ip=.*/ldap\.server\.ldap_dev_pub\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc12.properties
sed -i'' -r -e "s/ldap.server.ldap_dev_pub.port=.*/ldap\.server\.ldap_dev_pub\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/cdssvc12.properties

sed -i'' -r -e "s/profile.server.use=./profile\.server\.use=N/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc11.properties
sed -i'' -r -e "s/profile.server.profile1.ip=.*/profile\.server\.profile1\.ip=192\.168\.1\.205/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc11.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB.ip=.*/ldap\.server\.LDAP_TB\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc11.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB.port=.*/ldap\.server\.LDAP_TB\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc11.properties
sed -i'' -r -e "s/ldap.server.ldap_dev.ip=.*/ldap\.server\.ldap_dev\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc11.properties
sed -i'' -r -e "s/ldap.server.ldap_dev.port=.*/ldap\.server\.ldap_dev\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc11.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB_pub.ip=.*/ldap\.server\.LDAP_TB_pub\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc11.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB_pub.port=.*/ldap\.server\.LDAP_TB_pub\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc11.properties
sed -i'' -r -e "s/ldap.server.ldap_dev_pub.ip=.*/ldap\.server\.ldap_dev_pub\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc11.properties
sed -i'' -r -e "s/ldap.server.ldap_dev_pub.port=.*/ldap\.server\.ldap_dev_pub\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc11.properties

sed -i'' -r -e "s/profile.server.use=./profile\.server\.use=N/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc12.properties
sed -i'' -r -e "s/profile.server.profile1.ip=.*/profile\.server\.profile1\.ip=192\.168\.1\.205/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc12.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB.ip=.*/ldap\.server\.LDAP_TB\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc12.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB.port=.*/ldap\.server\.LDAP_TB\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc12.properties
sed -i'' -r -e "s/ldap.server.ldap_dev.ip=.*/ldap\.server\.ldap_dev\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc12.properties
sed -i'' -r -e "s/ldap.server.ldap_dev.port=.*/ldap\.server\.ldap_dev\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc12.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB_pub.ip=.*/ldap\.server\.LDAP_TB_pub\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc12.properties
sed -i'' -r -e "s/ldap.server.LDAP_TB_pub.port=.*/ldap\.server\.LDAP_TB_pub\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc12.properties
sed -i'' -r -e "s/ldap.server.ldap_dev_pub.ip=.*/ldap\.server\.ldap_dev_pub\.ip=192\.168\.1\.203/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc12.properties
sed -i'' -r -e "s/ldap.server.ldap_dev_pub.port=.*/ldap\.server\.ldap_dev_pub\.port=7050/" /svc/cds/was/app/cdsWebApp/WEB-INF/conf/glrsvc12.properties


#############
# tomcat native 다운로드 및 설치
# https://tomcat.apache.org/download-native.cgi
#############
cd tomcat-native-1.1.34-src/jni/native
./configure --prefix=/svc/cds/was/tomcat --with-apr=/usr/local/src/apr-1.6.3 --with-java-home=$JAVA_HOME
make
make install
cd ../../..

#############
# 폴더 및 파일 생성
#############
mkdir -p /svc/cds/web/app/cdsWebApp
mkdir -p /svc/cds/was/tomcat/logs/log/cdsSvr11/
mkdir -p /svc/cds/was/tomcat/logs/log/cdsSvr12/
mkdir -p /svc/cds/was/tomcat/logs/log/glrSvr11/
mkdir -p /svc/cds/was/tomcat/logs/log/glrSvr12/
mkdir -p /svc/cds/was/tomcat/logs/log/cdsSvr11/backup/
mkdir -p /svc/cds/was/tomcat/logs/log/cdsSvr12/backup/
mkdir -p /svc/cds/was/tomcat/logs/log/glrSvr11/backup/
mkdir -p /svc/cds/was/tomcat/logs/log/glrSvr12/backup/
mkdir -p /svc/cds/was/tomcat/logs/gclog/cdsSvr11
mkdir -p /svc/cds/was/tomcat/logs/gclog/cdsSvr12
mkdir -p /svc/cds/was/tomcat/logs/gclog/glrSvr11
mkdir -p /svc/cds/was/tomcat/logs/gclog/glrSvr12
mkdir -p /svc/cds/was/tomcat/logs/gclog/cdsSvr11/backup
mkdir -p /svc/cds/was/tomcat/logs/gclog/cdsSvr12/backup
mkdir -p /svc/cds/was/tomcat/logs/gclog/glrSvr11/backup
mkdir -p /svc/cds/was/tomcat/logs/gclog/glrSvr12/backup

touch /svc/cds/was/tomcat/logs/log/cdsSvr11/cdsSvr11.out
touch /svc/cds/was/tomcat/logs/log/cdsSvr12/cdsSvr12.out
touch /svc/cds/was/tomcat/logs/log/glrSvr11/glrSvr11.out
touch /svc/cds/was/tomcat/logs/log/glrSvr12/glrSvr12.out

touch /svc/cds/was/tomcat/logs/gclog/cdsSvr11/cdsSvr11-gc.log
touch /svc/cds/was/tomcat/logs/gclog/cdsSvr11/cdsSvr12-gc.log
touch /svc/cds/was/tomcat/logs/gclog/cdsSvr11/glrSvr11-gc.log
touch /svc/cds/was/tomcat/logs/gclog/cdsSvr11/glrSvr12-gc.log

mkdir -p /ifs_log/tomcat/cdsWebApplogs && touch /ifs_log/tomcat/cdsWebApplogs/TUPALL.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/STATUSCHECK.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPCUSTCHILDDEL.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPCUSTREG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPLIMITREG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPADMDEVICECHG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPMINCHG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPMULTINUMDEL.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPCUSTDELCAN.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPOPMDDEL.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPCHGPLUSDEL.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPADDSVC.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPOPMDDELCAN.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPGLR.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/AsfsDuplicationCheck.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPCUSTDEL.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPCUSTCHILDREG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPCHRGCHG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPASFSADDSVC.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPGLRRETRY.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPUSIMCHG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPGLRRECOVERY.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPNAMECHG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPMULTINUMREG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPDEVICECHG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPCUSTPAUSE.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPOPMDREG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPCHGPLUSREG.log
mkdir -p /ifs_log/tomcat/cdsWebApplogs/ && touch /ifs_log/tomcat/cdsWebApplogs/TUPOPMDPAUSE.log

chown -R nate:users /svc
chown -R nate:users /ifs_log
chmod -R 755 /svc

# Apache 기동
/svc/cds/web/apache/bin/apachectl start

# Tomcat 기동
su - nate
/svc/cds/was/tomcat/bin/start_cdsSvr11.sh

netstat -lnpt
ps -ef | grep httpd
ps -ef | grep tomcat
cat /svc/cds/was/tomcat/logs/log/cdsSvr11/cdsSvr11.out





