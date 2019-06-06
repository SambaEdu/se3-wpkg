<?php

include("wpkg_libsql.php");

$url_profiles = "/var/se3/unattended/install/wpkg/profiles.xml";
$url_hosts = "/var/se3/unattended/install/wpkg/hosts.xml";
$xml_profiles = simplexml_load_file($url_profiles);
$xml_hosts = simplexml_load_file($url_hosts);

$liste_postes=info_postes();
$liste_parcs=info_parcs();
$liste_app=liste_applications();
truncate_table_profiles();

foreach ($xml_hosts->host as $poste)
{
	if (!isset($liste_postes[(string) $poste["name"]]))
	{
		$info= array("nom_poste"=>(string) $poste["name"]
					,"datetime"=>"2000-01-01 00:00:00"
					,"mac_address"=>""
					,"ip"=>""
					,"logfile"=>""
					,"rapportfile"=>""
					,"sha256"=>""
					,"typewin"=>"");
		$id_poste=insert_poste_info_wpkg($info);
		$liste_postes[(string) $profile["id"]]["id"]=$id_poste;
	}
}
	
foreach ($xml_profiles->profile as $profile)
{
	if (isset($liste_postes[(string) $profile["id"]]))
	{
		$id_poste=$liste_postes[(string) $profile["id"]]["id"];
		$id_parc=-1;
	}
	elseif (isset($liste_parcs[(string) $profile["id"]]))
	{
		$id_parc=$liste_parcs[(string) $profile["id"]]["id"];
		$id_poste=-1;
	}
	else
	{
		$id_parc=insert_parc((string) $profile["id"]);
		$liste_parcs[(string) $profile["id"]]["id"]=$id_parc;
		$id_poste=-1;
	}
	
	foreach ($profile->package as $package)
	{
		$md5=hash('md5',(string) $package["package-id"]);
		if (isset($liste_app[$md5]))
		{
			$id_app=$liste_app[$md5]["id_app"];
			if ($id_parc>0)
			{
				insert_application_profile("parc",$id_parc,$id_app);
			}
			else
			{
				insert_application_profile("poste",$id_poste,$id_app);
			}
		}
		else
		{
			echo "app inconnue : ".(string) $package["package-id"]."<br>";
		}
	}
	foreach ($profile->depends as $depends)
	{
		insert_parc_profile($id_poste,$liste_parcs[(string) $depends["profile-id"]]["id"]);
	}
}
?>