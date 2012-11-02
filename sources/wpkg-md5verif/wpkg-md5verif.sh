#!/bin/bash
# Auteur : Olivier Lacroix
# Script permettant de tester les xml du svn du crdp.ac-caen.fr afin de surveiller les sommes md5 des xml officiels.

# ATTENTION : ce script ne doit pas tre exŽcutŽ sur un serveur en production. Il doit tre exŽcutŽ uniquement sur un serveur de tests car il modifie la base des xml wpkg automatiquement !

# Chemin UNC vers partages du se3
SE3="\\\\se3"

# Dossier contenant tous les fichiers generes par ce script.
REP=/var/se3/unattended/install/wpkg-md5verif
REPSOUSWIN="$SE3\install\wpkg-md5verif"
mkdir -p $REP

# dossier contenant les fichiers temoins pour les pauses.
mkdir -p $REP/pause

# MODE DEBUG
DEBUG=1

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
DESTFILE=$REP/wpkg-md5-verif-file.tmp

# mail d'envoi
DESTMAIL=wpkg-se3@listes.tice.ac-caen.fr

# IP du SE3
IPSE3="10.211.55.200"

# IP du client windows (qui doit repondre aux pings)
IPWIN="10.211.55.150"

# Acces au script wpkg-se3.js
WPKGJS="$SE3\install\wpkg\wpkg-se3.js"

# PARAMETRES wpkg-se3.js obligatoires
PARAM="/noDownload:True"

####### CONF : ne pas modifier la suite ###########

# emplacement local du fichier repertoriant les applications installees
WPKGXML="%systemroot%\system32\wpkg.xml"

# url de telechargement des xml (doit contenir trois sous-dossiers stable, testing (avec les xml) et logs (avec les fichiers journaux))
export url=http://svn.tice.ac-caen.fr/svn/SambaEdu3/wpkg-packages

# creation si besoin du dossier pour DESTFILE
DESTFILEDOSSIER="$(dirname "$DESTFILE")"
[ "$DEBUG" = "1" ] && echo "Le dossier de destination des telechargements est $DESTFILEDOSSIER."
mkdir -p $DESTFILEDOSSIER

# Dossier de dialogue avec le client
REPBAT=$REP/client
mkdir -p $REPBAT
REPBATWIN=$REPSOUSWIN\\client

# Fichier de dialogue avec le client windows : contient la liste des instructions qu'il devra exŽcuter pour tester les xml modifiŽs.
TESTFILE=$REPBAT/TesteXml.bat
TESTFILEWIN=$REPBATWIN\\TesteXml.bat

# Fichier provoquant une pause
PAUSEFILE=$REPBAT/pause.vbs
PAUSEFILEWIN=$REPBATWIN\\pause.vbs

# Fichier execute en tache panifiee au demarrage du pc client, qui ne s'arrete jamais et teste toutes les 10 secondes s'il y a quelquechose a faire (presence de $TESTFILE)
TACHEFILE=$REPBAT/bootscript.bat
TACHEFILEWIN=$REPBATWIN\\bootscript.bat

# Fichier provoquant une pause
INSTALLSCRIPTCLIENT=$REPBAT/install.bat

# Fichier de retour du client windows : contient les informations utiles pour savoir si l'install, l'upgrade, le remove ont fonctionnŽ.
RETOURFILE=$REPBAT/TesteXml.log
RETOURFILEWIN=$REPBATWIN\\TesteXml.log

# Dossier contenant toutes les commandes passŽes par le poste windows au serveur SE3.
REPCMDCRON=$REP/cron

# Dossier contenant tous les xml modifiŽs ˆ tester par le poste windows.
REPXML=$REP/xml

# Fichier qui reste apres le lancement du script afin de ne pas reprendre tous les download depuis le debut.
# Fichier listant dans l'ordre les verifications a faire. Permet de ne pas recommencer au debut a chaque lancement du script
# Le script reprend a la premiere ligne de ce fichier les verifications
LISTEAEXECUTER=$REP/wpkg-md5-verif-liste

# on concatene les xml les plus recents dans un wpkg-md5-verif-packages.xml
export PACKAGESFILE=$REP/wpkg-md5-verif-packages.xml

#### Fichiers temporaires a supprimer en fin de script.
# Fichier contenant le mail a envoyer
MAILFILETMP=$REP/wpkg-md5-verif-mail

