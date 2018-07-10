#!/bin/bash

# Activation de la branche XP

mv /var/www/sambaedu/wpkg/bin/mergeForum.xsl /var/www/sambaedu/wpkg/bin/mergeForum_nonXP.xsl -f
mv /var/www/sambaedu/wpkg/bin/mergeForumXP.xsl /var/www/sambaedu/wpkg/bin/mergeForum.xsl -f

mv /var/www/sambaedu/wpkg/AjoutPackage.xsl /var/www/sambaedu/wpkg/AjoutPackage_nonXP.xsl -f
mv /var/www/sambaedu/wpkg/AjoutPackageXP.xsl /var/www/sambaedu/wpkg/AjoutPackage.xsl -f

mv /var/www/sambaedu/wpkg/wpkglist.php /var/www/sambaedu/wpkg/wpkglist_nonXP.php -f
mv /var/www/sambaedu/wpkg/wpkglistXP.php /var/www/sambaedu/wpkg/wpkglist.php -f
