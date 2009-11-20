<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
   <xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes" />
   <xsl:param name="Appli"></xsl:param>
   <xsl:variable name="packages" select="document('/var/se3/unattended/install/wpkg/packages.xml')/packages"/>
   <!-- 
	Supprime le noeud <package id="$Appli" de packages.xml
	S'applique à packages.xml
   -->
	<xsl:variable name="Paquets" select="$packages/package[@id != $Appli]" />

	<xsl:template match="/">
		<!-- insère le noeud racine ( /packages )-->
		<xsl:element name = "packages" >
			<xsl:comment >  Généré par SambaEdu. Ne pas modifier. Contient <xsl:value-of select="count($Paquets)" /> applications </xsl:comment>
			<xsl:for-each select="$Paquets">
				<xsl:sort select="@id" />
				<xsl:copy-of select="." />
			</xsl:for-each>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
