<?php

/**

 * Gestion de la configuration de wsus offline
 * @Version $Id$

 * @Projet LCS / SambaEdu

 * @auteurs  Antoine & Laurent Joly

 * @note

 * @Licence Distribue sous la licence GPL

 */
/**
 * @Repertoire: dhcp
 * file: reservations.php
 */
// loading libs and init
include "entete.inc.php";
include "ldap.inc.php";
include "ihm.inc.php";



$login = isauth();
if (! $login )
{
	echo "<script language=\"JavaScript\" type=\"text/javascript\">\n<!--\n";
	$request = '/wpkg/index.php';
	echo "top.location.href = '/auth.php?request=" . rawurlencode($request) . "';\n";
	echo "//-->\n</script>\n";
	exit;
}


if (is_admin($config, "computers_is_admin",$login)!="Y")
	die (gettext("Vous n'avez pas les droits suffisants pour acc&#233;der &#224; cette fonction")."</BODY></HTML>");


// HTMLpurifier
include("../sambaedu/includes/library/HTMLPurifier.auto.php");
$config = HTMLPurifier_Config::createDefault();
$purifier = new HTMLPurifier($config);

if (isset($_POST['action']))
	$action=$purifier->purify($_POST['action']);
else
	$action="";

$update_generator = "/var/sambaedu/unattended/install/wsusoffline/UpdateGenerator.ini";
$default = "/var/sambaedu/unattended/install/packages/wsusoffline/default.txt";

function reset_ini($string)
{
	$name = "/var/sambaedu/unattended/install/wsusoffline/UpdateGenerator.ini";
	//On supprime le fichier s'il existe
	if (file_exists($name))
	{
		unlink($name);
	}
	$text = $string;
	$fh = fopen($name, 'w') or die("Could not create the file.");
	fwrite($fh, $text) or die("Could not write to the file.");
	fclose($fh);
	echo "Fichier " . $name . " r&#233;g&#233;n&#233;r&#233;!";
}

function update_ini_file($section_modif, $key_modif, $value_modif)
{
	$filepath = "/var/sambaedu/unattended/install/wsusoffline/UpdateGenerator.ini";
	$parsed = parse_ini_file($filepath, true);

	foreach ($parsed as $section => $values)
	{
		if ($section == $section_modif)
		{
			foreach ($values as $key => $value)
			{
				if ($key == $key_modif) {
					if ($value != $value_modif)
					{
						echo "<br/>Modification en cours...";
						echo nom_os($section)[0]." ".nom_option($key);
						if (nom_os($section)[1]!='-')
							echo " (".nom_os($section)[1].")";
						echo " : " . nom_value($value) . " --> " . nom_value($value_modif);
						$parsed[$section][$key] = $value_modif;
						save_ini_file($parsed, $filepath);
					}
				}
			}
		}
	}
}

function save_ini_file($array, $file)
{
	$a = arr2ini($array);
	$ffl = fopen($file, "w");
	fwrite($ffl, $a);
	fclose($ffl);
}

function arr2ini(array $a, array $parent = array())
{
	$out = '';
	foreach ($a as $k => $v)
	{
		if (is_array($v)) {
			$sec = array_merge((array)$parent, (array)$k);
			$out .= "\r\n" . '[' . join('.', $sec) . ']' . PHP_EOL;
			$out .= arr2ini($v, $sec);
		}
		else
		{
			$out .= "\r\n" . "$k=$v" . PHP_EOL;
		}
	}
	return $out;
}

function nom_os($nom)
{
	switch ($nom)
	{
		case "Windows Vista":
		$nom_return = array("Windows Vista","x86");
		break;
		case "Windows Vista x64":
		$nom_return = array("Windows Vista","x64");
		break;
		case "Windows 7":
		$nom_return = array("Windows 7 / Windows Server 2008 R2","x86");
		break;
		case "Windows Server 2008 R2":
		$nom_return = array("Windows 7 / Windows Server 2008 R2","x64");
		break;
		case "Windows 10":
		$nom_return = array("Windows 10 / Windows Server 2016","x86");
		break;
		case "Windows Server 2016":
		$nom_return = array("Windows 10 / Windows Server 2016","x64");
		break;
		case "Office 2007":
		$nom_return = array("Office 2007","-");
		break;
		case "Office 2010":
		$nom_return = array("Office 2010","-");
		break;
		case "Office 2013":
		$nom_return = array("Office 2013","-");
		break;
		case "Office 2016":
		$nom_return = array("Office 2016","-");
		break;
		default:
		$nom_return = array($nom,"-");
		break;
		
	}
	return $nom_return;
}

