<?php

/*
----------------------------------------------------------------------------------------------------

	microtime_float()
	download_file($fileUrl,$fileTarget,$hashage_md5,$hashage_sha256)
	remove_app($get_Appli,$url_packages)
	add_app($liste_appli,$url_packages,$url_package,$login)

----------------------------------------------------------------------------------------------------
*/

	function microtime_float()
	{
		list($usec, $sec) = explode(" ", microtime());
		return ((float)$usec + (float)$sec);
	}

	function download_file($fileUrl,$fileTarget,$hashage_md5,$hashage_sha256)
	{
		global $wpkgroot,$wpkgroot2;
		$fileName = basename($fileTarget);
		$direName = dirname($fileTarget);
		$download=0;
		$etat=0;
		if (file_exists($wpkgroot2."/".$fileTarget))
		{
			if ($hashage_sha256!="")
			{
				if (hash_file('sha256', $wpkgroot2."/".$fileTarget)!=$hashage_sha256)
				{
					$download=1;
				}
				else
				{
					$return="Le fichier <b>".$fileName."</b> est d&#233;j&#224; pr&#233;sent avec le bon hashage sha256.";
					$etat=1;
					$download=0;
				}
			}
			elseif ($hashage_md5!="")
			{
				if (hash_file('md5', $wpkgroot2."/".$fileTarget)!=$hashage_md5)
				{
					$download=1;
				}
				else
				{
					$return="Le fichier <b>".$fileName."</b> est d&#233;j&#224; pr&#233;sent avec le bon hashage md5.";
					$etat=1;
					$download=0;
				}
			}
			else
			{
				$download=1;
			}
		}
		else
		{
			$download=1;
		}
		if ($download==1)
		{
			$handle = popen("/usr/bin/wget --progress=dot -O '".$wpkgroot."/tmp2/".$fileName."' ".$fileUrl." 2>&1", 'r');
			if (is_resource($handle))
			{
				$timestamp = microtime_float();
				$ch = "";
				sleep(1);
				while ( !feof($handle) )
				{
					# Pour eviter : Fatal error:  Maximum execution time of 30 seconds exceeded
					set_time_limit(300);
					$car = fread($handle, 1);
					if ( strlen($car) == 0 )
					{
						sleep(1);
					}
					else
					{
						$ch = "$ch$car";
					}
					if ( (microtime_float() - $timestamp) > 1 )
					{
						echo nl2br("$ch");
						$ch = "";
						$timestamp = microtime_float();
						flush();
					}
				}
				echo "$ch";
				flush();
			}
			if (file_exists($wpkgroot."/tmp2/".$fileName))
			{
				if ($hashage_sha256!="")
				{
					if (hash_file('sha256', $wpkgroot."/tmp2/".$fileName)==$hashage_sha256)
					{
						exec("mkdir -p '".$wpkgroot2."/".$direName."'");
						exec("mv '".$wpkgroot."/tmp2/".$fileName."' '".$wpkgroot2."/".$fileTarget."'");
						$return="Le fichier <b>".$fileName."</b> a &#233;t&#233; t&#233;l&#233;charg&#233; avec succ&#232;s et poss&#232;de le bon hashage sha256.";
						$etat=1;
					}
					else
					{
						$return="Erreur : Le fichier <b>".$fileName."</b> a &#233;t&#233; t&#233;l&#233;charg&#233; avec succ&#232;s et ne poss&#232;de  pas le bon hashage sha256 (".hash_file('sha256', $wpkgroot."/tmp2/".$fileName).").";
						$etat=-1;
					}
				}
				elseif ($hashage_md5!="")
				{
					if (hash_file('md5', $wpkgroot."/tmp2/".$fileName)==$hashage_md5)
					{
						exec("mkdir -p '".$wpkgroot2."/".$direName."'");
						exec("mv '".$wpkgroot."/tmp2/".$fileName."' '".$wpkgroot2."/".$fileTarget."'");
						$return="Le fichier <b>".$fileName."</b> a &#233;t&#233; t&#233;l&#233;charg&#233; avec succ&#232;s et poss&#232;de le bon hashage md5.";
						$etat=1;
					}
					else
					{
						$return="Le fichier <b>".$fileName."</b> a &#233;t&#233; t&#233;l&#233;charg&#233; avec succ&#232;s et ne poss&#232;de pas le bon hashage md5 (".hash_file('md5', $wpkgroot."/tmp2/".$fileName).").";
						$etat=-1;
					}
				}
				else
				{
					$return="Le fichier <b>".$fileName."</b> a &#233;t&#233; t&#233;l&#233;charg&#233; avec succès et sans v&#233;rification du hashage.";
					$etat=1;
				}
			}
		}
		if ($etat==0)
		{
			$return="Le fichier <b>".$fileName."</b> n'a pas &#233;t&#233; t&#233;l&#233;charg&#233;!";
		}
		return array("etat"=>$etat,"msg"=>$return);
	}

	function remove_app($get_Appli,$url_packages)
	{
		$xml = new DOMDocument;
		$xml->formatOutput = true;
		$xml->preserveWhiteSpace = false;
		$xml->load($url_packages);
		$element = $xml->documentElement;
		$packages = $xml->documentElement->getElementsByTagName('package');
		$length = $packages->length;

		$xml2 = new DOMDocument;
		$xml2->formatOutput = true;
		$xml2->preserveWhiteSpace = false;
		$root=$xml2->createElement("packages");
		$xml2->appendChild($root);
		$comment=$xml2->createComment(" Fichier genere par SambaEdu. Ne pas modifier. Il contient ".($length-1)." applications. ");
		$root->appendChild($comment);
		$packages2 = $xml2->documentElement->getElementsByTagName('package');

		$result=0;

		foreach ($packages as $package)
		{
			if ($package->getAttribute('id')==$get_Appli)
			{
				$return=1;
			}
			else
			{
				$node=$xml2->importNode($package, true);
				$xml2->documentElement->appendChild($node);
			}
		}

		$xml2->save($url_packages);

		$wpkg_link=connexion_db_wpkg();
		$update_query = mysqli_prepare($wpkg_link, "UPDATE `applications` SET `active_app`=0, `date_modif_app`=NOW() WHERE md5(`id_nom_app`)=md5(?)");
		mysqli_stmt_bind_param($update_query,"s", $get_Appli);
		mysqli_stmt_execute($update_query);
		mysqli_stmt_close($update_query);
		deconnexion_db_wpkg($wpkg_link);

		return $return;
	}

	function add_app($liste_appli,$url_packages,$url_package,$login)
	{
		$xml_appli = new DOMDocument;
		$xml_appli->formatOutput = true;
		$xml_appli->preserveWhiteSpace = false;
		$xml_appli->load($url_package);
		$xml_appli2 = $xml_appli->documentElement->getElementsByTagName('package');

		$document = new DOMDocument;
		$document->formatOutput = true;
		$document->preserveWhiteSpace = false;
		$document->load($url_packages);

		foreach ($xml_appli2 as $package)
		{
			$get_Appli = (string) $package->getAttribute('id');

			$list_appli = array("id_nom_app"=>$get_Appli,
								"nom_app"=>(string) $package->getAttribute('name'),
								"version_app"=>(string) $package->getAttribute('revision'),
								"compatibilite_app"=>(string) $package->getAttribute('compatibilite'),
								"categorie_app"=>(string) $package->getAttribute('category2'),
								"prorite_app"=>(string) $package->getAttribute('priority'),
								"reboot_app"=>(string) $package->getAttribute('reboot'),
								"active_app"=>1);

			$node=$document->importNode($package, true);
			$document->documentElement->appendChild($node);
			if (array_key_exists(hash('md5',$get_Appli),$liste_appli))
			{
				update_applications($liste_appli[hash('md5',$get_Appli)]["id_app"],$list_appli);
				$id_app=$liste_appli[hash('md5',$get_Appli)]["id_app"];
			}
			else
			{
				$id_app=insert_applications($list_appli);
			}

			$xml_hash=hash_file('sha512',$url_package);
			$nom_xml=basename($url_package);
			$operation="add";
			$wpkg_link=connexion_db_wpkg();

			$update_query = mysqli_prepare($wpkg_link, "INSERT INTO `journal_app` (`id_app`, `operation_journal_app`, `user_journal_app`, `date_journal_app`, `xml_journal_app`, `sha_journal_app`) VALUES (?, ?, ?, NOW(), ?, ?)");
			mysqli_stmt_bind_param($update_query,"issss", $id_app, $operation, $login, $nom_xml, $xml_hash);
			mysqli_stmt_execute($update_query);
			mysqli_stmt_close($update_query);

			$update_query = mysqli_prepare($wpkg_link, "UPDATE `applications` SET `sha_app`=?, `user_modif_app`=?, `date_modif_app`=NOW() WHERE id_app=?");
			mysqli_stmt_bind_param($update_query,"ssi", $xml_hash, $login, $id_app);
			mysqli_stmt_execute($update_query);
			mysqli_stmt_close($update_query);

			deconnexion_db_wpkg($wpkg_link);
		}

		$packages = $document->documentElement->getElementsByTagName('package');
		$length = $packages->length;
		
		$xpath = new DOMXpath($document);
		$list = iterator_to_array($xpath->evaluate('/packages/package'));
		uasort(
		  $list,
		  function($one, $two) use ($xpath) {
			return strcmp(
			  (string) $one->getAttribute('id'),
			  (string) $two->getAttribute('id')
			);
		  }
		);

		$newdoc = new DOMDocument;
		$newdoc->formatOutput = true;
		$newdoc->preserveWhiteSpace = false;
		$comment=$newdoc->createComment(" Fichier genere par SambaEdu. Ne pas modifier. Il contient ".($length)." applications. ");
		$newdoc->appendChild($comment);
		$libraries = $newdoc->appendChild($newdoc->importNode($document->documentElement));
		foreach ($list as $lt) {
			$libraries->appendChild($newdoc->importNode($lt, true));
		}
		$newdoc->encoding = 'UTF-8';
		$newdoc->save($url_packages);
	}
?>