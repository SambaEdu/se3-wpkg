<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<!-- Génère le fichier PackagesCategory.txt qui sert a ranger les raccourcis dans %AllUsers%

	A démarrer depuis %Z%\wpkg\
		-->
	<xsl:output method="text" encoding="iso-8859-1" />
	<xsl:param name="debug"></xsl:param>
	<xsl:variable name="PACKAGES" select="document('./packages.xml')/packages"/>
	
	<xsl:template match="/">
		<xsl:for-each select="$PACKAGES/package[@category!='']" >
			<xsl:variable name="Pack" select="@id"/>
			<xsl:variable name="Cat" select="@category"/>
			<xsl:value-of select="concat($Pack, ';', $Cat, '&#x00d;&#x00a;')" />
		</xsl:for-each>	
	</xsl:template>

</xsl:stylesheet>
