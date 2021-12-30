#/bin/bash
OLD_WEB_DOC="/web/apache2.2.31/htdocs/portal"
NEW_WEB_DOC="/web/apache2.2.31/htdocs/gaebal_portal"
WEB_BIN="/web/apache2.2.31/bin"
WEB_CONF="/web/apache2.2.31/conf"
OLD_WAS_DEFAULT="/was/upwas/WebApp/PORTAL"
NEW_WAS_DEFAULT="/was/upwas/WebApp/GAEBAL_PORTAL"
WAS_MAIN="/was/weblogic1036/domains/updomain"
WAS_COM_CONF="/was/upwas/WebApp/COMMON/conf"
NEW_LOG_WEB="/logs/web/gaebal_portal"
NEW_LOG_WAS="/logs/was/gaebal_portal"
###############
# Web 처리
###############

#방화벽 처리
#sudo iptables -I INPUT 1 -p tcp --dport 445 -j ACCEPT
#sudo service iptables save
#sudo service iptables restart

#파일, 폴더 선처리 되어야 할 부분 처리
#WEB 소스 복사
cp -r ${OLD_WEB_DOC} ${NEW_WEB_DOC}
cp -v ${WEB_BIN}/apachectl_96_portal ${WEB_BIN}/apachectl_100_portal
echo "22222" > ${WEB_BIN}/httpd_100.pid
cp -v ${WEB_CONF}/httpd_96.conf ${WEB_CONF}/httpd_100.conf
cp -v ${WEB_CONF}/ssl_96.conf ${WEB_CONF}/ssl_100.conf
#없는 폴더 생성
if [ ! -d "${NEW_LOG_WEB}" ]; then
        mkdir -v ${NEW_LOG_WEB}
        mkdir -v ${NEW_LOG_WEB}/access
        mkdir -v ${NEW_LOG_WEB}/error
fi
cp -r ${OLD_WAS_DEFAULT} ${NEW_WAS_DEFAULT}
cp -v ${WAS_MAIN}/startM8030_J.sh ${WAS_MAIN}/startM8033_J.sh
cp -v ${WAS_MAIN}/viewM8030.sh ${WAS_MAIN}/viewM8033.sh 
cp -v ${WAS_MAIN}/stopM8030.sh ${WAS_MAIN}/stopM8033.sh
cp -v ${WAS_MAIN}/bin/startManagedWebLogic8030.sh ${WAS_MAIN}/bin/startManagedWebLogic8033.sh
cp -v ${WAS_COM_CONF}/ldapdev.properties ${WAS_COM_CONF}/gaebal_ldapdev.properties
cp -v ${WAS_COM_CONF}/portal.properties ${WAS_COM_CONF}/gaebal_portal.properties
#없는 폴더 및 파일 생성
if [ ! -d "${NEW_LOG_WAS}" ]; then
        mkdir -v ${NEW_LOG_WAS}
fi
if [ ! -d "${WAS_MAIN}/logs/gaebal_uapsPortal" ]; then
        mkdir -v ${WAS_MAIN}/logs/gaebal_uapsPortal
        touch ${WAS_MAIN}/logs/gaebal_uapsPortal/nohup_gaebal_uapsPortal.out
        touch ${WAS_MAIN}/logs/gaebal_uapsPortal/gaebal_uapsPortal_gc.log
else 
        if [ ! -f "${WAS_MAIN}/logs/gaebal_uapsPortal/nohup_gaebal_uapsPortal.out" ]; then
                touch ${WAS_MAIN}/logs/gaebal_uapsPortal/nohup_gaebal_uapsPortal.out
        fi
        if [ ! -f "${WAS_MAIN}/logs/gaebal_uapsPortal/gaebal_uapsPortal_gc.log" ]; then
                touch ${WAS_MAIN}/logs/gaebal_uapsPortal/gaebal_uapsPortal_gc.log
        fi
fi


