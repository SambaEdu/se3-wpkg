#!/bin/bash

# Creation de wpkg.xml contenant toutes les données wpkg
# nécessaire à l'interface de gestion
# à partir des fichiers profiles.xml hosts.xml packages.xml droits.xml
#
#  ## $Id$ ##

Erreur=0
wpkgroot="/var/se3/unattended/install/wpkg"
wpkgwww="/var/www/se3/wpkg"

if [ "$1" == "" ] ;then
    echo "Syntaxe : wpkgXml.sh login"
    echo "  Mise à jour de tmp/wpkg.login.xml destinée à l'interface web de wpkg."
    Erreur=1
else
    cd "$wpkgroot"
    
    # Mise à jour de rapports/rapports.xml
    if ( ls -rt1 rapports/*.txt rapports/rapports.xml | tail -n 1 | grep -v 'rapports/rapports.xml' >/dev/null ); then
        source $wpkgwww/bin/rapports.sh
    fi
	cd "$wpkgroot"
    NewWPkg=0
    if [ ! -e "tmp/wpkg.$1.xml" ] ; then
        echo "wpkg.$1.xml n'existait pas."
        NewWPkg=1
    else
        if [ packages.xml -nt tmp/wpkg.$1.xml ] || 
            [ profiles.xml -nt tmp/wpkg.$1.xml ] ||
            [ hosts.xml -nt tmp/wpkg.$1.xml ] ||
            [ droits.xml -nt tmp/wpkg.$1.xml ] ||
            [ rapports/rapports.xml -nt tmp/wpkg.$1.xml ] ; then
            NewWPkg=1
        fi
    fi    
    if [ "$NewWPkg" == "1" ] ;then
        echo "Mise à jour de wpkg.$1.xml."
        if ( ! xsltproc --output $wpkgroot/tmp/wpkg.$1.xml --stringparam "date" "`date --iso-8601='seconds'`" --stringparam user "$1" $wpkgwww/bin/updatewpkgXml.xsl profiles.xml 2>&1 ) ; then
            echo "Erreur $? : xsltproc --output $wpkgroot/tmp/wpkg.$1.xml --stringparam user '$1' $wpkgwww/bin/updatewpkgXml.xsl profiles.xml"
            Erreur=1
        fi
    else
        echo "wpkg.$1.xml était à jour."
    fi
fi
exit $Erreur
