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

// localisation wpkg

	$url_wpkg = "/var/se3/unattended/install";

// localisation des xml de wpkg

	$url_packages = "/var/se3/unattended/install/wpkg/packages.xml";
	$url_profiles = "/var/se3/unattended/install/wpkg/profiles.xml";
	$url_rapports = "/var/se3/unattended/install/wpkg/rapports/rapports.xml";
	$url_time = "/var/se3/unattended/install/wpkg/tmp/timeStamps.xml";
	$url_hosts = "/var/se3/unattended/install/wpkg/hosts.xml";
	$url_forum = "/var/www/se3/wpkg/forum.xml";

// Chargement des xml avec simpleXML

	include("wpkg_lib_load_xml.php");

// Liste des applications protegees

	$list_protected_app=array("wsusoffline", "ocs-client");

// listes des fonctions
/*

	get_list_wpkg_hosts($xml_hosts) : liste des hosts
	get_list_wpkg_parcs($xml_profiles) : liste des parcs
	get_list_wpkg_time($xml_time) : liste des horodatages des applications
	get_list_wpkg_app($xml_packages, $xml_time) : liste des applications
	get_list_wpkg_parc_app($xml_profiles) : liste des parcs par application
	get_list_wpkg_poste_parc($xml_profiles) : liste des postes par parc
	get_list_wpkg_poste_app($xml_profiles, $xml_hosts) : liste des postes demandes pour une appli
	get_list_wpkg_depend_app($xml_packages) : liste des dependances d une appli
	get_list_wpkg_required_by_app($xml_packages) : liste des applis dependant d une appli
	get_list_wpkg_poste_app_all($xml_profiles,$xml_packages) : liste complete des postes pour une appli
	get_list_wpkg_rapports_statut_poste_app($xml_rapports) : status des app installees sur un poste
	get_list_wpkg_rapports_statut_app($xml_rapports) : status d une app installee
	get_list_wpkg_file_app($xml_packages, $appli) : liste des fichiers d'une application donnee
	get_list_wpkg_postes_status($liste_hosts,$xml_packages,$xml_rapports,$xml_profiles,$xml_hosts) : Liste de l'état des postes
	
	---
	
	get_list_wpkg_svn_info($xml_forum) : info des app dispo sur le svn
	get_wpkg_branche_XP() : mode XP ou non
	
	---
	
	get_list_wpkg_app_status($liste_hosts,$liste_appli_postes,$liste_appli_status,$revision) : statuts des postes pour une app donnee
	
*/
	function get_list_wpkg_hosts($xml_hosts)
	{
		$list_host=array();
		foreach ($xml_hosts->host as $host1)
		{
			$list_host[(string) $host1["profile-id"]] = (string) $host1["name"];
		}
		return $list_host;
	}

	function get_list_wpkg_parcs($xml_profiles)
	{
		$list_parcs=array();
		foreach ($xml_profiles->profile as $profile1)
		{
			$parc=1;
			foreach ($profile1->depends as $profile2)
			{
				if ((string) $profile2["profile-id"]=="_TousLesPostes")
					$parc=0;
			}
			if ($parc==1)
				$list_parcs[] = (string) $profile1["id"];
		}
		return $list_parcs;
	}
	
	function get_list_wpkg_time($xml_time)
	{
		$liste_time=array();
		foreach ($xml_time->package as $time_package)
		{
			foreach ($time_package->op as $time_op)
			{
				sscanf($time_op["date"],"%4u-%2u-%2uT%2u:%2u:%2uZ",$annee,$mois,$jour,$heure,$minute,$seconde);
				$newTstamp = mktime($heure,$minute,$seconde,$mois,$jour,$annee)+3600;
				$liste_time[(string) $time_package["id"]] = array ("date"=>(string) $time_op["date"],
																	"date2"=>date("d/m/Y à H:i:s", $newTstamp));
			}
		}
		return $liste_time;
	}
	
	function get_list_wpkg_app($xml_packages, $xml_time)
	{
		$list_appli=array();
		$liste_time = get_list_wpkg_time($xml_time);
		foreach ($xml_packages->package as $app)
		{
			if ($app["category2"]!="")
				$app["category"]=(string) $app["category2"];
			else
				$app["category"]=$app["category"]."*";
			$list_appli[(string) $app["id"]]["id"] = (string) $app["id"];
			$list_appli[(string) $app["id"]]["category"] = str_replace("'"," ",(string) $app["category"]);
			$list_appli[(string) $app["id"]]["name"] = str_replace("'"," ",(string) $app["name"]);
			$list_appli[(string) $app["id"]]["compatibilite"] = (string) $app["compatibilite"];
			$list_appli[(string) $app["id"]]["revision"] = (string) $app["revision"];
			$list_appli[(string) $app["id"]]["reboot"] = (string) $app["reboot"];
			$list_appli[(string) $app["id"]]["priority"] = (string) $app["priority"];
			$list_appli[(string) $app["id"]]["date"] = $liste_time[(string) $app["id"]]["date"];
			$list_appli[(string) $app["id"]]["date2"] = $liste_time[(string) $app["id"]]["date2"];
			foreach ($app->depends as $app_dep)
			{
				$list_appli[(string) $app["id"]]["depends"][]=(string) $app_dep["package-id"];
				$list_appli[(string) $app_dep["package-id"]]["required_by"][]=(string) $app["id"];
			}
		}
		return $list_appli;
	}
	
	function get_list_wpkg_parc_app($xml_profiles)
	{
		$list_profiles=array();
		$list_parcs=get_list_wpkg_parcs($xml_profiles);
		foreach ($xml_profiles->profile as $profile1)
		{
			foreach ($profile1->package as $profile2)
			{
				if (in_array((string) $profile1["id"],$list_parcs))
					$list_profiles[(string) $profile2["package-id"]][] = (string) $profile1["id"];
			}
		}
		return $list_profiles;
	}
	
	
	function get_list_wpkg_poste_parc($xml_profiles)
	{
		$list_profiles=array();
		foreach ($xml_profiles->profile as $profile1)
		{
			foreach ($profile1->depends as $profile2)
			{
				$list_profiles[(string) $profile2["profile-id"]][] = (string) $profile1["id"];
			}
		}
		return $list_profiles;
	}
	
	function get_list_wpkg_poste_app($xml_profiles, $xml_hosts)
	{
		$list_profiles=array();
		$list_hosts=get_list_wpkg_hosts($xml_hosts);
		foreach ($xml_profiles->profile as $profile1)
		{
			foreach ($profile1->package as $profile2)
			{
				if (array_key_exists((string) $profile1["id"],$list_hosts))
					$list_profiles[(string) $profile2["package-id"]][(string) $profile1["id"]] = (string) $profile1["id"];
			}
		}
		return $list_profiles;
	}
	
	function get_list_wpkg_depend_app($xml_packages)
	{
		$list_profiles=array();
		foreach ($xml_packages->package as $package)
		{
			foreach ($package->depends as $package2)
			{
				$list_profiles[(string) $package["id"]][] = (string) $package2["package-id"];
			}
		}
		return $list_profiles;
	}
	
	function get_list_wpkg_required_by_app($xml_packages)
	{
		$list_profiles=array();
		foreach ($xml_packages->package as $package)
		{
			foreach ($package->depends as $package2)
			{
				$list_profiles[(string) $package2["package-id"]][] = (string) $package["id"];
			}
		}
		return $list_profiles;
	}
	
	function get_list_wpkg_poste_app_all($xml_profiles,$xml_packages)
	{
		$list_parc=get_list_wpkg_parcs($xml_profiles);
		$poste_parc=get_list_wpkg_poste_parc($xml_profiles);
		$list_depend=get_list_wpkg_depend_app($xml_packages);
		$list_profiles=array();
		foreach ($xml_profiles->profile as $profile1)
		{
			foreach ($profile1->package as $profile2)
			{
				if (array_key_exists((string) $profile1["id"],$poste_parc))
				{
					foreach ($poste_parc[(string) $profile1["id"]] as $poste)
					{
						$list_profiles[(string) $profile2["package-id"]][$poste]["parc"][(string) $profile1["id"]] = (string) $profile1["id"];
						if (isset($list_depend[(string) $profile2["package-id"]]))
						{
							foreach ($list_depend[(string) $profile2["package-id"]] as $depend)
							{
								$list_profiles[$depend][$poste]["depend"][(string) $profile2["package-id"]] = (string) $profile2["package-id"];
							}
						}
					}
				}
				elseif (!in_array((string) $profile1["id"], $list_parc))
				{
					$list_profiles[(string) $profile2["package-id"]][(string) $profile1["id"]]["poste"] = (string) $profile1["id"];
					if (isset($list_depend[(string) $profile2["package-id"]]))
					{
						foreach ($list_depend[(string) $profile2["package-id"]] as $depend)
						{
							$list_profiles[$depend][(string) $profile1["id"]]["depend"][(string) $profile2["package-id"]] = (string) $profile2["package-id"];
						}
					}
				}
			}
		}
		return $list_profiles;
	}

	function get_list_wpkg_rapports_statut_poste_app($xml_rapports)
	{
		$liste_statuts=array();
		foreach ($xml_rapports->rapport as $rapport)
		{
			$liste_statuts[(string) $rapport["id"]]["info"] = array("datetime"=>(string) $rapport["datetime"],
																	"date"=>(string) $rapport["date"],
																	"time"=>(string) $rapport["time"],
																	"mac"=>(string) $rapport["mac"],
																	"ip"=>(string) $rapport["ip"],
																	"typewin"=>(string) $rapport["typewin"],
																	"logfile"=>(string) $rapport["logfile"]);
			foreach ($rapport->package as $rapport2)
			{
				$liste_statuts[(string) $rapport["id"]][(string) $rapport2["id"]]=array("revision"=>(string) $rapport2["revision"],
																						"reboot"=>(string) $rapport2["reboot"],
																						"status"=>(string) $rapport2["status"]);
			}
		}
		return $liste_statuts;
	}
	
	function get_list_wpkg_rapports_statut_app($xml_rapports)
	{
		$liste_statuts=array();
		foreach ($xml_rapports->rapport as $rapport)
		{
			foreach ($rapport->package as $rapport2)
			{
				$liste_statuts[(string) $rapport2["id"]][(string) $rapport["id"]]=array("revision"=>(string) $rapport2["revision"],
																						"reboot"=>(string) $rapport2["reboot"],
																						"status"=>(string) $rapport2["status"]);
			}
		}
		return $liste_statuts;
	}
	
	
	function get_list_wpkg_file_app($xml_packages, $appli)
	{
		$liste_fichier=array();
		foreach ($xml_packages->package as $package)
		{
			if ((string) $package["id"]==$appli)
			{
				foreach ($package->download as $download)
				{
					$liste_fichier[]=(string) $download["saveto"];
				}1
			}
		}
		return $liste_fichier;
	}

	function get_list_wpkg_postes_status($id_parc,$xml_packages,$xml_rapports,$xml_profiles)
	{
		
		$list_parc=get_list_wpkg_parcs($xml_profiles); // liste des parcs
		$poste_parc=get_list_wpkg_poste_parc($xml_profiles); // liste des postes par parc
		$list_depend=get_list_wpkg_depend_app($xml_packages); // Liste des dépendances
		$list_profiles=array(); // liste des statuts des apps pour chaque poste
		$list_app_info=array(); // liste des infos pour chaque app
		$liste_statuts=array(); // liste des statuts des postes du parc

		if (!array_key_exists($id_parc,$poste_parc))
			return "-1";
		if (count($poste_parc[$id_parc])==0)
			return "0";
		
		foreach ($xml_profiles->profile as $profile1)
		{
			foreach ($profile1->package as $profile2)
			{
				if (array_key_exists((string) $profile1["id"],$poste_parc))
				{
					foreach ($poste_parc[(string) $profile1["id"]] as $poste)
					{
						$list_profiles[$poste]["app"][(string) $profile2["package-id"]]["deployed"]=1;
						if (isset($list_depend[(string) $profile2["package-id"]]))
						{
							foreach ($list_depend[(string) $profile2["package-id"]] as $depend)
							{
								$list_profiles[$poste]["app"][$depend]["deployed"]=1;
							}
						}
					}
				}
				elseif (!in_array((string) $profile1["id"], $list_parc))
				{
					$list_profiles[(string) $profile1["id"]]["app"][(string) $profile2["package-id"]]["deployed"]=1;
					if (isset($list_depend[(string) $profile2["package-id"]]))
					{
						foreach ($list_depend[(string) $profile2["package-id"]] as $depend)
						{
							$list_profiles[(string) $profile1["id"]]["app"][$depend]["deployed"]=1;
						}
					}
				}
			}
		}
		foreach ($xml_packages->package as $app)
		{
			$list_app_info[(string) $app["id"]]["id"] = (string) $app["id"];
			$list_app_info[(string) $app["id"]]["revision"] = (string) $app["revision"];
		}
		
		foreach ($xml_rapports->rapport as $rapport)
		{
			if (in_array((string) $rapport["id"],$poste_parc['$id_parc']))
			{
				$list_profiles[(string) $rapport["id"]]["info"] = array("datetime"=>(string) $rapport["datetime"],
																		"date"=>(string) $rapport["date"],
																		"time"=>(string) $rapport["time"],
																		"mac"=>(string) $rapport["mac"],
																		"ip"=>(string) $rapport["ip"],
																		"typewin"=>(string) $rapport["typewin"],
																		"logfile"=>(string) $rapport["logfile"]);
				foreach ($rapport->package as $rapport2)
				{
					$list_profiles[(string) $rapport["id"]]["app"][(string) $rapport2["id"]]["installed"]=$rapport2["status"];
					$list_profiles[(string) $rapport["id"]]["app"][(string) $rapport2["id"]]["revision"]=$rapport2["revision"];
				}
			}
		}
		
		foreach ($list_profiles as $poste_nom=>$info_poste)
		{
			$liste_statuts[$poste_nom]["info"]=$info_poste["info"];
			$liste_statuts[$poste_nom]["status"] = array("ok"=>0
														,"maj"=>0
														,"notok+"=>0
														,"notok-"=>0);
			foreach ($info_poste["app"] as $app_nom=>$info_app_poste)
			{
				if ($info_app_poste["deployed"]==1 and $info_app_poste["installed"]=="Installed")
				{
					if ($info_app_poste["revision"]==$list_app_info[$app_nom]["revision"])
						$liste_statuts[$poste_nom]["status"]["ok"]++;
					else
						$liste_statuts[$poste_nom]["status"]["maj"]++;
				}
				elseif ($info_app_poste["deployed"]==0 and $info_app_poste["installed"]=="Installed")
					$liste_statuts[$poste_nom]["status"]["notok+"]++;
				elseif ($info_app_poste["deployed"]==1 and $info_app_poste["installed"]=="Not Installed")
					$liste_statuts[$poste_nom]["status"]["notok-"]++;
			}
		}
		return $liste_statuts;
	}
	
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	function get_list_wpkg_svn_info($xml_forum)
	{
		$liste_svn=array();
		foreach ($xml_forum->package as $package)
		{
			sscanf($package["date"],"%4u-%2u-%2uT%2u:%2u:%2uZ",$annee,$mois,$jour,$heure,$minute,$seconde);
			$newTstamp = mktime($heure,$minute,$seconde,$mois,$jour,$annee)+3600;
			$liste_svn[(string) $package["id"]][(string) $package["forum"]] = array("id"=>(string) $package["id"],
																					"forum"=>(string) $package["forum"],
																					"xml"=>(string) $package["xml"],
																					"url"=>(string) $package["url"],
																					"md5sum"=>(string) $package["md5sum"],
																					"date"=>(string) $package["date"],
																					"date2"=>date("d/m/Y à H:i:s", $newTstamp),
																					"svn_link"=>(string) $package["svn_link"],
																					"category"=>(string) $package["category"],
																					"name"=>(string) $package["name"],
																					"compatibilite"=>(string) $package["compatibilite"],
																					"revision"=>(string) $package["revision"]);
		}
		return $liste_svn;
	}

	function get_wpkg_branche_XP()
	{
		$XP = fopen("/var/www/se3/wpkg/XP", "r");
		$XP_actif=fgets($XP);
		fclose($XP);
		return $XP_actif;
	}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	function get_list_wpkg_app_status($liste_hosts,$liste_appli_postes,$liste_appli_status,$revision)
	{
		$liste_status["NotOk"]=array();
		$liste_status["Ok"]=array();
		$liste_status["MaJ"]=array();
		foreach ($liste_hosts as $host_id => $host_name)
		{
			if (is_array($liste_appli_postes))
			{
				if (in_array($host_id, $liste_appli_postes))
				{
					if ($liste_appli_status[$host_id]["status"]=="Installed")
					{
						if ($liste_appli_status[$host_id]["revision"]==$revision)
						{
							$liste_status["Ok"][]=$host_id;
						}
						else
						{
							$liste_status["MaJ"][]=$host_id;
						}
					}
					else
					{
						$liste_status["NotOk"][]=$host_id;
					}
				}
				elseif ($liste_appli_status[$host_id]["status"]=="Installed")
				{
					$liste_status["NotOk"][]=$host_id;
				}
				else
				{
					$liste_status["Ok"][]=$host_id;
				}
			}
			elseif ($liste_appli_status[$host_id]["status"]=="Installed")
			{
				$liste_status["NotOk"][]=$host_id;
			}
			else
			{
				$liste_status["Ok"][]=$host_id;
			}
		}
		return $liste_status;
	}
?>