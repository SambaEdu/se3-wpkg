<?php
// Interface de gestion de wpkg
//
// ## $Id$ ##

// Compatibilit� register_globals = Off
foreach($_POST AS $key => $value) {
	${$key} = $value;
}
foreach($_GET AS $key => $value) {
	${$key} = $value;
}
$login = "";
$wpkgAdmin = false;
$wpkgUser = false;

include "inc/wpkg.auth.php";

$DEBUG=1;

$urlMD5 = "";
$status = "";

if (! $login ) {
	echo "<script language=\"JavaScript\" type=\"text/javascript\">\n<!--\n";
	$request = '/wpkg/index.php';
	echo "top.location.href = '/auth.php?request=" . rawurlencode($request) . "';\n";
	echo "//-->\n</script>\n";
} else {
	if ( ! $wpkgUser ) { 
		include entete.inc.php; ?>
			<h2>D&#233;ploiement d'applications</h2>
			<div class=error_msg>Vous n'avez pas les droits n&#233;cessaires &#224; l'utilisation de ce module !</div>
<?		include pdp.inc.php;
		exit;
	} else { 
		# On a affaire a un utilisateur autorise de wpkg

		if ( isset($getXml) ) {
			# Download d'un fichier xml
			get_xml($_GET['getXml']);

		} elseif ( isset($logfile) ) {
			# Download d'un fichier log
			get_fichierCP850("rapports/".$_GET['logfile']);

		} elseif ( isset($iCmd) && isset($associer) && isset($idPackage) && isset($idProfile)) {
			# Association ou dissociation d'une appli � un profile
			//sleep(4); // Simule un serveur qui r�pond lentement
			associer($_GET['iCmd'], $_GET['associer'], $_GET['idPackage'], $_GET['idProfile']);

		} elseif ( isset($updateProfiles) ) {
			echo "<pre>";
			echo "bash /usr/share/se3/scripts/update_hosts_profiles_xml.sh '$computersRdn' '$parcsRdn' '$ldap_base_dn'\n";
			passthru ( "bash /usr/share/se3/scripts/update_hosts_profiles_xml.sh '$computersRdn' '$parcsRdn' '$ldap_base_dn'", $status);
			echo "</pre>\n";
			if ( $status == 0 ) {
				echo "Les fichiers hosts.xml et profiles.xml ont &#233;t&#233; mis &#224; jour.<br>\n";
			} else {
				echo "Erreur $status : bash /usr/share/se3/scripts/update_hosts_profiles_xml.sh '$parcsRdn' '$ldap_base_dn'<br>\n";
			}
			echo "<br>Retourner &#224; la page <a href='index.php'>D&#233;ploiement d'applications</a>.<br>\n";

		} elseif ( isset($updateDroits) ) {
			echo "<pre>";
			echo "bash /usr/share/se3/scripts/update_droits_xml.sh\n";
			passthru ( "bash /usr/share/se3/scripts/update_droits_xml.sh", $status);
			echo "</pre>\n";
			if ( $status == 0 ) {
				echo "Le fichier droits.xml a &#233;t&#233; mis &#224; jour.<br>\n";
			} else {
				echo "Erreur $status : bash /usr/share/se3/scripts/update_droits_xml.sh<br>\n";
			}
			echo "<br>Retourner &#224; la page <a href='index.php'>D&#233;ploiement d'applications</a>.<br>\n";

		} elseif ( isset($extractAppli) ) {
			extractAppli($extractAppli);

		} elseif ( isset($SupprimerAppli) ) {
			if ( adminWpkg() ) {
				# Suppression d'une Appli
				$SupprimerAppli = $_POST['SupprimerAppli'];
				printHead();
				if ( "$SupprimerAppli" != "" ) {
					$deleteFiles = $_POST['deleteFiles'];
					if ( count($deleteFiles) > 0 ) {
						$listdeleteFiles = implode(' ',$deleteFiles);
					} else {
						$listdeleteFiles = '';
					}
					# echo "SupprimerAppli = $SupprimerAppli<br>eleteFiles = $deleteFiles<br>listdeleteFiles=$listdeleteFiles<br>\n";
					SupprAppli( "$SupprimerAppli", "$listdeleteFiles");
				} else {
					echo "Erreur _POST['SupprimerAppli'] est vide !<br>";
				}
				echo "<br>Retourner &#224; la page <a href='index.php'>D&#233;ploiement d'applications</a>.<br>\n";
				echo "</body></html>\n";
			}
		} elseif ( isset($displayDelPackage) ) {
			if ( adminWpkg() ) {
				passthru ( "xsltproc --stringparam idPackage '$displayDelPackage' $wpkgwebdir/displayDelPackage.xsl $wpkgroot/packages.xml", $status);
			}
		} elseif ( $_GET['upload'] == "1" ) {
			if ( adminWpkg() ) {
				# Upload d'un fichier appli.xml
				$ignoreMD5 = $_POST['ignoreWawadebMD5'];
				$pasDeDownload = $_POST['noDownload'];
				if ( $ignoreMD5 || isset($urlWawadebMD5) ) {
					if (isset($urlWawadebMD5)) {
						$urlMD5 = $_POST['urlWawadebMD5'];
					} else {
						$urlMD5 = '';
					}
					if ( isset($LocalappliXml) ) {
						# V�rification que l'appli est d&#233;j&#224; sur le serveur
						if ( file_exists("$wpkgroot/$LocalappliXml") ) {
							printHead();
							$appli = basename("$wpkgroot/$LocalappliXml");
							configAppli($appli);
							
						} else {
							Erreur(404);
							echo "Erreur : le fichier '$wpkgroot/$LocalappliXml' est introuvable !<br>\n";
						}
					} elseif (isset($_FILES['appliXml'])) {
						$uploaddir = "$wpkgroot/tmp/";
						$appli = basename($_FILES['appliXml']['name']);
						$uploadfile = $uploaddir . $appli;
						if (move_uploaded_file($_FILES['appliXml']['tmp_name'], $uploadfile)) {
							printHead();
							echo "<h1>Ajout d'une application</h1>\n";
							echo "<h2>Transfert du fichier XML</h2>\n";
							echo "Le fichier '$appli' a &#233;t&#233; transf&#233;r&#233; avec succ&#232;s.<br>\n";
							flush();
							configAppli($appli);
							echo "</body></html>";
						} else {
							Erreur(404);
							echo "Erreur de transfert du fichier '" . $_FILES['appliXml']['tmp_name'] . "' dans $uploadfile.<br>\n";
							echo '<pre>';
							print_r($_FILES);
							echo '</pre>';
						}
					} else {
						Erreur(404);
						echo "Erreur : appliXml n'est pas d&#233;fini !<br>\n";
					}
				} else {
					Erreur(404);
					echo "Erreur : urlWawadebMD5 n'est pas d&#233;fini et le contr&#244;le MD5 est demand&#233; !<br>\n";
				}
				echo "<br>Retourner &#224; la page <a href='index.php'>D&#233;ploiement d'applications</a>.<br>\n";
				echo "</body></html>";
			}
		} elseif ( $_GET['UpdateApplis'] == "1" ) {
			if ( adminWpkg() ) {
				# Installation d'applis � partir du d�pot officiel
				if (isset($urlWawadebMD5)) {
					$urlMD5 = isset($urlWawadebMD5) ? $_POST['urlWawadebMD5'] : '';
					$pasDeDownload = $_POST['noDownload'];
					$ignoreMD5 = $_POST['ignoreWawadebMD5'];
					printHead();
					if (count($chk) > 0) {
						echo "<h1>Mise &#224; jour des applications</h1>\n";
						while (list ($key,$val) = @each ($chk)) {
							# Pour eviter : Fatal error:  Maximum execution time of 30 seconds exceeded
							set_time_limit(300);
							//echo "key=$key, val=$val<br>\n";
							list($forum, $xml, $url) = preg_split('/:/', $val, 3); 

							echo "<div style='width: 100%;padding-top: 10px;padding-right: 10px;padding-bottom: 10px;padding-left: 10px;vertical-align: text-bottom;text-align: center;color: #005594;font-weight: bold;font-size: 16pt;background-color: #6699cc;'>Installation de '<b>$xml</b>'</div>\n";
							echo "<h3>T&#233;l&#233;chargement</h3>\n";
							echo "<pre>";
							passthru ( "cd $wpkgroot/tmp;wget --output-document='$xml' '$url' 2>&1", $status);
							echo "</pre>";
							if ($status != 0 ) {
								echo "Erreur : status=$status<br>\n";
							} else {
								$LastignoreMD5 = $ignoreMD5;
								if ($forum == 'test') {
									$ignoreMD5 = '1';
								}
								configAppli($xml);
								$ignoreMD5 = $LastignoreMD5;
							}
						} 
					} else {
						echo "Aucune application n'&#233;tait s&#233;lectionn&#233;e !<br/>\n";
					}
					echo "<br>Retourner &#224; la page <a href='index.php'>D&#233;ploiement d'applications</a>.<br>\n";
					echo "</body></html>";
				}
			}
		} else {
			# Par d�faut redirection sur admin.html
			header("Location: http://" . $_SERVER['HTTP_HOST'] . rtrim(dirname($_SERVER['PHP_SELF']), '/\\') . "/admin.html");
		}
	}
}

