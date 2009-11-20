<?php
// ## $Id$ ##
//$DEBUG=1;
foreach($_GET AS $key => $value) {
	${$key} = $value;
}
$login = "";
$wpkgAdmin = false;
$wpkgUser = false;

include "inc/wpkg.auth.php";


if ( $wpkgUser && ($login != "")) {
	$xml="$wpkgroot/tmp/wpkg.$login.xml";
	$xsl="";
	switch ( $page ) {
		case "PackagesProfiles":
			$xsl="$wpkgwebdir/PackagesProfiles.xsl";
			$parametres=array("login" => $login, "Navigateur" => $Navigateur, "sortPackages" => $sortPackages, "sortProfiles" => $sortProfiles);
			break;
		case "AjoutPackage":
			if(! is_file("$wpkgwebdir/forum.xml")) {
				if ($handle = fopen("$wpkgwebdir/forum.xml", 'w')) {
					fwrite($handle, '<packages/>');
					fclose($handle);				
				}
			}
			$xsl="$wpkgwebdir/AjoutPackage.xsl";
			$parametres=array("login" => $login, "Navigateur" => $Navigateur, "MAJPackages" => $MAJPackages, "urlWawadeb" => $urlWawadeb, "urlWawadebMD5" => $urlWawadebMD5, "wpkgAdmin" => $wpkgAdmin?1:0, "wpkgUser" => $wpkgUser?1:0);
			break;
		case "AfficheProfile":
			$xsl="$wpkgwebdir/AfficheProfile.xsl";
			$parametres=array("login" => $login, "Navigateur" => $Navigateur, "idProfile" => $idProfile);
			break;
		case "AffichePackage":
			$xsl="$wpkgwebdir/AffichePackage.xsl";
			$parametres=array("login" => $login, "Navigateur" => $Navigateur, "idPackage" => $idPackage, "idProfile" => $idProfile);
			break;
		case "AfficheHost":
			$xsl="$wpkgwebdir/AfficheHost.xsl";
			$parametres=array("login" => $login, "Navigateur" => $Navigateur, "idHost" => $idHost);
			break;
		default:
			header("HTTP/1.1 505 Exec error");
			header("Status: 505 Erreur d'execution"); 
			echo "Parametre page non défini !";
	}
	$Maintenant = strftime ( "%D_%T" );
	exec ( "sh $wpkgwebdir/bin/wpkgXml.sh '$login'", $output, $return_value);
	if ( $return_value == 0 ) {
		get_html($xsl, $xml, $parametres);
	} else {
		header("HTTP/1.1 505 Exec error");
		header("Status: 505 Erreur d'execution"); 
		print_r($output);
	}
}
?>
