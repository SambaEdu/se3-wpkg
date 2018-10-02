<?php
/**
 * Affichage de la liste des applications du serveur
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
require_once 'config.inc.php';
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

echo "<form method='get' action=''>\n";
$page_id = 0;
include ("app_top.php");

echo "<input type='hidden' name='parc' value='" . $get_parc . "'>";
echo "<input type='hidden' name='tous' value='" . $get_tous . "'>";
echo "<input type='hidden' name='ok' value='" . $get_ok . "'>";
echo "<input type='hidden' name='warning' value='" . $get_warning . "'>";
echo "<input type='hidden' name='error' value='" . $get_error . "'>";
echo "<input type='hidden' name='tri2' value='" . $tri2 . "'>";
echo "</form>\n";

$liste_appli = get_list_wpkg_app($xml_packages, $xml_time);
$liste_appli_postes = get_list_wpkg_poste_app_all($xml_profiles, $xml_packages);
$liste_appli_status = get_list_wpkg_rapports_statut_app($xml_rapports);
$liste_hosts = get_list_wpkg_hosts($xml_hosts);
$svn_info = get_list_wpkg_svn_info($xml_forum);

foreach ($liste_appli_postes as $key => $value) {
    $liste_appli[$key]["nb_postes"] = count($value) + 0;
}

foreach ($liste_appli as $key => $row) {
    if (is_array($liste_appli_postes[$key]))
        $tmp_liste_appli_poste = array_keys($liste_appli_postes[$key]);
    else
        $tmp_liste_appli_poste = array();
    $liste_status_tmp = get_list_wpkg_app_status($liste_hosts, $tmp_liste_appli_poste, $liste_appli_status[$key], $row['revision']);
    $liste_appli[$key]["NotOk"] = count($liste_status_tmp["NotOk"]);
    $liste_appli[$key]["Ok"] = count($liste_status_tmp["Ok"]);
    $liste_appli[$key]["MaJ"] = count($liste_status_tmp["MaJ"]);

    $name[$key] = strtolower($row['name']);
    $category[$key] = strtolower($row['category']);
    $compatibilite[$key] = $row['compatibilite'] + 0;
    $revision[$key] = $row['revision'];
    $nb_postes[$key] = $row['nb_postes'];
    $date[$key] = $row['date'];
    $NotOk[$key] = $liste_appli[$key]['NotOk'];
    $MaJ[$key] = $liste_appli[$key]['MaJ'];
}

switch ($tri) {
    case 0:
        array_multisort($name, SORT_ASC, $liste_appli);
        break;
    case 1:
        array_multisort($category, SORT_ASC, $name, SORT_ASC, $liste_appli);
        break;
    case 2:
        array_multisort($compatibilite, SORT_DESC, $name, SORT_ASC, $liste_appli);
        break;
    case 3:
        array_multisort($name, SORT_DESC, $liste_appli);
        break;
    case 4:
        array_multisort($category, SORT_DESC, $name, SORT_ASC, $liste_appli);
        break;
    case 5:
        array_multisort($compatibilite, SORT_ASC, $name, SORT_ASC, $liste_appli);
        break;
    case 6:
        array_multisort($date, SORT_DESC, $name, SORT_ASC, $liste_appli);
        break;
    case 7:
        array_multisort($date, SORT_ASC, $name, SORT_ASC, $liste_appli);
        break;
    case 8:
        array_multisort($nb_postes, SORT_DESC, $name, SORT_ASC, $liste_appli);
        break;
    case 9:
        array_multisort($nb_postes, SORT_ASC, $name, SORT_ASC, $liste_appli);
        break;
    case 10:
        array_multisort($NotOk, SORT_DESC, $name, SORT_ASC, $liste_appli);
        break;
    case 11:
        array_multisort($NotOk, SORT_ASC, $name, SORT_ASC, $liste_appli);
        break;
    case 12:
        array_multisort($MaJ, SORT_DESC, $name, SORT_ASC, $liste_appli);
        break;
    case 13:
        array_multisort($MaJ, SORT_ASC, $name, SORT_ASC, $liste_appli);
        break;
    default:
        array_multisort($name, SORT_ASC, $branche, SORT_ASC, $liste_appli);
        break;
}

echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black'>";
echo "<tr bgcolor='white' height='30' valing='center'>";
echo "<th width='300'><a href='?parc=" . $get_parc . "&warning=" . $get_warning . "&error=" . $get_error . "&ok=" . $get_ok . "&tous=" . $get_tous . "&Appli=" . $get_Appli . "&tri2=" . $tri2 . "&tri=";
if ($tri == 0)
    echo "3";
else
    echo "0";
echo "' style='color:" . $regular_lnk . "'>Nom de l'application</a></th>";
echo "<th width='120'>Version</th>";
echo "<th width='120'><a href='?parc=" . $get_parc . "&warning=" . $get_warning . "&error=" . $get_error . "&ok=" . $get_ok . "&tous=" . $get_tous . "&Appli=" . $get_Appli . "&tri2=" . $tri2 . "&tri=";
if ($tri == 2)
    echo "5";
else
    echo "2";
echo "' style='color:" . $regular_lnk . "'>Compatibilit&#233;</a></th>";
echo "<th width='150'><a href='?parc=" . $get_parc . "&warning=" . $get_warning . "&error=" . $get_error . "&ok=" . $get_ok . "&tous=" . $get_tous . "&Appli=" . $get_Appli . "&tri2=" . $tri2 . "&tri=";
if ($tri == 1)
    echo "4";
else
    echo "1";
echo "' style='color:" . $regular_lnk . "'>Cat&#233;gorie</a></th>";
echo "<th width='70'><a href='?parc=" . $get_parc . "&warning=" . $get_warning . "&error=" . $get_error . "&ok=" . $get_ok . "&tous=" . $get_tous . "&Appli=" . $get_Appli . "&tri2=" . $tri2 . "&tri=";
if ($tri == 8)
    echo "9";
else
    echo "8";
echo "' style='color:" . $regular_lnk . "'>Nombre de postes</a></th>";
echo "<th width='70'><a href='?parc=" . $get_parc . "&warning=" . $get_warning . "&error=" . $get_error . "&ok=" . $get_ok . "&tous=" . $get_tous . "&Appli=" . $get_Appli . "&tri2=" . $tri2 . "&tri=";
if ($tri == 10)
    echo "11";
else
    echo "10";
echo "' style='color:" . $regular_lnk . "'>Postes en erreur</a></th>";
echo "<th width='70'><a href='?parc=" . $get_parc . "&warning=" . $get_warning . "&error=" . $get_error . "&ok=" . $get_ok . "&tous=" . $get_tous . "&Appli=" . $get_Appli . "&tri2=" . $tri2 . "&tri=";
if ($tri == 12)
    echo "13";
else
    echo "12";
echo "' style='color:" . $regular_lnk . "'>Postes pas &#224; jour</a></th>";
echo "<th width='120'><a href='?parc=" . $get_parc . "&warning=" . $get_warning . "&error=" . $get_error . "&ok=" . $get_ok . "&tous=" . $get_tous . "&Appli=" . $get_Appli . "&tri2=" . $tri2 . "&tri=";
if ($tri == 6)
    echo "7";
else
    echo "6";
echo "' style='color:" . $regular_lnk . "'>Date d'ajout</a></th>";
echo "<th width='120'>Version SVN</th>";
echo "</tr>";
foreach ($liste_appli as $application) {
    echo "<tr bgcolor='white' height='30' valing='center'>";
    echo "<td><a href='app_parcs.php?Appli=" . $application["id"] . "' style='color:" . $regular_lnk . "'>" . $application["name"] . "</a></td>";
    echo "<td align='center'>" . $application["revision"] . "</td>";
    echo "<td align='center' bgcolor='" . $wintype_txt . "'>";

    switch ($application["compatibilite"]) {
        case 1:
            echo "<img src='winxp.png' witdh='20' height='20'>";
            break;
        case 2:
            echo "<img src='win7.png' witdh='20' height='20'>";
            break;
        case 3:
            echo "<img src='winxp.png' witdh='20' height='20'><img src='win7.png' witdh='20' height='20'>";
            break;
        case 4:
            echo "<img src='win10.png' witdh='20' height='20'>";
            break;
        case 5:
            echo "<img src='winxp.png' witdh='20' height='20'><img src='win10.png' witdh='20' height='20'>";
            break;
        case 6:
            echo "<img src='win7.png' witdh='20' height='20'><img src='win10.png' witdh='20' height='20'>";
            break;
        case 7:
            echo "<img src='winxp.png' witdh='20' height='20'><img src='win7.png' witdh='20' height='20'><img src='win10.png' witdh='20' height='20'>";
            break;
        case 0:
            echo "";
            break;
        default:
            echo "";
            break;
    }
    echo "</td>";
    echo "<td align='center'>" . $application["category"] . "</td>";
    echo "<td align='center'>" . ($application["nb_postes"] + 0) . "</td>";
    echo "<td align='center'";
    if ($application["NotOk"] > 0)
        echo " bgcolor='" . $warning_bg . "' style='color: " . $warning_txt . "'";
    echo ">" . $application["NotOk"] . "</td>";
    echo "<td align='center'";
    if ($application["MaJ"] > 0)
        echo " bgcolor='" . $error_bg . "' style='color: " . $error_txt . "'";
    echo ">" . $application["MaJ"] . "</td>";
    echo "<td align='center'>" . $application["date2"] . "</td>";
    if (isset($svn_info[$application["id"]])) {
        $rev = array();
        if (isset($svn_info[$application["id"]]["stable"])) {
            $rev["stable"] = $svn_info[$application["id"]]["stable"]["revision"];
        }
        if (isset($svn_info[$application["id"]]["test"])) {
            $rev["test"] = $svn_info[$application["id"]]["test"]["revision"];
        }
        if (isset($svn_info[$application["id"]]["XP"]) and get_wpkg_branche_XP() == 1) {
            $rev["XP"] = $svn_info[$application["id"]]["XP"]["revision"];
        }
        if (in_array($application["revision"], $rev)) {
            echo "<td align='center' bgcolor='" . $ok_bg . "' style='color: " . $ok_txt . "'>";
        } else {
            echo "<td align='center' bgcolor='" . $warning_bg . "' style='color: " . $warning_txt . "'>";
        }
        $i = 0;
        foreach ($rev as $key => $value) {
            if ($i > 0)
                echo "<br>";
            echo $value . " (" . $key . ")";
            $i ++;
        }
        echo "</td>";
    } else {
        echo "<td align='center' bgcolor='" . $error_bg . "' style='color: " . $error_txt . "'>-</td>";
    }

    echo "</tr>";
}
echo "</table>";
include ("pdp.inc.php");
?>