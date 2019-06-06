<?php


/*
----------------------------------------------------------------------------------------------------

connexion_db_wpkg() : connexion sql
deconnexion_db_wpkg($link) : deconnexion sql
info_postes() : liste des postes
info_poste_parcs($nom_poste) : liste des parcs d'un poste
info_poste_applications($nom_poste) : liste des applications d'un poste
info_poste_rapport($nom_poste) : liste des informations issus des rapports d'un poste
info_poste_statut($id_poste, $list_app) : renvoi l'etat du poste avec les infos ok, not_ok+/-, maj...
info_parcs() : liste des parcs
info_parc_postes($nom_parc) : liste des postes d'un parc
info_parc_appli($nom_parc) : liste des appli d'un parc
info_sha_postes() : liste des rapports et leur hashage
liste_applications() : liste des applications
info_application_postes($id_appli) : liste des postes devant avoir l'application
info_application_rapport($id_nom_appli) : liste des informations issus des rapports d'une application

----------------------------------------------------------------------------------------------------

insert_poste_info_wpkg($info) : insere un poste
update_poste_info_wpkg($info) : mise a jour des informations d'un poste
insert_info_app_poste($id_poste,$id_app,$info) : insere les infos rapports pour un poste
delete_info_app_poste($id_poste) : supprime toutes les infos rapports pour un poste
insert_applications($list_appli) : ajoute une application
update_applications($id_app,$list_appli) : mise à jour d'une application
delete_dependances() : suppression de toutes les dependances
insert_dependance($id_appli,$id_required) : ajout d'une dependance d'application
insert_journal_app($id_appli,$info) : ajout des info sur la mise a jour d'une application
update_sha_xml_journal($url_xml_tmp) : mise a jour des hashage des applications inserees
truncate_table_profiles() : vidage des tables profile
insert_application_profile($type_entite,$id_entite,$id_appli) : ajout d'une application a d'un poste ou un parc
insert_parc_profile($id_poste,$id_parc) : ajout d'un poste a un parc
delete_parc_profile($id_poste,$id_parc) : suppression d'un parc d'un parc
insert_parc($nom_parc) : ajout d'un parc

----------------------------------------------------------------------------------------------------
*/

function connexion_db_wpkg($config)
{
	$link = mysqli_connect("locahost", "sambaedu", $config['sqlpasswd'], "sambaedu");
	mysqli_set_charset($link, "utf8");
	return $link;
}

function deconnexion_db_wpkg($link)
{
	mysqli_close($link);
}

function info_postes()
{
	$wpkg_link=connexion_db_wpkg();
	$query = mysqli_prepare($wpkg_link, "SELECT id_poste,nom_poste,OS_poste,date_rapport_poste,ip_poste,mac_address_poste,sha_rapport_poste,file_log_poste,file_rapport_poste,date_modification_poste FROM postes");
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_id_poste,$res_nom_poste,$res_OS_poste,$res_date_rapport_poste,$res_ip_poste,$res_mac_address_poste,$res_sha_rapport_poste,$res_file_log_poste,$res_file_rapport_poste,$res_date_modification_poste);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array();
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[$res_nom_poste] = array("id"=>$res_id_poste
										,"nom_poste"=>$res_nom_poste
										,"OS_poste"=>$res_OS_poste
										,"date_rapport_poste"=>$res_date_rapport_poste
										,"IP_poste"=>$res_ip_poste
										,"mac_address_poste"=>$res_mac_address_poste
										,"sha_rapport_poste"=>$res_sha_rapport_poste
										,"file_log_poste"=>$res_file_log_poste
										,"file_rapport_poste"=>$res_file_rapport_poste
										,"date_modification_poste"=>$res_date_modification_poste);
		}

	}
	mysqli_stmt_close($query);
	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

