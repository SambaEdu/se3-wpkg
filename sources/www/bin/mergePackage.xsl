<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
   <xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes" />
   <xsl:param name="fichier">nomdefichierbidon</xsl:param>
   <xsl:param name="Appli"></xsl:param>
   <xsl:variable name="newPackages" select="/packages/package"/>
   <xsl:variable name="packages" select="document('/var/se3/unattended/install/wpkg/packages.xml')/packages"/>
   <!-- 
	Ajoute les données d'une application appli.xml à packages.xml
	les packages déja existants de packages.xml sont mis à jours (pas dupliqués)
   -->
	<xsl:variable name="AncienPaquets" select="$packages/package[@id != $Appli]" />
	<xsl:variable name="NouveauPaquet" select="$newPackages[@id = $Appli]" />

	<xsl:template match="/">
		<!-- insère le noeud racine ( /wpkg )-->
		<xsl:element name = "packages" >
			<xsl:comment >  Généré par SambaEdu. Ne pas modifier. Contient <xsl:value-of select="count($AncienPaquets) +count($NouveauPaquet)" /> applications </xsl:comment>
			<xsl:for-each select="$AncienPaquets | $NouveauPaquet">
				<xsl:sort select="@id" />
				<xsl:copy-of select="." />
			</xsl:for-each>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
