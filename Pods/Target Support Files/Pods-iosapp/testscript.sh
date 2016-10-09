
#!/bin/sh

#	$1 ${SRCROOT}
#	$2 ${PROJECT_NAME}

echo "SRCROOT:$1" >> $1/shrecord.txt
echo "PROJECT_NAME:$2" >> $1/shrecord.txt

#运行PodInstall命令
#	$1	Podfile路径
runPodInstall(){
	cd $1
	pod install
}

newversion=`sed -nE '/CFBundleShortVersionString/{n;s/.*<string>(.*)</string>.*//;p;}' $1/$2/Info.plist`
oldversion=`sed -nE "/myversion /{s/.*myversion '(.*)'//;p;}" $1/Podfile`
echo $newversion >> $1/shrecord.txt
echo $oldversion >> $1/shrecord.txt
if [ $newversion = $oldversion ]; then
	#statements
	echo "newversion = oldversion"
else
	runPodInstall $1
fi