function info_poste_parcs($nom_poste)
{
	$wpkg_link=connexion_db_wpkg();
	$query = mysqli_prepare($wpkg_link, "SELECT pa.nom_parc, pa.nom_parc_wpkg, pa.id_parc, po.id_poste FROM (parc pa, postes po, parc_profile pp) WHERE po.nom_poste=? and pa.id_parc=pp.id_parc and pp.id_poste=po.id_poste ORDER BY pa.nom_parc ASC");
	mysqli_stmt_bind_param($query,"s", $nom_poste);
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_nom_parc,$res_nom_parc_wpkg,$res_id_parc,$res_id_poste);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array();
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[$res_nom_parc] = array("id_parc"=>$res_id_parc
										,"id_poste"=>$res_id_poste
										,"nom_parc"=>$res_nom_parc
										,"nom_parc_wpkg"=>$res_nom_parc_wpkg);
		}

	}
	mysqli_stmt_close($query);
	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

function info_poste_applications($nom_poste)
{
	$wpkg_link=connexion_db_wpkg();

	$query = mysqli_prepare($wpkg_link,"SELECT ap.type_entite, a.id_app, a.id_nom_app, a.nom_app, a.version_app, a.compatibilite_app, a.categorie_app, a.prorite_app, a.reboot_app, a.sha_app, p.id_parc, p.nom_parc, p.nom_parc_wpkg, count(distinct d.id_app_requise) as NB_DEP
										FROM (`postes` po, `parc` p, `parc_profile` pp)
										LEFT JOIN (`applications_profile` ap, `applications` a) ON a.id_app=ap.id_appli AND a.active_app=1 AND ((po.id_poste=ap.id_entite AND ap.type_entite='poste') OR (pp.id_parc=ap.id_entite AND ap.type_entite='parc'))
										LEFT JOIN (`dependance` d) ON d.id_app=a.id_app
										WHERE po.nom_poste=? AND po.id_poste=pp.id_poste AND p.id_parc=pp.id_parc AND a.id_app is not NULL
										GROUP BY ap.type_entite, a.id_app, ap.id_entite");
	mysqli_stmt_bind_param($query,"s", $nom_poste);
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_type_entite, $res_id_app, $res_id_nom_app, $res_nom_app, $res_version_app, $res_compatibilite_app, $res_categorie_app, $res_prorite_app, $res_reboot_app, $res_sha_app, $res_id_parc, $res_nom_parc, $res_nom_parc_wpkg, $res_nb_dep);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array();
	$list_app_dep=array();
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[$res_id_app]["info_app"] =array("id_app"=>$res_id_app
												,"id_nom_app"=>$res_id_nom_app
												,"nom_app"=>$res_nom_app
												,"version_app"=>$res_version_app
												,"compatibilite_app"=>$res_compatibilite_app
												,"categorie_app"=>$res_categorie_app
												,"prorite_app"=>$res_prorite_app
												,"reboot_app"=>$res_reboot_app
												,"sha_app"=>$res_sha_app);
			if ($res_type_entite=="poste")
				$tab[$res_id_app]["poste"]=$nom_poste;
			elseif ($res_type_entite=="parc")
				$tab[$res_id_app]["parc"][$res_nom_parc] = array("id_parc"=>$res_id_parc
																,"nom_parc"=>$res_nom_parc
																,"nom_parc_wpkg"=>$res_nom_parc_wpkg);
			if ($res_nb_dep>0)
				$list_app_dep[$res_id_app]=$res_id_app;
		}
	}
	mysqli_stmt_close($query);

	if ($list_app_dep)
	{
		foreach ($list_app_dep as $id_app=>$tmp)
		{
			$query3 = mysqli_prepare($wpkg_link, "SELECT a.id_app, a.id_nom_app, a.nom_app, a.version_app, a.compatibilite_app, a.categorie_app, a.prorite_app, a.reboot_app, a.sha_app FROM (applications a, dependance d)
			WHERE d.id_app=? AND d.id_app_requise=a.id_app");
			mysqli_stmt_bind_param($query3,"i", $id_app);
			mysqli_stmt_execute($query3);
			mysqli_stmt_bind_result($query3,$res_id_app3, $res_id_nom_app3, $res_nom_app3, $res_version_app3, $res_compatibilite_app3, $res_categorie_app3, $res_prorite_app3, $res_reboot_app3, $res_sha_app3);
			mysqli_stmt_store_result($query3);
			$num_rows3=mysqli_stmt_num_rows($query3);
			if ($num_rows3!=0)
			{
				while (mysqli_stmt_fetch($query3))
				{
					$tab[$res_id_app3]["info_app"]=array("id_app"=>$res_id_app3
														,"id_nom_app"=>$res_id_nom_app3
														,"nom_app"=>$res_nom_app3
														,"version_app"=>$res_version_app3
														,"compatibilite_app"=>$res_compatibilite_app3
														,"categorie_app"=>$res_categorie_app3
														,"prorite_app"=>$res_prorite_app3
														,"reboot_app"=>$res_reboot_app3
														,"sha_app"=>$res_sha_app3);
					$tab[$res_id_app3]["required_by"][$id_app]=$tab[$id_app]["info_app"];
				}
			}
			mysqli_stmt_close($query3);
		}
	}
	ksort($tab);

	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

function info_poste_rapport($nom_poste)
{
	$wpkg_link=connexion_db_wpkg();
	$query = mysqli_prepare($wpkg_link, "SELECT a.id_nom_app, a.nom_app, pa.revision_poste_app, pa.statut_poste_app, pa.reboot_poste_app FROM (`poste_app` pa, `applications` a, `postes` p)  WHERE p.nom_poste=? AND pa.id_app=a.id_app AND pa.id_poste=p.id_poste ORDER BY a.id_nom_app ASC");
	mysqli_stmt_bind_param($query,"s", $nom_poste);
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_id_nom_app, $res_nom_app, $res_revision_poste_app, $res_statut_poste_app, $res_reboot_poste_app);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array();
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[hash('md5',$res_id_nom_app)] =array("id_nom_app"=>$res_id_nom_app
													,"nom_app"=>$res_nom_app
													,"revision_poste_app"=>$res_revision_poste_app
													,"statut_poste_app"=>$res_statut_poste_app
													,"reboot_poste_app"=>$res_reboot_poste_app);
		}

	}
	mysqli_stmt_close($query);
	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