function adminWpkg() {
	global $wpkgAdmin;
	if ( ! $wpkgAdmin ) { 
		?>
			<link  href='../style.css' rel='StyleSheet' type='text/css'>
			<html><body>
			<h2>D&#233;ploiement d'applications</h2>
			<div class=error_msg>Vous devez avoir des droits d'administration pour utiliser cette fonction !</div>
<?		include "pdp.inc.php";
		return false;
	} else { 
		return true;
	}
}
function configAppli($Appli) {
	global $urlMD5, $wpkgroot, $wpkgwebdir, $ignoreMD5, $pasDeDownload, $status, $login;
	$md5Checked = $ignoreMD5;

	$status = runprint("bash $wpkgwebdir/bin/installPackage.sh '$Appli' '$pasDeDownload' '$login' '$urlMD5' '$ignoreMD5'");
	# echo "status=$status<br>\n";
	if ( $status != 0 ) {
		#echo "Erreur $status. Le contenu du fichier '$Appli' n'a pas &#233;t&#233; ajout&#233; aux applications disponibles.<br>";
	} else {
		#echo "<br>F&#233;licitation ! Le contenu du fichier <b>$Appli</b> a &#233;t&#233; ajout&#233; avec succ&#232;s.<br>\n";
	}
	echo '</body></html>';

}

