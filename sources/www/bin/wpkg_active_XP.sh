#!/bin/bash

# Activation de la branche XP

mv /var/www/se3/wpkg/bin/mergeForum.xsl /var/www/se3/wpkg/bin/mergeForum_nonXP.xsl -f
mv /var/www/se3/wpkg/bin/mergeForumXP.xsl /var/www/se3/wpkg/bin/mergeForum.xsl -f

mv /var/www/se3/wpkg/AjoutPackage.xsl /var/www/se3/wpkg/AjoutPackage_nonXP.xsl -f
mv /var/www/se3/wpkg/AjoutPackageXP.xsl /var/www/se3/wpkg/AjoutPackage.xsl -f

mv /var/www/se3/wpkg/wpkglist.php /var/www/se3/wpkg/wpkglist_nonXP.php -f
mv /var/www/se3/wpkg/wpkglistXP.php /var/www/se3/wpkg/wpkglist.php -f
