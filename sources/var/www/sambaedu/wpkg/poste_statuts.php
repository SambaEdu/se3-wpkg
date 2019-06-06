<?php
/**
 * Affichage de la liste des statuts des applications d'un poste
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
	if (isset($_GET['id_host']))
		$id_host=$purifier->purify($_GET['id_host']);
	else
		$id_host="";
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
	if (isset($_GET["tous"]))
		$get_tous=$purifier->purify($_GET["tous"])+0;
	else
		$get_tous=0;

	echo "<form method='get' action=''>\n";
	$page_id=1;
	include ("poste_top.php");
	echo "</form>\n";

	if (is_array(@$liste_poste_infos["app"]))
		$list_app=$liste_poste_infos["app"];
	else
		$list_app=array();

	$tri_appli=array();
	$tri_status=array();
	$tri_revision=array();
	$tri_category=array();

	foreach ($list_app as $key=>$row)
	{
		$tri_appli[]=strtolower($row["nom_app"]);
		$tri_status[]=$row["statut_poste_app"];
		$tri_revision[]=$row["revision_poste_app"];
		$tri_category[]=$row["categorie_app"];
	}

	if ($list_app)
	{
		switch ($tri2)
		{
			case 0:
			array_multisort($tri_appli, SORT_ASC, $list_app);
			break;
			case 1:
			array_multisort($tri_appli, SORT_DESC, $list_app);
			break;
			case 2:
			array_multisort($tri_revision, SORT_ASC, $tri_appli, SORT_ASC, $list_app);
			break;
			case 3:
			array_multisort($tri_revision, SORT_DESC, $tri_appli, SORT_ASC, $list_app);
			break;
			case 4:
			array_multisort($tri_category, SORT_ASC, $tri_appli, SORT_ASC, $list_app);
			break;
			case 5:
			array_multisort($tri_category, SORT_DESC, $tri_appli, SORT_ASC, $list_app);
			break;
			case 6:
			array_multisort($tri_status, SORT_DESC, $tri_appli, SORT_ASC, $list_app);
			break;
			case 7:
			array_multisort($tri_status, SORT_ASC, $tri_appli, SORT_ASC, $list_app);
			break;
			default:
			array_multisort($tri_appli, SORT_ASC, $list_app);
			break;
		}
	}

	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr style='color:white'>";
	echo "<th width='300'><a href='?id_host=".$id_host."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=";
	if ($tri2==0)
		echo "1";
	else
		echo "0";
	echo "' style='color:".$regular_lnk."'>Application</a></th>";
	echo "<th width='120'><a href='?id_host=".$id_host."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=";
	if ($tri2==2)
		echo "3";
	else
		echo "2";
	echo "' style='color:".$regular_lnk."'>Version</a></th>";
	echo "<th width='120'>Compatibilit&#233;</th>";
	echo "<th width='150'><a href='?id_host=".$id_host."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=";
	if ($tri2==4)
		echo "5";
	else
		echo "4";
	echo "' style='color:".$regular_lnk."'>Cat&#233;gorie</a></th>";
	echo "<th width='120'><a href='?id_host=".$id_host."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=";
	if ($tri2==6)
		echo "7";
	else
		echo "6";
	echo "' style='color:".$regular_lnk."'>Statut</a></th>";
	echo "<th width='300'>Demand&#233; par</th>";
	echo "</tr>\n";

	foreach ($list_app as $nom_poste=>$lp)
	{
		$affichage=0;
		switch ($lp["status_app"])
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
			case 4:
				$bg=$unknown_bg;
				$lnk=$unknown_lnk;
				$txt=$unknown_txt;
				if ($get_tous==1)
					$affichage=1;
				else
					$affichage=0;
				break;
		}
		if ($affichage==1)
		{
			echo "<tr bgcolor='".$bg."' style='color: ".$txt."'>";
			echo "<td align='center'><a href='app_parcs.php?Appli=".$lp["id_nom_app"]."' style='color: ".$lnk."'>".$lp["nom_app"]."</a></td>";
			echo "<td align='center'>".$lp["revision_poste_app"]."</td>";
			echo "<td align='center' bgcolor='".$wintype_txt."'>";
			switch ($lp["compatibilite_app"])
			{
				case 1:
				echo "<img src='images/winxp.png' witdh='20' height='20'>";
				break;
				case 2:
				echo "<img src='images/win7.png' witdh='20' height='20'>";
				break;
				case 3:
				echo "<img src='images/winxp.png' witdh='20' height='20'><img src='images/win7.png' witdh='20' height='20'>";
				break;
				case 4:
				echo "<img src='images/win10.png' witdh='20' height='20'>";
				break;
				case 5:
				echo "<img src='images/winxp.png' witdh='20' height='20'><img src='images/win10.png' witdh='20' height='20'>";
				break;
				case 6:
				echo "<img src='images/win7.png' witdh='20' height='20'><img src='images/win10.png' witdh='20' height='20'>";
				break;
				case 7:
				echo "<img src='images/winxp.png' witdh='20' height='20'><img src='images/win7.png' witdh='20' height='20'><img src='images/win10.png' witdh='20' height='20'>";
				break;
				case 0:
				echo "";
				break;
				default:
				echo "";
				break;
			}
			echo "</td>";
			echo "<td align='center'>".$lp["categorie_app"]."</td>";
			echo "<td align='center'>".$lp["statut_poste_app"]."</td>";
			echo "<td align='center'>";
			$i=0;
			if (is_array($lp["parc"]))
			{
				foreach (@$lp["parc"] as $parc_app)
				{
					if ($i<>0)
						echo ", ";
					echo "<a href='parc_statuts.php?parc=".$parc_app["nom_parc"]."' style='color: ".$lnk."'>".$parc_app["nom_parc"]."</a>";
					$i++;
				}
			}
			if (is_array($lp["depend"]))
			{
				foreach ($lp["depend"] as $depend_app)
				{
					if ($i<>0)
						echo ", ";
					echo "<a href='app_parcs.php?Appli=".$depend_app["id_nom_app"]."' style='color: ".$lnk."'>".$depend_app["nom_app"]."</a>";
					$i++;
				}
			}
			if (@$lp["poste"])
			{
				if ($i<>0)
					echo ", ";
				echo $lp["poste"];
				$i++;
			}
			echo "</td>";
			echo "</tr>\n";
		}
	}
	echo "</table>\n";

include ("pdp.inc.php");
?>