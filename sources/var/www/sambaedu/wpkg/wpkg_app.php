<?php

include("wpkg_libsql.php");

$url_packages = "/var/se3/unattended/install/wpkg/packages.xml";
$xml_packages = simplexml_load_file($url_packages);
$liste_app=liste_applications();

$depend=array();
foreach ($xml_packages->package as $app)
{
	$list_appli=array();
	if ($app["category2"]!="")
		$app["category"]=(string) $app["category2"];
	else
		$app["category"]=$app["category"]."*";
	$list_appli["id_nom_app"] = (string) $app["id"];
	$list_appli["categorie_app"] = str_replace("'"," ",(string) $app["category"]);
	$list_appli["nom_app"] = str_replace("'"," ",(string) $app["name"]);
	$list_appli["compatibilite_app"] = (string) $app["compatibilite"];
	$list_appli["version_app"] = (string) $app["revision"];
	$list_appli["reboot_app"] = (string) $app["reboot"];
	if ($list_appli["reboot_app"]=="false")
		$list_appli["reboot_app"]=0;
	else
		$list_appli["reboot_app"]=1;
	$list_appli["prorite_app"] = (string) $app["priority"];
	$list_appli["active_app"] = 1;

	$md5=hash('md5',$list_appli["id_nom_app"]);
	if (isset($liste_app[$md5]))
	{
		$id_app=$liste_app[$md5]["id_app"];
		update_applications($id_app,$list_appli);
	}
	else
	{
		insert_applications($list_appli);
	}

	foreach ($app->depends as $app_dep)
	{
		$depend[(string) $app["id"]][]=(string) $app_dep["package-id"];
	}
}

if ($depend)
{
	$liste_app=liste_applications();
	delete_dependances();
	foreach ($depend as $appli=>$required)
	{
		$md5A=hash('md5',$appli);
		$id_appli=$liste_app[$md5A]["id_app"];
		foreach ($required as $required2)
		{
			$md5B=hash('md5',$required2);
			$id_required=$liste_app[$md5B]["id_app"];
			insert_dependance($id_appli,$id_required);
		}
	}
}

?>