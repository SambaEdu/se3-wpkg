<?php


// ## $Id$ ##


include "includes/wpkg.auth.php";
if ( isWpkgUser($config, $login) && ($login != "")) {
	$filename = "profiles.xml";
	$Maintenant = strftime ( "%D_%T" );
	exec ( "if [ $wpkgroot/profiles.xml -nt $wpkgroot/tmp/profiles.$login.xml ]; then xsltproc --output $wpkgroot/tmp/profiles.$login.xml --stringparam 'date' '$Maintenant' --stringparam 'user' '$login' $wpkgwebdir/bin/profilesXml.xsl $wpkgroot/profiles.xml 2>&1 ; fi", $output, $return_value);
	if ( $return_value == 0 ) {
		get_xml($config, $login, "tmp/profiles.$login.xml");
	} else {
		header("HTTP/1.1 505 Exec error");
		header("Status: 505 Erreur d'execution"); 
		print_r($output);
	}
}
?>
