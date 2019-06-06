#!/bin/bash

#########################################################################
#   /usr/share/sambaedu/scripts/update_hosts_profiles_xml.sh            #
#                                                                       #
#########################################################################
#
#
#   Met à jour hosts.xml et profiles.xml dans /var/se3/unattended/install/wpkg
#   à partir des données de l'annuaire
#
#   A executer chaque fois que les parcs sont modifiés
#   Syntaxe :  update_hosts_profiles_xml.sh ComputersRDN ParcsRDN BaseDN

#
/usr/bin/php /var/www/sambaedu/wpkg2/wpkg_ldap_update.php
