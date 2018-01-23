<?php

	// recuperation des donnees
	$liste_appli=get_list_wpkg_app($xml_packages, $xml_time);
	$liste_appli_postes=get_list_wpkg_poste_app_all($xml_profiles, $xml_packages);
	$liste_appli_status=get_list_wpkg_rapports_statut_app($xml_rapports);
	$liste_hosts=get_list_wpkg_hosts($xml_hosts);
	asort($liste_hosts);
	$svn_info=get_list_wpkg_svn_info($xml_forum);
	foreach (array_keys($liste_appli) as $l_ap)
	{
		$liste_apps[$l_ap]=$liste_appli[$l_ap]["name"];
	}
	asort($liste_apps);
	
	if (!array_key_exists($get_Appli,$liste_appli))
		header("Location: app_liste.php");
	
	if (is_array($liste_appli_postes[$get_Appli]))
			$tmp_liste_appli_poste=array_keys($liste_appli_postes[$get_Appli]);
		else
			$tmp_liste_appli_poste=array();
	$liste_status_tmp=get_list_wpkg_app_status($liste_hosts,$tmp_liste_appli_poste,$liste_appli_status[$get_Appli],$liste_appli[$get_Appli]['revision']);
	$liste_appli[$get_Appli]["NotOk"]=count($liste_status_tmp["NotOk"]);
	$liste_appli[$get_Appli]["Ok"]=count($liste_status_tmp["Ok"]);
	$liste_appli[$get_Appli]["MaJ"]=count($liste_status_tmp["MaJ"]);
	
	foreach ($liste_appli_postes as $key=>$value)
	{
		$liste_appli[$key]["nb_postes"]=count($value)+0;
	}
	
	$application=$liste_appli[$get_Appli];
	echo "<h1>Application : ".$application["name"]."</h1>\n";

	echo "<input type='hidden' name='tri2' value='".$tri2."'>";
	
// tableau 0
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<th width='220'><a href='app_liste.php' style='color:".$regular_lnk."'>Liste des Applications</a></th>";
	if ($page_id==1)
	{
		echo "<th width='220' bgcolor='black' style='color:white'>Etat du déploiement</th>";
	}
	else
	{
		echo "<th width='220'><a href='app_parcs.php?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&Appli=".$get_Appli."&tri2=".$tri2."' style='color:".$regular_lnk."'>Etat du déploiement</a></th>";
	}
	if ($page_id==2)
	{
		echo "<th width='220' bgcolor='black' style='color:white'>Gestion</th>";
	}
	else
	{
		echo "<th width='220'><a href='app_maintenance.php?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&Appli=".$get_Appli."&tri2=".$tri2."' style='color:".$regular_lnk."'>Gestion</a></th>";
	}
	echo "</tr>\n";
	echo "<tr bgcolor='black' height='30' valing='center'>";
	echo "<th colspan='2'>";
		echo "<select name='Appli'>";
		foreach ($liste_apps as $key=>$value)
		{
			echo "<option value='".$key."'";
			if ($key==$get_Appli)
				echo " selected";
			echo ">".$value."</option>";
		}
		echo "</select>";
	echo "</th>";
	echo "<th><input type='submit' value='Valider' name='Valider'></th>";
	echo "</tr>\n";
	echo "</table>\n";
	echo "<br>\n";


// tableau 1
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<th width='100'>Fichier xml</th>";
	echo "<th width='120'>Version</th>";
	echo "<th width='120'>Compatibilit&#233;</th>";
	echo "<th width='150'>Cat&#233;gorie</th>";
	echo "<th width='70'>Priorit&#233;</th>";
	echo "<th width='70'>Reboot</th>";
	echo "<th width='180'>Date d'ajout</th>";
	echo "<th width='120'>Version SVN</th>";
	echo "</tr>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<td align='center'><a href='index.php?extractAppli=".$application["id"]."' target='info' style='color: ".$regular_lnk."'>xml</a></td>";
	echo "<td align='center'>".$application["revision"]."</td>";
	echo "<td align='center' bgcolor='".$wintype_txt."'>";
	
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
	echo "<td align='center'>".$application["priority"]."</td>";
	echo "<td align='center'>";
	if ($application["reboot"]=="false")
		echo "Non";
	else
		echo "Oui";
	echo "</td>";
	echo "<td align='center'>".$application["date2"]."</td>";
	if (isset($svn_info[$application["id"]]))
	{
		$rev=array();
		if (isset ($svn_info[$application["id"]]["stable"]))
		{
			$rev["stable"]=$svn_info[$application["id"]]["stable"]["revision"];
		}
		if (isset ($svn_info[$application["id"]]["test"]))
		{
			$rev["test"]=$svn_info[$application["id"]]["test"]["revision"];
		}
		if (isset ($svn_info[$application["id"]]["XP"]) and get_wpkg_branche_XP()==1)
		{
			$rev["XP"]=$svn_info[$application["id"]]["XP"]["revision"];
		}
		if (in_array($application["revision"],$rev))
		{
			echo "<td align='center' bgcolor='".$ok_bg."' style='color:".$ok_txt."'>";
		}
		else
		{
			echo "<td align='center' bgcolor='".$warning_bg."' style='color:".$warning_txt."'>";
		}
		$i=0;
		foreach ($rev as $key=>$value)
		{
			if ($i>0)
				echo "<br>";
			echo $value." (".$key.")";
			$i++;
		}
		echo "</td>";
	}
	else
	{
		echo "<td align='center' bgcolor='".$error_bg."' style='color:".$error_txt."'>-</td>";
	}
	echo "</tr>\n";
	echo "</table>\n";
	echo "<br>\n";
	
	// tableau 2
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<th width='150'>D&#233;pend de</th>";
	echo "<th width='150'>Requis par</th>";
	echo "<th width='150'>Nombre de postes</th>";
	echo "<th width='150'>Postes en erreur</th>";
	echo "<th width='150'>Postes pas &#224; jour</th>";
	echo "</tr>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<td align='center'>";
	if (isset($application["depends"]))
	{
		$i=0;
		foreach ($application["depends"] as $dependance)
		{
			if ($i>0)
				echo "<br>";
			echo "<a href='app_parcs.php?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&Appli=".$dependance."&tri2=".$tri2."' style='color: ".$regular_lnk."'>";
			echo $liste_appli[$dependance]["name"];
			echo "</a>";
			$i++;
		}
	}
	echo "</td>";
	echo "<td align='center'>";
	if (isset($application["required_by"]))
	{
		$i=0;
		foreach ($application["required_by"] as $requis)
		{
			if ($i>0)
				echo "<br>";
			echo "<a href='app_parcs.php?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&Appli=".$requis."&tri2=".$tri2."' style='color: ".$regular_lnk."'>";
			echo $liste_appli[$requis]["name"];
			echo "</a>";
			$i++;
		}
	}
	echo "</td>";
	echo "<td align='center'>".($application["nb_postes"]+0)."</td>";
	echo "<td align='center'";
	if ($application["NotOk"]>0)
		echo " bgcolor='".$warning_bg."' style='color:".$warning_txt."'";
	echo ">".$application["NotOk"]."</td>";
	echo "<td align='center'";
	if ($application["MaJ"]>0)
		echo " bgcolor='".$error_bg."' style='color:".$error_txt."'";
	echo ">".$application["MaJ"]."</td>";
	echo "</tr>\n";
	echo "</table>\n";
	echo "<br>\n";
?>