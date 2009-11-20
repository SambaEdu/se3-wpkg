<?php
// ## $Id$ ##
include "inc/wpkg.auth.php";
if ( $wpkgUser && ($login != "")) {
	$filename = "profiles.xml";
	$Maintenant = strftime ( "%D_%T" );
	exec ( "if [ $wpkgroot/profiles.xml -nt $wpkgroot/tmp/profiles.$login.xml ]; then xsltproc --output $wpkgroot/tmp/profiles.$login.xml --stringparam 'date' '$Maintenant' --stringparam 'user' '$login' $wpkgwebdir/bin/profilesXml.xsl $wpkgroot/profiles.xml 2>&1 ; fi", $output, $return_value);
	if ( $return_value == 0 ) {
		get_xml("tmp/profiles.$login.xml");
	} else {
		header("HTTP/1.1 505 Exec error");
		header("Status: 505 Erreur d'execution"); 
		print_r($output);
	}
/*	$PathFichier = "$wpkgroot/$filename";
	if (file_exists("$PathFichier")) {
		// Date: Mon, 15 Jan 2007 10:06:50 GMT
		$dateLastModification = filemtime($PathFichier);
		if (httpConditional($dateLastModification)) {
			exit(); //No need to send anything
		} else {
			$DateFichier = gmdate("D, d M Y H:i:s", $dateLastModification) . " GMT" ;
			header("Content-type: application/xml");
			header("Last-Modified: $DateFichier");
			header("Cache-Control: must-revalidate");
			header("Content-Disposition: inline; filename=$filename");
			//$Maintenant = strftime ( "%D_%T" );
			$Maintenant = $DateFichier;
			passthru("xsltproc --stringparam 'date' '$Maintenant' --stringparam 'user' '$login' $wpkgwebdir/bin/profilesXml.xsl $wpkgroot/profiles.xml 2>&1", $return_value);
			if ( $return_value != 0 ) {
				print_r("Err $return_value : xsltproc --stringparam 'date' '$Maintenant' --stringparam 'user' '$login' $wpkgwebdir/bin/profilesXml.xsl $wpkgroot/profiles.xml");
			}
		}
	} else {
		header("HTTP/1.1 404 Not found");
		header("Status: 404 Not found"); 
		echo "Erreur : Le fichier $PathFichier est introuvable !\n";
		echo "Sans doute un problème de droits.\n";
		return false;
	}
*/
}
?>