# Fichier genere depuis $PACKAGEARCH avec toutes les url a verifier sous la forme :
# file.xml#url#md5sum
LISTEURLMD5=$REP/wpkg-url-md5-new

# fichier temporaire pour updater les sommes md5 des xml
export FILETMP=$REP/wpkg-md5verif-temp.xml

######################## FIN CONF #######################

####################### DEBUT DES VERIFICATIONS DES DEPENDANCES ############
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


####################### FIN DES VERIFICATIONS DES DEPENDANCES ############


####################### DEBUT DES FONCTIONS ############

function CmdToWin {
	echo $1 >> $TESTFILE
}

function SupprimeScriptClient {
	rm -f $TESTFILE
}

function WpkgInstall {
	idpackage=$1
	CmdToWin "cscript $WPKGJS $PARAM /install:$idpackage"
	RecupereWpkgXml
	WpkgStatus $idpackage
}

function WpkgUpgrade {
	idpackage=$1
	CmdToWin "cscript $WPKGJS $PARAM /upgrade:$idpackage"
	RecupereWpkgXml
	WpkgStatus $idpackage
}

function WpkgRemove {
	idpackage=$1
	CmdToWin "cscript $WPKGJS $PARAM /remove:$idpackage"
	RecupereWpkgXml
	WpkgStatus $idpackage
}

function WpkgStatus {
	idpackage=$1
	CmdToWin "cscript $WPKGJS /show:$idpackage > $RETOURFILEWIN"
}

function CreeTemoin {
	FICHIERTEMOIN=$1
	mkdir -p $REP/pause
	touch $REP/pause/$FICHIERTEMOIN
}

function SupprimeTemoin {
	FICHIERTEMOIN=$1
	[ -e $REP/pause/$FICHIERTEMOIN ] && rm -f $REP/pause/$FICHIERTEMOIN
}

function CreeScriptClient {
	echo "WScript.Sleep 10000" > $PAUSEFILE
	echo "set Z=$SE3\\install" > $TACHEFILE
	echo "set PACKAGE=$SE3\\install\\packages" >> $TACHEFILE
	echo ":debut" >> $TACHEFILE
	echo "if exist $TESTFILEWIN (" >> $TACHEFILE
	echo " call $TESTFILEWIN" >> $TACHEFILE
	#echo " del /F /Q /S  $TESTFILEWIN" >> $TACHEFILE
	echo ")" >> $TACHEFILE
	echo "cscript $REPBATWIN\pause.vbs > NUL" >> $TACHEFILE
	echo "goto debut" >> $TACHEFILE
	echo "copy /Y $TACHEFILEWIN %Systemdrive%" > $INSTALLSCRIPTCLIENT
	echo "if exist %systemroot%\\tasks\\WpkgMd5Verif.job del /F /Q /S %systemroot%\\tasks\\WpkgMd5Verif.job" >> $INSTALLSCRIPTCLIENT
	echo "schtasks /create /tn WpkgMd5Verif /sc ONSTART /tr \"%Comspec% /C start %Systemdrive%\\bootscript.bat\" " >> $INSTALLSCRIPTCLIENT
}

function PauseWinTantQue {
	FICHIERTEMOIN=$1
	CmdToWin ":debut$FICHIERTEMOIN"
	CmdToWin "if not exist $REPSOUSWIN\pause\\$FICHIERTEMOIN goto suite$FICHIERTEMOIN"
	CmdToWin "ping -n 10 $IPSE3 1&2> NUL"
	CmdToWin "goto debut$FICHIERTEMOIN"
	CmdToWin ":suite$FICHIERTEMOIN"
}

function PauseSE3TantQue {
# met le script en pause tant que wpkg.xml n'a pas change de date : passe la main au bout d'une heure en envoyant un mail
	APPLI=$1
	[ "$DEBUG" = "1" ] && echo "Pause sur le SE3 en attendant le test de $APPLI sur le client windows."
	FICHIER=$REP/wpkg.xml
	[ ! -e $FICHIER ] && touch $FICHIER
	modifinit=$(stat -c '%y' $FICHIER)
	dateinit=$(date +"%s")
	while true
	do
		modif=$(stat -c '%y' $FICHIER)
		[ "$modif" != "$modifinit" ] && echo "Le fichier wpkg.xml a change, on poursuit." && break # teste si le ficheir wpkg.xml a change depuis le debut de l'execution
#echo "date actu : $(date +\"%s\") - date init : $dateinit"
#echo "diff : $(($(date +"%s") - $dateinit))"
		[ $(($(date +"%s") - $dateinit)) -gt 3600 ] && echo "Le fichier wpkg.xml n'a pas change depuis 1H, on poursuit." && break # teste si une heure s'est ecoule depuis le debut de la pause 
		sleep 5
	done
	echo "Fin de la pause. wpkg.xml a ete modifie."
}