#바꿀것들 리스트 
echo
echo "=========================="
echo "===== Before Change ======"
echo "=========================="
grep "HTTPD='\/web\/apache2.2.31\/bin\/httpd -f \/web\/apache2.2.31\/conf\/httpd_96.conf'" ${WEB_BIN}/apachectl_100_portal
grep "^DocumentRoot \"/web/apache2.2.25/htdocs/portal\"" ${WEB_CONF}/httpd_100.conf
grep "^<Directory \"\/web\/apache2.2.25\/htdocs\/gaebal_portal\">" ${WEB_CONF}/httpd_100.conf
grep "^Listen 96" ${WEB_CONF}/httpd_100.conf
grep "^ServerName .*96" ${WEB_CONF}/httpd_100.conf
grep "ErrorLog \"|/web/apache2.2.25/bin/rotatelogs /logs/web/portal/error/error_log.%Y%m%d 96400\"" ${WEB_CONF}/httpd_100.conf
grep "CustomLog \"|/web/apache2.2.25/bin/rotatelogs -l /logs/web/portal/access/access_log.%Y%m%d%H 3600" ${WEB_CONF}/httpd_100.conf
grep "PidFile    /web/apache2.2.25/bin/httpd_96.pid" ${WEB_CONF}/httpd_100.conf
grep "Include /web/apache2.2.25/conf/ssl_96.conf" ${WEB_CONF}/httpd_100.conf
grep "^Listen 443" ${WEB_CONF}/ssl_100.conf
grep "           WebLogicPort 8030" ${WEB_CONF}/ssl_100.conf
grep "SERVER_NAME=uapsPortal" ${WAS_MAIN}/startM8033_J.sh
grep "SERVER_PORT=8030" ${WAS_MAIN}/startM8033_J.sh
grep "USER_MEM_ARGS=\"-DLDAPDEV=/was/upwas/WebApp/COMMON/conf/ldapdev.properties\"" ${WAS_MAIN}/startM8033_J.sh
grep "USER_MEM_ARGS=.* -DPORTAL_CONF=/was/upwas/WebApp/PORTAL/WEB-INF/conf/uaps_portal.properties" ${WAS_MAIN}/startM8033_J.sh
grep "USER_MEM_ARGS=.* -DUPPROP=/was/upwas/WebApp/COMMON/conf/portal.properties" ${WAS_MAIN}/startM8033_J.sh
grep "^nohup .*/bin/startManagedWebLogic8030.sh" ${WAS_MAIN}/startM8033_J.sh
grep "viewM8030" ${WAS_MAIN}/startM8033_J.sh
grep "tail -f .*/uapsPortal/nohup_uapsPortal.out" ${WAS_MAIN}/viewM8033.sh
grep "echo \"uapsPortal(8030) Stopping...\"" ${WAS_MAIN}/stopM8033.sh
grep "java weblogic.Admin -url t3://localhost:7050 -username weblogic -password nate_zzang FORCESHUTDOWN uapsPortal" ${WAS_MAIN}/stopM8033.sh
grep "/PORTAL" ${WAS_MAIN}/bin/startManagedWebLogic8033.sh
grep "/uaps.properties" ${WAS_MAIN}/bin/startManagedWebLogic8033.sh
grep "^ldap.server.bundang.ip=" ${WAS_COM_CONF}/gaebal_ldapdev.properties
grep "^ldap.server.bundang.port=" ${WAS_COM_CONF}/gaebal_ldapdev.properties
grep "^proc.name=uapsPortal" ${WAS_COM_CONF}/gaebal_portal.properties
grep "^service.name=uapsPortal" ${WAS_COM_CONF}/gaebal_portal.properties
grep "^ldap.server.WIDE.ip=" ${WAS_COM_CONF}/gaebal_portal.properties
grep "^ldap.server.WIDE.port=" ${WAS_COM_CONF}/gaebal_portal.properties
grep "portal" ${NEW_WAS_DEFAULT}/WEB-INF/conf/log4j.properties

