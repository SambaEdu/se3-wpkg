#!/bin/bash
# Auteur : Olivier Lacroix
# Script permettant de tester les xml du forum crdp.ac-caen.fr afin de surveiller les sommes md5 des xml officiels.

# MODE DEBUG
DEBUG=0

# quantite max a telecharger en une execution de ce script (en Ko)
# le script prend en compte cette limite avant le debut du telechargement suivant :
# exemple : si la limite est 1 000 000Ko et que le script a telecharge 999 999Ko, il va telecharger le fichier suivant
# meme si celui-ci pese lourd et s'interrompra apres...
# par defaut 6Go (en Ko)
MAXDOWNLOAD=6000000

# Heure du matin a partir de laquelle le script s'interrompt
HOURMAX=6

# Emplacement du fichier downloade... Ecrase-efface a chaque fois pour ne pas remplir le disque.
# 1Go doit etre dispo sur la partition du serveur pour certains download qui pesent un peu (orcad, ...).
DESTFILE=/var/wpkg-verif/wpkg-md5-verif-file.tmp

# mail d'envoi
DESTMAIL=wpkg-se3@listes.tice.ac-caen.fr

#URL de telechargement de l'archive contenant tous les xml du forum
url=http://www.crdp.ac-caen.fr/forum/packages.tgz


######################## FIN CONF #######################

# dependance subversion...
TEST=$(dpkg -l | grep subversion)
if [ "$TEST" == "" ] ; then
	echo "Le package subversion n'est pas installe. Ce script necessite xmlstarlet pour parser les xml..."
	echo "apt-get install subversion"
	exit 1
fi

# dependance xmlstarlet...
TEST=$(dpkg -l | grep xmlstarlet)
if [ "$TEST" == "" ] ; then
	echo "Le package xmlstarlet n'est pas installe. Ce script necessite xmlstarlet pour parser les xml..."
	echo "apt-get install xmlstarlet"
	exit 1
fi


# creation si besoin du dossier pour DESTFILE
DESTFILEDOSSIER="$(dirname "$DESTFILE")"
[ "$DEBUG" = "1" ] && echo "Le dossier de destination des telechargements est $DESTFILEDOSSIER."
mkdir -p $DESTFILEDOSSIER

#### Fichiers temporaires a supprimer en fin de script.
# Fichier contenant le mail a envoyer
MAILFILETMP=/tmp/wpkg-md5-verif-mail
# Fichier genere depuis $PACKAGEARCH avec toutes les url a verifier sous la forme :
# file.xml#url#md5sum
LISTEURLMD5=/tmp/wpkg-url-md5-new



#### Fichier qui reste apres le lancement du script afin de ne pas reprendre tous les download depuis le debut.
# Fichier listant dans l'ordre les verifications a faire. Permet de ne pas recommencer au debut a chaque lancement du script
# Le script reprend a la premiere ligne de ce fichier les verifications
LISTEAEXECUTER=/tmp/wpkg-md5-verif-liste

function svnUpdate {
    echo "Recuperation de $1 depuis le svn..."
    mkdir -p files
    if [ ! -e files/$1 ] ; then
       svn checkout $url/$1 files/$1
    else
       svn update files/$1
    fi
}

export url=http://svn.tice.ac-caen.fr/svn/SambaEdu3/wpkg-packages

svnUpdate "stable"
svnUpdate "testing"
svnUpdate "logs"


# on concatene les xml les plus recents dans un wpkg-md5-verif-packages.xml
export PACKAGESFILE=wpkg-md5-verif-packages.xml
[ -e $PACKAGESFILE ] && rm -f $PACKAGESFILES

function regroupeXml {
# on filtre les xml obsolete en les classant par date : les plus recents en premier
# en effet, certains xml obsoletes sont restes sur le forum/files
echo "Examen de tous les attributs download de tous les xml du svn, branche $1" 
[ -e $LISTEURLMD5 ] && rm -f LISTEURLMD5
ls -t files/$1 | while read FILE; do
	[ "$DEBUG" = "1" ] && echo "Examen de $FILE"
	cat files/$1/$FILE | xmlstarlet sel -t -m "/packages/package/download" -o "$1/$FILE#" -v "@url" -o "#" -v "@md5sum" -n >> $LISTEURLMD5
done
}

