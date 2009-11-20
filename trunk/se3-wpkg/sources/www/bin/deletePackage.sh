#!/bin/bash
#
# Suppression d'une appli contenue dans appli.xml 
# après vérification des dépendances
# Effacement des fichiers d'install sélectionnés
#
# Syntaxe : deletePackage.sh appli '1 3 4 5'
#   les numéros sont ceux des fichiers à supprimer
#
## $id ##

Erreur="0"
wpkgroot="/var/se3/unattended/install/wpkg"
wpkgwww="/var/www/se3/wpkg"
Z="/var/se3/unattended/install"

function installationsTimeStamp() {
	Appli=$1
	# $appliXml
	TimeStamp=`date --iso-8601='seconds'`
	# $md5Xml
	timeStampsXml="/var/se3/unattended/install/wpkg/tmp/timeStamps.xml"
	if [ ! -e "$timeStampsXml" ] ; then
		echo '<installations />' > "$timeStampsXml"
	fi
	xsltproc --output "$timeStampsXml" --stringparam op 'del' --stringparam Appli "$Appli" --stringparam TimeStamp "$TimeStamp" --stringparam user "$login" /var/www/se3/wpkg/bin/timeStampAddPackages.xsl "$timeStampsXml"
}


cd $wpkgroot/tmp
deletedPackage=0
if [ "$1" == "" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ] ; then
	echo " Suppression d'une appli ."
	echo ""
	echo "Syntaxe : deletePackage.sh login appli '1 3 4 5'"
	echo "   les numéros sont ceux des fichiers à supprimer."
else
	login="$1";
	appli="$2";
	bashFile="$wpkgroot/tmp/delete$appli.$$.sh"
	if ( xsltproc --output "$bashFile" --stringparam Appli "$appli" --stringparam deleteFiles " $3 " "$wpkgwww/bin/deletePackage.xsl" "$wpkgroot/profiles.xml" 2>&1 ) ; then
		#echo "----- $bashFile ---------"
		#cat "$bashFile";
		#echo "---------------------------------"
		cd $Z
		source "$bashFile"
		#echo "\$?=$?"
		installationsTimeStamp "$appli"
		cd -
	else
		echo -e "Erreur $? : xsltproc --output '$bashFile' --stringparam Appli '$appli' --stringparam deleteFiles ' $3 ' '$wpkgwww/bin/deletePackage.xsl' '$wpkgroot/profiles.xml'\n";
		Erreur="2"
	fi
	#if [ -e "$bashFile" ] ; then
	#	rm "$bashFile"
	#fi
fi
cd -
if [ "$Erreur" == "0" ]; then
	echo "L'application '<b>$appli</b>' a été supprimée du serveur.<br>"
else
	echo "Erreur $Erreur lors de la suppression de l'application '<b>$appli</b>'.<br>"
fi
exit $Erreur
