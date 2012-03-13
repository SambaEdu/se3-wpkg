#!/bin/bash

# Creation de wpkg/rapports/rapports.xml à partir des fichiers wpkg/rapports/*.txt
#
#  ## $Id$ ##

RAPPORTDIR="/var/se3/unattended/install/wpkg/rapports"
RAPPORTXML="rapports.xml"

cd $RAPPORTDIR

NewRapports=0
if [ ! -e $RAPPORTXML ] ; then
    echo "Création d'un fichier vide rapports.xml."
    echo '<?xml version="1.0" encoding="iso-8859-1"?>' > $RAPPORTXML
    echo '<!-- Généré par SambaEdu. Ne pas modifier -->' >> $RAPPORTXML
    echo '<rapports />' >> $RAPPORTXML
    NewRapports=1
fi
Nnew=`ls -rt1 *.txt rapports.xml | awk '{if ($0 == "rapports.xml") {N=0}else{N=N+1}}END{print N}'`
if [ "$Nnew" == "0" ]; then
    echo "rapports.xml était à jour."
else
    echo "$Nnew rapports à prendre en compte."
fi
if [ ! "$Nnew" == "0" -o "$NewRapports" == "1" ] ;then
    echo "Mise à jour de rapports.xml."
	# Si NewRapports=0, on met a jour rapports.xml seulement avec les nouveaux fichiers txt. Sinon, c'est qu'il s'agit de l'initialisation : on met a jour a partir de tous les fichiers presents.
	[ "$NewRapports" == "0" ] && OPTION="-cnewer rapports.xml" &&echo "Option : $OPTION"
    # Création de rapports.xml à partir des fichiers rapport (*.txt)
    gawk --re-interval -f /var/www/se3/wpkg/bin/rapports.awk `find . -iname '*.txt' $OPTION -a -maxdepth 1 -printf '%f '` > TMP$RAPPORTXML
    xsltproc --output $RAPPORTXML /var/www/se3/wpkg/bin/rapports.xsl TMP$RAPPORTXML
    if [ -e TMP$RAPPORTXML ] ; then
        /bin/rm TMP$RAPPORTXML
    fi
fi

cd -