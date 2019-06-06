#!/bin/bash
# Auteur : Olivier Lacroix
# Script permettant de tester les xml du svn du crdp.ac-caen.fr afin de surveiller les sommes md5 des xml officiels.

# ATTENTION : ce script ne doit pas �tre ex�cut� sur un serveur en production. Il doit �tre ex�cut� uniquement sur un serveur de tests car il modifie la base des xml wpkg automatiquement !

######## Utilisation : ##########

# 1. copier wpkg-md5verif.sh sur le serveur se3 de test.
# 2. renseigner toutes les variables en debut de script : nom netbios du se3, IP du client windows de test, etc...
# 3. ex�cuter une fois wpkg-md5verif.sh afin de generer les scripts utiles et la conf : installation en crontab de l'ex�cution de wpkg-md5verif.sh
# 4. sur le client windows, sous le compte admin executer une fois Y:\unattended\install\wpkg-md5verif\client\install.bat : renseigner le mot de passe d'admin lors de la creation de la tache planifiee.
# 5. redemarrer le client windows pour activer automatiquement la tache planifiee.

# PS : verifier au prealable que le serveur SE3 peut envoyer des mails.

####### Fin de la documentation sur l'utilisation ########

# Chemin UNC vers partages du se3
SE3="\\\\se3"

# Dossier contenant tous les fichiers generes par ce script.
REP=/var/sambaedu/unattended/install/wpkg-md5verif
REPSOUSWIN="${config_se4fs_name}\install\wpkg-md5verif"
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
HOURMAX=8

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
WPKGJS="${config_se4fs_name}\install\wpkg\wpkg-se3.js"

# PARAMETRES wpkg-se3.js obligatoires
PARAM="/noDownload:True"

####### CONF : ne pas modifier la suite ###########

wpkgroot=/var/sambaedu/unattended/install/wpkg

LISTEDESXML=$REP/wpkg-LISTEDESXML

# emplacement local du fichier repertoriant les applications installees
WPKGXML="%systemroot%\system32\wpkg.xml"

# url de telechargement des xml (doit contenir trois sous-dossiers stable, testing (avec les xml) et logs (avec les fichiers journaux))
export url=http://svn.tice.ac-caen.fr/svn/SambaEdu3/wpkg-packages

# variable globales utiles
export RetourTelechargeUrls=0
export TOUTESTCORRIGE=1

# creation si besoin du dossier pour DESTFILE
DESTFILEDOSSIER="$(dirname "$DESTFILE")"
mkdir -p $DESTFILEDOSSIER

# Dossier de dialogue avec le client
REPBAT=$REP/client
mkdir -p $REPBAT
REPBATWIN=$REPSOUSWIN\\client

# Fichier de dialogue avec le client windows : contient la liste des instructions qu'il devra ex�cuter pour tester les xml modifi�s.
TESTFILE=$REPBAT/TesteXml.bat
TESTFILEWIN=$REPBATWIN\\TesteXml.bat
[ -e $TESTFILE ] && rm -f $TESTFILE

# Fichier provoquant une pause
PAUSEFILE=$REPBAT/pause.vbs
PAUSEFILEWIN=$REPBATWIN\\pause.vbs

# Fichier execute en tache panifiee au demarrage du pc client, qui ne s'arrete jamais et teste toutes les 10 secondes s'il y a quelquechose a faire (presence de $TESTFILE)
TACHEFILE=$REPBAT/bootscript.bat
TACHEFILEWIN=$REPBATWIN\\bootscript.bat

# Fichier provoquant une pause
INSTALLSCRIPTCLIENT=$REPBAT/install.bat

# Fichier de retour du client windows : contient les informations utiles pour savoir si l'install, l'upgrade, le remove ont fonctionn�.
RETOURFILE=$REPBAT/TesteXml.log
RETOURFILEWIN=$REPBATWIN\\TesteXml.log

# Dossier contenant toutes les commandes pass�es par le poste windows au serveur SE3.
REPCMDCRON=$REP/cron

# Dossier contenant tous les xml modifi�s � tester par le poste windows.
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

############### DEBUT DES VERIFICATIONS DES DEPENDANCES ET TEST DE NON DOUBLE EXECUTION ############
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

VERROU=/var/lock/wpkg-md5verif

