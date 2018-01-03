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
	
	$xml->save("/var/se3/unattended/install/wpkg/profiles_test.xml");
	
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
	
	$xml->save("/var/se3/unattended/install/wpkg/profiles_test.xml");
	
	return $result;
}

?>