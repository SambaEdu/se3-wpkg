<?php
/**
 * Affichage de la liste des applications d'un parc
 * @Version $Id$
 * @Projet LCS / SambaEdu
 * @auteurs  Laurent Joly
 * @note
 * @Licence Distribue sous la licence GPL
 */
/**
 * @Repertoire: dhcp
 * file: reservations.php
*/
	// loading libs and init
	include "entete.inc.php";
	include "ldap.inc.php";
	include "ihm.inc.php";
	$login = isauth();
	if (! $login )
	{
		echo "<script language=\"JavaScript\" type=\"text/javascript\">\n<!--\n";
		$request = '/wpkg/index.php';
		echo "top.location.href = '/auth.php?request=" . rawurlencode($request) . "';\n";
		echo "//-->\n</script>\n";
		exit;
	}
	
	if (is_admin("computers_is_admin",$login)!="Y")
		die (gettext("Vous n'avez pas les droits suffisants pour acc&#233;der &#224; cette fonction")."</BODY></HTML>");
	
	// HTMLpurifier
	include("../se3/includes/library/HTMLPurifier.auto.php");
	$config = HTMLPurifier_Config::createDefault();
	$purifier = new HTMLPurifier($config);
	if (isset($_GET["tri"]))
		$tri=$purifier->purify($_GET["tri"])+0;
	else
		$tri=0;

	echo "<h1>Liste des applications d&#233;ployables sur votre SE3</h1>";
	
	$svnurl="http://svn.tice.ac-caen.fr/svn/SambaEdu3/wpkg-packages-ng";
	
	$xml_packages = simplexml_load_file("/var/se3/unattended/install/wpkg/packages.xml");
	$xml_profiles = simplexml_load_file("/var/se3/unattended/install/wpkg/profiles.xml");
	$xml_time = simplexml_load_file("/var/se3/unattended/install/wpkg/tmp/timeStamps.xml");
	
	$liste_appli=array();
	$liste_profiles=array();
	$liste_profiles2=array();
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
	
	foreach ($xml_packages->package as $app)
	{
		if ($app["category2"]!="")
			$app["category"]=$app["category2"];
		else
			$app["category"]=$app["category"]."*";
		$liste_appli[] = array("id"=>$app["id"],
						 "category"=>str_replace("'"," ",$app["category"]),
						 "name"=>str_replace("'"," ",$app["name"]),
						 "compatibilite"=>$app["compatibilite"],
						 "revision"=>$app["revision"],
						 "date"=>$liste_time[(string) $app["id"]]["date"],
						 "date2"=>$liste_time[(string) $app["id"]]["date2"]);
	}
	
	
	foreach ($xml_profiles->profile as $profile1)
	{
		foreach ($profile1->package as $profile2)
			$liste_profiles[(string) $profile2["package-id"]][] = (string) $profile1["id"];
		foreach ($profile1->depends as $profile2)
			$liste_profiles2[(string) $profile2["profile-id"]][] = (string) $profile1["id"];
	}
	
	foreach ($liste_appli as $key => $row)
	{
		$name[$key]  = strtolower($row['name']);
		$category[$key] = strtolower($row['category']);
		$compatibilite[$key] = $row['compatibilite']+0;
		$revision[$key] = $row['revision'];
		$date[$key] = $row['date'];
	}
	
	switch ($tri)
	{
		case 0:
		array_multisort($name, SORT_ASC, $liste_appli);
		break;
		case 1:
		array_multisort($category, SORT_ASC, $name, SORT_ASC, $liste_appli);
		break;
		case 2:
		array_multisort($compatibilite, SORT_DESC, $name, SORT_ASC, $liste_appli);
		break;
		case 3:
		array_multisort($name, SORT_DESC, $liste_appli);
		break;
		case 4:
		array_multisort($category, SORT_DESC, $name, SORT_ASC, $liste_appli);
		break;
		case 5:
		array_multisort($compatibilite, SORT_ASC, $name, SORT_ASC, $liste_appli);
		break;
		case 6:
		array_multisort($date, SORT_DESC, $name, SORT_ASC, $liste_appli);
		break;
		case 7:
		array_multisort($date, SORT_ASC, $name, SORT_ASC, $liste_appli);
		break;
		default:
		array_multisort($name, SORT_ASC, $branche, SORT_ASC, $liste_appli);
		break;
	}

	
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<th width='300'><a href='?tri=";
	if ($tri==0)
		echo "3";
	else
		echo "0";
	echo "'>Nom de l'application</a></th>";
	echo "<th width='120'>Version</th>";
	echo "<th width='120'><a href='?tri=";
	if ($tri==2)
		echo "5";
	else
		echo "2";
	echo "'>Compatibilit&#233;</a></th>";
	echo "<th width='150'><a href='?tri=";
	if ($tri==1)
		echo "4";
	else
		echo "1";
	echo "'>Cat&#233;gorie</a></th>";
	echo "<th width='120'>Liste des parcs</th>";
	echo "<th width='150'><a href='?tri=";
	if ($tri==6)
		echo "7";
	else
		echo "6";
	echo "'>Date d'ajout</a></th>";
	echo "</tr>";
	foreach ($liste_appli as $application)
	{
		echo "<tr bgcolor='white' height='30' valing='center'>";
		echo "<td><a href='index.php?extractAppli=".$application["id"]."' target='info'>".$application["name"]."</a></td>";
		echo "<td align='center'>".$application["revision"]."</td>";
		echo "<td align='center'>";
		
		switch ($application["compatibilite"])
		{
			case 1:
			echo "<img src='winxp.png' witdh='20' height='20'>";
			break;
			case 2:
			echo "<img src='win7.png' witdh='20' height='20'>";
			break;
			case 3:
			echo "<img src='winxp.png' witdh='20' height='20'><img src='win7.png' witdh='20' height='20'>";
			break;
			case 4:
			echo "<img src='win10.png' witdh='20' height='20'>";
			break;
			case 5:
			echo "<img src='winxp.png' witdh='20' height='20'><img src='win10.png' witdh='20' height='20'>";
			break;
			case 6:
			echo "<img src='win7.png' witdh='20' height='20'><img src='win10.png' witdh='20' height='20'>";
			break;
			case 7:
			echo "<img src='winxp.png' witdh='20' height='20'><img src='win7.png' witdh='20' height='20'><img src='win10.png' witdh='20' height='20'>";
			break;
			case 0:
			echo "";
			break;
			default:
			echo "";
			break;
			
		}
		echo "</td>";
		echo "<td align='center'>".$application["category"]."</td>";
		echo "<td align='center'>";
		if (isset($liste_profiles[(string) $application["id"]]))
		{
			$i=0;
			foreach ($liste_profiles[(string) $application["id"]] as $toto)
			{
				if ($i>0)
					echo ", ";
				else
					$i++;
				echo $toto;
			}
		}
		echo "</td>";
		echo "<td align='center'>".$application["date2"]."</td>";
		echo "</tr>";

	}
	echo "</table>";
include ("pdp.inc.php");
?>
