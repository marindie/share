#/bin/bash
NEW_WEB_DOC="/web/apache2.2.31/htdocs/gaebal_portal"
NEW_WAS_DOC="/was/upwas/WebApp/GAEBAL_PORTAL"
NEW_LOG_WEB="/logs/web/gaebal_portal"
NEW_LOG_WAS="/logs/was/gaebal_portal"

DEL_FOLDER_LIST="/web/apache2.2.31/htdocs/gaebal_portal
/was/upwas/WebApp/GAEBAL_PORTAL
/logs/web/gaebal_portal
/logs/was/gaebal_portal
/logs/weblogic1036/updomain/gaebal_uapsPortal"

DEL_FILE_LIST="/web/apache2.2.31/bin/apachectl_100_portal
/web/apache2.2.31/bin/httpd_100.pid
/web/apache2.2.31/conf/httpd_100.conf
/web/apache2.2.31/conf/ssl_100.conf
/was/weblogic1036/domains/updomain/startM8033_J.sh
/was/weblogic1036/domains/updomain/stopM8033.sh
/was/weblogic1036/domains/updomain/viewM8033.sh
/was/weblogic1036/domains/updomain/bin/startManagedWebLogic8033.sh
/was/upwas/WebApp/COMMON/conf/gaebal_ldapdev.properties
/was/upwas/WebApp/COMMON/conf/gaebal_portal.properties"

echo "============ LIST ============="
for directory in $DEL_FOLDER_LIST
do
        echo $directory
done

for file in $DEL_FILE_LIST
do
        echo $file
done

echo "========== DELETE START ========="
for directory in $DEL_FOLDER_LIST
do
        if [ -d "${directory}" ]; then
                echo $directory
                rm -rI $directory
        fi
done

for file in $DEL_FILE_LIST 
do
        if [ -f "${file}" ]; then
                rm -vi $file
        fi
done 

echo "======= Remove uapisdev.gaebal_uapsPortal from ldap.properties ========="
sed -ir "s/^uapisdev.gaebal_uapsPortal.*//g" /was/upwas/WebApp/COMMON/conf/ldap.properties
sed -i '/^$/d' /was/upwas/WebApp/COMMON/conf/ldap.properties

grep "uapisdev.gaebal_uapsPortal" /was/upwas/WebApp/COMMON/conf/ldap.properties

#방화벽 작업은 별도로해야함
echo "Check Port Firewall"