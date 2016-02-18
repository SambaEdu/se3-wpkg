#!/bin/bash

# Installation de l'interface web pour wpkg
#
## $Id$ ##
#

#web_wpkg_srcDir="`dirname $0`"

wpkgroot="/var/se3/unattended/install/wpkg"
wpkgwww="/var/www/se3/wpkg"

if [ ! -d "$wpkgroot" ]; then
    echo "Erreur : Il faut au préalable avoir installé se3-wpkg !"
    echo "Installation de web-wpkg : ECHEC"
    exit 1
fi
XSLTPROC="`which xsltproc`"
if [ ! -x "$XSLTPROC" ]; then
    apt-get install xsltproc
fi
XSLTPROC="`which xsltproc`"
if [ ! -x "$XSLTPROC" ]; then
    echo "Le paquet debian xsltproc n'a pas pu être installé !"
    exit 1
fi

if [ ! -d "$wpkgwww" ]; then
    mkdir $wpkgwww
fi
if [ ! -d "$wpkgroot/tmp" ]; then
    mkdir $wpkgroot/tmp
    chown -R www-se3 $wpkgroot/tmp
fi
if [ ! -e "$wpkgroot/tmp/timeStamps.xml" ]; then
    echo "<installations/>" > $wpkgroot/tmp/timeStamps.xml
    chown www-se3 $wpkgroot/tmp/timeStamps.xml
fi
if [ ! -e "$wpkgwww/se3_wpkglist.php" ]; then
    echo "<packages/>" > $wpkgwww/se3_wpkglist.php
    chown www-se3 $wpkgwww/se3_wpkglist.php
    # Pour que le fichier soit mis à jour à la prochaine demande
    touch --date='jun 1 00:00:00 CEST 2007' $wpkgwww/se3_wpkglist.php
fi
#cp -R $web_wpkg_srcDir/web/* $wpkgwww/
#cp -R $web_wpkg_srcDir/wpkg/* $wpkgroot/

chown -R www-se3:www-data $wpkgwww
chown -R www-se3:root $wpkgroot
chmod 775 $wpkgwww/bin/*