regroupeXml "testing"
regroupeXml "stable"


[ ! -e $LISTEURLMD5 ] && echo "Fichier $LISTEURLMD5 absent." && exit
echo "Fichier $LISTEURLMD5 genere."

# initialisation liste download. On rajoute au bout de la liste a traiter le debut du packages.xml
# si le fichier $LISTEAEXECUTER contient 2 fois plus de lignes que $LISTEURLMD5, c'est qu'il contient deja toutes les applis
# celles eventuellement en double seront virees par le sed -i ... -e "/$url/d" qui suit.
if [ -e $LISTEAEXECUTER ] ; then
    NBRELINES=$(wc -l $LISTEAEXECUTER | cut -d" " -f1)
else
    NBRELINES=0
fi

NBRELINESPACKAGE=$(wc -l $LISTEURLMD5 | cut -d" " -f1)

if [ $NBRELINES -ge $NBRELINESPACKAGE ] ; then
    [ "$DEBUG" = "1" ] && echo "Le fichier $LISTEAEXECUTER contient deja toutes les applications."
else
    [ "$DEBUG" = "1" ] && echo "Le fichier $LISTEAEXECUTER ne contient pas tous les packages, on les ajoute."
    cat $LISTEURLMD5 >> $LISTEAEXECUTER
fi

echo ""


######## Fonctions de modification des xml du svn #########

export FILETMP=/tmp/wpkg-md5verif-temp.xml

function InsertMd5Sum {
	FILE=$1
	URL=$2
	MD5=$3
	xmlstarlet ed -i "/packages/package/download[@url='$URL']" -t attr -n "md5sum" -v "$MD5" $FILE
}

function UpdateMd5Sum {
	FILE=$1
	URL=$2
	MD5=$3
	xmlstarlet ed -u "/packages/package/download[@url='$URL']/@md5sum" -v "$MD5" $FILE
}

function MiseAJourDuLog {
	LOG=$1
	MOTIF=$2
	echo "" >> $LOG
	echo "$(date) : $2" >> $LOG
	echo "" >> $LOG
	[ "$DEBUG" = "1" ] && echo "Mise a jour du fichier journal $LOG."
}

function MiseAJourDuXml {
	FILE=$1
	URL=$2
	MD5=$3
	if [ "$MD5" = "" ]; then
		InsertMd5Sum "$FILE" "$URL" "$MD5" > $FILETMP
		[ "$DEBUG" = "1" ] && echo "Ajout de la somme md5 $MD5 dans le fichier $FILE."
		MiseAJourDuLog $JOURNAL "Ajout de la somme md5 $MD5 dans le fichier $FILE."
	else
		UpdateMd5Sum "$FILE" "$URL" "$MD5" > $FILETMP
		[ "$DEBUG" = "1" ] && echo "Mise a jour de la somme md5 $MD5 dans le fichier $FILE."
		MiseAJourDuLog $JOURNAL "Mise a jour de la somme md5 $MD5 dans le fichier $FILE."
	fi
 
# si le xml est en stable mais pas en testing, on le passe en testing. Dans le cas contraire, on le corrige et on le commite sur place. 
	mv -f $FILETMP $FILE
}


####### Fin des fonctions ##########

#### telechargement effectif (les download effectues sont retires de $LISTEAEXECUTER au fur et a mesure)

# on nettoie les lignes vides du fichier $LISTEAEXECUTER
sed -i $LISTEAEXECUTER -e '/^$/d'

# on nettoie les cas ou l'url n'existe pas dans le noeud download du fichier $LISTEAEXECUTER
sed -i $LISTEAEXECUTER -e '/##/d'

export SIZETOT=0

