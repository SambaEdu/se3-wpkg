<?php
/**
 * Maintenance d'une application
 * @Version $Id$
 * @Projet LCS / SambaEdu
 * @auteurs  Laurent Joly
 * @note
 * @Licence Distribue sous la licence GPL
 */
/**
 *
 * @Repertoire: dhcp
 * file: reservations.php
 */
// loading libs and init
include "entete.inc.php";
include_once "ldap.inc.php";
include "ihm.inc.php";
include "wpkg_lib.php";

$login = isauth();
if (! $login) {
    echo "<script language=\"JavaScript\" type=\"text/javascript\">\n<!--\n";
    $request = '/wpkg/index.php';
    echo "top.location.href = '/auth.php?request=" . rawurlencode($request) . "';\n";
    echo "//-->\n</script>\n";
    exit();
}

if (! have_right($config, "computers_is_admin"))
    die(gettext("Vous n'avez pas les droits suffisants pour acc&#233;der &#224; cette fonction") . "</BODY></HTML>");

// HTMLpurifier
include ("../sambaedu/includes/library/HTMLPurifier.auto.php");
$conf = HTMLPurifier_Config::createDefault();
$purifier = new HTMLPurifier($conf);

if (isset($_GET["tri"]))
    $tri = $purifier->purify($_GET["tri"]) + 0;
else
    $tri = 0;
if (isset($_GET["tri2"]))
    $tri2 = $purifier->purify($_GET["tri2"]) + 0;
else
    $tri2 = 0;
if (isset($_GET['Appli']))
    $get_Appli = $purifier->purify($_GET['Appli']);
else
    $get_Appli = "";
if (isset($_GET['parc']))
    $get_parc = $purifier->purify($_GET['parc']);
else
    $get_parc = "";
if (isset($_GET["warning"]))
    $get_warning = $purifier->purify($_GET["warning"]) + 0;
else
    $get_warning = 1;
if (isset($_GET["error"]))
    $get_error = $purifier->purify($_GET["error"]) + 0;
else
    $get_error = 1;
if (isset($_GET["ok"]))
    $get_ok = $purifier->purify($_GET["ok"]) + 0;
else
    $get_ok = 0;
if (isset($_GET["tous"]))
    $get_tous = $purifier->purify($_GET["tous"]) + 0;
else
    $get_tous = 0;

$liste_rapports_status_poste = get_list_wpkg_rapports_statut_poste_app($xml_rapports);
$liste_postes_parc = get_list_wpkg_poste_parc($xml_profiles);
$liste_parcs = array_keys($liste_postes_parc);
asort($liste_parcs);

if (! count($liste_postes_parc[$get_parc])) {
    $get_parc = "_TousLesPostes";
}

echo "<form method='get' action=''>\n";
$page_id = 2;
include ("app_top.php");

echo "<input type='hidden' name='parc' value='" . $get_parc . "'>";
echo "<input type='hidden' name='tous' value='" . $get_tous . "'>";
echo "<input type='hidden' name='ok' value='" . $get_ok . "'>";
echo "<input type='hidden' name='warning' value='" . $get_warning . "'>";
echo "<input type='hidden' name='error' value='" . $get_error . "'>";
echo "<input type='hidden' name='tri2' value='" . $tri2 . "'>";
echo "</form>\n";

echo "<table align='center'>\n";
echo "<tr>\n";
echo "<td align='center'>";
echo "<a href='app_maintenance_supp.php?tri2=" . $tri2 . "&Appli=" . $get_Appli . "&parc=" . $get_parc . "&tous=" . $get_tous . "&ok=" . $get_ok . "&warning=" . $get_warning . "&error=" . $get_error . "'>Suppression de l'application</a>";
echo "</td>\n";
echo "</tr>\n";
echo "<tr>\n";
echo "<td align='center'>";
echo "<a href='app_maintenance_poste.php?tri2=" . $tri2 . "&Appli=" . $get_Appli . "&parc=" . $get_parc . "&tous=" . $get_tous . "&ok=" . $get_ok . "&warning=" . $get_warning . "&error=" . $get_error . "'>Choix du déploiement sur les postes</a>";
echo "</td>\n";
echo "</tr>\n";
echo "<tr>\n";
echo "<td align='center'>";
echo "<a href='app_maintenance_parc.php?tri2=" . $tri2 . "&Appli=" . $get_Appli . "&parc=" . $get_parc . "&tous=" . $get_tous . "&ok=" . $get_ok . "&warning=" . $get_warning . "&error=" . $get_error . "'>Choix du déploiement sur les parcs</a>";
echo "</td>\n";
echo "</tr>\n";
echo "</table>\n";

include ("pdp.inc.php");
?>