if [ -e $VERROU ]; then
	echo "wpkg-md5verif.sh est deja en cours d'execution sur ce serveur"
	exit 0
fi

####################### FIN DES VERIFICATIONS DES DEPENDANCES ET DU TEST ############


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
	#RecupereWpkgXml
	WpkgStatus $idpackage
}

function WpkgUpgrade {
	idpackage=$1
	CmdToWin "cscript $WPKGJS $PARAM /upgrade:$idpackage"
	#RecupereWpkgXml
	WpkgStatus $idpackage
}

function WpkgRemove {
	idpackage=$1
	CmdToWin "cscript $WPKGJS $PARAM /remove:$idpackage"
	#RecupereWpkgXml
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
	echo "set Z=${config_se4fs_name}\\install" > $TACHEFILE
	echo "set SOFTWARE=${config_se4fs_name}\\install\\packages" >> $TACHEFILE
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
# met le script en pause tant que $RETOURFILE n'a pas change de date : passe la main au bout d'une heure en envoyant un mail
	APPLI=$1
	[ "$DEBUG" = "1" ] && echo "Pause sur le SE3 en attendant le test de $APPLI sur le client windows."
	FICHIER=$RETOURFILE
	[ ! -e $FICHIER ] && touch $FICHIER
	modifinit=$(stat -c '%y' $FICHIER)
	dateinit=$(date +"%s")
	while true
	do
		modif=$(stat -c '%y' $FICHIER)
		[ "$modif" != "$modifinit" ] && echo "Le fichier $RETOURFILE a change, on poursuit." && break # teste si le ficheir wpkg.xml a change depuis le debut de l'execution
#echo "date actu : $(date +\"%s\") - date init : $dateinit"
#echo "diff : $(($(date +"%s") - $dateinit))"
		[ $(($(date +"%s") - $dateinit)) -gt 3600 ] && echo "Le fichier $RETOURFILE n'a pas change depuis 1H, on poursuit." && break # teste si une heure s'est ecoule depuis le debut de la pause 
		sleep 5
	done
	echo "Fin de la pause. $RETOURFILE a ete modifie."
}

function InstallXmlSE3 {
	XML=$1
	NOMDUXML="`basename \"$XML\"`"
	[ "$DEBUG" = "1" ] && echo "Installation de $XML dans la base packages.xml du SE3, telechargement des fichiers necessaires. En cours."
	cp -f $XML $wpkgroot/tmp
	retourinstallPackage=$(/var/www/sambaedu/wpkg/bin/installPackage.sh $wpkgroot/tmp/$NOMDUXML 0 admin urlmd5 1)
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
echo "Examen de tous les attributs download de tous les xml du svn, branche $1" 
ls -t $REP/$1 | while read FILE; do
	[ "$DEBUG" = "1" ] && echo "Examen de $FILE"
	cat $REP/$1/$FILE | xmlstarlet sel -t -m "/packages/package/download" -o "$REP/$1/$FILE#" -v "@url" -o "#" -v "@md5sum" -n >> $LISTEURLMD5
done
}


function ExtraireDownloadDuXml {
	#[ -e $LISTEURLMD5 ] && rm -f $LISTEURLMD5
	FICHIER=$1
	echo "Examen de tous les attributs download de $FICHIER" 
	cat $FICHIER | xmlstarlet sel -t -m "/packages/package/download" -v "@url" -o "#" -v "@md5sum" -o "#" -v "@saveto" -n > $LISTEURLMD5
}


######## Fonctions de lecture de wpkg.xml ###############

# lit le fichier $RETOURFILE 
function AppliInstalled {
	TEST=$(cat $RETOURFILE | grep "Status" | grep "Not Installed")
	if [ "$TEST" == "" ]; then
		RETOURAppliInstalled="True"
	else
		RETOURAppliInstalled="False"
	fi
	#echo $RETOUR
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
	CRONFILE=/etc/cron.d/sambaedu-wpkg-md5verif
	SCRIPT=$0
	echo "# Execution de $SCRIPT tous les soirs a 2H du matin" > $CRONFILE
	echo "0 2 * * * root $SCRIPT > /dev/null 2>&1" >> $CRONFILE
	[ "$DEBUG" = "1" ] && echo "Mise a jour de la commande crontab : execution de $SCRIPT a 2H tous les jours."
	/etc/init.d/cron restart > /dev/null
}

