<?xml version="1.0" encoding="iso-8859-1"?>

<!--  Met à jour rapports.xml à partir du fichier xml fourni
		
		## $Id$ ##
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes" />
	<xsl:variable name="NewRapportsId" select="/rapports/rapport/@id"/>
	<xsl:variable name="RAPPORT" select="document('/var/se3/unattended/install/wpkg/rapports/rapports.xml')/rapports/rapport"/>
	<xsl:template match="/">
		 <xsl:comment ><xsl:value-of select="concat('Généré par SambaEdu. Ne pas modifier. ', count($RAPPORT), ' - ', count($NewRapportsId))" /></xsl:comment>
		<rapports>
			<xsl:for-each select="/rapports/rapport">
				<xsl:copy-of select="." />
			</xsl:for-each>
			<xsl:for-each select="$RAPPORT">
				<xsl:if test="not(@id = $NewRapportsId)">
					<xsl:copy-of select="." />
				</xsl:if>
			</xsl:for-each>
		</rapports>
	</xsl:template>
</xsl:stylesheet>
