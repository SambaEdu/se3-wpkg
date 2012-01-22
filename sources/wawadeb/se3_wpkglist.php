<?php
// $GET $POST
$branche=$_GET['branch'];


// Récupérer la date de dernière modification d'un fichier distant (la fonction retourne un timestamp unix, cf. http://wiki.pcinfo-web.com/timestamp )
function RecupDateModifDistant( $uri ) {
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
echo "<?xml version='1.0' encoding='iso-8859-1'?>\n";
echo "<packages>\n";

$svnurl="http://svn.tice.ac-caen.fr/svn/SambaEdu3/wpkg-packages";

if ($branche<>"testing") {
    $branche="stable";
}

$file = fopen ("$svnurl/$branche", "r");
if (!$file) {
  echo "<p>Impossible de lire la page.\n";
  exit;
}
while (!feof ($file)) {
    $line = fgets ($file, 1024);
    /* Cela ne fonctionne que si les balises href sont correctement utilisees */
    //if (preg_match ("@\<a.*\>(.*)/\</a\>@i", $line, $out)) {
     //   $rep = $out[1];
        //echo $rep;

     //   if ($rep <> "..") {
            //echo $rep;
            // pour la date : date("F d Y H:i:s", filename($xml));
            //$srep = fopen ("$svnurl/$branche/$rep", "r");
            //while (!feof ($srep)) {
                //$files = fgets ($srep, 1024);
                if (preg_match ("@\<a.*\>(.*).xml\</a\>@i", $line, $xmlfiles)) {
                    $xmlfile = $xmlfiles[1];
                    // LIRE LE id dans le fichier $xmlfile.xml et sa date
                 	$filedate = RecupDateModifDistant( "$svnurl/$branche/$rep/$xmlfile.xml" );
			//$fileopened = fopen ("$svnurl/$branche/$rep/$xmlfile.xml", "r");
                    // recuperation de l'id dans le xml
                    //$filedate=date("F d Y H:i:s", filemtime($svnurl/$branche/$rep/$xmlfile.xml));
                    //fclose($fileopened);
			$md5sum=md5_file("$svnurl/$branche/$xmlfile.xml");
			//$md5sum="b3aa7b6f8357e66f291b8cda074e990d";
                    $id="$xmlfile"; // pour les tests
                    echo "<package id='$id' xml='$xmlfile.xml' url='$svnurl/$branche/$xmlfile.xml' md5sum='$md5sum' date='$filedate' svn_link='$svnurl/logs/$xmlfile.log' /> ";
                     //echo "$xmlfile.xml";
                    echo "\n";
                }
            //}
            //fclose($srep);
       // }
    //}
}
fclose($file);
echo "</packages>";
?>
