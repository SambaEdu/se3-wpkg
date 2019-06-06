<?php

	$repertoire = "/var/se3/unattended/install/wpkg/rapports/";

	if (isset($_GET["logfile"]))
	{
		$logfile=$_GET["logfile"];
	}
	else
	{
		echo "Erreur! Pas de machine déclarée.";
		exit;
	}

	header("Content-Transfer-Encoding: 8bit");
	header("Content-type: text/html; charset=UTF-8");
	header("Pragma: no-cache");
	header("Cache-Control: max-age=5, s-maxage=5, no-cache, must-revalidate");
	echo "<html><body>";
	$tabfich=file($repertoire.$logfile);
	foreach ($tabfich as $ligne)
	{
			$ligne=htmlspecialchars(utf8_encode($ligne), ENT_QUOTES);
			if (strstr($ligne,"===============================================================") or strstr($ligne,"-----"))
			{
				$ligne="<b><font color='red'>".$ligne."</font></b>";
			}
			echo $ligne."<br>";
	}
	echo "</body></html>";
?>