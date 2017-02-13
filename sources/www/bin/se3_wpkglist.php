<?php
// $GET $POST
$branche=$_GET['branch'];


// Récupérer la date de dernière modification d'un fichier distant (la fonction retourne un timestamp unix, cf. http://wiki.pcinfo-web.com/timestamp )
function RecupDateModifDistant( $uri )
{
	// default
	$unixtime = 0;
	$fp = fopen( $uri, "r" );
	if( !$fp ) {return;}

	$MetaData = stream_get_meta_data( $fp );

	foreach( $MetaData['wrapper_data'] as $response )
		{
		// Dans le cas d'une redirection vers une autre page / un autre fichier
		if( substr( strtolower($response), 0, 10 ) == 'location: ' )
			{
			$newUri = substr( $response, 10 );
			fclose( $fp );
			return RecupDateModifDistant( $newUri );
			}
		// Dans le cas où on a bien l'en-tête "last-modified"
		elseif( substr( strtolower($response), 0, 15 ) == 'last-modified: ' )
			{
			$unixtime = strtotime( substr($response, 15) );
			//$unixtime = substr($response,15);
			// Mise au format pour l'interface SE3
			$unixtime = date( 'Y-m-d\TH:i:sO' , $unixtime );
			break;
			}
		}
	fclose( $fp );
	return $unixtime;
}



// en-tete du fichier a generer.
echo "<?xml version='1.0' encoding='UTF-8'?>\n";
echo "<packages>\n";

$svnurl="http://svn.tice.ac-caen.fr/svn/SambaEdu3/wpkg-packages-ng";

if ($branche<>"testing" and $branche<>"XP") {
    $branche="stable";
}

$file = fopen ("$svnurl/$branche", "r");
if (!$file) {
  echo "<p>Impossible de lire la page.\n";
  exit;
}
while (!feof ($file))
{
	$line = fgets ($file, 1024);
	/* Cela ne fonctionne que si les balises href sont correctement utilisees */
	if (preg_match ("@\<a.*\>(.*).xml\</a\>@i", $line, $xmlfiles))
	{
		$xmlfile = $xmlfiles[1];
		// LIRE LE id dans le fichier $xmlfile.xml et sa date
		$filedate = RecupDateModifDistant( "$svnurl/$branche/$xmlfile.xml" );
		
		$filelog = fopen ("$svnurl/logs/$xmlfile.log", "r");
		$xml_name=utf8_encode(rtrim(fgets($filelog)));
		$xml_category=utf8_encode(rtrim(fgets($filelog)));
        fclose($filelog);	
		
		$md5sum=md5_file("$svnurl/$branche/$xmlfile.xml");
		$id="$xmlfile"; // pour les tests
		echo "<package id='$id' xml='$xmlfile.xml' url='$svnurl/$branche/$xmlfile.xml' md5sum='$md5sum' date='$filedate' svn_link='$svnurl/logs/$xmlfile.log' category='$xml_category' name='$xml_name'/> ";
		echo "\n";
	}
}
fclose($file);
echo "</packages>";
?>