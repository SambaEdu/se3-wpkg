<?php

include("wpkg_libsql.php");

$rapport_repertoire="/var/se3/unattended/install/wpkg/rapports/";

$liste_rapport=array();
$iterator = new DirectoryIterator($rapport_repertoire);
foreach($iterator as $fichier)
{
	if(($fichier->getExtension())=="txt")
	{
		$liste_rapport[]=$fichier->getFilename();
	}
}

sort($liste_rapport);

$liste_postes=info_postes();
$liste_app=liste_applications();
$info_sha_postes=info_sha_postes();

//Gestion de tous les rapports
foreach ($liste_rapport as $rapport_fichier)
{
	// Gestion de chaque rapport
	$rapport_txt=@fopen($rapport_repertoire.$rapport_fichier, "r");
	$uptodate=0;
	$sha256_file=hash_file('sha256',$rapport_repertoire.$rapport_fichier);
	if ($rapport_txt)
	{
		if (!isset ($info_sha_postes[$rapport_fichier]))
		{
			$uptodate=-1;
		}
		else if ($info_sha_postes[$rapport_fichier]==$sha256_file)
		{
			$uptodate=1;
		}
		else
		{
			$uptodate=0;
		}

		if ($uptodate!=1)
		{
			$ligne=0;
			$id_app=0;
			$info=array();
			while (($rapport_ligne=fgets($rapport_txt)) !== false)
			{
				if ($ligne==0)
				{
					$rapport_ligne_data=explode(" ",$rapport_ligne);
					$info= array("nom_poste"=>$rapport_ligne_data[2]
								,"datetime"=>substr($rapport_ligne_data[0],6,4)."-".substr($rapport_ligne_data[0],3,2)."-".substr($rapport_ligne_data[0],0,2)." ".$rapport_ligne_data[1]
								,"mac_address"=>$rapport_ligne_data[3]
								,"ip"=>substr($rapport_ligne_data[4],1)
								,"logfile"=>$rapport_ligne_data[2].".log"
								,"rapportfile"=>$rapport_fichier
								,"sha256"=>$sha256_file);

					if (strpos($info["ip"],"/")!== false)
					{
						$info["ip"]=substr($info["ip"],0,strpos($info["ip"],"/")-strlen($info["ip"]));
					}
					if (substr_count(strtolower($rapport_ligne),"windows 7")>0)
						$info["typewin"]="Windows 7";
					elseif (substr_count(strtolower($rapport_ligne),"windows 10")>0)
						$info["typewin"]="Windows 10";
					elseif (substr_count(strtolower($rapport_ligne),"winxp")>0)
						$info["typewin"]="Windows XP";
					else
						$info["typewin"]="Autre";
					if ($uptodate==-1)
					{
						$id_poste=insert_poste_info_wpkg($info);
					}
					else
					{
						$id_poste=update_poste_info_wpkg($info);
					}
					$info=array();
				}
				else
				{
					$rapport_ligne_data=explode(":",$rapport_ligne);
					switch(ltrim($rapport_ligne_data[0]))
					{
						case "ID":
							$id_app++;
							$info[$id_app]["id_nom_app"]=rtrim(ltrim($rapport_ligne_data[1]));
							break;
						case "Revision":
							$info[$id_app]["Revision"]=rtrim(ltrim($rapport_ligne_data[1]));
							break;
						case "Reboot":
							$info[$id_app]["Reboot"]=rtrim(ltrim($rapport_ligne_data[1]));
							if ($info[$id_app]["Reboot"]=="false")
								$info[$id_app]["Reboot"]=0;
							else
								$info[$id_app]["Reboot"]=1;
							break;
						case "Status":
							$info[$id_app]["Status"]=rtrim(ltrim($rapport_ligne_data[1]));
							break;
						default:
							break;
					}
				}
				$ligne++;
			}
			delete_info_app_poste($id_poste);
			if (count($info)>0)
			{
				foreach ($info as $tmp_info)
				{
					$md5=hash('md5',$tmp_info["id_nom_app"]);
					if (isset($liste_app[$md5]))
					{
						$id_app=$liste_app[$md5]["id_app"];
					}
					else
					{
						$id_app=0;
					}
					insert_info_app_poste($id_poste,$id_app,$tmp_info);
				}
			}
		}
		fclose($rapport_txt);
	}
}
?>