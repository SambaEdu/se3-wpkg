<?php
/**
 * Maintenance d'un parc
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
	if (isset($_POST["parc_cible"]))
		$post_parc_cible=$_POST["parc_cible"];
	else
		$post_parc_cible="";
	
	if (isset($_POST["action"]))
		$post_action=$purifier->purify($_POST["action"]);
	else
		$post_action="";
	
	$result_xml="";
	if ($post_action==	"Annuler le clonage")
	{
		header("Location: parc_maintenance.php?tri2=".$tri2."&parc=".$get_parc."&ok=".$get_ok."&warning=".$get_warning."&error=".$get_error);
		exit;
	}
	elseif ($post_action=="Valider le clonage")
	{
		if (in_array($post_parc_cible,get_list_wpkg_parcs($xml_profiles)))
		{
			include ("wpkg_lib_admin.php");
			$tmp_result_xml=clone_parc_apps($get_parc,$post_parc_cible,$url_profiles);
			$result_xml="<center>Modification effectu&#233;e. ".$tmp_result_xml["in"]." application";
			if ($tmp_result_xml["in"]>1)
				$result_xml.="s";
			$result_xml.=" d&#233;ploy&#233;";
			if ($tmp_result_xml["in"]>1)
				$result_xml.="s";
			$result_xml.=" sur le parc cible <b>".$post_parc_cible."</b>.<br>";
			$result_xml.="<a href='parc_maintenance.php?tri2=".$tri2."&parc=".$get_parc."&ok=".$get_ok."&warning=".$get_warning."&error=".$get_error."' style='color:".$regular_lnk."'>Retour</a>";
			$result_xml.="</center><br>";
			include("wpkg_lib_load_xml.php");
		}
	}	
	
	echo "<form method='get' action=''>\n";
	$page_id=3;
	include ("parc_top.php");
	echo "</form>\n";
	
	echo $result_xml;
	
	echo "<form method='post' action='?tri2=".$tri2."&parc=".$get_parc."&ok=".$get_ok."&warning=".$get_warning."&error=".$get_error."'>";
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='white'>";
		echo "<td align='justify' colspan='2'>";
		echo "<b><font color='#FF0000'>ATTENTION!</font></b> Toutes les applications du parc cible seront effac&#233;es. Les applications du parc <b>".$get_parc."</b> seront ensuite sélectionnées sur ce parc cible.<br>";
		echo "Choix du parc cible : <select name='parc_cible'>";
		foreach ($liste_parcs as $l_parc)
		{
			if ($l_parc<>$get_parc)
			{
				echo "<option value='".$l_parc."'";
				if ($l_parc==$post_parc_cible)
				{
					echo " selected";
				}
				echo ">".$l_parc."</option>";
			}
		}
		echo "</select>";
		echo "</td>";
	echo "</tr>";
	echo "<tr bgcolor='black'>";
		echo "<td align='center' width='400'>";
		echo "<input type='submit' name='action' value='Valider le clonage'>";
		echo "</td>";
		echo "<td align='center' width='400'>";
		echo "<input type='submit' name='action' value='Annuler le clonage'>";
		echo "</td>";
	echo "</tr>\n";
	
	
	
include ("pdp.inc.php");
?>