#변경 명령어 리스트
sed -i "s/^HTTPD='\/web\/apache2.2.31\/bin\/httpd -f \/web\/apache2.2.31\/conf\/httpd_96.conf'/HTTPD='\/web\/apache2.2.31\/bin\/httpd -f \/web\/apache2.2.31\/conf\/httpd_100.conf'/" ${WEB_BIN}/apachectl_100_portal
sed -i "s/^DocumentRoot \"\/web\/apache2.2.25\/htdocs\/portal\"/DocumentRoot \"\/web\/apache2.2.25\/htdocs\/gaebal_portal\"/" ${WEB_CONF}/httpd_100.conf
sed -i "s/^<Directory \"\/web\/apache2.2.25\/htdocs\/portal\">/<Directory \"\/web\/apache2.2.25\/htdocs\/gaebal_portal\">/" ${WEB_CONF}/httpd_100.conf
sed -i "s/^Listen 96/Listen 100/" ${WEB_CONF}/httpd_100.conf
sed -i "s/^ServerName \${SERVER_IP}:96/ServerName \${SERVER_IP}:100/" ${WEB_CONF}/httpd_100.conf
sed -i "s/ErrorLog \"|\/web\/apache2.2.25\/bin\/rotatelogs \/logs\/web\/portal\/error\/error_log.%Y%m%d 96400\"/ErrorLog \"|\/web\/apache2.2.25\/bin\/rotatelogs \/logs\/web\/gaebal_portal\/error\/error_log.%Y%m%d 96400\"/" ${WEB_CONF}/httpd_100.conf
sed -i "s/CustomLog \"|\/web\/apache2.2.25\/bin\/rotatelogs -l \/logs\/web\/portal\/access\/access_log.%Y%m%d%H 3600\"/CustomLog \"|\/web\/apache2.2.25\/bin\/rotatelogs -l \/logs\/web\/gaebal_portal\/access\/access_log.%Y%m%d%H 3600\"/" ${WEB_CONF}/httpd_100.conf
sed -i "s/PidFile    \/web\/apache2.2.25\/bin\/httpd_96.pid/PidFile    \/web\/apache2.2.25\/bin\/httpd_100.pid/" ${WEB_CONF}/httpd_100.conf
sed -i "s/^Include \/web\/apache2.2.25\/conf\/ssl_96.conf/Include \/web\/apache2.2.25\/conf\/ssl_100.conf/" ${WEB_CONF}/httpd_100.conf
sed -i "s/^Listen 443/Listen 445/" ${WEB_CONF}/ssl_100.conf
sed -i "s/           WebLogicPort 8030/           WebLogicPort 8033/" ${WEB_CONF}/ssl_100.conf
sed -i "s/SERVER_NAME=uapsPortal/SERVER_NAME=gaebal_uapsPortal/" ${WAS_MAIN}/startM8033_J.sh
sed -i "s/SERVER_PORT=8030/SERVER_PORT=8033/" ${WAS_MAIN}/startM8033_J.sh
sed -i "s/USER_MEM_ARGS=\"-DLDAPDEV=\/was\/upwas\/WebApp\/COMMON\/conf\/ldapdev.properties\"/USER_MEM_ARGS=\"-DLDAPDEV=\/was\/upwas\/WebApp\/COMMON\/conf\/gaebal_ldapdev.properties\"/" ${WAS_MAIN}/startM8033_J.sh
sed -i'' -e "s/USER_MEM_ARGS=\(.*\) -DPORTAL_CONF=\/was\/upwas\/WebApp\/PORTAL\/WEB-INF\/conf\/uaps_portal.properties/USER_MEM_ARGS=\1 -DPORTAL_CONF=\/was\/upwas\/WebApp\/GAEBAL_PORTAL\/WEB-INF\/conf\/uaps_portal.properties/" ${WAS_MAIN}/startM8033_J.sh
sed -i'' -e "s/USER_MEM_ARGS=\(.*\) -DUPPROP=\/was\/upwas\/WebApp\/COMMON\/conf\/portal.properties/USER_MEM_ARGS=\1 -DUPPROP=\/was\/upwas\/WebApp\/COMMON\/conf\/gaebal_portal.properties/" ${WAS_MAIN}/startM8033_J.sh
sed -i'' -e "/DUPPROP/a USER_MEM_ARGS=\"\$\{USER_MEM_ARGS\} -Dlog4j\.configuration=file:\/was\/upwas\/WebApp\/GAEBAL_PORTAL\/WEB-INF\/conf\/log4j\.properties\"" ${WAS_MAIN}/startM8033_J.sh
sed -i'' -e "s/^nohup \(.*\)\/bin\/startManagedWebLogic8030.sh/nohup \1\/bin\/startManagedWebLogic8033.sh/" ${WAS_MAIN}/startM8033_J.sh
sed -i "s/viewM8030/viewM8033/" ${WAS_MAIN}/startM8033_J.sh
sed -i'' -e "s/tail -f \(.*\)\/uapsPortal\/nohup_uapsPortal.out/tail -f \1\/gaebal_uapsPortal\/nohup_gaebal_uapsPortal.out/" ${WAS_MAIN}/viewM8033.sh 
sed -i "s/echo \"uapsPortal(8030) Stopping...\"/echo \"gaebal_uapsPortal(8033) Stopping...\"/" ${WAS_MAIN}/stopM8033.sh
sed -i "s/java weblogic.Admin -url t3:\/\/localhost:7050 -username weblogic -password nate_zzang FORCESHUTDOWN uapsPortal/java weblogic.Admin -url t3:\/\/localhost:7050 -username weblogic -password nate_zzang FORCESHUTDOWN gaebal_uapsPortal/" ${WAS_MAIN}/stopM8033.sh
sed -i "s/\/PORTAL/\/GAEBAL_PORTAL/g" ${WAS_MAIN}/bin/startManagedWebLogic8033.sh
sed -i "s/\/uaps.properties/\/gaebal_uaps.properties/g" ${WAS_MAIN}/bin/startManagedWebLogic8033.sh
sed -i "s/^ldap.server.bundang.ip=.*/ldap.server.bundang.ip=192.168.1.203/" ${WAS_COM_CONF}/gaebal_ldapdev.properties
sed -i "s/^ldap.server.bundang.port=.*/ldap.server.bundang.port=7070/" ${WAS_COM_CONF}/gaebal_ldapdev.properties
echo "uapisdev.gaebal_uapsPortal.bind.dn=webadmin1
uapisdev.gaebal_uapsPortal.bind.pw=wjdwebadmin66
uapisdev.gaebal_uapsPortal.min=2
uapisdev.gaebal_uapsPortal.max=10
uapisdev.gaebal_uapsPortal.retry.count=4
uapisdev.gaebal_uapsPortal.retry.time=3000
uapisdev.gaebal_uapsPortal.response.time=10000
uapisdev.gaebal_uapsPortal.connection.timeout=1000" >> ${WAS_COM_CONF}/gaebal_ldapdev.properties
sed -i "s/^proc.name=uapsPortal/proc.name=gaebal_uapsPortal/" ${WAS_COM_CONF}/gaebal_portal.properties
sed -i "s/^service.name=uapsPortal/service.name=gaebal_uapsPortal/" ${WAS_COM_CONF}/gaebal_portal.properties
sed -i "s/^ldap.server.WIDE.ip=.*/ldap.server.WIDE.ip=192.168.1.203/" ${WAS_COM_CONF}/gaebal_portal.properties
sed -i "s/^ldap.server.WIDE.port=.*/ldap.server.WIDE.port=7070/" ${WAS_COM_CONF}/gaebal_portal.properties
echo "uapisdev.gaebal_uapsPortal.bind.dn=webadmin1
uapisdev.gaebal_uapsPortal.bind.pw=wjdwebadmin66
uapisdev.gaebal_uapsPortal.min=2
uapisdev.gaebal_uapsPortal.max=10
uapisdev.gaebal_uapsPortal.retry.count=4
uapisdev.gaebal_uapsPortal.retry.time=3000
uapisdev.gaebal_uapsPortal.response.time=10000
uapisdev.gaebal_uapsPortal.connection.timeout=1000" >> ${WAS_COM_CONF}/ldap.properties
sed -i "s/\/portal\//\/gaebal_portal\//g" ${NEW_WAS_DEFAULT}/WEB-INF/conf/log4j.properties

