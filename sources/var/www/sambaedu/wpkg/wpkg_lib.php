<?php

// définition des style couleurs par defaut

	$warning_bg = "#FF0000";
	$warning_txt = "#FFFFFF";
	$warning_lnk = "#FFFF00";
	$error_bg = "#FFFF00";
	$error_txt = "#000000";
	$error_lnk = "#415594";
	$ok_bg = "#00FF00";
	$ok_txt = "#000000";
	$ok_lnk = "#415594";
	$unknown_bg = "#FFFFFF";
	$unknown_txt = "#000000";
	$unknown_lnk = "#415594";
	$regular_lnk = "#0080ff";
	$wintype_txt = "#FFF8DC";


	$dep_entite_bg = "#0000FF";
	$dep_entite_txt = "#FFFFFF";
	$dep_entite_lnk = "#FF0000";
	$dep_parc_bg = "#0080FF";
	$dep_parc_txt = "#000000";
	$dep_parc_lnk = "#FF0000";
	$dep_depend_bg = "#00FFFF";
	$dep_depend_txt = "#000000";
	$dep_depend_lnk = "#FF0000";
	$dep_no_bg = "#FFFFFF";
	$dep_no_txt = "#000000";
	$dep_no_lnk = "#FF0000";

// Liste des applications protegees

	$list_protected_app=array("wsusoffline", "ocs-client");

// localisation des repertoires

	$url_packages = "/var/se3/unattended/install/wpkg/packages.xml";
	$wpkgroot="/var/se3/unattended/install/wpkg";
	$wpkgwebdir="/var/www/se3/wpkg2";
	$wpkgroot2="/var/se3/unattended/install";

function extract_app($get_Appli,$url_packages)
{
	$xml = new DOMDocument;
	$xml->formatOutput = true;
	$xml->preserveWhiteSpace = false;
	$xml->load($url_packages);
	$element = $xml->documentElement;
	$packages = $xml->documentElement->getElementsByTagName('package');
	$length = $packages->length;

	$xml2 = new DOMDocument;
	$xml2->formatOutput = true;
	$xml2->preserveWhiteSpace = false;
	$root=$xml2->createElement("packages");
	$xml2->appendChild($root);
	//$comment=$xml2->createComment(" Fichier genere par SambaEdu. Ne pas modifier. Il contient ".($length-1)." applications. ");
	//$root->appendChild($comment);
	$packages2 = $xml2->documentElement->getElementsByTagName('package');

	foreach ($packages as $package)
	{
		if ($package->getAttribute('id')==$get_Appli)
		{
			$node=$xml2->importNode($package, true);
			$xml2->documentElement->appendChild($node);
		}
	}

	$xml2->encoding = 'UTF-8';

	return $xml2->saveXML();;
}

?>