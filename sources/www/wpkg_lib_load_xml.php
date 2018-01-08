<?php

/**
 * librairie
 * @Version $Id$
 * @Projet LCS / SambaEdu
 * @auteurs  Laurent Joly
 * @note
 * @Licence Distribue sous la licence GPL
 */
/**
 * @Repertoire: wpkg
 * file: wpkg_lib_load_xml.php
*/

	$xml_packages = simplexml_load_file($url_packages);
	$xml_profiles = simplexml_load_file($url_profiles);
	$xml_rapports = simplexml_load_file($url_rapports);
	$xml_time = simplexml_load_file($url_time);
	$xml_hosts = simplexml_load_file($url_hosts);
	$xml_forum = simplexml_load_file($url_forum);

?>