function info_poste_statut($id_poste, $list_app)
{
	$wpkg_link=connexion_db_wpkg();
	$app_ids="0";
	if ($list_app)
	{
		foreach ($list_app as $id)
		{
			$app_ids.=",".($id+0);
		}
	}
	$query = mysqli_prepare($wpkg_link, "SELECT IF(ISNULL(a2.id_app)=0,IF(ISNULL(pa.id_app)=1,2,IF(pa.statut_poste_app='Not installed',2,IF(a2.version_app=pa.revision_poste_app,0,1))),3) as statut, count(*) as NB FROM (applications a)
											LEFT JOIN (applications a2) ON a.id_app = a2.id_app and a2.id_app in (".$app_ids.")
											LEFT JOIN (poste_app pa) ON pa.id_app=a.id_app AND pa.id_poste=?
											WHERE (a2.id_app is not null OR pa.statut_poste_app='Installed') AND a.active_app=1
											GROUP BY statut ASC");
	mysqli_stmt_bind_param($query,"i", $id_poste);
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_statut, $res_nb);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array("MaJ"=>0,"Not_Ok-"=>0,"Ok"=>0,"Not_Ok+"=>0,"Status"=>0);
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			switch ($res_statut)
			{
				case 0:
					$tab["Ok"]=$res_nb; break;
				case 1:
					$tab["MaJ"]=$res_nb; $tab["status"]=max($tab["status"],1); break;
				case 2:
					$tab["Not_Ok-"]=$res_nb; $tab["status"]=2; break;
				case 3:
					$tab["Not_Ok+"]=$res_nb; $tab["status"]=2; break;
			}
		}
	}
	mysqli_stmt_close($query);
	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

function info_parcs()
{
    $wpkg_link=connexion_db_wpkg();
	$query = mysqli_prepare($wpkg_link, "SELECT id_parc,nom_parc,nom_parc_wpkg FROM parc");
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_id_parc,$res_nom_parc,$res_nom_parc_wpkg);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array();
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[$res_nom_parc]=array("id"=>$res_id_parc
									,"nom_parc"=>$res_nom_parc
									,"nom_parc_wpkg"=>$res_nom_parc_wpkg);
		}

	}
	mysqli_stmt_close($query);
	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

