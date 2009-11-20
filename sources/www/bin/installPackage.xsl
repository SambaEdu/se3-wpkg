<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
	<xsl:output method="text" encoding="iso-8859-1"/>
	<xsl:param name="debug">0</xsl:param>
	<xsl:param name="WPKGROOT" select="'/var/se3/unattended/install/wpkg'" />
	<xsl:param name="WPKGWWW" select="'/var/www/se3/wpkg'" />
	<xsl:param name="NoDownload">0</xsl:param>
	<xsl:param name="AppliXML"></xsl:param>
	<xsl:param name="md5Xml"></xsl:param>
	<xsl:param name="controlMD5">se3_wpkglist.php</xsl:param>
	<xsl:variable name="PACKAGES" select="document(concat($WPKGROOT, '/packages.xml'))/packages"/>
	<xsl:variable name="controlMD5Xml" select="concat($WPKGWWW, '/', $controlMD5)"/>
	<!-- Commandes de téléchargement des fichiers de l'application -->
	<xsl:template match="/">
		<xsl:variable name="nDownload" select="count(/packages/package/download)"/>
		
		<xsl:text>echo "Installation du fichier &apos;</xsl:text><xsl:value-of select="$AppliXML"/><xsl:text>&apos;."&#x00a;</xsl:text>
		<xsl:text>echo "</xsl:text><xsl:call-template name = "testMD5Xml" /><xsl:text>."&#x00a;</xsl:text>

		<xsl:choose>
			<xsl:when test="($controlMD5 = '') or (document($controlMD5Xml)/packages/package[(@xml = $AppliXML) and (@md5sum = $md5Xml)])" >
				<!-- le fichier xml est valide -->
				<xsl:choose>
					<xsl:when test="$nDownload = 0" >
						<xsl:text>echo "L'importation du fichier xml ne nécessite aucun fichier téléchargé."&#x00a;</xsl:text>
					</xsl:when>
					<xsl:when test="$nDownload = 1" >
						<xsl:text>echo "L'importation du fichier xml nécessite 1 fichier téléchargé."&#x00a;</xsl:text>
					</xsl:when>
					<xsl:otherwise >
						<xsl:text>echo "L'importation du fichier xml nécessite </xsl:text><xsl:value-of select="$nDownload"/><xsl:text> fichiers téléchargés."&#x00a;</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text>nPackage=</xsl:text><xsl:value-of select="count(/packages/package)"/><xsl:text>&#x00a;</xsl:text>
				<xsl:for-each select="/packages/package">
					<xsl:variable name="idAppli" select="@id"/>
					<xsl:variable name="nameAppli" select="@name"/>
					<xsl:variable name="nDownloadAppli" select="count(download)"/>
					<xsl:text>  echo "&lt;/pre&gt;&lt;h2&gt;Configuration de l'application '</xsl:text><xsl:value-of select="$idAppli"/><xsl:text>'.&lt;/h2&gt;&lt;pre&gt;"&#x00a;</xsl:text>
					
					<!-- Test des dépendances d'applications -->
					<xsl:text>  ErrDepends=0&#x00a;</xsl:text>
					<xsl:text>  TestDepends '</xsl:text><xsl:value-of select="$idAppli"/><xsl:text>'&#x00a;</xsl:text>
					<xsl:text>  if [ "$ErrDepends" != "0" ]; then &#x00a;</xsl:text>
					<xsl:text>    echo "  Il manque $ErrDepends application(s) dépendante(s) pour effectuer l'installation." &#x00a;</xsl:text>
					<xsl:text>    Erreur="1"&#x00a;</xsl:text>
					<xsl:text>  else &#x00a;</xsl:text>
					<xsl:text>    ErreurApp="0"&#x00a;</xsl:text>
					
					<xsl:choose>
						<xsl:when test="$nDownloadAppli > 1" >
							<xsl:text>    echo &quot;    &apos;</xsl:text><xsl:value-of select="@name"/><xsl:text>&apos; (Rev: </xsl:text><xsl:value-of select="@revision"/><xsl:text>) a besoin de </xsl:text><xsl:value-of select="$nDownloadAppli"/><xsl:text> fichiers téléchargés.&quot;&#x00a;</xsl:text>
							<xsl:for-each select="download">
								<xsl:text>      Download &apos;</xsl:text><xsl:value-of select="@url"/><xsl:text>&apos; &apos;</xsl:text><xsl:value-of select="@saveto"/><xsl:text>&apos; &apos;</xsl:text><xsl:value-of select="@md5sum"/><xsl:text>&apos; &apos;</xsl:text><xsl:value-of select="$NoDownload"/><xsl:text>&apos; &#x00a;</xsl:text>
							</xsl:for-each>
						</xsl:when>
						<xsl:when test="$nDownloadAppli = 1" >
							<xsl:text>    echo &quot;    &apos;</xsl:text><xsl:value-of select="@name"/><xsl:text>&apos; (Rev: </xsl:text><xsl:value-of select="@revision"/><xsl:text>) a besoin d'1 fichier téléchargé.&quot;&#x00a;</xsl:text>
							<xsl:for-each select="download">
								<xsl:text>      Download &apos;</xsl:text><xsl:value-of select="@url"/><xsl:text>&apos; &apos;</xsl:text><xsl:value-of select="@saveto"/><xsl:text>&apos; &apos;</xsl:text><xsl:value-of select="@md5sum"/><xsl:text>&apos; &apos;</xsl:text><xsl:value-of select="$NoDownload"/><xsl:text>&apos; &#x00a;</xsl:text>
							</xsl:for-each>
						</xsl:when>
						<xsl:when test="$nDownloadAppli = 0" >
							<xsl:text>    echo &quot;    Aucun fichier n&apos;est nécessaire à &apos;</xsl:text><xsl:value-of select="@name"/><xsl:text>&apos; (Rev: </xsl:text><xsl:value-of select="@revision"/><xsl:text>).&quot;&#x00a;</xsl:text>
						</xsl:when>
					</xsl:choose>
					<xsl:text>    if [ &quot;$ErreurApp&quot; == &quot;0&quot; ]; then &#x00a;</xsl:text>
					<xsl:for-each select="delete" >
						<xsl:variable name="deleteFile" select="concat($WPKGROOT, '/../', @file)"/>
						<xsl:text>      if [ -e &quot;</xsl:text><xsl:value-of select="$deleteFile"/><xsl:text>&quot; ]; then &#x00a;</xsl:text>
						<xsl:text>        echo &quot;    Suppression du fichier &apos;</xsl:text><xsl:value-of select="@file"/><xsl:text>&apos;.&quot; &#x00a;</xsl:text>
						<xsl:text>        /bin/rm &quot;</xsl:text><xsl:value-of select="$deleteFile"/><xsl:text>&quot; &#x00a;</xsl:text>
						<xsl:text>      fi &#x00a;</xsl:text>
					</xsl:for-each>
					<xsl:text>      AddApplication &apos;</xsl:text><xsl:value-of select="$idAppli"/><xsl:text>&apos; &#x00a;</xsl:text>
					<xsl:text>    fi &#x00a;</xsl:text>
					<xsl:text>  fi &#x00a;</xsl:text>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="not(document($controlMD5Xml)/packages/package[@xml = $AppliXML])">
				<xsl:text>
