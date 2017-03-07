<?php
// $GET
if (isset($_GET['branch']))
{
	switch ($_GET['branch'])
	{
		case "testing":
			$branche="testing"; break;
		case "XP":
			$branche="XP"; break;
		case "stable":
			$branche="stable"; break;
		default:
			$branche="stable"; break;
	}
}
else
	$branche="stable";
if (file_exists("packages_".$branche.".xml"))
	echo file_get_contents("packages_".$branche.".xml");
else
	echo "erreur";

?>