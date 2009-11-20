<?php

// inc/wpkg.auth.php
// Gère l'authentification sur le serveur se3 de l'interface web de wpkg
// La fonction get_xml retourne le fichier xml demandé par l'utilisateur authentifié
//
//  $Id$


//include "entete.inc.php";
require_once('http-conditional.php');
require_once ("config.inc.php");
require_once ("functions.inc.php");
require_once "ldap.inc.php";
require_once "ihm.inc.php";

$wpkgroot="/var/se3/unattended/install/wpkg";
$wpkgwebdir="/var/www/se3/wpkg";

$login = isauth();
if (! $login ) {
    echo "<script language=\"JavaScript\" type=\"text/javascript\">\n<!--\n";
    $request = '/wpkg/index.php';
    echo "top.location.href = '/auth.php?request=" . rawurlencode($request) . "';\n";
    echo "//-->\n</script>\n";
    exit;
}
$wpkgAdmin = isWpkgAdmin($login);
$wpkgUser = isWpkgUser($login);
//echo "<script language=\"JavaScript\" type=\"text/javascript\">\n<!--\n";
//echo "alert('login=$login, wpkgAdmin=$wpkgAdmin, wpkgUser=$wpkgUser');";
//echo "//-->\n</script>\n";
if ( ! $wpkgUser ) {
    //include "entete.inc.php";
    ?>
            <h2>Déploiement d'applications</h2>
            <div class=error_msg>Vous n'avez pas les droits nécessaires à l'utilisation de ce module !</div>
    <?
    include "pdp.inc.php";
    exit;
}

function isWpkgAdmin($login) {
    // Droit nécessaire pour ajouter ou supprimer une application
    if (is_admin("computers_is_admin",$login)=="Y") {
        return true;
    } else {
        return false;
    }
}

function isWpkgUser($login) {
    global $DEBUG, $wpkgAdmin;
    if ($wpkgAdmin || is_admin("parc_can_manage",$login)=="Y" || is_admin("parc_can_view",$login)=="Y") {
        return true;
    } else {
        $query="select login from delegation  where login='$login' and ( niveau='view' or niveau='manage');";
        $result=mysql_query($query) or die("Impossible d'accéder à la table");
        $ligne=mysql_num_rows($result);
        return ( $ligne != 0 );
    }
}

function get_html($xsl, $xml, $param)
// retourne le résultat de la transformation appliqué au fichier xml
{
    global $DEBUG, $wpkgAdmin, $wpkgUser, $wpkgroot;
	$parametres = '';
    #$nomFichier = $aFilePath[$nPath-1];
    #if ($DEBUG > 0) echo "xsl=".$xsl."<br>\n";
    #if ($DEBUG > 0) echo "xml=".$xml."<br>\n";
    #if ($DEBUG > 0) print_r($param);
# $wpkgAdmin=1;
    if ($wpkgUser) {
        if (file_exists("$xml")) {
            // Date: Mon, 15 Jan 2007 10:06:50 GMT
            $dateLastModification = filemtime("$xml");
            if (httpConditional($dateLastModification)) {
                exit(); //No need to send anything
            } else {
				$DateFichier = gmdate('D, d M Y H:i:s \G\M\T', $dateLastModification);
				header("Content-type: text/html");
				header("Last-Modified: $DateFichier");
				header("Expires: " . gmdate("D, d M Y H:i:s T", time() ));
				header("Pragma: no-cache");
				//header("Cache-Control: max-age=5, s-maxage=5, no-cache, must-revalidate");
				header("Cache-Control: must-revalidate");
				header("Content-Disposition: inline; filename=".basename ($xml));
				foreach($param as $key=> $val){
					$parametres .= " --stringparam '" . $key . "' '" . $val . "'";
				}
				# echo "xsltproc $parametres '$xsl' '$xml' 2>&1";
				passthru ( "xsltproc $parametres '$xsl' '$xml' 2>&1", $status);
				if ($status != 0 ) {
					echo "<pre>\nErreur xsltproc $parametres $xsl $xml : status=$status</pre><br>\n";
					return false;
				} else {
					return true;
				}
			}
        } else {
            header("HTTP/1.1 404 Not found");
            header("Status: 404 Not found"); 
            echo "Erreur : Le fichier $xml est introuvable !\n";
            echo "Sans doute un problème de droits.\n";
            return false;
        }
    } else {
        echo "Erreur : vous n'êtes pas autorisé à afficher cette page !\n";
        return false;
    }
}

