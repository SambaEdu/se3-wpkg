<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
	<xsl:output method="html" version="1.0" encoding="utf8" indent="yes"/>
	<!-- ## $Id$ ##
			S'applique � /var/se3/unattended/install/wpkg/packages.xml
			et retourne un html pour le div 'Effacer une appli'   -->

	<xsl:param name="idPackage"></xsl:param>
	<xsl:variable name="CePackage" select="/packages/package[@id = $idPackage]"/>

	<xsl:template match="/">
		<html>
			<head>
				<meta http-equiv="content-type" content="text/html; charset=utf8" />
			</head>
			<body>
				<p>
				Supprimer une application du serveur n'est pas anodin.
				Si elle est actuellement install�e sur des postes, elle appara�tra comme une application 'zombie'.
				De plus, d'autres applications peuvent d�pendre de <xsl:value-of select="$idPackage" />...
				</p>
				<p>
					Vous pouvez cependant la modifier en mettant � jour son fichier xml.
					Pensez alors � changer le n� de version (revision) pour que la mise � jour soit effectu�e sur les postes.
				</p>
				<form method="post" action="index.php" >
					<input name="SupprimerAppli" type="hidden" value="{$idPackage}" />
					<xsl:if test="$CePackage/download/@saveto" >
						<p>
							Si vous �tes vraiment s�r de vouloir supprimer cette application, les fichiers qui ont �t� t�l�charg�s, lors de son installation, peuvent �galement �tre supprim�s du serveur.
							Pour cela s�lectionnez ceux que vous voulez effacer.
						</p>
						<xsl:for-each select="$CePackage/download/@saveto" >
							<xsl:choose>
								<xsl:when test="../@url">
									<input name="deleteFiles[]" value="{position()}" checked="true" type="checkbox"></input>
								</xsl:when>
								<xsl:otherwise>
									<input name="deleteFiles[]" value="{position()}" type="checkbox"></input>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:value-of select="." /><br />
						</xsl:for-each>
					</xsl:if>
					<br/>
					<input type="SUBMIT" value="{concat('Supprimer ', $idPackage, ' maintenant !')}" />
				</form>
			</body>
		</html>
	</xsl:template>

</xsl:stylesheet>
