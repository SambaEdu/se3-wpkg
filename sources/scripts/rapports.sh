#!/bin/bash

# Creation de wpkg/rapports/rapports.xml à partir des fichiers wpkg/rapports/*.txt
#
#  ## $Id$ ##

RAPPORTDIR="/var/sambaedu/unattended/install/wpkg/rapports"
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
    echo "<pre>Création d'un fichier vide rapports.xml.</pre>"
    echo '<?xml version="1.0" encoding="UTF-8"?>' > $RAPPORTXML
    echo '<!-- Genere par SambaEdu. Ne pas modifier -->' >> $RAPPORTXML
    echo '<rapports />' >> $RAPPORTXML
    NewRapports=1
fi

if [ ! -e $RAPPORTMD5XML ] ; then
    echo "<pre>Création d'un fichier vide rapports_md5.xml.</pre>"
    echo '<?xml version="1.0" encoding="UTF-8"?>' > $RAPPORTMD5XML
    echo '<!-- Genere par SambaEdu. Ne pas modifier -->' >> $RAPPORTMD5XML
    echo '<rapports />' >> $RAPPORTMD5XML
fi
chown www-admin:www-data $RAPPORTXML
chown www-admin:www-data $RAPPORTMD5XML

su www-admin -c "/usr/bin/php /var/www/sambaedu/wpkg/wpkg_rapport.php"
su www-admin -c "/usr/bin/php /var/www/sambaedu/wpkg/wpkg_profiles.php"


rm -f $fich_lock

cd - > /dev/null 
exit 0