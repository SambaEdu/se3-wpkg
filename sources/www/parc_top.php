<?php

	// recuperation des donnees
	$liste_hosts=get_list_wpkg_hosts($xml_hosts);
	asort($liste_hosts);
	$liste_parcs=array_keys($liste_postes_parc);
	asort($liste_parcs);
	if (!array_key_exists($get_parc,$liste_parcs))
		header("Location: parc_status.php");
	$liste_poste_infos=get_list_wpkg_postes_status($get_parc,$xml_packages,$xml_rapports,$xml_profiles);
	ksort($liste_poste_infos["postes"]);

	echo "<h1>Gestion des parcs</h1>\n";

	echo "<input type='hidden' name='tri2' value='".$tri2."'>";
	
// tableau 0
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	if ($page_id==1)
	{
		echo "<th width='220' bgcolor='black' style='color:white'>Etat de parcs</th>";
	}
	else
	{
		echo "<th width='220'><a href='parc_statuts.php?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&Appli=".$get_Appli."&tri2=".$tri2."' style='color:".$regular_lnk."'>Etat des parcs</a></th>";
	}
	if ($page_id==2)
	{
		echo "<th width='220' bgcolor='black' style='color:white'>Gestion</th>";
	}
	else
	{
		echo "<th width='220'><a href='parc_maintenance.php?parc=".$get_parc."&warning=".$get_warning."&error=".$get_error."&ok=".$get_ok."&tous=".$get_tous."&Appli=".$get_Appli."&tri2=".$tri2."' style='color:".$regular_lnk."'>Gestion</a></th>";
	}
	echo "</tr>\n";
	echo "<tr bgcolor='black' height='30' valing='center'>";
	echo "<th>";
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
	echo "<th><input type='submit' value='Valider' name='Valider'></th>";
	echo "</tr>\n";
	echo "</table>\n";
	echo "<br>\n";
	
	// tableau 1
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<th width='150'>Nombre de postes</th>";
	echo "<th width='150'>Postes &#224; jour</th>";
	echo "<th width='150'>Postes en erreur</th>";
	echo "<th width='150'>Postes pas &#224; jour</th>";
	echo "</tr>\n";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<td align='center'>".($liste_poste_infos["parc"]["nb_postes"]+0)."</td>";
	echo "<td align='center'";
	//if ($liste_poste_infos["parc"]["ok"]>0)
		echo " bgcolor='".$ok_bg."' style='color:".$ok_txt."'";
	echo ">".$liste_poste_infos["parc"]["ok"]."</td>";
	echo "<td align='center'";
	//if ($liste_poste_infos["parc"]["notok"]>0)
		echo " bgcolor='".$warning_bg."' style='color:".$warning_txt."'";
	echo ">".$liste_poste_infos["parc"]["notok"]."</td>";
	echo "<td align='center'";
	//if ($liste_poste_infos["parc"]["maj"]>0)
		echo " bgcolor='".$error_bg."' style='color:".$error_txt."'";
	echo ">".$liste_poste_infos["parc"]["maj"]."</td>";
	echo "</tr>\n";
	echo "</table>\n";
	echo "<br>\n";
?>