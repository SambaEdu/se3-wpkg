#!/bin/bash

# Desactivation de la branche XP

mv /var/www/se3/wpkg/bin/mergeForum.xsl /var/www/se3/wpkg/bin/mergeForumXP.xsl -f
mv /var/www/se3/wpkg/bin/mergeForum_nonXP.xsl /var/www/se3/wpkg/bin/mergeForum.xsl -f

mv /var/www/se3/wpkg/AjoutPackage.xsl /var/www/se3/wpkg/AjoutPackageXP.xsl -f
mv /var/www/se3/wpkg/AjoutPackage_nonXP.xsl /var/www/se3/wpkg/AjoutPackage.xsl -f

mv /var/www/se3/wpkg/wpkglist.php /var/www/se3/wpkg/wpkglistXP.php -f
mv /var/www/se3/wpkg/wpkglist_nonXP.php /var/www/se3/wpkg/wpkglist.php -f