cat $LISTEAEXECUTER | while read LINE; do
    [ -e $DESTFILE ] && rm -f $DESTFILE
    
    # nouvelle extraction des url et md5sum
	xmlfile=$(echo "$LINE" | cut -d"#" -f1)
    url=$(echo "$LINE" | cut -d"#" -f2)
    md5sum=$(echo "$LINE" | cut -d"#" -f3)

    echo "Fichier $xmlfile : telechargement de $url. MD5 attendue : $md5sum"
    
        /usr/bin/wget -O "$DESTFILE" "$url" 1>/dev/null 2>/dev/null
        # 2>>$MAILFILETMP
        # recuperation taille du download
        REALSIZE=$(stat -c %s $DESTFILE)
        SIZEMO=$[ $(stat -c %s $DESTFILE) / 1000 ]
        SIZETOT=$[$SIZEMO + $SIZETOT ]

		# calcul de la somme md5, envoi du mail si mauvaise
        if [ -e $DESTFILE ] ; then
		  # en cas d'erreur 404, le fichier est vide.
		  if [ $REALSIZE -eq 0 ] ; then
				echo "Le fichier telecharge depuis $xmlfile correspondant a $url est vide. Une erreur 404 surement..." >> $MAILFILETMP
				echo "Le fichier telecharge depuis $xmlfile correspondant a $url est vide. Une erreur 404 surement... Envoi d'un email d'avertissement."
		  else
			
			[ "$DEBUG" = "1" ] && echo "Fichier bien telecharge : $DESTFILE"
            		MD5REAL="$(/usr/bin/md5sum $DESTFILE | cut -d" " -f1)"
    		        if [ "$md5sum" = "" ] ; then
 			       echo "Somme md5 absente du fichier $xmlfile pour $url." >> $MAILFILETMP
 			       echo "Somme md5 absente du fichier $xmlfile pour $url."
		
  			      # nettoyage liste download avec sed -i
    			     FILENAME=$(echo "$url" | sed -e "s+$(dirname $url)/++g")
   			     [ "$DEBUG" = "1" ] && echo "On supprime le fichier $FILENAME de la liste a verifier." 
   			     sed -i $LISTEAEXECUTER -e "/$FILENAME/d"
    	    		elif [ "$MD5REAL" = "$md5sum" ]; then
                		echo "Tout va bien : somme md5 reelle $MD5REAL = somme md5 du xml $md5sum."
          		else
               			echo "Somme md5 incorrecte. Le telechargement depuis $xmlfile de $url a la somme md5 $MD5REAL et non celle attendue $md5sum." >> $MAILFILETMP
                		echo "Somme md5 incorrecte. Le telechargement depuis $xmlfile de $url a la somme md5 $MD5REAL et non celle attendue $md5sum. Envoi d'un mail d'avertissement"
           		fi
		  fi
        else
           	 echo "Fichier non telecharge : l'url $url du fichier $xmlfile est invalide." >> $MAILFILETMP
            	echo "Fichier non telecharge : l'url $url du fichier $xmlfile est invalide. Envoi d'un mail d'avertissement."
        fi

        # nettoyage liste download avec sed -i
        FILENAME=$(echo "$url" | sed -e "s+$(dirname $url)/++g")
	# FILENAME=$(echo $url | sed -e "s#/#\\\\/#g")
        [ "$DEBUG" = "1" ] && echo "On supprime le telechargement $FILENAME de la liste a verifier." 
	#echo $FILENAME
        sed -i $LISTEAEXECUTER -e "/$FILENAME/d"
    
        # on quitte si HEURE>6H
        HOUR=$(date '+%H')
        if [ $HOUR -ge $HOURMAX ] ; then
            echo "Il est $HOURMAX H. On continuera demain, tot le matin, lors du prochain lancement de ce script."
            exit
        fi


        # on quitte si $SIZETOT > $MAXDOWNLOAD
		[ "$DEBUG" = "1" ] && echo "Taille du telechargement : $SIZEMO Ko. Taille totale depuis le debut : $SIZETOT Ko."
        if [ $SIZETOT -ge $MAXDOWNLOAD ] ; then
            echo "Quantite maximale ($MAXDOWNLOAD Mo) atteinte. On continuera le controle des sommes md5 lors du prochain lancement de ce script."
            exit
        fi
    echo ""
done

[ -e $MAILFILETMP ] && mail $DESTMAIL -s"Controle des sommes md5 WPKG" < $MAILFILETMP

rm -f $MAILFILETMP
rm -f $DESTFILE
rm -f $LISTEURLMD5

