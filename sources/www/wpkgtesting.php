<?php
// ## $Id$ ##
include "inc/wpkg.auth.php";

$url='http://www.crdp.ac-caen.fr/forum/se3_wpkglist.php?branch=testing';
exec ( "cd $wpkgwebdir;wget -N --timeout=15 --tries=3 '$url' 2>&1 && touch 'se3_wpkglist.php?branch=testing'", $output, $return_value);
if ( $return_value == 0 ) {
	get_xml('../../../../www/se3/wpkg/se3_wpkglist.php?branch=testing');
} else {
	header("HTTP/1.1 404 Not found");
	header("Status: 404 Erreur d'acces a '$url'"); 
	echo '<pre>';
	foreach($output as $key => $value) {
		echo "   $value\n";
	}
	//print_r($output);
	echo '</pre>';
}
?>
