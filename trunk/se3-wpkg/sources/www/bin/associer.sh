#!/bin/bash

#########################################################################
#   /var/www/se3/wpkg/bin/associer.sh                                   #
#                                                                       #
#########################################################################
#
## $Id$ ##
#
#   Met à jour profiles.xml dans /var/se3/unattended/install/wpkg
#   en Ajoutant ou Retirant un package d'un profile avec prise en compte des droits
#

if [ "$4" == "" ] ; then
	echo " Syntaxe : /var/www/se3/wpkg/bin/associer.sh  'operation' 'idPackage' 'idProfile' 'login'"
	echo "      operation : Associer|Dissocier"
	echo "      idPackage : idPackage"
	echo "      idProfile : idProfile"
	echo "      login     : login utilisateur en cours"
	exit 1
fi

wpkgroot="/var/se3/unattended/install/wpkg"
wpkgwebdir="/var/www/se3/wpkg"

PROFILES_XML="$wpkgroot/profiles.xml";

# Attend que $wpkgwebdir/bin/associer.lock ne soit plus présent
while [ -e $wpkgwebdir/bin/associer.lock ] ; do
	sleep 1
done

# C'est notre tour
echo "$$" >> "$wpkgwebdir/bin/associer.lock"
# Memorise la date actuelle de $wpkgroot/profiles.xml
#touch -r $wpkgroot/profiles.xml $wpkgroot/profiles.timestamp

erreur=0
TmpProfiles="$wpkgroot/tmp/profiles.$$.xml"
if ( xsltproc --stringparam operation "$1" --stringparam idPackage "$2" --stringparam idProfile "$3" --stringparam login "$4" --output $TmpProfiles $wpkgwebdir/bin/associer.xsl $wpkgroot/profiles.xml ) ; then
	if ( ! grep 'Erreur Associer' $TmpProfiles ) ; then
		if ( ! mv "$TmpProfiles" "$wpkgroot/profiles.xml" ) ; then
			erreur=4
		else
			# Erreur 10 = OK
			erreur=10
		fi
	else
		erreur=3
	fi
else
	erreur=2
fi

#remet la date de $wpkgroot/profiles.xml 
#touch -r $wpkgroot/profiles.timestamp $wpkgroot/profiles.xml 

# libération du lock
rm "$wpkgwebdir/bin/associer.lock"
exit $erreur