function get_xml($filename)
// Retourne le fichier xml demandé (profiles.xml, packages.xml ou hosts.xml) si les droits de l'utilisateur en cours le permettent
{
    global $DEBUG, $wpkgAdmin, $wpkgUser, $wpkgroot;
    #$nomFichier = $aFilePath[$nPath-1];
    $PathFichier = "$wpkgroot/$filename";
    #if ($DEBUG > 0) echo "nomFichier=".$nomFichier."<br>\n";
    #if ($DEBUG > 0) echo "PathFichier=".$PathFichier."<br>\n";
# $wpkgAdmin=1;
    if ($wpkgUser) {
        if (file_exists("$PathFichier")) {
            // Date: Mon, 15 Jan 2007 10:06:50 GMT
            $dateLastModification = filemtime("$PathFichier");
            if (httpConditional($dateLastModification)) {
                exit(); //No need to send anything
            } else {
				//$DateFichier = gmdate("D, d M Y H:i:s T", $dateLastModification);
				//$DateFichier = gmdate("D, d M Y H:i:s", $dateLastModification) . " GMT" ;
				$DateFichier = gmdate('D, d M Y H:i:s \G\M\T', $dateLastModification);
				# mktime ( int   hour  , int   minute  , int   second  , int   month  , int   day  , int   year  , int   is_dst  )
				# $DatePassee = gmdate("D, d M Y H:i:s T", mktime(0, 0, 0, 1, 1, 1998));
				header("Content-type: text/xml");
				header("Last-Modified: $DateFichier");
				//header("Expires: " . gmdate("D, d M Y H:i:s T", time() + 5));
				header("Pragma: no-cache");
				//header("Cache-Control: max-age=5, s-maxage=5, no-cache, must-revalidate");
				header("Cache-Control: must-revalidate");
				header("Content-Disposition: inline; filename=".basename ($filename));
				#header("Cache-Control: no-store, no-cache, must-revalidate");
				//flush();
				if ( readfile("$PathFichier") ) {
					return true;
				} else {
					return false;
				}
			}
        } else {
            header("HTTP/1.1 404 Not found");
            header("Status: 404 Not found"); 
            echo "Erreur : Le fichier $PathFichier est introuvable !\n";
            echo "Sans doute un problème de droits.\n";
            return false;
        }
    } else {
        echo "Erreur : vous n'êtes pas administrateur wpkg !\n";
        return false;
    }
}

function get_fichierCP850($filename)
// Retourne le fichier demandé (utilisé pour les fichiers rapports/*.log)
// après conversion CP850/CR-LF..819/CR-LF  ( dos oem -> iso-8859-1 )
{
    global $DEBUG, $wpkgAdmin, $wpkgUser, $wpkgroot;
    #$nomFichier = $aFilePath[$nPath-1];
    $PathFichier = "$wpkgroot/$filename";
    #if ($DEBUG > 0) echo "nomFichier=".$nomFichier."<br>\n";
    #if ($DEBUG > 0) echo "PathFichier=".$PathFichier."<br>\n";
# $wpkgAdmin=1;
    if ($wpkgUser) {
        if (file_exists("$PathFichier")) {
            // Date: Mon, 15 Jan 2007 10:06:50 GMT
            $DateFichier = gmdate("D, d M Y H:i:s T", filemtime("$PathFichier"));
            # mktime ( int   hour  , int   minute  , int   second  , int   month  , int   day  , int   year  , int   is_dst  )
            # $DatePassee = gmdate("D, d M Y H:i:s T", mktime(0, 0, 0, 1, 1, 1998));
            
            
            header("Content-Transfer-Encoding: 8bit");
            header("Content-type: text/html; charset=ISO-8859-1"); // IE ne gère pas bien text/plain :(
            header("Last-Modified: $DateFichier");
            header("Expires: " . gmdate("D, d M Y H:i:s T", time() + 30));
            header("Pragma: no-cache");
            header("Cache-Control: max-age=5, s-maxage=5, no-cache, must-revalidate");
            header("Content-Disposition: inline; filename=".$filename.".txt");
            #header("Cache-Control: no-store, no-cache, must-revalidate");
            //flush();
            echo "<pre>\n"; // toujours pour IE
			$handle = fopen ("$PathFichier", "r");
			$contents = fread ($handle, filesize ($PathFichier));
			fclose ($handle);
			echo htmlspecialchars($contents);
            //if ( readfile("$PathFichier") ) {
            // Conversion OEM -> ANSI déjà faite dans le script (plus de dépendance avec recode)
            //passthru ( "cat $PathFichier | recode CP850/CR-LF..819/CR-LF", $status);
            // htmlspecialchars(passthru ( "cat $PathFichier", $status));
            echo "\n</pre>\n";
            if ( $status == 0 ) {
                return true;
            } else {
                return false;
            }
        } else {
            header("HTTP/1.1 404 Not found");
            header("Status: 404 Not found"); 
            echo "Erreur : Le fichier $PathFichier est introuvable !\n";
            echo "Sans doute un problème de droits.\n";
            return false;
        }
    } else {
        echo "Erreur : vous n'êtes pas autorisé à utiliser cette fonction !\n";
        return false;
    }
}
?>