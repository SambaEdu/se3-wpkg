<?php
/**
 * librairie
 * @Version $Id$
 * @Projet LCS / SambaEdu
 * @auteurs  Laurent Joly
 * @note
 * @Licence Distribue sous la licence GPL
 */
/**
 * @Repertoire: wpkg
 * file: wpkg_lib.php
*/

	
	
	// listes des fonctions
/*

	set_app_parcs($post_parc,$get_Appli,$liste_parcs,$url_profiles)
	set_app_postes($post_host,$get_Appli,$liste_parcs,$url_profiles)
	set_parc_apps($post_appli,$get_parc,$url_profiles)
	remove_app($get_Appli,$url_packages)
	clean_timeStamps($url_time)
	update_timeStamps($url_time,$get_Appli,$operation,$xml,$md5sum,$login)
	
*/


function set_app_parcs($post_parc,$get_Appli,$liste_parcs,$url_profiles)
{	
	$xml = new DOMDocument;
	$xml->formatOutput = true;
	$xml->preserveWhiteSpace = false;
	$xml->load($url_profiles);
	$element = $xml->documentElement;
	$profiles = $xml->documentElement->getElementsByTagName('profile');

	$result=array("out"=>0,"in"=>0);
	
	foreach ($profiles as $profile)
	{
		$packages=$profile->getElementsByTagName('package');
		if (in_array($profile->getAttribute('id'), $liste_parcs))
		{
			foreach ($packages as $package)
			{
				if ($package->getAttribute('package-id')==$get_Appli)
					$profile->removeChild($package);
			}
			
			if (in_array($profile->getAttribute('id'), $post_parc))
			{
				$new_package = new DOMElement('package');
				$new_package2 = $profile->appendChild($new_package);
				$new_package2->setAttribute("package-id", $get_Appli);
				$result["in"]++;
			}
			else
				$result["out"]++;
		}
	}
	
	$xml->save($url_profiles);
	
	return $result;
}

function set_app_postes($post_host,$get_Appli,$liste_parcs,$url_profiles)
{	
	$xml = new DOMDocument;
	$xml->formatOutput = true;
	$xml->preserveWhiteSpace = false;
	$xml->load($url_profiles);
	$element = $xml->documentElement;
	$profiles = $xml->documentElement->getElementsByTagName('profile');

	$result=array("out"=>0,"in"=>0);
	
	foreach ($profiles as $profile)
	{
		$packages=$profile->getElementsByTagName('package');
		if (!in_array($profile->getAttribute('id'), $liste_parcs))
		{
			foreach ($packages as $package)
			{
				if ($package->getAttribute('package-id')==$get_Appli)
					$profile->removeChild($package);
			}
			
			if (in_array($profile->getAttribute('id'), $post_host))
			{
				$new_package = new DOMElement('package');
				$new_package2 = $profile->appendChild($new_package);
				$new_package2->setAttribute("package-id", $get_Appli);
				$result["in"]++;
			}
			else
				$result["out"]++;
		}
	}
	
	$xml->save($url_profiles);
	
	return $result;
}

function set_parc_apps($post_appli,$get_parc,$url_profiles)
{
	$xml = new DOMDocument;
	$xml->formatOutput = true;
	$xml->preserveWhiteSpace = false;
	$xml->load($url_profiles);
	$element = $xml->documentElement;
	$profiles = $xml->documentElement->getElementsByTagName('profile');

	$result=array("out"=>0,"in"=>0);
	
	foreach ($profiles as $profile)
	{
		if ($profile->getAttribute('id')==$get_parc)
		{
			$packages=$profile->getElementsByTagName('package');
			$length = $packages->length; $i=$length;
			for ($i=$length-1; $i>=0; $i--)
			{
				$profile->removeChild($packages->item($i));
			}
			foreach ($post_appli as $appli)
			{
				$new_package = new DOMElement('package');
				$new_package2 = $profile->appendChild($new_package);
				$new_package2->setAttribute("package-id", $appli);
				$result["in"]++;
			}
		}
	}
	
	$xml->save($url_profiles);
	
	return $result;
}

function remove_app($get_Appli,$url_packages)
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
	$comment=$xml2->createComment(" Fichier genere par SambaEdu. Ne pas modifier. Il contient ".($length-1)." applications. ");
	$root->appendChild($comment);
	$packages2 = $xml2->documentElement->getElementsByTagName('package');
	
	$result=0;
	
	foreach ($packages as $package)
	{
		if ($package->getAttribute('id')==$get_Appli)
		{
			$return=1;
		}
		else
		{
			$node=$xml2->importNode($package, true);
			$xml2->documentElement->appendChild($node);
		}
	}
	
	$xml2->save($url_packages);
	
	return $return;
}

function clean_timeStamps($url_time)
{
	$xml_time = new DOMDocument;
	$xml_time->formatOutput = true;
	$xml_time->preserveWhiteSpace = false;
	$xml_time->load($url_time);
	$element_time = $xml_time->documentElement;
	$packages_time = $xml_time->documentElement->getElementsByTagName('package');

	$result=array();
	
	foreach ($packages_time as $package_time)
	{
		$ops_time = $package_time->getElementsByTagName('op');
		$length = $ops_time->length; $i=$length;
		for ($i=$length-4; $i>=0; $i--)
		{
			$package_time->removeChild($ops_time->item($i));
		}
	}
	$xml_time->save($url_time);
	
	return 1;
}

function update_timeStamps($url_time,$get_Appli,$operation,$xml,$md5sum,$login)
{
	$xml_time = new DOMDocument;
	$xml_time->formatOutput = true;
	$xml_time->preserveWhiteSpace = false;
	$xml_time->load($url_time);
	$element_time = $xml_time->documentElement;
	$packages_time = $xml_time->documentElement->getElementsByTagName('package');

	$date=date(DATE_ATOM);
	
	foreach ($packages_time as $package_time)
	{
		if ($package_time->getAttribute('id')==$get_Appli)
		{
				$new_operation = new DOMElement('op');
				$new_operation2 = $package_time->appendChild($new_operation);
				$new_operation2->setAttribute("op", $operation);
				$new_operation2->setAttribute("date", $date);
				if ($operation=="add")
				{
					$new_operation2->setAttribute("xml", $xml);
					$new_operation2->setAttribute("md5sum", $md5sum);
				}
				$new_operation2->setAttribute("user", $login);
		}
	}

	
	$xml_time->save($url_time);
	
	return 1;
}

?>