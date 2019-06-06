# On teste si des maj wsusoffline sont disponibles
# A partir de 20h45 UTC+2, afin de correspondre avec l'heure de mise en ligne
# des maj Micosoft a 18h UTC
45 20  * * *   root    /usr/share/se3/scripts/wsusoffline-download.sh >/dev/null 2>&1

# telechargement automatique de la liste des paquets disponibles sur le svn a 22h00 chaque soir
00 22  * * *   www-se3    /usr/bin/php /var/www/se3/wpkg/wpkg_svn.php >/dev/null 2>&1

# mise a jour automatique des rapports toutes les 5 minutes
*/5 * * * *   www-se3    /usr/bin/php /var/www/se3/wpkg2/wpkg_rapport.php >/dev/null 2>&1

# mise a jour automatique des parcs et hosts toutes les heures
* * * * *   www-se3    /usr/bin/php /var/www/se3/wpkg2/wpkg_ldap_update.php >/dev/null 2>&1
