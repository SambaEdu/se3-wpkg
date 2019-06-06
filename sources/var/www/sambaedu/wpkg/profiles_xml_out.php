<?php

	include("wpkg_libsql.php");

	if (isset($_GET["poste"]))
	{
		$nom_poste=$_GET["poste"];
	}
	else
	{
		echo "Erreur! Pas de machine déclarée.";
		exit;
	}

	$liste_applications=info_poste_applications($nom_poste);

	$xml_profile = new DOMDocument;
	$xml_profile->formatOutput = true;
	$xml_profile->preserveWhiteSpace = false;
	$root=$xml_profile->createElement("profiles");
	$xml_profile->appendChild($root);
	$comment=$xml_profile->createComment(" Fichier genere par SambaEdu. Ne pas modifier.");
	$root->appendChild($comment);

	// Ajout de la nouvelle entree
	$profile = new DOMElement('profile');
	$new_profile = $root->appendChild($profile);
	$new_profile->setAttribute("id",$nom_poste);
	foreach ($liste_applications as $info_app)
	{
		$new_package = new DOMElement('package');
		$new_package2 = $new_profile->appendChild($new_package);
		$new_package2->setAttribute("package-id", $info_app["info_app"]["id_nom_app"]);
	}

	$xml_profile->encoding = 'UTF-8';
	echo header('Content-type: text/xml');
	echo $xml_profile->saveXML();

?>