function microtime_float() {
	list($usec, $sec) = explode(" ", microtime());
	return ((float)$usec + (float)$sec);
}

function runprint ( $cmd ) {
	# Ex�cute $cmd en affichant son r�sultat

	$handle = popen("$cmd 2>&1", 'r');
	if (is_resource($handle)) {
		$timestamp = microtime_float();
		$ch = "";
		sleep(1);
		while ( !feof($handle) ) {
			# Pour eviter : Fatal error:  Maximum execution time of 30 seconds exceeded
			set_time_limit(300);
			$car = fread($handle, 1);
			if ( strlen($car) == 0 ) {
				sleep(1);
			} else {
				$ch = "$ch$car";
			}
			if ( (microtime_float() - $timestamp) > 1 ) {
				echo "$ch";
				$ch = "";
				$timestamp = microtime_float();
				flush();
			}
		}
		echo "$ch";
		flush();
		if (pclose($handle)) {
			return 0;
		}else {
			return 1;
		}
	} else {
		return 1;
	}

}

function printHead() { 
?>
	<html>
		<head>
			<title>D&#233;ploiement d'applications</title>
			<link  href='../style.css' rel='StyleSheet' type='text/css'>
		</head>
	<body>  
<?
}

function Erreur($iErr) {
	if ( $iErr == 404 ) {
		header("HTTP/1.1 404 Not found");
		header("Status: 404 Not found"); 
	} elseif ( $iErr == 403 ) {
		header("HTTP/1.1 403 Forbidden");
		header("Status: 403 Forbidden"); 
	} else {
		header("HTTP/1.1 $iErr Erreur $iErr");
		header("Status: $iErr Erreur $iErr"); 
	}
}

