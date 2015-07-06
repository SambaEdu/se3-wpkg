#!/bin/bash

# Creation de wpkg/rapports/rapports.xml à partir des fichiers wpkg/rapports/*.txt
#
#  ## $Id$ ##

RAPPORTDIR="/var/se3/unattended/install/wpkg/rapports"
RAPPORTXML="rapports.xml"

cd $RAPPORTDIR
find $RAPPORTDIR/. -mtime +365 -delete 
NewRapports=0


# Chemin des fichiers de lock:
chemin_lock="/var/lock"
# Nom du fichier de lock:
fich_lock="$chemin_lock/wpkg.lck"
if [ -e $fich_lock ]; then
	t1=$(cat $fich_lock)
	t_expiration=$(($t1+120))
	t2=$(date +%s)
	difference=$(($t2-$t1))
	if [ $t2 -gt $t_expiration ]; then
		echo "generation de rappport initiee en $t1 et il est $t2" 
		echo "La tache a depasse le delai imparti."
		echo "Le fichier va etre reinitialise..." 
	else
		echo "Un rapport semble deja en cours de construction, veuillez patienter 2mn" 
		echo "</pre>"
		exit 1
	fi

else
	date +%s > $fich_lock
fi


if [ ! -e $RAPPORTXML ] ; then
    echo "Création d'un fichier vide rapports.xml."
    echo '<?xml version="1.0" encoding="iso-8859-1"?>' > $RAPPORTXML
    echo '<!-- Généré par SambaEdu. Ne pas modifier -->' >> $RAPPORTXML
    echo '<rapports />' >> $RAPPORTXML
    NewRapports=1
fi
Nnew=`ls -rt1 *.txt rapports.xml | grep -v wsusoffline  | grep -v unattended | awk '{if ($0 == "rapports.xml") {N=0}else{N=N+1}}END{print N}'`
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
    gawk --re-interval -f /var/www/se3/wpkg/bin/rapports.awk `find . -maxdepth 1 -iname '*.txt' $OPTION -a -printf '%f '` > TMP$RAPPORTXML
    xsltproc --output $RAPPORTXML /var/www/se3/wpkg/bin/rapports.xsl TMP$RAPPORTXML
    if [ -e TMP$RAPPORTXML ] ; then
        /bin/rm TMP$RAPPORTXML
    fi
fi

rm -f $fich_lock

cd -