function InstallXmlSE3 {
	XML=$1
	[ "$DEBUG" = "1" ] && echo "Installation de $XML dans la base packages.xml du SE3, telechargement des fichiers necessaires. En cours."
	/var/www/se3/wpkg/bin/installPackage.sh $XML 0 admin urlmd5 1 > /dev/null
	# reste : recuperer l'erreur en cas de probleme md5 (si besoin: pas forcement besoin car on a corrige la somme md5 au prealable sur les xml testes et les anciens liens, si non valides ne peuvent plus etre telechargees...)
}

function RecupereWpkgXml {
	CmdToWin "copy /Y $WPKGXML $REPSOUSWIN"
}

function svnUpdate {
    echo "Recuperation de $1 depuis le svn..."
    if [ ! -e $REP/$1 ] ; then
       svn checkout $url/$1 $REP/$1
    else
       svn update $REP/$1
    fi
}

function regroupeXml {
# on filtre les xml obsolete en les classant par date : les plus recents en premier
# en effet, certains xml obsoletes sont restes sur le forum/files
echo "Examen de tous les attributs download de tous les xml du svn, branche $1" 
ls -t files/$1 | while read FILE; do
	[ "$DEBUG" = "1" ] && echo "Examen de $FILE"
	cat files/$1/$FILE | xmlstarlet sel -t -m "/packages/package/download" -o "$1/$FILE#" -v "@url" -o "#" -v "@md5sum" -n >> $LISTEURLMD5
done
}

######## Fonctions de lecture de wpkg.xml ###############

# lit le fichier $RETOURFILE 
function AppliInstalled {
	TEST=$(cat $RETOURFILE | grep "Status" | grep "Installed")
	if [ "$TEST" == "" ]; then
		RETOUR="True"
	else
		RETOUR="False"
	fi
	echo $RETOUR
	#xmlstarlet sel -t -m "/wpkg:wpkg/checkResults/" -v "@result" $WpkgXml
	#xmlstarlet ed -i "/packages/package/download[@url='$URL']" -t attr -n "md5sum" -v "$MD5" $FILE
}



######## Fonctions de modification des xml du svn #########

function Lireid {
	FILE=$1
	RETOUR=$(cat $FILE | xmlstarlet sel -t -m "/packages/package" -v "@id" -n)
	echo "$RETOUR"
}

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

function AjoutCrontabCommandeClientWindows {
	if [ ! -e /etc/cron.d/se3-wpkg-md5verif ]; then
		
		[ "$DEBUG" = "1" ] && echo "Ajout de la commande crontab (absente)."
	fi
}

function AppliATester {
	XML=$1
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
 	
	# si le xml est en testing et que les tests sont concluants, on le passe en stable.
	mv -f $FILETMP $FILE
	# reste a commiter le fichier
}


################## FIN DES FONCTIONS ##################

####################### NOUVEAU SCRIPT EXECUTE UNIQUEMENT AVEC CLIENT WINDOWS #######################
# Permet la modification autoamtique des xml incorrects via un test de validation (upgrade-remove-install) sur le client windows

