<?php
// ## $Id$ ## 
// Définit le fichier $wpkgroot/ini/$computer.ini qui fixe les paramètres d'exécution de wpkg pour ce poste.
header("Pragma: no-cache");
header("Cache-Control: no-cache, must-revalidate");
$wpkgUser = false;
include "inc/wpkg.auth.php";
$ini = "";
if ( ! $wpkgUser ) {
	include entete.inc.php; ?>
		<h2>Déploiement d'applications</h2>
		<div class=error_msg>Vous n'avez pas les droits nécessaires à l'utilisation de cette fonction !</div>
<?  include pdp.inc.php;
	exit;
} else{ ?>
<html>
	<head>
		<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
		<META HTTP-EQUIV="Cache-Control" CONTENT="no-cache"> 
		<meta http-equiv="Pragma" content="no-cache" />
	</head>
	<body>
<?	if ($_GET["Poste"] === '') {
		Erreur("poste non défini");
	} else {
		$Poste = $_GET["Poste"];
		echo "<h3>Configuration du client wpkg sur le poste '$Poste' </h3>";
		$Param = $_GET["Param"];
		$Valeur = $_GET["Valeur"];
		$inifile = "$wpkgroot/ini/".$Poste.".ini";
		$msgOperation = "<br/>";
		$ValueParamChanged = false;
		if ( ! is_dir("$wpkgroot/ini")) {
			mkdir ("$wpkgroot/ini", 0700);
		}
		
		if ( $Param === 'undefined' ) $Param = '';
		
		if ( $Param === 'DELETE' ) {
			if (file_exists($inifile)) {
				if (@unlink($inifile)) {
					$msgOperation .= "Ficher '$inifile' effacé.";
				} else {
					$msgOperation .= "Erreur de suppression de  '$inifile'.<br>";
				}
			} else {
				$msgOperation .= "Il n'y avait pas de fichier '$inifile' a effacer.<br>";
			}
		} else {
			$ini = '';
			if (file_exists($inifile) && (filesize ($inifile) > 0 )) {
				// Lecture du fichier
				if (!$handle = fopen ($inifile, "r")) {
					$msgOperation .= "Impossible d'ouvrir le fichier '$inifile' en lecture.<br>";
					//exit;
				} else {
					$ini = fread ($handle, filesize ($inifile));
					fclose ($handle);
				}
			} else {
				$msgOperation .= "Fichier '$inifile' créé.<br>";
				// A défaut de fichier ini, initialisation avec des valeurs par défaut
				$ini  = "debug=true ' Permet d'avoir des logs plus détaillés.\r\n";
				$ini .= "logdebug=false ' Pour avoir des logs en temps réel sur le serveur.\r\n";
				$ini .= "force=false ' Pour tester la présence ou l'absence effective de chaque appli sur le poste.\r\n";
				$ini .= "forceinstall=false ' Pour installer ou désinstaller les applications même si les tests 'check' sont vérifiés.\r\n";
				$ini .= "nonotify=false ' Pour ne pas avertir l'utilisateur logué des opérations de wpkg.\r\n";
				//$ini .= "norunningstate=false ' Pour que wpkg n'écrive pas running=true dans la base de registre lorsqu'il s'exécute.\r\n";
				$ini .= "dryrun=false ' Pour que wpkg simule une exécution mais n'installe ou ne désinstalle rien.\r\n";
				$ini .= "nowpkg=false ' Pour ne pas exécuter wpkg sur le poste.\r\n";
				$ini .= "nozombie=false ' Pour retirer les applis zombie de la base de données du poste.\r\n";
			}
			
			if ( $ini != '') {
				$Aini = explode ("\r\n", $ini);
				$derligne = array_pop($Aini);
				if ($derligne != "") array_push ($Aini, $derligne);
				
				$r = "";
				$rHtml = '';

				// Affichage HTML des valeurs des options
				$r = '';
				// echo "Param=$Param, ParamFound=$ParamFound<br/><br/>";
				echo "<table>\n";
				foreach ($Aini as $ligne) {
					if ( preg_match("/^\s*(\b[^=]+\b)\s*=\s*(\b[^']+\b)\s*('.*)$/" , $ligne , $t) ) {
						$Parametre = $t[1];
						if (($Param === $Parametre) && ($Valeur != '')) {
							$Val = $Valeur;
							$Param = '';
							$ValueParamChanged = true;
						} else {
							$Val = $t[2];
						}
						$Commentaire = $t[3];
						
						$L = "$Parametre=$Val $Commentaire\r\n";
						echo "<tr>\n";
						if ( NotValeur($Val) != '') {
							echo "<td><button title='$Parametre=".NotValeur($Val)."' style='font-size:x-small;' onclick=\"posteini('$Poste', '$Parametre', '" . NotValeur($Val) . "' );\">Changer</button></td>"; 
						} else {
							echo "<td></td>\n";
						}
						echo "<td>$Parametre=$Val</td>\n";
						//echo utf8_encode("<td> $Commentaire</td>\n");
						echo "<td> $Commentaire</td>\n";
						echo "</tr>\n";
						$r .= $L;
						
					} else {
						echo "Ligne inconnue : '$ligne'<br/>";
						$r .= $ligne . "\r\n";
						$ValueParamChanged = true;
					}
					
				}
				echo "<tr><td align='center' colspan='3'><button style='font-size:small;' onclick=\"posteini('$Poste', 'DELETE', '' );\">Rétablir la configuration par défaut</button></td></tr>\n";
				echo "</table>\n";
				// echo "Param=$Param, ParamFound=$ParamFound<br/><br/>";
				if (($Param != '') && ($Valeur != '')) {
					$L = $Param . "=" . $Valeur ."\r\n";
					$r .= $L;
				}
				
				// Réécriture du fichier 
				if (!$handle = fopen($inifile, 'w')) {
					$msgOperation .= "Impossible d'ouvrir le fichier '$inifile' en écriture.";
				} else {
					if (fwrite($handle, $r) === false) {
						$msgOperation .= "Impossible d'écrire dans le fichier ($inifile)";
					} else {
						if ($ValueParamChanged) $msgOperation .= "Ficher '$inifile' mis à jour.";
					}
					fclose($handle);
				}
				//echo "<pre>";
				//utf8_encode(readfile($inifile)); 
				//echo "</pre>";
			}
			
		}
		//echo utf8_encode("<p>$msgOperation</p>");
		echo "<p>$msgOperation</p>";
		
	}
	?>
	</body>
</html>
<?
}
function NotValeur( $Val ) {
	if ( $Val === '1' ) $NVal = '0';
	elseif  ( $Val === '0' ) $NVal = '1';
	elseif  ( $Val === 'false' ) $NVal = 'true';
	elseif  ( $Val === 'true' ) $NVal = 'false';
	return $NVal;
}
function Erreur505($msg) {
	//header("HTTP/1.1 505 Not found");
	//header("Status: 505 Erreur d'execution"); 
	echo "$msg\n";
}
function Erreur($msg) {
	header("HTTP/1.1 404 Not found");
	header("Status: 404 Not found"); 
	echo "$msg\n";
}

?>