function info_parc_postes($nom_parc)
{
	$wpkg_link=connexion_db_wpkg();
	$query = mysqli_prepare($wpkg_link, "SELECT po.id_poste, po.nom_poste, po.OS_poste, po.date_rapport_poste, po.ip_poste, po.mac_address_poste, po.file_log_poste FROM (parc pa, postes po, parc_profile pp) WHERE pa.nom_parc=? and pa.id_parc=pp.id_parc and pp.id_poste=po.id_poste");
	mysqli_stmt_bind_param($query,"s", $nom_parc);
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_id_poste,$res_nom_poste,$res_OS_poste,$res_date_rapport_poste,$res_ip_poste,$res_mac_address_poste,$res_file_log_poste);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array();
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[$res_nom_poste] = array("nom_poste"=>$res_nom_poste
										,"id_poste"=>$res_id_poste
										,"OS_poste"=>$res_OS_poste
										,"date_rapport_poste"=>$res_date_rapport_poste
										,"ip_poste"=>$res_ip_poste
										,"mac_address_poste"=>$res_mac_address_poste
										,"file_log_poste"=>$res_file_log_poste);
		}
	}
	mysqli_stmt_close($query);
	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

function info_parc_appli($nom_parc)
{
	$wpkg_link=connexion_db_wpkg();
	$query = mysqli_prepare($wpkg_link, "SELECT a.id_app, a.id_nom_app, a.nom_app, a.version_app, a.compatibilite_app, a.prorite_app, a.reboot_app, a.sha_app, a.categorie_app
											FROM (`applications_profile` ap, `applications` a, `parc` p)
											WHERE p.id_parc=ap.id_entite AND type_entite='parc' AND ap.id_appli=a.id_app AND p.nom_parc=?
											ORDER BY nom_app ASC");
	mysqli_stmt_bind_param($query,"s", $nom_parc);
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_id_app,$res_id_nom_app,$res_nom_app,$res_version_app,$res_compatibilite_app,$res_prorite_app,$res_reboot_app, $res_sha_app, $res_categorie_app);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array();
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[$res_id_app] =array("id_app"=>$res_id_app
									,"id_nom_app"=>$res_id_nom_app
									,"nom_app"=>$res_nom_app
									,"version_app"=>$res_version_app
									,"compatibilite_app"=>$res_compatibilite_app
									,"categorie_app"=>$res_categorie_app
									,"prorite_app"=>$res_prorite_app
									,"reboot_app"=>$res_reboot_app
									,"sha_app"=>$res_sha_app);
		}
	}
	mysqli_stmt_close($query);
	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

function info_sha_postes()
{
    $wpkg_link=connexion_db_wpkg();
	$query = mysqli_prepare($wpkg_link, "SELECT sha_rapport_poste,file_rapport_poste FROM postes");
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_sha_rapport_poste,$res_file_rapport_poste);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array();
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[$res_file_rapport_poste] = $res_sha_rapport_poste;
		}

	}
	mysqli_stmt_close($query);
	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

function liste_applications()
{
	$wpkg_link=connexion_db_wpkg();
	$query = mysqli_prepare($wpkg_link, "SELECT id_app, id_nom_app, nom_app, version_app, compatibilite_app, categorie_app, prorite_app, reboot_app, sha_app, date_modif_app, user_modif_app, active_app FROM applications");
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_id_app, $res_id_nom_app, $res_nom_app, $res_version_app, $res_compatibilite_app, $res_categorie_app, $res_prorite_app, $res_reboot_app, $res_sha_app, $res_date_modif_app, $res_user_modif_app, $res_active_app);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array();
	$temp=array();
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[hash('md5',$res_id_nom_app)]= array("id_app"=>$res_id_app
													,"id_nom_app"=>$res_id_nom_app
													,"nom_app"=>$res_nom_app
													,"version_app"=>$res_version_app
													,"compatibilite_app"=>$res_compatibilite_app
													,"categorie_app"=>$res_categorie_app
													,"prorite_app"=>$res_prorite_app
													,"reboot_app"=>$res_reboot_app
													,"sha_app"=>$res_sha_app
													,"date_modif_app"=>$res_date_modif_app
													,"user_modif_app"=>$res_user_modif_app
													,"active_app"=>$res_active_app);
			$temp[$res_id_app]=array("id_nom_app"=>$res_id_nom_app,"nom_app"=>$res_nom_app);
		}

	}
	mysqli_stmt_close($query);

	$query = mysqli_prepare($wpkg_link, "SELECT d.id_app, d.id_app_requise FROM dependance d");
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_id_app2, $id_app_requise2);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[hash('md5',$temp[$id_app_requise2]["id_nom_app"])]["required_by"][$res_id_app2]=$temp[$res_id_app2];
			$tab[hash('md5',$temp[$res_id_app2]["id_nom_app"])]["depends"][$id_app_requise2]=$temp[$id_app_requise2];
		}

	}
	mysqli_stmt_close($query);

	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