function nom_image($nom)
{
	switch ($nom)
	{
		case "Windows Vista":
		$nom_return = "winvista";
		break;
		case "Windows 7 / Windows Server 2008 R2":
		$nom_return = "win7";
		break;
		case "Windows 10 / Windows Server 2016":
		$nom_return = "win10";
		break;
		case "Office 2007":
		$nom_return = "o2k07";
		break;
		case "Office 2010":
		$nom_return = "o2k10";
		break;
		case "Office 2013":
		$nom_return = "o2k13";
		break;
		case "Office 2016":
		$nom_return = "o2k16";
		break;
		default:
		$nom_return = "vide";
		break;
		
	}
	return $nom_return;
}

function nom_option($nom)
{
	switch ($nom)
	{
		case "includedotnet":
		$nom_return = "Net Framework";
		break;
		case "includemsse":
		$nom_return = "Microsoft Security Essentials";
		break;
		case "includewddefs":
		$nom_return = "Windows Defender";
		break;
		case "glb":
		$nom_return = "Global";
		break;
		case "fra":
		$nom_return = "Fran&#231;ais";
		break;
		default:
		$nom_return = $nom;
		break;
		
	}
	return $nom_return;
}

function nom_value($nom)
{
	switch ($nom)
	{
		case "Disabled":
		$nom_return = "D&#233;sactiv&#233;";
		break;
		case "Enabled":
		$nom_return = "Activ&#233;";
		break;
		default:
		$nom_return = $nom;
		break;
		
	}
	return $nom_return;
}

class Data_ignore
{

	//On consid&#232;re que les windows non pris en charge ont &#233;t&#233; supprim&#233;s du fichier ini
	//On ignore quelques options qui ne doivent pas être modifi&#233;s
	const cleanupdownloads = 'cleanupdownloads';
	const verifydownloads = 'verifydownloads';
	const includesp = 'includesp';
	const seconly = 'seconly';
	//On ignore les version de windows pas pris en charge
	const Windows_Server_2012_R2 = 'Windows Server 2012 R2';
	const Windows_8_1 = 'Windows 8.1';
	const Windows_Server_2012 = 'Windows Server 2012';
	const Windows_8 = 'Windows 8';
	//On ignore diff&#233;rentes sections &#224; ne pas modifier
	const USB_Images = 'USB Images';
	const ISO_Images = 'ISO Images';
	const Miscellaneous = 'Miscellaneous';
	//On ignore les langues office
	const enu = 'enu';
	const esn = 'esn';
	const jpn = 'jpn';
	const kor = 'kor';
	const rus = 'rus';
	const ptg = 'ptg';
	const ptb = 'ptb';
	const deu = 'deu';
	const nld = 'nld';
	const ita = 'ita';
	const chs = 'chs';
	const cht = 'cht';
	const plk = 'plk';
	const hun = 'hun';
	const csy = 'csy';
	const sve = 'sve';
	const trk = 'trk';
	const ell = 'ell';
	const ara = 'ara';
	const heb = 'heb';
	const dan = 'dan';
	const nor = 'nor';
	const fin = 'fin';

	static public function exist($const)
	{
		$cls = new ReflectionClass(__CLASS__);
		foreach ($cls->getConstants() as $key => $value)
		{
			if ($value == $const)
			{
				return true;
			}
		}

		return false;
	}
}

echo "<h1>Configuration du module wsus-offline</h1>";

