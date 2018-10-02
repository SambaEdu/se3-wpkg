<?php

// loading libs and init
	include "entete.inc.php";
	include_once "ldap.inc.php";
	include "ihm.inc.php";
	include "wpkg_lib.php";
	
	$login = isauth();
	if (! $login )
	{
		echo "<script language=\"JavaScript\" type=\"text/javascript\">\n<!--\n";
		$request = '/wpkg/index.php';
		echo "top.location.href = '/auth.php?request=" . rawurlencode($request) . "';\n";
		echo "//-->\n</script>\n";
		exit;
	}
	
	if (!have_right($config, "computers_is_admin"))
		die (gettext("Vous n'avez pas les droits suffisants pour acc&#233;der &#224; cette fonction")."</BODY></HTML>");

	// HTMLpurifier
	include("../sambaedu/includes/library/HTMLPurifier.auto.php");
	$config = HTMLPurifier_Config::createDefault();
	$purifier = new HTMLPurifier($config);
	
	if (isset($_GET["tri"]))
		$tri=$purifier->purify($_GET["tri"])+0;
	else
		$tri=0;
	if (isset($_GET["tri2"]))
		$tri2=$purifier->purify($_GET["tri2"])+0;
	else
		$tri2=0;	
	if (isset($_GET['Appli']))
		$get_Appli=$purifier->purify($_GET['Appli']);
	else
		$get_Appli="";
	if (isset($_GET['parc']))
		$get_parc=$purifier->purify($_GET['parc']);
	else
		$get_parc="_TousLesPostes";
	if (isset($_GET["warning"]))
		$get_warning=$purifier->purify($_GET["warning"])+0;
	else
		$get_warning=1;
	if (isset($_GET["error"]))
		$get_error=$purifier->purify($_GET["error"])+0;
	else
		$get_error=1;
	if (isset($_GET["ok"]))
		$get_ok=$purifier->purify($_GET["ok"])+0;
	else
		$get_ok=1;
	
	header ("Location: parc_maintenance.php?tri2=".$tri2."&parc=".$get_parc."&ok=".$get_ok."&warning=".$get_warning."&error=".$get_error);
?>