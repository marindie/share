#/bin/bash

###############
# Web 처리
###############
#소스 복사
cp -pr /web/apache2.2.31/htdocs/portal /web/apache2.2.31/htdocs/gaebal_portal
#방화벽 처리
#sudo iptables -I INPUT 1 -p tcp --dport 445 -j ACCEPT
#sudo service iptables save
#sudo service iptables restart

cd /web/apache2.2.31/bin
cp -p apachectl_96_portal apachectl_100_portal

#conf 파일명 변경
check=$(grep "HTTPD='\/web\/apache2.2.31\/bin\/httpd -f \/web\/apache2.2.31\/conf\/httpd_96.conf'" apachectl_100_portal)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^HTTPD='\/web\/apache2.2.31\/bin\/httpd -f \/web\/apache2.2.31\/conf\/httpd_96.conf'/HTTPD='\/web\/apache2.2.31\/bin\/httpd -f \/web\/apache2.2.31\/conf\/httpd_100.conf'/" apachectl_100_portal
                grep "HTTPD='\/web\/apache2.2.31\/bin\/httpd -f \/web\/apache2.2.31\/conf\/httpd_100.conf'" apachectl_100_portal
        fi
else
        grep "HTTPD='\/web\/apache2.2.31\/bin\/httpd -f \/web\/apache2.2.31\/conf\/httpd_100.conf'" apachectl_100_portal
        echo "httpd_96.conf Match not Found."
fi

#PID 추가
echo "22222" > httpd_100.pid
#conf 설정 파일 추가
cd /web/apache2.2.31/conf
cp -p httpd_96.conf httpd_100.conf

#DocumentRoot 경로 변경
check=$(grep "^DocumentRoot \"/web/apache2.2.25/htdocs/portal\"" httpd_100.conf)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^DocumentRoot \"\/web\/apache2.2.25\/htdocs\/portal\"/DocumentRoot \"\/web\/apache2.2.25\/htdocs\/gaebal_portal\"/" httpd_100.conf
                grep "^DocumentRoot \"/web/apache2.2.25/htdocs/gaebal_portal\"" httpd_100.conf
        fi
else
        grep "^DocumentRoot \"/web/apache2.2.25/htdocs/gaebal_portal\"" httpd_100.conf
        echo "DocumentRoot Match not Found."
fi

#Directory 경로 변경
check=$(grep "^<Directory \"\/web\/apache2.2.25\/htdocs\/gaebal_portal\">" httpd_100.conf)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^<Directory \"\/web\/apache2.2.25\/htdocs\/portal\">/<Directory \"\/web\/apache2.2.25\/htdocs\/gaebal_portal\">/" httpd_100.conf
                grep "^<Directory \"\/web\/apache2.2.25\/htdocs\/gaebal_portal\">" httpd_100.conf
        fi
else
        grep "^<Directory \"\/web\/apache2.2.25\/htdocs\/gaebal_portal\">" httpd_100.conf
        echo "Directory Match not Found."
fi

#Listen 포트 변경
check=$(grep "^Listen 96" httpd_100.conf)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^Listen 96/Listen 100/" httpd_100.conf
                grep "^Listen 100" httpd_100.conf
        fi
else
        grep "^Listen 100" httpd_100.conf
        echo "Listen Match not Found."
fi

#ServerName 포트 변경
check=$(grep "^ServerName .*96" httpd_100.conf)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^ServerName \${SERVER_IP}:96/ServerName \${SERVER_IP}:100/" httpd_100.conf
                grep "^ServerName .*100" httpd_100.conf
        fi
else
        grep "^ServerName .*100" httpd_100.conf
        echo "ServerName Match not Found."
fi

#ErrorLog 경로 변경
check=$(grep "ErrorLog \"|/web/apache2.2.25/bin/rotatelogs /logs/web/portal/error/error_log.%Y%m%d 96400\"" httpd_100.conf)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/ErrorLog \"|\/web\/apache2.2.25\/bin\/rotatelogs \/logs\/web\/portal\/error\/error_log.%Y%m%d 96400\"/ErrorLog \"|\/web\/apache2.2.25\/bin\/rotatelogs \/logs\/web\/gaebal_portal\/error\/error_log.%Y%m%d 96400\"/" httpd_100.conf
                grep "ErrorLog \"|/web/apache2.2.25/bin/rotatelogs /logs/web/gaebal_portal/error/error_log.%Y%m%d 96400" httpd_100.conf
        fi
