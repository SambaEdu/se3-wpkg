#!/bin/bash

#########################################################################
#   /usr/share/se3/scripts/update_droits_xml.sh                             #
#                                                                       #
#########################################################################
#
#
#   Met à jour droits.xml dans /var/se3/unattended/install/wpkg
#   à partir des gon de l'annuaire : computers_is_admin, parc_can_manage et parc_can_view
#   et des délégations lues dans la table mysql : base se3db, table delegation

#   A executer chaque fois que les droits ou delegations sont modifiés
#   Syntaxe :  update_droits_xml.sh [--help]

## $Id$ ##
#

CONFIG_INC="/var/www/se3/includes/config.inc.php"
dbhost="`gawk -F'[\"]' '/^ *\\$dbhost *=/ {print $2}' $CONFIG_INC`";
dbname="`gawk -F'[\"]' '/^ *\\$dbname *=/ {print $2}' $CONFIG_INC`";
dbuser="`gawk -F'[\"]' '/^ *\\$dbuser *=/ {print $2}' $CONFIG_INC`";
dbpass="`gawk -F'[\"]' '/^ *\\$dbpass *=/ {print $2}' $CONFIG_INC`";

RightsRDN=`mysql --host=$dbhost --user=$dbuser --password=$dbpass --skip-column-names --execute="SELECT value FROM params WHERE name='rightsRdn';" --silent $dbname`
BaseDN=`mysql --host=$dbhost --user=$dbuser --password=$dbpass --skip-column-names --execute="SELECT value FROM params WHERE name='ldap_base_dn';" --silent $dbname`
#RightsRDN=`echo "SELECT value FROM params WHERE name='rightsRdn'" | mysql -h localhost se3db -N`
#BaseDN=`echo "SELECT value FROM params WHERE name='ldap_base_dn'" | mysql -h localhost se3db -N`
# echo "RightsRDN=$RightsRDN; BaseDN=$BaseDN"

wpkgroot="/var/se3/unattended/install/wpkg"
wpkgwebdir="/var/www/se3/wpkg"

PROFILES_XML="$wpkgroot/profiles.xml";
DROITS_XML="$wpkgroot/droits.xml";

if [ "$BaseDN" == "" ]; then
	echo "Met à jour le fichier /var/se3/unattended/install/wpkg/droits.xml"
	echo "  Syntaxe :  update_droits_xml.sh RightsRDN BaseDN"
	exit 1
fi

# Nom du profile TousLesPostes
TousLesPostes="_TousLesPostes"

echo '<?xml version="1.0" encoding="iso-8859-1"?>' > $DROITS_XML
echo '<!-- Généré par SambaEdu. Ne pas modifier -->' >> $DROITS_XML
echo '<droits>' >> $DROITS_XML

# mysql --host=$dbhost --user=$dbuser --password=$dbpass --skip-column-names --execute='SELECT login, parc, niveau FROM delegation' --silent $dbname

mysql --host=$dbhost --user=$dbuser --password=$dbpass --skip-column-names --execute='SELECT login, parc, niveau FROM delegation' --silent $dbname | 
	gawk '  BEGIN {
				ListDroits = "ldapsearch -x -LLL -S \"cn\" -b \"'$RightsRDN','$BaseDN'\" \"(|(cn=computers_is_admin)(cn=parc_can_manage)(cn=parc_can_view))\" cn member";
				while ( ListDroits | getline ) {
					if ( $1 == "cn:") {
						if ( $2 == "computers_is_admin") {
							Droits_EnCours=3;
						} else if ( $2 == "parc_can_manage") {
							Droits_EnCours=2;
						} else if ( $2 == "parc_can_view") {
							Droits_EnCours=1;
						}
					}
					if ( $1 == "member:") {
						if ( split($2,a,"[=,]") > 2 ) {
							USER=tolower(a[2]);
							droitParcs_EnCours[ USER ] = USER;
						}
					}
					if ( $0 == "") {
						for ( USER in droitParcs_EnCours ) {
							if (Droits_EnCours == 3) {
								print "  <droit parc=\"'$TousLesPostes'\" user=\"" USER "\" droit=\"admin\" />";
								DroitParcs[USER] = 3;
							} else if ( USER in DroitParcs) {
								if ( DroitParcs[USER] < Droits_EnCours ) {
									DroitParcs[USER] = Droits_EnCours;
								}
							} else {
								DroitParcs[USER] = Droits_EnCours;
							}
						}
						USER="";
						Droits_EnCours=0;
						delete droitParcs_EnCours;
					}
				}
			}
			{
				USER=$1;
				PARC=$2;
				DROIT=$3;
				if ( USER in DroitParcs ) {
					print "  <droit parc=\"" PARC "\" user=\"" USER "\" droit=\"" DROIT "\" />";
					DroitParcs[USER] = 0;
				}
			}
			END {
				for ( USER in DroitParcs ) {
					if ( DroitParcs[USER] == 2 ) {
						print "  <droit parc=\"'$TousLesPostes'\" user=\"" USER "\" droit=\"manage\" />";
					} else if ( DroitParcs[USER] == 1 ) {
						print "  <droit parc=\"'$TousLesPostes'\" user=\"" USER "\" droit=\"view\" />";
					}
					
				}
			}' >> $DROITS_XML
# Fermeture du noeud profiles de $DROITS_XML 
echo '</droits>' >> $DROITS_XML
chown www-se3 $DROITS_XML
