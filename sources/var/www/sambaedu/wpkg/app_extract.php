<?php

include ("wpkg_lib.php");

$url_packages = "/var/se3/unattended/install/wpkg/packages.xml";

$Appli=$_GET["extractAppli"];

echo header('Content-type: text/xml');
echo extract_app($Appli,$url_packages);

?>
