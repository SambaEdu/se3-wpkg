<html lang="fr">
<HEAD>
<meta charset="utf-8">
<link rel="StyleSheet" type="text/css" href="style.css"></HEAD>
<title>Version des paquets SE3 wheezy</title>
<meta name=generator content=HTML::TextToHTML v2.51/>
</head>
<body background="fond_SE3.png">
<h1>Liste des applications déployables sur SE3 wheezy</h1>
<?php
	
	$wawadeburl="wpkg-list-ng";
	$svnurl="http://svn.tice.ac-caen.fr/svn/SambaEdu3/wpkg-packages-ng";
	
	$xml_stable = simplexml_load_file($wawadeburl."/packages_stable.xml");
	$xml_testing = simplexml_load_file($wawadeburl."/packages_testing.xml");
	
	$liste=array();
	
	foreach ($xml_stable->package as $app)
	{

		$liste[] = array("id"=>$app["id"],
						 "xml"=>$app["xml"],
						 "url"=>$app["url"],
						 "md5sum"=>$app["md5sum"],
						 "date"=>$app["date"],
						 "svn_link"=>$app["svn_link"],
						 "category"=>str_replace("'"," ",$app["category"]),
						 "name"=>str_replace("'"," ",$app["name"]),
						 "compatibilite"=>$app["compatibilite"],
						 "revision"=>$app["revision"],
						 "branche"=>"stable");
	}
	foreach ($xml_testing->package as $app)
	{

		$liste[] = array("id"=>$app["id"],
						 "xml"=>$app["xml"],
						 "url"=>$app["url"],
						 "md5sum"=>$app["md5sum"],
						 "date"=>$app["date"],
						 "svn_link"=>$app["svn_link"],
						 "category"=>str_replace("'"," ",$app["category"]),
						 "name"=>str_replace("'"," ",$app["name"]),
						 "compatibilite"=>$app["compatibilite"],
						 "revision"=>$app["revision"],
						 "branche"=>"testing");
	}
	
	foreach ($liste as $key => $row)
	{
		$name[$key]  = strtolower($row['name']);
		$category[$key] = $row['category'];
		$date[$key] = substr($row['date'],0,4).substr($row['date'],5,2).substr($row['date'],8,2).substr($row['date'],11,2).substr($row['date'],14,2).substr($row['date'],17,2);
		$branche[$key] = $row['branche'];
		$revision[$key] = $row['revision'];
	}
	
	if (isset($_GET["tri"]))
		$tri=$_GET["tri"]+0;
	else
		$tri=0;	
	
	switch ($tri)
	{
		case 0:
		array_multisort($name, SORT_ASC, $branche, SORT_ASC, $liste);
		break;
		case 1:
		array_multisort($category, SORT_ASC, $branche, SORT_ASC, $liste);
		break;
		case 2:
		array_multisort($date, SORT_DESC, $branche, SORT_ASC, $liste);
		break;
		default:
		array_multisort($name, SORT_ASC, $branche, SORT_ASC, $liste);
		break;
	}

	
	echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>";
	echo "<tr bgcolor='white' height='30' valing='center'>";
	echo "<th width='300'><a href='?tri=0'>Nom de l'application</a></th>";
	echo "<th width='120'>Version</th>";
	echo "<th width='120'>Compatibilit&#233;</th>";
	echo "<th width='150'><a href='?tri=1'>Cat&#233;gorie</a></th>";
	echo "<th width='50'>Info</th>";
	echo "<th width='80'>branche</th>";
	echo "<th width='120'><a href='?tri=2'>Mise &#224; jour</a></th>";
	echo "</tr>";
	foreach ($liste as $application)
	{
		echo "<tr bgcolor='white' height='30' valing='center'>";
		echo "<td><a href='".$application["url"]."' target='info'>".$application["name"]."</a></td>";
		echo "<td align='center'>".$application["revision"]."</td>";
		echo "<td align='center'>";
		
		switch ($application["compatibilite"])
		{
			case 1:
			echo "<img src='".$wawadeburl."/winxp.png' witdh='20' height='20'>";
			break;
			case 2:
			echo "<img src='".$wawadeburl."/win7.png' witdh='20' height='20'>";
			break;
			case 3:
			echo "<img src='".$wawadeburl."/winxp.png' witdh='20' height='20'><img src='".$wawadeburl."/win7.png' witdh='20' height='20'>";
			break;
			case 4:
			echo "<img src='".$wawadeburl."/win10.png' witdh='20' height='20'>";
			break;
			case 5:
			echo "<img src='".$wawadeburl."/winxp.png' witdh='20' height='20'><img src='".$wawadeburl."/win10.png' witdh='20' height='20'>";
			break;
			case 6:
			echo "<img src='".$wawadeburl."/win7.png' witdh='20' height='20'><img src='".$wawadeburl."/win10.png' witdh='20' height='20'>";
			break;
			case 7:
			echo "<img src='".$wawadeburl."/winxp.png' witdh='20' height='20'><img src='".$wawadeburl."/win7.png' witdh='20' height='20'><img src='".$wawadeburl."/win10.png' witdh='20' height='20'>";
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
		echo "<td align='center'><a href='".$application["svn_link"]."' target='info'>Info</a></td>";
		echo "<td align='center'>".$application["branche"]."</td>";
		echo "<td align='center'>".substr($application["date"],8,2)."/".substr($application["date"],5,2)."/".substr($application["date"],0,4)."</td>";
		echo "</tr>";
		/*echo $application["id"]." ";
		echo $application["md5sum"]." ";
		echo $application["xml"]." ";
		*/

	}
	echo "</table>";

?>