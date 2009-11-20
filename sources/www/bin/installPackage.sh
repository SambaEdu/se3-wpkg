#!/bin/bash
#
# Configuration des applis contenue dans appli.xml 
# avec téléchargement des fichiers nécessaires à l'installation
# et gestion des dépendances entre applications
#
# Syntaxe : installPackage.sh appli.xml NoDownload
#   appli.xml doit être dans $wpkgroot/tmp/
#
## $id$ ##

Erreur="0"
wpkgroot="/var/se3/unattended/install/wpkg"
wpkgwww="/var/www/se3/wpkg"
Z="/var/se3/unattended/install"

function Download () {
	local url="$1"
	local destFile="$2"
	local MD5="$3"
	local pasDeDownload="$4"
	# $Appli est défini avec l'id de l'Appli
	echo ""
	
	if [ "$pasDeDownload" == "1" ]; then
		if [ -e "$Z/$destFile" ]; then
			echo -e "    Le fichier '$Z/$destFile' est présent.\n"
			PassMD5="1"
			if [ "$MD5" != "" ]; then
				if ( md5sum "$Z/$destFile" | grep $MD5 ) ; then
					echo -e "Le fichier présent est valide (MD5=$MD5).\n";
				else
					md5sum "$Z/$destFile"
					echo -e "  Erreur : le test md5sum ($MD5) a échoué.\n"
					ErreurApp="13"
					PassMD5="0"
				fi
			fi
		else
			echo "    Erreur : Le fichier '$Z/$destFile' est absent."
			if [ "$url" != "" ] ; then
				echo "      Vous avez refusé le téléchargement automatique, l'application ne peut pas être installée."
				echo "      Vous auriez dû télécharger ce fichier depuis l'adresse : </pre><a href='$url'>$url</a><pre>"
			fi
			ErreurApp="7"
		fi
	else
		if [ "$url" == "" ]; then
			if [ -e "$Z/$destFile" ]; then
				echo -e "Présence du fichier $Z/$destFile : OK.\n"
			else
				echo -e "Erreur : Le fichier $Z/$destFile est absent et l'url de téléchargement n'est pas définie.\n\n"
				ErreurApp="8"
			fi
		else
			if [ -e "$Z/$destFile" ]; then
				if [ "$MD5" != "" ]; then
					if ( md5sum "$Z/$destFile" | grep $MD5 ) ; then
						echo -e "Pas de téléchargement de '$destFile' : il est déjà présent et valide (MD5=$MD5).\n";
						pasDeDownload=1
					else
						echo -e "Une ancienne version du fichier $destFile existait déjà. Il va être mis à jour.\n"
					fi
				fi
			fi
			if [ "$pasDeDownload" != "1" ]; then
				echo -e "Téléchargement de '$url'.\n"
				destDir="`dirname \"$Z/$destFile\"`"
				fileName="`basename \"$destFile\"`"
				mkdir -p "$destDir"
				if [ ! -d "$destDir" ]; then
					echo -e "Erreur de création du répertoire '$destDir'.\n"
					ErreurApp="9"
				else
					# Le fichier est d'abord téléchargé dans $wpkgroot/tmp
					# puis si c'est OK, déplacé dans $Z/$destFile (avec écrasement éventuel d'une ancienne version de ce fichier)
					if ( ! /usr/bin/wget --progress=dot -O "$fileName" "$url" 2>&1 ); then
						echo -e "  Erreur de téléchargement de $url\n";
						ErreurApp="12"
					else
						PassMD5="1"
						if [ "$MD5" != "" ]; then
							if ( md5sum "$fileName" | grep $MD5 ) ; then
								echo -e "\nLe fichier téléchargé est valide (MD5=$MD5).\n";
							else
								md5sum "$fileName"
								echo -e "  Erreur : le test md5sum ($MD5) a échoué.\n"
								ErreurApp="13"
								PassMD5="0"
							fi
						fi
						if [ "$PassMD5" == "1" ] ; then
							if ( mv "$fileName" "$Z/$destFile" ) ;then
								echo -e "  sauvegardé dans '$Z/$destFile'.\n"
							else
								echo -e "  Erreur $? : mv '$fileName' '$Z/$destFile'.\n"
								ErreurApp="14"
							fi
						fi
					fi
				fi
			fi
		fi
	fi
	if [ "$Erreur" == "0" ] ; then
		Erreur="$ErreurApp"
	fi
}

function TestDepends() {
	Appli="$1"
	BashDepends="$wpkgroot/tmp/$Appli.depends.sh"
	if ( xsltproc -o "$BashDepends" --stringparam Appli "$Appli" "$wpkgwww/bin/testPackageDepends.xsl" "$wpkgroot/tmp/$appliXml" 2>&1 ) ; then
		source "$BashDepends"
	else
		echo "Erreur $? xsltproc -o '$BashDepends' --stringparam Appli '$Appli' '$wpkgwww/bin/testPackageDepends.xsl' '$wpkgroot/tmp/$appliXml'<br>"
		Erreur="10"
	fi
	if [ -e "$BashDepends" ] ; then
		rm "$BashDepends"
	fi
}