Erreur="3"
				echo "&lt;/pre&gt;
Si vous êtes sûr de sa validité, vous pouvez ajouter cette application après avoir coché la case 'Ignorer le contrôle MD5'.&lt;br/&gt;
Attention! Dans ce cas, c'est à vous de contrôler le contenu du fichier xml de l'application.&lt;br&gt;&lt;br/&gt;
Voir le fichier &lt;a target=\"_blank\" href='index.php?getXml=tmp/$appliXml'&gt;$appliXml&lt;/a&gt;.&lt;br/&gt;&lt;br/&gt;
&lt;form method=\"post\" action=\"index.php?upload=1\" enctype=\"multipart/form-data\"&gt;
&lt;table&gt;
&lt;tr&gt;
&lt;td&gt;
&lt;input type=\"hidden\" name=\"appliXml\" value=\"$appliXml\" /&gt;
&lt;input type=\"hidden\" name=\"LocalappliXml\" value=\"tmp/$appliXml\" /&gt;
&lt;input type=\"hidden\" name=\"urlWawadebMD5\" value=\"$urlMD5\" /&gt;
&lt;input type=\"checkbox\" name=\"noDownload\" value=\"1\" "
if [ "$NoDownload" == "1" ] ; then echo " checked "; fi
echo "&gt;
&lt;/input&gt;Ne pas télécharger les fichiers d'installation de cette application, (suppose qu'ils sont déjà présents sur le serveur).&lt;br/&gt;
&lt;input type=\"checkbox\" name=\"ignoreWawadebMD5\" value=\"1\" onclick=\"if(this.checked) alert('Soyez sûr du contenu du fichier xml que vous allez installer sur le serveur!\nAucun contrôle ne sera effectué !\n\nLa sécurité de votre réseau est en jeu !!');\"&gt;&lt;/input&gt;Ignorer le contrôle MD5.
&lt;/td&gt;
&lt;/tr&gt;
&lt;tr&gt;
&lt;td&gt;
&lt;input type=\"submit\" value=\"Ajouter l'application contenue dans '$appliXml'\" /&gt;
&lt;/td&gt;
&lt;/tr&gt;
&lt;/table&gt;
&lt;/form&gt; &lt;pre&gt;"
				</xsl:text>
			</xsl:when>
		</xsl:choose>
		<xsl:text>&#x00a;</xsl:text>
	</xsl:template>
	
	<xsl:template name="testMD5Xml" >
		<xsl:choose>
			<xsl:when test="$controlMD5 = ''">
				<xsl:text>Pas de contrôle MD5 du fichier </xsl:text><xsl:value-of select="$AppliXML"/><xsl:text> (md5=</xsl:text><xsl:value-of select="$md5Xml"/><xsl:text>)</xsl:text>
			</xsl:when>
			<xsl:otherwise >
				
				<xsl:choose>
					<xsl:when test="document($controlMD5Xml)/packages/package[(@xml = $AppliXML) and (@md5sum = $md5Xml)]">
						<xsl:text>Le fichier xml est valide  (md5=</xsl:text><xsl:value-of select="$md5Xml"/><xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:when test="document($controlMD5Xml)/packages/package[@xml = $AppliXML]">
						<xsl:text>Erreur : le md5sum du fichier xml ne correspond pas (md5=</xsl:text><xsl:value-of select="$md5Xml"/><xsl:text> &lt;&gt; md5Ref=</xsl:text><xsl:value-of select="document($controlMD5Xml)/packages/package[@xml = $AppliXML]/@md5sum"/><xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:otherwise >
						<xsl:text>Le fichier </xsl:text><xsl:value-of select="$AppliXML"/><xsl:text> n'est pas répertorié sur le forum (md5=</xsl:text><xsl:value-of select="$md5Xml"/><xsl:text>)</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>