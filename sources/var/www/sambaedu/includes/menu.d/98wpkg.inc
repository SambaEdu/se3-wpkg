<?php
/* $Id$ */

/**
 * Menu Wpkg
 *
 * @Projet  SambaEdu
 *
 * @Auteurs J Lebail, DBO
 *
 * @Note: Menu de WPKG
 *
 * @Licence Distribue sous la licence GPL
 */

/**
 *
 * file: 98wpkg.inc
 *
 * @Repertoire: includes/menu.d/
 */
if (count(list_delegations($config) > 0)) {
    $liens1 = array(
        array(
            gettext("Applications Windows"),
            "computers_is_admin|parc_can_manage|parc_can_view",
            3,
            gettext("Ajouter une application"),
            "wpkg/admin.html?PageEnCours=AjoutPackage",
            "computers_is_admin",
            3,
            gettext("Gestion des applications"),
            "wpkg/app_liste.php",
            "computers_is_admin|parc_can_manage|parc_can_view",
            3,
            gettext("Gestion des parcs"),
            "wpkg/parc_statuts.php",
            "computers_is_admin|parc_can_manage|parc_can_view",
            3,
            gettext("Gestion des postes"),
            "wpkg/poste_statuts.php",
            "computers_is_admin|parc_can_manage|parc_can_view",
            3,
            gettext("D&#233;tail d'un poste"),
            "wpkg/admin.html?PageEnCours=AfficheHost",
            "computers_is_admin|parc_can_manage|parc_can_view",
            3,
            gettext("Param&#233;trage de Wsus Offline"),
            "wpkg/wsusoffline.php",
            "computers_is_admin|parc_can_manage|parc_can_view",
            3
        )
    );
} else {
    $liens1 = array(
        array(
            gettext("Applications Windows"),
            "",
            3,
            gettext("Ajouter une application"),
            "wpkg/admin.html?PageEnCours=AjoutPackage",
            "computers_is_admin",
            3,
            gettext("Gestion des applications"),
            "wpkg/app_liste.php",
            "",
            3,
            gettext("Gestion des parcs"),
            "wpkg/parc_statuts.php",
            "",
            3,
            gettext("Gestion des postes"),
            "wpkg/poste_statuts.php",
            "",
            3,
            gettext("D&#233;tail d'un poste"),
            "wpkg/admin.html?PageEnCours=AfficheHost",
            "",
            3,
            gettext("Param&#233;trage de Wsus Offline"),
            "wpkg/wsusoffline.php",
            "",
            3
        )
    );
}
if (file_exists("/var/www/se3/wpkg/WindowsUpdate.js")) {
    array_push($liens1[0], gettext("Mises &#224; jour Microsoft"), "wpkg/admin.html?PageEnCours=WindowsUpdate", "computers_is_admin", 3);
}
$liens = array_merge($liens, $liens1);
?>