function AddApplication () {
	Appli="$1"
	echo "</pre>"
	echo "<h2>Ajout de '$Appli' aux applications disponibles.</h2>"
	if ( xsltproc -o "$wpkgroot/packages.xml" --stringparam Appli "$Appli" "$wpkgwww/bin/mergePackage.xsl" "$wpkgroot/tmp/$appliXml" 2>&1 ) ; then
		installationsTimeStamp "$Appli"
		echo "<br>L'application <b>$Appli</b> est maintenant disponible pour le déploiement.<br>"
		InstalledPackage=$(( $InstalledPackage + 1 ))
	else
		echo "<br>Erreur $? lors de l'ajout de l'application <b>$Appli</b> :<br>"
		echo "xsltproc -o '$wpkgroot/packages.xml' --stringparam Appli '$Appli' '$wpkgwww/bin/mergePackage.xsl' '$wpkgroot/tmp/$appliXml'<br>"
		Erreur="10"
	fi
	echo "<pre>"
}

function installationsTimeStamp() {
	Appli=$1
	# $appliXml
	TimeStamp=`date --iso-8601='seconds'`
	# $md5Xml
	timeStampsXml="/var/se3/unattended/install/wpkg/tmp/timeStamps.xml"
	if [ ! -e "$timeStampsXml" ] ; then
		echo '<installations />' > "$timeStampsXml"
	fi
	xsltproc --output "$timeStampsXml" --stringparam op add --stringparam Appli "$Appli" --stringparam AppliXml "$appliXml" --stringparam TimeStamp "`date --iso-8601='seconds'`" --stringparam md5sum "$md5Xml" --stringparam user "$login" /var/www/se3/wpkg/bin/timeStampAddPackages.xsl "$timeStampsXml"
}

cd $wpkgroot/tmp
InstalledPackage=0
nPackage=0
if [ "$4" == "" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ] ; then
	echo " Téléchargement des fichiers nécessaires à l'installation d'une appli."
	echo ""
	echo "Syntaxe : installPackage.sh appli.xml NoDownload login urlMD5 ignoreMD5"
else
	appliXml="`basename \"$1\"`";
	NoDownload="$2";
	login="$3";
	urlMD5="$4";
	ignoreMD5="$5";
	echo "<pre>"
	#echo "urlMD5=$urlMD5";
	#echo "ignoreMD5=$ignoreMD5";
	if [ -e "$appliXml" ]; then
		md5Xml="`md5sum "$appliXml" |gawk '{print $1;exit}'`"
		bashFile="$wpkgroot/tmp/$appliXml.$$.sh"
		if [ "$urlMD5" != "" ] && [ "$ignoreMD5" != "1" ] ; then
			controlMD5="`basename \"$urlMD5\"`";
		else
			controlMD5="";
		fi
		if ( xsltproc --output "$bashFile" --stringparam AppliXML "$appliXml" --stringparam md5Xml "$md5Xml" --stringparam controlMD5 "$controlMD5" --stringparam NoDownload "$NoDownload" "$wpkgwww/bin/installPackage.xsl" "$appliXml" 2>&1 ) ; then
			# cat "$bashFile";
			cd $Z
			source "$bashFile"
			cd - >/dev/null
		else
			echo -e "Erreur $? : xsltproc --output '$bashFile' --stringparam AppliXML '$appliXml' --stringparam md5Xml '$md5Xml' --stringparam controlMD5 '$controlMD5' --stringparam NoDownload '$NoDownload' '$wpkgwww/bin/installPackage.xsl' '$appliXml'\n";
			Erreur="2"
		fi
		if [ -e "$bashFile" ] ; then
			rm "$bashFile"
		fi
	else
		echo -e "Le fichier xml : '$wpkgroot/$appliXml' n'existe pas !\n"
		Erreur="1"
	fi
	echo "</pre>"
fi
cd - >/dev/null
if [ "$InstalledPackage" == "0" ] ; then
	if [ "$Erreur" != "3" ] ; then
		echo "Aucune application installée sur <b>$nPackage</b> que contenait <b>$appliXml</b>.<br>"
	fi
else
	if [ "$InstalledPackage" == "1" ] ; then
		echo "<b>$InstalledPackage</b> application installée sur <b>$nPackage</b> que contenait <b>$appliXml</b>.<br>"
	else
		echo "<b>$InstalledPackage</b> applications installées sur <b>$nPackage</b> que contenait <b>$appliXml</b>.<br>"
	fi
fi
echo "<br/>";
exit $Erreur
