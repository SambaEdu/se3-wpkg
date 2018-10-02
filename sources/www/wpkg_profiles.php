<?php 
/*
 *  script de mise à jour des fichiers profiles.xml et hosts.xml
 *  normalement lancé en cron
 *  
 */
include "config.inc.php";
include "ldap.inc.php";
include "wpkg_lib_admin.php";

   
update_xml_profiles($config);    
php?>