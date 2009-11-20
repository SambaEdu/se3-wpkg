<?php
// ## $Id$ ##
include "inc/wpkg.auth.php";
//header("Pragma: no-cache");
//header("Cache-Control: no-cache, must-revalidate");
if ( $_GET['refresh'] == "1" ) {
	if(is_file("$wpkgwebdir/se3_wpkglist.php?branch=testing")) {
		unlink("$wpkgwebdir/se3_wpkglist.php?branch=testing");
	}
	if(is_file("$wpkgwebdir/se3_wpkglist.php")) {
		unlink("$wpkgwebdir/se3_wpkglist.php");
	}
}
$ErreurWget=false;
$url='http://www.crdp.ac-caen.fr/forum/se3_wpkglist.php';
$urlTest='http://www.crdp.ac-caen.fr/forum/se3_wpkglist.php?branch=testing';
exec ( "cd $wpkgwebdir;wget -N --timeout=15 --tries=3 '$url' 2>&1", $output, $return_value);
if ( $return_value != 0 ) {
	$ErreurWget=true;
} else {
	exec ( "cd $wpkgwebdir;wget -N --timeout=15 --tries=3 '$urlTest' 2>&1", $output, $return_value);
	if ( $return_value != 0 ) {
		$ErreurWget=true;
	} else {
		// Concatenation des deux fichiers
		exec ( "xsltproc -o $wpkgwebdir/forum.xml $wpkgwebdir/bin/mergeForum.xsl $wpkgwebdir/se3_wpkglist.php", $output, $return_value);
	}

} 
if ( $ErreurWget ) {
	header("HTTP/1.1 404 Not found");
	header("Status: 404 Erreur d'acces a '$url'"); 
	echo '<pre>';
	foreach($output as $key => $value) {
		echo "   $value\n";
	}
	//print_r($output);
	echo '</pre>';
} else {
	if ( $return_value != 0 ) {
		header("HTTP/1.1 500 Internal Server Error");
		header("Status: 500 Internal Server Error"); 
		header("Pragma: no-cache");
		header("Cache-Control: max-age=5, s-maxage=5, no-cache, must-revalidate");
		//echo "$last_line\n";
		echo '<pre>';
		echo "Erreur : xsltproc -o $wpkgwebdir/forum.xml $wpkgwebdir/bin/mergeForum.xsl $wpkgwebdir/se3_wpkglist.php\n";
		echo "return_value=$return_value\n";
		echo "\n";
		foreach($output as $key => $value) {
			echo "   $value\n";
		}
		echo '</pre>';
	} else {
		get_xml('../../../../www/se3/wpkg/forum.xml');
	}
}
?>
