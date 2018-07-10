<?php


// ## $Id$ ##


include "inc/wpkg.auth.php";
//header("Pragma: no-cache");
//header("Cache-Control: no-cache, must-revalidate");
if ( $_GET['refresh'] == "1" ) {
	if(is_file("$wpkgwebdir/sambaedu_wpkglist.php?branch=testing")) {
		unlink("$wpkgwebdir/sambaedu_wpkglist.php?branch=testing");
	}
	if(is_file("$wpkgwebdir/sambaedu_wpkglist.php")) {
		unlink("$wpkgwebdir/sambaedu_wpkglist.php");
	}
}
$ErreurWget=false;
$url='http://wawadeb.crdp.ac-caen.fr/wpkg-list-ng/packages_stable.xml';
$fichier='se3_wpkglist.php';
$urlTest='http://wawadeb.crdp.ac-caen.fr/wpkg-list-ng/packages_testing.xml';
$fichiertest='se3_wpkglist.php?branch=testing';
$urlXP='http://wawadeb.crdp.ac-caen.fr/wpkg-list-ng/packages_XP.xml';
$fichierXP='se3_wpkglist.php?branch=XP';
exec ( "cd $wpkgwebdir;wget -N --timeout=15 --cache=off --tries=3 '$url' -O '$fichier' 2>&1", $output, $return_value);
if ( $return_value != 0 ) {
	$ErreurWget=true;
} else {
	exec ( "cd $wpkgwebdir;wget -N --timeout=15 --cache=off --tries=3 '$urlTest' -O '$fichiertest' 2>&1", $output, $return_value);
	if ( $return_value != 0 ) {
		$ErreurWget=true;
	} else {
		// Concatenation des deux fichiers
		exec ( "xsltproc -o $wpkgwebdir/forum.xml $wpkgwebdir/bin/mergeForum.xsl $wpkgwebdir/sambaedu_wpkglist.php", $output, $return_value);
	}
	exec ( "cd $wpkgwebdir;wget -N --timeout=15 --cache=off --tries=3 '$urlXP' -O '$fichierXP' 2>&1", $output, $return_value);
	if ( $return_value != 0 ) {
		$ErreurWget=true;
	} else {
		// Concatenation des deux fichiers
		exec ( "xsltproc -o $wpkgwebdir/forum.xml $wpkgwebdir/bin/mergeForum.xsl $wpkgwebdir/sambaedu_wpkglist.php", $output, $return_value);
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
		echo "Erreur : xsltproc -o $wpkgwebdir/forum.xml $wpkgwebdir/bin/mergeForum.xsl $wpkgwebdir/sambaedu_wpkglist.php\n";
		echo "return_value=$return_value\n";
		echo "\n";
		foreach($output as $key => $value) {
			echo "   $value\n";
		}
		echo '</pre>';
	} else {
	    get_xml($config, $login, '../../../../www/sambaedu/wpkg/forum.xml');
	}
}
?>