function AppliATester {
	XML=$1
	MOTIF=$2
	echo "" >> $LOG
	echo "$(date) : $2" >> $LOG
	echo "" >> $LOG
	[ "$DEBUG" = "1" ] && echo "Mise a jour du fichier journal $LOG."
}

function GenereListeDesXml {
	# compte le nombre de xml a tester dans $LISTEDESXML 
	if [ -e $LISTEDESXML ] ; then
		NBRELINES=$(wc -l $LISTEDESXML | cut -d" " -f1)
	else
		NBRELINES=0
	fi

	NBREDEXMLSTABLE=$(ls $REP/stable | wc -l)
	NBREDEXMLTESTING=$(ls $REP/testing | wc -l)
	NBRETOTALDEXML=$(($NBREDEXMLSTABLE+$NBREDEXMLTESTING))

	if [ $NBRELINES -ge $NBRETOTALDEXML ] ; then
		[ "$DEBUG" = "1" ] && echo "Le fichier $LISTEDESXML contient deja toutes les applications."
	else
		[ "$DEBUG" = "1" ] && echo "Le fichier $LISTEDEXML ne contient pas tous les packages, on les ajoute."
		ls -t $REP/stable | while read FILE; do
			[ "$DEBUG" = "1" ] && echo "Examen programme de $REP/$FILE"
			echo stable/$FILE >> $LISTEDESXML
		done
		ls -t $REP/testing | while read FILE; do
			[ "$DEBUG" = "1" ] && echo "Examen programme de $REP/$FILE"
			echo testing/$FILE >> $LISTEDESXML
		done
		[ "$DEBUG" = "1" ] && echo "Mise a jour du fichier $LISTEDESXML effectuee."
	fi
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

function TelechargeUrls {
if [ -e $LISTEURLMD5 ]; then
	TOUTESTCORRIGE=1
	RETOUR=0
	cat $LISTEURLMD5 | while read LINE; do
		# echo "$LINE"
		# nouvelle extraction des url et md5sum
		url=$(echo "$LINE" | cut -d"#" -f1)
		md5sum=$(echo "$LINE" | cut -d"#" -f2)
	    DESTFILE=$(echo "$LINE" | cut -d"#" -f3)
		DESTFILE=/var/sambaedu/unattended/install/$DESTFILE
		[ "$url" == "" ]&& exit 0
		echo "Telechargement de $url. MD5 attendue : $md5sum sauve vers $DESTFILE"
        /usr/bin/wget -O "$DESTFILE" "$url" 1>/dev/null 2>/dev/null
        # 2>>$MAILFILETMP
        # recuperation taille du download
        REALSIZE=$(stat -c %s $DESTFILE)
        #SIZEMO=$[ $(stat -c %s $DESTFILE) / 1000 ]
		# calcul de la somme md5, envoi du mail si mauvaise
        if [ -e $DESTFILE ] ; then
		  # en cas d'erreur 404, le fichier est vide.
		  if [ $REALSIZE -eq 0 ] ; then
				echo "Le fichier telecharge depuis $url est vide. Une erreur 404 surement..." >> $MAILFILETMP
				echo "Le fichier telecharge depuis $url est vide. Une erreur 404 surement... Envoi d'un email d'avertissement."
				RETOUR=1
				TOUTESTCORRIGE=0
				echo "RETOUR=$RETOUR et $TOUTESTCORRIGE=TOUTESTCORRIGE"
		  else
				[ "$DEBUG" = "1" ] && echo "Fichier bien telecharge : $DESTFILE"
				MD5REAL="$(/usr/bin/md5sum $DESTFILE | cut -d" " -f1)"
    		    if [ "$md5sum" = "" ] ; then
 			       echo "Somme md5 absente du fichier xml pour $url. On l'ajoute." >> $MAILFILETMP
 			       echo "Somme md5 absente du fichier xml pour $url. On l'ajoute."
				   # on le fait par ailleurs : sed -e "s/$url#$md5sum#$DESTFILE/$url#$MD5REAL#$DESTFILE/g" $LISTEURLMD5
				   InsertMd5Sum $XMLCORRIGE $url $MD5REAL
				   ERREUR=1
    	    	elif [ "$MD5REAL" = "$md5sum" ]; then
                		echo "Tout va bien : somme md5 reelle $MD5REAL = somme md5 du xml $md5sum."
          		else
               			echo "Somme md5 incorrecte. Le telechargement depuis $url a la somme md5 $MD5REAL et non celle attendue $md5sum." >> $MAILFILETMP
                		echo "Somme md5 incorrecte. Le telechargement depuis $url a la somme md5 $MD5REAL et non celle attendue $md5sum. Envoi d'un mail d'avertissement"
						UpdateMd5Sum $XMLCORRIGE $url $MD5REAL
						RETOUR=1
           		fi
		  fi
        else
           	echo "Fichier non telecharge : l'url $url du fichier xml est invalide." >> $MAILFILETMP
			echo "Fichier non telecharge : l'url $url du fichier xml est invalide. Envoi d'un mail d'avertissement."
			RETOUR=1
			TOUTESTCORRIGE=0
        fi
	done
	RetourTelechargeUrls=$RETOUR
	echo "RETOUR=$RETOUR et $TOUTESTCORRIGE=TOUTESTCORRIGE"
else
	echo "$LISTEURLMD5 est vide pour $XMLATESTER. Peut-etre normal s'il ne comporte aucun lien download."
	RetourTelechargeUrls=0
fi
echo $RetourTelechargeUrls > $ERREURFILE
echo $TOUTESTCORRIGE > $TOUTESTCORRIGEFILE
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
	echo "On teste : $APPLI de $BRANCHE avec l'id $ID"
		# Si tout est corrige :
			if [ "$Correctif" == 1 ]; then
				# on teste $REP/xml/$APPLI sur le client windows
				echo "On provoque l'install de l'ancien xml sur le client windows."
				# si celle-ci provoque une erreur : download impossible ou install invalide, on ignore"
				InstallXmlSE3 $APPLI # telecharge les fichiers du xml old version sur le SE3
				WpkgInstall $ID # commande d'install de l'ancienne version du xml
				PauseSE3TantQue $NOMAPPLI # teste la date de $WPKGXML et poursuit quand elle a change ou apres une heure
				SupprimeScriptClient # supprime le script car deja execute par le client windows.
				
				echo "On lance un upgrade depuis l'ancienne version vers la version corrigee."
				InstallXmlSE3 $XMLCORRIGE # telecharge les fichiers du xml corrige sur le SE3
				WpkgInstall $ID # commande d'install de l'ancienne version du xml pour le client windows
				PauseSE3TantQue $NOMAPPLI # teste la date de $WPKGXML et poursuit quand elle a change ou apres une heure
				SupprimeScriptClient # supprime le script car deja execute par le client windows.
			else
				echo "Xml jamais teste avec ce script sur ce serveur. On lance une installation de la version du svn."
				InstallXmlSE3 $APPLI # telecharge les fichiers du xml du svn sur le SE3
				WpkgInstall $ID # commande d'install de l'ancienne version du xml pour le client windows
				PauseSE3TantQue $NOMAPPLI # teste la date de $WPKGXML et poursuit quand elle a change ou apres une heure
				SupprimeScriptClient # supprime le script car deja execute par le client windows.				
			fi

			# recupere le succes de l'installation-upgrade
			AppliInstalled
			INSTALLED=$RETOURAppliInstalled
			# si succes 
			if [ "$INSTALLED" == "True" ]; then
				echo "Installation-Upgrade realise avec succes."
				# on teste le remove
				echo "On lance un remove."
				WpkgRemove $ID # commande d'install de l'ancienne version du xml pour le client windows
				PauseSE3TantQue $NOMAPPLI # teste la date de $WPKGXML et poursuit quand elle a change ou apres une heure
				SupprimeScriptClient # supprime le script car deja execute par le client windows.
				# recupere le succes du remove
				AppliInstalled
				INSTALLED=$RETOURAppliInstalled
				if [ "$INSTALLED" == "True" ]; then
					echo "Le remove de $APPLI d'id $ID s'est mal deroule." >> $MAILFILETMP
					echo "Le remove de $APPLI d'id $ID s'est mal deroule. Envoi d'un mail"
				else
					echo "L'install-upgrade $APPLI d'id $ID depuis le xml actuel et le remove semblent corrects. On valide ce xml corrige:" >> $MAILFILETMP
					echo "L'install-upgrade $APPLI d'id $ID depuis le xml actuel et le remove semblent corrects. On valide ce xml corrige:"
					cat $XMLCORRIGE
					cat $XMLCORRIGE >> $MAILFILETMP
					echo "" >> $MAILFILETMP
					stat -c '%y' $XMLCORRIGE > $REP/xml/$NOMAPPLI.$BRANCHE.teste # garde en memoire la date du xml valide pour ne pas le tester indefiniment.
					# reste : le corriger automatiquement sur le svn.
					# A FAIRE.
				fi
			else
				echo "L'upgrade de $APPLI d'id $ID s'est mal deroule" >> $MAILFILETMP
				echo "L'upgrade de $APPLI d'id $ID s'est mal deroule"
				# reste :  effectuer une correction du check s'il s'agit d'un type de check uninstall
				# si check nouveau non valide 
					# envoi d'un mail.
				
				# effectuer le remove dans tous les cas pour nettoyer le client. On ne regarde pas si le remove a reussi ou pas.
				echo "On lance un remove pour vider le DD de la VM."
				WpkgRemove $ID # commande d'install de l'ancienne version du xml pour le client windows
				PauseSE3TantQue $NOMAPPLI # teste la date de $WPKGXML et poursuit quand elle a change ou apres une heure
				SupprimeScriptClient # supprime le script car deja execute par le client windows.
			fi
		# Sinon
			# on envoie un mail car un lien est invalide.
}

# fichier rajoute a cause d'un probleme de portee de variable.
ERREURFILE=/tmp/wpkg-md5verifERREURFILE
TOUTESTCORRIGEFILE=/tmp/wpkg-md5verifTOUTESTCORRIGEFILE

function TestAndModify {
# programme principal du script nouvelle version

AjoutCrontabCommandeClientWindows # ajout crontab pour dialogue avec le client windows
CreeScriptClient # creation des scripts a executer cote client au boot , en tache planifiee

GenereListeDesXml # Genere la liste des xml � examiner. Permet de reprendre les tests la ou le script s'est interrompu

# Pour chaque fichier de stable puis de testing faire
cat $LISTEDESXML | while read XMLATESTER ; do
	NOMAPPLI=$(echo "$REP/$XMLATESTER" | sed -e "s+$(dirname $REP/$XMLATESTER)/++g" | cut -d"." -f1)
	BRANCHE=$(echo "$XMLATESTER" | cut -d"/" -f1)
	FILE=$(echo "$XMLATESTER" | cut -d"/" -f2)
	ERREUR=0
	echo "On examine $NOMAPPLI de la branche $BRANCHE dans le fichier $FILE"

	# Tester tous les download url de $REP/$XMLATESTER
	ExtraireDownloadDuXml $REP/$XMLATESTER
	# Ce dernier script genere un fichier $LISTEURLMD5 qui contient url#md5#saveto
	# on modifie le xml ailleurs et on ne repercute sur le depot svn qu'en cas de succes.
	mkdir -p $REP/xml
	cp -f $REP/$XMLATESTER $REP/xml/
	# On corrige le xml dans 
	XMLCORRIGE=$REP/xml/$NOMAPPLI.xml
	TelechargeUrls # telecharge toutes les urls du $XMLATESTER et corrige les sommes md5 si besoin dans $XMLCORRIGE
	# si l'une d'elle est erronee alors ERREUR=1
	ERREUR=$(cat $ERREURFILE)
	TOUTESTCORRIGE=$(cat $TOUTESTCORRIGEFILE)
	echo "ERREUR=$ERREUR et TOUTESTCORRIGE=$TOUTESTCORRIGE"
	
	# si le fichier xml a change depuis la derniere execution que le client windows, il faut le retester.
	# tester la date contenue dans $REP/xml/$NOMAPPLI.$BRANCHE.teste la comparer a la variable $actu ci-apres
	if [ -e $REP/xml/$NOMAPPLI.$BRANCHE.teste ]; then
		old=$(cat $REP/xml/$NOMAPPLI.$BRANCHE.teste)
	else
		old="ToutSaufUneDateValide"
	fi
	actu=$(stat -c '%y' $REP/$BRANCHE/$FILE)
	# si le xml a change depuis le dernier test sur le client windows, on le teste de nouveau. Suppression du fichier temoin.
	echo "old=$old actu=$actu"
	[ ! "$old" == "$actu" ] && [ -e $REP/xml/$NOMAPPLI.$BRANCHE.teste ] && rm -f $REP/xml/$NOMAPPLI.$BRANCHE.teste 
	
	# teste si le xml a ete corrige entirement :
	[ "$ERREUR" == "1" -a "$TOUTESTCORRIGE" == "1" ] && CORRIGEENTIEREMENT=1
	if [ ! -e $REP/xml/$NOMAPPLI.$BRANCHE.teste -o "$CORRIGEENTIEREMENT"="1" ]; then
		# Si le client windows repond au ping, on l'utilise, sinon, on ne fait que tester.
		WINDOWSPRESENT=0
		ping -c 4 $IPWIN > /dev/null && WINDOWSPRESENT=1
		if [ $WINDOWSPRESENT == 1 ]; then
			echo "Le client windows $IPWIN est present, on l'utilise pour les validations des corrections de $BRANCHE/$FILE."
			# si jamais teste, on teste le xml corrige dessus.
			# si le xml a pu etre completement corrige, on le teste, sinon on envoie un mail : erreur 404 probable.
			if [ "$TOUTESTCORRIGE" == "1" ]; then
				TesterXml $BRANCHE $FILE $ERREUR
				#[ ! -e $REP/xml/$NOMAPPLI.$BRANCHE.teste ] && stat -c '%y' $XMLCORRIGE > $REP/xml/$NOMAPPLI.$BRANCHE.teste
			else
				echo "Le xml $XMLATESTER n'a ete que partiellement corrige (erreur 404 probable)"
				cat $XMLCORRIGE
				echo "Le xml $XMLATESTER n'a ete que partiellement corrige (erreur 404 probable)" >> $MAILFILETMP
				echo ""  >> $MAILFILETMP
				cat $XMLCORRIGE  >> $MAILFILETMP
				echo ""  >> $MAILFILETMP
			fi
		else
			echo "On envoie $XMLATESTER corrige par mail au destinataire sans garantie."
			echo "Voici $XMLATESTER corrige avec les nouvelles sommes md5. Malheureusement, en l'absence de client windows, impossible de tester son bon fonctionnement."
			echo ""
			cat $XMLCORRIGE
			echo ""	
			echo "Voici $XMLATESTER corrige avec les nouvelles sommes md5. Malheureusement, en l'absence de client windows, impossible de tester son bon fonctionnement." >> $MAILFILETMP
			echo ""  >> $MAILFILETMP
			cat $XMLCORRIGE  >> $MAILFILETMP
			echo ""  >> $MAILFILETMP			
		fi
	else
		echo "$BRANCHE/$FILE a deja ete teste et il n'y a pas d'erreur md5, on passe au xml suivant"
	fi
	[ -e $XMLCORRIGE ] && rm -f $XMLCORRIGE
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
[ -e $LISTEURLMD5 ] && rm -f $LISTEURLMD5

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
        FILENAME=$(echo "$url" | sed -e "s+$(dirname $url)/++g" | sed -e "s+/++g")
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

# reste : decommenter la ligne qui suit
#touch $VERROU

[ "$DEBUG" = "1" ] && echo "Le dossier de destination des telechargements est $DESTFILEDOSSIER."

# mise a jour par rapport au svn
# reste : decommenter les trois lignes suivantes
#svnUpdate "stable"
#svnUpdate "testing"
#svnUpdate "logs"

# Si le client windows repond au ping, on l'utilise, sinon, on ne fait que tester.
#WINDOWSPRESENT=0
#ping -c 4 $IPWIN > /dev/null && WINDOWSPRESENT=1
#if [ $WINDOWSPRESENT == 1 ]; then
#	echo "Le client windows $IPWIN est present, on l'utilise pour les validations des corrections md5"
	TestAndModify ##### Nouvelle version du script qui gere tous les cas : client present ou pas... Le script TestOnly est obsolete.
#else
#	echo "Le client windows $IPWIN n'est pas present, on teste juste les sommes md5"
#	TestOnly
#fi

[ -e $VERROU ] && rm -f $VERROU