function info_application_postes($id_nom_appli)
{
	$wpkg_link=connexion_db_wpkg();

	$depend=array();
	$tab=array();
	$md5=hash('md5',$id_nom_appli);
	$query3 = mysqli_prepare($wpkg_link, "SELECT a.id_app, d.id_app as id_app_dependance FROM (applications a) LEFT JOIN (dependance d) ON d.id_app_requise=a.id_app WHERE MD5(a.id_nom_app)=?");
	mysqli_stmt_bind_param($query3,"s", $md5);
	mysqli_stmt_execute($query3);
	mysqli_stmt_bind_result($query3,$res_id_app,$res_id_app_dependance);
	mysqli_stmt_store_result($query3);
	$num_rows3=mysqli_stmt_num_rows($query3);
	if ($num_rows3!=0)
	{
		while (mysqli_stmt_fetch($query3))
		{
			if (!is_null($res_id_app_dependance))
			{
				$depend[]=$res_id_app_dependance;
			}
			$id_app=$res_id_app;
		}
	}
	else
		return $tab;
	mysqli_stmt_close($query3);

	$list_appli="(".$id_app;
	if ($depend)
	{
		foreach ($depend as $id_depend)
		{
			$list_appli.=",".$id_depend;
		}
	}
	$list_appli.=")";

	$query = mysqli_prepare($wpkg_link, "SELECT po.id_poste, po.nom_poste, po.OS_poste, po.date_rapport_poste, po.ip_poste, po.mac_address_poste, po.file_log_poste, a.id_app, a.id_nom_app, a.nom_app 
	FROM (`applications` a, `applications_profile` ap, `postes` po)
	WHERE a.id_app in ".$list_appli." AND a.id_app=ap.id_appli AND ap.type_entite='poste' AND po.id_poste=ap.id_entite AND a.active_app=1");
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_id_poste, $res_nom_poste, $res_OS_poste, $res_date_rapport_poste, $res_ip_poste, $res_mac_address_poste, $res_file_log_poste, $res_id_app, $res_id_nom_app, $res_nom_app);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);

	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[$res_nom_poste]["info_poste"]=array("id_poste"=>$res_id_poste
													,"nom_poste"=>$res_nom_poste
													,"OS_poste"=>$res_OS_poste
													,"date_rapport_poste"=>$res_date_rapport_poste
													,"ip_poste"=>$res_ip_poste
													,"mac_address_poste"=>$res_mac_address_poste
													,"file_log_poste"=>$res_file_log_poste);
			if ($res_id_app==$id_app)
			{
				$tab[$res_nom_poste]["poste"]=$nom_poste;
			}
			else
			{
				$tab[$res_nom_poste]["required_by"][$res_id_nom_app] = array("id_app"=>$res_id_app
																			,"id_nom_app"=>$res_id_nom_app
																			,"nom_app"=>$res_nom_app);
			}
		}

	}
	mysqli_stmt_close($query);

	$query2 = mysqli_prepare($wpkg_link, "SELECT po.id_poste, po.nom_poste, po.OS_poste, po.date_rapport_poste, po.ip_poste, po.mac_address_poste, po.file_log_poste, p.id_parc, p.nom_parc, p.nom_parc_wpkg, a.id_app, a.id_nom_app, a.nom_app
	FROM (`applications` a, `applications_profile` ap, `postes` po, `parc_profile` pp, `parc` p)
	WHERE a.id_app in ".$list_appli." AND a.id_app=ap.id_appli AND ap.type_entite='parc' AND pp.id_parc=ap.id_entite AND p.id_parc=pp.id_parc AND po.id_poste=pp.id_poste AND a.active_app=1
	ORDER BY p.nom_parc ASC");
	mysqli_stmt_execute($query2);
	mysqli_stmt_bind_result($query2,$res_id_poste2, $res_nom_poste2, $res_OS_poste2, $res_date_rapport_poste2, $res_ip_poste2, $res_mac_address_poste2, $res_file_log_poste2, $res_id_parc2, $res_nom_parc2, $res_nom_parc_wpkg2, $res_id_app2, $res_id_nom_app2, $res_nom_app2);
	mysqli_stmt_store_result($query2);
	$num_rows2=mysqli_stmt_num_rows($query2);
	if ($num_rows2!=0)
	{
		while (mysqli_stmt_fetch($query2))
		{
			$tab[$res_nom_poste2]["info_poste"] = array("id_poste"=>$res_id_poste2
														,"nom_poste"=>$res_nom_poste2
														,"OS_poste"=>$res_OS_poste2
														,"date_rapport_poste"=>$res_date_rapport_poste2
														,"ip_poste"=>$res_ip_poste2
														,"mac_address_poste"=>$res_mac_address_poste2
														,"file_log_poste"=>$res_file_log_poste2);
			if ($res_id_app2==$id_app)
			{
				$tab[$res_nom_poste2]["parc"][$res_nom_parc2]= array("id_parc"=>$res_id_parc2
																	,"nom_parc"=>$res_nom_parc2
																	,"nom_parc_wpkg"=>$res_nom_parc_wpkg2);
			}
			else
			{
				$tab[$res_nom_poste2]["required_by"][$res_id_nom_app2]=array("id_app"=>$res_id_app2
																			,"id_nom_app"=>$res_id_nom_app2
																			,"nom_app"=>$res_nom_app2);
			}
		}

	}
	mysqli_stmt_close($query2);
	ksort($tab);

	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

function info_application_rapport($id_nom_appli)
{
	$wpkg_link=connexion_db_wpkg();
	$md5=hash('md5',$id_nom_appli);
	$query = mysqli_prepare($wpkg_link, "SELECT p.id_poste, p.nom_poste, pa.revision_poste_app, pa.statut_poste_app, pa.reboot_poste_app FROM (`poste_app` pa, `applications` a, `postes` p)  WHERE MD5(a.id_nom_app)=? AND pa.id_app=a.id_app AND pa.id_poste=p.id_poste ORDER BY p.nom_poste ASC");
	mysqli_stmt_bind_param($query,"s", $md5);
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_id_poste, $res_nom_poste, $res_revision_poste_app, $res_statut_poste_app, $res_reboot_poste_app);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array();
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$tab[$res_nom_poste] = array("nom_poste"=>$res_nom_poste
										,"id_poste"=>$res_id_poste
										,"revision_poste_app"=>$res_revision_poste_app
										,"statut_poste_app"=>$res_statut_poste_app
										,"reboot_poste_app"=>$res_reboot_poste_app);
		}

	}
	mysqli_stmt_close($query);
	deconnexion_db_wpkg($wpkg_link);
	return $tab;
}

