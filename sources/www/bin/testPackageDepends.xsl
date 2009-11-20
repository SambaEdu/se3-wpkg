<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
	<!-- Test les dépendances logicielles des packages contenues dans le fichier appli.xml traité -->
	<xsl:output method="text" encoding="iso-8859-1"/>
	<xsl:param name="debug">0</xsl:param>
	<xsl:param name="Appli"></xsl:param>
	<xsl:param name="NoDownload">0</xsl:param>
	<xsl:variable name="PACKAGES" select="document('/var/se3/unattended/install/wpkg/packages.xml')/packages"/>
	<xsl:template match="/packages">
		<xsl:text>    ErrDepends=0&#x00a;</xsl:text>
		<xsl:for-each select="package[(@id = $Appli) or ($Appli = '')]/depends">
			<xsl:variable name="packageRequired" select="@package-id"/>
			<xsl:text>    # Teste la présence de l&apos;application &apos;</xsl:text><xsl:value-of select="$packageRequired"/><xsl:text>&apos; (pour &apos;</xsl:text><xsl:value-of select="../@id"/><xsl:text>&apos;).&#x00a;</xsl:text>
			<xsl:choose>
				<xsl:when test="$PACKAGES/package[@id = $packageRequired]">
					<xsl:text>    echo "    Dépend de l'application '</xsl:text><xsl:value-of select="$packageRequired"/><xsl:text>' qui est installée."&#x00a;</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>    echo &quot;    Erreur : L&apos;application &apos;</xsl:text><xsl:value-of select="$packageRequired"/><xsl:text>&apos; est absente. Elle doit être installée en premier !&quot;&#x00a;</xsl:text>
					<xsl:text>    ErrDepends=$(( $ErrDepends + 1 ))&#x00a;</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>