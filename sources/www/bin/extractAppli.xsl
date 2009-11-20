<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
   <xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes"/>
   <!--     S'applique à /var/se3/unattended/install/wpkg/packages.xml
            et retourne un xml de l'appli passée en paramètre   -->

    <xsl:param name="Appli"></xsl:param>

    <xsl:template match="/">
        <xsl:element name="packages">
			<xsl:comment> Application '<xsl:value-of select="$Appli" />' extraite de packages.xml </xsl:comment>
			<xsl:copy-of select="/packages/package[@id = $Appli]" />
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
