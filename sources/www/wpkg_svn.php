<?php

	$url_stable='http://wawadeb.crdp.ac-caen.fr/wpkg-list-ng/packages_stable.xml';
	$url_testing='http://wawadeb.crdp.ac-caen.fr/wpkg-list-ng/packages_testing.xml';
	$url_XP='http://wawadeb.crdp.ac-caen.fr/wpkg-list-ng/packages_XP.xml';
	$url_forum = "/var/www/sambaedu/wpkg/forum.xml";

	$xml = new DOMDocument;
	$xml->formatOutput = true;
	$xml->preserveWhiteSpace = false;
	$xml->load($url_stable);
	$element = $xml->documentElement;
	$packages = $xml->documentElement->getElementsByTagName('package');
	
	foreach ($packages as $package)
	{
		$package->setAttribute("forum", "stable");
	}

	$xml2 = new DOMDocument;
	$xml2->formatOutput = true;
	$xml2->preserveWhiteSpace = false;
	$xml2->load($url_testing);
	$packages2 = $xml2->documentElement->getElementsByTagName('package');
	
	foreach ($packages2 as $package2)
	{
		$package2->setAttribute("forum", "test");
	}
	foreach ($xml2->documentElement->childNodes as $node2)
      $xml->documentElement->appendChild($xml->importNode($node2, TRUE));
	
	
	$xml3 = new DOMDocument;
	$xml3->formatOutput = true;
	$xml3->preserveWhiteSpace = false;
	$xml3->load($url_XP);
	$packages3 = $xml3->documentElement->getElementsByTagName('package');
	
	foreach ($packages3 as $package3)
	{
		$package3->setAttribute("forum", "XP");
	}
	foreach ($xml3->documentElement->childNodes as $node3)
      $xml->documentElement->appendChild($xml->importNode($node3, TRUE));
	
	$xml->save($url_forum);
?>