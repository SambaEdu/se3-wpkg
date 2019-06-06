<?php

include("wpkg_libsql.php");

$url_time = "/var/se3/unattended/install/wpkg/tmp/timeStamps.xml";
$url_xml_tmp = "/var/se3/unattended/install/wpkg/tmp/";
$xml_time = simplexml_load_file($url_time);
$liste_app=liste_applications();

foreach ($xml_time->package as $app)
{
	$id_nom_app=(string) $app["id"];
	$md5=hash('md5',$id_nom_app);
	if (isset($liste_app[$md5]))
	{
		$id_app=$liste_app[$md5]["id_app"];
	}
	else
	{
		$id_app=0;
	}
	foreach ($app->op as $operation)
	{
		$date = new DateTime((string) $operation["date"]);
		$info=array("operation_journal_app"=>(string) $operation["op"],
					"user_journal_app"=>(string) $operation["user"],
					"date_journal_app"=>$date->format('Y-m-d H:i:s'),
					"xml_journal_app"=>(string) $operation["xml"],
					"sha_journal_app"=>"md5:".(string) $operation["md5sum"]);
		insert_journal_app($id_app,$info);
	}
}

update_sha_xml_journal($url_xml_tmp);

?>