<?php

	// recuperation des donnees
	$liste_hosts=info_postes();
	ksort($liste_hosts);
	if (!array_key_exists($id_host,$liste_hosts))
	{
		$id_host=key($liste_hosts);
	}
	$liste_poste_parc=info_poste_parcs($id_host);
	$liste_poste_rapport=info_poste_rapport($id_host);
	$liste_poste_app=info_poste_applications($id_host);
	$liste_appli=liste_applications();

	$liste_poste_infos["info"]=array("typewin"=>$liste_hosts[$id_host]["OS_poste"],"status"=>0,"logfile"=>$liste_hosts[$id_host]["file_log_poste"],"ip"=>$liste_hosts[$id_host]["IP_poste"],"mac"=>$liste_hosts[$id_host]["mac_address_poste"],"datetime"=>$liste_hosts[$id_host]["date_rapport_poste"]);
	$liste_poste_infos["status"]=array("Ok"=>0,"Not_Ok+"=>0,"Not_Ok-"=>0,"MaJ"=>0,"Nb_App"=>count($liste_poste_app));
	$liste_poste_infos["info"]["date"]=date('d/m/Y',strtotime($liste_poste_infos["info"]["datetime"]));
	$liste_poste_infos["info"]["time"]=date('H:i:s',strtotime($liste_poste_infos["info"]["datetime"]));
	foreach ($liste_appli as $key_md5=>$appli)
	{
		$liste_poste_infos["app"][$appli["id_app"]] = array("id_nom_app"=>$appli["id_nom_app"]
															,"nom_app"=>$appli["nom_app"]
															,"version_app"=>$appli["version_app"]
															,"compatibilite_app"=>$appli["compatibilite_app"]
															,"categorie_app"=>$appli["categorie_app"]
															,"depend"=>@$liste_poste_app[$appli["id_app"]]["required_by"]
															,"parc"=>@$liste_poste_app[$appli["id_app"]]["parc"]
															,"poste"=>@$liste_poste_app[$appli["id_app"]]["poste"]
															,"status_app"=>0);
		if (isset($liste_poste_rapport[$key_md5]["revision_poste_app"]))
		{
			$liste_poste_infos["app"][$appli["id_app"]]["revision_poste_app"]=$liste_poste_rapport[$key_md5]["revision_poste_app"];
		}
		else
		{
			$liste_poste_infos["app"][$appli["id_app"]]["revision_poste_app"]="-";
		}
		if (isset($liste_poste_rapport[$key_md5]["statut_poste_app"]))
		{
			switch ($liste_poste_rapport[$key_md5]["statut_poste_app"])
			{
				case "Installed":
					$liste_poste_infos["app"][$appli["id_app"]]["statut_poste_app"]="Install&#233;"; break;
				case "Not Installed":
					$liste_poste_infos["app"][$appli["id_app"]]["statut_poste_app"]="Non Install&#233;"; break;
				default:
					$liste_poste_infos["app"][$appli["id_app"]]["statut_poste_app"]="Inconnu"; break;
			}
		}
		else
		{
			$liste_poste_infos["app"][$appli["id_app"]]["statut_poste_app"]="Inconnu";
		}
		if (array_key_exists($appli["id_app"],$liste_poste_app))
		{
			if (!isset($liste_poste_rapport[$key_md5]["statut_poste_app"]))
			{
				$liste_poste_infos["app"][$appli["id_app"]]["status_app"]=2;
				$liste_poste_infos["status"]["Not_Ok-"]++;
				$liste_poste_infos["info"]["status"]=max($liste_poste_infos["info"]["status"],2);
			}
			elseif ($liste_poste_rapport[$key_md5]["statut_poste_app"]=="Not Installed")
			{
				$liste_poste_infos["app"][$appli["id_app"]]["status_app"]=2;
				$liste_poste_infos["status"]["Not_Ok-"]++;
				$liste_poste_infos["info"]["status"]=max($liste_poste_infos["info"]["status"],2);
			}
			elseif ($liste_poste_rapport[$key_md5]["revision_poste_app"]==$appli["version_app"])
			{
				$liste_poste_infos["app"][$appli["id_app"]]["status_app"]=0;
				$liste_poste_infos["status"]["Ok"]++;
			}
			else
			{
				$liste_poste_infos["app"][$appli["id_app"]]["status_app"]=1;
				$liste_poste_infos["status"]["MaJ"]++;
				$liste_poste_infos["info"]["status"]=max($liste_poste_infos["info"]["status"],1);
			}
		}
		elseif (@$liste_poste_rapport[$key_md5]["statut_poste_app"]=="Installed")
		{
			$liste_poste_infos["app"][$appli["id_app"]]["status_app"]=2;
			$liste_poste_infos["status"]["Not_Ok+"]++;
			$liste_poste_infos["info"]["status"]=max($liste_poste_infos["info"]["status"],2);
		}
		else
		{
			$liste_poste_infos["app"][$appli["id_app"]]["status_app"]=4;
		}
	}

	echo "<h1>Gestion du poste : ".$id_host."</h1>\n";

	echo "<input type='hidden' name='tri2' value='".$tri2."'>";

