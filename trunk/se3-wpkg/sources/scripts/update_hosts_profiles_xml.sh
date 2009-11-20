#!/bin/bash

#########################################################################
#   /usr/share/se3/scripts/update_hosts_profiles_xml.sh                 #
#                                                                       #
#########################################################################
#
#
#   Met à jour hosts.xml et profiles.xml dans /var/se3/unattended/install/wpkg
#   à partir des données de l'annuaire
#
#   A executer chaque fois que les parcs sont modifiés
#   Syntaxe :  update_hosts_profiles_xml.sh ComputersRDN ParcsRDN BaseDN

## $Id$ ##
#


ComputersRDN="$1"
ParcsRDN="$2"
BaseDN="$3"

wpkgroot="/var/se3/unattended/install/wpkg"
wpkgwebdir="/var/www/se3/wpkg"

HOSTS_XML="$wpkgroot/hosts.xml";
PROFILES_XMLTMP="$wpkgroot/profiles.xml.tmp";
PROFILES_XML="$wpkgroot/profiles.xml";

if [ "$2" == "" ]; then
    echo "hosts.xml et profiles.xml dans /var/se3/unattended/install/wpkg/"
    echo "  Syntaxe :  update_hosts_profiles_xml.sh ComputersRDN ParcsRDN BaseDN"
    exit 1
fi

# Nom du profile TousLesPostes
TousLesPostes="_TousLesPostes"

#BaseDN=`echo "SELECT value FROM params WHERE name='ldap_base_dn'" | mysql -h localhost se3db -N`
#ParcsRDN=`echo "SELECT value FROM params WHERE name='parcsRdn'" | mysql -h localhost se3db -N`
#ComputersRDN=`echo "SELECT value FROM params WHERE name='computersRdn'" | mysql -h localhost se3db -N`

# echo "ParcsRDN=$ParcsRDN; BaseDN=$BaseDN"

# Création de $PROFILES_XMLTMP et $HOSTS_XML


echo '<?xml version="1.0" encoding="iso-8859-1"?>' > $PROFILES_XMLTMP
echo '<!-- Généré par SambaEdu. Ne pas modifier -->' >> $PROFILES_XMLTMP
echo '<profiles>' >> $PROFILES_XMLTMP
echo '<?xml version="1.0" encoding="iso-8859-1"?>' > $HOSTS_XML
echo '<!-- Généré par SambaEdu. Ne pas modifier -->' >> $HOSTS_XML
echo '<wpkg>' >> $HOSTS_XML
# Ajout d'un profile pour chaque parc et pour chaque machine
# Chaque profile poste depend du profile des parcs auxquels il appartient ainsi que du profile $TousLesPostes
# Seuls les postes ayant un compte (WinXP et2K) sont répertoriés.

# echo "ldapsearch -x -LLL -S 'cn' -b \"$ParcsRDN,$BaseDN\" '(cn=*)' cn member"
ldapsearch -x -LLL -S 'cn' -b "$ParcsRDN,$BaseDN" '(cn=*)' cn member | 
    gawk '  BEGIN {
                print "<profile id=\"'$TousLesPostes'\" />";
            }
            /^cn: /{
                parc=$2;
                print "<profile id=\"" parc "\" />";
            }
            /^member: /{
                if ( split($2,a,"[=,]") > 2 ) {
                    HOST=tolower(a[2]);
                    tempParc[ HOST ] = HOST;
                }
            }
            /^$/ {
                for ( HOST in tempParc ) {
                    parcs[HOST] = parcs[HOST] ";" parc ;
                }
                delete tempParc;
				parcsConnus[parc] = 1;
                parc = "";
            }
            END {
                for ( HOST in parcs ) {
                    if ( not (HOST in parcsConnus) ) {
                        parcs[HOST] = "'$TousLesPostes'" parcs[HOST] ;
                        hosts[HOST] = HOST;
                        ListHosts = ListHosts "(uid=" HOST "$)"
                    }
                }
                ListHosts = "ldapsearch -x -LLL -S \"uid\" -b \"'$ComputersRDN','$BaseDN'\" \"(|" ListHosts ")\" uid";
                while ( ListHosts | getline ) {
                    if ( $1 == "uid:" ) {
                        sub("\\$", "", $2);
                        HOST = tolower($2);
                        print "<profile id=\""HOST"\" >";
                        split(parcs[HOST], a, ";");
                        for (iparc in a) {
                            if ( a[iparc] != "" ) {
                                print "<depends profile-id=\"" a[iparc] "\" />";
                            }
                        }
                        print "</profile>";
                        print "<host name=\""HOST"\" profile-id=\""HOST"\" />" >> "'$HOSTS_XML'";
                    }
                }
            }' >> $PROFILES_XMLTMP
# Fermeture du noeud profiles de $PROFILES_XMLTMP et wpkg de $HOSTS_XML
echo '</profiles>' >> $PROFILES_XMLTMP
echo '</wpkg>' >> $HOSTS_XML

# Profile profiles.xml
if [ ! -e $PROFILES_XML ]; then
cat - > $PROFILES_XML <<ProfilesXML
<?xml version="1.0" encoding="iso-8859-1"?>
<profiles>
  <profile id="_TousLesPostes">
    <package package-id="time" />
  </profile>
</profiles>
ProfilesXML
fi

# Réassocie les packages des profiles qui existaient dans profiles.xml
gawk '{printf("%s",$0)}' $PROFILES_XMLTMP | xsltproc --output $PROFILES_XML $wpkgwebdir/bin/addPackages.xsl -
#[ -e $PROFILES_XMLTMP ] && rm $PROFILES_XMLTMP