function extractAppli ($idAppli) {
	global $DEBUG, $wpkgwebdir, $wpkgroot;
	// Retourne au client le xml de l'appli extraite du fichier $wpkgroot/packages.xml
	$DateFichier = gmdate("D, d M Y H:i:s T", filemtime("$wpkgroot/packages.xml"));
	header("Content-type: application/xml");
	header("Last-Modified: $DateFichier");
	header("Expires: " . gmdate("D, d M Y H:i:s T", time() + 5));
	header("Pragma: no-cache");
	header("Cache-Control: max-age=5, s-maxage=5, no-cache, must-revalidate");
	#header("Content-Disposition: attachment; filename=".$filename);
	#header("Cache-Control: no-store, no-cache, must-revalidate");
	
	//echo "xsltproc --stringparam Appli \"$idAppli\"  $wpkgwebdir/bin/extractAppli.xsl $wpkgroot/packages.xml\n";
	passthru ( "xsltproc --stringparam Appli \"$idAppli\"  $wpkgwebdir/bin/extractAppli.xsl $wpkgroot/packages.xml", $status);
	if ( $status == 0 ) {
		return true;
	} else {
		return false;
	}
}

function associer ($iCmd, $operation, $package, $profile) {
	global $DEBUG, $wpkgwebdir, $wpkgroot, $wpkgAdmin, $wpkgUser, $login;
	# Associe un appli � un profil si l'utilisateur en a le droit
	
	exec ( "$wpkgwebdir/bin/associer.sh '$operation' '$package' '$profile' '$login' 2>&1", $output, $status );
	//$last_line = system ( "$wpkgwebdir/bin/associer.sh '$operation' '$package' '$profile' '$login' >/dev/null 2>&1", $status);
	if ( $status == 10 ) {
		header("Pragma: no-cache");
		header("Cache-Control: max-age=5, s-maxage=5, no-cache, must-revalidate");
		//header("Cache-Control: no-cache, must-revalidate");
		echo "OK\n";
		return true;
	} else {
		Erreur(403);
		header("Pragma: no-cache");
		header("Cache-Control: max-age=5, s-maxage=5, no-cache, must-revalidate");
		//echo "$last_line\n";
		echo "Erreur : $login ne peut pas $operation '$profile' et '$package'\n";
		echo "status=$status\n";
		echo "iCmd=$iCmd\n";
		echo "\n";
		foreach($output as $key => $value) {
			echo "   $value\n";
		}
		//echo "last_line=$last_line\n";
		return false;
	}
}

function SupprAppli ( $idAppli, $delFiles) {
	global $wpkgwebdir, $login;
	# echo "Ex�cution de : bash $wpkgwebdir/bin/deletePackage.sh '$idAppli' '$delFiles'<br>";
	echo "<h3>Suppression de l'application '$idAppli'</h3>\n";
	echo "<pre>";
	passthru ( "bash $wpkgwebdir/bin/deletePackage.sh '$login' '$idAppli' '$delFiles' 2>&1", $status);
	echo "</pre>\n";
	if ( $status != 0 ) {
		echo "Erreur $status<br>\n";
	}
}
?>
