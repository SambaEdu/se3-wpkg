<?php

	if (isset($_GET["tri2"]))
		$tri2=$purifier->purify($_GET["tri2"])+0;
	else
		$tri2=0;
	if (isset($_GET['id_host']))
		$get_id_host=$purifier->purify($_GET['id_host']);
	else
		$get_id_host="";
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
	
	header ("Location: poste_statuts.php?tri2=".$tri2."&id_host=".$get_id_host."&ok=".$get_ok."&warning=".$get_warning."&error=".$get_error);
?>