function TesterXml {
	BRANCHE=$1
	Xml=$2
	Correctif=$3
	APPLI=$REP/$BRANCHE/$Xml
	ID=$(Lireid $APPLI)
	NOMAPPLI=$(echo "$APPLI" | sed -e "s+$(dirname $APPLI)/++g" | cut -d"." -f1)
	echo "On teste : $NOMAPPLI de $BRANCHE avec l'id $ID"
	# Tester tous les download url de $APPLI
	# Si l'une d'elle est erronee ou si "$BRANCHE" == "testing"
		# Si tout est corrige dans $REP/xml/$APPLI :
			if [ "$Correctif" == 1 ]; then
				# on teste $REP/xml/$APPLI sur le client windows
				echo "On provoque l'install de l'ancien xml sur le client windows."
				# si celle-ci provoque une erreur : download impossible ou install invalide, on ignore"
				InstallXmlSE3 $APPLI # telecharge les fichiers du xml old version sur le SE3
				WpkgInstall $ID # commande d'install de l'ancienne version du xml
				PauseSE3TantQue $NOMAPPLI # teste la date de $WPKGXML et poursuit quand elle a change ou apres une heure
				SupprimeScriptClient # supprime le script car deja execute par le client windows.
			fi 
			
			echo "On lance un upgrade depuis l'ancienne version vers la version corrigee."
			InstallXmlSE3 $REP/xml/$APPLI # telecharge les fichiers du xml corrige sur le SE3
			WpkgInstall $ID # commande d'install de l'ancienne version du xml pour le client windows
			PauseSE3TantQue $NOMAPPLI # teste la date de $WPKGXML et poursuit quand elle a change ou apres une heure
			SupprimeScriptClient # supprime le script car deja execute par le client windows.

			# recupere le succes de l'installation-upgrade
			INSTALLED=$(AppliInstalled)
			# si succes 
			if [ "$INSTALLED" == "True" ]; then
				# on teste le remove
				echo "On lance un remove depuis l'ancienne version vers la version corrigee."
				WpkgRemove $ID # commande d'install de l'ancienne version du xml pour le client windows
				PauseSE3TantQue $NOMAPPLI # teste la date de $WPKGXML et poursuit quand elle a change ou apres une heure
				SupprimeScriptClient # supprime le script car deja execute par le client windows.
				# recupere le succes du remove
				INSTALLED=$(AppliInstalled)
				if [ "$INSTALLED" == "True" ]; then
					echo "Le remove de $NOMAPPLI d'id $ID s'est mal deroule" >> $MAILFILETMP
					echo "Le remove de $NOMAPPLI d'id $ID s'est mal deroule"
				else
					echo "L'upgrade $NOMAPPLI d'id $ID depuis le xml actuel et le remove semblent corrects. On valide ce xml corrige." >> $MAILFILETMP
					echo "L'upgrade $NOMAPPLI d'id $ID depuis le xml actuel et le remove semblent corrects. On valide ce xml corrige."
				fi
			else
				echo "L'upgrade de $NOMAPPLI d'id $ID s'est mal deroule" >> $MAILFILETMP
				echo "L'upgrade de $NOMAPPLI d'id $ID s'est mal deroule"
			fi
		# Sinon
			# on envoie un mail car un lien est invalide.
	# sinon
		# aucune url n'est erronee , on passe au xml suivant
		# echo "Toutes les url des attributes download de $APPLI sont corrects"
}

function TestAndModify {
# programme principal du script nouvelle version

AjoutCrontabCommandeClientWindows # ajout crontab pour dialogue avec le client windows
CreeScriptClient # creation des scripts a executer cote client au boot , en tache planifiee


# Pour chaque fichier $APPLI de stable puis de testing faire
BRANCHE="stable"
#APPLI=$REP/$BRANCHE/algobox.xml
ls $REP/$BRANCHE | while read FILE ; do
	TesterXml "stable" $FILE
done

# envoi de mail puis menage
[ -e $MAILFILETMP ] && mail $DESTMAIL -s"Controle des sommes md5 WPKG" < $MAILFILETMP

rm -f $MAILFILETMP
rm -f $DESTFILE
rm -f $LISTEURLMD5
}


####################### FIN DU NOUVEAU SCRIPT EXECUTE UNIQUEMENT AVEC CLIENT WINDOWS #######################

####################### VIEUX SCRIPT EXECUTE UNIQUEMENT SANS CLIENT WINDOWS #######################
function TestOnly {
[ -e $PACKAGESFILE ] && rm -f $PACKAGESFILES
[ -e $LISTEURLMD5 ] && rm -f LISTEURLMD5

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
}

####################### FIN VIEUX SCRIPT EXECUTE UNIQUEMENT SANS CLIENT WINDOWS #######################

### MAIN ()

# mise a jour par rapport au svn
# reste : decommenter les trois lignes suivantes
svnUpdate "stable"
# svnUpdate "testing"
# svnUpdate "logs"

# Si le client windows repond au ping, on l'utilise, sinon, on ne fait que tester.
WINDOWSPRESENT=0
ping -c 4 $IPWIN > /dev/null && WINDOWSPRESENT=1
if [ $WINDOWSPRESENT == 1 ]; then
	echo "Le client windows $IPWIN est present, on l'utilise pour les validations des corrections md5"
	TestAndModify
else
	echo "Le client windows $IPWIN n'est pas present, on teste juste les sommes md5"
	TestOnly
fi