else
        grep "ErrorLog \"|/web/apache2.2.25/bin/rotatelogs /logs/web/gaebal_portal/error/error_log.%Y%m%d 96400" httpd_100.conf
        echo "ErrorLog Match not Found."
fi



#CustomLog 경로 변경
check=$(grep "CustomLog \"|/web/apache2.2.25/bin/rotatelogs -l /logs/web/portal/access/access_log.%Y%m%d%H 3600" httpd_100.conf)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/CustomLog \"|\/web\/apache2.2.25\/bin\/rotatelogs -l \/logs\/web\/portal\/access\/access_log.%Y%m%d%H 3600\"/CustomLog \"|\/web\/apache2.2.25\/bin\/rotatelogs -l \/logs\/web\/gaebal_portal\/access\/access_log.%Y%m%d%H 3600\"/" httpd_100.conf
                grep "CustomLog \"|/web/apache2.2.25/bin/rotatelogs -l /logs/web/gaebal_portal/access/access_log.%Y%m%d%H 3600" httpd_100.conf
        fi
else
        grep "CustomLog \"|/web/apache2.2.25/bin/rotatelogs -l /logs/web/gaebal_portal/access/access_log.%Y%m%d%H 3600" httpd_100.conf
        echo "CustomLog Match not Found."
fi

#PID 파일 변경
check=$(grep "PidFile    /web/apache2.2.25/bin/httpd_96.pid" httpd_100.conf)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/PidFile    \/web\/apache2.2.25\/bin\/httpd_96.pid/PidFile    \/web\/apache2.2.25\/bin\/httpd_100.pid/" httpd_100.conf
                grep "PidFile    /web/apache2.2.25/bin/httpd_100.pid" httpd_100.conf
        fi
else
        grep "PidFile    /web/apache2.2.25/bin/httpd_100.pid" httpd_100.conf
        echo "PID Match not Found."
fi

#SSL 파일 변경
check=$(grep "Include /web/apache2.2.25/conf/ssl_96.conf" httpd_100.conf)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^Include \/web\/apache2.2.25\/conf\/ssl_96.conf/Include \/web\/apache2.2.25\/conf\/ssl_100.conf/" httpd_100.conf
                grep "Include /web/apache2.2.25/conf/ssl_100.conf" httpd_100.conf
        fi
else
        grep "Include /web/apache2.2.25/conf/ssl_100.conf" httpd_100.conf
        echo "SSL Match not Found."
fi

#없는 폴더 생성
if [ ! -d "/logs/web/gaebal_portal" ]; then
        mkdir /logs/web/gaebal_portal
fi
if [ ! -d "/logs/web/gaebal_portal/access" ]; then
        mkdir /logs/web/gaebal_portal/access
fi
if [ ! -d "/logs/web/gaebal_portal/error" ]; then
        mkdir /logs/web/gaebal_portal/error
fi

#SSL Conf 복사
cp -p ssl_96.conf ssl_100.conf

#Listen 포트 변경
check=$(grep "^Listen 443" ssl_100.conf)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^Listen 443/Listen 445/" ssl_100.conf
                grep "^Listen 445" ssl_100.conf
        fi
else
        grep "^Listen 445" ssl_100.conf
        echo "Listen Match not Found."
fi

#WebLogicPort 포트 변경
check=$(grep "           WebLogicPort 8030" ssl_100.conf)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/           WebLogicPort 8030/           WebLogicPort 8033/" ssl_100.conf
                grep "           WebLogicPort 8033" ssl_100.conf
        fi
else
        grep "           WebLogicPort 8033" ssl_100.conf
        echo "WebLogicPort Match not Found."
fi

###############
# Web 처리 끝
###############

