<?php

	// recuperation des donnees
	$liste_appli=liste_applications(); // liste des applications
	$liste_appli_postes=info_application_postes($get_Appli); // liste des postes devant avoir l'application donnee
	$liste_appli_status=info_application_rapport($get_Appli); // liste des informations rapports pour une application donnee
	$liste_hosts=info_postes();

	ksort($liste_hosts);
	foreach ($liste_appli as $key => $row)
	{
		$name[$key] = strtolower($row['nom_app']);
	}
	array_multisort($name, SORT_ASC, $liste_appli);

	$svn_info=array(); //get_list_wpkg_svn_info($xml_forum);

	if ($page_id>0)
	{
		if (!array_key_exists(hash('md5',$get_Appli),$liste_appli))
			header("Location: app_liste.php");

		$statut=array("Not_Ok"=>0,"Ok"=>0,"MaJ"=>0,"Total"=>0,"Total2"=>0);
		foreach ($liste_hosts as $host1)
		{
			if (isset($liste_appli_postes[$host1["nom_poste"]])) // le poste necessite l'app
			{
				if (!isset($liste_appli_status[$host1["nom_poste"]]["statut_poste_app"])) // aucune info sur l'app
				{
					$statut["Not_Ok"]++;
					$liste_appli_status[$host1["nom_poste"]]["statut_wpkg"]="Not_Ok";
				}
				else if ($liste_appli_status[$host1["nom_poste"]]["statut_poste_app"]=="Not Installed") // l'app n'est pas installee
				{
					$statut["Not_Ok"]++;
					$liste_appli_status[$host1["nom_poste"]]["statut_wpkg"]="Not_Ok";
				}
				else if ($liste_appli_status[$host1["nom_poste"]]["revision_poste_app"]==$liste_appli[hash('md5',$get_Appli)]["version_app"]) // revision ok
				{
					$statut["Ok"]++;
					$liste_appli_status[$host1["nom_poste"]]["statut_wpkg"]="Ok";
				}
				else // revision not ok
				{
					$statut["MaJ"]++;
					$liste_appli_status[$host1["nom_poste"]]["statut_wpkg"]="MaJ";
				}
				$statut["Total2"]++;
			}
			else // le poste ne necessite pas l'app
			{
				if (@$liste_appli_status[$host1["nom_poste"]]["statut_poste_app"]=="Installed") // l'app est installee
				{
					$statut["Not_Ok"]++;
					$liste_appli_status[$host1["nom_poste"]]["statut_wpkg"]="Not_Ok";
				}
				else // l'app n'est pas installee
				{
					$statut["Ok"]++;
					$liste_appli_status[$host1["nom_poste"]]["statut_wpkg"]="Ok";
				}
			}
			$statut["Total"]++;
		}
		
		$application=$liste_appli[hash('md5',$get_Appli)];
		echo "<h1>Application : ".$application["nom_app"]."</h1>\n";

		echo "<input type='hidden' name='tri2' value='".$tri2."'>";

	// tableau 0
		echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
		echo "<tr bgcolor='white' height='30' valing='center'>";
		echo "<th width='220'><a href='app_liste.php?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&Appli=".$get_Appli."&tri2=".$tri2."' style='color:".$regular_lnk."'>Liste des Applications</a></th>";
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
			foreach ($liste_appli as $key=>$value)
			{
				echo "<option value='".$value["id_nom_app"]."'";
				if ($key==hash('md5',$get_Appli))
					echo " selected";
				echo ">".$value["nom_app"]."</option>";
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
		echo "<td align='center'><a href='app_extract.php?extractAppli=".$application["id_nom_app"]."' target='info' style='color: ".$regular_lnk."'>xml</a></td>";
		echo "<td align='center'>".$application["version_app"]."</td>";
		echo "<td align='center' bgcolor='".$wintype_txt."'>";

		switch ($application["compatibilite_app"])
		{
			case 1:
			echo "<img src='images\winxp.png' witdh='20' height='20'>";
			break;
			case 2:
			echo "<img src='images\win7.png' witdh='20' height='20'>";
			break;
			case 3:
			echo "<img src='images\winxp.png' witdh='20' height='20'><img src='images\win7.png' witdh='20' height='20'>";
			break;
			case 4:
			echo "<img src='images\win10.png' witdh='20' height='20'>";
			break;
			case 5:
			echo "<img src='images\winxp.png' witdh='20' height='20'><img src='images\win10.png' witdh='20' height='20'>";
			break;
			case 6:
			echo "<img src='images\win7.png' witdh='20' height='20'><img src='images\win10.png' witdh='20' height='20'>";
			break;
			case 7:
			echo "<img src='images\winxp.png' witdh='20' height='20'><img src='images\win7.png' witdh='20' height='20'><img src='images\win10.png' witdh='20' height='20'>";
			break;
			case 0:
			echo "";
			break;
			default:
			echo "";
			break;
		}
		echo "</td>";
		echo "<td align='center'>".$application["categorie_app"]."</td>";
		echo "<td align='center'>".$application["prorite_app"]."</td>";
		echo "<td align='center'>";
		if ($application["reboot_app"]=="false")
			echo "Non";
		else
			echo "Oui";
		echo "</td>";
		echo "<td align='center'>".date('d/m/Y à H:i:s',strtotime($application["date_modif_app"]))."</td>";
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
				echo "<a href='app_parcs.php?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&Appli=".$dependance["id_nom_app"]."&tri2=".$tri2."' style='color: ".$regular_lnk."'>";
				echo $dependance["nom_app"];
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
				echo "<a href='app_parcs.php?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&Appli=".$requis["id_nom_app"]."&tri2=".$tri2."' style='color: ".$regular_lnk."'>";
				echo $requis["nom_app"];
				echo "</a>";
				$i++;
			}
		}
		echo "</td>";
		echo "<td align='center'>".$statut["Total2"]."</td>";
		echo "<td align='center'";
		if ($statut["Not_Ok"]>0)
			echo " bgcolor='".$warning_bg."' style='color:".$warning_txt."'";
		echo ">".$statut["Not_Ok"]."</td>";
		echo "<td align='center'";
		if ($statut["MaJ"]>0)
			echo " bgcolor='".$error_bg."' style='color:".$error_txt."'";
		echo ">".$statut["MaJ"]."</td>";
		echo "</tr>\n";
		echo "</table>\n";
		echo "<br>\n";
	}
	else
	{
		echo "<h1>Liste des applications du serveur</h1>";
		if ($get_Appli=="")
			$get_Appli=key($liste_apps);

		echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
		echo "<tr bgcolor='white' height='30' valing='center'>";
		echo "<th width='220' bgcolor='black' style='color:white'>Liste des Applications</th>";
		echo "<th width='220'><a href='app_parcs.php?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&Appli=".$get_Appli."&tri2=".$tri2."' style='color:".$regular_lnk."'>Etat du déploiement</a></th>";
		echo "<th width='220'><a href='app_maintenance.php?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&Appli=".$get_Appli."&tri2=".$tri2."' style='color:".$regular_lnk."'>Gestion</a></th>";
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
	}
?>