///////////////////////////////////

function insert_poste_info_wpkg($info)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "INSERT INTO `postes` (`nom_poste`, `OS_poste`, `date_rapport_poste`, `ip_poste`, `mac_address_poste`, `sha_rapport_poste`, `file_log_poste`, `file_rapport_poste`, `date_modification_poste`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())");
	mysqli_stmt_bind_param($update_query,"ssssssss", $info["nom_poste"], $info["typewin"], $info["datetime"], $info["ip"], $info["mac_address"], $info["sha256"], $info["logfile"], $info["rapportfile"]);
	mysqli_stmt_execute($update_query);
	$id=mysqli_insert_id($wpkg_link);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
	return $id;
}


function update_poste_info_wpkg($info)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "UPDATE `postes` SET `OS_poste`=?, `date_rapport_poste`=?, `ip_poste`=?, `mac_address_poste`=?, `sha_rapport_poste`=?, `file_log_poste`=?, `file_rapport_poste`=?, `date_modification_poste`=NOW() WHERE `nom_poste`=?");
	mysqli_stmt_bind_param($update_query,"ssssssss", $info["typewin"], $info["datetime"], $info["ip"], $info["mac_address"], $info["sha256"], $info["logfile"], $info["rapportfile"], $info["nom_poste"]);
	mysqli_stmt_execute($update_query);
	mysqli_stmt_close($update_query);
	$query = mysqli_prepare($wpkg_link, "SELECT id_poste FROM `postes` WHERE nom_poste=?");
	mysqli_stmt_bind_param($query,"s", $info["nom_poste"]);
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_id_poste);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$id=0;
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			$id=$res_id_poste;
		}
	}
	mysqli_stmt_close($query);
	deconnexion_db_wpkg($wpkg_link);
	return $id;
}

