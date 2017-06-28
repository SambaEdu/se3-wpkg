<html>
<body>
<?php


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

foreach ($liste_rapport as $rapport_fichier)
{

$rapport_txt=@fopen($rapport_repertoire.$rapport_fichier, "r");


if ($rapport_txt)
{
	$ligne=0;
	$id_app=0;
	$info[$rapport_fichier]=array();
	while (($rapport_ligne=fgets($rapport_txt)) !== false)
	{
		if ($ligne==0)
		{
			$rapport_ligne_data=explode(" ",$rapport_ligne);
			$info[$rapport_fichier]["general"]=array("id"=>$rapport_ligne_data[2]
								,"datetime"=>str_replace("/","-",$rapport_ligne_data[0])." ".$rapport_ligne_data[1]
								,"date"=>$rapport_ligne_data[0]
								,"time"=>$rapport_ligne_data[1]
								,"mac"=>$rapport_ligne_data[3]
								,"ip"=>substr($rapport_ligne_data[4],1)
								,"logfile"=>$rapport_ligne_data[2].".log"
								);

			if (strpos($info[$rapport_fichier]["general"]["ip"],"/")!== false)
			{
				$info[$rapport_fichier]["general"]["ip"]=substr($info[$rapport_fichier]["general"]["ip"],0,strpos($info[$rapport_fichier]["general"]["ip"],"/")-strlen($info[$rapport_fichier]["general"]["ip"]));
			}
			if (substr_count(strtolower($rapport_ligne),"windows 7")>0)
				$info[$rapport_fichier]["general"]["typewin"]="Windows 7";
			elseif (substr_count(strtolower($rapport_ligne),"windows 10")>0)
				$info[$rapport_fichier]["general"]["typewin"]="Windows 10";
                        elseif (substr_count(strtolower($rapport_ligne),"winxp")>0)
                                $info[$rapport_fichier]["general"]["typewin"]="Windows XP";
			else
                                $info[$rapport_fichier]["general"]["typewin"]="Autre";
		}
		else
		{
			$rapport_ligne_data=explode(":",$rapport_ligne);
			switch(ltrim($rapport_ligne_data[0]))
			{
				case "ID":
					$id_app++;
					$info[$rapport_fichier]["App"][$id_app]["ID"]=rtrim(ltrim($rapport_ligne_data[1]));
					break;
				case "Revision":
                                        $info[$rapport_fichier]["App"][$id_app]["Revision"]=rtrim(ltrim($rapport_ligne_data[1]));
                                        break;
				case "Reboot":
                                        $info[$rapport_fichier]["App"][$id_app]["Reboot"]=rtrim(ltrim($rapport_ligne_data[1]));
                                        break;
				case "Status":
                                        $info[$rapport_fichier]["App"][$id_app]["Status"]=rtrim(ltrim($rapport_ligne_data[1]));
                                        break;
				default:
					break;
			}
		}
		$ligne++;
	}
	fclose($rapport_txt);
}
}

$xml = simplexml_load_file("/var/www/se3/wpkg/bin/rapports_vide.xml");
foreach ($info as $info2)
{
	$rapport=$xml->addChild('rapport');
	foreach ($info2["general"] as $key_g=>$info_g)
		$rapport->addAttribute($key_g,$info_g);

	foreach ($info2["App"] as $info_g2)
	{
		$package=$rapport->addChild("package");
		$package->addAttribute("id",$info_g2["ID"]);
		$package->addAttribute("revision",$info_g2["Revision"]);
		$package->addAttribute("reboot",$info_g2["Reboot"]);
		$package->addAttribute("satuts",$info_g2["Status"]);
	}

}

$xml->asXML("/var/se3/unattended/install/wpkg/rapports/rapports.xml");
?>
</body>
</html>
