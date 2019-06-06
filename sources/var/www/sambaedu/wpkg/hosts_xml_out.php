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

	$xml_host = new DOMDocument;
	$xml_host->formatOutput = true;
	$xml_host->preserveWhiteSpace = false;
	$root=$xml_host->createElement("wpkg");
	$xml_host->appendChild($root);
	$comment=$xml_host->createComment(" Fichier genere par SambaEdu. Ne pas modifier.");
	$root->appendChild($comment);

	// Ajout de la nouvelle entree
	$host = new DOMElement('host');
	$new_host = $root->appendChild($host);
	$new_host->setAttribute("name",$nom_poste);
	$new_host->setAttribute("profile-id",$nom_poste);

	$xml_host->encoding = 'UTF-8';
	echo header('Content-type: text/xml');
	echo $xml_host->saveXML();
?>