<?php
/**
 * Maintenance des applications d'un parc
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
	include("../sambaedu/includes/library/HTMLPurifier.auto.php");
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

	if (isset($_POST["action"]))
		$post_action=$purifier->purify($_POST["action"]);
	else
		$post_action="";
	
	$result_xml="";
	if ($post_action=="Annuler les modifications")
	{
		header("Location: parc_maintenance.php?tri2=".$tri2."&parc=".$get_parc."&ok=".$get_ok."&warning=".$get_warning."&error=".$get_error);
		exit;
	}
	elseif ($post_action=="Valider les modifications")
	{
		if (isset($_POST["appli"]))
			$post_appli=$_POST["appli"];
		else
			$post_appli=array();
		
		include ("wpkg_lib_admin.php");
		$tmp_result_xml=set_parc_apps($post_appli,$get_parc,$url_profiles);
		$result_xml="<center>Modification effectu&#233;e. ".$tmp_result_xml["in"]." application";
		if ($tmp_result_xml["in"]>1)
			$result_xml.="s";
		$result_xml.=" d&#233;ploy&#233;";
		if ($tmp_result_xml["in"]>1)
			$result_xml.="s";
		$result_xml.=" sur le parc.";
		$result_xml.=".</center><br>";
		include("wpkg_lib_load_xml.php");
	}
	
	echo "<script>\n";
	echo "function checkAll()\n";
	echo "{\n";
	echo "     var checkboxes = document.getElementsByTagName('input'), val = null; \n";   
	echo "     for (var i = 0; i < checkboxes.length; i++)\n";
	echo "     {\n";
 	echo "        if (checkboxes[i].type == 'checkbox')\n";
 	echo "        {\n";
 	echo "            if (val === null) val = checkboxes[i].checked;\n";
 	echo "            checkboxes[i].checked = val;\n";
 	echo "        }\n";
 	echo "    }\n";
	echo " }\n";
	echo "</script>\n";
	
	echo "<form method='get' action=''>\n";
	$page_id=3;
	include ("parc_top.php");
	echo "</form>\n";
	
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='white' align='justify'>\n";
		echo "<td bgcolor='".$dep_entite_bg."' style='color:".$dep_entite_txt."' width='250'>";
		echo "D&#233;ploiement demand&#233; pour cette application";
		echo "</td>\n";
		echo "<td bgcolor='".$dep_depend_bg."' style='color:".$dep_depend_txt."' width='250'>";
		echo "D&#233;ploiement demand&#233; par une d&#233;pendance";
		echo "</td>\n";
		echo "<td bgcolor='".$dep_no_bg."' style='color:".$dep_no_txt."' width='250'>";
		echo "D&#233;ploiement non demand&#233; pour cette application";
		echo "</td>\n";
	echo "</tr>\n";
	echo "<tr bgcolor='white'>\n";
		echo "<th colspan='3'>";
		echo "<a href='parc_maintenance.php?tri2=".$tri2."&parc=".$get_parc."&ok=".$get_ok."&warning=".$get_warning."&error=".$get_error."' style='color:".$regular_lnk."'>Retour</a>";
		echo "</th>\n";
	echo "</tr>\n";
	echo "</table><br>\n";
	
	echo $result_xml;
	
	echo "<form method='post' action='?tri2=".$tri2."&parc=".$get_parc."&ok=".$get_ok."&warning=".$get_warning."&error=".$get_error."'>";
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='black'>";
		echo "<td align='center' colspan='2' width='320'>";
		echo "<input type='submit' name='action' value='Valider les modifications'>";
		echo "</td>";
		echo "<th align='center' width='240' style='color:white' colspan='2'>";
		echo "<input type='checkbox' onchange='checkAll()' name='chk[]' /> Tous/Aucun";
		echo "</th>";
		echo "<td align='center' colspan='2' width='320'>";
		echo "<input type='submit' name='action' value='Annuler les modifications'>";
		echo "</td>";
	echo "</tr>\n";
	
	$list_app=get_list_wpkg_app($xml_packages, $xml_time);
	$list_app_parc=get_list_wpkg_app_parc($xml_profiles,$xml_packages);
	
	echo "<tr bgcolor='black' style='color:white'>";
	echo "<td align='center' width='20'>";
	echo "</td>";
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
		$lnk=$dep_no_lnk;
		$bg=$dep_no_bg;
		$txt=$dep_no_txt;
		if (isset($list_app_parc[$get_parc][$lp["id"]]))
		{
			if ($list_app_parc[$get_parc][$lp["id"]]["parc"]==$get_parc)
			{
				$lnk=$dep_entite_lnk;
				$bg=$dep_entite_bg;
				$txt=$dep_entite_txt;
				$temp2=1;
			}
			if (isset($list_app_parc[$get_parc][$lp["id"]]["depend"]))
			{
				if ($temp2==0)
				{
					$lnk=$dep_depend_lnk;
					$bg=$dep_depend_bg;
					$txt=$dep_depend_txt;
				}
				foreach ($list_app_parc[$get_parc][$lp["id"]]["depend"] as $lp_dep)
				{
					if ($temp!="")
						$temp.= ", ";
					$temp.= "<a href='app_parcs.php?Appli=".$lp_dep."' style='color:".$lnk."'>".$list_app[$lp_dep]["name"]."</a>";
				}
			}
		}
		
		
		echo "<tr bgcolor='".$bg."' style='color:".$txt."'>";
		echo "<td align='center'>";
		echo "<input type='checkbox' id='appli[]' name='appli[]' value='".$lp["id"]."'";
		if ($temp2==1)
			echo " checked";
		echo " />";
		echo "</td>";
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
	echo "</table>\n";
	echo "<br>\n";
	echo "</form>";
	
include ("pdp.inc.php");
?>