#변경 확인 리스트
echo
echo
echo "================================="
echo "===== After Change and Add ======"
echo "================================="
grep "HTTPD='\/web\/apache2.2.31\/bin\/httpd -f \/web\/apache2.2.31\/conf\/httpd_100.conf'" ${WEB_BIN}/apachectl_100_portal
grep "^DocumentRoot \"/web/apache2.2.25/htdocs/gaebal_portal\"" ${WEB_CONF}/httpd_100.conf
grep "^<Directory \"\/web\/apache2.2.25\/htdocs\/gaebal_portal\">" ${WEB_CONF}/httpd_100.conf
grep "^Listen 100" ${WEB_CONF}/httpd_100.conf
grep "^ServerName .*100" ${WEB_CONF}/httpd_100.conf
grep "ErrorLog \"|/web/apache2.2.25/bin/rotatelogs /logs/web/gaebal_portal/error/error_log.%Y%m%d 96400" ${WEB_CONF}/httpd_100.conf
grep "CustomLog \"|/web/apache2.2.25/bin/rotatelogs -l /logs/web/gaebal_portal/access/access_log.%Y%m%d%H 3600" ${WEB_CONF}/httpd_100.conf
grep "PidFile    /web/apache2.2.25/bin/httpd_100.pid" ${WEB_CONF}/httpd_100.conf
grep "Include /web/apache2.2.25/conf/ssl_100.conf" ${WEB_CONF}/httpd_100.conf
grep "^Listen 445" ${WEB_CONF}/ssl_100.conf
grep "           WebLogicPort 8033" ${WEB_CONF}/ssl_100.conf
grep "SERVER_NAME=gaebal_uapsPortal" ${WAS_MAIN}/startM8033_J.sh
grep "SERVER_PORT=8033" ${WAS_MAIN}/startM8033_J.sh
grep "USER_MEM_ARGS=\"-DLDAPDEV=/was/upwas/WebApp/COMMON/conf/gaebal_ldapdev.properties\"" ${WAS_MAIN}/startM8033_J.sh
grep "USER_MEM_ARGS=.* -DPORTAL_CONF=/was/upwas/WebApp/GAEBAL_PORTAL/WEB-INF/conf/uaps_portal.properties" ${WAS_MAIN}/startM8033_J.sh
grep "USER_MEM_ARGS=.* -DUPPROP=/was/upwas/WebApp/COMMON/conf/gaebal_portal.properties" ${WAS_MAIN}/startM8033_J.sh
grep "USER_MEM_ARGS=.* -Dlog4j.configuration=file:/was/upwas/WebApp/GAEBAL_PORTAL/WEB-INF/conf/log4j.properties" ${WAS_MAIN}/startM8033_J.sh
grep "^nohup .*/bin/startManagedWebLogic8033.sh" ${WAS_MAIN}/startM8033_J.sh
grep "viewM8033" ${WAS_MAIN}/startM8033_J.sh
grep "tail -f .*/gaebal_uapsPortal/nohup_gaebal_uapsPortal.out" ${WAS_MAIN}/viewM8033.sh
grep "echo \"gaebal_uapsPortal(8033) Stopping...\"" ${WAS_MAIN}/stopM8033.sh
grep "java weblogic.Admin -url t3://localhost:7050 -username weblogic -password nate_zzang FORCESHUTDOWN gaebal_uapsPortal" ${WAS_MAIN}/stopM8033.sh
grep "/GAEBAL_PORTAL" ${WAS_MAIN}/bin/startManagedWebLogic8033.sh
grep "/gaebal_uaps.properties" ${WAS_MAIN}/bin/startManagedWebLogic8033.sh
grep "^ldap.server.bundang.ip=" ${WAS_COM_CONF}/gaebal_ldapdev.properties
grep "^ldap.server.bundang.port=" ${WAS_COM_CONF}/gaebal_ldapdev.properties
grep "gaebal_uapsPortal" ${WAS_COM_CONF}/gaebal_ldapdev.properties
grep "^proc.name=gaebal_uapsPortal" ${WAS_COM_CONF}/gaebal_portal.properties
grep "^service.name=gaebal_uapsPortal" ${WAS_COM_CONF}/gaebal_portal.properties
grep "^ldap.server.WIDE.ip=" ${WAS_COM_CONF}/gaebal_portal.properties
grep "^ldap.server.WIDE.port=" ${WAS_COM_CONF}/gaebal_portal.properties
grep "gaebal_uapsPortal" ${WAS_COM_CONF}/ldap.properties
grep "gaebal_portal" ${NEW_WAS_DEFAULT}/WEB-INF/conf/log4j.properties