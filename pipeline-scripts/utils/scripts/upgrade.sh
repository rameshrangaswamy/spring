#!/bin/bash
###
# Script to invoke installer ant script on the installer machine
###

numargs=$#
if [ $numargs -lt  2 ]
then
    echo "Usage: $0 [package] [version] [hostList]"
    exit 1
fi

package=$1
version=$2
hostList=$3

echo "package : $package"
echo "version : $version"
echo "hostList : $hostList"

cd /opt/installer/webapps/installer/

IFS='~' read -ra ADDR <<< "$hostList"
for hostName in "${ADDR[@]}"
do
    echo "hostName : $hostName"
	hostPropertiesPath=/opt/serverconfig/$hostName/host.properties
    appInstanceNames=`awk -v PACKAGE_PREFIX="$package-" '/package.instances=/ {
        split($0, prop, "=")
        n = split(prop[2], apps, ",")
        echo "$n"
        for (i = 0; ++i <= n;) {
            if (match(apps[i], PACKAGE_PREFIX)) {
                print apps[i]
            }
        }
    }' $hostPropertiesPath`

    if [ "$appInstanceNames" = "" ]
    then
        echo "appInstanceNames configuration is missing for the host"
        exit 1
    else
       echo "$appInstanceNames"
    fi
	
	for appInstance in $appInstanceNames
	do
			echo "Deploying app instance $appInstance on $hostName"
			instanceName=`echo $appInstance | sed "s/${package}-\(.*\)/\1/"`
			echo "$instanceName"
			echo "Stopping app instance $appInstance on $hostName"
			# Stop the instance
			curl -X GET $hostName:9800/bpm/rest/stop/$instanceName
			sleep 60

			echo "Installing app instance $appInstance on $hostName"
			# Install the package
			echo "Before ant command $package $version $appInstance"
			pwd
			ls -ltr
			ant -lib WEB-INF/lib/ -f installer.xml -Dhost=$hostName -Dpackage=$package -Dversion=$version -DinstallerInstanceName=$appInstance pre-upgrade
			
			 echo  "Updating host.properties for app $appInstance"
			# Update host.properties
			sed -i "s/$appInstance.version=.*/$appInstance.version=$version/" /opt/serverconfig/$hostName/host.properties
			# Start the service
			curl -X GET $hostName:9800/bpm/rest/start/$instanceName
			sleep 30
	done
done