if ($action!='')
{
	switch ($action)
	{
		case 'download':
		ob_implicit_flush(true);
		ob_end_flush();

		echo "<h2>T&#233;l&#233;chargement des derni&#232;res mises &#224; jour</h2>";
		echo "<p>Ne pas interrompre l'op&#233;ration en cours!</p>";
		
		while (@ ob_end_flush());  // end all output buffers
		
		$proc = popen("/usr/share/sambaedu/scripts/wsusoffline-download.sh", "r");
		echo '<pre>';
		while (!feof($proc))
		{
			echo fread($proc, 4096);
			@ flush();
		}
		echo "</pre>";
		break;

		case 'generate':
		echo "<h2>Reset du fichier updategenerator.ini</h2>";
		reset_ini(file_get_contents("http://svn.tice.ac-caen.fr/svn/SambaEdu3/wpkg-packages-ng/files/wsusoffline/UpdateGenerator.ini"));
		break;

		case 'update':
		echo "<h2>Modification du fichier ini</h2>";
		foreach ($_POST["data"] as $section => $values)
		{
			$section_pur=$purifier->purify($section);
			foreach ($values as $key => $value)
			{
				
				$key_pur=$purifier->purify($key);
				$value_pur=$purifier->purify($value);
				$section_pur = str_replace("_", " ", $section_pur);
				update_ini_file($section_pur, $key_pur, $value_pur);
			}
		}
		break;
		
		default:
		echo "<p>Une erreur a eu lieu</p>";
		break;
	}
	echo '<p>Op&#233;ration termin&#233;e</p>';
	echo '<p><a href="wsusoffline.php">Retour &#224; la page pr&#233;c&#233;dente</a></p>';
}
else
{
	?>

	<!-- Gestion du updategenerator.ini -->
	<form action="" method="post">
			<?php
			$parse = parse_ini_file($update_generator, true);
			$list_conf_ini=array();
			$size_max=array();
			foreach ($parse as $section => $values)
			{
				//TRI
				if (!Data_ignore::exist($section))
				{
					foreach ($values as $key => $value)
					{
						//TRI
						if (!Data_ignore::exist($key))
						{
							$list_conf_ini[nom_os($section)[0]][$section][$key]=$value;
							@$size_max[nom_os($section)[0]]++;
						}
					}
				}
			}
			echo "<table align='center' cellspacing='1' cellpadding='2' bgcolor='#000000'>";
			echo "<tr bgcolor='#7CA9D6'>";
			echo "<th colspan='".(max($size_max)+2)."' align='center' style='color:white;text-shadow: 1px 1px 1px #000000;'>";
			echo "Choix des mises &#224; jour t&#233;l&#233;charg&#233;es &#224; 20h45";
			echo "</th>";
			echo "</tr>";
			foreach ($list_conf_ini as $id_os_nom=>$list_conf_ini_os)
			{
				$compteur=0;
				echo "<tr bgcolor='white'>";
				echo "<td valign='center' width='60' align='center'><img src='".nom_image($id_os_nom).".png' width='30' height='30'></td>";
				echo "<td valign='center' width='300' align='center'>".$id_os_nom."</td>";
				foreach ($list_conf_ini_os as $id_section=>$list_conf_ini_arch)
				{
					$id_arch=nom_os($id_section)[1];
					foreach ($list_conf_ini_arch as $id_lang=>$id_value)
					{
						echo "<td width='220' align='center'>".nom_option($id_lang)." ";
						if ($id_arch!="-")
							echo "(".$id_arch.")";
						echo "<br>";
						echo "<select name='data[{$id_section}][$id_lang]'>";
						echo "<option value='Enabled' " . (($id_value == 'Enabled') ? 'selected="selected"' : "") . ">".nom_value(Enabled)."</option>";
						echo "<option value='Disabled' " . (($id_value == 'Disabled') ? 'selected="selected"' : "") . ">".nom_value(Disabled)."</option>";
						echo "</select>";
						echo "</td>";
						$compteur++;
					}
				}
				if (max($size_max)>$compteur)
					echo "<td colspan='".(max($size_max)-$compteur)."'></td>";
				echo "</tr>";
			}
			echo "<tr bgcolor='#7CA9D6'>";
			echo "<td colspan='".(max($size_max)+2)."' align='center'>";
			echo "<input type='submit' value='Enregistrer les modifications'/>";
			echo "<input type='hidden' name='action' value='update'/>";
			echo "</td>";
			echo "</tr>";
			echo "</table>";
			?>		
	</form>
	<form id="generate" action="" name="generate" method="post">
<input type="hidden" name="action" value="generate"/>
</form>
<a href='#' onclick='document.getElementById("generate").submit()'>R&#233;initialiser le fichier de configuration &#224; partir de celui du svn</a>

<form id="download" action="" name="download" method="post">
<input type="hidden" name="action" value="download"/>
</form>
<a href='#' onclick='document.getElementById("download").submit()'>Lancer le script de t&#233;l&#233;chargement des mises &#224; jour (Op&#233ration tr&#232;s longue)</a>

	<?php
}
?>
</body>
</html>
