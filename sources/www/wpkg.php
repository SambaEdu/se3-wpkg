<?php


//  $Id$

$login = "";
$wpkgUser = false;
include "includes/wpkg.auth.php";

if ( isWpkgUser($config, $login) && ($login != "")) {
	// Mise à jour de tmp/wpkg.$login.xml en cas de besoin
	exec ( "$wpkgwebdir/bin/wpkgXml.sh '$login'", $output, $return_value);
	if ( $return_value == 0 ) {
	    get_xml($config, $login, "tmp/wpkg.$login.xml");
	} else {
		header("HTTP/1.1 505 Exec error");
		header("Status: 505 Erreur d'execution"); 
		print_r($output);
	}
}
?>
