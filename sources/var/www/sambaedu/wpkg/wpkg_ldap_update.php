<?php

include("wpkg_libsql.php");
include("ldap.inc.php");

$liste_postes=info_postes();
$liste_parcs=info_parcs();
$liste_hosts_brut=search_computers("(&(cn=*)(objectClass=ipHost))");
$liste_parc_brut=search_machines("objectclass=groupOfNames", "parcs");
$liste_parc_brut[]["cn"]="_TousLesPostes";

$liste_parcs_tmp=$liste_parcs;
foreach ($liste_parc_brut as $parc)
{
	if (isset($liste_parcs[$parc["cn"]]))
	{
		//echo "Le parc ".$parc["cn"]." existait déjà.<br>";
	}
	else
	{
		$id_parc=insert_parc($parc["cn"]);
		$liste_parcs[$parc["cn"]]["id"]=$id_parc;
		//echo "<b>Le parc ".$parc["cn"]." a été créé.</b><br>";
	}
	$liste_parcs_tmp[$parc["cn"]]=array();
}

foreach ($liste_hosts_brut as $host)
{
	$liste_poste_parcs_ldap=search_parcs($host["cn"]);
	if ($liste_poste_parcs_ldap)
	{
		if (!isset($liste_postes[$host["cn"]]))
		{
			$info= array("nom_poste"=>$host["cn"]
						,"datetime"=>"2000-01-01 00:00:00"
						,"mac_address"=>""
						,"ip"=>""
						,"logfile"=>""
						,"rapportfile"=>""
						,"sha256"=>""
						,"typewin"=>"");
			$id_poste=insert_poste_info_wpkg($info);
			$liste_postes[$host["cn"]]["id"]=$id_poste;
			//echo "<b>Le poste ".$host["cn"]." a été créé.</b><br>";
		}
		else
		{
			//echo "Le poste ".$host["cn"]." existait déjà.<br>";
		}
	}
	$liste_poste_parc_sql=info_poste_parcs($host["cn"]);
	if (isset($liste_postes[$host["cn"]]))
	{
		$liste_poste_parcs_ldap[]["cn"]="_TousLesPostes";
		foreach ($liste_poste_parcs_ldap as $parcs)
		{
			if (isset($liste_poste_parc_sql[$parcs["cn"]]))
			{
				//echo "Le poste ".$host["cn"]." est déjà dans le parc ".$parcs["cn"].".<br>";
				$liste_poste_parc_sql[$parcs["cn"]]=array();
			}
			else
			{
				
				insert_parc_profile($liste_postes[$host["cn"]]["id"],$liste_parcs[$parcs["cn"]]["id"]);
				//echo "<b>Le poste ".$host["cn"]." a été ajouté au parc ".$parcs["cn"].".</b><br>";
				$liste_poste_parc_sql[$parcs["cn"]]=array();
			}
		}
	}
	foreach ($liste_poste_parc_sql as $parcs)
	{
		if (isset($parcs["id_parc"]))
		{
			delete_parc_profile($liste_postes[$host["cn"]]["id"],$liste_parcs[$parcs["nom_parc"]]["id"]);
			//echo "<b>Le poste ".$host["cn"]." a été supprimé du parc ".$parcs["nom_parc"].".</b><br>";
			$liste_poste_parc_sql[$parcs["cn"]]=array();
		}
	}
	$liste_postes[$host["cn"]]=array();
}
foreach ($liste_postes as $postes)
{
	if (isset($postes["id"]))
	{
		$liste_poste_parcs_ldap=search_parcs($postes["nom_poste"]);
		$liste_poste_parcs_ldap[]["cn"]="_TousLesPostes";
		$liste_poste_parc_sql=info_poste_parcs($postes["nom_poste"]);
		foreach ($liste_poste_parcs_ldap as $parcs)
		{
			if (isset($liste_poste_parc_sql[$parcs["cn"]]))
			{
				//echo "Le poste ".$postes["nom_poste"]." est déjà dans le parc ".$parcs["cn"].".<br>";
				$liste_poste_parc_sql[$parcs["cn"]]=array();
			}
			else
			{
				insert_parc_profile($postes["id"],$liste_parcs[$parcs["cn"]]["id"]);
				//echo "<b>Le poste ".$postes["nom_poste"]." a été ajouté au parc ".$parcs["cn"].".</b><br>";
				$liste_poste_parc_sql[$parcs["cn"]]=array();
			}
		}
		foreach ($liste_poste_parc_sql as $parcs)
		{
			if (isset($parcs["id_parc"]))
			{
				delete_parc_profile($postes["id"],$liste_parcs[$parcs["nom_parc"]]["id"]);
				//echo "<b>Le poste ".$postes["nom_poste"]." a été supprimé du parc ".$parcs["nom_parc"].".</b><br>";
				$liste_poste_parc_sql[$parcs["cn"]]=array();
			}
		}
	}
}
?>