###############
# Was 처리
###############
cp -pr /was/upwas/WebApp/PORTAL /was/upwas/WebApp/GAEBAL_PORTAL
cd /was/weblogic1036/domains/updomain
cp -p startM8030_J.sh startM8033_J.sh

#SERVER_NAME 변경
check=$(grep "SERVER_NAME=uapsPortal" startM8033_J.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/SERVER_NAME=uapsPortal/SERVER_NAME=gaebal_uapsPortal/" startM8033_J.sh
                grep "SERVER_NAME=gaebal_uapsPortal" startM8033_J.sh
        fi
else
        grep "SERVER_NAME=gaebal_uapsPortal" startM8033_J.sh
        echo "SERVER_NAME Match not Found."
fi

#SERVER_PORT 변경
check=$(grep "SERVER_PORT=8030" startM8033_J.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/SERVER_PORT=8030/SERVER_PORT=8033/" startM8033_J.sh
                grep "SERVER_PORT=8033" startM8033_J.sh
        fi
else
        grep "SERVER_PORT=8033" startM8033_J.sh
        echo "SERVER_NAME Match not Found."
fi

#ldapdev.properties 변경
check=$(grep "USER_MEM_ARGS=\"-DLDAPDEV=/was/upwas/WebApp/COMMON/conf/ldapdev.properties\"" startM8033_J.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/USER_MEM_ARGS=\"-DLDAPDEV=\/was\/upwas\/WebApp\/COMMON\/conf\/ldapdev.properties\"/USER_MEM_ARGS=\"-DLDAPDEV=\/was\/upwas\/WebApp\/COMMON\/conf\/gaebal_ldapdev.properties\"/" startM8033_J.sh
                grep "USER_MEM_ARGS=\"-DLDAPDEV=/was/upwas/WebApp/COMMON/conf/gaebal_ldapdev.properties\"" startM8033_J.sh
        fi
else
        grep "USER_MEM_ARGS=\"-DLDAPDEV=/was/upwas/WebApp/COMMON/conf/gaebal_ldapdev.properties\"" startM8033_J.sh
        echo "ldapdev.properties Match not Found."
fi

#uaps_portal.properties 경로 변경
check=$(grep "USER_MEM_ARGS=.* -DPORTAL_CONF=/was/upwas/WebApp/PORTAL/WEB-INF/conf/uaps_portal.properties" startM8033_J.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i'' -e "s/USER_MEM_ARGS=\(.*\) -DPORTAL_CONF=\/was\/upwas\/WebApp\/PORTAL\/WEB-INF\/conf\/uaps_portal.properties/USER_MEM_ARGS=\1 -DPORTAL_CONF=\/was\/upwas\/WebApp\/GAEBAL_PORTAL\/WEB-INF\/conf\/uaps_portal.properties/" startM8033_J.sh
                grep "USER_MEM_ARGS=.* -DPORTAL_CONF=/was/upwas/WebApp/GAEBAL_PORTAL/WEB-INF/conf/uaps_portal.properties" startM8033_J.sh
        fi
else
        grep "USER_MEM_ARGS=.* -DPORTAL_CONF=/was/upwas/WebApp/GAEBAL_PORTAL/WEB-INF/conf/uaps_portal.properties" startM8033_J.sh
        echo "uaps_portal.properties Match not Found."
fi

#gaebal_portal.properties 변경
check=$(grep "USER_MEM_ARGS=.* -DUPPROP=/was/upwas/WebApp/COMMON/conf/portal.properties" startM8033_J.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i'' -e "s/USER_MEM_ARGS=\(.*\) -DUPPROP=\/was\/upwas\/WebApp\/COMMON\/conf\/portal.properties/USER_MEM_ARGS=\1 -DUPPROP=\/was\/upwas\/WebApp\/COMMON\/conf\/gaebal_portal.properties/" startM8033_J.sh
                grep "USER_MEM_ARGS=.* -DUPPROP=/was/upwas/WebApp/COMMON/conf/gaebal_portal.properties" startM8033_J.sh
        fi
else
        grep "USER_MEM_ARGS=.* -DUPPROP=/was/upwas/WebApp/COMMON/conf/gaebal_portal.properties" startM8033_J.sh
        echo "gaebal_portal.properties Match not Found."
fi

#log4j.properties 경로 추가
sed -i'' -e "/DUPPROP/a USER_MEM_ARGS=\"\$\{USER_MEM_ARGS\} -Dlog4j\.configuration=file:\/was\/upwas\/WebApp\/GAEBAL_PORTAL\/WEB-INF\/conf\/log4j\.properties\"" startM8033_J.sh
grep "USER_MEM_ARGS=.* -Dlog4j.configuration=file:/was/upwas/WebApp/GAEBAL_PORTAL/WEB-INF/conf/log4j.properties" startM8033_J.sh
echo 

#startManagedWebLogic8033.sh 파일 변경
check=$(grep "^nohup .*/bin/startManagedWebLogic8030.sh" startM8033_J.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i'' -e "s/^nohup \(.*\)\/bin\/startManagedWebLogic8030.sh/nohup \1\/bin\/startManagedWebLogic8033.sh/" startM8033_J.sh
                grep "^nohup .*/bin/startManagedWebLogic8033.sh" startM8033_J.sh
        fi
else
        grep "^nohup .*/bin/startManagedWebLogic8033.sh" startM8033_J.sh
        echo "startManagedWebLogic8030.sh Match not Found."
fi

#viewM8033.sh 파일 변경
check=$(grep "viewM8030" startM8033_J.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/viewM8030/viewM8033/" startM8033_J.sh
                grep "viewM8033" startM8033_J.sh
        fi
else
        grep "viewM8033" startM8033_J.sh
        echo "viewM8030.sh Match not Found."
fi

#viewM8033.sh 추가
cp -p viewM8030.sh viewM8033.sh 

#nohup_gaebal_uapsPortal.out 경로 및 이름 변경
check=$(grep "tail -f .*/uapsPortal/nohup_uapsPortal.out" viewM8033.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i'' -e "s/tail -f \(.*\)\/uapsPortal\/nohup_uapsPortal.out/tail -f \1\/gaebal_uapsPortal\/nohup_gaebal_uapsPortal.out/" viewM8033.sh 
                grep "tail -f .*/gaebal_uapsPortal/nohup_gaebal_uapsPortal.out" viewM8033.sh
        fi
else
        grep "tail -f .*/gaebal_uapsPortal/nohup_gaebal_uapsPortal.out" viewM8033.sh
        echo "nohup_uapsPortal.out Match not Found."
fi

#stopM8033.sh 추가
cp -p stopM8030.sh stopM8033.sh

#stopM8033.sh 이름 변경
check=$(grep "echo \"uapsPortal(8030) Stopping...\"" stopM8033.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/echo \"uapsPortal(8030) Stopping...\"/echo \"gaebal_uapsPortal(8033) Stopping...\"/" stopM8033.sh
                grep "echo \"gaebal_uapsPortal(8033) Stopping...\"" stopM8033.sh
        fi
else
        grep "echo \"gaebal_uapsPortal(8033) Stopping...\"" stopM8033.sh
        echo "uapsPortal Match not Found."
fi

#stopM8033.sh 이름 변경
check=$(grep "java weblogic.Admin -url t3://localhost:7050 -username weblogic -password nate_zzang FORCESHUTDOWN uapsPortal" stopM8033.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/java weblogic.Admin -url t3:\/\/localhost:7050 -username weblogic -password nate_zzang FORCESHUTDOWN uapsPortal/java weblogic.Admin -url t3:\/\/localhost:7050 -username weblogic -password nate_zzang FORCESHUTDOWN gaebal_uapsPortal/" stopM8033.sh
                grep "java weblogic.Admin -url t3://localhost:7050 -username weblogic -password nate_zzang FORCESHUTDOWN gaebal_uapsPortal" stopM8033.sh
        fi
else
        grep "java weblogic.Admin -url t3://localhost:7050 -username weblogic -password nate_zzang FORCESHUTDOWN gaebal_uapsPortal" stopM8033.sh
        echo "uapsPortal Match not Found."
fi



#startManagedWebLogic8033.sh 추가
cd /was/weblogic1036/domains/updomain/bin
cp -p startManagedWebLogic8030.sh startManagedWebLogic8033.sh

#startManagedWebLogic8033.sh 이름 변경
check=$(grep "/PORTAL" startManagedWebLogic8033.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/\/PORTAL/\/GAEBAL_PORTAL/g" startManagedWebLogic8033.sh
                grep "/GAEBAL_PORTAL" startManagedWebLogic8033.sh
        fi
else
        grep "/GAEBAL_PORTAL" startManagedWebLogic8033.sh
        echo "PORTAL Match not Found."
fi

#startManagedWebLogic8033.sh 이름 변경
check=$(grep "/uaps.properties" startManagedWebLogic8033.sh)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/\/uaps.properties/\/gaebal_uaps.properties/g" startManagedWebLogic8033.sh
                grep "/gaebal_uaps.properties" startManagedWebLogic8033.sh
        fi
else
        grep "/gaebal_uaps.properties" startManagedWebLogic8033.sh
        echo "uaps.properties Match not Found."
fi

#gaebal_ldapdev.properties 추가
cd /was/upwas/WebApp/COMMON/conf/
cp -p ldapdev.properties gaebal_ldapdev.properties

#gaebal_ldapdev.properties IP 변경
check=$(grep "^ldap.server.bundang.ip=" gaebal_ldapdev.properties)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^ldap.server.bundang.ip=.*/ldap.server.bundang.ip=192.168.1.203/" gaebal_ldapdev.properties
                grep "^ldap.server.bundang.ip=" gaebal_ldapdev.properties
        fi
else
        grep "^ldap.server.bundang.ip=" gaebal_ldapdev.properties
        echo "ldap.server.bundang.ip Match not Found."
fi

#gaebal_ldapdev.properties PORT 변경
check=$(grep "^ldap.server.bundang.port=" gaebal_ldapdev.properties)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^ldap.server.bundang.port=.*/ldap.server.bundang.port=7070/" gaebal_ldapdev.properties
                grep "^ldap.server.bundang.port=" gaebal_ldapdev.properties
        fi
else
        grep "^ldap.server.bundang.port=" gaebal_ldapdev.properties
        echo "ldap.server.bundang.ip Match not Found."
fi

#gaebal_ldapdev.properties gaebal_uapsPortal 추가
check=$(grep "gaebal_uapsPortal" gaebal_ldapdev.properties)
if [ ! -z "$check" ]; then
        echo $check
else
        echo "Found Not Match. Continue Add? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                echo "uapisdev.gaebal_uapsPortal.bind.dn=webadmin1
                uapisdev.gaebal_uapsPortal.bind.pw=wjdwebadmin66
                uapisdev.gaebal_uapsPortal.min=2
                uapisdev.gaebal_uapsPortal.max=10
                uapisdev.gaebal_uapsPortal.retry.count=4
                uapisdev.gaebal_uapsPortal.retry.time=3000
                uapisdev.gaebal_uapsPortal.response.time=10000
                uapisdev.gaebal_uapsPortal.connection.timeout=1000" >> gaebal_ldapdev.properties
                grep "gaebal_uapsPortal" gaebal_ldapdev.properties
        fi
fi

#gaebal_portal.properties 추가
cp -p portal.properties gaebal_portal.properties

#gaebal_portal.properties proc.name 변경
check=$(grep "^proc.name=uapsPortal" gaebal_portal.properties)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^proc.name=uapsPortal/proc.name=gaebal_uapsPortal/" gaebal_portal.properties
                grep "^proc.name=gaebal_uapsPortal" gaebal_portal.properties
        fi
else
        grep "^proc.name=gaebal_uapsPortal" gaebal_portal.properties
        echo "proc.name Match not Found."
fi

#gaebal_portal.properties service.name 변경
check=$(grep "^service.name=uapsPortal" gaebal_portal.properties)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^service.name=uapsPortal/service.name=gaebal_uapsPortal/" gaebal_portal.properties
                grep "^service.name=gaebal_uapsPortal" gaebal_portal.properties
        fi
else
        grep "^service.name=gaebal_uapsPortal" gaebal_portal.properties
        echo "service.name Match not Found."
fi

#gaebal_portal.properties ldap.server.WIDE.ip= 변경
check=$(grep "^ldap.server.WIDE.ip=" gaebal_portal.properties)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^ldap.server.WIDE.ip=.*/ldap.server.WIDE.ip=192.168.1.203/" gaebal_portal.properties
                grep "^ldap.server.WIDE.ip=" gaebal_portal.properties
        fi
else
        grep "^ldap.server.WIDE.ip=" gaebal_portal.properties
        echo "ldap.server.WIDE.ip Match not Found."
fi

#gaebal_portal.properties ldap.server.WIDE.port= 변경
check=$(grep "^ldap.server.WIDE.port=" gaebal_portal.properties)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/^ldap.server.WIDE.port=.*/ldap.server.WIDE.port=7070/" gaebal_portal.properties
                grep "^ldap.server.WIDE.port=" gaebal_portal.properties
        fi
else
        grep "^ldap.server.WIDE.port=" gaebal_portal.properties
        echo "ldap.server.WIDE.port Match not Found."
fi

#ldap.properties gaebal_uapsPortal 추가
check=$(grep "gaebal_uapsPortal" ldap.properties)
if [ ! -z "$check" ]; then
        echo $check
else
        echo "Found Not Match. Continue Add? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                echo "uapisdev.gaebal_uapsPortal.bind.dn=webadmin1
                uapisdev.gaebal_uapsPortal.bind.pw=wjdwebadmin66
                uapisdev.gaebal_uapsPortal.min=2
                uapisdev.gaebal_uapsPortal.max=10
                uapisdev.gaebal_uapsPortal.retry.count=4
                uapisdev.gaebal_uapsPortal.retry.time=3000
                uapisdev.gaebal_uapsPortal.response.time=10000
                uapisdev.gaebal_uapsPortal.connection.timeout=1000" >> ldap.properties
                grep "gaebal_uapsPortal" ldap.properties
        fi
fi


#없는 폴더 및 파일 생성
if [ ! -d "/logs/was/gaebal_portal" ]; then
        mkdir /logs/was/gaebal_portal
fi
if [ ! -d "/was/weblogic1036/domains/updomain/logs/gaebal_uapsPortal" ]; then
        mkdir /was/weblogic1036/domains/updomain/logs/gaebal_uapsPortal
        touch /was/weblogic1036/domains/updomain/logs/gaebal_uapsPortal/nohup_gaebal_uapsPortal.out
        touch /was/weblogic1036/domains/updomain/logs/gaebal_uapsPortal/gaebal_uapsPortal_gc.log
else 
        if [ ! -f "/was/weblogic1036/domains/updomain/logs/gaebal_uapsPortal/nohup_gaebal_uapsPortal.out" ]; then
                touch /was/weblogic1036/domains/updomain/logs/gaebal_uapsPortal/nohup_gaebal_uapsPortal.out
        fi
        if [ ! -f "/was/weblogic1036/domains/updomain/logs/gaebal_uapsPortal/gaebal_uapsPortal_gc.log" ]; then
                touch /was/weblogic1036/domains/updomain/logs/gaebal_uapsPortal/gaebal_uapsPortal_gc.log
        fi
fi

#log4j 경로 변경
check=$(grep "portal" /was/upwas/WebApp/GAEBAL_PORTAL/WEB-INF/conf/log4j.properties)
if [ ! -z "$check" ]; then
        echo $check
        echo "Found Match. Continue Replace? (y/n)"
        read -r confirm
        if [ ${confirm^^} == "Y" ]; then
                sed -i "s/\/portal\//\/gaebal_portal\//g" /was/upwas/WebApp/GAEBAL_PORTAL/WEB-INF/conf/log4j.properties
                grep "gaebal_portal" /was/upwas/WebApp/GAEBAL_PORTAL/WEB-INF/conf/log4j.properties
        fi
else
        grep "gaebal_portal" /was/upwas/WebApp/GAEBAL_PORTAL/WEB-INF/conf/log4j.properties
        echo "log4j Match not Found."
fi

