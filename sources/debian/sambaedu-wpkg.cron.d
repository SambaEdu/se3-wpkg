# On teste si des maj wsusoffline sont disponibles
# A partir de 20h45 UTC+2, afin de correspondre avec l'heure de mise en ligne
# des maj Microsoft a 18h UTC
45 20  * * *   root    /usr/share/sambaedu/scripts/wsusoffline-download.sh >/dev/null 2>&1

# telechargement automatique de la liste des paquets disponibles sur le svn a 22h00 chaque soir
00 22  * * *   www-admin    /usr/bin/php /var/www/sambaedu/wpkg/wpkg_svn.php >/dev/null 2>&1

# mise a jour automatique du fichier rapport toutes les 5 minutes
*/5 * * * *   root    /var/www/sambaedu/wpkg/bin/rapports.sh >/dev/null 2>&1
