#/bin/bash
WEBLOGIC_HOME=/was/weblogic1036

if [ -f ${WEBLOGIC_HOME}/wlserver_10.3/server/lib/wls-wast.war ]; then
	echo "wls-wast.war found remove it"

	if [ -d ${WEBLOGIC_HOME}/wlserver_10.3/server/lib/wls_wsat_${DATE} ]; then
		echo "${WEBLOGIC_HOME}/wlserver_10.3/server/lib/wls_wsat_${DATE}/ exists"
	else
		mkdir ${WEBLOGIC_HOME}/wlserver_10.3/server/lib/wls_wsat_${DATE}
	fi
	
	mv ${WEBLOGIC_HOME}/wlserver_10.3/server/lib/wls-wast.war ${WEBLOGIC_HOME}/wlserver_10.3/server/lib/wls_wsat_${DATE}
else
	echo "${WEBLOGIC_HOME}/wlserver_10.3/server/lib/wls-wast.war Not Exist"
fi

DATE=`date +%Y%m%d`

for serverNM in myserver adtsvc cpinsvc custsvc custsvc1 uapsPortal upsvc upsvc1
do
	if [ -f ${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/.internal/wls-wsat.war ]; then
		echo "${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/.internal/wls-wsat.war found. remove it"
		if [ ! -d ${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/.internal_${DATE} ]; then
			mkdir ${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/.internal_${DATE}
		fi
		mv ${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/.internal/wls-wsat.war ${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/.internal_${DATE}
	else
		echo "${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/.internal/wls-wsat.war Not Exist"
	fi
	
	if [ -d ${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/_WL_internal/wls-wsat ]; then
		echo "${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/_WL_internal/wls-wsat found remove it"
		mv ${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/_WL_internal/wls-wsat ${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/_WL_internal/wls-wsat_${DATE}
	else
		echo "${WEBLOGIC_HOME}/domains/updomain/servers/${serverNM}/tmp/_WL_internal/wls-wsat Not Exist"
	fi
done		


for file in ${WEBLOGIC_HOME}/domains/updomain/startM*.sh
do
	if ! grep -H "^USER_MEM_ARGS=\"\${USER_MEM_ARGS} -Dweblogic.wsee.wstx.wsat.deployed=false\"" $file; then
		sed -ie "/export USER_MEM_ARGS/i USER_MEM_ARGS=\"\${USER_MEM_ARGS} -Dweblogic.wsee.wstx.wsat.deployed=false\"" $file
		grep -H "USER_MEM_ARGS=\"\${USER_MEM_ARGS} -Dweblogic.wsee.wstx.wsat.deployed=false\"" $file
	fi
done

