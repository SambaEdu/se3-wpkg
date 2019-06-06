<?php
/**
 * Affichage de la liste des statuts des postes pour un parc
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
	include "ihm.inc.php";
	include "wpkg_lib.php";
	include "wpkg_libsql.php";

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
	$page_id=1;
	include ("parc_top.php");
	echo "</form>\n";

	if (is_array(@$info_poste))
		$list_poste=$info_poste;
	else
		$list_poste=array();
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
		$tri_mac[]=$row["info"]["mac"];
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
	echo "<tr style='color:white'>";
	echo "<th width='120' rowspan='2'><a href='?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=";
	if ($tri2==0)
		echo "1";
	else
		echo "0";
	echo "' style='color:".$regular_lnk."'>Nom du poste</a></th>";
	echo "<th width='50' rowspan='2'>OS</th>";
	echo "<th width='120' rowspan='2'><a href='?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=";
	if ($tri2==2)
		echo "3";
	else
		echo "2";
	echo "' style='color:".$regular_lnk."'>Statut</a></th>";
	echo "<th width='180' colspan='3'>Applications</th>";
	echo "<th width='200' rowspan='2'><a href='?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=";
	if ($tri2==6)
		echo "7";
	else
		echo "6";
	echo "' style='color:".$regular_lnk."'>Date du dernier rapport</a></th>";
	echo "<th width='120' rowspan='2'><a href='?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=";
	if ($tri2==8)
		echo "9";
	else
		echo "8";
	echo "' style='color:".$regular_lnk."'>Adresse ip</a></th>";
	echo "<th width='160' rowspan='2'><a href='?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=";
	if ($tri2==10)
		echo "11";
	else
		echo "10";
	echo "' style='color:".$regular_lnk."'>Adresse mac</a></th>";
	echo "</tr>\n";

	echo "<tr style='color:white'>";
	echo "<th width='60'><a href='?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=";
	if ($tri2==4)
		echo "5";
	else
		echo "4";
	echo "' style='color:".$regular_lnk."'>Nombre</a></th>";
	echo "<th width='60'>Pas &#224; jour</th>";
	echo "<th width='60'>En erreur</th>";
	echo "</tr>\n";

	foreach ($list_poste as $nom_poste=>$lp)
	{
		$affichage=0;
		switch ($lp["info"]["status"])
		{
			case 0:
				$bg=$ok_bg;
				$lnk=$ok_lnk;
				$txt=$ok_txt;
				if ($get_ok==1)
					$affichage=1;
				else
					$affichage=0;
				break;
			case 1:
				$bg=$error_bg;
				$lnk=$error_lnk;
				$txt=$error_txt;
				if ($get_error==1)
					$affichage=1;
				else
					$affichage=0;
				break;
			case 2:
				$bg=$warning_bg;
				$lnk=$warning_lnk;
				$txt=$warning_txt;
				if ($get_warning==1)
					$affichage=1;
				else
					$affichage=0;
				break;
		}
		if ($affichage==1)
		{
			echo "<tr bgcolor='".$bg."' style='color: ".$txt."'>";
			echo "<td align='center'><a href='poste_statuts.php?id_host=".$nom_poste."' style='color: ".$lnk."'>".$nom_poste."</a></td>";
			echo "<td align='center' bgcolor='".$wintype_txt."'>";
			echo '<img src="images/';
			switch ($lp["info"]["typewin"])
			{
				case 'Windows XP':
					echo "winxp.png";
					break;
				case 'Windows 7':
					echo "win7.png";
					break;
				case 'Windows 10':
					echo "win10.png";
					break;
				default:
					echo "vide.png";
					break;
			}
			echo '" width="20" height="20">';
			echo "</td>";
			echo "<td align='center'>";
			switch ($lp["info"]["status"])
			{
				case 0:
					echo "A jour";
					break;
				case 1:
					echo "Pas &#224; jour";
					break;
				case 2:
					echo "En erreur";
					break;
			}
			echo "</td>";
			echo "<td align='center'>".$lp["info"]["nb_app"]."</td>";
			echo "<td align='center'>".$lp["status"]["MaJ"]."</td>";
			echo "<td align='center'>(-".$lp["status"]["Not_Ok-"]."/+".$lp["status"]["Not_Ok+"].")</td>";
			echo "<td align='center'><a href='log.php?logfile=".$lp["info"]["logfile"]."' target='rapport_poste' style='color: ".$lnk."'>".$lp["info"]["date"]." à ".$lp["info"]["time"]."</a></td>";
			echo "<td align='center'>".$lp["info"]["ip"]."</td>";
			echo "<td align='center'>".$lp["info"]["mac"]."</td>";
			echo "</tr>\n";
		}
	}
	echo "</table>\n";

include ("pdp.inc.php");
?>