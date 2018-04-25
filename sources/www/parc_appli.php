<?php
/**
 * Affichage de la liste des applications pour un parc
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
	include "wpkg_lib.php";
	
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
	if (isset($_GET["tri2"]))
		$tri2=$purifier->purify($_GET["tri2"])+0;
	else
		$tri2=0;	
	if (isset($_GET['Appli']))
		$get_Appli=$purifier->purify($_GET['Appli']);
	else
		$get_Appli="";
	if (isset($_GET['parc']))
		$get_parc=$purifier->purify($_GET['parc']);
	else
		$get_parc="_TousLesPostes";
	if (isset($_GET["warning"]))
		$get_warning=$purifier->purify($_GET["warning"])+0;
	else
		$get_warning=1;
	if (isset($_GET["error"]))
		$get_error=$purifier->purify($_GET["error"])+0;
	else
		$get_error=1;
	if (isset($_GET["ok"]))
		$get_ok=$purifier->purify($_GET["ok"])+0;
	else
		$get_ok=1;

	echo "<form method='get' action=''>\n";
	$page_id=2;
	include ("parc_top.php");
	echo "</form>\n";
	


	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	
	$list_app=get_list_wpkg_app($xml_packages, $xml_time);
	$list_app_parc=get_list_wpkg_app_parc($xml_profiles,$xml_packages);
	
	echo "<tr bgcolor='black' style='color:white'>";
	echo "<td align='center' width='300'>";
	echo "Nom de l'application";
	echo "</td>";
	echo "<td align='center' width='120'>";
	echo "Version";
	echo "</td>";
	echo "<td align='center' width='120'>";
	echo "Compatibilit&#233;";
	echo "</td>";
	echo "<td align='center' width='160'>";
	echo "Cat&#233;gorie";
	echo "</td>";
	echo "<td align='center' width='160'>";
	echo "Requis par";
	echo "</td>";
	echo "</tr>\n";
	foreach ($list_app as $lp)
	{
		$temp="";
		$temp2=0;
		$lnk=$regular_lnk;
		$bg="#FFFFFF";
		$txt="#000000";
		if (isset($list_app_parc[$get_parc][$lp["id"]]))
		{
			if ($list_app_parc[$get_parc][$lp["id"]]["parc"]==$get_parc)
			{
				$temp2=1;
			}
			if (isset($list_app_parc[$get_parc][$lp["id"]]["depend"]))
			{
				foreach ($list_app_parc[$get_parc][$lp["id"]]["depend"] as $lp_dep)
				{
					if ($temp!="")
						$temp.= ", ";
					$temp.= "<a href='app_parcs.php?Appli=".$lp_dep."' style='color:".$lnk."'>".$list_app[$lp_dep]["name"]."</a>";
				}
				$temp2=1;
			}
		}
		
		if ($temp2==1)
		{
			echo "<tr bgcolor='".$bg."' style='color:".$txt."'>";
			echo "<td align='center'>";
			echo "<a href='app_parcs.php?Appli=".$lp["id"]."' style='color:".$lnk."'>".$lp["name"]."</a>";
			echo "</td>";
			echo "<td align='center'>";
			echo $lp["revision"];
			echo "</td>";
			echo "<td align='center' bgcolor='".$wintype_txt."'>";
			switch ($lp["compatibilite"])
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
			echo "<td align='center'>";
			echo $lp["category"];
			echo "</td>";
			echo "<td align='center'>";
			echo $temp;
			echo "</td>";
			echo "</tr>\n";
		}
	}
	echo "</table>\n";
	echo "<br>\n";
	echo "</form>";
	
include ("pdp.inc.php");
?>