function insert_info_app_poste($id_poste,$id_app,$info)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "INSERT INTO `poste_app` (`id_poste`, `id_app`, `id_nom_app`, `revision_poste_app`, `statut_poste_app`, `reboot_poste_app`) VALUES (?, ?, ?, ?, ?, ?)");
	mysqli_stmt_bind_param($update_query,"iisssi", $id_poste, $id_app, $info["id_nom_app"], $info["Revision"], $info["Status"], $info["Reboot"]);
	mysqli_stmt_execute($update_query);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
}

function delete_info_app_poste($id_poste)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "DELETE FROM `poste_app` WHERE `id_poste`=?");
	mysqli_stmt_bind_param($update_query,"i", $id_poste);
	mysqli_stmt_execute($update_query);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
}

function insert_applications($list_appli)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "INSERT INTO `applications` (`id_nom_app`, `nom_app`, `version_app`, `compatibilite_app`, `categorie_app`, `prorite_app`, `reboot_app`, `active_app`, `date_modif_app`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())");
	mysqli_stmt_bind_param($update_query,"sssisiii", $list_appli["id_nom_app"], $list_appli["nom_app"], $list_appli["version_app"], $list_appli["compatibilite_app"], $list_appli["categorie_app"], $list_appli["prorite_app"], $list_appli["reboot_app"], $list_appli["active_app"]);
	mysqli_stmt_execute($update_query);
	mysqli_stmt_close($update_query);
	$id=mysqli_insert_id($wpkg_link);
	deconnexion_db_wpkg($wpkg_link);
	return $id;
}

function update_applications($id_app,$list_appli)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "UPDATE `applications` SET `id_nom_app`=?, `nom_app`=?, `version_app`=?, `compatibilite_app`=?, `categorie_app`=?, `prorite_app`=?, `reboot_app`=?, `active_app`=?, `date_modif_app`=NOW() WHERE id_app=?");
	mysqli_stmt_bind_param($update_query,"sssisiiii", $list_appli["id_nom_app"], $list_appli["nom_app"], $list_appli["version_app"], $list_appli["compatibilite_app"], $list_appli["categorie_app"], $list_appli["prorite_app"], $list_appli["reboot_app"], $list_appli["active_app"],$id_app);
	mysqli_stmt_execute($update_query);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
}

function delete_dependances()
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "DELETE FROM `dependance`");
	mysqli_stmt_execute($update_query);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
}

function insert_dependance($id_appli,$id_required)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "INSERT INTO `dependance` (`id_app`, `id_app_requise`) VALUES (?, ?)");
	mysqli_stmt_bind_param($update_query,"ii", $id_appli, $id_required);
	mysqli_stmt_execute($update_query);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
}

function insert_journal_app($id_appli,$info)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "INSERT INTO `journal_app` (`id_app`, `operation_journal_app`, `user_journal_app`, `date_journal_app`, `xml_journal_app`, `sha_journal_app`) VALUES (?, ?, ?, ?, ?, ?)");
	mysqli_stmt_bind_param($update_query,"isssss", $id_appli, $info["operation_journal_app"], $info["user_journal_app"], $info["date_journal_app"], $info["xml_journal_app"], $info["sha_journal_app"]);
	mysqli_stmt_execute($update_query);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
}