// tableau 0
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	if ($page_id==1)
	{
		echo "<th width='220' bgcolor='black' style='color:white'>Etat du poste</th>";
	}
	else
	{
		echo "<th width='220'><a href='poste_statuts.php?id_host=".$id_host."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=".$tri2."' style='color:".$regular_lnk."'>Etat du poste</a></th>";
	}
	if ($page_id==2)
	{
		echo "<th width='220' bgcolor='black' style='color:white'>Gestion</th>";
	}
	else
	{
		echo "<th width='220'><a href='poste_maintenance.php?parc=".$id_host."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tri2=".$tri2."' style='color:".$regular_lnk."'>Gestion</a></th>";
	}
	echo "</tr>\n";
	echo "<tr bgcolor='black' height='30' valing='center'>";
	echo "<th>";
	echo "<select name='id_host'>";
	foreach ($liste_hosts as $l_host)
	{
		echo "<option value='".$l_host["nom_poste"]."'";
		if ($l_host["nom_poste"]==$id_host)
			echo " selected";
		echo ">".$l_host["nom_poste"]."</option>";
	}
	echo "</select>";
	echo "</td>\n";
	echo "<th><input type='submit' value='Valider' name='Valider'></th>";
	echo "</tr>\n";
	echo "</table>\n";
	echo "<br>\n";

	switch ($liste_poste_infos["info"]["status"])
	{
		case 0:
			$status_bg=$ok_bg;
			$status_lnk=$ok_lnk;
			$status_txt=$ok_txt;
			break;
		case 1:
			$status_bg=$error_bg;
			$status_lnk=$error_lnk;
			$status_txt=$error_txt;
			break;
		case 2:
			$status_bg=$warning_bg;
			$status_lnk=$warning_lnk;
			$status_txt=$warning_txt;
			break;
		default:
			$status_bg=$unknown_bg;
			$status_txt=$unknown_txt;
			$status_lnk=$unknown_lnk;
			break;
	}

	// tableau 1
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<th width='50'>OS</th>";
	echo "<th width='200'>Date du dernier rapport</th>";
	echo "<th width='120'>Adresse IP</th>";
	echo "<th width='160'>Adresse Mac</th>";
	echo "<th width='400'>Appartient aux parcs</th>";
	echo "</tr>";
	echo "<tr bgcolor='".$status_bg."' height='30' valing='center'>";
	echo "<td align='center' bgcolor='".$wintype_txt."'>";
	echo '<img src="images/';
	switch ($liste_poste_infos["info"]["typewin"])
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
	echo '" width="30" height="30">';
	echo "</td>";
	echo "<td align='center' style='color:".$status_txt."'><a href='log.php?logfile=".$liste_poste_infos["info"]["logfile"]."'  style='color: ".$status_lnk."' target='rapport'>".$liste_poste_infos["info"]["date"]." &#0224; ".$liste_poste_infos["info"]["time"]."</a></td>";
	echo "<td align='center' style='color:".$status_txt."'>".$liste_poste_infos["info"]["ip"]."</td>";
	echo "<td align='center' style='color:".$status_txt."'>".$liste_poste_infos["info"]["mac"]."</td>";
	echo "<td style='color:".$status_txt."'>";
	$i=0;
	foreach ($liste_poste_parc as $lpp)
	{
		if ($i<>0)
			echo ", ";
			echo "<a href='parc_statuts.php?parc=".$lpp["nom_parc"]."' style='color: ".$status_lnk."'>".$lpp["nom_parc"]."</a>";
			$i++;
	}
	echo "</td>";
	echo "</tr>\n";
	echo "</table>\n";
	echo "<br>\n";

	// tableau 2
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<th colspan='4'>Applications</th>";
	echo "</tr>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<th width='150'>Nombre</th>";
	echo "<th width='150'>A jour</th>";
	echo "<th width='150'>En erreur</th>";
	echo "<th width='150'>Pas &#224; jour</th>";
	echo "</tr>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<td align='center'>".$liste_poste_infos["status"]["Nb_App"]."<br>";
		echo "<select name='tous'>";
		echo "<option value='1'";
		if ($get_tous==1)
			echo " selected";
		echo ">Afficher toutes les applications</option>";
		echo "<option value='0'";
		if ($get_tous==0)
			echo " selected";
		echo ">Afficher les applications d&#233;ploy&#233;es</option>";
		echo "</select>";
	echo "</td>";
	echo "<td align='center'";
	echo " bgcolor='".$ok_bg."' style='color:".$ok_txt."'";
	echo ">".@$liste_poste_infos["status"]["Ok"]."<br>";
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
	echo "</td>";
	echo "<td align='center'";
	echo " bgcolor='".$warning_bg."' style='color:".$warning_txt."'";
	echo ">(-".@$liste_poste_infos["status"]["Not_Ok-"]."/+".@$liste_poste_infos["status"]["Not_Ok+"].")<br>";
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
	echo "</td>";
	echo "<td align='center'";
	echo " bgcolor='".$error_bg."' style='color:".$error_txt."'";
	echo ">".$liste_poste_infos["status"]["MaJ"]."<br>";
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
	echo "</td>";
	echo "</tr>\n";
	echo "</table>\n";
	echo "<br>\n";
?>