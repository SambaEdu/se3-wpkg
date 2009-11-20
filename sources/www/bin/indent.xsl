<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes" />
	<xsl:template match="*">
	   <xsl:copy>
		  <xsl:copy-of select="@*" />
		  <xsl:apply-templates />
	   </xsl:copy>
	</xsl:template>

	<xsl:template match="comment()|processing-instruction()">
	   <xsl:copy />
	</xsl:template>

</xsl:stylesheet>
