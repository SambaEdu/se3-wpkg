<?php
/**
 * Affichage de la liste des status des postes pour un parc
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
		$get_parc="";
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
		$get_ok=0;
	if (isset($_GET["tous"]))
		$get_tous=$purifier->purify($_GET["tous"])+0;
	else
		$get_tous=0;
	
	$liste_rapports_status_poste = get_list_wpkg_rapports_statut_poste_app($xml_rapports);
	$liste_postes_parc=get_list_wpkg_poste_parc($xml_profiles);
	$liste_parcs=array_keys($liste_postes_parc);
	asort($liste_parcs);
	
	if (!count($liste_postes_parc[$get_parc]))
	{
		$get_parc="_TousLesPostes";
	}
	
	echo "<form method='get' action=''>\n";
	$page_id=1;
	include ("parc_top.php");
	
	$list_poste=liste_poste_infos["postes"];
	$tri_poste=array();
	$tri_status=array();
	$tri_date=array();
	$tri_ip=array();
	$tri_mac=array();
	$tri_nb_app=array();
	
	foreach ($list_poste as $key=>$row)
	{
		$tri_poste[]=$key;
		$tri_status[]=$row["info"]["status"];
		$tri_date[]=$row["info"]["datetime"];
		$tri_ip[]=ip2long($row["info"]["ip"]);
		$tri_mac[]=$tri_mac=$row["info"]["mac"];
		$tri_nb_app[]=$row["info"]["nb_app"];
	}
	
	if ($list_poste)
	{
		switch ($tri2)
		{
			case 0:
			array_multisort($tri_poste, SORT_ASC, $list_poste);
			break;
			case 1:
			array_multisort($tri_poste, SORT_DESC, $list_poste);
			break;
			case 2:
			array_multisort($tri_status, SORT_ASC, $tri_poste, SORT_ASC, $list_poste);
			break;
			case 3:
			array_multisort($tri_status, SORT_DESC, $tri_poste, SORT_ASC, $list_poste);
			break;
			case 4:
			array_multisort($tri_nb_app, SORT_DESC, $tri_poste, SORT_ASC, $list_poste);
			break;
			case 5:
			array_multisort($tri_nb_app, SORT_ASC, $tri_poste, SORT_ASC, $list_poste);
			break;
			case 6:
			array_multisort($tri_date, SORT_DESC, $tri_poste, SORT_ASC, $list_poste);
			break;
			case 7:
			array_multisort($tri_date, SORT_ASC, $tri_poste, SORT_ASC, $list_poste);
			break;
			case 8:
			array_multisort($tri_ip, SORT_ASC, $list_poste);
			break;
			case 9:
			array_multisort($tri_ip, SORT_DESC, $list_poste);
			break;
			case 10:
			array_multisort($tri_mac, SORT_ASC, $list_poste);
			break;
			case 11:
			array_multisort($tri_mac, SORT_DESC, $list_poste);
			break;
			default:
			array_multisort($tri_poste, SORT_ASC, $list_poste);
			break;
		}
	}
	
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<th width='200'>Parc</th>";
	echo "<th width='200'>Nombre de postes</th>";
	echo "<th width='200'>Postes à jour</th>";
	echo "<th width='200'>Postes en erreur</th>";
	echo "<th width='200'>Postes pas à jour</th>";
	echo "</tr>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<td align='center'>";
		echo $get_parc."<br>";
		echo "<select name='parc'>";
		foreach ($liste_parcs as $l_parc)
		{
			echo "<option value='".$l_parc."'";
			if ($l_parc==$get_parc)
				echo " selected";
			echo ">".$l_parc."</option>";
		}
		echo "</select>";
	echo "</td>\n";
	echo "<td align='center'>";
		echo $parc_poste_status["Total"]."<br>";
		echo "<select name='tous'>";
		echo "<option value='1'";
		if ($get_tous==1)
			echo " selected";
		echo ">Afficher Tous</option>";
		echo "<option value='0'";
		if ($get_tous==0)
			echo " selected";
		echo ">Afficher Postes d&#233;ploy&#233;s</option>";
		echo "</select>";
	echo "</td>\n";
	echo "<td align='center' bgcolor='".$ok_bg."' style='color:".$ok_txt."'>";
		echo $parc_poste_status["Ok"]."<br>";
		echo "<select name='ok'>";
		echo "<option value='1'";
		if ($get_ok==1)
			echo " selected";
		echo ">Afficher</option>";
		echo "<option value='0'";
		if ($get_ok==0)
			echo " selected";
		echo ">Masquer</option>";
		echo "</select>";
	echo "</td>\n";
	echo "<td align='center' bgcolor='".$warning_bg."' style='color:".$warning_txt."'>";
		echo $parc_poste_status["NotOk"]."<br>";
		echo "<select name='warning'>";
		echo "<option value='1'";
		if ($get_warning==1)
			echo " selected";
		echo ">Afficher</option>";
		echo "<option value='0'";
		if ($get_warning==0)
			echo " selected";
		echo ">Masquer</option>";
		echo "</select>";
	echo "</td>\n";
	echo "<td align='center' bgcolor='".$error_bg."' style='color:".$error_txt."'>";
		echo $parc_poste_status["MaJ"]."<br>";
		echo "<select name='error'>";
		echo "<option value='1'";
		if ($get_error==1)
			echo " selected";
		echo ">Afficher</option>";
		echo "<option value='0'";
		if ($get_error==0)
			echo " selected";
		echo ">Masquer</option>";
		echo "</select>";
	echo "</td>\n";
	echo "</tr>\n";
	echo "</table>\n";
	echo "<br>\n";
	echo "</form>\n";
	
	
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr style='color:white'>";
	echo "<th width='120'><a href='?parc=".$get_parc."&Appli=".$get_Appli."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&tri2=";
	if ($tri2==0)
		echo "1";
	else
		echo "0";
	echo "' style='color:".$regular_lnk."'>Nom du poste</a></th>";
	echo "<th width='50'>OS</th>";
	echo "<th width='120'><a href='?parc=".$get_parc."&Appli=".$get_Appli."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&tri2=";
	if ($tri2==2)
		echo "3";
	else
		echo "2";
	echo "' style='color:".$regular_lnk."'>Statut</a></th>";
	echo "<th width='120'><a href='?parc=".$get_parc."&Appli=".$get_Appli."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&tri2=";
	if ($tri2==4)
		echo "5";
	else
		echo "4";
	echo "' style='color:".$regular_lnk."'>Version</a></th>";
	echo "<th width='200'><a href='?parc=".$get_parc."&Appli=".$get_Appli."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&tri2=";
	if ($tri2==6)
		echo "7";
	else
		echo "6";
	echo "' style='color:".$regular_lnk."'>Date du dernier rapport</a></th>";
	echo "<th width='120'><a href='?parc=".$get_parc."&Appli=".$get_Appli."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&tri2=";
	if ($tri2==8)
		echo "9";
	else
		echo "8";
	echo "' style='color:".$regular_lnk."'>Adresse ip</a></th>";
	echo "<th width='160'><a href='?parc=".$get_parc."&Appli=".$get_Appli."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&tri2=";
	if ($tri2==10)
		echo "11";
	else
		echo "10";
	echo "' style='color:".$regular_lnk."'>Adresse mac</a></th>";
	echo "</tr>\n";
	
	foreach ($list_poste as $lp)
	{
		if ($lp["wpkg"]==1)
		{
			echo "<tr bgcolor='".$lp["bg"]."' style='color: ".$lp["txt"]."'>";
			echo "<td align='center'><a href='poste_info.php' style='color: ".$lp["lnk"]."'>".$lp["poste"]."</a></td>";
			echo "<td align='center' bgcolor='".$wintype_txt."'>";
			echo '<img src="../elements/images/'.$lp["typewin"].'" width="20" height="20">';
			echo "</td>";
			echo "<td align='center'>".$lp["status"]."</td>";
			echo "<td align='center'>".$lp["revision"]."</td>";
			echo "<td align='center'><a href='index.php?logfile=".$lp["logfile"]."' target='rapport_poste' style='color: ".$lp["lnk"]."'>".$lp["date"]." à ".$lp["time"]."</a></td>";
			echo "<td align='center'>".$lp["ip"]."</td>";
			echo "<td align='center'>".$lp["mac"]."</td>";
			echo "</tr>\n";
		}
	}
	echo "</table>\n";
	
include ("pdp.inc.php");
?>