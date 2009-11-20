<?php
// ## $Id$ ##
include "inc/wpkg.auth.php";

// Mise à jour de rapports.xml en cas de besoin
exec ( "bash $wpkgwebdir/bin/rapports.sh", $output, $return_value);
if ( $return_value == 0 ) {
	get_xml("rapports/rapports.xml");
} else {
	header("HTTP/1.1 505 Exec error");
	header("Status: 505 Erreur d'execution"); 
	print_r($output);
}
?>
