<?php
	echo header('Content-type: text/xml');
	$url_packages = "/var/se3/unattended/install/wpkg/packages.xml";
	echo file_get_contents($url_packages);
?>