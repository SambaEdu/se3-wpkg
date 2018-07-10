#!/bin/bash

# Desactivation de la branche XP

mv /var/www/sambaedu/wpkg/bin/mergeForum.xsl /var/www/sambaedu/wpkg/bin/mergeForumXP.xsl -f
mv /var/www/sambaedu/wpkg/bin/mergeForum_nonXP.xsl /var/www/sambaedu/wpkg/bin/mergeForum.xsl -f

mv /var/www/sambaedu/wpkg/AjoutPackage.xsl /var/www/sambaedu/wpkg/AjoutPackageXP.xsl -f
mv /var/www/sambaedu/wpkg/AjoutPackage_nonXP.xsl /var/www/sambaedu/wpkg/AjoutPackage.xsl -f

mv /var/www/sambaedu/wpkg/wpkglist.php /var/www/sambaedu/wpkg/wpkglistXP.php -f
mv /var/www/sambaedu/wpkg/wpkglist_nonXP.php /var/www/sambaedu/wpkg/wpkglist.php -f