function update_sha_xml_journal($url_xml_tmp)
{
	$wpkg_link=connexion_db_wpkg();
	$query = mysqli_prepare($wpkg_link, "SELECT ja1.id_app, ja1.xml_journal_app, ja1.user_journal_app, ja1.id_journal_app FROM (journal_app ja1)
										LEFT JOIN (journal_app ja2)
										ON (ja1.id_app=ja2.id_app and ja1.id_journal_app<ja2.id_journal_app)
										where ja2.id_journal_app is NULL and ja1.id_app!=0 and ja1.operation_journal_app='add'
										ORDER BY ja1.`id_app` ASC");
	mysqli_stmt_execute($query);
	mysqli_stmt_bind_result($query,$res_id_app, $res_xml_journal_app, $res_user_journal_app, $res_id_journal_app);
	mysqli_stmt_store_result($query);
	$num_rows=mysqli_stmt_num_rows($query);
	$tab=array();
	if ($num_rows!=0)
	{
		while (mysqli_stmt_fetch($query))
		{
			if (file_exists($url_xml_tmp.$res_xml_journal_app))
			{
				$sha512_file=hash_file('sha512',$url_xml_tmp.$res_xml_journal_app);
				$update_query = mysqli_prepare($wpkg_link, "UPDATE `journal_app` SET `sha_journal_app`=? WHERE `id_journal_app`=?");
				mysqli_stmt_bind_param($update_query,"si", $sha512_file, $res_id_journal_app);
				mysqli_stmt_execute($update_query);
				mysqli_stmt_close($update_query);
				$update_query = mysqli_prepare($wpkg_link, "UPDATE `applications` SET `sha_app`=?, user_modif_app=? WHERE `id_app`=?");
				mysqli_stmt_bind_param($update_query,"ssi", $sha512_file, $res_user_journal_app, $res_id_app);
				mysqli_stmt_execute($update_query);
				mysqli_stmt_close($update_query);
			}
		}

	}
	mysqli_stmt_close($query);
	deconnexion_db_wpkg($wpkg_link);
}

function truncate_table_profiles()
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "TRUNCATE TABLE `applications_profile`");
	mysqli_stmt_execute($update_query);
	mysqli_stmt_close($update_query);
	$update_query = mysqli_prepare($wpkg_link, "TRUNCATE TABLE `parc_profile`");
	mysqli_stmt_execute($update_query);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
}

function insert_application_profile($type_entite,$id_entite,$id_appli)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "INSERT INTO `applications_profile` (`type_entite`, `id_entite`, `id_appli`) VALUES (?, ?, ?)");
	mysqli_stmt_bind_param($update_query,"sii", $type_entite, $id_entite, $id_appli);
	mysqli_stmt_execute($update_query);
	$id=mysqli_insert_id($wpkg_link);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
	return $id;
}

function insert_parc_profile($id_poste,$id_parc)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "INSERT INTO `parc_profile` (`id_poste`, `id_parc`) VALUES (?, ?)");
	mysqli_stmt_bind_param($update_query,"ii", $id_poste, $id_parc);
	mysqli_stmt_execute($update_query);
	$id=mysqli_insert_id($wpkg_link);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
	return $id;
}

function delete_parc_profile($id_poste,$id_parc)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "DELETE FROM `parc_profile` WHERE `id_poste`=? AND `id_parc`=?");
	mysqli_stmt_bind_param($update_query,"ii", $id_poste, $id_parc);
	mysqli_stmt_execute($update_query);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
}

function insert_parc($nom_parc)
{
	$wpkg_link=connexion_db_wpkg();
	$update_query = mysqli_prepare($wpkg_link, "INSERT INTO `parc` (`nom_parc`) VALUES (?)");
	mysqli_stmt_bind_param($update_query,"s", $nom_parc);
	mysqli_stmt_execute($update_query);
	$id=mysqli_insert_id($wpkg_link);
	mysqli_stmt_close($update_query);
	deconnexion_db_wpkg($wpkg_link);
	return $id;
}

?>