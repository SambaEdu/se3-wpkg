#!/bin/bash

# Creation de wpkg/rapports/rapports.xml à partir des fichiers wpkg/rapports/*.txt
#
#  ## $Id$ ##

RAPPORTDIR="/var/se3/unattended/install/wpkg/rapports"
RAPPORTXML="rapports.xml"
RAPPORTMD5XML="rapports_md5.xml"

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
    echo '<?xml version="1.0" encoding="UTF-8"?>' > $RAPPORTXML
    echo '<!-- Genere par SambaEdu. Ne pas modifier -->' >> $RAPPORTXML
    echo '<rapports />' >> $RAPPORTXML
    NewRapports=1
fi

if [ ! -e $RAPPORTMD5XML ] ; then
    echo "Création d'un fichier vide rapports_md5.xml."
    echo '<?xml version="1.0" encoding="UTF-8"?>' > $RAPPORTMD5XML
    echo '<!-- Genere par SambaEdu. Ne pas modifier -->' >> $RAPPORTMD5XML
    echo '<rapports />' >> $RAPPORTMD5XML
fi


#Nnew=`ls -rt1 *.txt rapports.xml | grep -v wsusoffline  | grep -v unattended | awk '{if ($0 == "rapports.xml") {N=0}else{N=N+1}}END{print N}'`
#if [ "$Nnew" == "0" ]; then
#    echo "rapports.xml était à jour."
#else
#    echo "$Nnew rapports à prendre en compte."
#fi
#if [ ! "$Nnew" == "0" -o "$NewRapports" == "1" ] ;then
#    echo "Mise à jour de rapports.xml."
#	# Si NewRapports=0, on met a jour rapports.xml seulement avec les nouveaux fichiers txt. Sinon, c'est qu'il s'agit de l'initialisation : on met a jour a partir de tous les fichiers presents.
#	[ "$NewRapports" == "0" ] && OPTION="-cnewer rapports.xml" &&echo "Option : $OPTION"
#	# Création de rapports.xml à partir des fichiers rapport (*.txt)
#	# modif de superflaf ;)
#	valid_reports=''
#
#	for f in $(find . -maxdepth 1 -iname '*.txt' $OPTION -a -printf '%f ')
#	do
#		# Handle of only one report.
#		if tail -4 "$f" | grep -q 'Installed' 
#		then
#			# The report file is valid.
#			valid_reports="$valid_reports $f"
#		fi
#	done
#	
#	gawk --re-interval -f /var/www/se3/wpkg/bin/rapports.awk $valid_reports | xsltproc --output "$RAPPORTXML" /var/www/se3/wpkg/bin/rapports.xsl -
#fi

/usr/bin/php /var/www/se3/wpkg/wpkg_rapport.php

rm -f $fich_lock

cd -
exit 0