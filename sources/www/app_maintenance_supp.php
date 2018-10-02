<?php
/**
 * Suppression d'une application
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
include "wpkg_lib_admin.php";

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

echo "<script>\n";
echo "function checkAll()\n";
echo "{\n";
echo "     var checkboxes = document.getElementsByTagName('input'), val = null; \n";
echo "     for (var i = 0; i < checkboxes.length; i++)\n";
echo "     {\n";
echo "        if (checkboxes[i].type == 'checkbox')\n";
echo "        {\n";
echo "            if (val === null) val = checkboxes[i].checked;\n";
echo "            checkboxes[i].checked = val;\n";
echo "        }\n";
echo "    }\n";
echo " }\n";
echo "</script>\n";

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

$list_appli_required_by = get_list_wpkg_required_by_app($xml_packages);
$stop = 0;

if (isset($_POST["action"]))
    $post_action = $purifier->purify($_POST["action"]);
else
    $post_action = "";

if ($post_action == 'Valider la suppression') {
    echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black' width='900'>\n";
    echo "<tr><th style='color:white'>Suppression de l'application</td></tr>\n";
    echo "<tr bgcolor='#FFF8DC'>";
    echo "<td>\n";
    $stop = 0;

    // test de securite
    if (count($list_appli_required_by[$get_Appli]) > 0) {
        echo "<b><font color='red'>Erreur :</font></b> Pour supprimer l'application, il faut supprimer toutes les applications dont elle d&#233;pend (";
        $i = 0;
        foreach ($list_appli_required_by[$get_Appli] as $larb) {
            if ($i > 0)
                echo ", ";
            echo $liste_appli[$larb]["name"];
            $i ++;
        }
        echo ")";
        echo "<br>\n";
        $stop = 1;
    }

    $nb_poste_app = count($liste_appli_postes[$get_Appli]);
    if ($nb_poste_app > 0) {
        echo "<b><font color='red'>Erreur :</font></b> Pour supprimer l'application, il faut qu'elle ne soit associ&#233;e &#224; aucun poste (" . $nb_poste_app . " postes associ&#233;es)";
        echo "<br>\n";
        $stop = 1;
    }

    if (in_array($get_Appli, $list_protected_app)) {
        echo "<b><font color='red'>Erreur :</font></b> L'application est prot&#233;g&#233;e. Vous ne pouvez pas la supprimer.";
        echo "<br>\n";
    }

    if ($stop == 1) {
        echo "</td>";
        echo "</tr>\n";
        echo "<tr bgcolor='#FFF8DC'>";
        echo "<td align='center'>";
        echo "<b><font color='red'>Suppression annul&#233;e.</font></b><br>";
        echo "</td>";
        echo "</tr>\n";
    } else {
        if (isset($_POST["file"]))
            $post_file = $_POST["file"];
        else
            $post_file = array();
        if ($post_file) {
            foreach ($post_file as $pf) {
                echo "Suppression du fichier <b>" . $url_wpkg . "/" . $pf . "</b><br>\n";
                unlink($url_wpkg . "/" . $pf);
            }
        }
        $return = remove_app($get_Appli, $url_packages);
        if ($return == 0) {
            echo "<font color='red'><b>Erreur lors de la suppression de l'application.</b></font><br>\n";
        } else {
            update_timeStamps($url_time, $get_Appli, "del", "", "", $login);
            clean_timeStamps($url_time);
            echo "<font color='red'><b>Suppression de l'application effectu&#233;e.</b></font><br>\n";
        }
        echo "</td>";
        echo "</tr>\n";
    }
    echo "<tr bgcolor='#FFF8DC'>";
    echo "<th>";
    echo "<a href='app_maintenance.php?parc=" . $get_parc . "&warning=" . $get_warning . "&error=" . $get_error . "&ok=" . $get_ok . "&tous=" . $get_tous . "&Appli=" . $get_Appli . "&tri2=" . $tri2 . "' style='color:" . $regular_lnk . "'>Retour</a>";
    echo "</th>";
    echo "</tr>\n";
    echo "</table>\n";
} else {
    echo "<form method='post' action='?parc=" . $get_parc . "&warning=" . $get_warning . "&error=" . $get_error . "&ok=" . $get_ok . "&tous=" . $get_tous . "&Appli=" . $get_Appli . "&tri2=" . $tri2 . "' style='color:" . $regular_lnk . "'>\n";
    echo "<table cellspadding='2' cellspacing='1' border='0' align='center' bgcolor='black' width='900'>\n";
    echo "<tr><th style='color:white'>Suppression de l'application</td></tr>";
    echo "<tr bgcolor='#FFF8DC'>";
    echo "<td>";

    if (count($list_appli_required_by[$get_Appli]) > 0) {
        echo "<b><font color='red'>Erreur :</font></b> Pour supprimer l'application, il faut supprimer toutes les applications dont elle d&#233;pend (";
        $i = 0;
        foreach ($list_appli_required_by[$get_Appli] as $larb) {
            if ($i > 0)
                echo ", ";
            echo $liste_appli[$larb]["name"];
            $i ++;
        }
        echo ")";
        echo "<br>\n";
        $stop = 1;
    }

    $nb_poste_app = count($liste_appli_postes[$get_Appli]);
    if ($nb_poste_app > 0) {
        echo "<b><font color='red'>Erreur :</font></b> Pour supprimer l'application, il faut qu'elle ne soit associ&#233;e &#224; aucun poste (" . $nb_poste_app . " postes associ&#233;es)";
        echo "<br>\n";
        $stop = 1;
    }

    if (in_array($get_Appli, $list_protected_app)) {
        echo "<b><font color='red'>Erreur :</font></b> L'application est prot&#233;g&#233;e. Vous ne pouvez pas la supprimer.";
        echo "<br>\n";
    }

    if ($stop == 0) {
        $list_files = get_list_wpkg_file_app($xml_packages, $get_Appli);

        echo "<b>Avant de supprimer l'application, v&#233;rifiez qu'elle n'est plus install&#233;e sur les postes.</b>";
        echo "</td>";
        echo "</tr>\n";
        echo "<tr bgcolor='#FFF8DC'>";
        echo "<td>";
        if (count($list_files) > 0) {
            echo "Les fichiers qui ont &#233;t&#233; t&#233;l&#233;charg&#233;s, lors de son installation, peuvent &#233;galement &#234;tre supprim&#233;s du serveur. ";
            echo "Pour cela s&#233;lectionnez ceux que vous voulez effacer. <br>";
            echo "\n";
            echo "<table width='100%' align='left'>";
            echo "<tr>";
            echo "<td width='30' align='center'><input type='checkbox' onchange='checkAll()' name='chk[]' /></td>";
            echo "<td><b>Tous les fichiers / Aucun fichier</b></td>";
            echo "</tr>";
            foreach ($list_files as $lf) {
                echo "<tr>";
                echo "<td width='30' align='center'><input type='checkbox' name='file[]' id='file[]' value='" . $lf . "'></td>";
                echo "<td>" . $lf . "</td>";
                echo "</tr>";
            }
            echo "</table>\n";
            echo "<br>\n";
        } else {
            echo "Aucun fichier n'a &#233;t&#233; t&#233;l&#233;charg&#233;, lors de l'installation de l'application.<br>\n";
        }
        echo "<center><input type='submit' value='Valider la suppression' name='action'></center>";
        echo "</td>";
        echo "</tr>\n";
    } else {
        echo "</td>";
        echo "</tr>\n";
        echo "<tr bgcolor='#FFF8DC'>";
        echo "<td align='center'>";
        echo "<b><font color='red'>Suppression annul&#233;e.</font></b><br>";
        echo "</td>";
        echo "</tr>\n";
    }

    echo "<tr bgcolor='#FFF8DC'>";
    echo "<th>";
    echo "<a href='app_maintenance.php?parc=" . $get_parc . "&warning=" . $get_warning . "&error=" . $get_error . "&ok=" . $get_ok . "&tous=" . $get_tous . "&Appli=" . $get_Appli . "&tri2=" . $tri2 . "' style='color:" . $regular_lnk . "'>Retour</a>";
    echo "</th>";
    echo "</tr>\n";
    echo "</table>";
    echo "</form>\n";
}

include ("pdp.inc.php");
?>