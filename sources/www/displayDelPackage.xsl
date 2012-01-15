<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
	<xsl:output method="html" version="1.0" encoding="iso-8859-1" indent="yes"/>
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
				Supprimer une application du serveur n'est pas anodin. D'autres applications peuvent d�pendre de <xsl:value-of select="$idPackage" />...
				</p>
				<p>
				Si elle est actuellement install�e sur des postes, il faut imp�rativement la d�cocher de tous les postes et parcs auxquels elle est associ�e. Elle sera alors d�sinstall�e de ceux-ci au prochain d�marrage. Si la d�sinstallation �choue, l'application restera sur le poste : plus aucune tentative de d�sinstallation ne sera effectu�e. Elle n'appara�tra plus comme une application 'zombie' (versions ant�rieures de wpkg).
				</p>
				<p>
					Attendez plut�t que l'application soit d�sinstall�e de tous les postes avant de la supprimer. En cas d'�chec de la d�sinstallation, vous pourrez modifier le package en mettant � jour son fichier xml.
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
