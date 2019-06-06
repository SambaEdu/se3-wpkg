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
 *
 * @Repertoire: wpkg
 * file: wpkg_lib_load_xml.php
 */
if ($fp = fopen("/var/lock/wpkg.lock", 'w+')) {
    $startTime = microtime();
    do {
        $canRead = flock($fp, LOCK_SH);
        // If lock not obtained sleep for 0 - 100 milliseconds, to avoid collision and CPU load
        if (! $canWRead)
            usleep(round(rand(0, 100) * 1000));
    } while ((! $canRead) and ((microtime() - $startTime) < 1000));

    // file was locked so now we can store information
    if ($canRead) {

        $xml_packages = simplexml_load_file($url_packages);
        $xml_profiles = simplexml_load_file($url_profiles);
        $xml_rapports = simplexml_load_file($url_rapports);
        $xml_time = simplexml_load_file($url_time);
        $xml_hosts = simplexml_load_file($url_hosts);
        $xml_forum = simplexml_load_file($url_forum);

        flock($fp, LOCK_UN);
    } else {
        die ("erreur, impossible de lire les xml"); 
    }
}


?>