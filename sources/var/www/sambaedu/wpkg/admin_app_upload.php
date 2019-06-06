<?
/**
 * Upload d'un xml
 * @Version $Id$
 * @Projet LCS / SambaEdu
 * @auteurs  Laurent Joly
 * @note
 * @Licence Distribue sous la licence GPL
 */

	// loading libs and init
	include "entete.inc.php";
	include "ihm.inc.php";
	include "wpkg_lib.php";
	include "wpkg_libsql.php";
	include "wpkg_lib_admin.php";

	$login = isauth();
	if (! $login )
	{
		echo "<script language=\"JavaScript\" type=\"text/javascript\">\n<!--\n";
		$request = '/wpkg/index.php';
		echo "top.location.href = '/auth.php?request=" . rawurlencode($request) . "';\n";
		echo "//-->\n</script>\n";
		exit;
	}

	if (is_admin("computers_is_admin",$login)!="Y")
		die (gettext("Vous n'avez pas les droits suffisants pour acc&#233;der &#224; cette fonction")."</BODY></HTML>");

	// HTMLpurifier
	include("../se3/includes/library/HTMLPurifier.auto.php");
	$config = HTMLPurifier_Config::createDefault();
	$purifier = new HTMLPurifier($config);

	if (isset($_POST["ignoreWawadebMD5"]))
		$ignoreWawadebMD5=$purifier->purify($_POST["ignoreWawadebMD5"])+0;
	else
		$ignoreWawadebMD5=0;
	if (isset($_POST["noDownload"]))
		$noDownload=$purifier->purify($_POST["noDownload"])+0;
	else
		$noDownload=0;

	if (isset($_FILES['appliXml']))
	{
		$liste_appli=liste_applications();
		$uploaddir = $wpkgroot."/tmp2/";
		$appli = basename($_FILES['appliXml']['name']);
		$name_import=pathinfo($appli,PATHINFO_FILENAME)."_".date("Ymd")."_".date("His").".".pathinfo($appli,PATHINFO_EXTENSION);
		$uploadfile = $uploaddir.$name_import;
		$hash_xml=hash_file('sha512',$_FILES['appliXml']['tmp_name']);
		if ($ignoreWawadebMD5==0 and $hash_xml!=$hash_xml)
		{
			echo "<h1>Ajout d'une application</h1>\n";
			echo "<h2>Transfert du fichier XML</h2>\n";
			echo "Le fichier '<b>".$appli."</b>' n'a pas &#233;t&#233; transf&#233;r&#233; car le contr&#244;le de hashage a &#233;chou&#233;.<br>\n";
			echo "Hashage du fichier transf&#233;r&#233; : ".$hash_xml."<br>\n";
			echo "Hashage du fichier du d&#233;p&#244;t : ".$hash_xml."<br>\n";
			flush();
		}
		elseif ($_FILES['appliXml']['type']!="text/xml")
		{
			echo "<h1>Ajout d'une application</h1>\n";
			echo "<h2>Transfert du fichier XML</h2>\n";
			echo "Le fichier '<b>".$appli."</b>' n'a pas &#233;t&#233; transf&#233;r&#233; car le type de fichier (".$_FILES['appliXml']['type'].") est incompatible.<br>\n";
			flush();
		}
		elseif (move_uploaded_file($_FILES['appliXml']['tmp_name'], $uploadfile))
		{
			echo "<h1>Ajout d'une application</h1>\n";
			echo "<h2>Transfert du fichier XML</h2>\n";
			echo "Le fichier '<b>".$appli."</b>' a &#233;t&#233; transf&#233;r&#233; avec succ&#232;s dans le r&#233;pertoire <i><u><a onmouseover=\"this.innerHTML='".$uploaddir."';\" onmouseout=\"this.innerHTML='tmp2'; \">tmp2</a></i></u> sous le nom '<b>".$name_import."</b>'.<br>\n";
			flush();

			$xml = new DOMDocument;
			$xml->formatOutput = true;
			$xml->preserveWhiteSpace = false;
			$xml->load($uploadfile);

			echo "<h2>Téléchargement des fichiers d'installation</h2>\n";
			echo "<table width='80%' align='center'>\n";
			$i=1; $success=0; $list_Appli=array();
			foreach ($xml->getElementsByTagName('package') as $package)
			{
				$list_Appli[] = (string) $package->getAttribute('id');
				if ($noDownload==0)
				{
					foreach ($package->getElementsByTagName('download') as $dwn)
					{
						$fileUrl = (string) $dwn->getAttribute('url');
						$fileTarget = (string) $dwn->getAttribute('saveto');
						$hashage_md5 = (string) $dwn->getAttribute('md5sum');
						$hashage_sha256 = (string) $dwn->getAttribute('sha256sum');
						echo "<tr><td align='center'>\n";
						echo "<div id='".$i."'>";
						$info_return=download_file($fileUrl,$fileTarget,$hashage_md5,$hashage_sha256);
						echo "</div>";
						if ($info_return["etat"]==1)
						{
							echo "<script language='JavaScript'> document.getElementById('".$i."').innerHTML = '".$info_return["msg"]."'; </script>";
							$success++;
						}
						elseif ($info_return["etat"]==-1)
						{
							echo "<script language='JavaScript'> document.getElementById('".$i."').innerHTML = '".$info_return["msg"]."'; </script>";
						}
						else
						{
							echo $info_return["msg"]."<br>\n";
						}
						echo "</td></tr>\n";
						$i++;
					}
				}
			}
			echo "<tr><td align='center'>\n";
			if ($noDownload==0)
			{
				echo $success." fichiers t&#233;l&#233;charg&#233;s avec succ&#232;s sur ".($i-1)." fichiers n&#233;cessaires.<br>\n";
			}
			else
			{
				echo "Option NoDownload activ&#233;e. Aucun fichier t&#233;l&#233;charg&#233;.<br>\n";
			}
			echo "</td></tr>\n";
			echo "</table>\n";

			// si tout est telecharge... import du paquet dans packages.xml
			echo "<h2>Importation du xml dans packages.xml et mise &#224; jour de la liste des applications.</h2>\n";
			echo "<table width='80%' align='center'>\n";
			if ($i==$success+1)
			{
				echo "<tr><td align='center'>\n";
				foreach ($list_Appli as $get_Appli)
				{
					remove_app($get_Appli,$url_packages);
					echo "Suppression de l'ancien paquet (".$get_Appli.").<br>\n";
				}
				echo "</td></tr>\n";
				echo "<tr><td align='center'>\n";
				add_app($liste_appli,$url_packages,$uploadfile,$login);
				echo "Ajout des nouveaux paquets achev&#233;.";
				echo "</td></tr>\n";
				echo "<tr><td align='center'>\n";
				echo "";
				echo "</td></tr>\n";
			}
			else
			{
				echo "<tr><td align='center'>\n";
				echo "Op&#233;ration annul&#233;e. Erreur sur le t&#233;l&#233;chargement des fichiers.";
				echo "</td></tr>\n";
			}
			echo "</table>\n";
		}
		else
		{
			echo "<h1>Ajout d'une application</h1>\n";
			echo "<h2>Transfert du fichier XML</h2>\n";
			echo "Erreur de transfert du fichier '" . $_FILES['appliXml']['tmp_name'] . "' dans $uploadfile.<br>\n";
			echo '<pre>';
			print_r($_FILES);
			echo '</pre>';
		}

	}
	else
	{
?>
<h1>Ajout d'une application</h1>
<form name="formulaire" method="post" action="" enctype="multipart/form-data">
			<table align="center">
				<tr>
					<td>
						Si vous avez déjà placé les fichiers nécessaires à l'application, sur le serveur: <br>
						<input name="noDownload" value="1" type="checkbox"></input>Ne pas télécharger les fichiers d'installation de cette application.<br><br>
						Pour ajouter une application qui n'est pas répertoriée sur le serveur de référence, cocher cette case : <br>
						<input name="ignoreWawadebMD5" value="1" onclick="if(this.checked) alert('Soyez sûr du contenu du fichier xml que vous allez installer sur le serveur!\nAucun contrôle ne sera effectué !\n\nLa sécurité de votre réseau est en jeu !!');" type="checkbox"></input>Ignorer le contrôle de hashage.<br><br>
					</td>
				</tr>
				<tr>
					<td>
						Fichier xml de définition de l'application :<br>
						<input title="chemin du fichier xml" size="70" name="appliXml" type="file"></input><input value="Ajouter cette application !" type="submit"></input>
					</td>
				</tr>
			</table>
		</form>
<?php
	}
	include ("pdp.inc.php");
?>